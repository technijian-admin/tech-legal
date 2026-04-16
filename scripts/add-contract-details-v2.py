"""
Add CONTRACT.md to each active client folder with contract details.
Includes: header info, labor rates, SLA, contract period,
and the Technijian service catalog + VM tiers available to each contract.

NOTE: Per-client service assignments (which services & how many devices)
are NOT available via the portal API — RS0 is empty for all contracts.
The global catalog (RS6/7/8) is included as a reference for what's available.
"""
import sys
import os
import json

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".codex", "skills", "client-portal-core", "scripts"))
from client_portal_api import request_json

BASE_DIR = os.path.join(os.path.dirname(__file__), "..", "clients")


def fmt_date(dt_str):
    if not dt_str:
        return "Not set"
    return dt_str[:10]


def fmt_currency(val):
    if val is None:
        return "N/A"
    return f"${val:,.2f}"


def main():
    # 1. Active clients
    clients_resp = request_json("/api/clients/active", method="GET")
    clients = clients_resp["ResultSets"][0]["Rows"]
    client_by_did = {c["DirID"]: c for c in clients}

    # 2. All contracts
    contracts_resp = request_json(
        "/api/modules/contract/stored-procedures/client-portal/dbo/GetAllContracts/execute",
        method="POST",
        body={"Parameters": {}},
    )
    all_contracts = contracts_resp["resultSets"][0]["rows"]
    active = [c for c in all_contracts if (c.get("ContractStatusTxt") or "").upper() == "ACTIVE"]

    # 3. Get the global price catalog once (same for all contracts)
    sample_cid = active[0]["Contract_ID"]
    detail_resp = request_json(
        "/api/modules/contract/stored-procedures/client-portal/dbo/stp_dt_Con_Org_Loc_Con_Contract_Get/execute",
        method="POST",
        body={"Parameters": {"ContractID": sample_cid}},
    )
    detail_rs = detail_resp.get("resultSets", [])

    # RS6 = Services catalog, RS7 = VM tiers, RS8 = Microsoft licensing
    services_catalog = detail_rs[6]["rows"] if len(detail_rs) > 6 else []
    vm_tiers = detail_rs[7]["rows"] if len(detail_rs) > 7 else []
    msft_licensing = detail_rs[8]["rows"] if len(detail_rs) > 8 else []

    print(f"Active clients: {len(clients)}, Active contracts: {len(active)}")
    print(f"Global catalog: {len(services_catalog)} services, {len(vm_tiers)} VM tiers, {len(msft_licensing)} MSFT licenses")

    # 4. Group contracts by Client_LocationsID
    contracts_by_lid = {}
    for c in active:
        lid = c.get("Client_LocationsID")
        if lid:
            contracts_by_lid.setdefault(lid, []).append(c)

    # 5. Write CONTRACT.md for each client
    written = 0
    for cl in sorted(clients, key=lambda x: x["Location_Name"]):
        did = cl["DirID"]
        code = cl["LocationCode"]
        name = cl["Location_Name"]
        folder = os.path.join(BASE_DIR, code)

        client_contracts = contracts_by_lid.get(did, [])
        if not client_contracts:
            print(f"{code:<8} {name:<42} NO ACTIVE CONTRACT")
            continue

        os.makedirs(folder, exist_ok=True)
        lines = [f"# Active Contracts: {name} ({code})", ""]

        for idx, ct in enumerate(client_contracts, 1):
            ct_name = ct.get("Contract_Name", "Unnamed")
            ct_type = ct.get("ContractType", "N/A")

            if len(client_contracts) > 1:
                lines.append(f"## Contract {idx}: {ct_name}")
            else:
                lines.append(f"## {ct_name}")
            lines.append("")

            # Contract overview
            lines.append("### Contract Overview")
            lines.append("")
            lines.append("| Field | Value |")
            lines.append("|-------|-------|")
            lines.append(f"| **Contract ID** | {ct.get('Contract_ID', 'N/A')} |")
            lines.append(f"| **Contract Name** | {ct_name} |")
            lines.append(f"| **Type** | {ct_type} |")
            lines.append(f"| **Status** | {ct.get('ContractStatusTxt', 'N/A')} |")
            lines.append(f"| **Start Date** | {fmt_date(ct.get('StartDate'))} |")
            lines.append(f"| **End Date** | {fmt_date(ct.get('EndDate'))} |")
            lines.append(f"| **Contract Period** | {ct.get('Under_Contract_Period', 'N/A')} |")
            lines.append(f"| **Date Signed** | {fmt_date(ct.get('DateSigned'))} |")
            lines.append(f"| **Net Terms** | {ct.get('NetTerms') or cl.get('Net_Terms', 'N/A')} |")
            lines.append(f"| **Created** | {fmt_date(ct.get('Create_timestamp'))} |")
            lines.append(f"| **Last Updated** | {fmt_date(ct.get('Update_timestamp'))} |")
            lines.append("")

            # Labor rates
            lines.append("### Labor & Billing Rates")
            lines.append("")
            lines.append("| Rate | Amount |")
            lines.append("|------|--------|")

            fixed_rate = ct.get("Fixed_Rate_Cost", 0)
            over_hours = ct.get("Over_Hours_Rate", 0)
            min_time = ct.get("Minimum_Time_Rate", 0)
            min_incr = ct.get("Minimum_Increment_Time", 0)

            if ct_type == "Monthly Service":
                lines.append(f"| **Monthly Fixed Rate** | {fmt_currency(fixed_rate)} |")
            elif ct_type == "Hourly Rate":
                if fixed_rate and fixed_rate > 0:
                    lines.append(f"| **Base Hourly Rate** | {fmt_currency(fixed_rate)} |")
                else:
                    lines.append(f"| **Base Hourly Rate** | Per rate card |")
            else:
                lines.append(f"| **Rate / Cost** | {fmt_currency(fixed_rate)} |")

            lines.append(f"| **Over-Contract Hours Rate** | {fmt_currency(over_hours)} |")

            if min_time and min_time > 0:
                lines.append(f"| **Minimum Time Rate** | {fmt_currency(min_time)} |")
            if min_incr and min_incr > 0:
                lines.append(f"| **Minimum Increment** | {min_incr} min |")

            if ct.get("IsDedicatedBandwidth"):
                lines.append(f"| **Dedicated Bandwidth** | Yes |")
                lines.append(f"| **Bandwidth Rate** | {fmt_currency(ct.get('Bandwidth_Rate'))} |")
                if ct.get("DedicatedBandwidth_Rate"):
                    lines.append(f"| **Dedicated BW Rate** | {fmt_currency(ct.get('DedicatedBandwidth_Rate'))} |")
            lines.append("")

            # SLA
            lines.append("### SLA Commitments")
            lines.append("")
            lines.append("| Metric | Target |")
            lines.append("|--------|--------|")
            lines.append(f"| **Initial Response Time (IRT)** | {ct.get('SLA_IRT', 'N/A')} hours |")
            lines.append(f"| **Escalation / Resolution (EOR)** | {ct.get('SLA_EOR', 'N/A')} hours |")
            lines.append("")

            # Internal reference
            lines.append("### Internal Reference")
            lines.append("")
            lines.append(f"- **Serial ID:** `{ct.get('SerialID', 'N/A')}`")
            lines.append(f"- **Client LocationsID (DirID):** {ct.get('Client_LocationsID', 'N/A')}")
            if ct.get("AutotaskID"):
                lines.append(f"- **Autotask ID:** {ct['AutotaskID']}")
            if ct.get("DSGUID"):
                lines.append(f"- **DocuSign GUID:** `{ct['DSGUID']}`")
            lines.append("")

        # Service catalog (appended once, not per-contract)
        lines.append("---")
        lines.append("")
        lines.append("## Technijian Service Catalog (Available Services)")
        lines.append("")
        lines.append("> **Note:** The per-client service assignments (which services are active and")
        lines.append("> device/user counts) are not available via the portal API. The table below shows")
        lines.append("> the full Technijian catalog with per-unit pricing. Contact the account team for")
        lines.append("> this client's specific service mix.")
        lines.append("")

        # Group by ServiceType
        by_type = {}
        for s in services_catalog:
            stype = s.get("ServiceType") or "Other"
            by_type.setdefault(stype, []).append(s)

        for stype in sorted(by_type.keys()):
            items = by_type[stype]
            lines.append(f"### {stype}")
            lines.append("")
            lines.append("| Code | Service | Unit Price/mo | Per | License |")
            lines.append("|------|---------|-------------:|-----|---------|")
            for s in sorted(items, key=lambda x: x.get("Code", "")):
                price = s.get("Monthly Price", 0)
                lines.append(
                    f"| {s.get('Code', '')} | {s.get('Service', '')} | "
                    f"${price:,.2f} | {s.get('DeviceType', '')} | "
                    f"{'Monthly' if s.get('LicenseType') == 'M' else 'Annual'} |"
                )
            lines.append("")

        # VM tiers
        lines.append("### Cloud VM Tiers")
        lines.append("")
        lines.append("| Type | vCores | Memory GB | Bare VM/mo | + Win Server/mo |")
        lines.append("|------|-------:|----------:|-----------:|----------------:|")
        for v in vm_tiers:
            lines.append(
                f"| {v.get('VMType', '')} | {v.get('vCores', '')} | "
                f"{v.get('Memory', '')} | ${v.get('Bare VM', '0')} | "
                f"${v.get('Windows Server Standard', '0')} |"
            )
        lines.append("")

        # Microsoft licensing
        lines.append("### Microsoft Licensing")
        lines.append("")
        lines.append("| Code | Service | Unit Price/mo | License |")
        lines.append("|------|---------|-------------:|---------|")
        for m in msft_licensing:
            price = m.get("Monthly Price", 0)
            lines.append(
                f"| {m.get('Code', '')} | {m.get('Service', '')} | "
                f"${price:,.2f} | "
                f"{'Monthly' if m.get('LicenseType') == 'M' else 'Annual'} |"
            )
        lines.append("")

        contract_file = os.path.join(folder, "CONTRACT.md")
        with open(contract_file, "w", encoding="utf-8") as f:
            f.write("\n".join(lines))

        types = ", ".join(ct.get("ContractType", "?") for ct in client_contracts)
        rates = ", ".join(
            fmt_currency(ct.get("Over_Hours_Rate")) for ct in client_contracts
        )
        print(f"{code:<8} {name:<42} {types:<20} OHR={rates}")
        written += 1

    print(f"\nDone. Wrote CONTRACT.md for {written} clients in {BASE_DIR}")


if __name__ == "__main__":
    main()

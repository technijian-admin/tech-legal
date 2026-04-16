"""
Add CONTRACT.md to each active client folder with their active contract details.
"""
import sys
import os

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

    # Active contracts only
    active = [c for c in all_contracts if (c.get("ContractStatusTxt") or "").upper() == "ACTIVE"]
    print(f"Active clients: {len(clients)}, Active contracts: {len(active)}")

    # Group contracts by Client_LocationsID
    contracts_by_lid = {}
    for c in active:
        lid = c.get("Client_LocationsID")
        if lid:
            contracts_by_lid.setdefault(lid, []).append(c)

    # 3. Write CONTRACT.md for each client
    written = 0
    for cl in sorted(clients, key=lambda x: x["Location_Name"]):
        did = cl["DirID"]
        code = cl["LocationCode"]
        name = cl["Location_Name"]
        folder = os.path.join(BASE_DIR, code)

        client_contracts = contracts_by_lid.get(did, [])
        if not client_contracts:
            # Check if there might be a match we missed
            print(f"{code:<8} {name:<42} NO ACTIVE CONTRACT")
            continue

        os.makedirs(folder, exist_ok=True)

        lines = [
            f"# Active Contracts: {name} ({code})",
            "",
        ]

        for i, ct in enumerate(client_contracts, 1):
            if len(client_contracts) > 1:
                lines.append(f"## Contract {i}: {ct.get('Contract_Name', 'Unnamed')}")
            else:
                lines.append(f"## {ct.get('Contract_Name', 'Unnamed')}")
            lines.append("")

            # Core details table
            lines.append("| Field | Value |")
            lines.append("|-------|-------|")
            lines.append(f"| **Contract ID** | {ct.get('Contract_ID', 'N/A')} |")
            lines.append(f"| **Contract Name** | {ct.get('Contract_Name', 'N/A')} |")
            lines.append(f"| **Type** | {ct.get('ContractType', 'N/A')} |")
            lines.append(f"| **Status** | {ct.get('ContractStatusTxt', 'N/A')} |")
            lines.append(f"| **Start Date** | {fmt_date(ct.get('StartDate'))} |")
            lines.append(f"| **End Date** | {fmt_date(ct.get('EndDate'))} |")
            lines.append(f"| **Contract Period** | {ct.get('Under_Contract_Period', 'N/A')} |")
            lines.append(f"| **Date Signed** | {fmt_date(ct.get('DateSigned'))} |")
            lines.append(f"| **Net Terms** | {ct.get('NetTerms') or cl.get('Net_Terms', 'N/A')} |")
            lines.append("")

            # Pricing
            lines.append("### Pricing")
            lines.append("")
            lines.append("| Field | Value |")
            lines.append("|-------|-------|")

            ct_type = ct.get("ContractType", "")
            if ct_type == "Monthly Service":
                lines.append(f"| **Monthly Fixed Rate** | {fmt_currency(ct.get('Fixed_Rate_Cost'))} |")
            elif ct_type == "Hourly Rate":
                lines.append(f"| **Hourly Rate** | {fmt_currency(ct.get('Fixed_Rate_Cost'))} |")
            else:
                lines.append(f"| **Rate / Cost** | {fmt_currency(ct.get('Fixed_Rate_Cost'))} |")

            lines.append(f"| **Over-Hours Rate** | {fmt_currency(ct.get('Over_Hours_Rate'))} |")

            if ct.get("IsDedicatedBandwidth"):
                lines.append(f"| **Dedicated Bandwidth** | Yes |")
                lines.append(f"| **Bandwidth Rate** | {fmt_currency(ct.get('Bandwidth_Rate'))} |")
                if ct.get("DedicatedBandwidth_Rate"):
                    lines.append(f"| **Dedicated BW Rate** | {fmt_currency(ct.get('DedicatedBandwidth_Rate'))} |")

            if ct.get("Minimum_Time_Rate"):
                lines.append(f"| **Minimum Time Rate** | {fmt_currency(ct.get('Minimum_Time_Rate'))} |")
            if ct.get("Minimum_Increment_Time"):
                lines.append(f"| **Minimum Increment** | {ct.get('Minimum_Increment_Time')} min |")
            lines.append("")

            # SLA
            lines.append("### SLA")
            lines.append("")
            lines.append("| Metric | Target |")
            lines.append("|--------|--------|")
            lines.append(f"| **Initial Response Time** | {ct.get('SLA_IRT', 'N/A')} hours |")
            lines.append(f"| **Escalation / Resolution** | {ct.get('SLA_EOR', 'N/A')} hours |")
            lines.append("")

            # Internal reference
            lines.append("### Internal Reference")
            lines.append("")
            lines.append(f"- **Serial ID:** `{ct.get('SerialID', 'N/A')}`")
            lines.append(f"- **Client LocationsID:** {ct.get('Client_LocationsID', 'N/A')}")
            if ct.get("AutotaskID"):
                lines.append(f"- **Autotask ID:** {ct['AutotaskID']}")
            if ct.get("DSGUID"):
                lines.append(f"- **DocuSign GUID:** {ct['DSGUID']}")
            lines.append(f"- **Created:** {fmt_date(ct.get('Create_timestamp'))}")
            lines.append(f"- **Last Updated:** {fmt_date(ct.get('Update_timestamp'))}")
            lines.append("")

        contract_file = os.path.join(folder, "CONTRACT.md")
        with open(contract_file, "w", encoding="utf-8") as f:
            f.write("\n".join(lines))

        # Summary
        types = ", ".join(ct.get("ContractType", "?") for ct in client_contracts)
        rates = ", ".join(fmt_currency(ct.get("Fixed_Rate_Cost")) for ct in client_contracts)
        print(f"{code:<8} {name:<42} {types:<20} {rates}")
        written += 1

    print(f"\nDone. Wrote CONTRACT.md for {written} clients in {BASE_DIR}")


if __name__ == "__main__":
    main()

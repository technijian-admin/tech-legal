#!/usr/bin/env python3
"""Pull TALY invoice list + detail for the most recent monthly invoices.

Re-runnable. Writes:
  - invoices-list.xml         raw stp_xml_Inv_Org_Loc_Inv_List_Get output
  - invoices-list.csv         flattened list (all invoices)
  - details/det_<id>_<no>.xml stp_xml_Inv_Org_Loc_Inv_Detail_Get_V2 output
"""
from __future__ import annotations

import csv
import json
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

HERE = Path(__file__).resolve().parent
DETAIL_DIR = HERE / "details"
DETAIL_DIR.mkdir(exist_ok=True)

REPO_HELPERS = Path(r"C:\vscode\annual-client-review\annual-client-review\scripts\clientportal")
sys.path.insert(0, str(REPO_HELPERS))
from cp_api import execute_sp, sp_xml_out  # noqa: E402

TALY_DIR_ID = 7728
RECENT_DETAIL_COUNT = 6  # how many recent non-void monthlies to pull detail for


def parse_invoice_list(xml: str) -> list[dict]:
    if not xml:
        return []
    root = ET.fromstring(xml if xml.lstrip().startswith("<Root") else f"<Root>{xml}</Root>")
    out = []
    for inv in root.iter("Invoice"):
        out.append({c.tag: (c.text or "").strip() for c in inv})
    return out


def main() -> None:
    print("[1/3] Pulling invoice list (stp_xml_Inv_Org_Loc_Inv_List_Get)...")
    r = execute_sp("invoices", "dbo", "stp_xml_Inv_Org_Loc_Inv_List_Get", {"DirID": TALY_DIR_ID})
    xml_all = sp_xml_out(r)
    (HERE / "invoices-list.xml").write_text(xml_all, encoding="utf-8")
    invoices = parse_invoice_list(xml_all)
    print(f"        {len(invoices)} invoices")

    fields: list[str] = []
    seen: set[str] = set()
    for inv in invoices:
        for k in inv:
            if k not in seen:
                seen.add(k)
                fields.append(k)
    csv_path = HERE / "invoices-list.csv"
    with csv_path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(invoices)
    print(f"[2/3] Wrote {csv_path.name}")

    monthlies = [d for d in invoices if d.get("InvoiceType") == "Monthly" and d.get("Status") != "Void"]
    monthlies.sort(key=lambda d: d.get("InvoiceDate", ""), reverse=True)
    print(f"[3/3] Pulling detail for {RECENT_DETAIL_COUNT} most recent non-void monthlies...")
    for d in monthlies[:RECENT_DETAIL_COUNT]:
        iid = int(d["InvoiceID"])
        no = d["InvoiceNo"]
        r = execute_sp("invoices", "dbo", "stp_xml_Inv_Org_Loc_Inv_Detail_Get_V2", {"InvoiceID": iid})
        xml = sp_xml_out(r)
        (DETAIL_DIR / f"det_{iid}_{no}.xml").write_text(xml, encoding="utf-8")
        print(f"        {no} ({d.get('InvoiceDate','')[:10]}) -> {len(xml)} chars")

    print("Done.")


if __name__ == "__main__":
    main()

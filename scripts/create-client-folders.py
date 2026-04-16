"""
Create client folders with CONTACTS.md for each active client.
Pulls data from Client Portal API: active clients, directory, user details.
"""
import sys
import os
import json

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".codex", "skills", "client-portal-core", "scripts"))
from client_portal_api import request_json

BASE_DIR = os.path.join(os.path.dirname(__file__), "..", "clients")


def main():
    # 1. Active clients
    clients_resp = request_json("/api/clients/active", method="GET")
    clients = clients_resp["ResultSets"][0]["Rows"]
    print(f"Active clients: {len(clients)}")

    # 2. Full directory (all entries)
    dir_resp = request_json(
        "/api/modules/dir/stored-procedures/client-portal/dbo/stp_Get_All_Dir/execute",
        method="POST",
        body={"Parameters": {}},
    )
    all_dir = dir_resp["resultSets"][0]["rows"]
    print(f"Directory entries: {len(all_dir)}")

    # Lookup maps
    dir_map = {d["DirID"]: d for d in all_dir}
    client_entries = {d["DirID"]: d for d in all_dir if d.get("DirectoryType") == "Client"}

    def user_info(uid):
        if not uid:
            return None
        u = dir_map.get(uid)
        if not u:
            return None
        name = f"{u.get('First_Name', '') or ''} {u.get('Last_Name', '') or ''}".strip()
        return {
            "name": name or None,
            "email": u.get("EMail_Primary"),
            "phone": u.get("Phone_Cell") or u.get("Phone_Office"),
            "title": u.get("Title"),
        }

    def find_active_users(client_dirid):
        ce = dir_map.get(client_dirid)
        if not ce:
            return []
        loc_filter = ce.get("LocationTopFilter", "")
        if not loc_filter:
            return []
        return [
            e
            for e in all_dir
            if e.get("DirectoryType") == "User"
            and (e.get("LocationTopFilter") or "").startswith(loc_filter)
            and e.get("IsActive", False)
        ]

    # 3. Build and write
    os.makedirs(BASE_DIR, exist_ok=True)
    header = f"{'Code':<8} {'Client Name':<42} {'Signer':<28} {'Invoice To':<28} {'Primary':<28} {'Users':>5}"
    print(header)
    print("-" * len(header))

    for cl in sorted(clients, key=lambda x: x["Location_Name"]):
        did = cl["DirID"]
        code = cl["LocationCode"]
        name = cl["Location_Name"]

        ce = client_entries.get(did, {})
        sign = user_info(ce.get("Sign_User_ID"))
        inv = user_info(ce.get("Invoice_User_ID"))
        prim = user_info(ce.get("Primary_User_ID"))
        active_users = find_active_users(did)

        # Create folder
        folder = os.path.join(BASE_DIR, code)
        os.makedirs(folder, exist_ok=True)

        # Build CONTACTS.md
        lines = [
            f"# {name} ({code})",
            "",
            f"**Client Code:** {code}",
            f"**Portal DirID:** {did}",
        ]
        office_phone = ce.get("Phone_Office")
        if office_phone:
            lines.append(f"**Office Phone:** {office_phone}")
        lines.append("")

        # Contract Signer
        lines.append("## Contract Signer")
        if sign and sign["name"]:
            lines.append(f"- **Name:** {sign['name']}")
            lines.append(f"- **Email:** {sign['email'] or 'Not set'}")
            lines.append(f"- **Phone:** {sign['phone'] or 'Not available'}")
            if sign["title"]:
                lines.append(f"- **Title:** {sign['title']}")
        else:
            lines.append("*Not designated in portal*")
        lines.append("")

        # Invoice Recipient
        lines.append("## Invoice Recipient")
        if inv and inv["name"]:
            lines.append(f"- **Name:** {inv['name']}")
            lines.append(f"- **Email:** {inv['email'] or 'Not set'}")
            lines.append(f"- **Phone:** {inv['phone'] or 'Not available'}")
            if inv["title"]:
                lines.append(f"- **Title:** {inv['title']}")
        else:
            lines.append("*Not designated in portal*")
        lines.append("")

        # Primary Contact
        lines.append("## Primary Contact")
        if prim and prim["name"]:
            lines.append(f"- **Name:** {prim['name']}")
            lines.append(f"- **Email:** {prim['email'] or 'Not set'}")
            lines.append(f"- **Phone:** {prim['phone'] or 'Not available'}")
            if prim["title"]:
                lines.append(f"- **Title:** {prim['title']}")
        else:
            lines.append("*Not designated in portal*")
        lines.append("")

        # All Active Users
        if active_users:
            lines.append(f"## All Active Users ({len(active_users)})")
            lines.append("")
            for u in sorted(active_users, key=lambda x: f"{x.get('First_Name','')} {x.get('Last_Name','')}"):
                uname = f"{u.get('First_Name', '') or ''} {u.get('Last_Name', '') or ''}".strip()
                main_star = " (Main Contact)" if u.get("IsMainContact") else ""
                lines.append(f"### {uname}{main_star}")
                lines.append(f"- **Email:** {u.get('EMail_Primary') or 'N/A'}")
                phone = u.get("Phone_Cell") or u.get("Phone_Office") or "N/A"
                lines.append(f"- **Phone:** {phone}")
                if u.get("Title"):
                    lines.append(f"- **Title:** {u['Title']}")
                lines.append(f"- **Role:** {u.get('Role') or 'N/A'}")
                lines.append("")
        else:
            lines.append("## All Active Users")
            lines.append("*No active users found in portal*")
            lines.append("")

        contact_file = os.path.join(folder, "CONTACTS.md")
        with open(contact_file, "w", encoding="utf-8") as f:
            f.write("\n".join(lines))

        # Summary line
        s_name = (sign["name"] if sign and sign["name"] else "-")[:27]
        i_name = (inv["name"] if inv and inv["name"] else "-")[:27]
        p_name = (prim["name"] if prim and prim["name"] else "-")[:27]
        n_users = len(active_users)
        print(f"{code:<8} {name:<42} {s_name:<28} {i_name:<28} {p_name:<28} {n_users:>5}")

    print(f"\nDone. Created {len(clients)} client folders with CONTACTS.md in {BASE_DIR}")


if __name__ == "__main__":
    main()

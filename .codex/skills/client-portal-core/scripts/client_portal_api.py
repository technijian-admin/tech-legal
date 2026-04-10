#!/usr/bin/env python3
import argparse
import base64
import copy
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

BASE_URL = "https://api-clientportal.technijian.com"
CACHE_DIR = Path.home() / ".cache" / "client-portal"
TOKEN_CACHE = CACHE_DIR / "token.json"
HTTP_TIMEOUT = 60
TOKEN_SKEW_SECONDS = 120
DEFAULT_KEYS_FILES = [
    Path("/mnt/c/Users/rjain/OneDrive - Technijian, Inc/Documents/VSCODE/keys/client-portal.md"),
]


def ensure_cache_dir():
    CACHE_DIR.mkdir(parents=True, exist_ok=True)


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path, data):
    ensure_cache_dir()
    path.write_text(json.dumps(data, indent=2), encoding="utf-8")


def safe_slug(value):
    return re.sub(r"[^a-zA-Z0-9_.-]+", "-", value)


def cache_file(name):
    return CACHE_DIR / f"{safe_slug(name)}.json"


def load_markdown_value(text, label):
    target = label.lower()
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        cleaned = line.lstrip("- ").replace("`", "")
        cleaned = cleaned.replace("**", "")
        if cleaned.lower().startswith(target.lower() + ":"):
            return cleaned.split(":", 1)[1].strip()
    return None


def load_credentials():
    env_user = os.environ.get("CLIENT_PORTAL_USERNAME")
    env_password = os.environ.get("CLIENT_PORTAL_PASSWORD")
    if env_user and env_password:
        return env_user, env_password, "environment"

    candidates = []
    env_file = os.environ.get("CLIENT_PORTAL_KEYS_FILE")
    if env_file:
        candidates.append(Path(env_file))
    candidates.extend(DEFAULT_KEYS_FILES)

    for path in candidates:
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        user = load_markdown_value(text, "UserName")
        password = load_markdown_value(text, "Password")
        if user and password:
            return user, password, str(path)

    raise SystemExit(
        "Could not load Client Portal credentials. Set CLIENT_PORTAL_USERNAME and "
        "CLIENT_PORTAL_PASSWORD, or create the OneDrive keys file."
    )


def decode_jwt_payload(token):
    parts = token.split(".")
    if len(parts) != 3:
        return {}
    payload = parts[1]
    payload += "=" * (-len(payload) % 4)
    try:
        return json.loads(base64.urlsafe_b64decode(payload.encode()).decode())
    except Exception:
        return {}


def token_is_valid(data):
    access_token = data.get("accessToken")
    if not access_token:
        return False
    payload = decode_jwt_payload(access_token)
    exp = payload.get("exp")
    if not exp:
        return False
    return (int(exp) - TOKEN_SKEW_SECONDS) > int(time.time())


def token_cache_data():
    if TOKEN_CACHE.exists():
        try:
            data = read_json(TOKEN_CACHE)
            if token_is_valid(data):
                return data
        except Exception:
            return None
    return None


def request_json(path, method="GET", body=None, headers=None, auth=True):
    url = BASE_URL + path
    req_headers = {"Accept": "application/json"}
    if headers:
        req_headers.update(headers)
    if auth:
        token = get_token()["accessToken"]
        req_headers["Authorization"] = f"Bearer {token}"
    data = None
    if body is not None:
        data = json.dumps(body).encode()
        req_headers.setdefault("Content-Type", "application/json")
    req = urllib.request.Request(url, data=data, headers=req_headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=HTTP_TIMEOUT) as response:
            text = response.read().decode("utf-8", "replace")
            if not text:
                return None
            return json.loads(text)
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", "replace")
        raise RuntimeError(f"HTTP {exc.code} for {path}: {detail[:1000]}") from exc


def get_token(force=False):
    ensure_cache_dir()
    if not force:
        cached = token_cache_data()
        if cached:
            return cached
    username, password, source = load_credentials()
    token = request_json(
        "/api/auth/token",
        method="POST",
        body={"userName": username, "password": password},
        auth=False,
        headers={"Content-Type": "application/json"},
    )
    token["credentialSource"] = source
    write_json(TOKEN_CACHE, token)
    return token


def get_cached_endpoint(name, path, ttl_seconds):
    ensure_cache_dir()
    path_obj = cache_file(name)
    if path_obj.exists() and (time.time() - path_obj.stat().st_mtime) < ttl_seconds:
        return read_json(path_obj)
    data = request_json(path)
    write_json(path_obj, data)
    return data


def get_health(refresh=False):
    if refresh:
        return request_json("/api/system/health")
    return get_cached_endpoint("health", "/api/system/health", 300)


def get_databases(refresh=False):
    if refresh:
        return request_json("/api/catalog/databases")
    return get_cached_endpoint("databases", "/api/catalog/databases", 3600)


def get_modules(refresh=False):
    if refresh:
        return request_json("/api/catalog/modules/guide")
    return get_cached_endpoint("modules-guide", "/api/catalog/modules/guide", 3600)


def get_objects(refresh=False):
    if refresh:
        return request_json("/api/catalog/objects")
    return get_cached_endpoint("objects", "/api/catalog/objects", 3600)


def get_guide_catalog(refresh=False):
    if refresh:
        return request_json("/api/catalog/guide")
    return get_cached_endpoint("guide-catalog", "/api/catalog/guide", 3600)


def get_guide_entry(database_alias, schema, name, refresh=False):
    cache_name = f"guide-{database_alias}-{schema}-{name}"
    if not refresh:
        cached_path = cache_file(cache_name)
        if cached_path.exists() and (time.time() - cached_path.stat().st_mtime) < 3600:
            return read_json(cached_path)
    data = request_json(f"/api/catalog/guide/{database_alias}/{schema}/{name}")
    write_json(cache_file(cache_name), data)
    return data


def normalize_key(database_alias, schema, name):
    return f"{database_alias.lower()}::{schema.lower()}::{name.lower()}"


def merged_catalog(refresh=False):
    objects = get_objects(refresh=refresh)
    guides = get_guide_catalog(refresh=refresh)
    guide_map = {
        normalize_key(g["databaseAlias"], g["schema"], g["objectName"]): g
        for g in guides
    }
    merged = []
    for obj in objects:
        key = normalize_key(obj["DatabaseAlias"], obj["Schema"], obj["Name"])
        guide = guide_map.get(key, {})
        input_params = [
            p["Name"].lstrip("@")
            for p in obj.get("Parameters", [])
            if not p.get("IsOutput")
        ]
        merged.append(
            {
                "module": obj.get("Module"),
                "databaseAlias": obj.get("DatabaseAlias"),
                "schema": obj.get("Schema"),
                "name": obj.get("Name"),
                "kind": obj.get("Kind"),
                "isWriteOperation": bool(obj.get("IsWriteOperation")),
                "parameters": input_params,
                "guide": guide,
                "route": guide.get("route"),
                "businessArea": guide.get("businessArea") or obj.get("Module"),
                "label": guide.get("label"),
                "description": guide.get("description"),
                "parameterSummary": guide.get("parameterSummary"),
            }
        )
    return merged


def search_records(query, limit=10, module_filter=None, include_write=False, refresh=False):
    tokens = [token for token in re.findall(r"[a-z0-9]+", query.lower()) if token]
    records = merged_catalog(refresh=refresh)
    results = []
    for record in records:
        module_segment = str(record["module"] or "").lower()
        if module_filter and module_filter.lower() not in module_segment:
            continue
        if not include_write and record["isWriteOperation"]:
            continue
        text_parts = [
            record.get("module") or "",
            record.get("databaseAlias") or "",
            record.get("schema") or "",
            record.get("name") or "",
            record.get("businessArea") or "",
            record.get("label") or "",
            record.get("description") or "",
            " ".join(record.get("parameters") or []),
        ]
        hay = " ".join(text_parts).lower()
        score = 0
        for token in tokens:
            if token in str(record.get("name") or "").lower():
                score += 8
            if token in str(record.get("label") or "").lower():
                score += 6
            if token in str(record.get("module") or "").lower():
                score += 4
            if token in str(record.get("businessArea") or "").lower():
                score += 3
            if token in hay:
                score += 1
        if record.get("route"):
            score += 2
        if not record.get("isWriteOperation"):
            score += 1
        if score > 0:
            results.append((score, record))
    results.sort(key=lambda item: (-item[0], item[1]["module"], item[1]["name"]))
    return [record for _, record in results[:limit]]


def guessed_route(module_name, database_alias, schema, name):
    segment = (module_name or "").lower()
    return f"/api/modules/{segment}/stored-procedures/{database_alias}/{schema}/{name}/execute"


def merge_body(template, params=None, raw_body=None):
    if raw_body is not None:
        return raw_body
    base = copy.deepcopy(template) if template else {}
    if params is None:
        return base or {"Parameters": {}}
    if "Parameters" in params and isinstance(params["Parameters"], dict):
        if isinstance(base.get("Parameters"), dict):
            base["Parameters"].update(params["Parameters"])
            extra = {k: v for k, v in params.items() if k != "Parameters"}
            base.update(extra)
            return base
        return params
    if isinstance(base.get("Parameters"), dict):
        base["Parameters"].update(params)
        return base
    if not base:
        return {"Parameters": params}
    base.update(params)
    return base


def execute_procedure(database_alias, schema, name, params=None, raw_body=None, refresh=False):
    guide = get_guide_entry(database_alias, schema, name, refresh=refresh)
    route = guide.get("route") or guessed_route(guide.get("module"), database_alias, schema, name)
    request_template = guide.get("requestTemplate") or {"Parameters": {}}
    body = merge_body(request_template, params=params, raw_body=raw_body)
    return request_json(route, method=guide.get("method", "POST"), body=body)


def recipe_active_client_contracts(limit=50, refresh=False):
    clients_response = execute_procedure("client-portal", "dbo", "stp_Get_Client_List", refresh=refresh)
    contracts_response = execute_procedure("client-portal", "dbo", "GET_CONTRACTS_LIST", refresh=refresh)
    clients = clients_response["resultSets"][0]["rows"]
    contracts = contracts_response["resultSets"][0]["rows"]
    active_clients = {row["ClientID"]: row for row in clients if row.get("IsActive")}
    matched = {}
    unmatched_active_contract_rows = 0
    for row in contracts:
        is_active = str(row.get("Is_Active_Contract") or row.get("Active") or "").lower() == "true"
        if not is_active:
            continue
        client_id = row.get("Client_ID")
        if client_id in active_clients:
            matched[client_id] = active_clients[client_id]
        else:
            unmatched_active_contract_rows += 1
    ordered = sorted(
        matched.values(),
        key=lambda row: (
            0 if (row.get("ClientCode") or row.get("ClientName")) else 1,
            (row.get("ClientCode") or ""),
            (row.get("ClientName") or ""),
            row.get("ClientID") or 0,
        ),
    )
    clients_out = [
        {
            "ClientID": row.get("ClientID"),
            "ClientCode": row.get("ClientCode"),
            "ClientName": row.get("ClientName"),
        }
        for row in ordered[:limit]
    ]
    return {
        "recipe": "active-client-contracts",
        "generatedAtUtc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "matchedClientCount": len(ordered),
        "activeClientCount": len(active_clients),
        "contractRowCount": len(contracts),
        "unmatchedActiveContractRows": unmatched_active_contract_rows,
        "note": "Many active contract rows are location-linked and have Client_ID = null, so this join is a best-effort client-level view rather than a complete contract census.",
        "clients": clients_out,
    }


def parse_json_arg(value, label):
    try:
        return json.loads(value)
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Invalid JSON for {label}: {exc}") from exc


def print_json(data):
    print(json.dumps(data, indent=2, sort_keys=False))


def cmd_auth(args):
    token = get_token(force=args.force)
    payload = decode_jwt_payload(token["accessToken"])
    print_json(
        {
            "tokenType": token.get("tokenType"),
            "expiresIn": token.get("expiresIn"),
            "scope": token.get("scope"),
            "credentialSource": token.get("credentialSource"),
            "issuer": payload.get("iss"),
            "audience": payload.get("aud"),
            "preferred_username": payload.get("preferred_username"),
            "exp": payload.get("exp"),
        }
    )


def cmd_health(args):
    print_json(get_health(refresh=args.refresh))


def cmd_databases(args):
    data = get_databases(refresh=args.refresh)
    if args.json:
        print_json(data)
        return
    for row in data:
        print(
            f"{row.get('Alias')}\t{row.get('DisplayName')}\t{row.get('DatabaseName')}\t{row.get('Server')}"
        )


def cmd_modules(args):
    data = get_modules(refresh=args.refresh)
    if args.json:
        print_json(data)
        return
    for row in data:
        print(
            f"{row.get('moduleSegment')}\t{row.get('module')}\t{row.get('businessArea')}\t"
            f"{row.get('endpointCount')}\t{row.get('readEndpointCount')}\t{row.get('writeEndpointCount')}"
        )


def cmd_objects(args):
    data = get_objects(refresh=args.refresh)
    query_tokens = [token.lower() for token in args.query]
    out = []
    for row in data:
        if args.module and args.module.lower() not in str(row.get("Module") or "").lower():
            continue
        if not args.include_write and row.get("IsWriteOperation"):
            continue
        hay = " ".join(
            [
                str(row.get("Module") or ""),
                str(row.get("DatabaseAlias") or ""),
                str(row.get("Schema") or ""),
                str(row.get("Name") or ""),
            ]
        ).lower()
        if query_tokens and not all(token in hay for token in query_tokens):
            continue
        out.append(row)
    out = out[: args.limit]
    if args.json:
        print_json(out)
        return
    for row in out:
        print(
            f"{row.get('Module')}\t{row.get('DatabaseAlias')}\t{row.get('Schema')}\t{row.get('Name')}\twrite={row.get('IsWriteOperation')}"
        )


def cmd_search(args):
    matches = search_records(
        args.query,
        limit=args.limit,
        module_filter=args.module,
        include_write=args.include_write,
        refresh=args.refresh,
    )
    if args.json:
        print_json(matches)
        return
    for index, match in enumerate(matches, start=1):
        write_flag = "write" if match.get("isWriteOperation") else "read"
        params = ", ".join(match.get("parameters") or []) or "none"
        print(f"[{index}] {match.get('module')} {match.get('databaseAlias')}/{match.get('schema')}/{match.get('name')} ({write_flag})")
        if match.get("label"):
            print(f"    label: {match.get('label')}")
        if match.get("parameterSummary"):
            print(f"    params: {match.get('parameterSummary')}")
        else:
            print(f"    params: {params}")
        if match.get("route"):
            print(f"    route: {match.get('route')}")
        if match.get("description"):
            print(f"    why: {match.get('description')[:220]}")


def cmd_guide(args):
    print_json(get_guide_entry(args.database_alias, args.schema, args.name, refresh=args.refresh))


def cmd_execute(args):
    params = parse_json_arg(args.params, "--params") if args.params else None
    raw_body = parse_json_arg(args.raw_body, "--raw-body") if args.raw_body else None
    result = execute_procedure(
        args.database_alias,
        args.schema,
        args.name,
        params=params,
        raw_body=raw_body,
        refresh=args.refresh,
    )
    print_json(result)


def cmd_recipe(args):
    if args.name != "active-client-contracts":
        raise SystemExit(f"Unknown recipe: {args.name}")
    print_json(recipe_active_client_contracts(limit=args.limit, refresh=args.refresh))


def build_parser():
    parser = argparse.ArgumentParser(description="Client Portal API helper")
    subparsers = parser.add_subparsers(dest="command", required=True)

    auth_parser = subparsers.add_parser("auth", help="Generate or read the cached token")
    auth_parser.add_argument("--force", action="store_true", help="Force a fresh token")
    auth_parser.set_defaults(func=cmd_auth)

    health_parser = subparsers.add_parser("health", help="Get system health")
    health_parser.add_argument("--refresh", action="store_true")
    health_parser.set_defaults(func=cmd_health)

    db_parser = subparsers.add_parser("databases", help="List database aliases")
    db_parser.add_argument("--refresh", action="store_true")
    db_parser.add_argument("--json", action="store_true")
    db_parser.set_defaults(func=cmd_databases)

    modules_parser = subparsers.add_parser("modules", help="List module guide summary")
    modules_parser.add_argument("--refresh", action="store_true")
    modules_parser.add_argument("--json", action="store_true")
    modules_parser.set_defaults(func=cmd_modules)

    objects_parser = subparsers.add_parser("objects", help="Browse raw catalog objects")
    objects_parser.add_argument("query", nargs="*", help="Optional raw token filter")
    objects_parser.add_argument("--module")
    objects_parser.add_argument("--include-write", action="store_true")
    objects_parser.add_argument("--limit", type=int, default=20)
    objects_parser.add_argument("--refresh", action="store_true")
    objects_parser.add_argument("--json", action="store_true")
    objects_parser.set_defaults(func=cmd_objects)

    search_parser = subparsers.add_parser("search", help="Search across guide and object catalogs")
    search_parser.add_argument("query")
    search_parser.add_argument("--module")
    search_parser.add_argument("--include-write", action="store_true")
    search_parser.add_argument("--limit", type=int, default=10)
    search_parser.add_argument("--refresh", action="store_true")
    search_parser.add_argument("--json", action="store_true")
    search_parser.set_defaults(func=cmd_search)

    guide_parser = subparsers.add_parser("guide", help="Fetch a specific guide entry")
    guide_parser.add_argument("database_alias")
    guide_parser.add_argument("schema")
    guide_parser.add_argument("name")
    guide_parser.add_argument("--refresh", action="store_true")
    guide_parser.set_defaults(func=cmd_guide)

    exec_parser = subparsers.add_parser("execute", help="Execute a procedure by alias/schema/name")
    exec_parser.add_argument("database_alias")
    exec_parser.add_argument("schema")
    exec_parser.add_argument("name")
    exec_parser.add_argument("--params", help="JSON object merged into requestTemplate.Parameters")
    exec_parser.add_argument("--raw-body", help="Full JSON body to send as-is")
    exec_parser.add_argument("--refresh", action="store_true")
    exec_parser.set_defaults(func=cmd_execute)

    recipe_parser = subparsers.add_parser("recipe", help="Run a seeded composite recipe")
    recipe_parser.add_argument("name")
    recipe_parser.add_argument("--limit", type=int, default=50)
    recipe_parser.add_argument("--refresh", action="store_true")
    recipe_parser.set_defaults(func=cmd_recipe)

    return parser


def main():
    parser = build_parser()
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()

# Phase 4: Read Ops - Research

**Researched:** 2026-05-11
**Domain:** qbXML read operations on top of the Phase-3 engine (op abstraction + `company_info`, `get_company_preferences`, `report`, `list_*`, `get_transaction`, `run_query`) — .NET 8, pure in-process, tested against `FakeRequestProcessor`.
**Confidence:** HIGH for the op abstraction / compose pattern / DI / test approach (all derived directly from the in-repo Phase 1–3 code, which is authoritative). MEDIUM for the exact qbXML `*Rq` element names and child filters (training knowledge of the qbXML Onscreen Reference, corroborated by `.planning/research/FEATURES.md` and Intuit SDK sample files, but not byte-verified against spec 16.0 — same situation Phase 3 was in; the P&L fixture is already flagged for Phase-9 re-pinning and the new Phase-4 fixtures inherit that caveat). LOW for: whether there's a "default A/R / A/P account" *preference* element (there isn't a clean one — see Open Questions), and the exact `PreferencesRet` decimal-places field name.

## Summary

Phase 4 turns the Phase-3 qbXML engine into a set of callable read operations. Phase 3 already gave us everything heavy: `QbXmlBuilder.Rq(name, ...content)` + `BuildRequest(...)` (envelope + `<?qbxml version?>` PI), `QbConnectionManager.ExecuteAsync(xml, ct)` (the serialized COM round-trip), `QbXmlParser.Parse(raw)` → `ParsedQbXmlResponse{ Message, Elements:[ParsedElement{ Name, Status, IteratorId?, IteratorRemaining?, Rows:List<Dictionary<string,object?>> }], RawSpilledTo? }` (entity responses; polymorphic `Item*Ret` already collapsed to a `type` discriminator; `DataExtRet`→`customFields`), `QbReportParser.Parse(raw)` → `ParsedReport{ Title, Subtitle, Basis, Columns, Rows }` (header-aware report parse), and `QbListExecutor.RunAsync(queryRq, ownerIdZero?, ct)` → `ParsedQbXmlResponse` (drives the `Start`→`Continue` iterator loop, accumulates rows, mid-iteration-error abort, size-guard spill). Phase 4 builds the thin layer above: one interface, a base class to dedupe build→execute→parse→shape, and one class per op. **It does not touch HTTP, the `OpRegistry`, or any write path** — those are Phases 5/6/7.

The recommended abstraction is a single `IReadOp` with `string Name { get; }` and `Task<object?> RunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct)`, returning a plain serializable object (anonymous-ish `Dictionary<string,object?>` shapes plus the Phase-3 records, which already serialize cleanly). All ops are DI singletons registered as `IReadOp` (so Phase 5's `OpRegistry` is just `IEnumerable<IReadOp>` → `ToDictionary(o => o.Name)`). A small `ReadOpBase` provides three protected helpers: `QuerySingleAsync(XElement rq, ct)` (single-shot → `QbConnectionManager.ExecuteAsync` → `QbXmlParser.Parse`, throws on a per-element `Error` only if you ask it to — by default it returns the status), `QueryListAsync(XElement rq, bool? ownerIdZero, ct)` (→ `QbListExecutor.RunAsync`), and `QueryReportAsync(XElement rq, ct)` (→ `ExecuteAsync` → `QbReportParser.Parse`). New op classes live in `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/` namespace `QbConnectService.Qb.Ops` — consistent with Phase 3's files which sit directly in `Qb.Com/` under `namespace QbConnectService.Qb;` (note: the .csproj root namespace folds everything under `QbConnectService.Qb`; just put `Ops/` under it). Tests follow the existing pattern exactly: build a `FakeRequestProcessor`, `AddResponse("XxxQueryRq", <fixture>)`, wire a `QbConnectionManager` + `QbXmlBuilder` + `QbXmlParser`/`QbReportParser` + `QbListExecutor` (copy `CreateExecutor()` from `QbListExecutorTests`), call `op.RunAsync(args, default)`, assert the shaped result **and** assert the captured request via `fake.ProcessRequests` (the same `XDocument.Parse(...).Root!.Element("QBXMLMsgsRq")!.Element("...")!` trick the existing tests use).

**Primary recommendation:** One `IReadOp { Name; Task<object?> RunAsync(IReadOnlyDictionary<string,object?>, CancellationToken) }` + a `ReadOpBase` with `QuerySingleAsync`/`QueryListAsync`/`QueryReportAsync` helpers; one class per op in `Qb/Ops/`; `report` is **one** op taking `{ type, fromDate?, toDate?, dateMacro? }`; `run_query` is one op with a hard-coded read-only-entity whitelist; register all as `IReadOp` singletons in `Program.cs`. Build it in 8 atomic commits (one per op group + the scaffolding/DI bookends). Use **zero new NuGet packages** (System.Xml.Linq + the existing engine cover it), as Phases 1–3 did.

## Standard Stack

### Core (already present — Phase 4 adds no dependencies)
| Component | Where | Purpose | Phase 4 use |
|---|---|---|---|
| `QbXmlBuilder` | `Qb.Com/QbXmlBuilder.cs` | `static Rq(name, ...content)`, `static WithIterator`, `static WithOwnerIdZero`, `BuildRequest(XElement\|IEnumerable<XElement>)`, `.Version` | Every op builds its `*Rq` body with `QbXmlBuilder.Rq("XxxQueryRq", child1, child2, …)`; single-shot ops then call `BuildRequest(body)` |
| `QbConnectionManager` | `Qb.Com/QbConnectionManager.cs` | `Task<string> ExecuteAsync(xml, ct)` (serialized COM round-trip); `Task<string[]> GetSupportedQbXmlVersionsAsync(ct)` | Single-shot ops (`company_info`, `get_company_preferences`, `report`, `get_transaction`) call `ExecuteAsync` directly |
| `QbXmlParser` | `Qb.Com/QbXmlParser.cs` | `ParsedQbXmlResponse Parse(string)` — per-message + per-element `QbStatus`, `IteratorId`/`IteratorRemaining`, `Rows`; `Item*Ret`→`type`; `DataExtRet`→`customFields` | All entity ops shape `parsed.First.Rows` |
| `QbReportParser` | `Qb.Com/QbReportParser.cs` | `ParsedReport Parse(string)` — `ColDesc`-driven columns + `ColData`-by-`colID` rows | `report` op returns this |
| `QbListExecutor` | `Qb.Com/QbListExecutor.cs` | `Task<ParsedQbXmlResponse> RunAsync(XElement queryRq, bool? ownerIdZero=null, ct)` — `Start`→`Continue` iterator loop, accumulate, mid-iter abort, spill | `list_*` and `run_query` use this; **do not** call `WithIterator` yourself — `RunAsync` does it |
| `QbXmlOptions` | `Qb.Com/QbXmlOptions.cs` | `Version`, `OwnerIdZero`, `MaxReturned`, `MaxResponseBytes`, `SpillPath` | Inject `IOptions<QbXmlOptions>` if an op needs `MaxReturned` (most don't — `QbListExecutor` already reads it) |
| Phase-3 records | `Qb.Com/QbXmlModels.cs` | `QbStatus`, `ParsedElement`, `ParsedQbXmlResponse`, `ReportColumn`, `ReportRow`, `ParsedReport` | Returned (directly or wrapped) by ops; already JSON-serializable |
| `FakeRequestProcessor` | `Tests/Fakes/FakeRequestProcessor.cs` | `AddResponse(rqName, xml)` / `AddResponses(rqName, params…)` (FIFO queue) / `ProcessRequestHook` / `ProcessRequests` (captured raw requests) / records `LastAppId` etc. | The whole Phase-4 test substrate; **may add canned fixtures (in-scope — it's in the test project)** |
| `IReadOp` + `ReadOpBase` | **NEW** `Qb.Com/Qb/Ops/` | the op abstraction | see Architecture |

### Alternatives Considered
| Instead of | Could Use | Tradeoff — why not |
|---|---|---|
| One `IReadOp` for all 11+ ops | Three interfaces (`IReportOp`, `IEntityListOp`, `ILookupOp`) | Phase 5's `OpRegistry` wants to wrap them *uniformly* (one `/api/ops/{op}` dispatch). One interface + a base class that dedupes the three compose-shapes is simpler and still keeps the variation in one place. **Recommend one interface.** |
| `IReadOnlyDictionary<string,object?>` args | a typed `record` per op + a bind-from-dictionary helper | Phase 5 will deserialize a JSON request body. A `JsonElement`/dictionary is the lowest-friction handoff and keeps Phase 4 from over-committing to a binding scheme. Each op does its own arg extraction (`args.TryGetValue("activeStatus", out var v)`) with a tiny shared `ArgReader` helper for string/date/bool/enum coercion. **Recommend `IReadOnlyDictionary<string,object?>`** — typed records are a Phase-5 refinement if wanted. |
| `Task<object?>` return | `Task<JsonNode>` or a typed result per op | `object?` (Dictionary shapes + the Phase-3 records) round-trips through `System.Text.Json` fine and is the least ceremony. **Recommend `object?`.** A `record` per op result is a fine future tightening. |
| One `report` op taking `{type, …}` | Four ops (`report_pnl`, `report_balance_sheet`, `report_aging_ar`, `report_aging_ap`) | The spec and `READ-06` say "op: `report` … args: report type, date range (or date macro)" — one op. **Recommend one `report` op**, internal `switch` on `type` → the right `*ReportQueryRq` + `ReportType` value. |
| `run_query` builds `<{entity}QueryRq>` from arbitrary input | a fixed whitelist of read-only entity names | Without a whitelist `run_query` could build `CustomerDelRq` etc. (it only ever appends `QueryRq`, but defense-in-depth + a clear allowed set is the right call). **Recommend a hard-coded whitelist** (see `run_query` section). |

**Installation:** none. `dotnet build` / `dotnet test`, no new packages — matching Phases 1–3 (which each added zero NuGet packages).

## Architecture Patterns

### Recommended layout (under `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/`)
```
Qb.Com/
├── (existing Phase-3 files: QbXmlBuilder.cs, QbXmlParser.cs, QbReportParser.cs,
│    QbListExecutor.cs, QbConnectionManager.cs, QbXmlOptions.cs, QbXmlModels.cs, …)
└── Qb/
    └── Ops/
        ├── IReadOp.cs              # interface
        ├── ReadOpBase.cs          # build→execute→parse helpers; ArgReader nested or separate
        ├── ArgReader.cs           # (optional) string/date/bool/enum coercion over IReadOnlyDictionary
        ├── CompanyInfoOp.cs       # company_info
        ├── CompanyPreferencesOp.cs# get_company_preferences
        ├── ReportOp.cs            # report  (4 types)
        ├── ListCustomersOp.cs     # list_customers
        ├── ListVendorsOp.cs       # list_vendors
        ├── ListItemsOp.cs         # list_items   (polymorphic — relies on parser's `type`)
        ├── ListAccountsOp.cs      # list_accounts
        ├── ListInvoicesOp.cs      # list_invoices
        ├── ListBillsOp.cs         # list_bills
        ├── ListPaymentsOp.cs      # list_payments
        ├── GetTransactionOp.cs    # get_transaction  (by TxnID | by RefNumber)
        └── RunQueryOp.cs          # run_query  (whitelist + passthrough filters)
```
All `namespace QbConnectService.Qb.Ops;` (the .csproj's `<RootNamespace>QbConnectService.Qb</RootNamespace>` makes the folder `Ops/` map to `QbConnectService.Qb.Ops`). New test files under `QbConnectService.Tests/` (flat, like the others): `CompanyInfoOpTests.cs`, `CompanyPreferencesOpTests.cs`, `ReportOpTests.cs`, `ListEntityOpsTests.cs` (covers customers/vendors/items/accounts), `ListTransactionOpsTests.cs` (invoices/bills/payments), `GetTransactionOpTests.cs`, `RunQueryOpTests.cs`, plus an `OpRegistrationTests.cs` (host resolves all `IReadOp`s, names are unique).

### Pattern 1: `IReadOp`
```csharp
// Qb/Ops/IReadOp.cs   namespace QbConnectService.Qb.Ops;
public interface IReadOp
{
    string Name { get; }   // e.g. "company_info", "list_invoices" — Phase 5's OpRegistry key
    Task<object?> RunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct = default);
}
```

### Pattern 2: `ReadOpBase` — the three compose-shapes, deduped
```csharp
// Qb/Ops/ReadOpBase.cs
public abstract class ReadOpBase : IReadOp
{
    private readonly QbXmlBuilder _builder;
    private readonly QbConnectionManager _manager;
    private readonly QbXmlParser _xmlParser;
    private readonly QbReportParser _reportParser;
    private readonly QbListExecutor _listExecutor;

    protected ReadOpBase(QbXmlBuilder builder, QbConnectionManager manager,
        QbXmlParser xmlParser, QbReportParser reportParser, QbListExecutor listExecutor)
    { _builder = builder; _manager = manager; _xmlParser = xmlParser;
      _reportParser = reportParser; _listExecutor = listExecutor; }

    public abstract string Name { get; }
    public abstract Task<object?> RunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct = default);

    // single-shot entity query → parsed response (status surfaced, NOT thrown)
    protected async Task<ParsedQbXmlResponse> QuerySingleAsync(XElement rq, CancellationToken ct)
        => _xmlParser.Parse(await _manager.ExecuteAsync(_builder.BuildRequest(rq), ct));

    // iterator-driven list → parsed response (rows accumulated, spill handled)
    protected Task<ParsedQbXmlResponse> QueryListAsync(XElement rq, bool? ownerIdZero, CancellationToken ct)
        => _listExecutor.RunAsync(rq, ownerIdZero, ct);

    // single-shot report → ParsedReport
    protected async Task<ParsedReport> QueryReportAsync(XElement rq, CancellationToken ct)
        => _reportParser.Parse(await _manager.ExecuteAsync(_builder.BuildRequest(rq), ct));

    // shared result envelope for entity ops: surface status + spilled-file ref + rows
    protected static object ListResult(ParsedQbXmlResponse r) => new Dictionary<string, object?>
    {
        ["status"] = r.First.Status,                 // QbStatus{ Code, Severity, Message } — JSON-friendly
        ["rows"]   = r.First.Rows,
        ["count"]  = r.First.Rows.Count,
        ["rawSpilledTo"] = r.RawSpilledTo,
    };
}
```
**Status handling rule (matches `READ-01`):** a per-element `Error` (e.g. fixture `InvoiceAddRs.error.qbxml` style — `statusCode != 0`, `statusSeverity="Error"`) is **surfaced in the result body** (`status.severity == "Error"`), not thrown. A zero-row result (`statusCode="1"` "no matching") is **success** — `QbXmlParser` already does this; the op just returns `rows: []`. Ops only let exceptions propagate for *transport/COM* failures (`QbException`/`QbBusyException`/`QbTimeoutException` from `QbConnectionManager` — Phase 5 maps those to 4xx/5xx, not Phase 4's concern). This is the behavior research-question 7's "an op that gets a per-element `Error` status → surfaces it (doesn't throw a raw exception)" requires.

### Pattern 3: how a list op composes (`list_customers`)
```csharp
public sealed class ListCustomersOp(QbXmlBuilder b, QbConnectionManager m, QbXmlParser xp,
    QbReportParser rp, QbListExecutor le) : ReadOpBase(b, m, xp, rp, le)
{
    public override string Name => "list_customers";
    public override async Task<object?> RunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct)
    {
        var rq = QbXmlBuilder.Rq("CustomerQueryRq");
        // ActiveStatus filter: "ActiveOnly" | "InactiveOnly" | "All" (qbXML enum) — default "All"
        var active = ArgReader.String(args, "activeStatus") ?? "All";   // accept "Active"/"Inactive" too → normalize
        rq.Add(new XElement("ActiveStatus", NormalizeActiveStatus(active)));   // ActiveOnly|InactiveOnly|All
        // name filter: NameFilter { MatchCriterion, Name }   (StartsWith|Contains|EndsWith) — default Contains
        if (ArgReader.String(args, "name") is { Length: > 0 } name)
            rq.Add(new XElement("NameFilter",
                new XElement("MatchCriterion", ArgReader.String(args, "nameMatch") ?? "Contains"),
                new XElement("Name", name)));
        // NOTE: do NOT add MaxReturned / iterator attrs — QbListExecutor.RunAsync does that.
        var parsed = await QueryListAsync(rq, ownerIdZero: null /* use QbXmlOptions.OwnerIdZero */, ct);
        return ListResult(parsed);
    }
}
```
`list_vendors` = `VendorQueryRq`, same `ActiveStatus`/`NameFilter`. `list_accounts` = `AccountQueryRq`, same `ActiveStatus`; name filter via `FullNameWithChildren` is awkward — for v1 keep just `ActiveStatus` + an optional `NameFilter` (Account also supports it) and optionally an `AccountType` passthrough. `list_items` = `ItemQueryRq`, same `ActiveStatus`/`NameFilter`; **no extra work for polymorphism** — `QbXmlParser` already collapses `ItemServiceRet`/`ItemInventoryRet`/… into one `type` discriminator key per row (`type` ∈ `"Service"`,`"Inventory"`,`"NonInventory"`,`"InventoryAssembly"`,`"FixedAsset"`,`"OtherCharge"`,`"Subtotal"`,`"Discount"`,`"Payment"`,`"SalesTax"`,`"SalesTaxGroup"`,`"Group"`). Tests assert `rows[0]["type"]` and `rows[1]["type"]` against `ItemQueryRs.polymorphic.qbxml` (already exists) — add `ItemQueryRs.normal.qbxml` only if you want a single-type case.

### Pattern 4: how a single-shot op composes (`company_info`)
```csharp
public sealed class CompanyInfoOp(…) : ReadOpBase(…)
{
    public override string Name => "company_info";
    public override async Task<object?> RunAsync(IReadOnlyDictionary<string, object?> _, CancellationToken ct)
    {
        var parsed = await QuerySingleAsync(QbXmlBuilder.Rq("CompanyQueryRq"), ct);
        var co = parsed.First.Rows.FirstOrDefault() ?? new();   // CompanyRet → already a Dictionary
        return new Dictionary<string, object?>
        {
            ["status"]            = parsed.First.Status,
            ["companyName"]       = co.GetValueOrDefault("CompanyName"),
            ["legalCompanyName"]  = co.GetValueOrDefault("LegalCompanyName"),
            ["address"]           = co.GetValueOrDefault("Address"),          // {Addr1..Addr5,City,State,PostalCode,Country}
            ["legalAddress"]      = co.GetValueOrDefault("LegalAddress"),
            ["phone"]             = co.GetValueOrDefault("Phone"),
            ["email"]             = co.GetValueOrDefault("Email"),
            ["fiscalYearStartMonth"]   = co.GetValueOrDefault("FirstMonthFiscalYear"),     // qbXML: month name
            ["incomeTaxYearStartMonth"]= co.GetValueOrDefault("FirstMonthIncomeTaxYear"),
            ["taxForm"]           = co.GetValueOrDefault("TaxForm"),
            ["edition"]           = ExtractEdition(co),     // see below
            ["companyType"]       = co.GetValueOrDefault("CompanyType"),
            ["rawCompanyRet"]     = co,                     // keep the full thing for the agent's fallback
        };
    }
}
```
**Edition detail:** `CompanyRet` does **not** carry the QuickBooks edition string directly. Two options: (a) `CompanyRet/SubscribedServices` and the `IsSampleCompany` flag give *some* signal but not the edition name; (b) the proper source is `HostQueryRq` → `HostRet` (`ProductName` = e.g. "QuickBooks Enterprise Solutions: Manufacturing and Wholesale 24.0", `MajorVersion`, `MinorVersion`, `Country`, `SupportedQBXMLVersionList`). **Recommendation:** `company_info` should also fire `HostQueryRq` (cheap — can be the same request message: `BuildRequest(new[]{ Rq("HostQueryRq"), Rq("CompanyQueryRq") })`, then `parsed.Elements` has both `HostQueryRs` and `CompanyQueryRs`) and put `HostRet.ProductName`/version/country under an `edition`/`host` key. (`READ-04` literally asks for "QuickBooks edition" — `HostRet.ProductName` is it. Note Phase 5's `/api/health` will *also* call `HostQueryRq` for supported-versions — that's fine, separate concern.) Fixture: `HostCompanyQueryRs.qbxml` (one message, both `*Rs` elements) — **constructed; flag for Phase-9 re-pin** (the `ProductName` string format varies by edition/year).

### Anti-Patterns to Avoid
- **Re-implementing the iterator loop in list ops.** `QbListExecutor.RunAsync` already does `Start`→`Continue`, accumulation, mid-iter-error abort, and spill. List ops just build the bare `<XxxQueryRq>` (with filters) and hand it to `QueryListAsync`. Adding `MaxReturned`/`iterator` attrs in the op would double them up. (`QbListExecutor` copies the element before mutating, so a bare `Rq(...)` is correct input.)
- **Throwing on a `statusCode != 0` element.** `READ-01` is explicit: surface `statusCode`/`statusSeverity`/`statusMessage`; zero-row is success. Phase 5 returns `statusCode != 0` as a normal `200` body (`API-06`). Phase 4 ops must return the status in the body, never throw it.
- **Calling `QbReportParser.Parse` through `QbListExecutor`.** Reports don't support iterators (`READ-02`/`READ-03`). The `report` op is a single-shot `ExecuteAsync` + `QbReportParser.Parse` — never goes through `QbListExecutor`.
- **Letting `run_query` build arbitrary `*Rq` element names.** Whitelist the entity, then append exactly `"QueryRq"`. Never accept a full request name from the caller.
- **A typed-`record`-per-op-args binding scheme in Phase 4.** Phase 5 owns JSON→args; keep Phase 4 args as `IReadOnlyDictionary<string,object?>` so there's no premature coupling. (A `Phase5` improvement note for the planner: when Phase 5 wires `/api/ops/{op}`, it can deserialize the JSON body to `Dictionary<string,object?>` via `System.Text.Json` and pass straight through.)
- **Hard-coding the qbXML version in the op.** It's already in `QbXmlOptions.Version` and `QbXmlBuilder.BuildRequest` emits the PI. Ops never deal with the PI.

## Don't Hand-Roll

| Problem | Don't build | Use instead | Why |
|---|---|---|---|
| qbXML envelope / `<?qbxml version?>` PI | string concat or a new builder | `QbXmlBuilder.Rq(...)` + `BuildRequest(...)` | Phase 3 already does it with `XDocument` (escaping, encoding, `onError="stopOnError"`) |
| Iterator paging for `list_*` / `run_query` | `iterator="Start"`/`Continue` loop | `QbListExecutor.RunAsync(rq, …)` | Phase 3's `QbListExecutor` does Start→Continue, accumulation, mid-iter abort, size-guard spill — tested |
| Report `ColDesc`/`ColData` reconstruction | parse `ReportData` yourself | `QbReportParser.Parse(raw)` → `ParsedReport` | Phase 3's separate report parser is exactly for this; the `report` op just returns it |
| Polymorphic `Item*Ret` normalization | branch on element name | nothing — `QbXmlParser` already emits `type` per item row | `QbXmlParser.ItemRetNames` + the `["type"] = …["Item".Length..^"Ret".Length]` slice already do it |
| `DataExtRet` (custom fields) | parse `DataExtRet` blocks | nothing — parser emits `customFields` list per row when `OwnerID="0"` was sent | `QbXmlOptions.OwnerIdZero` config + `QbXmlBuilder.WithOwnerIdZero` + parser's `MapDataExt` |
| Per-call serialization / dead-ticket retry / timeout | any of it | `QbConnectionManager.ExecuteAsync` | Phase 2 owns the COM state machine, gate, watchdog, retry-once |
| The op catalog/dispatch table | a `Dictionary<string,IReadOp>` | **don't** — that's Phase 5's `OpRegistry` | Phase 4 only registers `IReadOp` singletons in DI; Phase 5 collects `IEnumerable<IReadOp>` |
| Test request-capture | a custom recording processor | `FakeRequestProcessor.ProcessRequests` + `AddResponse`/`AddResponses` | Already in the test project; `QbListExecutorTests` shows the exact assertion pattern |

**Key insight:** Phase 3 was deliberately built so that "a read op" is ≈ 20–40 lines: build an `XElement` body with the right filters, hand it to one of three engine entry points, shape the result into a `Dictionary`. If a Phase-4 op is doing XML plumbing or iterator bookkeeping, it's wrong.

## Common Pitfalls

### Pitfall 1: `report` op date-arg validation
**What goes wrong:** Caller passes both `dateMacro` and `fromDate`/`toDate`, or neither, or only `fromDate`. qbXML rejects a `*ReportQueryRq` that has both a `ReportDateMacro` *and* a `ReportPeriod`, and a `ReportPeriod` needs both `FromReportDate` and `ToReportDate`.
**How to avoid:** Validate before building: exactly one of (`fromDate` AND `toDate`) **or** (`dateMacro`) — else throw `ArgumentException` (Phase 5 → 400; for Phase 4, an `ArgumentException` from `RunAsync` is fine, document it). Aging reports use `ReportPeriod`/`ReportAgingAsOf` differently (see `report` section) — the op's `switch` picks the right element set per `type`.
**Warning signs:** Test that passes `{type:"ProfitAndLoss"}` with no dates should throw; with both → throw; with `dateMacro:"ThisMonth"` → builds `<ReportDateMacro>ThisMonth</ReportDateMacro>`; with `fromDate`/`toDate` → builds `<ReportPeriod><FromReportDate>…</FromReportDate><ToReportDate>…</ToReportDate></ReportPeriod>`.

### Pitfall 2: `get_transaction` assumes `RefNumber` is unique
**What goes wrong:** `RefNumber` is editable and non-unique (repeats across years/types). Looking up by `RefNumber` can return >1 row. Code that does `rows.Single()` blows up.
**How to avoid:** `get_transaction` always returns a `{ matches: [...], count: N, ambiguous: count > 1 }` shape (a list, even for `TxnID` which is exact). `QbXmlParser.Parse(...).First.Rows` is already a list — just don't collapse it. When `ambiguous`, set a flag so the agent/skill can disambiguate.
**Warning signs:** Test with two `TransactionRet` rows sharing a `RefNumber` → `count == 2`, `ambiguous == true`.

### Pitfall 3: `get_transaction` returns "lite" `TransactionRet`, not full lines
**What goes wrong:** Caller expects line items; `TransactionQueryRq` → `TransactionRet` is header-only-ish (`TxnID`, `TxnType`, `TxnDate`, `RefNumber`, `Entity`, `Account`, `Amount`, `IsPending`, `Currency`, plus a couple). It does **not** return invoice lines.
**How to avoid (recommended v1 design):** `get_transaction` does a **single** `TransactionQueryRq` (with `TxnIDList` or `RefNumberList`/`RefNumberFilter`) and returns the lite `TransactionRet` rows. Document that for full detail (lines) the caller uses `list_invoices`/`list_bills`/`list_payments` (which can take an entity/date filter narrow enough to find it) or, in v1.x, a type-specific follow-up. **Do not** build the two-step (look up type → fire `InvoiceQueryRq` by TxnID) in Phase 4 — it's spec-creep; `READ-09` only asks for "looks up a transaction by `TxnID` or `RefNumber`". A `_lite: true` marker in the result makes the limitation explicit.
**Warning signs:** Result includes a `lite: true` flag; doc-comment on the op explains the follow-up path.

### Pitfall 4: `ActiveStatus` default — Active vs All
**What goes wrong:** Defaulting `list_*` to `ActiveOnly` silently hides inactive customers/items the agent may legitimately need; defaulting to `All` returns clutter.
**How to avoid:** Default `ActiveStatus` = **`All`** (the agent is doing exploratory reads and an inactive entity is still a valid reference target), and *always* emit the element explicitly so the request is unambiguous and easy to assert in tests. Accept caller values `"Active"`/`"Inactive"`/`"All"` (friendly) and normalize to qbXML's `"ActiveOnly"`/`"InactiveOnly"`/`"All"`. (Note: qbXML's actual enum is `ActiveOnly` | `InactiveOnly` | `All` — get this right; a wrong enum value is a `statusCode 3100`-ish error.)
**Warning signs:** Test asserts `<ActiveStatus>All</ActiveStatus>` is in the captured request by default; passing `activeStatus:"Active"` → `<ActiveStatus>ActiveOnly</ActiveStatus>`.

### Pitfall 5: `run_query` whitelist drift / verb safety
**What goes wrong:** Allowing an arbitrary entity name lets a caller reach `<HostQueryRq>` (harmless) or, if the suffix were ever caller-controlled, a write. Also some entities have *no* `*QueryRq` (`DataExtDef`, etc.) → `statusCode` error that looks like our bug.
**How to avoid:** Hard-code an allow-list of entities that (a) have a `*QueryRq` and (b) are reads, and *always* build `entity + "QueryRq"` from that vetted name. Reject anything else with `ArgumentException("entity 'X' is not allowed for run_query; allowed: …")`. Pass `filters` through as child elements (each `{key: value}` → `<key>value</key>`; nested objects → nested elements) — but **only** simple element construction, no attributes from caller input, no raw XML strings. Document the whitelist in the op's XML-doc and the eventual skill cheatsheet.
**Warning signs:** Test: `run_query{entity:"Employee", filters:{ActiveStatus:"ActiveOnly"}}` → builds `<EmployeeQueryRq><ActiveStatus>ActiveOnly</ActiveStatus></EmployeeQueryRq>` (through `QbListExecutor`, so it'll also get `MaxReturned`/iterator); `run_query{entity:"CustomerDel"}` → throws; `run_query{entity:"Banana"}` → throws.

### Pitfall 6: forgetting `run_query` and `list_*` go through the iterator
**What goes wrong:** A `run_query` test that `AddResponse`s a single `EmployeeQueryRs` with `iteratorRemainingCount="0"` is fine, but if you accidentally `AddResponses` (queue) a second page that never gets consumed (because remaining=0) the test passes for the wrong reason; conversely if your fixture omits `iteratorRemainingCount` the executor treats it as 0 (`int.TryParse` fails → `null` → `?? 0`) which is the right default but worth knowing.
**How to avoid:** Use `AddResponse` (single) for the simple-case fixtures; only use `AddResponses` (queue) when deliberately testing multi-page (copy `CustomerQueryRs.page1/page2.qbxml` style). Each list/`run_query` test should assert `fake.ProcessRequests.Count == 1` for the single-page case + that the request has `iterator="Start"`.

## Code Examples

### `get_company_preferences` (READ-05)
```csharp
public sealed class CompanyPreferencesOp(…) : ReadOpBase(…)
{
    public override string Name => "get_company_preferences";
    public override async Task<object?> RunAsync(IReadOnlyDictionary<string, object?> _, CancellationToken ct)
    {
        var parsed = await QuerySingleAsync(QbXmlBuilder.Rq("PreferencesQueryRq"), ct);
        var p = parsed.First.Rows.FirstOrDefault() ?? new();   // PreferencesRet → nested Dictionary
        var salesTax = AsDict(p.GetValueOrDefault("SalesTaxPreferences"));
        var accounting = AsDict(p.GetValueOrDefault("AccountingPreferences"));
        var multiCcy = AsDict(p.GetValueOrDefault("MultiCurrencyPreferences"));
        var purchases = AsDict(p.GetValueOrDefault("PurchasesAndVendorsPreferences"));
        return new Dictionary<string, object?>
        {
            ["status"]            = parsed.First.Status,
            ["salesTaxEnabled"]   = salesTax is not null,                 // block present ⇔ sales tax on
            ["defaultItemSalesTaxRef"] = salesTax?.GetValueOrDefault("DefaultItemSalesTaxRef"),
            ["paySalesTax"]       = salesTax?.GetValueOrDefault("IsPaySalesTax") ?? salesTax?.GetValueOrDefault("PaySalesTax"),
            ["multiCurrencyEnabled"] = (multiCcy?.GetValueOrDefault("IsMultiCurrencyOn") as string)?.Equals("true", StringComparison.OrdinalIgnoreCase) ?? false,
            ["homeCurrencyRef"]   = multiCcy?.GetValueOrDefault("HomeCurrencyRef"),
            ["decimalPlaces"]     = ItemsAndInventoryDecimalPlaces(p),    // see Open Questions — may live in ItemsAndInventoryPreferences
            ["classTrackingOn"]   = (accounting?.GetValueOrDefault("IsUsingClassTracking") as string)?.Equals("true", StringComparison.OrdinalIgnoreCase),
            ["assignClassesTo"]   = accounting?.GetValueOrDefault("AssignClassesTo"),
            ["requireAccounts"]   = accounting?.GetValueOrDefault("IsRequiringAccounts"),
            ["useAccountNumbers"] = accounting?.GetValueOrDefault("IsUsingAccountNumbers"),
            ["defaultDiscountAccountRef"] = purchases?.GetValueOrDefault("DefaultDiscountAccountRef"),
            // NOTE: there is no clean "default A/R / default A/P account" preference element (see Open Questions).
            // For READ-05's "default A/R and A/P accounts" we surface what's available and document the gap;
            // a follow-up AccountQueryRq filtered to AccountType=AccountsReceivable/AccountsPayable can list them.
            ["rawPreferencesRet"] = p,
        };
    }
}
```
**Constructed fixture:** `PreferencesQueryRs.qbxml` — flag for Phase-9 re-pin (the exact set of present preference blocks and the multi-currency block's presence depend on the company file's configuration; the field names `IsMultiCurrencyOn`, `IsUsingClassTracking`, `DefaultItemSalesTaxRef` are from training knowledge of the qbXML OSR — verify against the live `10.120.254.13` file).

### `report` op (READ-06) — one op, four `type`s
```csharp
public sealed class ReportOp(…) : ReadOpBase(…)
{
    public override string Name => "report";
    public override async Task<object?> RunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct)
    {
        var type = ArgReader.String(args, "type") ?? throw new ArgumentException("report: 'type' is required.");
        var from = ArgReader.Date(args, "fromDate");   // accepts "YYYY-MM-DD"
        var to   = ArgReader.Date(args, "toDate");
        var macro = ArgReader.String(args, "dateMacro");
        bool hasRange = from is not null && to is not null;
        if (hasRange == (macro is not null) || (from is not null) != (to is not null))
            throw new ArgumentException("report: supply exactly one of (fromDate+toDate) or dateMacro.");

        XElement dateChild = macro is not null
            ? new XElement("ReportDateMacro", macro)
            : new XElement("ReportPeriod",
                new XElement("FromReportDate", from!.Value.ToString("yyyy-MM-dd")),
                new XElement("ToReportDate",   to!.Value.ToString("yyyy-MM-dd")));

        XElement rq = type switch
        {
            "ProfitAndLoss" => QbXmlBuilder.Rq("GeneralSummaryReportQueryRq",
                                  new XElement("GeneralSummaryReportType", "ProfitAndLossStandard"), dateChild),
            "BalanceSheet"  => QbXmlBuilder.Rq("GeneralSummaryReportQueryRq",
                                  new XElement("GeneralSummaryReportType", "BalanceSheetStandard"), dateChild),
            "AgingAR"       => QbXmlBuilder.Rq("AgingReportQueryRq",
                                  new XElement("AgingReportType", "ARAgingSummary"), dateChild),  // see note on date element for aging
            "AgingAP"       => QbXmlBuilder.Rq("AgingReportQueryRq",
                                  new XElement("AgingReportType", "APAgingSummary"), dateChild),
            _ => throw new ArgumentException($"report: unknown type '{type}' (ProfitAndLoss|BalanceSheet|AgingAR|AgingAP).")
        };
        var report = await QueryReportAsync(rq, ct);
        return new Dictionary<string, object?> { ["type"] = type, ["report"] = report };  // report = ParsedReport
    }
}
```
**Verified shape (Intuit SDK sample `xmlfiles/legacy/CustomDetailReport.xml`):** a report query is `<{Report}QueryRq><{Report}Type>…</{Report}Type><ReportDateMacro>ThisMonth</ReportDateMacro></{Report}QueryRq>` — i.e. the `*Type` element first, then either `<ReportDateMacro>VALUE</ReportDateMacro>` **or** `<ReportPeriod><FromReportDate>YYYY-MM-DD</FromReportDate><ToReportDate>YYYY-MM-DD</ToReportDate></ReportPeriod>`. (Sample used `CustomDetailReportQueryRq`/`CustomDetailReportType=CustomTxnDetail`; the same envelope shape applies to `GeneralSummaryReportQueryRq`/`GeneralDetailReportQueryRq`/`AgingReportQueryRq`.) **MEDIUM confidence on the enum values** `ProfitAndLoss­Standard`, `BalanceSheet­Standard`, `ARAgingSummary`, `APAgingSummary` (training knowledge of the qbXML OSR; `.planning/research/FEATURES.md` line 25 corroborates these exact spellings). **Open detail:** aging reports historically take a `ReportPeriod`/`ReportAgingAsOf` (an "as-of" date) rather than a from/to range — for v1, accept the same `dateMacro`/`fromDate`+`toDate` args and, for `AgingAR`/`AgingAP`, if a single anchor date is wanted use `toDate` as the as-of (or just pass `<ReportDateMacro>Today</ReportDateMacro>`); the planner should note "confirm `AgingReportQueryRq`'s date element name (`ReportPeriod` vs `ReportAgingAsOf`) and whether it wants a range or an as-of date when re-pinning fixtures in Phase 9." `DisplayReport` element: not needed (it controls whether QB pops the report UI — irrelevant for headless). **Constructed fixtures (flag for Phase-9 re-pin):** reuse the existing `GeneralSummaryReportQueryRs.pnl.qbxml`; add `GeneralSummaryReportQueryRs.balancesheet.qbxml`, `AgingReportQueryRs.ar.qbxml`, `AgingReportQueryRs.ap.qbxml` (same `ReportRet`/`ColDesc`/`ReportData` shape — note `QbReportParser` already handles `*ReportQueryRs` suffix-matching, so `AgingReportQueryRs` parses fine).

`ReportDateMacro` enum (MEDIUM — training/OSR; subset of the common ones for the doc/skill): `All`, `Today`, `ThisWeek`, `ThisWeekToDate`, `ThisMonth`, `ThisMonthToDate`, `ThisCalendarQuarter`, `ThisCalendarQuarterToDate`, `ThisFiscalQuarter`, `ThisFiscalQuarterToDate`, `ThisCalendarYear`, `ThisCalendarYearToDate`, `ThisFiscalYear`, `ThisFiscalYearToDate`, `Yesterday`, `LastWeek`, `LastWeekToDate`, `LastMonth`, `LastMonthToDate`, `LastCalendarQuarter`, `LastCalendarQuarterToDate`, `LastFiscalQuarter`, `LastFiscalQuarterToDate`, `LastCalendarYear`, `LastCalendarYearToDate`, `LastFiscalYear`, `LastFiscalYearToDate`, `NextWeek`, `NextMonth`, `NextFiscalQuarter`, `NextFiscalYear`, etc. v1: don't validate the macro string against this list (forwarding QB's error is fine) — just document the common ones.

### `list_invoices` / `list_bills` / `list_payments` (READ-08)
```csharp
public sealed class ListInvoicesOp(…) : ReadOpBase(…)
{
    public override string Name => "list_invoices";
    public override async Task<object?> RunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct)
    {
        var rq = QbXmlBuilder.Rq("InvoiceQueryRq");
        // date range filter
        var from = ArgReader.Date(args, "fromDate"); var to = ArgReader.Date(args, "toDate");
        var dateMacro = ArgReader.String(args, "dateMacro");
        if (from is not null || to is not null || dateMacro is not null)
        {
            var f = new XElement("TxnDateRangeFilter");
            if (dateMacro is not null) f.Add(new XElement("DateMacro", dateMacro));
            else { if (from is not null) f.Add(new XElement("FromTxnDate", from.Value.ToString("yyyy-MM-dd")));
                   if (to   is not null) f.Add(new XElement("ToTxnDate",   to.Value.ToString("yyyy-MM-dd"))); }
            rq.Add(f);
        }
        // entity filter (customer for invoices/payments; vendor for bills)
        if (ArgReader.String(args, "entity") is { Length: >0 } entity)
            rq.Add(new XElement("EntityFilter", new XElement("FullNameList", new XElement("FullName", entity))));
        // header-only is the qbXML default for *QueryRq; an `includeLineItems:true` arg → <IncludeLineItems>true</IncludeLineItems>
        if (ArgReader.Bool(args, "includeLineItems") == true) rq.Add(new XElement("IncludeLineItems", "true"));
        var parsed = await QueryListAsync(rq, ownerIdZero: null, ct);
        return ListResult(parsed);
    }
}
```
`list_bills` = `BillQueryRq` (entity = vendor; `EntityFilter/FullNameList/FullName`); `list_payments` = `ReceivePaymentQueryRq` (entity = customer). All take `TxnDateRangeFilter` (`FromTxnDate`/`ToTxnDate` or a `DateMacro`) + optional `EntityFilter`. **MEDIUM confidence on `IncludeLineItems`** (training/OSR — `*QueryRq` element to opt into line detail; default off). **Constructed fixtures (flag for re-pin):** `InvoiceQueryRs.qbxml`, `BillQueryRs.qbxml`, `ReceivePaymentQueryRs.qbxml` (a couple of `InvoiceRet`/`BillRet`/`ReceivePaymentRet` rows with `TxnID`, `TxnDate`, `RefNumber`, `CustomerRef`/`VendorRef`, `BalanceRemaining`/`AmountDue`/`TotalAmount`).

### `get_transaction` (READ-09)
```csharp
public sealed class GetTransactionOp(…) : ReadOpBase(…)
{
    public override string Name => "get_transaction";
    public override async Task<object?> RunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct)
    {
        var txnId = ArgReader.String(args, "txnId");
        var refNo = ArgReader.String(args, "refNumber");
        if ((txnId is null) == (refNo is null))
            throw new ArgumentException("get_transaction: supply exactly one of txnId or refNumber.");
        var rq = QbXmlBuilder.Rq("TransactionQueryRq",
            txnId is not null
                ? new XElement("TxnIDList", new XElement("TxnID", txnId))
                : new XElement("RefNumberFilter", new XElement("MatchCriterion", "Equals"), new XElement("RefNumber", refNo)));
        // optional: narrow by TxnType ("Invoice","Bill","ReceivePayment","Check","JournalEntry",...) via <TransactionTypeList><TxnType>...</TxnType></TransactionTypeList>
        if (ArgReader.String(args, "txnType") is { Length: >0 } tt)
            rq.Add(new XElement("TransactionTypeList", new XElement("TxnType", tt)));
        var parsed = await QuerySingleAsync(rq, ct);   // TransactionQuery does NOT support iterators in practice for our use; single-shot is fine
        var rows = parsed.First.Rows;
        return new Dictionary<string, object?>
        {
            ["status"]    = parsed.First.Status,
            ["matches"]   = rows,
            ["count"]     = rows.Count,
            ["ambiguous"] = txnId is null && rows.Count > 1,   // RefNumber is non-unique
            ["lite"]      = true,   // TransactionRet is header-level only; use list_invoices/bills/payments for lines
        };
    }
}
```
**Notes:** `TransactionQueryRq` *does* support iterators in the spec; for `get_transaction` (a point lookup, expected to return 0–few rows) a single `ExecuteAsync` is appropriate and keeps the op simple — if you'd rather be safe, route it through `QueryListAsync` instead (harmless; `QbListExecutor` handles a single page fine). `RefNumberFilter` with `MatchCriterion=Equals` finds all txns whose ref equals the value (across types unless narrowed by `TransactionTypeList`). `RefNumberList` (`<RefNumberList><RefNumber>123</RefNumber></RefNumberList>`) is the exact-match alternative — either works; `RefNumberFilter`+`Equals` is what the OSR examples use. **MEDIUM confidence** on `TxnIDList`/`RefNumberFilter`/`TransactionTypeList` element names (training/OSR; `.planning/research/FEATURES.md` line 29 corroborates the design ("a `TransactionQuery` (generic, all txn types) is a nice superset")). **Constructed fixtures (flag for re-pin):** `TransactionQueryRs.byid.qbxml` (one `TransactionRet` with the lookup `TxnID`), `TransactionQueryRs.byref.multi.qbxml` (two `TransactionRet` rows sharing a `RefNumber`).

### `run_query` (READ-10)
```csharp
public sealed class RunQueryOp(…) : ReadOpBase(…)
{
    // read-only entities that have a *QueryRq; v1 whitelist (extend as needed — V2-01 promotes some to first-class ops)
    private static readonly HashSet<string> Allowed = new(StringComparer.Ordinal)
    {
        "Employee", "OtherName", "SalesRep", "Class", "Term", "PriceLevel", "PaymentMethod",
        "ShipMethod", "Currency", "DateDrivenTerms", "StandardTerms", "SalesTaxCode", "Vehicle",
        "SalesReceipt", "Estimate", "PurchaseOrder", "CreditMemo", "SalesOrder", "Deposit",
        "Check", "BillPaymentCheck", "BillPaymentCreditCard", "CreditCardCharge", "CreditCardCredit",
        "JournalEntry", "InventoryAdjustment", "TimeTracking", "VendorCredit", "ItemReceipt",
        "Customer", "Vendor", "Item", "Account", "Invoice", "Bill", "ReceivePayment", "Transaction",
        "ToDo", "Company", "Host", "Preferences", "DataExtDef", "TxnDisplayMod" /* etc — keep curated */
    };
    public override string Name => "run_query";
    public override async Task<object?> RunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct)
    {
        var entity = ArgReader.String(args, "entity") ?? throw new ArgumentException("run_query: 'entity' is required.");
        if (!Allowed.Contains(entity))
            throw new ArgumentException($"run_query: entity '{entity}' is not allowed. Allowed: {string.Join(", ", Allowed.OrderBy(x=>x))}");
        var rq = QbXmlBuilder.Rq(entity + "QueryRq");
        if (args.TryGetValue("filters", out var filtersObj) && filtersObj is IReadOnlyDictionary<string, object?> filters)
            AddFilters(rq, filters);   // simple {key:value}->{<key>value</key>}; nested dict -> nested element; list -> repeated element; NO attributes, NO raw XML
        // Company/Host/Preferences don't support iterators — route those through QuerySingleAsync; everything else through QueryListAsync
        var noIter = entity is "Company" or "Host" or "Preferences";
        var parsed = noIter ? await QuerySingleAsync(rq, ct) : await QueryListAsync(rq, ownerIdZero: null, ct);
        return ListResult(parsed) is Dictionary<string,object?> d ? d.Append(new("entity", (object?)entity)).ToDictionary(k=>k.Key, v=>v.Value) : (object?)null;
    }
}
```
(Trim the whitelist as the planner sees fit — the *important* contract is "vetted set, append `QueryRq`, never accept a raw request name". `.planning/research/FEATURES.md` line 50 lists the expected v1 set: `EmployeeQuery`, `OtherNameQuery`, `SalesReceiptQuery`, `EstimateQuery`, `PurchaseOrderQuery`, `CreditMemoQuery`, `DepositQuery`, `ClassQuery`.) **Constructed fixture (flag for re-pin):** `EmployeeQueryRs.qbxml` (one or two `EmployeeRet` rows).

### Test pattern (mirrors `QbListExecutorTests`)
```csharp
public sealed class ListEntityOpsTests
{
    [Fact]
    public async Task list_customers_returns_rows_and_applies_filters()
    {
        var (fake, manager, ops) = CreateOps();           // copy CreateExecutor() + build the op
        fake.AddResponse("CustomerQueryRq", Fixture("CustomerQueryRs.normal.qbxml"));
        try
        {
            var result = (Dictionary<string,object?>)(await ops["list_customers"]
                .RunAsync(new Dictionary<string,object?>{ ["activeStatus"]="Active", ["name"]="Acme" }, default))!;
            var rows = (List<Dictionary<string,object?>>)result["rows"]!;
            Assert.Equal(2, rows.Count);
            Assert.Equal("Acme Roofing", rows[0]["FullName"]);
            // assert the request was built right
            var rq = XDocument.Parse(fake.ProcessRequests[0]).Root!.Element("QBXMLMsgsRq")!.Element("CustomerQueryRq")!;
            Assert.Equal("ActiveOnly", rq.Element("ActiveStatus")!.Value);
            Assert.Equal("Acme", rq.Element("NameFilter")!.Element("Name")!.Value);
            Assert.Equal("Start", rq.Attribute("iterator")?.Value);     // QbListExecutor added it
            Assert.Single(fake.ProcessRequests);
        }
        finally { await manager.DisposeAsync(); }
    }
}
```
**Helper:** factor `CreateOps()` (returns `(FakeRequestProcessor, QbConnectionManager, Dictionary<string,IReadOp>)`) into a small shared test-base/static so all op tests reuse it — it's the `CreateExecutor()` from `QbListExecutorTests` plus building the ops with the same `QbXmlBuilder`/`QbXmlParser`/`QbReportParser`/`QbListExecutor` instances.

### DI registration (`Program.cs` — add after the Phase-3 lines)
```csharp
// Phase 4: read ops (each registered as IReadOp so Phase 5's OpRegistry is `IEnumerable<IReadOp>` → dictionary by Name)
builder.Services.AddSingleton<IReadOp, CompanyInfoOp>();
builder.Services.AddSingleton<IReadOp, CompanyPreferencesOp>();
builder.Services.AddSingleton<IReadOp, ReportOp>();
builder.Services.AddSingleton<IReadOp, ListCustomersOp>();
builder.Services.AddSingleton<IReadOp, ListVendorsOp>();
builder.Services.AddSingleton<IReadOp, ListItemsOp>();
builder.Services.AddSingleton<IReadOp, ListAccountsOp>();
builder.Services.AddSingleton<IReadOp, ListInvoicesOp>();
builder.Services.AddSingleton<IReadOp, ListBillsOp>();
builder.Services.AddSingleton<IReadOp, ListPaymentsOp>();
builder.Services.AddSingleton<IReadOp, GetTransactionOp>();
builder.Services.AddSingleton<IReadOp, RunQueryOp>();
```
(`QbXmlBuilder`, `QbXmlParser`, `QbReportParser`, `QbListExecutor`, `QbConnectionManager` are already registered singletons — the ops' primary constructors get them injected. No `IOptions<QbXmlOptions>` needed in the ops themselves; `QbListExecutor` already consumes it.) **Host-resolves test:** in `OpRegistrationTests` (or extend `HostStartupTests`), `WebApplicationFactory<Program>` in `Testing` env, resolve `IEnumerable<IReadOp>`, assert `>= 12` and that `Name`s are unique and include `"company_info"`/`"report"`/`"run_query"` etc. (This proves Phase 5 can build the `OpRegistry`.)

## State of the Art

| Old approach | Current approach | Impact |
|---|---|---|
| Hand-written qbXML per op, ad-hoc XML strings | `QbXmlBuilder` (XDocument-based, PI + envelope) — already built in Phase 3 | Ops never touch raw XML; just `XElement` bodies |
| One giant `*QueryRq` returning everything → truncation/OOM on real files | iterators (`Start`/`Continue`), wrapped once in `QbListExecutor` — Phase 3 | List ops are paging-safe for free |
| `ReportQuery` parsed by ordinal column position | `ColDesc`-keyed `ColData` parse — `QbReportParser`, Phase 3 | `report` op returns a stable `ParsedReport` |
| Op dispatch baked into a controller | `IReadOp` registry assembled in Phase 5 from DI | Phase 4 stays HTTP-agnostic; ops are unit-testable in isolation |

**Deprecated/outdated for this phase:** nothing — Phases 1–3 are the substrate and they're current (reviewed 100/100, 76/76 tests green).

## Open Questions

1. **"Default A/R and A/P accounts" (READ-05).** `PreferencesQueryRq`/`PreferencesRet` does not expose a clean "default Accounts Receivable account" / "default Accounts Payable account" preference. (`PurchasesAndVendorsPreferences` has a `DefaultDiscountAccountRef`; sales-tax has `DefaultItemSalesTaxRef`; there's no generic default-AR/AP.)
   - **What we know:** every company file *has* an A/R account (the one invoices post to) and an A/P account (bills post to), discoverable via `AccountQueryRq` filtered by `AccountType` (`AccountsReceivable` / `AccountsPayable`).
   - **What's unclear:** whether `READ-05`'s reviewer expects these from `PreferencesRet` specifically or just "the A/R and A/P accounts".
   - **Recommendation:** `get_company_preferences` returns everything `PreferencesRet` has, *plus* — if cheap — fires an `AccountQueryRq` with `<AccountType>AccountsReceivable</AccountType>` and one with `AccountsPayable` (or one query and filter client-side) and surfaces `defaultArAccount`/`defaultApAccount` from those. The planner should make this an explicit task step and note the data source in the result (`source: "AccountQuery"` vs `"Preferences"`).

2. **`AgingReportQueryRq` date element.** Aging reports take an "as-of" date (`ReportPeriod`'s `ToReportDate`, or historically a `ReportAgingAsOf`/`ReportAsOfDate` element) rather than a true from/to range; some `aging*` reports also take `ReportAgingInterval`.
   - **What we know:** the report-query envelope is `<{Report}QueryRq><{Report}Type>…</…><ReportDateMacro>…</…|<ReportPeriod>…</…></{Report}QueryRq>` (verified from the Intuit SDK sample).
   - **What's unclear:** exact element name for the aging anchor date in spec 16.0.
   - **Recommendation:** for v1, the `report` op accepts the same `dateMacro` / `fromDate`+`toDate` args for all four types and, for aging, builds `<ReportPeriod><FromReportDate>…</FromReportDate><ToReportDate>…</ToReportDate></ReportPeriod>` (QB tolerates a range on aging — it uses the end date) or `<ReportDateMacro>Today</ReportDateMacro>`. Phase 9 re-pins the exact element when capturing the live fixture. Document this in the task.

3. **`PreferencesRet` decimal-places field.** Whether "decimal places" lives in `ItemsAndInventoryPreferences` (`AllowsItemQuantitiesGreaterThanOne`/quantity decimals), in `SalesAndCustomersPreferences`, or is a multi-currency thing.
   - **Recommendation:** surface whatever decimal/rounding-related field is present (`rawPreferencesRet` is always included so nothing is lost); name the result key `decimalPlaces` and let Phase 9 pin the source. Not worth blocking on.

4. **Whether `company_info` should bundle `HostQueryRq`.** Recommended yes (it's the only place "QuickBooks edition" actually comes from) and it's a single extra `*Rq` in the same message — but the planner could split `company_info` (just `CompanyQueryRq`) from a separate `host_info` op. **Recommend bundling** (one op, two `*Rq`s in one `BuildRequest(new[]{…})` call, `parsed.Elements` has both `*Rs`).

## Suggested ordered task breakdown (one commit each, `dotnet build` + `dotnet test` green at every step, no QuickBooks needed)

1. **`feat(04-01): IReadOp + ReadOpBase + ArgReader + company_info + DI scaffolding`** — `Qb/Ops/IReadOp.cs`, `ReadOpBase.cs` (the three `QuerySingleAsync`/`QueryListAsync`/`QueryReportAsync` helpers + `ListResult`), `ArgReader.cs` (string/date/bool/enum coercion over `IReadOnlyDictionary<string,object?>`), `CompanyInfoOp.cs` (bundled `HostQueryRq`+`CompanyQueryRq`), register `IReadOp` for it in `Program.cs`; new test `CompanyInfoOpTests.cs` (fields extracted, `HostQueryRq`+`CompanyQueryRq` both in the request) + extend the test helper (`CreateOps()`); add fixture `HostCompanyQueryRs.qbxml` (constructed — note for re-pin). Proves the shape end-to-end.
2. **`feat(04-01): get_company_preferences`** — `CompanyPreferencesOp.cs` (+ the optional `AccountQueryRq` AR/AP follow-up — make it a clear sub-step; if dropped, document why), DI line, `CompanyPreferencesOpTests.cs` (sales-tax-enabled, decimal places, multi-currency-enabled, default AR/AP), fixture `PreferencesQueryRs.qbxml` (+ `AccountQueryRs.arap.qbxml` if doing the follow-up) (constructed — note for re-pin).
3. **`feat(04-01): report op (ProfitAndLoss / BalanceSheet / AgingAR / AgingAP)`** — `ReportOp.cs` (one op, `switch` on `type`, date-arg validation, `QbReportParser`), DI line, `ReportOpTests.cs` (4 types: assert the right `*ReportQueryRq` + `*Type` value via `ProcessRequests`; assert date-arg validation throws on both/neither/half; parse a report fixture), fixtures: reuse `GeneralSummaryReportQueryRs.pnl.qbxml`; add `GeneralSummaryReportQueryRs.balancesheet.qbxml`, `AgingReportQueryRs.ar.qbxml`, `AgingReportQueryRs.ap.qbxml` (constructed — note for re-pin).
4. **`feat(04-01): list_customers / list_vendors / list_accounts`** — three op classes (`ActiveStatus` default `All` + `NameFilter`), DI lines, `ListEntityOpsTests.cs` (rows + the `ActiveStatus`/`NameFilter` applied, asserted via `ProcessRequests`; `iterator="Start"` present; single page → `ProcessRequests.Count == 1`), fixtures: reuse `CustomerQueryRs.normal.qbxml`; add `VendorQueryRs.qbxml`, `AccountQueryRs.qbxml` (constructed — note for re-pin).
5. **`feat(04-01): list_items`** — `ListItemsOp.cs` (`ItemQueryRq`, same filters; polymorphism is free via the parser's `type`), DI line, add to `ListEntityOpsTests.cs` (assert `rows[0]["type"]=="Service"`, `rows[1]["type"]=="Inventory"` against the existing `ItemQueryRs.polymorphic.qbxml`); optionally add `ItemQueryRs.normal.qbxml` for a single-type case.
6. **`feat(04-01): list_invoices / list_bills / list_payments`** — three op classes (`TxnDateRangeFilter` w/ `FromTxnDate`/`ToTxnDate` or `DateMacro`; `EntityFilter/FullNameList/FullName`; optional `IncludeLineItems`), DI lines, `ListTransactionOpsTests.cs` (rows + date filter + entity filter asserted via `ProcessRequests`), fixtures `InvoiceQueryRs.qbxml`, `BillQueryRs.qbxml`, `ReceivePaymentQueryRs.qbxml` (constructed — note for re-pin).
7. **`feat(04-01): get_transaction (TxnID | RefNumber)`** — `GetTransactionOp.cs` (`TransactionQueryRq` w/ `TxnIDList` or `RefNumberFilter`+`Equals`; optional `TransactionTypeList`; returns `{matches, count, ambiguous, lite}`; exactly-one-of-txnId/refNumber validation), DI line, `GetTransactionOpTests.cs` (by TxnID → one match; by RefNumber → multiple → `ambiguous == true`; both/neither → throws; a per-element `Error` status → surfaced in `status`, not thrown), fixtures `TransactionQueryRs.byid.qbxml`, `TransactionQueryRs.byref.multi.qbxml` (constructed — note for re-pin).
8. **`feat(04-01): run_query (whitelist) + register all read ops`** — `RunQueryOp.cs` (whitelist, `entity + "QueryRq"`, `filters` → child elements, `Company`/`Host`/`Preferences` → single-shot, everything else → `QbListExecutor`), DI line, `RunQueryOpTests.cs` (whitelisted entity → builds `<EmployeeQueryRq>` + passes filters + goes through iterator; non-whitelisted → throws; verb-y name like `CustomerDel` → throws); fixture `EmployeeQueryRs.qbxml` (constructed — note for re-pin); add `OpRegistrationTests.cs` (host resolves `IEnumerable<IReadOp>`, ≥12 ops, unique `Name`s, includes the expected names) — proves Phase 5 can build the `OpRegistry`. Final `dotnet test` sweep.

(Tasks 4+5 or 6 could be merged if the planner wants fewer commits; 8 must come last because it adds the registration test. Each task: ~1 op class file each + 1 DI line + ~1 test file (or additions) + ~1–3 fixtures. No new NuGet packages.)

## Sources

### Primary (HIGH confidence)
- In-repo Phase 1–3 source (authoritative for the abstraction/compose pattern/DI/tests): `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/{QbXmlBuilder,QbXmlParser,QbReportParser,QbListExecutor,QbConnectionManager,QbXmlOptions,QbXmlModels,QbExceptions}.cs`; `.../QbConnectService/Program.cs`; `.../QbConnectService.Tests/Fakes/FakeRequestProcessor.cs`; `.../QbConnectService.Tests/{QbListExecutorTests,QbXmlBuilderTests}.cs`; `.../QbConnectService.Tests/Fixtures/qbxml/*.qbxml`.
- `.planning/STATE.md` "Completed phases" — full Phase 1/2/3 inventory + the constructed-fixture re-pin note.
- `.planning/ROADMAP.md` (Phase 4 detail + success criteria), `.planning/REQUIREMENTS.md` (READ-04..10), `docs/superpowers/specs/2026-05-11-quickbooks-direct-sdk-accounting-design.md` (§4 op catalog).
- `.planning/research/FEATURES.md` — corroborates the op catalog, the `run_query`/`get_company_preferences` adds, and the qbXML quirks per op (report ColData shape, Item polymorphism, RefNumber non-uniqueness, iterator mechanics, `ReportType` spellings).
- Intuit Developer `QBXML_SDK_Samples` repo — `xmlfiles/legacy/CustomDetailReport.xml` confirms the report-query envelope shape (`<{Report}QueryRq><{Report}Type>…</…><ReportDateMacro>ThisMonth</…></…>`). (`github.com/IntuitDeveloper/QBXML_SDK_Samples`)

### Secondary (MEDIUM confidence)
- Training knowledge of the qbXML Onscreen Reference (OSR) for element/enum names: `CompanyQueryRq`/`CompanyRet`, `HostQueryRq`/`HostRet.ProductName`, `PreferencesQueryRq`/`PreferencesRet` block names (`SalesTaxPreferences`/`AccountingPreferences`/`MultiCurrencyPreferences`/`PurchasesAndVendorsPreferences`) and fields (`IsMultiCurrencyOn`, `IsUsingClassTracking`, `DefaultItemSalesTaxRef`), `GeneralSummaryReportQueryRq`/`GeneralSummaryReportType` (`ProfitAndLossStandard`, `BalanceSheetStandard`), `AgingReportQueryRq`/`AgingReportType` (`ARAgingSummary`, `APAgingSummary`, `ARAgingDetail`, `APAgingDetail`), `ReportDateMacro` values, `CustomerQueryRq`/`VendorQueryRq`/`ItemQueryRq`/`AccountQueryRq` filters (`ActiveStatus` = `ActiveOnly`|`InactiveOnly`|`All`, `NameFilter`/`MatchCriterion`/`Name`), `InvoiceQueryRq`/`BillQueryRq`/`ReceivePaymentQueryRq` filters (`TxnDateRangeFilter`/`FromTxnDate`/`ToTxnDate`/`DateMacro`, `EntityFilter`/`FullNameList`/`FullName`, `IncludeLineItems`), `TransactionQueryRq` (`TxnIDList`, `RefNumberFilter`/`MatchCriterion`/`RefNumber`, `RefNumberList`, `TransactionTypeList`/`TxnType`). Treated as hypothesis; consistent with FEATURES.md and the SDK sample where they overlap. **Must be re-pinned against the live `10.120.254.13` host in Phase 9** (same caveat already applied to the Phase-3 P&L fixture).
- ConsoliBYTE wiki ("QbXML for Reporting", "Example qbXML Requests") and `qbwc/qbxml` schema repo — referenced for report/iterator/preference shapes (could not be fully fetched this session: ConsoliBYTE refused the connection; the `qbxmlops130.xml` schema is too large for WebFetch to scan to the report/preferences sections — flagged so the planner knows these specific shapes are training-derived).

### Tertiary (LOW confidence)
- The "no clean default-AR/AP-account preference" claim — based on absence in training knowledge of `PreferencesRet`, not a positive doc statement. Mitigation: `get_company_preferences` includes `rawPreferencesRet` and the recommended `AccountQueryRq` fallback, so nothing is lost if a default-AR/AP element does exist.

## Metadata

**Confidence breakdown:**
- Op abstraction / `ReadOpBase` / DI / compose pattern / test approach: **HIGH** — derived directly from the in-repo Phase 1–3 code, which is the contract.
- qbXML `*Rq` element names + child filters per op: **MEDIUM** — training/OSR knowledge corroborated by FEATURES.md and an Intuit SDK sample; not byte-verified against spec 16.0. All new fixtures are constructed and flagged for Phase-9 re-pin (consistent with how Phase 3's P&L fixture is treated).
- Report `*ReportType` enum values + `ReportDateMacro` list: **MEDIUM** — training/OSR, corroborated by FEATURES.md line 25; report-query *envelope* shape verified from the Intuit SDK sample.
- "Default A/R / A/P account" source + `PreferencesRet` decimal-places field name: **LOW** — see Open Questions; mitigated by always returning `rawPreferencesRet` and a documented fallback.

**Research date:** 2026-05-11
**Valid until:** ~30 days for the abstraction/pattern recommendations (stable — they're built on shipped Phase 1–3 code); the qbXML element/enum specifics should be confirmed whenever a live `10.120.254.13` capture is available (Phase 9) regardless of date.

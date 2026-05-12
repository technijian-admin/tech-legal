# Phase 7: Write Ops - Research

**Researched:** 2026-05-11
**Domain:** qbXML `*AddRq`/`*ModRq` write operations as thin `WriteOpBase` subclasses on the Phase-6 write-safety machinery (`IWriteOp`, `WriteOpBase.RunAsync`, `/dryrun`, hash-chained `AuditLog`, `AllowWrites` gate)
**Confidence:** HIGH on the in-repo seam (`WriteOpBase`/`IWriteOp`/`ReadOpBase`/`ArgReader`/`QbXmlBuilder`/`QbXmlParser`/`FakeRequestProcessor` — all read in this session). MEDIUM on the exact qbXML `*AddRq`/`*ModRq` element/child names and the stale-`EditSequence` `statusCode` (corroborated across the consolibyte/quickbooks-php schema files, the quickbooksdesktopapi.com simulator, the Intuit SDK samples readme, and a status-code search returning "3200 — The provided edit sequence is out-of-date" — but NOT live-pinned against `10.120.254.13`; Phase 9 re-pins). Consistent with the Phase 3/4 fixture-construction precedent: every constructed `*AddRs`/`*ModRs`/`*ModRq` element name and the `3200` code is flagged below for Phase-9 re-pin.

## Summary

Phase 7 adds the v1 WRITE ops (WRITE-03..07). Each is a thin `WriteOpBase` subclass that (a) implements `BuildRequest(args)` — a *pure* `args → qbXML string` map producing the `<{Entity}AddRq><{Entity}Add>…</…></{Entity}AddRq>` body via `QbXmlBuilder.Rq(...)` + `_builder.BuildRequest(thatXElement)` — and (b) overrides `DryRunAsync(args, ct)` with real pre-flight (the Phase-6 default is a stub: `{BuildRequest, "...would send...", [], {}, AllowWrites}`). `RunAsync` is inherited unchanged from `WriteOpBase` for the `create_*` ops: it calls `BuildRequest`, throws `QbWriteForbiddenException` if `!AllowWrites`, runs `_manager.ExecuteAsync`, parses, appends exactly one `AuditRecord`, returns `{status, rows, auditSeq, rawSpilledTo}`. A non-zero qbXML `statusCode` (incl. a QB business error like 3100 "name in use", 3140 "invalid reference", or 3200 "edit sequence out of date") is **not** thrown — it flows out in `{status:...}` as a 200 body and the audit row records it.

The `mod_*` op is the only one that needs more than `args → XML`, because `*ModRq` is **full-replace** (every child you don't carry over is cleared) and needs the live `EditSequence` from a *fresh* read of THAT object. **Recommendation: ONE generic `mod` op** (`{entity, ref:{listID?|txnID?|fullName?}, fields:{...}}`) with an entity whitelist, that overrides `RunAsync` (not just `DryRunAsync`) to do read → merge fields over the current `*Ret` → strip read-only/computed children → build `<{Entity}ModRq><{Entity}Mod>` with the just-read `EditSequence` → `ExecuteAsync` → parse → audit. `BuildRequest(args)` for the `mod` op is the awkward part of the `IWriteOp` contract: it can't be a side-effect-free `args → XML` because it needs a read. **Recommendation: `mod`'s `BuildRequest` throws `InvalidOperationException` ("mod ops build their qbXML inside DryRunAsync/RunAsync after a fresh read of the target") UNLESS `args` already carries a resolved `_currentRecord` + `editSequence` (the path `DryRunAsync`/`RunAsync` use internally) — and `DryRunAsync` does the read, computes the merged `*ModRq`, returns it as `QbXml`, and a before/after `DiffFields` summary; `RunAsync` re-does the read (the `EditSequence` may have moved on by then — that's the point: QB rejects it with `3200`, returned verbatim, no retry).** Stale `EditSequence`: NEVER retried, NEVER auto-fixed; the `3200` response is returned `{status:{code:"3200",severity:"Error",message:"..."}}` 200, and `WriteOpBase.RunAsync` still writes the audit row (it always does, per the Phase-6 code, regardless of `status.Severity`).

Pre-flight reads from a write op should build `*QueryRq` directly via the inherited `ReadOpBase.QuerySingleAsync`/`QueryListAsync` (no new DI dep) — recommend small `protected` helpers on `WriteOpBase` (filled into the existing `// TODO(Phase 7)` slot): `FetchByNameAsync(entity, fullName, ct)` → first matching `*Ret` row or null, and `FetchCurrentAsync(entity, refKind, refValue, ct)` → `(record, editSequence)` or null. Multi-currency refusal: **for v1, refuse any write whose `args` carry a `currencyRef`/`exchangeRate` at all** (`ArgumentException` → 400) — that's the v1 contract per the design (multi-currency is out of scope), and it avoids a `PreferencesQueryRq` round-trip just to refuse. JE balance: validate `sum(debits) == sum(credits)` in a shared `Validate(args)` the JE op calls at the TOP of both `BuildRequest` and `DryRunAsync` → `ArgumentException` → 400, qbXML never built/sent.

**Primary recommendation:** Build seven `create_*` ops as thin `WriteOpBase` subclasses (inherited `RunAsync`, overridden `DryRunAsync`) + ONE generic `mod` op (`{entity, ref, fields}`, whitelist, overrides `RunAsync` for read→merge→build→execute→audit), with `WriteOpBase` getting `FetchByNameAsync`/`FetchCurrentAsync` + a static `MultiCurrencyGuard.Reject(args)` helper; register all eight in `Program.cs`; flag every constructed element name + the `3200` code for Phase-9 re-pin.

## Standard Stack

No new libraries. Phase 7 is pure C# on the Phase 1–6 seam — `System.Xml.Linq` (`XElement`/`XDocument`, already used by `QbXmlBuilder`), `xUnit` + `Microsoft.AspNetCore.Mvc.Testing` (already test deps). The "stack" here is the *existing seam*, which Phase 7 builds on directly:

### Core (existing, do not re-create — extend)
| Component | Where | Phase-7 role |
|-----------|-------|--------------|
| `IWriteOp : IReadOp` | `Qb/Ops/IWriteOp.cs` | `string BuildRequest(args)` (pure, deterministic, `ArgumentException` on bad args) + `Task<DryRunResult> DryRunAsync(args, ct)` (may read; MUST NOT write or audit). Every Phase-7 write op implements it via `WriteOpBase`. |
| `WriteOpBase` | `Qb/Ops/WriteOpBase.cs` | `: ReadOpBase, IWriteOp`. `BuildRequest` abstract; `DryRunAsync` virtual stub (Phase-7 ops **override**); `RunAsync` (effectively final for `create_*`) = `BuildRequest` → `if(!AllowWrites) throw QbWriteForbiddenException` → `_manager.ExecuteAsync` → `_xmlParser.Parse` → `_audit.AppendAsync(new AuditRecord(Name, args, requestXml, status.Code, status.Severity, status.Message))` → `{status, rows, auditSeq, rawSpilledTo}`. `protected static PreFlightCheck DiffFields(label, before, after)`. `protected bool AllowWrites`. `protected readonly AuditLog _audit`. The `// TODO(Phase 7): add current-record resolution helpers for mod_* pre-flight lookups` slot — **Phase 7 fills it** with `FetchByNameAsync`/`FetchCurrentAsync`. |
| `ReadOpBase` | `Qb/Ops/ReadOpBase.cs` | `WriteOpBase` extends it → write ops get `QuerySingleAsync(XElement|IEnumerable<XElement>, ct)`, `QueryListAsync(XElement, bool? ownerIdZero, ct)`, `QueryReportAsync`, `ListResult`, `PreviewRequest` (default null). Pre-flight reads use `QuerySingleAsync`/`QueryListAsync`. |
| `DryRunResult` / `PreFlightCheck` | `Qb/Ops/DryRunResult.cs` | `record DryRunResult(string QbXml, string Summary, IReadOnlyList<PreFlightCheck> PreFlight, IReadOnlyDictionary<string,object?> ResolvedReferences, bool AllowWrites)`; `record PreFlightCheck(string Name, bool Ok, string? Detail)`. Phase-7 `DryRunAsync` returns these with `QbXml = BuildRequest(args)` (byte-exact), `PreFlight` listing each check, `ResolvedReferences` mapping `{customerName → ListID}` etc., `Summary` plain-English (for `mod`: the field diff). |
| `QbXmlBuilder` | `QbXmlBuilder.cs` | `static XElement Rq(string requestName, params object[] content)`, `WithIterator`, `WithOwnerIdZero`, `string BuildRequest(XElement)` / `BuildRequest(IEnumerable<XElement>)` (wraps in `<?xml?>` decl + `<?qbxml version?>` PI + `<QBXML><QBXMLMsgsRq onError="stopOnError">…</…></QBXML>` via `XDocument.Save`), `.Version`. Phase-7 write ops: `QbXmlBuilder.Rq("CustomerAddRq", new XElement("CustomerAdd", …children))` then `_builder.BuildRequest(thatXElement)`. Note: `Rq` is `static` — ops call it directly; `_builder` is the instance field for `.BuildRequest(...)`. |
| `QbXmlParser` | `QbXmlParser.cs` | `Parse(raw) → ParsedQbXmlResponse{Message:QbStatus, Elements:[ParsedElement{Name, Status, IteratorId, IteratorRemaining, Rows:List<Dictionary<string,object?>>}], RawSpilledTo}`. `QbStatus{Code, Severity, Message, IsError}`, `QbStatus.FromElement(XElement)`. `MapRet` maps `*Ret` children → a `Dictionary` (nested complex elements → nested `Dictionary`, repeated elements → `List`, `DataExtRet` → `customFields`). `*ModRs` responses parse the same way (the `*Ret` it carries is the updated record + new `EditSequence`). |
| `QbConnectionManager` | `QbConnectionManager.cs` | `ExecuteAsync(requestXml, ct)`. Phase-6: refuses *write* qbXML when `AllowWrites=false` (4th defensive belt). Reads are **always** allowed → a `mod` op's `DryRunAsync` read works even with `AllowWrites=false`. Confirm in Phase-7 tests. |
| `AuditLog` | `Audit/AuditLog.cs` | `Task<long> AppendAsync(AuditRecord, ct)` → returns the new `Seq` (0-based). Hash-chained JSONL at `Audit:Path/audit.jsonl`. `WriteOpBase.RunAsync` appends one row per executed write **regardless of `status.Severity`**. Dry-run / refused-403 / COM-or-parse-failure paths append nothing (existing behavior). |
| `AuditRecord` | `Audit/AuditRecord.cs` | `record(string Op, IReadOnlyDictionary<string,object?> Args, string QbXmlRequest, string ResponseStatusCode, string ResponseStatusSeverity, string ResponseStatusMessage)`. `WriteOpBase.RunAsync` constructs it; Phase-7 ops don't touch it directly. |
| `ArgReader` | `Qb/Ops/ArgReader.cs` | `public static String/Bool/Date/Dict(args, key)` (null-tolerant, `JsonElement`-aware, trims, throws `ArgumentException` on bad date), `ToDictionary(JsonElement)`, `ConvertJson(JsonElement)`. Phase-7 ops use these for scalars + nested dicts. **Note: there is no `ArgReader.List` / `Decimal` / `Int` helper** — line-item arrays arrive as `List<object?>` (each item a `Dictionary<string,object?>` after `ConvertJson`, or a `JsonElement`), and money/qty arrive as strings (`ConvertJson` turns JSON numbers into strings). Phase 7 should add a small `ArgReader.List(args, key)` → `IReadOnlyList<IReadOnlyDictionary<string,object?>>` (handles `List<object?>`, `JsonElement` array) and `ArgReader.Decimal(args, key)` → invariant-culture `decimal?` (Pitfall 17: `decimal` + invariant + fixed precision; never `double`) and `ArgReader.RequiredString(args, key)` (throws if missing). |
| `OpRegistry` / `OpsEndpoints` / `/dryrun` | `Qb/Ops/OpRegistry.cs`, `Api/OpsEndpoints.cs` | `OpRegistry(IEnumerable<IReadOp>) → dict by Name`. `POST /api/ops/{op}`: `is IWriteOp && !AllowWrites` → 403; else `RunAsync` → `200 {op, result}`. `POST /api/ops/{op}/dryrun`: `is IWriteOp` → `DryRunAsync` → `200 {op, dryRun}`; not write-gated. `ArgumentException` → mapped to 400 by `ApiExceptionHandler` (used by Phase 4's read ops — `get_transaction` already throws `ArgumentException` for bad args and gets 400; `OpsEndpoints.ReadArgsAsync` itself throws `ArgumentException` on non-object body). `QbWriteForbiddenException` → 403 (Phase 6). `QbException`/`QbBusyException`/`QbTimeoutException` → 503/409/504-ish (Phase 2/5). **Phase 7 needs no endpoint changes** — register the ops, the machinery dispatches them. |
| `FakeRequestProcessor` | `Tests/Fakes/FakeRequestProcessor.cs` | `AddResponse(rqName, xml)` (`rqName` = the request element local name, e.g. `"CustomerAddRq"`), `AddResponses(rqName, params xml[])` (FIFO queue — use for the `mod` flow's `*QueryRq` then `*ModRq`, or two `*QueryRq` if a pre-flight does name-resolution then the mod-target fetch), `ProcessRequestHook` (full control), `ProcessRequests` (captures every request XML sent — assert byte-exact + count), `EnqueueComError(hresult)`. Picks the response by the first `<QBXMLMsgsRq>` child's local name. |
| `QbWebAppFactory` | `Tests/QbWebAppFactory.cs` | `WebApplicationFactory<Program>` + `Testing` env, `Auth:ApiToken`, `Safety:AllowWrites` knob, `Audit:Path` per-test temp dir, `Qb:CompanyFilePath`, registers `services.AddSingleton<IReadOp, FakeWriteOp>()`. **Phase 7: register the real write ops in `Program.cs`** — they then show up here automatically; tests that want only a specific op can keep using the `OpTestHarness`-style direct-construct pattern (`WriteOpBaseTests` already does that — copy that fixture shape for per-op unit tests). |
| `OpTestHarness` | `Tests/OpTestHarness.cs` | Direct-construct harness for read ops; `WriteOpBaseTests.CreateFixture` is the write-op equivalent (builds `QbConnectionManager` + `QbXmlBuilder` + `QbXmlParser` + `QbReportParser` + `QbListExecutor` + `AuditLog` + the op, with `AllowWrites` toggle and a temp audit dir). Phase 7's per-op test fixtures should follow `WriteOpBaseTests.CreateFixture` exactly (and likely add the new ops to `OpTestHarness.Create` and `OpRegistrationTests`). |

### Supporting (new, small)
| Component | Purpose |
|-----------|---------|
| `WriteOpBase.FetchByNameAsync(string entity, string fullName, ct)` | `protected async Task<IReadOnlyDictionary<string,object?>?>` — builds `QbXmlBuilder.Rq(entity+"QueryRq", new XElement("FullName", fullName))` (list entities) or the txn equivalent, `QuerySingleAsync`, returns `parsed.First.Rows.FirstOrDefault()`. Used by `create_*` `DryRunAsync` to *warn* (not fail) when a referenced customer/vendor/item/account doesn't resolve, and to populate `ResolvedReferences`. |
| `WriteOpBase.FetchCurrentAsync(string entity, string refKind, string refValue, ct)` | `protected async Task<(IReadOnlyDictionary<string,object?> Record, string EditSequence)?>` — builds `{Entity}QueryRq` by `ListID` (list entities) or `TxnID` (txn entities) (or `FullName`/`RefNumber` if that's what's supplied — but `RefNumber` is non-unique so `mod` should require `txnID`/`listID`; allow `fullName` for list entities), `QuerySingleAsync`, returns `(row, row["EditSequence"] as string)`. Used by the `mod` op. Returns null if no rows (→ `mod` raises `ArgumentException` "no such object" → 400, OR surfaces it; recommend `ArgumentException` so the dry-run/execute fails cleanly rather than building a bogus `*ModRq`). |
| `MultiCurrencyGuard.Reject(IReadOnlyDictionary<string,object?> args)` | `internal static void` — throws `ArgumentException("multi-currency is not supported in v1; remove currencyRef/exchangeRate (v2 item)")` if `ArgReader.String(args, "currencyRef") is not null || ArgReader.Dict(args, "currencyRef") is not null || ArgReader.String(args, "exchangeRate") is not null`. Called at the top of every `create_*` op's `BuildRequest` (and the `mod` op's pre-flight). Avoids needing a `PreferencesQueryRq` round-trip to refuse. |
| `ArgReader.List` / `ArgReader.Decimal` / `ArgReader.RequiredString` | see above |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| ONE generic `mod` op | `mod_customer`, `mod_vendor`, `mod_invoice`, `mod_bill`, `mod_check` per-entity | Per-entity: each maps fields precisely (knows which `*Ret` fields → `*Mod` children, in schema order) and `BuildRequest` could *almost* be pure if the caller supplied a full record + `editSequence`; but it's 5+ near-identical classes, each still needs the read→merge flow, and the read→merge→re-serialize is genuinely mechanical (the parsed `Rows[0]` dict IS the current full record; merge `fields` over it; re-emit children). **Recommend generic `mod`** — the merge is generic, the only entity-specific bit is the whitelist + the read-only-children strip-list (a static `Dictionary<string,string[]>`). The risk (schema-order sensitivity of `*Mod` children, read-only fields that can't go in `*Mod`) is the same for both shapes and is a Phase-9 re-pin item either way. |
| `mod`'s `BuildRequest` throws unless `args` has the resolved record | `mod`'s `BuildRequest` does the read itself | `BuildRequest` is contractually pure/side-effect-free/synchronous (it's `string` not `Task<string>`, and `IWriteOp` says "no I/O, no COM"). A `mod` `BuildRequest` that reads would violate that and can't be sync. **Recommend: `BuildRequest(args)` throws `InvalidOperationException` for `mod` unless `args` carries `_currentRecord`+`editSequence` (the internal path); document "the normal flow is `/dryrun` (which does the read and returns the byte-exact `*ModRq`) then `/ops/mod` (which re-reads, re-builds, executes)".** `RunAsync` is overridden for `mod` to do read→merge→build-from-resolved→execute→audit. |
| Write op calls read ops via `OpRegistry` | Build `*QueryRq` directly via `ReadOpBase.QuerySingleAsync` | `OpRegistry` dep on `WriteOpBase` is a cross-dependency (write ops depending on read ops by name) and `OpRegistry` isn't injectable into ops cleanly (it's built *from* `IEnumerable<IReadOp>` which includes the write ops → potential cycle in DI graph reasoning). **Recommend: build `*QueryRq` directly** via the inherited `QuerySingleAsync`/`QueryListAsync` (zero new deps; `WriteOpBase` already has `_builder`/`_manager`/`_xmlParser`). For the (rare) multi-currency-detection-via-prefs case we *don't* need it because v1 refuses currency-bearing writes outright. |
| `create_journal_entry` validates balance only in `DryRunAsync` | Validate in a shared `Validate(args)` called at the top of BOTH `BuildRequest` and `DryRunAsync` | If only `DryRunAsync` validates, a direct `POST /api/ops/create_journal_entry` (skipping dry-run) with an imbalanced JE would `BuildRequest` a bogus qbXML and `ExecuteAsync` it (QB would reject it, but we said pre-flight rejects it and the qbXML is "never built/sent"). **Recommend: a private `Validate(args)` (also does `MultiCurrencyGuard.Reject`) called as line 1 of `BuildRequest` and line 1 of `DryRunAsync` → `ArgumentException` → 400 → qbXML never built.** `RunAsync` calls `BuildRequest` first, so it's covered transitively. |

## Architecture Patterns

### File layout (under `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/`)
```
Qb/Ops/
├── WriteOpBase.cs          # EXTEND: add FetchByNameAsync / FetchCurrentAsync (fill the // TODO(Phase 7) slot)
├── WriteOpHelpers.cs        # NEW: MultiCurrencyGuard, RefElement(name, args-or-string), AddressElement(name, dict), small shared XElement builders
├── ArgReader.cs            # EXTEND: List / Decimal / RequiredString
├── CreateCustomerOp.cs      # NEW: "create_customer" → CustomerAddRq
├── CreateVendorOp.cs        # NEW: "create_vendor" → VendorAddRq
├── CreateInvoiceOp.cs       # NEW: "create_invoice" → InvoiceAddRq (lines)
├── CreateBillOp.cs          # NEW: "create_bill" → BillAddRq (expense + item lines)
├── CreateCheckOp.cs         # NEW: "create_check" → CheckAddRq (expense + item lines)
├── ReceivePaymentOp.cs      # NEW: "receive_payment" → ReceivePaymentAddRq (AppliedToTxnAdd / IsAutoApply)
├── CreateJournalEntryOp.cs  # NEW: "create_journal_entry" → JournalEntryAddRq (debit/credit lines; balance Validate)
└── ModOp.cs                 # NEW: "mod" → {entity, ref, fields} read→merge→{Entity}ModRq; overrides RunAsync
```
Tests under `QbConnectService.Tests/`: `CreateEntityOpsTests.cs`, `CreateTransactionOpsTests.cs`, `ReceivePaymentOpTests.cs`, `CreateJournalEntryOpTests.cs`, `ModOpTests.cs` (+ extend `OpRegistrationTests`). New fixtures under `Tests/Fixtures/qbxml/`: `CustomerAddRs.qbxml`, `VendorAddRs.qbxml`, `InvoiceAddRs.success.qbxml` (there's already an `InvoiceAddRs.error.qbxml`), `BillAddRs.qbxml`, `CheckAddRs.qbxml`, `ReceivePaymentAddRs.qbxml`, `JournalEntryAddRs.qbxml`, `CustomerQueryRs.formod.qbxml` (current record + `EditSequence` for `mod customer` — or reuse `CustomerQueryRs.normal.qbxml` if it has an `EditSequence`; check), `CustomerModRs.qbxml`, `InvoiceQueryRs.formod.qbxml`, `InvoiceModRs.stale.qbxml` (`statusCode="3200" statusSeverity="Error" statusMessage="The provided edit sequence is out-of-date."`).

### Pattern 1: a `create_*` op (the common case — inherited `RunAsync`)
**What:** `BuildRequest` is the only abstract member; override `DryRunAsync` for real pre-flight; do NOT override `RunAsync`.
```csharp
// Source: pattern derived from WriteOpBase.cs + FakeWriteOp.cs + the consolibyte/quickbooks-php CustomerAddRq schema
public sealed class CreateCustomerOp(
    QbXmlBuilder b, QbConnectionManager m, QbXmlParser xp, QbReportParser rp,
    QbListExecutor le, AuditLog audit, IOptions<SafetyOptions> safety)
    : WriteOpBase(b, m, xp, rp, le, audit, safety)
{
    public override string Name => "create_customer";

    public override string BuildRequest(IReadOnlyDictionary<string, object?> args)
    {
        MultiCurrencyGuard.Reject(args);
        var name = ArgReader.RequiredString(args, "name"); // throws ArgumentException -> 400

        var add = new XElement("CustomerAdd", new XElement("Name", name));
        if (ArgReader.String(args, "companyName") is { } c) add.Add(new XElement("CompanyName", c));
        if (ArgReader.String(args, "firstName") is { } f) add.Add(new XElement("FirstName", f));
        if (ArgReader.String(args, "lastName") is { } l) add.Add(new XElement("LastName", l));
        if (WriteOpHelpers.AddressElement("BillAddress", ArgReader.Dict(args, "billAddress")) is { } ba) add.Add(ba);
        if (WriteOpHelpers.AddressElement("ShipAddress", ArgReader.Dict(args, "shipAddress")) is { } sa) add.Add(sa);
        if (ArgReader.String(args, "phone") is { } p) add.Add(new XElement("Phone", p));
        if (ArgReader.String(args, "email") is { } e) add.Add(new XElement("Email", e));
        if (WriteOpHelpers.RefElement("TermsRef", args, "terms") is { } tr) add.Add(tr);

        return _builder.BuildRequest(QbXmlBuilder.Rq("CustomerAddRq", add));
    }

    public override async Task<DryRunResult> DryRunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct = default)
    {
        var qbXml = BuildRequest(args); // also runs MultiCurrencyGuard + required-name check
        var name = ArgReader.RequiredString(args, "name");
        var checks = new List<PreFlightCheck> { new("name-present", true, $"name = '{name}'") };
        var resolved = new Dictionary<string, object?>();

        // warn-not-fail: an Add will surface 3100 "name in use" itself
        var existing = await FetchByNameAsync("Customer", name, ct);
        checks.Add(new("name-not-already-in-use", existing is null, existing is null
            ? "no existing customer with that Name"
            : $"a customer named '{name}' already exists (ListID {existing.GetValueOrDefault("ListID")}); Add will fail 3100"));
        if (WriteOpHelpers.RefValue(args, "terms") is { } termsName)
        {
            var term = await FetchByNameAsync("Term", termsName, ct);
            checks.Add(new("terms-resolves", term is not null, term is null ? $"no Term named '{termsName}'" : "ok"));
            if (term is not null) resolved["termsRef"] = term.GetValueOrDefault("ListID");
        }
        return new DryRunResult(qbXml, $"Create customer '{name}'.", checks, resolved, AllowWrites);
    }
}
```
`RunAsync` is inherited: builds, gates on `AllowWrites`, executes, parses, **appends one audit row** (`status` may be a QB error like `3100` — it still audits and returns 200 `{status, rows, auditSeq, rawSpilledTo}`).

### Pattern 2: refs by `FullName` or `ListID`/`TxnID`
Every `*Ref` (`CustomerRef`, `ItemRef`, `AccountRef`, `VendorRef`, `PayeeEntityRef`, `TermsRef`, `PaymentMethodRef`, `DepositToAccountRef`, `ARAccountRef`, `APAccountRef`, `EntityRef`, …) is `<XxxRef><FullName>…</FullName></XxxRef>` OR `<XxxRef><ListID>…</ListID></XxxRef>`. `WriteOpHelpers.RefElement(elementName, args, key)`: if `args[key]` is a string → `<elementName><FullName>that</FullName></elementName>`; if it's a dict with `listID` → `<elementName><ListID>that</ListID></elementName>`; with `fullName` → `<elementName><FullName>that</FullName></elementName>`; if absent → null. (Confirmed shape: simulator example uses `<CustomerRef><ListID>1</ListID></CustomerRef>`; consolibyte schema lists every `*Ref` as `(ListID or FullName)`.)

### Pattern 3: line-item arrays
`args["lines"]` (or `args["expenseLines"]` / `args["itemLines"]` / `args["debits"]` / `args["credits"]` / `args["appliedTo"]`) is a `List<object?>` of dicts (after `ConvertJson`). Build one `<{LineName}>` per item. For Add requests **`TxnLineID` is NOT sent** (it's `-1`/auto for new lines — the consolibyte schema marks `LinkToTxn`'s `TxnLineID` required only when *linking* to an existing txn line; a plain new line omits it). For invoices: `<InvoiceLineAdd><ItemRef>…</ItemRef><Desc>…</Desc><Quantity>…</Quantity><Rate>…</Rate></InvoiceLineAdd>` (or `<Amount>` instead of `Rate`). At least one line required → `ArgumentException` if `lines` empty/absent.

### Pattern 4: the generic `mod` op (overrides `RunAsync`)
**What:** `{entity:"customer"|"vendor"|"invoice"|"bill"|"check", ref:{listID?|txnID?|fullName?}, fields:{...}}`. Read the current `*Ret` (with its `EditSequence`), merge `fields` over it, strip read-only/computed children, emit `<{Entity}ModRq><{Entity}Mod><{ListID|TxnID}>…</…><EditSequence>…</EditSequence>…all-other-fields…</{Entity}Mod></{Entity}ModRq>`. `*ModRq` is **full-replace**: every `*Ret` child you don't carry over is *cleared* — so the merge is "current record ⊕ fields" not "just fields".
```csharp
// Source: pattern derived from WriteOpBase.cs + PITFALLS.md Pitfall 13 + the consolibyte *ModRq schemas + status-code search (3200)
public sealed class ModOp(...) : WriteOpBase(...)
{
    private static readonly IReadOnlyDictionary<string,string> EntityToRet = new Dictionary<string,string>(StringComparer.OrdinalIgnoreCase)
    { ["customer"]="Customer", ["vendor"]="Vendor", ["invoice"]="Invoice", ["bill"]="Bill", ["check"]="Check" };
    // read-only / computed *Ret children that MUST NOT go into *Mod (Phase-9 re-pin the full list):
    private static readonly IReadOnlyDictionary<string,string[]> ReadOnlyChildren = new Dictionary<string,string[]>(StringComparer.OrdinalIgnoreCase)
    {
        ["*"]    = new[]{ "TimeCreated", "TimeModified", "DataExtRet" /* DataExtMod is a different shape */ },
        ["Customer"] = new[]{ "Balance", "TotalBalance", "JobStatus" /* careful */ },
        ["Invoice"]  = new[]{ "Subtotal", "SalesTaxTotal", "TotalAmount", "AppliedAmount", "BalanceRemaining", "IsPaid", "TxnNumber", "CurrencyRef", "ExchangeRate", "AmountTotalAmount" },
        ["Bill"]     = new[]{ "AmountDue", "OpenAmount", "IsPaid", "TxnNumber" },
        ["Check"]    = new[]{ "TxnNumber" },
    };
    public override string Name => "mod";

    public override string BuildRequest(IReadOnlyDictionary<string,object?> args)
    {
        // pure path only used internally after a fresh read populated _currentRecord + editSequence:
        if (args.TryGetValue("__resolvedRecord", out var r) && r is IReadOnlyDictionary<string,object?> rec
            && args.TryGetValue("__editSequence", out var es) && es is string seq)
            return BuildModXml(EntityKey(args), IdElementFor(EntityKey(args), args), seq, rec, args);
        throw new InvalidOperationException(
            "mod builds its qbXML inside DryRunAsync/RunAsync after a fresh read of the target. Use POST /api/ops/mod/dryrun then POST /api/ops/mod.");
    }

    public override async Task<DryRunResult> DryRunAsync(IReadOnlyDictionary<string,object?> args, CancellationToken ct = default)
    {
        MultiCurrencyGuard.Reject(args);
        var (entity, refKind, refValue, fields) = ParseModArgs(args); // ArgumentException -> 400 on bad shape / unknown entity / missing ref
        var current = await FetchCurrentAsync(EntityToRet[entity], refKind, refValue, ct)
            ?? throw new ArgumentException($"mod: no {entity} found for {refKind}={refValue}.");
        var (before, after) = MergeStrip(EntityToRet[entity], current.Record, fields);
        var qbXml = BuildModXml(EntityToRet[entity], IdElement(refKind, current.Record), current.EditSequence, after, args);
        var diff = DiffFields($"{entity}-fields", FlattenStrings(before), FlattenStrings(after));
        return new DryRunResult(
            qbXml,
            $"Update {entity} {refKind}={refValue}: {(string.Equals(diff.Detail,"no changes",StringComparison.Ordinal) ? "no field changes" : diff.Detail)} (EditSequence {current.EditSequence}).",
            new[] { new PreFlightCheck("target-resolves", true, $"{entity} {refKind}={refValue} found"),
                    new PreFlightCheck("edit-sequence-fresh", true, current.EditSequence), diff },
            new Dictionary<string,object?> { ["target"] = $"{entity} {refKind}={refValue}", ["editSequence"] = current.EditSequence },
            AllowWrites);
    }

    public override async Task<object?> RunAsync(IReadOnlyDictionary<string,object?> args, CancellationToken ct = default)
    {
        MultiCurrencyGuard.Reject(args);
        var (entity, refKind, refValue, fields) = ParseModArgs(args);
        if (!AllowWrites) throw new QbWriteForbiddenException($"{Name} is a write op and Safety:AllowWrites is false.");
        var current = await FetchCurrentAsync(EntityToRet[entity], refKind, refValue, ct)   // FRESH read, every time
            ?? throw new ArgumentException($"mod: no {entity} found for {refKind}={refValue}.");
        var (_, after) = MergeStrip(EntityToRet[entity], current.Record, fields);
        var requestXml = BuildModXml(EntityToRet[entity], IdElement(refKind, current.Record), current.EditSequence, after, args);
        var rawResponse = await _manager.ExecuteAsync(requestXml, ct);
        var parsed = _xmlParser.Parse(rawResponse);
        var status = parsed.Message;                          // 3200 "edit sequence out of date" lands HERE, not thrown
        var rows = parsed.Elements.Count > 0 ? parsed.First.Rows : new List<Dictionary<string,object?>>();
        var seq = await _audit.AppendAsync(new AuditRecord(Name, args, requestXml, status.Code, status.Severity, status.Message), ct); // audits even on Error
        return new Dictionary<string,object?> { ["status"]=status, ["rows"]=rows, ["auditSeq"]=seq, ["rawSpilledTo"]=parsed.RawSpilledTo };
        // NO retry, NO re-fetch-and-resubmit on 3200.
    }
}
```
`*ModRq` child order is schema-sensitive — emit `<{ListID|TxnID}>` first, then `<EditSequence>`, then the rest in the same order they appeared in the `*Ret` (the parser preserves first-seen order in the `Dictionary`; if it doesn't, Phase 9 re-pins to the schema order). `mod`'s `OpsEndpoints` path is unchanged: `is IWriteOp && !AllowWrites` → 403 before `RunAsync` even runs; `/dryrun` → `DryRunAsync`.

### Anti-Patterns to Avoid
- **`mod`'s `BuildRequest` doing a COM read** — violates the `IWriteOp` contract (pure, synchronous, no I/O). Throw unless `args` carries the pre-resolved record.
- **Retrying / auto-fixing `3200`** — explicitly forbidden (WRITE-07, PITFALLS Pitfall 13, design §5). Return verbatim, audit it, done. The skill re-dry-runs.
- **Caching an `EditSequence` from an earlier call** — `mod`'s `RunAsync` MUST do its own fresh read. The dry-run's `EditSequence` is for *display*; by execute time it may be stale (that's the whole point).
- **Sending a partial `*Mod`** — `*ModRq` is full-replace; a `<CustomerMod>` with only `<Name>` and `<EditSequence>` wipes `CompanyName`, `BillAddress`, etc. Always merge over the current `*Ret`.
- **`double` for money/quantity** — use `decimal` + `CultureInfo.InvariantCulture` + fixed precision (Pitfall 17). qbXML wants plain decimal strings; locale formatting (commas, `$`) gets rejected; `double` rounding can make a JE not balance and QB rejects it.
- **`ArgumentException` vs QB business error confusion** — caller-side validation (missing required arg, imbalanced JE, currency-bearing write, unknown `mod` entity, bad arg shape) → `ArgumentException` → 400 → qbXML never sent. A QB-side rejection (name in use, invalid ref, stale `EditSequence`, locked record) → comes back in `parsed.Message` as `statusCode != 0` → returned in `{status:...}` as **200**, audited. Never throw on the latter.
- **Treating `*ModRs`/`*AddRs` with `statusCode != 0` as a thrown error** — `WriteOpBase.RunAsync` doesn't, and Phase-7 `mod`'s overridden `RunAsync` mustn't either. (`QbXmlParser.Parse` only throws on *malformed XML* — `QbXmlParseException` — never on a non-zero `statusCode`.)
- **Substring-detecting currency** — check `args["currencyRef"]` / `args["exchangeRate"]` keys, not a substring of the built XML.

## Don't Hand-Roll

| Problem | Don't build | Use instead | Why |
|---------|-------------|-------------|-----|
| Building the qbXML envelope (`<?xml?>`, `<?qbxml version?>` PI, `<QBXML><QBXMLMsgsRq onError=...>`) | A string template per op | `QbXmlBuilder.Rq("CustomerAddRq", add)` + `_builder.BuildRequest(...)` | The builder pins the version PI from config, escapes via `XDocument.Save`, and is the byte-exact contract the dry-run/tests assert against. Hand-rolled strings drift. |
| Parsing the `*AddRs`/`*ModRs` | Custom XML walking | `_xmlParser.Parse(rawResponse)` → `{Message, Elements[0].Rows, RawSpilledTo}` | Already handles per-message + per-element `statusCode/Severity/Message`, nested complex elements → nested dicts, repeated → list, `DataExtRet` → `customFields`, the spill marker. |
| The `AllowWrites` 403 gate | A check inside each op | Inherited `WriteOpBase.RunAsync` (`throw QbWriteForbiddenException`) + `OpsEndpoints` `is IWriteOp && !AllowWrites` 403 + `QbConnectionManager` defensive belt | Four layers already, all tested. Phase-7 `mod`'s overridden `RunAsync` just needs to keep the `if (!AllowWrites) throw QbWriteForbiddenException` line. |
| The audit row | A custom log line | `_audit.AppendAsync(new AuditRecord(Name, args, requestXml, status.Code, status.Severity, status.Message), ct)` | Hash-chained, UTC, `requesterId`, canonical bytes — already done. Exactly one call per executed write; none on dry-run/refused/COM-fail. |
| Reading the current record + `EditSequence` for `mod` | A bespoke query | A `{Entity}QueryRq` by `ListID`/`TxnID` via the inherited `QuerySingleAsync` (wrap in `FetchCurrentAsync`) | The parser already gives you the full record as a `Dictionary` including `EditSequence`. The merge is "dict ⊕ fields → XElement children". |
| Refusing multi-currency writes | A `PreferencesQueryRq` round-trip on every write | `MultiCurrencyGuard.Reject(args)` (key check, throws `ArgumentException`) | v1 *refuses* currency-bearing writes outright (design out-of-scope) — you don't need to know if the file has multi-currency on; you just reject `currencyRef`/`exchangeRate` args. Cheaper, no round-trip, no false "healthy" if the prefs read fails. |
| Detecting an imbalanced JE | Trusting QB to reject it | A `Validate(args)` (sum debits == sum credits, `decimal`, invariant) at the top of `BuildRequest` + `DryRunAsync` → `ArgumentException` → 400 | Pre-flight must reject it *before* building/sending the qbXML (WRITE-06); also `double` rounding could let an "almost balanced" JE through to QB. |
| Date formatting | `.ToString()` | `dateOnly.ToString("yyyy-MM-dd")` / `ArgReader.Date(args, key)` | qbXML dates are `yyyy-MM-dd`; `ArgReader.Date` already parses + validates (the Phase-4 ops use exactly this). |

**Key insight:** Phase 7 is *almost entirely* "translate `args` → the right `XElement` tree, hand it to `QbXmlBuilder`, let the inherited `RunAsync` do the rest." The only genuine new machinery is (a) the `mod` read→merge→strip→build flow and (b) two `protected` fetch helpers on `WriteOpBase`. Everything else is data: which children, in which order, which are required, which are read-only.

## Common Pitfalls

### Pitfall 1: stale `EditSequence` on `mod_*` (the #1 write failure)
**What goes wrong:** the target object was changed in QuickBooks between the `mod`'s read and its `*ModRq` submit → QB returns a `*ModRs` with `statusCode` for "edit sequence out of date".
**Why:** qbXML optimistic concurrency — you must echo back the *current* `EditSequence`, and the window between read and write is exactly where another change can land.
**How to avoid:** `mod`'s `RunAsync` does its OWN fresh read immediately before building the `*ModRq` (don't reuse the dry-run's `EditSequence` — by then it may be stale). When QB still rejects with the stale code: **return it verbatim** (`{status:{code, severity:"Error", message}}`, 200), **audit the failed attempt** (`WriteOpBase`/`mod.RunAsync` always audits regardless of severity), **do NOT retry, do NOT auto-fetch-and-resubmit**. The skill (Phase 8) re-runs `/dryrun` (fresh read → new `EditSequence`) and re-confirms.
**The status code:** `0x800404C5` is the COM HRESULT *name*. In a qbXML *response*, a stale `EditSequence` surfaces as **`statusCode="3200"`, `statusMessage="The provided edit sequence is out-of-date."` `statusSeverity="Error"`** (corroborated by the QB status-code search this session + consolibyte forum threads on `*Mod` 3200; this is the qbXML-level code, distinct from the HRESULT). **CONFIDENCE: MEDIUM — use `3200` in the `InvoiceModRs.stale.qbxml` fixture, and flag it for Phase-9 re-pin against the live host (it could conceivably be `3170`/`3175`/`3180` on some builds; `3200` is the best-supported answer).** (Aside: `QbErrors.cs` maps the *HRESULT* `0x800404C5` — but `QbXmlParser` never throws for a non-zero `statusCode`, so `QbErrors` isn't on this path; the `3200` goes straight into `QbStatus` and out the 200 body.)
**Warning signs:** a `*ModRq` test that asserts a retry / a second `ProcessRequests` entry — there must be exactly ONE `*ModRq` sent and ZERO retries; the audit row must record the `3200` Error status.

### Pitfall 2: `*ModRq` is full-replace, not a patch
**What goes wrong:** a `mod` that sends only the changed fields wipes everything else on the object.
**How to avoid:** the merge is `current *Ret dict ⊕ fields → *Mod children` — carry over EVERY current child (except the read-only/computed strip-list), then overlay the supplied `fields`. The dry-run summary must show the field-level before/after diff (via `DiffFields`) so a partial-overwrite is visible before it commits.
**Warning signs:** a `mod` dry-run whose `qbXml` is missing children that were in the `*Ret`; a `DiffFields` that only lists the changed keys but the `*ModRq` doesn't carry the unchanged ones.

### Pitfall 3: read-only / computed fields can't go in `*Mod`
**What goes wrong:** the `*ModRq` includes `<TimeCreated>` / `<TimeModified>` / a computed `<TotalAmount>` / `<Balance>` / `<TxnNumber>` / a `<DataExtRet>`-shaped block → QB rejects with a validation error.
**How to avoid:** strip a known set from the merged record before emitting `*Mod` children (the `ReadOnlyChildren["*"]` + per-entity lists in Pattern 4). **CONFIDENCE: MEDIUM — the obvious ones (`TimeCreated`, `TimeModified`, `DataExtRet`) are safe; the per-entity computed-total list is best-effort and a Phase-9 re-pin item (the live host's `*ModRq` schema is authoritative).** Note `DataExtRet` (read) ≠ `DataExtMod` (write) — custom-field *writes* are a v1.x item; for v1 just strip `DataExtRet` from the mod body.
**Warning signs:** a `*ModRq` golden test fixture that includes `TimeCreated`.

### Pitfall 4: `RefNumber` is not a key
**What goes wrong:** a `mod` keyed on `RefNumber` hits the wrong record (or several) — `RefNumber` is user-editable and non-unique.
**How to avoid:** `mod`'s `ref` accepts `txnID` (transactions) / `listID` (list entities) / `fullName` (list entities only, unique enough for Customer/Vendor). Reject `refNumber` as a `mod` key (`get_transaction` may resolve `refNumber → txnID` for the *caller* to then `mod` by `txnID`). Same `ListID` vs `TxnID` discipline as the read ops.

### Pitfall 5: money/quantity formatting
**What goes wrong:** `1,234.50` or `$1234.5` or a `double`-rounded `0.30000000000000004` gets rejected by QB, or makes a JE not balance.
**How to avoid:** `ArgReader.Decimal` parses with `NumberStyles.Number` + `CultureInfo.InvariantCulture`; emit with `.ToString(CultureInfo.InvariantCulture)` (or a fixed `"0.00"` for amounts, `"0.#####"` for quantities — match what the live host accepts; Phase-9 re-pin). JE balance check uses `decimal`.

### Pitfall 6: forgetting the `is IWriteOp` registration → 403 path doesn't apply
**What goes wrong:** if a write op is registered as `IReadOp` but the dispatch only checks `is IWriteOp` (it does) — fine. But if a write op accidentally *doesn't* implement `IWriteOp` (e.g. someone makes it `: ReadOpBase` instead of `: WriteOpBase`), it bypasses the 403 gate and the audit log.
**How to avoid:** every Phase-7 write op is `: WriteOpBase` (which `: ReadOpBase, IWriteOp`); `OpRegistrationTests` should assert each new op `is IWriteOp` (not just that it resolves).

### Pitfall 7: `ApiExceptionHandler` ↔ `ArgumentException` mapping
**What goes wrong:** assuming a thrown `ArgumentException` from an op becomes a 500.
**Reality:** it becomes 400 — the Phase-4 read ops already rely on this (`get_transaction` throws `ArgumentException` for "supply exactly one of txnId or refNumber" → 400; `OpsEndpoints.ReadArgsAsync` throws `ArgumentException` for a non-object body → 400). So Phase-7 ops should throw `ArgumentException` for ALL caller-side validation (missing required field, imbalanced JE, currency-bearing write, unknown `mod` entity, bad arg shape, `mod` target not found). Verify the handler maps `ArgumentException` (not just `ValidationException`) — check `ApiExceptionHandler.cs`; if it only maps a narrower type, the planner should note "ops throw `ArgumentException`; confirm the handler maps it to 400 (Phase 4 ops already do)".

## Code Examples

### `WriteOpHelpers` (new)
```csharp
// Source: derived from QbXmlBuilder.cs + consolibyte/quickbooks-php schema (BillAddress/Address = Addr1-5,City,State,PostalCode,Country,Note)
internal static class WriteOpHelpers
{
    public static void RejectMultiCurrency(IReadOnlyDictionary<string, object?> args)  // == MultiCurrencyGuard.Reject
    {
        if (ArgReader.String(args, "currencyRef") is not null
            || ArgReader.Dict(args, "currencyRef") is not null
            || ArgReader.String(args, "exchangeRate") is not null)
            throw new ArgumentException("multi-currency is not supported in v1; remove 'currencyRef'/'exchangeRate' (v2 item).");
    }

    public static XElement? RefElement(string elementName, IReadOnlyDictionary<string, object?> args, string key)
    {
        if (ArgReader.String(args, key) is { } full) return new XElement(elementName, new XElement("FullName", full));
        if (ArgReader.Dict(args, key) is { } d)
        {
            if (ArgReader.String(d, "listID") is { } id) return new XElement(elementName, new XElement("ListID", id));
            if (ArgReader.String(d, "fullName") is { } fn) return new XElement(elementName, new XElement("FullName", fn));
        }
        return null;
    }

    public static string? RefValue(IReadOnlyDictionary<string, object?> args, string key) =>  // for ResolvedReferences display
        ArgReader.String(args, key) ?? (ArgReader.Dict(args, key) is { } d ? ArgReader.String(d, "fullName") ?? ArgReader.String(d, "listID") : null);

    public static XElement? AddressElement(string elementName, IReadOnlyDictionary<string, object?>? d)
    {
        if (d is null) return null;
        var e = new XElement(elementName);
        foreach (var (argKey, xmlName) in new[] {
            ("addr1","Addr1"),("addr2","Addr2"),("addr3","Addr3"),("addr4","Addr4"),("addr5","Addr5"),
            ("city","City"),("state","State"),("postalCode","PostalCode"),("country","Country"),("note","Note") })
            if (ArgReader.String(d, argKey) is { } v) e.Add(new XElement(xmlName, v));
        return e.HasElements ? e : null;
    }
}
```

### `WriteOpBase` additions (fill the `// TODO(Phase 7)` slot)
```csharp
// Source: derived from ReadOpBase.QuerySingleAsync + PITFALLS Pitfall 13
private static readonly HashSet<string> TxnEntities = new(StringComparer.OrdinalIgnoreCase)
    { "Invoice", "Bill", "Check", "ReceivePayment", "JournalEntry", "SalesReceipt", "CreditMemo", "PurchaseOrder", "Estimate", "BillPaymentCheck", "Deposit" };

protected async Task<IReadOnlyDictionary<string, object?>?> FetchByNameAsync(string entity, string fullName, CancellationToken ct)
{
    var rq = QbXmlBuilder.Rq(entity + "QueryRq", new XElement("FullName", fullName));   // list-entity name lookup
    var parsed = await QuerySingleAsync(rq, ct);
    return parsed.Elements.Count > 0 ? parsed.First.Rows.FirstOrDefault() : null;
}

protected async Task<(IReadOnlyDictionary<string, object?> Record, string EditSequence)?> FetchCurrentAsync(
    string entity, string refKind, string refValue, CancellationToken ct)
{
    var idEl = refKind switch
    {
        "txnID"   => new XElement("TxnIDList", new XElement("TxnID", refValue)),
        "listID"  => new XElement("ListIDList", new XElement("ListID", refValue)),
        "fullName"=> new XElement("FullNameList", new XElement("FullName", refValue)),
        _ => throw new ArgumentException($"mod: ref must be one of txnID/listID/fullName; got '{refKind}'.")
    };
    // NOTE: list entities use ListIDList/FullNameList; txn entities use TxnIDList; some txn queries want a TransactionTypeList too.
    var rq = TxnEntities.Contains(entity)
        ? QbXmlBuilder.Rq(entity + "QueryRq", idEl)            // e.g. <InvoiceQueryRq><TxnIDList><TxnID>...</TxnID></TxnIDList></InvoiceQueryRq>
        : QbXmlBuilder.Rq(entity + "QueryRq", idEl);           // e.g. <CustomerQueryRq><ListIDList><ListID>...</ListID></ListIDList></CustomerQueryRq>
    var parsed = await QuerySingleAsync(rq, ct);
    var row = parsed.Elements.Count > 0 ? parsed.First.Rows.FirstOrDefault() : null;
    if (row is null) return null;
    var es = row.GetValueOrDefault("EditSequence") as string
             ?? throw new ArgumentException($"mod: {entity} record has no EditSequence — cannot modify.");
    return (row, es);
}
```
(The exact `ListIDList`/`FullNameList`/`TxnIDList` wrapper names + per-entity query-filter elements are Phase-9 re-pin items; `GetTransactionOp` already uses `<TxnIDList><TxnID>…</TxnID></TxnIDList>` and `<RefNumberFilter>`, so that's the established pattern in-repo.)

### Per-op test fixture shape (copy `WriteOpBaseTests.CreateFixture`)
```csharp
// Source: WriteOpBaseTests.cs CreateFixture — the canonical write-op test harness
// 1. temp audit dir; 2. FakeRequestProcessor; 3. QbConnectionManager(() => fake, QbOptions, RequestOptions, NullLogger, SafetyOptions{AllowWrites});
// 4. QbXmlOptions{Version="16.0",...}; QbXmlBuilder; QbXmlParser; QbReportParser; QbResponseSpiller(.. inmemory config Audit:Path=auditDir);
//    QbListExecutor; AuditLog(AuditOptions{Path=auditDir}, AuditAuthOptions{ApiToken="test-token"}, NullLogger);
// 5. new CreateCustomerOp(builder, manager, parser, reportParser, listExecutor, audit, Options.Create(new SafetyOptions{AllowWrites}));
// dry-run: op.DryRunAsync(args) -> assert QbXml == op.BuildRequest(args), PreFlight non-empty, fake.ProcessRequests empty (except a pre-flight READ if the op does one), no audit.jsonl;
//   (NOTE: a create_* DryRunAsync that does FetchByNameAsync WILL send a *QueryRq -> the fake needs AddResponse("CustomerQueryRq", <zero-rows or a hit>) and fake.ProcessRequests will have that one READ but no WRITE; assert no *AddRq was sent and no audit row.)
// execute (AllowWrites=true): fake.AddResponse("CustomerAddRq", <CustomerAddRs ...>); op.RunAsync(args);
//   assert fake.ProcessRequests last entry == op.BuildRequest(args) byte-exact, exactly one audit.jsonl row, row["op"]=="create_customer", row["responseStatusCode"]=="0";
// execute with QB business error: AddResponse returns statusCode="3100" Error -> RunAsync returns {status:{code:"3100",...}} 200, ONE audit row with responseStatusCode "3100", responseStatusSeverity "Error";
// execute AllowWrites=false: ThrowsAsync<QbWriteForbiddenException>, no ProcessRequests, no audit.jsonl;
// COM failure: fake.EnqueueComError(0x80040408) -> ThrowsAsync<QbException>, no audit row.
// create_journal_entry imbalanced: ThrowsAsync<ArgumentException> from DryRunAsync AND from BuildRequest; no ProcessRequests, no audit.
// mod stale: AddResponses("InvoiceQueryRq", <InvoiceQueryRs with EditSequence "X">) then AddResponse("InvoiceModRq", <InvoiceModRs statusCode="3200" Error>) -> RunAsync returns {status:{code:"3200",severity:"Error"}}, exactly ONE InvoiceModRq in ProcessRequests, ONE audit row recording the 3200 Error, NO retry.
```

### qbXML element shapes (the data Phase 7 needs — MEDIUM confidence, Phase-9 re-pin)
Verified-ish against consolibyte/quickbooks-php schema files + the quickbooksdesktopapi.com simulator + Intuit SDK samples readme. Required-vs-optional from the schemas; element *order* matters in the qbXML schema (emit in this order):

| Op / request | `*Add` children (order) — **bold = required** | Line element + key children |
|---|---|---|
| `create_customer` `CustomerAddRq`/`CustomerAdd` | **Name**, IsActive, ParentRef, CompanyName, Salutation, FirstName, MiddleName, LastName, Suffix, BillAddress, ShipAddress, PrintAs, Phone, Mobile, Pager, AltPhone, Fax, Email, Contact, AltContact, CustomerTypeRef, **TermsRef**(opt), SalesRepRef, OpenBalance, OpenBalanceDate, SalesTaxCodeRef, ItemSalesTaxRef, … (v1 maps: name→Name, companyName→CompanyName, firstName/lastName→First/LastName, billAddress/shipAddress→Bill/ShipAddress{Addr1-5,City,State,PostalCode,Country,Note}, phone→Phone, email→Email, terms→TermsRef) | n/a |
| `create_vendor` `VendorAddRq`/`VendorAdd` | **Name**, IsActive, CompanyName, Salutation, FirstName, MiddleName, LastName, Suffix, VendorAddress{Addr1-5,City,State,PostalCode,Country,Note}, Phone, Mobile, Pager, AltPhone, Fax, Email, Contact, AltContact, NameOnCheck, AccountNumber, Notes, VendorTypeRef, TermsRef, … | n/a |
| `create_invoice` `InvoiceAddRq`/`InvoiceAdd` | **CustomerRef**, ClassRef, ARAccountRef, TemplateRef, TxnDate, RefNumber, BillAddress, ShipAddress, IsPending, PONumber, TermsRef, DueDate, SalesRepRef, FOB, ShipDate, ShipMethodRef, ItemSalesTaxRef, Memo, CustomerMsgRef, IsToBePrinted, IsToBeEmailed, IsTaxIncluded, CustomerSalesTaxCodeRef, Other, ExchangeRate, **≥1 InvoiceLineAdd** | `InvoiceLineAdd`: ItemRef, Desc, Quantity, UnitOfMeasure, Rate **or** RatePercent, PriceLevelRef, ClassRef, Amount, ServiceDate, SalesTaxCodeRef, … (omit `TxnLineID` for new lines). Also `InvoiceLineGroupAdd` (ItemGroupRef, Desc, Quantity) — v1 may skip groups. |
| `create_bill` `BillAddRq`/`BillAdd` | **VendorRef**, APAccountRef, TxnDate, DueDate, RefNumber, TermsRef, Memo, IsTaxIncluded, SalesTaxCodeRef, LinkToTxnID*, **≥1 of ExpenseLineAdd / ItemLineAdd / ItemGroupLineAdd** | `ExpenseLineAdd`: AccountRef, Amount, TaxAmount, Memo, CustomerRef, ClassRef, SalesTaxCodeRef, BillableStatus. `ItemLineAdd`: ItemRef, Desc, Quantity, UnitOfMeasure, Cost, Amount, CustomerRef, ClassRef, BillableStatus, … |
| `create_check` `CheckAddRq`/`CheckAdd` | **AccountRef** (bank account), PayeeEntityRef, RefNumber (check number), TxnDate, Memo, Address{Addr1-5,City,State,PostalCode,Country,Note}, IsToBePrinted, IsTaxIncluded, SalesTaxCodeRef, ApplyCheckToTxnAdd{TxnID}, **≥1 of ExpenseLineAdd / ItemLineAdd / ItemGroupLineAdd** | `ExpenseLineAdd` / `ItemLineAdd` — same children as Bill's. |
| `receive_payment` `ReceivePaymentAddRq`/`ReceivePaymentAdd` | **CustomerRef**, ARAccountRef, TxnDate, RefNumber, TotalAmount, PaymentMethodRef, Memo, DepositToAccountRef, CreditCardTxnInfo, IsAutoApply, **(IsAutoApply=true OR ≥1 AppliedToTxnAdd)** | `AppliedToTxnAdd`: **TxnID** (the open invoice's TxnID), **PaymentAmount**, TxnLineDetail{TxnLineID,Amount}, SetCredit{CreditTxnID,TxnLineID,AppliedAmount}, DiscountAmount, DiscountAccountRef. (If neither IsAutoApply nor AppliedToTxnAdd: QB leaves the payment unapplied — surface that.) |
| `create_journal_entry` `JournalEntryAddRq`/`JournalEntryAdd` | TxnDate, RefNumber, Memo, IsAdjustment, **≥1 JournalDebitLine + ≥1 JournalCreditLine, sum(debit Amount)==sum(credit Amount)** | `JournalDebitLine` / `JournalCreditLine` (identical shape): AccountRef, **Amount**, Memo, EntityRef, ClassRef, ItemSalesTaxRef, BillableStatus. (omit `TxnLineID` for new lines.) |
| `mod` `{Entity}ModRq`/`{Entity}Mod` | `<ListID>` (list entities) **or** `<TxnID>` (txns) first, then `<EditSequence>`, then **all current `*Ret` children** except the read-only/computed strip-list, with the supplied `fields` overlaid. Line items on txn `*Mod`s are *also* full-replace (echo the current lines, each with its `<TxnLineID>` from the `*Ret`, plus any line edits) — **v1 `mod` may restrict to header-level field edits and refuse `fields` that touch line items** (flag this for the planner; full line-level mod is a v1.x item). | n/a — `mod` emits children from the merged dict. |

All of the above element/child names are **MEDIUM confidence** (schema-file + simulator + samples, not live-pinned). Phase 9 re-pins against `10.120.254.13`'s qbXML 16.0 schema. The `InvoiceAddRs.error.qbxml` fixture already exists from Phase 4-ish; the success `*AddRs` fixtures Phase 7 adds should be minimal: `<QBXML><QBXMLMsgsRs statusCode="0" ...><CustomerAddRs statusCode="0" ...><CustomerRet><ListID>...</ListID><Name>...</Name><EditSequence>...</EditSequence></CustomerRet></CustomerAddRs></QBXMLMsgsRs></QBXML>`.

## State of the Art

| Old approach | Current approach | When changed | Impact |
|---|---|---|---|
| Phase-6 `WriteOpBase.DryRunAsync` stub (`BuildRequest`, generic "would send" summary, empty pre-flight) | Phase-7 ops **override** `DryRunAsync` with real pre-flight (entity-exists warnings, JE-balanced, multi-currency-refused, `mod` field-diff) | Phase 7 | The `/dryrun` endpoint becomes useful for the skill's confirm step; the byte-exact `qbXml` + `preFlight` + `resolvedReferences` + `summary` are the safety contract. |
| Phase-6 only write op is `FakeWriteOp` (test double) | Phase 7 adds 8 real write ops; `FakeWriteOp` stays as a test fixture (it's still registered in `QbWebAppFactory` and used by `WriteSafetyTests`/`DryRunEndpointTests`) | Phase 7 | Don't remove `FakeWriteOp`; the real ops are *additional*. `OpRegistrationTests` currently asserts "twelve read ops" — Phase 7 must update it (now ~12 read + 8 write = 20 `IReadOp` registrations in `Program.cs`, plus `FakeWriteOp` only in the test factory). |
| `IWriteOp.BuildRequest` assumed pure `args → XML` for all write ops | Still true for `create_*`; **`mod`'s `BuildRequest` throws unless pre-resolved** (the read-then-replace flow can't be pure) | Phase 7 | Documented exception; the planner should call this out in the `mod` task. |
| `ArgReader` has `String/Bool/Date/Dict` only | Phase 7 adds `List/Decimal/RequiredString` (line arrays, money, required fields) | Phase 7 | Small, low-risk; keep them `public static` like the rest. |

**Deprecated/outdated:** nothing — Phase 7 only adds. (The QBWC-polled design remains a README fallback note; not touched here.)

## Open Questions

1. **`mod` shape — generic vs per-entity (RECOMMEND GENERIC)**
   - What we know: generic `{entity, ref, fields}` with an entity whitelist + read-only-strip-list works mechanically (parsed `*Ret` dict ⊕ `fields` → `*Mod` children); the only entity-specific data is the whitelist and the strip-list.
   - What's unclear: whether `*Mod` child *order* (schema-sensitive) can be reproduced by emitting in `*Ret` first-seen order — probably yes (the parser preserves order in the `Dictionary`); if not, the `mod` op needs a per-entity child-order list (a Phase-9 re-pin).
   - Recommendation: **build the generic `mod` op.** Entity whitelist for v1: `customer, vendor, invoice, bill, check` (the entities that have both a v1 `create_*` AND a `*ModRq`). qbXML *also* supports `*ModRq` for Item* / Account / SalesReceipt / Estimate / PurchaseOrder / CreditMemo / JournalEntry / ReceivePayment / Class / Term / PaymentMethod / etc. — but keep v1's `mod` whitelist tight (the 5 above) and note "more entities promotable in v1.x". `mod` accepts `ref:{txnID}` for `invoice/bill/check`, `ref:{listID}` or `ref:{fullName}` for `customer/vendor`. Read-only children to strip: `["*"]: TimeCreated, TimeModified, DataExtRet`; per-entity computed totals (`Customer.Balance/TotalBalance`, `Invoice.Subtotal/SalesTaxTotal/TotalAmount/AppliedAmount/BalanceRemaining/IsPaid/TxnNumber`, `Bill.AmountDue/OpenAmount/IsPaid/TxnNumber`, `Check.TxnNumber`) — **best-effort, Phase-9 re-pins the authoritative list**. v1 `mod` restricts `fields` to header-level (refuse `fields` keys that map to line-item collections) — flag for planner.

2. **The stale-`EditSequence` qbXML `statusCode`**
   - What we know: `0x800404C5` is the COM HRESULT name; the qbXML-response code for "edit sequence out of date" is **`3200`** ("The provided edit sequence is out-of-date."), per the QB status-code search + consolibyte forum threads.
   - What's unclear: whether some QB Enterprise builds use a different code (`3170`/`3175`/`3180` have been seen for related "object not found / changed" conditions).
   - Recommendation: use `statusCode="3200" statusSeverity="Error" statusMessage="The provided edit sequence is out-of-date."` in the `InvoiceModRs.stale.qbxml` fixture; the *behavior* (return verbatim, audit, no retry) is code-agnostic so the test is robust; flag `3200` for Phase-9 re-pin.

3. **`ApiExceptionHandler` → 400 for `ArgumentException`**
   - What we know: Phase-4 read ops + `OpsEndpoints.ReadArgsAsync` throw `ArgumentException` and get 400 in practice (`GetTransactionOpTests`/`OpsEndpointTests` presumably cover it).
   - What's unclear: whether the handler maps `ArgumentException` specifically or a base type.
   - Recommendation: Phase-7 ops throw `ArgumentException` for all caller-side validation (consistent with Phase 4); planner adds a verification step "imbalanced JE / currency-bearing write / missing required field / unknown `mod` entity → 400 via `POST /api/ops/...`" — if it 500s, the handler needs an `ArgumentException` case (cheap fix). Read `Api/ApiExceptionHandler.cs` during planning to confirm.

4. **Pre-flight reads & `AllowWrites=false`**
   - What we know: `QbConnectionManager` refuses *write* qbXML when `AllowWrites=false`; *reads* are always allowed.
   - Confirmation needed: that a `*QueryRq` (built by `FetchByNameAsync`/`FetchCurrentAsync`) is recognized as a *read* by `QbWriteDetector`/the manager's defensive belt (it should be — no `Add`/`Mod`/`Del`/`Void` element). So a `mod` dry-run works even with `AllowWrites=false`. Planner adds a test for this.

5. **Does `CustomerQueryRs.normal.qbxml` carry an `EditSequence`?**
   - If yes, `mod customer` tests can reuse it for the read leg; if not, add `CustomerQueryRs.formod.qbxml`. (Check during planning — `CustomerQueryRs.normal.qbxml` is 542 bytes; likely minimal.)

## Suggested ordered task breakdown (atomic, one commit each; each `dotnet build` + `dotnet test` green with no QuickBooks)

1. **`WriteOpBase` pre-flight helpers + `WriteOpHelpers` + `ArgReader` extensions + base tests** — fill the `// TODO(Phase 7)` slot with `FetchByNameAsync` / `FetchCurrentAsync`; add `WriteOpHelpers.cs` (`RejectMultiCurrency`/`MultiCurrencyGuard.Reject`, `RefElement`, `RefValue`, `AddressElement`); add `ArgReader.List` / `ArgReader.Decimal` / `ArgReader.RequiredString`. Unit tests for each helper (pure, no COM — except the fetch helpers which go through the manager+fake).
2. **`create_customer` + `create_vendor`** — `CreateCustomerOp.cs`, `CreateVendorOp.cs`; `BuildRequest` (`MultiCurrencyGuard.Reject` + required `name` + map optionals) + `DryRunAsync` (name-present + name-not-in-use warn + resolve `terms` etc.) ; DI in `Program.cs`; fixtures `CustomerAddRs.qbxml`, `VendorAddRs.qbxml`, plus a `CustomerQueryRs.formod.qbxml`-style zero-rows-or-hit fixture for the name-resolution dry-run leg; tests (dry-run = byte-exact + pre-flight + the pre-flight READ but NO `*AddRq` + no audit; execute = byte-exact `*AddRq` + one audit row + status 0; execute QB error 3100 → 200 `{status}` + one audit row Error; `AllowWrites=false` → `QbWriteForbiddenException` + nothing; COM fail → `QbException` + no audit).
3. **`create_invoice`** — `CreateInvoiceOp.cs`; `BuildRequest` (`MultiCurrencyGuard.Reject` + required `customerRef` (`RefElement`) + ≥1 `InvoiceLineAdd` from `args["lines"]` each with `ItemRef`/`Desc`/`Quantity`/`Rate`-or-`Amount` + optional `txnDate`/`refNumber`/`billAddress`/`terms`/`dueDate`); `DryRunAsync` (refs resolve warn-not-fail, line count, total) ; DI; `InvoiceAddRs.success.qbxml` fixture; tests (incl. "no lines → `ArgumentException` → 400").
4. **`create_bill` + `create_check`** — `CreateBillOp.cs` (required `vendorRef` + ≥1 of `expenseLines`/`itemLines`), `CreateCheckOp.cs` (required `accountRef` (bank) + optional `payeeEntityRef`/`refNumber`(check #) + ≥1 of `expenseLines`/`itemLines`); shared `ExpenseLineAdd`/`ItemLineAdd` builders in `WriteOpHelpers`; DI; `BillAddRs.qbxml`, `CheckAddRs.qbxml` fixtures; tests.
5. **`receive_payment`** — `ReceivePaymentOp.cs`; `BuildRequest` (required `customerRef` + `(isAutoApply==true || ≥1 appliedTo)` else `ArgumentException`; each `AppliedToTxnAdd` = `TxnID` + `PaymentAmount`; optional `txnDate`/`refNumber`/`totalAmount`/`paymentMethodRef`/`depositToAccountRef`); `DryRunAsync` (warn if neither auto-apply nor explicit applications → "QB will leave it unapplied"); DI; `ReceivePaymentAddRs.qbxml` fixture; tests.
6. **`create_journal_entry`** — `CreateJournalEntryOp.cs`; private `Validate(args)` = `MultiCurrencyGuard.Reject` + parse `args["debits"]`/`args["credits"]` (each `{accountRef, amount, memo?, entityRef?}`) + `sum(debit amounts decimal) == sum(credit amounts decimal)` else `ArgumentException` — called line 1 of `BuildRequest` AND line 1 of `DryRunAsync`; `BuildRequest` emits `<JournalEntryAdd><TxnDate?/><RefNumber?/>{JournalDebitLine}*{JournalCreditLine}*</JournalEntryAdd>`; `DryRunAsync` shows the balanced totals; DI; `JournalEntryAddRs.qbxml` fixture; tests (balanced → builds + executes + audits; imbalanced → `ArgumentException` from both `DryRunAsync` and `BuildRequest`, NOTHING sent, no audit).
7. **`mod` (generic op)** — `ModOp.cs` `: WriteOpBase`, `Name => "mod"`; `ParseModArgs(args)` (entity in whitelist `{customer,vendor,invoice,bill,check}` else `ArgumentException`; `ref` exactly one of `txnID`/`listID`/`fullName`, `fullName` only for `customer`/`vendor` else `ArgumentException`; `fields` a dict, reject keys mapping to line collections in v1); `MergeStrip(entityRet, currentRow, fields)` (current ⊕ fields, drop `ReadOnlyChildren["*"]`+per-entity, return `(before,after)` as string-flattened dicts for `DiffFields`); `BuildModXml(entityRet, idElement, editSequence, mergedDict, args)` (`<{Entity}Mod>{ListID|TxnID}<EditSequence>…</EditSequence>…children…</{Entity}Mod>` wrapped in `{Entity}ModRq` → `_builder.BuildRequest`); `BuildRequest(args)` → throws `InvalidOperationException` unless `args` has `__resolvedRecord`+`__editSequence`; **override `DryRunAsync`** = `MultiCurrencyGuard.Reject` → `ParseModArgs` → `FetchCurrentAsync` (→ `ArgumentException` if not found) → `MergeStrip` → `BuildModXml` → return `{QbXml, "Update ... : <diff> (EditSequence X)", [target-resolves, edit-sequence-fresh, DiffFields], {target, editSequence}, AllowWrites}` — **does the read, sends ONE `*QueryRq`, NO `*ModRq`, NO audit**; **override `RunAsync`** = `MultiCurrencyGuard.Reject` → `ParseModArgs` → `if(!AllowWrites) throw QbWriteForbiddenException` → `FetchCurrentAsync` (FRESH) → `MergeStrip` → `BuildModXml` → `_manager.ExecuteAsync` → `_xmlParser.Parse` → `_audit.AppendAsync(new AuditRecord("mod", args, requestXml, status.Code, status.Severity, status.Message))` → `{status, rows, auditSeq, rawSpilledTo}` — **NO retry on 3200, NO re-fetch-and-resubmit**; DI; fixtures `CustomerQueryRs.formod.qbxml` (full record + `EditSequence`), `CustomerModRs.qbxml`, `InvoiceQueryRs.formod.qbxml`, `InvoiceModRs.stale.qbxml` (`statusCode="3200" statusSeverity="Error"`); tests (dry-run `mod customer` → reads (`AddResponse("CustomerQueryRq",...)`) → `QbXml` is the merged `*ModRq` carrying the read's `EditSequence` and ALL current children minus the strip-list → before/after diff in summary → ONE `*QueryRq` in `ProcessRequests`, NO `*ModRq`, no audit; execute `mod customer` happy → `AddResponses("CustomerQueryRq", <record>)` then `AddResponse("CustomerModRq", <CustomerModRs ok>)` → returns `{status:0}` + one audit row + the `*QueryRq` then exactly one `*ModRq` in `ProcessRequests`; execute `mod invoice` stale → `AddResponses("InvoiceQueryRq", <record EditSeq X>)` then `AddResponse("InvoiceModRq", <InvoiceModRs statusCode="3200" Error>)` → returns `{status:{code:"3200",severity:"Error"}}` 200 + ONE audit row recording the 3200 Error + exactly ONE `InvoiceModRq` (NO retry); `mod` with bad entity / bad ref / line-touching fields → `ArgumentException` → 400; `mod` with `AllowWrites=false` → `DryRunAsync` STILL works (only reads) but `RunAsync` → `QbWriteForbiddenException` (and `OpsEndpoints` 403s before that); `mod` target not found → `ArgumentException` → 400; `BuildRequest({})` directly → `InvalidOperationException`).
8. **DI sweep + `OpRegistrationTests` + final** — confirm all 8 write ops `AddSingleton<IReadOp, …>()` in `Program.cs` (alongside the 12 read ops); update `OpRegistrationTests` (now `12 read + 8 write = 20` `IReadOp` registrations there — actually `Program.cs` registers 20; the test's standalone host should mirror that, and assert each new write op name resolves AND `is IWriteOp`); add the 8 new op names to `OpTestHarness.Create` if tests use it; full `dotnet build` (Debug+Release) + `dotnet test` green; `07-01-SUMMARY.md`; tick WRITE-03..07 in REQUIREMENTS.md + Phase 7 boxes in ROADMAP.md + STATE.md (Codex commits its own per the established pattern).

(Could compress 3+4 into "the create_* transaction ops" or 2+3+4 into "the create_* ops" — but 8 atomic tasks is the more reviewable shape and matches the Phase-4 precedent of 8 distinct-titled `feat(04-01)` commits. Recommend keeping 8.)

## Sources

### Primary (HIGH confidence — read this session)
- In-repo Phase 1–6 code: `Qb/Ops/{IWriteOp,WriteOpBase,IReadOp,ReadOpBase,DryRunResult,ArgReader,OpRegistry,ListInvoicesOp,GetTransactionOp,CompanyPreferencesOp,RunQueryOp}.cs`, `QbXmlBuilder.cs`, `QbXmlParser.cs`, `QbXmlModels.cs`, `QbExceptions.cs`, `Audit/{AuditRecord}.cs`, `Program.cs`, `Api/OpsEndpoints.cs`, `Tests/{WriteOpBaseTests,DryRunEndpointTests,OpRegistrationTests,OpTestHarness,QbWebAppFactory}.cs`, `Tests/Fakes/{FakeWriteOp,FakeRequestProcessor}.cs`, fixture listing under `Tests/Fixtures/qbxml/`.
- `.planning/{PROJECT.md→STATE.md, ROADMAP.md, REQUIREMENTS.md}`, `.planning/research/{FEATURES,PITFALLS}.md`, `docs/superpowers/specs/2026-05-11-quickbooks-direct-sdk-accounting-design.md` (§4 op catalog, §5 write-safety, §8 testing).

### Secondary (MEDIUM confidence — web, this session)
- consolibyte/quickbooks-php qbXML schema files (raw GitHub): `QuickBooks/QBXML/Schema/Object/{CustomerAddRq,VendorAddRq,InvoiceAddRq,BillAddRq,CheckAddRq,ReceivePaymentAddRq,JournalEntryAddRq}.php` — element names + child order + required/optional + line-item children for every v1 `*Add`. https://github.com/consolibyte/quickbooks-php
- quickbooksdesktopapi.com simulator — `InvoiceAddRq` example confirming the `<?qbxml version="16.0"?><QBXML><QBXMLMsgsRq onError="stopOnError"><InvoiceAddRq><InvoiceAdd><CustomerRef><ListID>…</ListID></CustomerRef><InvoiceLineAdd><ItemRef><ListID>…</ListID></ItemRef><Desc/><Quantity/><Rate/></InvoiceLineAdd></InvoiceAdd></InvoiceAddRq></QBXMLMsgsRq></QBXML>` shape. https://quickbooksdesktopapi.com/simulator/invoices/create
- Intuit `QBXML_SDK_Samples` (GitHub) — `qbdt/c-sharp/QBFC/QBInvoiceAdd/InvoiceAdd.cs`, `readme.html` — corroborating `InvoiceLineAdd`/`ItemRef`/`Quantity`/`Rate`/`Amount` and that referenced customer/item must pre-exist (Add → 3100/3140 otherwise). https://github.com/IntuitDeveloper/QBXML_SDK_Samples
- WebSearch "qbXML statusCode 3200 EditSequence out of date" → "**3200: The provided edit sequence is out-of-date**" returned consistently across the QB status-codes PDF, consolibyte forum threads on `*Mod`, and QODBC's error tables. (HRESULT `0x800404C5` per `QbErrors.cs`/PITFALLS Pitfall 13 is the COM-side name; `3200` is the qbXML-response code.)

### Tertiary (LOW confidence — flagged for Phase-9 re-pin)
- Exact `*ModRq` child *order* and the complete read-only/computed-children strip-list per entity — best-effort here; the live host's qbXML 16.0 schema is authoritative.
- `ListIDList`/`FullNameList`/`TxnIDList` query-filter wrapper names for `FetchCurrentAsync` (in-repo `GetTransactionOp` already uses `<TxnIDList><TxnID>…</TxnID></TxnIDList>` so that one's near-HIGH).
- The `3200` code itself — strong but not live-confirmed; the test asserts behavior not the specific code, so robust either way.

## Metadata

**Confidence breakdown:**
- In-repo seam / patterns / DI / test harness: HIGH — read directly this session.
- `mod`-op design (generic, override `RunAsync`, `BuildRequest` throws): HIGH on the *shape* (forced by the `IWriteOp` contract + full-replace semantics + the no-retry rule), MEDIUM on the read-only-children strip-list and `*Mod` child-order details.
- qbXML `*AddRq`/`*ModRq` element + child names + required/optional: MEDIUM — corroborated across the consolibyte schema + simulator + Intuit samples, not live-pinned; consistent with the Phase-3/4 fixture-construction precedent (Phase 9 re-pins).
- Stale-`EditSequence` `statusCode` = `3200`: MEDIUM — strong web corroboration; behavior-not-code is what the test asserts.
- Pitfalls: HIGH — straight from `.planning/research/PITFALLS.md` Pitfall 13 + 17 + the Phase-6 audit/gate behavior in code.

**Research date:** 2026-05-11
**Valid until:** ~30 days for the in-repo seam (stable); the qbXML element-name + `3200`-code findings are "valid until Phase 9 re-pins them on `10.120.254.13`" — treat as provisional inputs to constructed fixtures, not as live-verified facts.

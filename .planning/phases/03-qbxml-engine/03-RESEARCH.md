# Phase 3: qbXML Engine - Research

**Researched:** 2026-05-11
**Domain:** Pure, I/O-free qbXML request building and response parsing in C#/.NET 8 with `System.Xml.Linq` — request envelope + version PI, status surfacing, polymorphic-Item normalization, the `ColDesc`/`ColData` report parser, the iterator (`Start`/`Continue`) runner over `QbConnectionManager`, and a size-guard spill-to-file. Builds on Phase 1 (`IRequestProcessor` seam + `FakeRequestProcessor`) and Phase 2 (`QbConnectionManager.ExecuteAsync` / `GetSupportedQbXmlVersionsAsync`). No QuickBooks needed — everything tests against `FakeRequestProcessor` via `QbConnectionManager`.

**Confidence:** HIGH for the qbXML envelope/version-PI/status mechanics, XLinq patterns, and the iterator protocol (long-stable qbXML spec, cross-checked against project research FEATURES.md/ARCHITECTURE.md/STACK.md, Intuit OSR/sample repo, ConsoliBYTE wiki, `to_qbxml`). HIGH for the report-response shape (`ReportRet` → `ColDesc` + `ReportData` → `DataRow`/`SubtotalRow`/`TotalRow`/`TextRow` with positional `ColData`/`RowData`) — confirmed by Intuit's "Preparing report requests" doc and the SDK sample repo. MEDIUM only on the *exact* attribute names inside `ColDesc` (`colID` vs `colTitle`/`ColTitle` vs `ColType` casing) and a couple of `DataExtRet` field names — these are flagged below and the planner should have Codex pin them from the OSR/a real `SDKTestPlus3` response when authoring fixtures; the *parser design is correct either way* because it is data-driven from whatever `ColDesc` actually says.

> This phase is executed by **Codex CLI** from the PLAN.md, then reviewed by Claude (bar: 100/100 — the reviewer scores code/functionality/quality). Be concrete: the PLAN should hand Codex exact class designs, method signatures, the XLinq code, the sample qbXML fixtures to commit, and a green-the-whole-way ordered task list. Phase 3 adds **zero new NuGet packages** unless the PLAN explicitly opts into `Verify.Xunit` for golden files (recommended *against* — plain string/JSON equality against committed fixtures is enough and dependency-free; see "Tests").

---

## Summary

Phase 3 is the **pure qbXML engine** that Phase 4's read ops (and Phase 7's writes, via Phase 6) will compose on top of. It is five small, mostly-pure pieces in the existing `QbConnectService.Qb.Com` project, namespace `QbConnectService.Qb` (consistent with Phase 2):

1. **`QbXmlBuilder`** (pure, no I/O) — wraps a caller-supplied `XElement` request body (a `*Rq` element, or a list of them) in the full `<?xml version="1.0" encoding="utf-8"?><?qbxml version="N.N"?><QBXML><QBXMLMsgsRq onError="stopOnError">…</QBXMLMsgsRq></QBXML>` envelope, with the qbXML version pulled from a new `QbXmlOptions` POCO. Helpers: `Rq(name, params XObject[] children)` to build a `*Rq` element for Phase 4 to fill, `WithIterator(queryElement, IteratorMode, iteratorId?, maxReturned?, requestId?)` to stamp iterator attributes (READ-03), `WithOwnerIdZero(queryElement)` to add `<OwnerID>0</OwnerID>` when custom-field data is wanted (READ-11). It exposes the chosen version string. Fully unit-testable with golden-string assertions.

2. **`QbXmlParser`** (pure, no I/O) — parses a raw qbXML *response* string into a clean `ParsedQbXmlResponse`: the message-level `QbStatus` (from `<QBXMLMsgsRs>`), plus a list of `ParsedElement` per `*Rs` element each carrying its own `QbStatus`, optional `iteratorID`/`iteratorRemainingCount`, and the body as a `List<Dictionary<string, object?>>` of normalized rows (one dict per `*Ret`). A zero-row result (`statusCode="1"`, "no matching record(s)") parses as a **successful empty result**, not an error (READ-01). `DataExtRet` blocks inside a `*Ret` are surfaced as a nested `customFields` list. Polymorphic Item shapes (`ItemServiceRet`/`ItemInventoryRet`/…) are normalized into one row shape with a `type` discriminator (`"Service"`, `"Inventory"`, …) (READ-07's parser half lives here). Golden-testable.

3. **`QbReportParser`** (separate class, pure, no I/O — the research/spec said *separate*) — parses a `*ReportQueryRs` (`GeneralSummaryReportQueryRs`, `AgingReportQueryRs`, etc.) by reading `ColDesc` to learn the columns (no ordinal guessing), then walking `ReportData` rows (`DataRow`/`SubtotalRow`/`TotalRow`/`TextRow`) mapping each row's positional `ColData` (matched by `colID`) to the named columns, also capturing `RowData` (the row's label/group cell). Returns a `ParsedReport { Title, Subtitle, Basis?, Columns[], Rows[] }` where each row is `{ RowType, Label, Cells: Dictionary<colTitle, value> }`. Golden test against a committed sample report fixture (READ-02).

4. **`QbListExecutor`** (impure — does I/O via `QbConnectionManager`; belongs in Phase 3 per ROADMAP "list parsing follows qbXML iterators so a multi-page result comes back complete") — given a query `*Rq` `XElement` (without iterator attributes), it: stamps `iterator="Start" MaxReturned=<config>` via the builder, sends it through `QbConnectionManager.ExecuteAsync`, parses with `QbXmlParser`, then while `iteratorRemainingCount > 0` re-sends with `iterator="Continue" iteratorID=<from response>` (same `requestID`), accumulating rows from every page into one `ParsedQbXmlResponse`. Mid-iteration error (`statusSeverity="Error"`) → stop, surface that page's status. Tested against `FakeRequestProcessor` (page 1 has `iteratorRemainingCount>0` + an `iteratorID`; page 2 has `iteratorRemainingCount=0`).

5. **`QbResponseSpiller`** (small, I/O — used by `QbListExecutor`, and reusable by Phase 5's `/api/qbxml` later) — when the accumulated raw qbXML response (or any single raw response) exceeds `QbXml:MaxResponseBytes`, it writes the raw qbXML to `<QbXml:SpillPath>/<UTC-timestamp>-<guid>.qbxml` and returns the path; the result then carries `RawSpilledTo` instead of the full raw blob in memory. Configurable, sensible defaults.

Plus **config**: a new `QbXmlOptions` POCO (`Version` default `"16.0"`, `MaxReturned` default `100`, `MaxResponseBytes` default `5_000_000`, `SpillPath` default `""` meaning "fall back to `Audit:Path`"), bound from a `"QbXml"` section in `Program.cs`, with new keys in `appsettings.sample.json`. **Recommendation: move `OwnerIdZero` from `QbOptions` to `QbXmlOptions`** so all qbXML knobs live together — this is a tiny refactor (drop the property from `QbOptions.cs`, add it to `QbXmlOptions`, move the `"OwnerIdZero"` key under `"QbXml"` in `appsettings.sample.json`, update the `QbOptionsBindingTests`); flag it for the planner so Codex does it deliberately as one task. (If the planner prefers minimal churn, leaving `OwnerIdZero` in `QbOptions` and having `QbXmlBuilder` take *both* `IOptions<QbXmlOptions>` and `IOptions<QbOptions>` also works — but the move is cleaner and READ-11 just wants it "a documented config setting with a sensible default", default `false`, which it already is.)

**Primary recommendation:** `QbXmlBuilder` wraps a caller-built `XElement` body + the version PI + `onError` + (optionally) iterator attrs / `<OwnerID>0`; `QbXmlParser` returns `ParsedQbXmlResponse { Message: QbStatus, Elements: List<ParsedElement> }` with rows as `List<Dictionary<string,object?>>` and zero-row-as-success; `QbReportParser` is a separate, `ColDesc`-driven parser returning `ParsedReport`; `QbListExecutor(QbConnectionManager, QbXmlBuilder, QbXmlParser, QbResponseSpiller, IOptions<QbXmlOptions>)` runs Start→Continue→done; `QbResponseSpiller` does the size-guard write; `QbXmlOptions` holds `Version`/`MaxReturned`/`MaxResponseBytes`/`SpillPath` and (moved) `OwnerIdZero`; register the pure ones (`QbXmlBuilder`, `QbXmlParser`, `QbReportParser`) and `QbResponseSpiller` and `QbListExecutor` as singletons in `Program.cs` (all stateless or depending only on singletons); commit small `.qbxml` fixture files under `QbConnectService.Tests/Fixtures/qbxml/`.

---

## Standard Stack

### Core (already in the project — no new packages)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `System.Xml.Linq` (`XDocument`, `XElement`, `XProcessingInstruction`, `XDeclaration`, `XAttribute`) — in-box | net8.0 | Build the qbXML request envelope (incl. the `<?qbxml version?>` PI) and parse the response | `STACK.md` is explicit: "hand-roll qbXML with `System.Xml.Linq`; do NOT pull in QBFC". XLinq's `XProcessingInstruction` is the clean way to emit `<?qbxml version="16.0"?>` at document level alongside the `<?xml ...?>` declaration. Zero deps. |
| `System.Text.Json` (`JsonSerializer`, `JsonNode`) — in-box | net8.0 | (Only if the planner wants the parsed body as `JsonNode` instead of `List<Dictionary<string,object?>>` — see Q2; the recommendation is the dictionary list, which needs no JSON lib at all, but `System.Text.Json` is available if the API layer later wants to serialize it) | In-box; the recommendation doesn't depend on it for parsing. |
| `Microsoft.Extensions.Options` (`IOptions<T>`) — in-box w/ host | 8.0.x | Bind `QbXmlOptions` from `appsettings.json`; inject into `QbXmlBuilder` / `QbListExecutor` | Same pattern Phase 2 used for `QbOptions`/`RequestOptions`. |
| `Microsoft.Extensions.Logging` (`ILogger<T>`) — in-box | 8.0.x | `QbListExecutor` logs page count / spill events; parsers log nothing (pure) | Host already has logging wired. |
| `Microsoft.Extensions.DependencyInjection` (`AddSingleton`) — in-box | 8.0.x | Register the engine pieces in `Program.cs` | Phase 2's `QbConnectionManager` is already a singleton; the engine pieces hang off it. |
| Phase-2 `QbConnectionManager` | (in repo) | The I/O door — `QbListExecutor` calls `Task<string> ExecuteAsync(string qbXmlRequest, CancellationToken)` for each iterator page; engine never touches `IRequestProcessor` directly | Already serialized/STA/watchdog/dead-ticket-retried; Phase 3 produces the request string and parses the response string. |
| Phase-1 `FakeRequestProcessor` | (in test project) | Drives `QbListExecutor`/spiller tests via `QbConnectionManager` | Keyed by `*Rq` element name; has `ProcessRequestHook` + `AddResponse(name, xml)` + records args. **Needs a small extension for multi-page** — see "FakeRequestProcessor extension" below. |

### Supporting / optional

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Verify.Xunit` | latest | Snapshot/golden-file tests for `QbXmlBuilder` output and `QbXmlParser`/`QbReportParser` JSON | **Optional — recommended AGAINST for Phase 3.** `STACK.md` already calls it optional ("plain `Assert.Equal(expectedXml, actualXml)` against committed `.xml`/`.json` fixtures is just as good and has zero deps"). Phases 1 & 2 added zero new packages and reviewed 100/100; keep that streak. Use committed `.qbxml` request fixtures + `Assert.Equal` (normalize whitespace if needed) and committed `.json` expectation files compared via `JsonNode.DeepEquals` or string-equal-after-`JsonSerializer`-round-trip. If the planner *does* want `Verify.Xunit`, that's a defensible choice — just flag it as the one new dependency. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `System.Xml.Linq` | `XmlWriter`/`XmlReader` (lower-level, streaming) | XLinq is far more readable for hand-building small request trees and walking response trees; the responses here are never huge enough (post-spill-guard) to need streaming. Stick with XLinq, matching `STACK.md`. |
| `List<Dictionary<string,object?>>` for parsed rows | `JsonNode`/`JsonElement` per element | The dictionary list is the simplest thing Phase 4's ops can consume (`row["FullName"]`, `row["ListID"]`) and is trivially golden-testable by serializing it. `JsonNode` adds a dependency-flavored abstraction with no payoff here. **Recommend the dictionary list.** (Values are `string` for scalars, nested `List<Dictionary<...>>` for repeated child elements like line items / `DataExtRet`.) |
| `QbReportParser` as a separate class | A `ParseReport` method on `QbXmlParser` | The project research (FEATURES.md "Report parsing is unlike every other parser… budget for this separately"; ARCHITECTURE.md "the separate report parser") explicitly wants it separate. Keep it a distinct class — it shares nothing structural with the entity parser. |
| `QbResponseSpiller` as a class | A static method | A small instance class taking `IOptions<QbXmlOptions>` + `ILogger` is consistent with the rest and easy to inject/test (you can point `SpillPath` at a temp dir in tests). |
| Hand-rolled iterator loop in `QbListExecutor` | A generic "paged enumerable" abstraction | Over-engineering for v1; one tight loop is clearer and easier to review. |

**Installation:** None. Phase 3 adds **zero NuGet packages** (unless the planner opts into `Verify.Xunit` — recommended against).

---

## Architecture Patterns

### Recommended file layout (all in the existing `QbConnectService.Qb.Com` project)

```
quickbooks/QbConnectService/src/QbConnectService.Qb.Com/
├── QbXmlOptions.cs          # NEW: Version, MaxReturned, MaxResponseBytes, SpillPath, (moved) OwnerIdZero
├── QbXmlBuilder.cs          # NEW: pure — envelope + version PI + onError + iterator attrs + OwnerID; Rq() helper
├── QbXmlParser.cs           # NEW: pure — ParsedQbXmlResponse: status, rows, zero-row-as-success, DataExtRet, polymorphic Items
├── QbReportParser.cs        # NEW: pure — ColDesc-driven; DataRow/SubtotalRow/TotalRow/TextRow + RowData
├── QbXmlModels.cs           # NEW: records — QbStatus, ParsedQbXmlResponse, ParsedElement, ParsedReport, ReportRow, IteratorMode enum
├── QbResponseSpiller.cs     # NEW: I/O — size-guard spill-to-file
├── QbListExecutor.cs        # NEW: I/O via QbConnectionManager — Start→Continue→done accumulation
├── QbOptions.cs             # EDIT: remove OwnerIdZero (moved to QbXmlOptions)  [the small refactor]
└── (Phase 1/2 files unchanged)

quickbooks/QbConnectService/src/QbConnectService/
├── Program.cs               # EDIT: builder.Services.Configure<QbXmlOptions>(Configuration.GetSection("QbXml"));
│                            #       AddSingleton<QbXmlBuilder>(); AddSingleton<QbXmlParser>(); AddSingleton<QbReportParser>();
│                            #       AddSingleton<QbResponseSpiller>(); AddSingleton<QbListExecutor>();
└── appsettings.sample.json  # EDIT: "QbXml": { "Version": "16.0", "OwnerIdZero": false, "MaxReturned": 100,
                             #                  "MaxResponseBytes": 5000000, "SpillPath": "" }   (drop OwnerIdZero from "Qb")

quickbooks/QbConnectService/src/QbConnectService.Tests/
├── Fixtures/qbxml/          # NEW: committed sample .qbxml files (see "Fixtures to commit")
├── QbXmlBuilderTests.cs     # NEW: golden-string envelope/version/ownerId/iterator-attr tests
├── QbXmlParserTests.cs      # NEW: normal CustomerQueryRs, zero-row, DataExtRet, polymorphic Items, per-element error
├── QbReportParserTests.cs   # NEW: golden test against the report fixture
├── QbListExecutorTests.cs   # NEW: single-page; two-page accumulation; size-guard spill; mid-iteration error
├── QbResponseSpillerTests.cs# NEW (or fold into QbListExecutorTests): under/over threshold
├── QbXmlOptionsBindingTests.cs # NEW (or extend QbOptionsBindingTests): "QbXml" section binds with defaults
└── Fakes/FakeRequestProcessor.cs # EDIT: add multi-response support (queue per request name) — see below
```

### Pattern 1: `QbXmlBuilder` wraps a caller-built `XElement` body (the seam for Phase 4)

**What:** Phase 4's read ops build the `*Rq` body element (e.g. `<CustomerQueryRq><ActiveStatus>ActiveOnly</ActiveStatus><MaxReturned>…` minus the iterator attrs) and hand it to `QbXmlBuilder.BuildRequest(body)`. The builder only owns the *envelope*: the `<?xml ...?>` declaration, the `<?qbxml version="N.N"?>` PI from config, the `<QBXML>` root, and `<QBXMLMsgsRq onError="stopOnError">` around the body. This is the simplest seam — the builder never needs to know op-specific shapes; Phase 4 owns those.

**When to use:** Always. Reads call `BuildRequest(body)` (single op) or `BuildRequest(IEnumerable<XElement> bodies)` (the rare multi-element message). `QbListExecutor` calls the iterator-attr helper on the body first, then `BuildRequest`.

**Code — produces a correct envelope:**
```csharp
// QbXmlBuilder.cs  (pure, no I/O)
using System.Xml.Linq;
using Microsoft.Extensions.Options;

namespace QbConnectService.Qb;

public enum IteratorMode { None, Start, Continue }

public sealed class QbXmlBuilder
{
    private readonly QbXmlOptions _opts;
    public QbXmlBuilder(IOptions<QbXmlOptions> opts) => _opts = opts.Value;

    /// <summary>The qbXML spec version this builder targets (from config). Surfaced for /api/health later.</summary>
    public string Version => _opts.Version;

    /// <summary>Build a *Rq element from a name plus children (attributes + elements). Phase 4's ops use this.</summary>
    public static XElement Rq(string requestName, params object[] content) => new(requestName, content);

    /// <summary>Stamp iterator attributes on a query element. requestID defaults to "1" if not given.</summary>
    public static XElement WithIterator(XElement queryElement, IteratorMode mode,
                                        string? iteratorId = null, int? maxReturned = null, string requestId = "1")
    {
        if (mode == IteratorMode.None) return queryElement;
        queryElement.SetAttributeValue("requestID", requestId);
        queryElement.SetAttributeValue("iterator", mode == IteratorMode.Start ? "Start" : "Continue");
        if (mode == IteratorMode.Continue && iteratorId is not null)
            queryElement.SetAttributeValue("iteratorID", iteratorId);
        if (maxReturned is int m)
        {
            // MaxReturned is a CHILD ELEMENT on most query types, not an attribute. Put it first if present;
            // if the element already has one (op supplied it), leave the op's value alone.
            if (queryElement.Element("MaxReturned") is null)
                queryElement.AddFirst(new XElement("MaxReturned", m));
        }
        return queryElement;
    }

    /// <summary>Add &lt;OwnerID&gt;0&lt;/OwnerID&gt; to a query element so QuickBooks returns DataExtRet custom fields (READ-11).</summary>
    public static XElement WithOwnerIdZero(XElement queryElement)
    {
        if (queryElement.Element("OwnerID") is null) queryElement.Add(new XElement("OwnerID", "0"));
        return queryElement;
    }

    public string BuildRequest(XElement requestBody) => BuildRequest(new[] { requestBody });

    public string BuildRequest(IEnumerable<XElement> requestBodies)
    {
        var doc = new XDocument(
            new XDeclaration("1.0", "utf-8", null),                       // <?xml version="1.0" encoding="utf-8"?>
            new XProcessingInstruction("qbxml", $"version=\"{_opts.Version}\""), // <?qbxml version="16.0"?>
            new XElement("QBXML",
                new XElement("QBXMLMsgsRq",
                    new XAttribute("onError", "stopOnError"),
                    requestBodies)));
        // XDocument.ToString() omits the XML declaration; use a StringWriter/XmlWriter or string-concat the declaration.
        using var sw = new Utf8StringWriter();
        doc.Save(sw, SaveOptions.None);   // SaveOptions.None keeps indentation; use DisableFormatting if you want it tight
        return sw.ToString();
    }

    private sealed class Utf8StringWriter : System.IO.StringWriter
    { public override System.Text.Encoding Encoding => System.Text.Encoding.UTF8; }
}
```
Notes for the planner / Codex:
- **Emitting the declaration:** `XDocument.ToString()` and `XElement.Save()` *drop* the `<?xml ...?>` declaration by default. Saving to a `TextWriter`/`XmlWriter` preserves it. The `Utf8StringWriter` trick makes the declaration say `encoding="utf-8"`; QuickBooks accepts `utf-8`, `UTF-8`, and `US-ASCII` declarations. The reference `to_qbxml` and most samples use `encoding="US-ASCII"` or `utf-8`; either is fine — **pick one and pin it in a builder test** so it can't drift.
- **`onError`:** spec/scope says `onError="stopOnError"` on `<QBXMLMsgsRq>` for v1 (single op per message anyway). Make it a const; a future phase can parameterize.
- **`MaxReturned` is a child element**, not an attribute, on `CustomerQuery`/`VendorQuery`/`ItemQuery`/`InvoiceQuery`/… — verify against the OSR for each query type Phase 4 wires, but the `WithIterator` helper above handles it generically. (`iterator`, `iteratorID`, `requestID` *are* attributes.)
- **`OwnerID`** child element placement: it goes *inside* the `*Rq`, typically after the filters. The exact required position can be schema-strict in qbXML; Codex should validate any builder output that includes `<OwnerID>` against the OSR / `SDKTestPlus3` when authoring fixtures. The parser side (surfacing `DataExtRet`) is position-independent.

### Pattern 2: `QbXmlParser` → `ParsedQbXmlResponse` (status + normalized rows; zero-row = success)

**What:** Parse `<QBXML><QBXMLMsgsRs>` → read the message-level status off `<QBXMLMsgsRs>` (some QuickBooks builds put status on the wrapper, some don't — be defensive: if absent, synthesize "OK"), then for each child `*Rs` element produce a `ParsedElement` with: its own `QbStatus` (`statusCode`/`statusSeverity`/`statusMessage` attributes), optional `IteratorID`/`IteratorRemaining` (attributes present only on query responses with active iterators), and `Rows` = each child `*Ret` turned into a flat-ish `Dictionary<string,object?>` (scalar leaf → string; repeated child element name → `List<Dictionary<...>>`; `DataExtRet` collected under a `"customFields"` key as `List<{OwnerID, DataExtName, DataExtType, DataExtValue}>`). Polymorphic Items: when the `*Ret` name is one of `ItemServiceRet`/`ItemInventoryRet`/`ItemNonInventoryRet`/`ItemInventoryAssemblyRet`/`ItemFixedAssetRet`/`ItemOtherChargeRet`/`ItemSubtotalRet`/`ItemDiscountRet`/`ItemPaymentRet`/`ItemSalesTaxRet`/`ItemSalesTaxGroupRet`/`ItemGroupRet`, set `row["type"]` to the part before `Ret` after `Item` (`"Service"`, `"Inventory"`, …) and keep the union of fields. (Phase 4's `list_items` consumes these rows directly.)

**Zero-row detection (READ-01):** the canonical "no matching record(s)" response has `statusCode="1"` and `statusSeverity="Info"` (sometimes `statusSeverity="Warn"` on older builds) on the `*Rs` element and *no* `*Ret` children. The rule: **a `*Rs` whose `statusSeverity` is `Info` (or `Warn`) is a success regardless of `statusCode`; only `statusSeverity="Error"` is a failure.** So `ParsedElement` exposes `Status.IsError => Status.Severity == "Error"`; zero `Rows` is just an empty list, never an exception. Surface `statusCode`/`statusMessage` verbatim either way (Phase 7 needs `statusCode` to recognize `0x800404C5` stale-`EditSequence` — note that's a *qbXML status code on the element*, decimal-ish form `3200` "edit sequence is out of date" in some contexts; surfacing the raw `statusCode` string lets Phase 7 map it).

**Code skeleton:**
```csharp
// QbXmlModels.cs
public sealed record QbStatus(string Code, string Severity, string Message)
{
    public bool IsError => string.Equals(Severity, "Error", StringComparison.OrdinalIgnoreCase);
    public static QbStatus FromElement(System.Xml.Linq.XElement e) => new(
        e.Attribute("statusCode")?.Value ?? "0",
        e.Attribute("statusSeverity")?.Value ?? "Info",
        e.Attribute("statusMessage")?.Value ?? "Status OK");
}
public sealed record ParsedElement(
    string Name, QbStatus Status,
    string? IteratorId, int? IteratorRemaining,
    List<Dictionary<string, object?>> Rows);
public sealed record ParsedQbXmlResponse(
    QbStatus Message, List<ParsedElement> Elements, string? RawSpilledTo = null)
{
    public ParsedElement First => Elements[0];   // convenience for single-op messages
}

// QbXmlParser.cs (pure)
public sealed class QbXmlParser
{
    private static readonly HashSet<string> ItemRetNames = new(StringComparer.Ordinal)
    { "ItemServiceRet","ItemInventoryRet","ItemNonInventoryRet","ItemInventoryAssemblyRet","ItemFixedAssetRet",
      "ItemOtherChargeRet","ItemSubtotalRet","ItemDiscountRet","ItemPaymentRet","ItemSalesTaxRet",
      "ItemSalesTaxGroupRet","ItemGroupRet" };

    public ParsedQbXmlResponse Parse(string rawQbXmlResponse)
    {
        var doc = System.Xml.Linq.XDocument.Parse(rawQbXmlResponse);
        var msgs = doc.Root?.Element("QBXMLMsgsRs")
            ?? throw new QbXmlParseException("Response has no <QBXMLMsgsRs>.");
        var message = msgs.HasAttributes && msgs.Attribute("statusSeverity") is not null
            ? QbStatus.FromElement(msgs) : new QbStatus("0", "Info", "Status OK");
        var elements = new List<ParsedElement>();
        foreach (var rs in msgs.Elements().Where(x => x.Name.LocalName.EndsWith("Rs", StringComparison.Ordinal)))
        {
            var status = QbStatus.FromElement(rs);
            var iterId = rs.Attribute("iteratorID")?.Value;
            int? iterRemain = int.TryParse(rs.Attribute("iteratorRemainingCount")?.Value, out var n) ? n : null;
            var rows = rs.Elements()
                .Where(IsRetElement)
                .Select(MapRet)
                .ToList();
            elements.Add(new ParsedElement(rs.Name.LocalName, status, iterId, iterRemain, rows));
        }
        return new ParsedQbXmlResponse(message, elements);
    }

    private static bool IsRetElement(System.Xml.Linq.XElement e) =>
        e.Name.LocalName.EndsWith("Ret", StringComparison.Ordinal) && e.Name.LocalName != "DataExtRet";
        // DataExtRet is handled inside MapRet as a nested customFields list, not a top-level row.

    private Dictionary<string, object?> MapRet(System.Xml.Linq.XElement ret)
    {
        var row = new Dictionary<string, object?>(StringComparer.Ordinal);
        if (ItemRetNames.Contains(ret.Name.LocalName))
            row["type"] = ret.Name.LocalName["Item".Length..^"Ret".Length];   // ItemServiceRet -> "Service"
        foreach (var group in ret.Elements().GroupBy(x => x.Name.LocalName))
        {
            if (group.Key == "DataExtRet")
            { row["customFields"] = group.Select(MapDataExt).ToList(); continue; }
            var items = group.Select(MapNode).ToList();
            row[group.Key] = items.Count == 1 && items[0] is string ? items[0]   // single scalar -> string
                           : items.Count == 1 ? items[0]                          // single complex -> dict
                           : (object)items;                                       // repeated -> List
        }
        return row;
    }
    private object MapNode(System.Xml.Linq.XElement e) =>
        e.HasElements ? (object)MapComplex(e) : e.Value;   // leaf -> string; complex -> nested dict
    private Dictionary<string, object?> MapComplex(System.Xml.Linq.XElement e)
    { /* same grouping logic, recursive */ return MapRet(e); }   // reuse MapRet's body (it's generic)
    private Dictionary<string, object?> MapDataExt(System.Xml.Linq.XElement d) => new(StringComparer.Ordinal)
    { ["OwnerID"] = d.Element("OwnerID")?.Value, ["DataExtName"] = d.Element("DataExtName")?.Value,
      ["DataExtType"] = d.Element("DataExtType")?.Value, ["DataExtValue"] = d.Element("DataExtValue")?.Value };
}
public sealed class QbXmlParseException(string msg) : Exception(msg);
```
*(Codex should tidy the `MapRet`/`MapComplex` recursion — the point is: leaves become strings, repeated siblings become lists, `DataExtRet` becomes `customFields`, Item subtypes get a `type`. The exact recursion shape is Codex's call; the *contract* — `ParsedQbXmlResponse` shape, zero-row-as-success, `customFields`, `type` discriminator — is what the planner pins.)*

### Pattern 3: `QbReportParser` — `ColDesc`-driven, no ordinal guessing (READ-02)

**What:** A `*ReportQueryRs` body looks like (representative shape, confirmed against Intuit's "Preparing report requests" doc + the SDK sample repo — exact attribute casing flagged):
```xml
<QBXML><QBXMLMsgsRs>
  <GeneralSummaryReportQueryRs requestID="1" statusCode="0" statusSeverity="Info" statusMessage="Status OK">
    <ReportRet>
      <ReportTitle>Profit &amp; Loss</ReportTitle>
      <ReportSubtitle>January 2026</ReportSubtitle>
      <ReportBasis>AccrualBasis</ReportBasis>          <!-- not always present -->
      <NumRows>12</NumRows> <NumColumns>2</NumColumns>  <!-- counts; advisory only -->
      <ColDesc colID="1"><ColTitle titleRow="1" value="" /><ColType>Amount</ColType></ColDesc>
      <ColDesc colID="2"><ColTitle titleRow="1" value="TOTAL" /><ColType>Amount</ColType></ColDesc>
      <ReportData>
        <TextRow rowNumber="1"><RowData rowType="text" value="Ordinary Income/Expense" /></TextRow>
        <TextRow rowNumber="2"><RowData rowType="text" value="  Income" /></TextRow>
        <DataRow rowNumber="3">
          <RowData rowType="account" value="Consulting" ><DataExtRet>…</DataExtRet></RowData>  <!-- DataExtRet possible here too -->
          <ColData colID="1" value="12000.00" />
          <ColData colID="2" value="12000.00" />
        </DataRow>
        <SubtotalRow rowNumber="4"><RowData rowType="subtotal" value="Total Income" /><ColData colID="1" value="12000.00" /><ColData colID="2" value="12000.00" /></SubtotalRow>
        <TotalRow   rowNumber="12"><RowData rowType="total" value="Net Income" /><ColData colID="1" value="3500.00" /><ColData colID="2" value="3500.00" /></TotalRow>
      </ReportData>
    </ReportRet>
  </GeneralSummaryReportQueryRs>
</QBXMLMsgsRs></QBXML>
```
The parser:
1. Reads every `<ColDesc>` → `(colID, title, colType)` where `title` is from the `<ColTitle value="…">` attribute (a `ColDesc` can have multiple `<ColTitle titleRow="N">` for multi-row headers — concatenate, or take `titleRow="1"`; the canonical financial reports have one). Build an ordered `Columns` list and a `colID → title` map.
2. Walks `<ReportData>` children in document order. Each child is one of `DataRow`/`SubtotalRow`/`TotalRow`/`TextRow` → record `RowType` from the element name. The row's `<RowData value="…">` is the label/group cell (and `rowType` attribute is the QuickBooks row classification — keep it too). Each `<ColData colID="N" value="…">` maps by `colID` into `Cells[title]`. `TextRow`s typically have only `RowData`, no `ColData`.
3. Returns `ParsedReport { Title, Subtitle, Basis, Columns: List<ReportColumn{Id,Title,Type}>, Rows: List<ReportRow{RowType, Label, RowDataType, Cells: Dictionary<string,string>}> }`. Indentation/grouping is implicit in the document order + the `value` whitespace + `rowType` — v1 just preserves it; Phase 4's report op / a future summarizer can re-derive a tree if needed.

**Critical: never index `ColData` by position-in-XML.** `colID` is the source of truth and `ColData` elements *can* be sparse (a row may omit a column). Match by `colID` only.

**Flag:** the exact element/attribute names — `ColTitle` (element) with a `value` attribute vs a `colTitle` attribute on `ColDesc`; `ColType` vs `colType`; `RowData` `value` vs `colData`; whether `rowNumber` is `rowNumber` — vary slightly across qbXML spec versions and across the OSR vs sample files. **The parser must be written tolerantly** (try the element, fall back to the attribute; use `LocalName` comparisons; null-safe everywhere) **and the committed fixture must be a real `SDKTestPlus3`/OSR-sourced response** so the golden test pins reality. The *design* (ColDesc → columns; ReportData rows by colID) is right regardless. If Codex can't get a real fixture, it should build a plausible one **and the PLAN should say so explicitly** so the reviewer knows the fixture is constructed, not captured.

### Pattern 4: `QbListExecutor` — Start → Continue → done (READ-03)

```csharp
// QbListExecutor.cs  (impure: uses QbConnectionManager)
public sealed class QbListExecutor
{
    private readonly QbConnectionManager _mgr;
    private readonly QbXmlBuilder _builder;
    private readonly QbXmlParser _parser;
    private readonly QbResponseSpiller _spiller;
    private readonly QbXmlOptions _opts;
    private readonly ILogger<QbListExecutor> _log;
    // ctor injects all of the above

    /// <param name="queryRq">A *Rq XElement WITHOUT iterator attributes (Phase 4 builds the body + filters).</param>
    public async Task<ParsedQbXmlResponse> RunAsync(XElement queryRq, CancellationToken ct = default)
    {
        var requestId = "1";
        var rawPages = new System.Text.StringBuilder();   // for size-guard accounting
        // ---- page 1: Start ----
        var startBody = QbXmlBuilder.WithIterator(new XElement(queryRq), IteratorMode.Start,
                                                  maxReturned: _opts.MaxReturned, requestId: requestId);
        var raw = await _mgr.ExecuteAsync(_builder.BuildRequest(startBody), ct);
        rawPages.Append(raw);
        var parsed = _parser.Parse(raw);
        var first = parsed.First;
        if (first.Status.IsError) return await FinishAsync(parsed, rawPages, ct);   // surface mid-iteration error
        var accumulated = new List<Dictionary<string, object?>>(first.Rows);
        var iteratorId = first.IteratorId;
        var remaining = first.IteratorRemaining ?? 0;
        // ---- pages 2..n: Continue ----
        while (remaining > 0 && iteratorId is not null)
        {
            var contBody = QbXmlBuilder.WithIterator(new XElement(queryRq), IteratorMode.Continue,
                                                     iteratorId: iteratorId, maxReturned: _opts.MaxReturned, requestId: requestId);
            raw = await _mgr.ExecuteAsync(_builder.BuildRequest(contBody), ct);
            rawPages.Append(raw);
            var p = _parser.Parse(raw).First;
            if (p.Status.IsError)   // abort, surface this page's status
                return await FinishAsync(new ParsedQbXmlResponse(parsed.Message,
                    new List<ParsedElement> { p with { Rows = accumulated } }), rawPages, ct);
            accumulated.AddRange(p.Rows);
            iteratorId = p.IteratorId ?? iteratorId;
            remaining = p.IteratorRemaining ?? 0;
            _log.LogDebug("Iterator page fetched; {Remaining} remaining, {Total} rows so far.", remaining, accumulated.Count);
        }
        var merged = new ParsedQbXmlResponse(parsed.Message,
            new List<ParsedElement> { first with { Rows = accumulated, IteratorRemaining = 0 } });
        return await FinishAsync(merged, rawPages, ct);
    }

    private async Task<ParsedQbXmlResponse> FinishAsync(ParsedQbXmlResponse result, System.Text.StringBuilder rawPages, CancellationToken ct)
    {
        var bytes = System.Text.Encoding.UTF8.GetByteCount(rawPages.ToString());
        if (bytes > _opts.MaxResponseBytes)
        {
            var path = await _spiller.SpillAsync(rawPages.ToString(), ct);
            _log.LogInformation("Iterator response {Bytes} bytes exceeded {Limit}; spilled raw qbXML to {Path}.",
                bytes, _opts.MaxResponseBytes, path);
            return result with { RawSpilledTo = path };
        }
        return result;
    }
}
```
Caveats baked in: `requestID` stays constant across the iteration (correlation); `iteratorID` is taken from each response; `iteratorRemainingCount=0` (or missing) ends the loop; an `Error` severity on any page aborts and surfaces *that page's* status with whatever rows we already have; `new XElement(queryRq)` clones the body each page so we don't mutate the caller's element. The size-guard accounting concatenates the *raw* page strings (post-iterator) — a multi-page result that's individually small but cumulatively huge still spills. **`QbListExecutor` is the right home for the size-guard** (it's the thing that produces a possibly-huge concatenated blob). A single non-iterator response that's huge (e.g. a giant report) can also be spilled — expose `QbResponseSpiller` so Phase 4's `report` op / Phase 5's `/api/qbxml` can call it too; in Phase 3 just wire it into `QbListExecutor` and make it independently usable.

### Pattern 5: `QbResponseSpiller` — size-guard spill-to-file (READ-03)

```csharp
public sealed class QbResponseSpiller
{
    private readonly QbXmlOptions _opts;
    private readonly QbAuditPathProvider _audit;   // OR just inject IConfiguration to read "Audit:Path"; see note
    public QbResponseSpiller(IOptions<QbXmlOptions> opts, IConfiguration config) { _opts = opts.Value; /* read Audit:Path fallback */ }

    public int Threshold => _opts.MaxResponseBytes;
    public bool ExceedsThreshold(string raw) => System.Text.Encoding.UTF8.GetByteCount(raw) > _opts.MaxResponseBytes;

    public async Task<string> SpillAsync(string rawQbXml, CancellationToken ct = default)
    {
        var dir = !string.IsNullOrWhiteSpace(_opts.SpillPath) ? _opts.SpillPath
                : /* config["Audit:Path"] ?? */ Path.Combine(Path.GetTempPath(), "QbConnectService", "spill");
        Directory.CreateDirectory(dir);
        var file = Path.Combine(dir, $"{DateTime.UtcNow:yyyyMMdd-HHmmssfff}-{Guid.NewGuid():N}.qbxml");
        await File.WriteAllTextAsync(file, rawQbXml, ct);
        return file;
    }
}
```
- **Default `SpillPath` = `""` → fall back to `Audit:Path`** (which already exists in `appsettings.sample.json` as `C:\ProgramData\QbConnectService\audit`). Putting spilled raw qbXML "beside the audit log" is exactly what the spec/ROADMAP says ("spills the raw qbXML to a file beside the audit log"). If `Audit:Path` is also empty, fall back to `%TEMP%\QbConnectService\spill`. **Recommend adding the explicit `QbXml:SpillPath` key** (default `""`) so deployers *can* separate them, but defaulting to the audit dir keeps it "beside the audit log" with zero new required config.
- Reading `Audit:Path`: simplest is to inject `IConfiguration` and read `config["Audit:Path"]` in the spiller (the `AuditOptions` POCO is Phase 6's; don't pre-create it). Or have `Program.cs` resolve the effective path and pass it via `QbXmlOptions.SpillPath` at startup. Either is fine — flag the choice for the planner.
- **Default threshold `5_000_000` bytes (~5 MB)** is the scope's suggested default; reasonable for "this is too big to ship in an HTTP body / hold in memory comfortably". Make it config-overridable (it is — `QbXml:MaxResponseBytes`).

### Pattern 6: Config — `QbXmlOptions` + `appsettings.sample.json` + DI

```csharp
// QbXmlOptions.cs
namespace QbConnectService.Qb;
public sealed class QbXmlOptions
{
    public string Version { get; set; } = "16.0";
    public bool OwnerIdZero { get; set; }                 // moved from QbOptions (READ-11) — default false, documented
    public int MaxReturned { get; set; } = 100;           // iterator page size
    public int MaxResponseBytes { get; set; } = 5_000_000; // spill threshold
    public string SpillPath { get; set; } = "";           // "" => fall back to Audit:Path, then %TEMP%
}
```
`Program.cs` adds:
```csharp
builder.Services.Configure<QbXmlOptions>(builder.Configuration.GetSection("QbXml"));
builder.Services.AddSingleton<QbXmlBuilder>();
builder.Services.AddSingleton<QbXmlParser>();
builder.Services.AddSingleton<QbReportParser>();
builder.Services.AddSingleton<QbResponseSpiller>();
builder.Services.AddSingleton<QbListExecutor>();
```
`appsettings.sample.json` — move `OwnerIdZero` out of `"Qb"`, expand `"QbXml"`:
```jsonc
"Qb": { "CompanyFilePath": "...", "AppId": "...", "AppName": "QbConnectService",
        "ConnectionType": "LocalQBD", "OpenMode": "DoNotCare" },          // OwnerIdZero removed
"QbXml": { "Version": "16.0", "OwnerIdZero": false,
           "MaxReturned": 100, "MaxResponseBytes": 5000000, "SpillPath": "" },
"Audit": { "Path": "C:\\ProgramData\\QbConnectService\\audit" }            // unchanged; spill falls back here
```
And update `QbOptions.cs` (drop the `OwnerIdZero` property) and `QbOptionsBindingTests.cs` accordingly. **The planner should make this its own task** ("relocate `OwnerIdZero` to `QbXmlOptions`") so the small cross-cutting refactor is deliberate and reviewable, and it must keep the suite green (`QbConnectService` builds, `QbConnectService.Tests` all pass) at that commit. *(If the planner judges the move risky given concurrent unrelated git activity on the branch, leaving `OwnerIdZero` in `QbOptions` and having `QbXmlBuilder` not need it directly — the *ops* in Phase 4 read `QbOptions.OwnerIdZero` and call `QbXmlBuilder.WithOwnerIdZero` — is an acceptable fallback. But the move is the clean answer and Phases 1/2 set the bar that small refactors get done properly.)*

### Anti-Patterns to Avoid

- **Indexing report `ColData` by XML position.** Always match by `colID` against the `ColDesc` map (READ-02 is explicit: "never by ordinal guess"). `ColData` can be sparse.
- **Treating a zero-row / `statusCode="1"` query response as an error.** `statusSeverity` is the discriminator: `Info`/`Warn` = success (possibly empty), `Error` = failure (READ-01). A test must cover this.
- **`XDocument.ToString()` for the request string.** It drops the `<?xml ...?>` declaration; QuickBooks wants both the declaration and the `<?qbxml version?>` PI. Save to a `TextWriter`/`XmlWriter`.
- **Putting `MaxReturned` as an attribute.** It's a child element on the query types; only `iterator`/`iteratorID`/`requestID` are attributes.
- **Mutating the caller's `XElement` in `QbListExecutor`.** Clone (`new XElement(src)`) before stamping iterator attrs per page.
- **A `<?qbxml version>` higher than the host supports.** Phase 3 just emits `QbXml:Version` from config (the *config* default `16.0` matches `appsettings.sample.json`); Phase 5's `/api/health` reconciles against `QbConnectionManager.GetSupportedQbXmlVersionsAsync()`. Don't try to auto-negotiate in Phase 3 — out of scope, and the manager already exposes the supported list for later.
- **`QbXmlParser`/`QbReportParser`/`QbXmlBuilder` doing any I/O.** They're pure — no file, no COM, no `QbConnectionManager`. Only `QbListExecutor` and `QbResponseSpiller` touch I/O. Keep the boundary (ARCHITECTURE.md "Builder and Parser are pure" is load-bearing for testability).
- **Building Phase 4 read ops here.** Phase 3 is the *engine* only — no `company_info`/`report`/`list_*`/`get_transaction`/`run_query`/`get_company_preferences`. Those are Phase 4. (The PLAN's "DO NOT build" list should restate this.)

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Parsing / building XML | A regex/string-concat XML approach | `System.Xml.Linq` (`XDocument`/`XElement`) | Entity-escaping (`&amp;` in `ReportTitle`), namespaces, attribute ordering, CDATA — XLinq handles it. `STACK.md` mandates it; QBFC is explicitly rejected. |
| Serializing/comparing parsed results in tests | A bespoke equality walker | `JsonSerializer.Serialize(...)` against a committed `.json` fixture, or `JsonNode.Parse(...).DeepEquals(...)` | In-box, deterministic, diff-friendly on review. (`Verify.Xunit` is the heavier alternative — recommended against.) |
| Iterator paging | Re-inventing a paged-enumerable framework | One tight `while (remaining > 0)` loop in `QbListExecutor` | The protocol is trivial; a framework obscures it and adds review surface. |
| qbXML schema validation | Loading the `qbxmlops*.xsd` and validating every request | Pinning builder output with golden-string tests + (later) `SDKTestPlus3` on-box | Schema validation at runtime is overkill for v1 and the XSDs aren't in the repo; the golden tests + the round-trip against `FakeRequestProcessor` catch shape regressions, and Phase 9's on-box smoke catches real-schema issues. |
| HRESULT / status-code → message mapping | A new map in Phase 3 | Phase 2's `QbErrors` (HRESULTs) for COM errors; surface the raw qbXML `statusCode` string for Phase 7 to map | Phase 3's parser just *exposes* `statusCode`/`statusSeverity`/`statusMessage` verbatim — it doesn't editorialize. The `0x800404C5`-class qbXML *status* mapping is Phase 7's job. |
| The COM/STA/serialization plumbing | Anything | Phase 2's `QbConnectionManager.ExecuteAsync` | Already done — `QbListExecutor` just calls it. Phase 3 must not touch `IRequestProcessor`, `StaThread`, or the gate directly. |

**Key insight:** Phase 3 is *thin glue between two well-defined edges* — a caller-built `XElement` request body on one side, the Phase-2 manager + raw qbXML response strings on the other. The only genuinely non-obvious piece is the report parser's `ColDesc`-driven, position-free mapping; everything else is small. Resist building abstractions; build the five concrete pieces and pin them with fixtures.

---

## Common Pitfalls

### Pitfall 1: The `<?xml ...?>` declaration vanishes from the built request
**What goes wrong:** `QbXmlBuilder.BuildRequest` returns `<?qbxml version="16.0"?><QBXML>…` with no `<?xml version="1.0"?>` prefix, because `XDocument.ToString()` / `XElement.Save(StringWriter)` without care omit the declaration.
**Why it happens:** XLinq treats the `XDeclaration` specially; `ToString()` never emits it, and `Save(TextWriter)` emits it only with the right overload/options.
**How to avoid:** Save via a `TextWriter` (the `Utf8StringWriter` trick) so the declaration is written; assert the full string (`<?xml version="1.0" encoding="utf-8"?>\r\n<?qbxml version="16.0"?>\r\n<QBXML>…`) in a builder golden test. Pin the encoding token you choose.
**Warning signs:** A builder test that asserts only on `Contains("<QBXMLMsgsRq")` instead of the whole envelope string.

### Pitfall 2: Zero-row response surfaced as an exception/error
**What goes wrong:** `CustomerQuery` for a name that doesn't exist returns `statusCode="1" statusSeverity="Info" statusMessage="A query request did not find a matching object in QuickBooks"` and no `CustomerRet` — and the parser throws or marks it `IsError`.
**Why it happens:** Treating `statusCode != 0` as failure.
**How to avoid:** `IsError = (Severity == "Error")` only. Zero rows = empty `Rows` list, status preserved. Dedicated test (READ-01).
**Warning signs:** Any `if (statusCode != "0") throw` in the parser.

### Pitfall 3: Report parser breaks on a sparse / multi-header report
**What goes wrong:** A `DataRow` omits `ColData` for column 1 (it's blank); the parser, indexing `ColData` by position, shifts every cell left. Or a `ColDesc` has two `<ColTitle titleRow="1">`/`<ColTitle titleRow="2">` and the parser picks the wrong one.
**Why it happens:** Positional assumptions; assuming one `ColTitle` per `ColDesc`.
**How to avoid:** Map `ColData` strictly by `colID`; for `ColTitle`, prefer `titleRow="1"` (or concatenate all). Use a real captured fixture (P&L *with* a subtotal/total/text row) for the golden test.
**Warning signs:** `ColData` accessed via `.Elements().ElementAt(i)`; no `TextRow`/`SubtotalRow`/`TotalRow` in the test fixture.

### Pitfall 4: `FakeRequestProcessor` can't distinguish Start from Continue, so the iterator test can't have two pages
**What goes wrong:** The current fake keys responses by `*Rq` element name only — both the `iterator="Start"` and `iterator="Continue"` requests are `CustomerQueryRq`, so it returns the same canned response forever (infinite loop or one page).
**Why it happens:** `_responses` is a `Dictionary<string,string>` (one response per request name).
**How to avoid (minimal extension — in-scope, it's the test project):** add a per-name *queue* of responses to `FakeRequestProcessor` — e.g. `AddResponses(string requestName, params string[] responsesInOrder)` that dequeues on each `ProcessRequest`, falling back to `_responses[name]` (keep `AddResponse` for the single-response case, backward-compatible). Then the test does `fake.AddResponses("CustomerQueryRq", page1Xml, page2Xml)`. *Alternatively*, the test can set `ProcessRequestHook` to inspect the request's `iterator` attribute and return page1 vs page2 — also works, no fake change needed; but the queue is reusable and cleaner. **Recommend the queue extension** (a few lines, BC-preserving). Either way it's an explicit PLAN task.
**Warning signs:** An iterator test that only ever exercises one page; a hung test.

### Pitfall 5: Spilled-file path collides or the directory doesn't exist
**What goes wrong:** Two spills in the same millisecond overwrite each other; or `SpillPath`/`Audit:Path` directory doesn't exist and `File.WriteAllText` throws.
**Why it happens:** Timestamp-only filename; not creating the dir.
**How to avoid:** Filename = `{UTC yyyyMMdd-HHmmssfff}-{Guid:N}.qbxml`; `Directory.CreateDirectory(dir)` first; in tests point `SpillPath` at a `Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString())` dir and clean it up.
**Warning signs:** Spiller test that doesn't assert the file exists *and* contains the raw qbXML *and* the result's `RawSpilledTo == thatPath`.

### Pitfall 6: `OwnerID="0"` moved/forgotten so `DataExtRet` silently never appears
**What goes wrong:** READ-11 — custom fields are wanted, `QbXmlOptions.OwnerIdZero=true`, but the builder/op never calls `WithOwnerIdZero`, so QuickBooks omits all `DataExtRet` and nobody notices ("we just don't have custom fields").
**Why it happens:** `OwnerID` is a silent gate (FEATURES.md "OwnerID is a silent gate").
**How to avoid:** In Phase 3, provide `QbXmlBuilder.WithOwnerIdZero(queryElement)` and a parser that *does* surface `DataExtRet` as `customFields` when present — and a parser test with a `*Ret` that contains `DataExtRet`. (Wiring `if (opts.OwnerIdZero) WithOwnerIdZero(body)` into each query op is Phase 4's job, but the *capability* and the config knob and the documented default are Phase 3's, per READ-11.) Document the default (`false`) in `appsettings.sample.json`.
**Warning signs:** No `DataExtRet` in any parser fixture; `OwnerIdZero` config key with no code path that reads it.

### Pitfall 7: Parser chokes on namespaces / leading whitespace / BOM in the raw response
**What goes wrong:** Real qbXML responses sometimes have a BOM, sometimes a trailing newline, sometimes the `<?xml?>` declaration; `XDocument.Parse` handles all of those, but a hand-written prefix-strip wouldn't.
**Why it happens:** Trying to be clever about the raw string.
**How to avoid:** Just `XDocument.Parse(raw)` (or `XDocument.Parse(raw, LoadOptions.None)`); use `LocalName` comparisons throughout (qbXML has no namespace prefixes in practice, but `LocalName` is safe regardless). Don't pre-process the string.
**Warning signs:** `raw.Substring(raw.IndexOf("<QBXML"))` anywhere.

---

## Code Examples

(All verified against project research + the qbXML samples cited in Sources; the exact element/attribute *names* in the report fixture must be re-pinned from the OSR/`SDKTestPlus3` by Codex when committing the fixture — flagged.)

### Building a request (what Phase 4 will do, exercising `QbXmlBuilder`)
```csharp
// Phase-4-style usage (NOT built in Phase 3 — shown so the seam is clear):
var body = QbXmlBuilder.Rq("CustomerQueryRq",
    new XElement("ActiveStatus", "ActiveOnly"),
    new XElement("MaxReturned", 50));            // op may set its own MaxReturned; WithIterator won't override it
// list op path:
var pageBody = QbXmlBuilder.WithIterator(body, IteratorMode.Start, maxReturned: 100, requestId: "1");
if (qbXmlOptions.OwnerIdZero) QbXmlBuilder.WithOwnerIdZero(pageBody);
string requestXml = qbXmlBuilder.BuildRequest(pageBody);
// -> "<?xml version=\"1.0\" encoding=\"utf-8\"?>\r\n<?qbxml version=\"16.0\"?>\r\n<QBXML>\r\n  <QBXMLMsgsRq onError=\"stopOnError\">\r\n    <CustomerQueryRq requestID=\"1\" iterator=\"Start\"><MaxReturned>50</MaxReturned><ActiveStatus>ActiveOnly</ActiveStatus><OwnerID>0</OwnerID></CustomerQueryRq>\r\n  </QBXMLMsgsRq>\r\n</QBXML>"
```

### A normal CustomerQueryRs (fixture sketch — 2 rows, status OK)
```xml
<?xml version="1.0" ?><QBXML><QBXMLMsgsRs>
  <CustomerQueryRs requestID="1" statusCode="0" statusSeverity="Info" statusMessage="Status OK">
    <CustomerRet>
      <ListID>80000001-1234567890</ListID><EditSequence>1234567890</EditSequence>
      <Name>Acme Roofing</Name><FullName>Acme Roofing</FullName><IsActive>true</IsActive>
      <BillAddress><Addr1>1 Main St</Addr1><City>Irvine</City><State>CA</State><PostalCode>92602</PostalCode></BillAddress>
    </CustomerRet>
    <CustomerRet>
      <ListID>80000002-1234567891</ListID><EditSequence>1234567891</EditSequence>
      <Name>Globex</Name><FullName>Globex</FullName><IsActive>true</IsActive>
    </CustomerRet>
  </CustomerQueryRs>
</QBXMLMsgsRs></QBXML>
```
→ parses to `ParsedQbXmlResponse` with one `ParsedElement("CustomerQueryRs", Status("0","Info","Status OK"), null, null, Rows=[ {ListID, EditSequence, Name, FullName, IsActive, BillAddress:{Addr1,City,State,PostalCode}}, {ListID, EditSequence, Name, FullName, IsActive} ])`.

### A zero-row CustomerQueryRs (fixture — must parse as success, READ-01)
```xml
<?xml version="1.0" ?><QBXML><QBXMLMsgsRs>
  <CustomerQueryRs requestID="1" statusCode="1" statusSeverity="Info"
     statusMessage="A query request did not find a matching object in QuickBooks" />
</QBXMLMsgsRs></QBXML>
```
→ `Elements[0].Status.IsError == false`, `Elements[0].Rows.Count == 0`, `Status.Code == "1"`, `Status.Message` preserved verbatim. No exception.

### A polymorphic ItemQueryRs (fixture — Service + Inventory → normalized rows with `type`, READ-07 parser half)
```xml
<?xml version="1.0" ?><QBXML><QBXMLMsgsRs>
  <ItemQueryRs requestID="1" statusCode="0" statusSeverity="Info" statusMessage="Status OK">
    <ItemServiceRet><ListID>800A-1</ListID><Name>Consulting</Name><IsActive>true</IsActive>
      <SalesOrPurchase><Price>200.00</Price><AccountRef><FullName>Consulting Income</FullName></AccountRef></SalesOrPurchase></ItemServiceRet>
    <ItemInventoryRet><ListID>800B-1</ListID><Name>Widget</Name><IsActive>true</IsActive>
      <SalesPrice>9.99</SalesPrice><QuantityOnHand>42</QuantityOnHand>
      <IncomeAccountRef><FullName>Product Income</FullName></IncomeAccountRef></ItemInventoryRet>
  </ItemQueryRs>
</QBXMLMsgsRs></QBXML>
```
→ `Rows = [ {type:"Service", ListID, Name, IsActive, SalesOrPurchase:{Price, AccountRef:{FullName}}}, {type:"Inventory", ListID, Name, IsActive, SalesPrice, QuantityOnHand, IncomeAccountRef:{FullName}} ]`.

### A response with DataExtRet (fixture — custom fields surfaced when OwnerID=0 was sent, READ-11)
```xml
<?xml version="1.0" ?><QBXML><QBXMLMsgsRs>
  <CustomerQueryRs requestID="1" statusCode="0" statusSeverity="Info" statusMessage="Status OK">
    <CustomerRet><ListID>80000003-1</ListID><Name>Initech</Name><IsActive>true</IsActive>
      <DataExtRet><OwnerID>0</OwnerID><DataExtName>Region</DataExtName><DataExtType>STR255TYPE</DataExtType><DataExtValue>West</DataExtValue></DataExtRet>
      <DataExtRet><OwnerID>0</OwnerID><DataExtName>Tier</DataExtName><DataExtType>STR255TYPE</DataExtType><DataExtValue>Gold</DataExtValue></DataExtRet>
    </CustomerRet>
  </CustomerQueryRs>
</QBXMLMsgsRs></QBXML>
```
→ `Rows[0]["customFields"] == [ {OwnerID:"0", DataExtName:"Region", DataExtType:"STR255TYPE", DataExtValue:"West"}, {…Tier/Gold…} ]` and `Rows[0]` does *not* contain a top-level `"DataExtRet"` key.

### A per-element error response (fixture — surfaced in Status, not thrown)
```xml
<?xml version="1.0" ?><QBXML><QBXMLMsgsRs>
  <InvoiceAddRs requestID="1" statusCode="3140" statusSeverity="Error"
     statusMessage="There is an invalid reference to QuickBooks Customer ... in the Invoice." />
</QBXMLMsgsRs></QBXML>
```
→ `Elements[0].Status.IsError == true`, `Status.Code == "3140"`, `Rows.Count == 0`. (Phase 3 surfaces it; whether the API returns 200-with-status or something else is Phase 5/6.)

### Two-page iterator (fixtures — `QbListExecutor` accumulates, READ-03)
```xml
<!-- page 1 (response to iterator="Start" MaxReturned=1) -->
<?xml version="1.0" ?><QBXML><QBXMLMsgsRs>
  <CustomerQueryRs requestID="1" statusCode="0" statusSeverity="Info" statusMessage="Status OK"
     iteratorRemainingCount="1" iteratorID="{eb05f701-e727-472f-8ade-6753c4f67a46}">
    <CustomerRet><ListID>80000001-1</ListID><Name>Acme Roofing</Name></CustomerRet>
  </CustomerQueryRs>
</QBXMLMsgsRs></QBXML>
<!-- page 2 (response to iterator="Continue" iteratorID="{eb05f701-...}") -->
<?xml version="1.0" ?><QBXML><QBXMLMsgsRs>
  <CustomerQueryRs requestID="1" statusCode="0" statusSeverity="Info" statusMessage="Status OK"
     iteratorRemainingCount="0" iteratorID="{eb05f701-e727-472f-8ade-6753c4f67a46}">
    <CustomerRet><ListID>80000002-1</ListID><Name>Globex</Name></CustomerRet>
  </CustomerQueryRs>
</QBXMLMsgsRs></QBXML>
```
Test: `fake.AddResponses("CustomerQueryRq", page1, page2)` (after the queue extension); `var result = await listExecutor.RunAsync(QbXmlBuilder.Rq("CustomerQueryRq"));` → `result.First.Rows.Count == 2`, names `["Acme Roofing","Globex"]`, `result.First.IteratorRemaining == 0`, `result.RawSpilledTo == null` (under threshold). Also assert the fake's `CallLog`/recorded requests show the 2nd request carried `iterator="Continue"` and the same `iteratorID`. (Use `ProcessRequestHook` to capture the request strings if the recorded-args surface isn't rich enough — Phase 1's fake records `LastCompanyFilePath` etc. but not per-`ProcessRequest` request bodies; the hook or a small `List<string> ProcessRequests` addition covers it — in-scope.)

### Size-guard spill (fixture — over threshold → file written, READ-03)
Test: set `QbXmlOptions.MaxResponseBytes = 100` and `SpillPath = <temp dir>`; `fake.AddResponse("CustomerQueryRq", aBigCannedResponse)` (or `AddResponses` with one big page, `iteratorRemainingCount="0"`); `RunAsync` → `result.RawSpilledTo` is a path under the temp dir, `File.Exists` is true, `File.ReadAllText` equals the big raw qbXML, and `result.First.Rows` is still populated (we parsed it before spilling). Clean up the temp dir.

### Report parsing (fixture — `ColDesc`-driven, READ-02)
Commit a real-ish `GeneralSummaryReportQueryRs` (ProfitAndLossStandard) fixture with: 2 `ColDesc` (`colID="1"` blank title, `colID="2"` "TOTAL"), and `ReportData` containing at least one `TextRow` (header line, RowData only), one `DataRow` (account line with `ColData colID="1"`/`colID="2"`), one `SubtotalRow`, one `TotalRow` ("Net Income"). Test: `ParsedReport.Title == "Profit & Loss"`, `Columns.Count == 2`, `Columns[1].Title == "TOTAL"`, `Rows` has the right `RowType` sequence (`Text, Data, Subtotal, Total`), `Rows[1].Cells["TOTAL"] == "12000.00"`, `Rows.Last().Label == "Net Income"`. **Codex: source this fixture from the OSR / a real `SDKTestPlus3` P&L run if possible; if constructed, say so in the PLAN.**

---

## State of the Art

| Old approach | Current approach | When changed | Impact |
|--------------|------------------|--------------|--------|
| QBFC OO COM wrapper to build qbXML | Hand-build with `System.Xml.Linq` | Project decision (STACK.md) | No second COM dependency; the engine is pure C#, CI-able with no SDK. |
| Loading the `qbxmlops*.xsd` and validating at runtime | Golden-string tests on builder output + `SDKTestPlus3` on-box (Phase 9) | Project decision | Lighter; the XSDs aren't in-repo; golden tests catch shape drift. |
| Auto-negotiating the qbXML version | Pin `QbXml:Version` in config; `/api/health` reconciles vs `HostQueryRq` (Phase 5) | Project decision | Phase 3 just emits the configured version; reconciliation is Phase 5's. |

**Deprecated/outdated / not applicable:**
- `QBXMLRP` (the legacy non-2 request processor) — irrelevant; we use `QBXMLRP2` via Phase 1/2's seam, and Phase 3 doesn't touch the processor at all.
- "qbXML version 13.0 as a broad-compat default" (STACK.md mentions it) — for *this* project the config default is `16.0` (already in `appsettings.sample.json`); the host is QuickBooks Enterprise (modern). Phase 3 reads whatever's in config; don't second-guess it.

---

## Open Questions

1. **Exact `ColDesc`/`ColData`/`RowData`/`ColTitle` element & attribute names/casing in the live qbXML 16.0 report response.**
   - What we know: the *shape* is `ReportRet → ReportTitle/ReportSubtitle/[ReportBasis]/[NumRows/NumColumns]/ColDesc*/ReportData → (DataRow|SubtotalRow|TotalRow|TextRow)* each with [RowData] and ColData* by `colID`` — confirmed by Intuit's "Preparing report requests" doc and the SDK sample repo.
   - What's unclear: whether the column title comes via `<ColTitle value="…"/>` (element with attribute) or a `colTitle` attribute on `ColDesc`; `ColType` vs `colType`; `RowData`'s `value` vs another attribute name; whether `rowNumber` is present.
   - Recommendation: write `QbReportParser` *tolerantly* (try element, fall back to attribute; null-safe; `LocalName` compares) and have Codex pin the committed fixture from the OSR or a real `SDKTestPlus3` ProfitAndLossStandard run. The parser design is correct regardless; only the fixture's literal text needs to be real. If a real fixture can't be obtained, the PLAN must state the fixture is constructed.

2. **Parsed-body representation: `List<Dictionary<string,object?>>` vs `JsonNode`.**
   - What we know: Phase 4's ops just need to read fields off rows; the result must be golden-testable.
   - Recommendation: **`List<Dictionary<string,object?>>`** (scalar leaf → `string`; complex child → nested dict; repeated child → `List<...>`; `DataExtRet` → `customFields` list). No JSON dependency for parsing; serialize-to-JSON only for tests/API later. (Documented as the recommendation above.) If the planner strongly prefers `JsonNode`/`JsonObject` for downstream ergonomics, that's acceptable — but the dictionary list is simpler and keeps the zero-new-packages streak.

3. **Where the size-guard threshold check lives & whether to expose it beyond `QbListExecutor`.**
   - What we know: it must apply to the concatenated post-iterator response (READ-03); Phase 4's `report` op and Phase 5's `/api/qbxml` could also produce huge single responses.
   - Recommendation: `QbResponseSpiller` (its own injectable class) does the check + write; `QbListExecutor` calls it after accumulation; expose it as a singleton so Phase 4/5 can call `ExceedsThreshold(raw)` / `SpillAsync(raw)` too. Default threshold `5_000_000` bytes, config-overridable (`QbXml:MaxResponseBytes`). Default `SpillPath=""` → fall back to `Audit:Path` (matches "beside the audit log") → then `%TEMP%\QbConnectService\spill`.

4. **`OwnerIdZero` — move to `QbXmlOptions` or leave in `QbOptions`?**
   - Recommendation: **move** (cleaner — all qbXML knobs together; tiny refactor: drop from `QbOptions.cs`, add to `QbXmlOptions`, relocate the `appsettings.sample.json` key, update `QbOptionsBindingTests`). Make it its own PLAN task so it's deliberate. Fallback (acceptable): leave it in `QbOptions`; Phase 4's ops read `QbOptions.OwnerIdZero` and call `QbXmlBuilder.WithOwnerIdZero`. Either way: documented, default `false` (satisfies READ-11).

5. **`FakeRequestProcessor` multi-page support — queue per request name vs hook-based page selection.**
   - Recommendation: add `AddResponses(string requestName, params string[] inOrder)` (a `Queue<string>` per name; dequeue on each `ProcessRequest`; fall back to `_responses[name]` when the queue is empty; keep `AddResponse` unchanged for BC). Also consider adding a `List<string> ProcessRequests` that records each raw request string so tests can assert the 2nd request carried `iterator="Continue"`. Both are small, in-scope (test project), BC-preserving, and make a clean iterator test. (Hook-based selection via `ProcessRequestHook` inspecting the `iterator` attribute also works with zero fake changes — but the queue is more reusable for later phases.)

---

## Suggested Ordered Task Breakdown for the PLAN

Each task = one atomic commit; each verifiable with **no QuickBooks** via `dotnet build` (both `QbConnectService` and `QbConnectService.Tests`) + `dotnet test` (full suite green at every commit). Ordered so each builds on the prior. (Codex executes from the PLAN, commit-per-task; reviewer wants 100/100.)

1. **`QbXmlOptions` POCO + relocate `OwnerIdZero` + `appsettings.sample.json` + DI binding + binding test.**
   New `QbXmlOptions.cs` (`Version="16.0"`, `OwnerIdZero=false`, `MaxReturned=100`, `MaxResponseBytes=5_000_000`, `SpillPath=""`). Remove `OwnerIdZero` from `QbOptions.cs`. Update `appsettings.sample.json` (drop `Qb:OwnerIdZero`; add the full `QbXml` section). `Program.cs`: `Configure<QbXmlOptions>(GetSection("QbXml"))`. Update/extend the options-binding test (`QbOptionsBindingTests` or a new `QbXmlOptionsBindingTests`) to assert `QbXml` binds with the right defaults and `OwnerIdZero` round-trips. *Verify:* build + test green; `Program` host still resolves.

2. **`QbXmlModels.cs` + `QbXmlBuilder` + golden tests.**
   `QbStatus`, `ParsedQbXmlResponse`, `ParsedElement`, `ParsedReport`/`ReportColumn`/`ReportRow`, `IteratorMode` enum (models file). `QbXmlBuilder` (envelope + `<?xml?>` decl + `<?qbxml version?>` PI + `onError="stopOnError"`; `Rq(name, content)`; `WithIterator`; `WithOwnerIdZero`; `BuildRequest(XElement)` / `BuildRequest(IEnumerable<XElement>)`; `Version` property). `QbXmlBuilderTests`: full-envelope golden string for a simple `*Rq`; version PI matches config (test with a custom `QbXmlOptions.Version`); `iterator="Start"` attrs; `iterator="Continue" iteratorID=…` attrs; `<OwnerID>0</OwnerID>` added when requested; idempotent (`WithOwnerIdZero` twice doesn't double). DI: `AddSingleton<QbXmlBuilder>()`. *Verify:* build + test green.

3. **`QbXmlParser` + parser tests + entity fixtures.**
   `QbXmlParser.Parse(string) → ParsedQbXmlResponse`: message status (defensive), per-`*Rs` `ParsedElement` with `QbStatus` + `iteratorID`/`iteratorRemainingCount`, rows = `*Ret`→`Dictionary<string,object?>` (leaf→string, complex→nested dict, repeated→list, `DataExtRet`→`customFields`), Item subtype→`type` discriminator; `QbXmlParseException` for malformed input. Commit fixtures under `Tests/Fixtures/qbxml/`: `CustomerQueryRs.normal.qbxml` (2 rows), `CustomerQueryRs.zerorows.qbxml` (`statusCode="1"` Info, no Ret), `CustomerQueryRs.dataext.qbxml` (DataExtRet), `ItemQueryRs.polymorphic.qbxml` (Service+Inventory), `InvoiceAddRs.error.qbxml` (`statusSeverity="Error"`). `QbXmlParserTests`: normal→2 rows + Status OK; zero-row→empty rows + `IsError==false` + Code/Message preserved; DataExt→`customFields` populated, no top-level `DataExtRet` key; polymorphic→rows have `type`; error→`IsError==true`, Code preserved, no throw. DI: `AddSingleton<QbXmlParser>()`. *Verify:* build + test green.

4. **`QbReportParser` + report test + report fixture.**
   `QbReportParser.Parse(string) → ParsedReport`: read all `ColDesc`→`(colID,title,colType)` (tolerant: `<ColTitle value>` element or `colTitle` attr; `<ColType>` element or attr); walk `ReportData` children→`ReportRow{RowType from element name, Label/RowDataType from <RowData>, Cells: colID→title→value}`; `Title`/`Subtitle`/`Basis` from `ReportRet`. Commit `Tests/Fixtures/qbxml/GeneralSummaryReportQueryRs.pnl.qbxml` (real-sourced if possible — else note "constructed" in the PLAN; must include a `TextRow`, `DataRow`, `SubtotalRow`, `TotalRow`). `QbReportParserTests`: title, column count + titles, row-type sequence, a specific cell value by column title, last row label. DI: `AddSingleton<QbReportParser>()`. *Verify:* build + test green.

5. **`QbResponseSpiller` + spiller tests.**
   `QbResponseSpiller(IOptions<QbXmlOptions>, IConfiguration)`: `Threshold`, `ExceedsThreshold(raw)`, `SpillAsync(raw, ct) → path` (dir = `SpillPath` ?? `config["Audit:Path"]` ?? `%TEMP%\QbConnectService\spill`; `Directory.CreateDirectory`; filename `{UTC ts}-{guid:N}.qbxml`; `File.WriteAllTextAsync`). `QbResponseSpillerTests`: under threshold → `ExceedsThreshold==false`; over threshold → `SpillAsync` writes a file whose contents == input, returns its path, path is under the configured dir; cleanup. DI: `AddSingleton<QbResponseSpiller>()`. *Verify:* build + test green. *(May be folded into task 6 if the planner prefers — but a standalone task keeps commits atomic.)*

6. **`FakeRequestProcessor` multi-response extension (+ keep BC) + `ProcessRequests` capture.**
   Add `AddResponses(string requestName, params string[] inOrder)` (per-name `Queue<string>`, dequeue on `ProcessRequest`, fall back to `_responses[name]`, then `*`, then throw — preserving current behavior when no queue is registered). Add `List<string> ProcessRequests` recording each raw request string. Keep `AddResponse`/`ProcessRequestHook`/all existing surface unchanged. Extend `FakeRequestProcessorTests`: a 2-element queue dequeues in order then falls back; recorded `ProcessRequests` capture works; existing tests still pass. *Verify:* build + test green (this is purely additive in the test project; the 44 existing tests stay green).

7. **`QbListExecutor` + iterator tests.**
   `QbListExecutor(QbConnectionManager, QbXmlBuilder, QbXmlParser, QbResponseSpiller, IOptions<QbXmlOptions>, ILogger<QbListExecutor>)` with `Task<ParsedQbXmlResponse> RunAsync(XElement queryRq, CancellationToken)`: clone body, stamp `iterator="Start" MaxReturned` (+ `OwnerID=0` *only if* the caller already put it on — Phase 3 doesn't decide that; or accept a `bool ownerIdZero` param defaulting to `_opts.OwnerIdZero` — planner's call; recommend the param so Phase 4 ops can pass through), `ExecuteAsync`, parse; loop `iterator="Continue" iteratorID` while `iteratorRemainingCount>0` same `requestID`, accumulate rows; abort on `statusSeverity="Error"` surfacing that page's status; after accumulation, if concatenated raw bytes > `MaxResponseBytes` → `_spiller.SpillAsync` and set `RawSpilledTo`. Commit fixtures `CustomerQueryRs.page1.qbxml` / `CustomerQueryRs.page2.qbxml` and a big-response fixture (or generate the big string in the test). `QbListExecutorTests` (drive the real `QbConnectionManager` with a `FakeRequestProcessor` via `Func<IRequestProcessor>` + `IOptions<QbOptions>`/`IOptions<RequestOptions>`/`NullLogger` — same construction the Phase-2 `QbConnectionManagerTests` use): single page (`iteratorRemainingCount="0"`) → done, rows from that page; two pages → rows accumulated in order, `IteratorRemaining==0`, 2nd recorded request carried `iterator="Continue"` + same `iteratorID`; size-guard → `RawSpilledTo` set, file exists with the raw qbXML, rows still parsed; mid-iteration error on page 2 → loop aborts, result carries page 2's `Status.IsError==true` + the page-1 rows. DI: `AddSingleton<QbListExecutor>()`. *Verify:* build + test green.

8. **DI registration smoke + final sweep.**
   Ensure `Program.cs` registers all five engine singletons (`QbXmlBuilder`, `QbXmlParser`, `QbReportParser`, `QbResponseSpiller`, `QbListExecutor`) and `Configure<QbXmlOptions>`. Add a host-resolves test (extend `HostStartupTests` or a new test): build the test host (`WebApplicationFactory<Program>` with `Environment=Testing` + `FakeRequestProcessor` registered — same pattern Phase 1's `HostStartupTests` already use) and resolve each engine type from DI without exception; resolve `IOptions<QbXmlOptions>` and assert the bound defaults. Confirm `dotnet build` (Release, x86) and full `dotnet test` are green. *(If the planner folds this into task 7, fine — but a standalone "wire + smoke" task is clean.)*

**Estimate:** 8 tasks (could compress to 6 by folding 5→7 and 8→7), all CI-able with no QuickBooks, suite green at every commit. No new NuGet packages (unless the planner opts into `Verify.Xunit` — recommended against).

---

## Sources

### Primary (HIGH confidence)
- Project research — `.planning/research/FEATURES.md` (the qbXML quirks: `ReportQuery` `ColDesc`+positional `ColData` in typed rows `DataRow`/`SubtotalRow`/`TotalRow`/`TextRow`; iterator `Start`/`Continue`/`iteratorID`/`iteratorRemainingCount`; version PI ≤ installed build; `statusCode`/`statusSeverity`/`statusMessage` per-element AND per-message; "0 rows" not an error; `OwnerID="0"` silently gates `DataExtRet`; polymorphic `ItemQueryRs`; `RefNumber` non-unique), `.planning/research/ARCHITECTURE.md` (QbXmlBuilder/QbXmlParser pure no-I/O; separate report parser; iterator handling location; size-guard/spill), `.planning/research/STACK.md` (hand-build qbXML with `System.Xml.Linq`; `Verify.Xunit` optional; no QBFC), `.planning/PROJECT.md`/`REQUIREMENTS.md` (READ-01/02/03/11) / `ROADMAP.md` (Phase 3 detail + success criteria).
- Project design spec — `docs/superpowers/specs/2026-05-11-quickbooks-direct-sdk-accounting-design.md` §4 (qbXML version PI pinned in config; `QbXmlBuilder` targets it) §7 (size guard → file beside the audit log + reference + parsed summary).
- Phase 1 & 2 code (read directly): `IRequestProcessor.cs`, `QbConnectionManager.cs` (`Task<string> ExecuteAsync(string, CancellationToken)`, `Task<string[]> GetSupportedQbXmlVersionsAsync(...)`), `QbOptions.cs` (`OwnerIdZero` lives here today; `RequestOptions`), `QbErrors.cs`/`QbExceptions.cs`, `StaThread.cs`, `Program.cs` (DI: `Func<IRequestProcessor>` + `QbConnectionManager` singleton; `Configure<QbOptions>`/`<RequestOptions>`), `Tests/Fakes/FakeRequestProcessor.cs` (keyed by `*Rq` name; `ProcessRequestHook`; `AddResponse`; records `Last*`; `CallLog`), `Tests/QbConnectionManagerTests.cs` (construction pattern: `new QbConnectionManager(() => fake, Options.Create(qbOpts), Options.Create(reqOpts), NullLogger<...>)`), `Tests/HostStartupTests.cs` (`WebApplicationFactory<Program>` + `Environment=Testing`), `Tests/QbOptionsBindingTests.cs`, `appsettings.sample.json` (already has `QbXml:Version=16.0` and `Audit:Path`), `.planning/STATE.md` ("Completed phases" — Phase 1 & 2 inventory; "quality bar = 100/100"), `.planning/phases/02-com-session-lifecycle/02-RESEARCH.md` (conventions: zero new packages, concrete signatures, green-the-whole-way ordering).
- Intuit Developer — "Preparing report requests" (`developer.intuit.com/app/developer/qbdesktop/docs/develop/exploring-the-quickbooks-desktop-sdk/preparing-report-requests`) — confirms `ReportRet` header fields (`ReportTitle`/`ReportSubtitle`/`ReportBasis`/`NumRows`/`NumColumns`), `ColDesc` (`colID`, `ColTitle`, `ColType`), `ReportData` row types (`DataRow`/`SubtotalRow`/`TotalRow`/`TextRow`), `ColData` (`colID`+`value`), `RowData`. (HIGH on structure; exact attribute casing flagged as Open Question 1.)
- Intuit Developer — `QBXML_SDK_Samples` repo (`github.com/IntuitDeveloper/QBXML_SDK_Samples`) — `xmlfiles/legacy/CustomDetailReport.xml`, `AccountQueryRq.xml`, `qbdt/vb.NET/QBFC/SyncCustomerList/...` — corroborates request envelope shape and report-request structure.

### Secondary (MEDIUM confidence)
- ConsoliBYTE wiki — "QbXML for Querying for Customers, with iterators" (`wiki.consolibyte.com/wiki/doku.php/quickbooks_qbxml_customerquery_with_iterators`) — the iterator protocol: `iterator="Start"` + `MaxReturned` → response carries `iteratorID` + `iteratorRemainingCount`; while `iteratorRemainingCount>0` send `iterator="Continue" iteratorID="…"`; example response with `requestID="5" statusCode="0" statusSeverity="Info" iteratorRemainingCount="0" iteratorID="{eb05f701-...}"`. (Server was intermittently unreachable; corroborated by the Sanmol Software mirror and `to_qbxml` docs.)
- `to_qbxml` Ruby gem README (`rubydoc.info/gems/to_qbxml`) — confirms the request envelope: `<?xml version="1.0" encoding="US-ASCII"?>` / `<?qbxml version="13.0"?>` / `<QBXML><QBXMLMsgsRq onError="stopOnError">…</QBXMLMsgsRq></QBXML>`; iterator attributes (`requestID`, `iterator`, `iteratorID`) passed as element attributes verbatim.
- ProductiveComputing "FM Books Connector – Developer's Guide" PDF — independent confirmation of qbXML request/response patterns, the version PI, `EditSequence`, `DataExtRet`/`OwnerID`.

### Tertiary (LOW confidence — design-confirming only, not load-bearing)
- `johnballantyne/qbxml`, `qbwc/qbxml` (GitHub) — qbXML XSD schema files (`qbxmlops*.xsd`) — corroborate element names; not fetched in full.
- Claude training knowledge of the qbXML Onscreen Reference (OSR) for element names (`GeneralSummaryReportQueryRq`, `ItemServiceRet`/`ItemInventoryRet`/…, `DataExtRet`, `ColDesc`/`ColData`/`RowData`) — treated as hypothesis; consistent with the above where they overlap. The exact report attribute casing is flagged for Codex to pin from the OSR/`SDKTestPlus3` (Open Question 1).

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — `STACK.md` is explicit (hand-build with `System.Xml.Linq`, no QBFC, no new packages); in-box XLinq is the only thing needed.
- Architecture (class decomposition, pure-vs-impure boundary, `QbListExecutor`/`QbResponseSpiller` placement, `ParsedQbXmlResponse` shape): HIGH — directly derived from ARCHITECTURE.md + FEATURES.md + the Phase 1/2 code; the seam to Phase 4 (caller-built `XElement` body) is the simplest workable design.
- qbXML mechanics (envelope, version PI, status surfacing, iterator protocol, polymorphic Items, `DataExtRet` gating): HIGH — long-stable spec, multiple corroborating sources.
- Report-response shape (`ColDesc`-driven, `DataRow`/`SubtotalRow`/`TotalRow`/`TextRow`, `ColData` by `colID`): HIGH on structure, MEDIUM on exact attribute casing — flagged (Open Question 1); parser written tolerantly, fixture to be pinned from a real source.
- Pitfalls: HIGH — the XLinq-declaration trap, zero-row-as-success, sparse `ColData`, the `FakeRequestProcessor` single-response limitation, and the `OwnerID` silent gate are all concrete and verified.

**Research date:** 2026-05-11
**Valid until:** ~2026-06-10 (30 days — qbXML is a stable spec; the only volatility is whether Codex captures a real report fixture vs constructs one, which is a within-phase decision, not a research-staleness risk).

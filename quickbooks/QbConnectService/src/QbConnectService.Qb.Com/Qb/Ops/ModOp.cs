using Microsoft.Extensions.Options;
using System.Collections;
using System.Xml.Linq;
using QbConnectService.Qb;

namespace QbConnectService.Qb.Ops;

public sealed class ModOp(
    QbXmlBuilder b,
    QbConnectionManager m,
    QbXmlParser xp,
    QbReportParser rp,
    QbListExecutor le,
    AuditLog audit,
    IOptions<SafetyOptions> safety)
    : WriteOpBase(b, m, xp, rp, le, audit, safety)
{
    private static readonly IReadOnlyDictionary<string, string> EntityToRet = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
    {
        ["customer"] = "Customer",
        ["vendor"] = "Vendor",
        ["invoice"] = "Invoice",
        ["bill"] = "Bill",
        ["check"] = "Check",
    };

    private static readonly IReadOnlyDictionary<string, string[]> ReadOnlyChildren = new Dictionary<string, string[]>(StringComparer.OrdinalIgnoreCase)
    {
        ["*"] = ["TimeCreated", "TimeModified", "DataExtRet"],
        ["Customer"] = ["Balance", "TotalBalance"],
        ["Vendor"] = ["Balance"],
        ["Invoice"] = ["Subtotal", "SalesTaxTotal", "TotalAmount", "AppliedAmount", "BalanceRemaining", "IsPaid", "TxnNumber", "CurrencyRef", "ExchangeRate"],
        ["Bill"] = ["AmountDue", "OpenAmount", "IsPaid", "TxnNumber"],
        ["Check"] = ["TxnNumber"],
    };

    private static readonly string[] LineCollectionKeys = ["lines", "expenseLines", "itemLines", "debits", "credits", "appliedTo"];

    public override string Name => "mod";

    public override string BuildRequest(IReadOnlyDictionary<string, object?> args)
    {
        if (TryGetResolvedRecord(args, out var record) &&
            args.TryGetValue("__editSequence", out var editSequenceValue) &&
            editSequenceValue is string editSequence)
        {
            var (entity, refKind, refValue, fields) = ParseModArgs(args);
            var entityRet = EntityToRet[entity];
            var (_, after) = MergeStrip(entityRet, record, fields);
            var idKind = refKind == "txnID" || (record.ContainsKey("TxnID") && !record.ContainsKey("ListID")) ? "TxnID" : "ListID";
            var idValue = record.GetValueOrDefault(idKind) as string ?? refValue;
            return BuildModXml(entityRet, idKind, idValue, editSequence, after);
        }

        throw new InvalidOperationException("mod builds its qbXML inside DryRunAsync/RunAsync after a fresh read of the target. Use POST /api/ops/mod/dryrun then POST /api/ops/mod.");
    }

    public override async Task<DryRunResult> DryRunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct = default)
    {
        MultiCurrencyGuard.Reject(args);
        var (entity, refKind, refValue, fields) = ParseModArgs(args);
        var entityRet = EntityToRet[entity];
        var current = await FetchCurrentAsync(entityRet, refKind, refValue, ct)
            ?? throw new ArgumentException($"mod: no {entity} found for {refKind}={refValue}.");

        var (before, after) = MergeStrip(entityRet, current.Record, fields);
        var idKind = refKind == "txnID" || (current.Record.ContainsKey("TxnID") && !current.Record.ContainsKey("ListID")) ? "TxnID" : "ListID";
        var idValue = current.Record.GetValueOrDefault(idKind) as string ?? refValue;
        var qbXml = BuildModXml(entityRet, idKind, idValue, current.EditSequence, after);
        var diff = DiffFields($"{entity}-fields", FlattenStrings(before), FlattenStrings(after));
        var summary = $"Update {entity} {refKind}={refValue}: {(string.IsNullOrEmpty(diff.Detail) || diff.Detail == "no changes" ? "no field changes" : diff.Detail)} (EditSequence {current.EditSequence}).";

        return new DryRunResult(
            qbXml,
            summary,
            new[]
            {
                new PreFlightCheck("target-resolves", true, $"{entity} {refKind}={refValue} found"),
                new PreFlightCheck("edit-sequence-fresh", true, current.EditSequence),
                diff,
            },
            new Dictionary<string, object?>(StringComparer.Ordinal)
            {
                ["target"] = $"{entity} {refKind}={refValue}",
                ["editSequence"] = current.EditSequence,
            },
            AllowWrites);
    }

    public override async Task<object?> RunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct = default)
    {
        MultiCurrencyGuard.Reject(args);
        var (entity, refKind, refValue, fields) = ParseModArgs(args);
        if (!AllowWrites)
        {
            throw new QbWriteForbiddenException($"{Name} is a write op and Safety:AllowWrites is false.");
        }

        var entityRet = EntityToRet[entity];
        var current = await FetchCurrentAsync(entityRet, refKind, refValue, ct)
            ?? throw new ArgumentException($"mod: no {entity} found for {refKind}={refValue}.");

        var (_, after) = MergeStrip(entityRet, current.Record, fields);
        var idKind = refKind == "txnID" || (current.Record.ContainsKey("TxnID") && !current.Record.ContainsKey("ListID")) ? "TxnID" : "ListID";
        var idValue = current.Record.GetValueOrDefault(idKind) as string ?? refValue;
        var requestXml = BuildModXml(entityRet, idKind, idValue, current.EditSequence, after);
        var rawResponse = await _manager.ExecuteAsync(requestXml, ct);
        var parsed = _xmlParser.Parse(rawResponse);
        var status = parsed.Message;
        var rows = parsed.Elements.Count > 0 ? parsed.First.Rows : new List<Dictionary<string, object?>>();
        var seq = await _audit.AppendAsync(new AuditRecord(Name, args, requestXml, status.Code, status.Severity, status.Message), ct);

        return new Dictionary<string, object?>
        {
            ["status"] = status,
            ["rows"] = rows,
            ["auditSeq"] = seq,
            ["rawSpilledTo"] = parsed.RawSpilledTo,
        };
    }

    private static (string Entity, string RefKind, string RefValue, IReadOnlyDictionary<string, object?> Fields) ParseModArgs(IReadOnlyDictionary<string, object?> args)
    {
        var entity = ArgReader.RequiredString(args, "entity");
        if (!EntityToRet.ContainsKey(entity))
        {
            throw new ArgumentException($"mod: entity must be one of {string.Join("/", EntityToRet.Keys)}; got '{entity}'.");
        }

        var refDict = ArgReader.Dict(args, "ref")
            ?? throw new ArgumentException("mod: 'ref' is required and must be an object with exactly one of {txnID, listID, fullName}.");
        var refPairs = new List<(string Kind, string Value)>();
        foreach (var kind in new[] { "txnID", "listID", "fullName" })
        {
            if (ArgReader.String(refDict, kind) is { } value)
            {
                refPairs.Add((kind, value));
            }
        }

        if (refPairs.Count != 1)
        {
            throw new ArgumentException("mod: 'ref' is required and must be an object with exactly one of {txnID, listID, fullName}.");
        }

        var (refKind, refValue) = refPairs[0];
        if (string.Equals(refKind, "fullName", StringComparison.OrdinalIgnoreCase) &&
            !entity.Equals("customer", StringComparison.OrdinalIgnoreCase) &&
            !entity.Equals("vendor", StringComparison.OrdinalIgnoreCase))
        {
            throw new ArgumentException("mod: 'fullName' refs are only allowed for customer/vendor; use txnID for transactions.");
        }

        var fields = ArgReader.Dict(args, "fields")
            ?? throw new ArgumentException("mod: 'fields' is required and must be an object of header-level fields to overlay.");
        MultiCurrencyGuard.Reject(fields);

        foreach (var key in fields.Keys)
        {
            if (LineCollectionKeys.Contains(key, StringComparer.OrdinalIgnoreCase) || TouchesLineItems(key))
            {
                throw new ArgumentException($"mod v1: 'fields.{key}' touches line items, which v1 mod does not support (header-level edits only; full line-level mod is a v1.x item).");
            }
        }

        return (entity, refKind, refValue, fields);
    }

    private static (IReadOnlyDictionary<string, object?> Before, IReadOnlyDictionary<string, object?> After) MergeStrip(
        string entityRet,
        IReadOnlyDictionary<string, object?> currentRow,
        IReadOnlyDictionary<string, object?> fields)
    {
        var before = CloneDictionary(currentRow);
        var after = CloneDictionary(currentRow);
        OverlayDictionary(after, fields);

        foreach (var key in ReadOnlyChildren["*"])
        {
            after.Remove(key);
        }

        if (ReadOnlyChildren.TryGetValue(entityRet, out var entityKeys))
        {
            foreach (var key in entityKeys)
            {
                after.Remove(key);
            }
        }

        after.Remove("EditSequence");
        after.Remove("FullName");
        after.Remove("customFields");
        after.Remove(entityRet is "Customer" or "Vendor" ? "ListID" : "TxnID");

        foreach (var key in after.Keys.Where(TouchesLineItems).ToList())
        {
            after.Remove(key);
        }

        return (before, after);
    }

    private string BuildModXml(
        string entityRet,
        string idKind,
        string idValue,
        string editSequence,
        IReadOnlyDictionary<string, object?> mergedAfter)
    {
        var mod = new XElement(entityRet + "Mod", new XElement(idKind, idValue), new XElement("EditSequence", editSequence));
        foreach (var (key, value) in mergedAfter)
        {
            if (value is null)
            {
                continue;
            }

            mod.Add(BuildElement(key, value));
        }

        return _builder.BuildRequest(QbXmlBuilder.Rq(entityRet + "ModRq", mod));
    }

    private static XElement BuildElement(string key, object value)
    {
        return value switch
        {
            IReadOnlyDictionary<string, object?> readOnlyDict => new XElement(key, readOnlyDict.Select(pair => pair.Value is null ? null : BuildElement(pair.Key, pair.Value))),
            IDictionary<string, object?> dict => new XElement(key, dict.Select(pair => pair.Value is null ? null : BuildElement(pair.Key, pair.Value))),
            IEnumerable enumerable when value is not string => new XElement(key, enumerable.Cast<object?>().Where(item => item is not null).Select(item => BuildElement(key, item!))),
            _ => new XElement(key, value),
        };
    }

    private static bool TryGetResolvedRecord(IReadOnlyDictionary<string, object?> args, out IReadOnlyDictionary<string, object?> record)
    {
        if (args.TryGetValue("__resolvedRecord", out var value))
        {
            switch (value)
            {
                case IReadOnlyDictionary<string, object?> readOnly:
                    record = readOnly;
                    return true;
                case IDictionary<string, object?> dict:
                    record = new Dictionary<string, object?>(dict, StringComparer.OrdinalIgnoreCase);
                    return true;
            }
        }

        record = default!;
        return false;
    }

    private static Dictionary<string, object?> CloneDictionary(IReadOnlyDictionary<string, object?> source)
    {
        var clone = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase);
        foreach (var (key, value) in source)
        {
            clone[key] = DeepClone(value);
        }

        return clone;
    }

    private static object? DeepClone(object? value)
    {
        return value switch
        {
            IReadOnlyDictionary<string, object?> readOnly => CloneDictionary(readOnly),
            IDictionary<string, object?> dict => CloneDictionary(new Dictionary<string, object?>(dict, StringComparer.OrdinalIgnoreCase)),
            IEnumerable enumerable when value is not string => enumerable.Cast<object?>().Select(DeepClone).ToList(),
            _ => value,
        };
    }

    private static void OverlayDictionary(Dictionary<string, object?> target, IReadOnlyDictionary<string, object?> overlay)
    {
        foreach (var (inputKey, newValue) in overlay)
        {
            var existingKey = target.Keys.FirstOrDefault(key => string.Equals(key, inputKey, StringComparison.OrdinalIgnoreCase));
            var canonicalKey = existingKey ?? CanonicalizeKey(inputKey);

            if (newValue is IReadOnlyDictionary<string, object?> newReadOnlyDict)
            {
                if (existingKey is not null && target[existingKey] is IReadOnlyDictionary<string, object?> existingReadOnlyDict)
                {
                    var merged = CloneDictionary(existingReadOnlyDict);
                    OverlayDictionary(merged, newReadOnlyDict);
                    target[canonicalKey] = merged;
                }
                else if (existingKey is not null && target[existingKey] is IDictionary<string, object?> existingDict)
                {
                    var merged = CloneDictionary(new Dictionary<string, object?>(existingDict, StringComparer.OrdinalIgnoreCase));
                    OverlayDictionary(merged, newReadOnlyDict);
                    target[canonicalKey] = merged;
                }
                else
                {
                    target[canonicalKey] = CloneDictionary(newReadOnlyDict);
                }

                continue;
            }

            target[canonicalKey] = DeepClone(newValue);
        }
    }

    private static string CanonicalizeKey(string key)
    {
        if (string.IsNullOrEmpty(key))
        {
            return key;
        }

        if (key.Length > 2 && key.StartsWith("ar", StringComparison.OrdinalIgnoreCase) && char.IsUpper(key[2]))
        {
            return "AR" + key[2..];
        }

        if (key.Length > 2 && key.StartsWith("ap", StringComparison.OrdinalIgnoreCase) && char.IsUpper(key[2]))
        {
            return "AP" + key[2..];
        }

        return char.ToUpperInvariant(key[0]) + key[1..];
    }

    private static Dictionary<string, string?> FlattenStrings(IReadOnlyDictionary<string, object?> source)
    {
        var flattened = new Dictionary<string, string?>(StringComparer.OrdinalIgnoreCase);
        foreach (var (key, value) in source)
        {
            FlattenValue(flattened, key, value);
        }

        return flattened;
    }

    private static void FlattenValue(Dictionary<string, string?> flattened, string path, object? value)
    {
        var key = path.Split('.').Last();
        if (ShouldIgnoreForDiff(key))
        {
            return;
        }

        switch (value)
        {
            case null:
                flattened[path] = null;
                break;
            case IReadOnlyDictionary<string, object?> readOnlyDict:
                foreach (var (childKey, childValue) in readOnlyDict)
                {
                    FlattenValue(flattened, $"{path}.{childKey}", childValue);
                }

                break;
            case IDictionary<string, object?> dict:
                foreach (var (childKey, childValue) in dict)
                {
                    FlattenValue(flattened, $"{path}.{childKey}", childValue);
                }

                break;
            case IEnumerable enumerable when value is not string:
                var index = 0;
                foreach (var item in enumerable.Cast<object?>())
                {
                    FlattenValue(flattened, $"{path}[{index}]", item);
                    index++;
                }

                break;
            default:
                flattened[path] = value.ToString();
                break;
        }
    }

    private static bool ShouldIgnoreForDiff(string key) =>
        key is "ListID" or "TxnID" or "EditSequence" or "FullName" or "TimeCreated" or "TimeModified" or "Balance" or "TotalBalance" or "Subtotal" or "SalesTaxTotal" or "TotalAmount" or "AppliedAmount" or "BalanceRemaining" or "IsPaid" or "TxnNumber" or "CurrencyRef" or "ExchangeRate" or "AmountDue" or "OpenAmount" or "customFields"
        || TouchesLineItems(key);

    private static bool TouchesLineItems(string key) =>
        key.Contains("Line", StringComparison.OrdinalIgnoreCase);
}

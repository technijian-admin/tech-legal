using Microsoft.Extensions.Options;
using QbConnectService.Qb;
using QbConnectService.Qb.Ops;

namespace QbConnectService.Tests.Fakes;

public sealed class FakeWriteOp : WriteOpBase
{
    public const string OpName = "fake_create";
    public const string KnownRequestXml =
        "<?xml version=\"1.0\" encoding=\"utf-8\"?><?qbxml version=\"16.0\"?><QBXML><QBXMLMsgsRq onError=\"stopOnError\"><CustomerAddRq><CustomerAdd><Name>FAKE</Name></CustomerAdd></CustomerAddRq></QBXMLMsgsRq></QBXML>";

    public FakeWriteOp(
        QbXmlBuilder builder,
        QbConnectionManager manager,
        QbXmlParser xmlParser,
        QbReportParser reportParser,
        QbListExecutor listExecutor,
        AuditLog audit,
        IOptions<SafetyOptions> safety)
        : base(builder, manager, xmlParser, reportParser, listExecutor, audit, safety)
    {
    }

    public override string Name => OpName;

    public override string BuildRequest(IReadOnlyDictionary<string, object?> args) => KnownRequestXml;

    public override Task<DryRunResult> DryRunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct = default) =>
        Task.FromResult(new DryRunResult(
            KnownRequestXml,
            "fake_create: would create customer 'FAKE'.",
            new[]
            {
                new PreFlightCheck("name-not-empty", true, "name = 'FAKE'"),
                DiffFields(
                    "customer-fields",
                    new Dictionary<string, string?> { ["Name"] = "OLD" },
                    new Dictionary<string, string?> { ["Name"] = "FAKE" }),
            },
            new Dictionary<string, object?> { ["customer"] = "FAKE (no ListID - new)" },
            AllowWrites));
}

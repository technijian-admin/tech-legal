using System.Text;
using System.Xml.Linq;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace QbConnectService.Qb;

public sealed class QbListExecutor
{
    private readonly QbConnectionManager _manager;
    private readonly QbXmlBuilder _builder;
    private readonly QbXmlParser _parser;
    private readonly QbResponseSpiller _spiller;
    private readonly QbXmlOptions _opts;
    private readonly ILogger<QbListExecutor> _log;

    public QbListExecutor(
        QbConnectionManager manager,
        QbXmlBuilder builder,
        QbXmlParser parser,
        QbResponseSpiller spiller,
        IOptions<QbXmlOptions> opts,
        ILogger<QbListExecutor> log)
    {
        _manager = manager;
        _builder = builder;
        _parser = parser;
        _spiller = spiller;
        _opts = opts.Value;
        _log = log;
    }

    public async Task<ParsedQbXmlResponse> RunAsync(XElement queryRq, bool? ownerIdZero = null, CancellationToken ct = default)
    {
        var emitOwnerId = ownerIdZero ?? _opts.OwnerIdZero;
        const string requestId = "1";
        var rawPages = new StringBuilder();

        var startBody = new XElement(queryRq);
        QbXmlBuilder.WithIterator(startBody, IteratorMode.Start, maxReturned: _opts.MaxReturned, requestId: requestId);
        if (emitOwnerId)
        {
            QbXmlBuilder.WithOwnerIdZero(startBody);
        }

        var raw = await _manager.ExecuteAsync(_builder.BuildRequest(startBody), ct);
        rawPages.Append(raw);

        var parsed = _parser.Parse(raw);
        var first = parsed.First;

        if (first.Status.IsError)
        {
            return await FinishAsync(parsed, rawPages, ct);
        }

        var accumulated = new List<Dictionary<string, object?>>(first.Rows);
        var iteratorId = first.IteratorId;
        var remaining = first.IteratorRemaining ?? 0;

        while (remaining > 0 && iteratorId is not null)
        {
            var continueBody = new XElement(queryRq);
            QbXmlBuilder.WithIterator(
                continueBody,
                IteratorMode.Continue,
                iteratorId: iteratorId,
                maxReturned: _opts.MaxReturned,
                requestId: requestId);

            if (emitOwnerId)
            {
                QbXmlBuilder.WithOwnerIdZero(continueBody);
            }

            raw = await _manager.ExecuteAsync(_builder.BuildRequest(continueBody), ct);
            rawPages.Append(raw);

            var next = _parser.Parse(raw).First;
            if (next.Status.IsError)
            {
                return await FinishAsync(
                    new ParsedQbXmlResponse(parsed.Message, [next with { Rows = accumulated }]),
                    rawPages,
                    ct);
            }

            accumulated.AddRange(next.Rows);
            iteratorId = next.IteratorId ?? iteratorId;
            remaining = next.IteratorRemaining ?? 0;

            _log.LogDebug("Iterator page fetched; {Remaining} remaining, {Total} rows so far.", remaining, accumulated.Count);
        }

        var merged = new ParsedQbXmlResponse(
            parsed.Message,
            [first with { Rows = accumulated, IteratorRemaining = 0 }]);

        return await FinishAsync(merged, rawPages, ct);
    }

    private async Task<ParsedQbXmlResponse> FinishAsync(
        ParsedQbXmlResponse result,
        StringBuilder rawPages,
        CancellationToken ct)
    {
        var raw = rawPages.ToString();
        if (_spiller.ExceedsThreshold(raw))
        {
            var path = await _spiller.SpillAsync(raw, ct);
            _log.LogInformation(
                "Iterator response {Bytes} bytes exceeded {Limit}; spilled raw qbXML to {Path}.",
                Encoding.UTF8.GetByteCount(raw),
                _spiller.Threshold,
                path);
            return result with { RawSpilledTo = path };
        }

        return result;
    }
}

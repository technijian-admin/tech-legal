using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace QbConnectService.Qb;

public sealed class AuditLog
{
    private const string GenesisPrevHash = "0000000000000000000000000000000000000000000000000000000000000000";

    private readonly string _filePath;
    private readonly string _requesterId;
    private readonly SemaphoreSlim _gate = new(1, 1);
    private readonly ILogger<AuditLog> _log;

    private long _lastSeq = -1;
    private string _lastHash = GenesisPrevHash;
    private bool _loaded;

    public AuditLog(IOptions<AuditOptions> audit, IOptions<AuditAuthOptions> auth, ILogger<AuditLog> log)
    {
        var directory = string.IsNullOrWhiteSpace(audit.Value.Path)
            ? Path.Combine(Path.GetTempPath(), "QbConnectService", "audit")
            : audit.Value.Path;

        _filePath = Path.Combine(directory, "audit.jsonl");
        _requesterId = DeriveRequesterId(auth.Value.ApiToken);
        _log = log;
    }

    public async Task<long> AppendAsync(AuditRecord rec, CancellationToken ct = default)
    {
        await _gate.WaitAsync(ct);
        try
        {
            await EnsureLoadedAsync(ct);

            var seq = _lastSeq + 1;
            var timestampUtc = DateTime.UtcNow;
            var (canonical, hash) = ComputeRecord(
                seq,
                timestampUtc,
                rec.Op,
                writer => JsonSerializer.Serialize(writer, rec.Args),
                rec.QbXmlRequest,
                rec.ResponseStatusCode,
                rec.ResponseStatusSeverity,
                rec.ResponseStatusMessage,
                _requesterId,
                _lastHash);

            Directory.CreateDirectory(Path.GetDirectoryName(_filePath)!);
            await File.AppendAllTextAsync(_filePath, WithHash(canonical, hash) + "\n", ct);

            _lastSeq = seq;
            _lastHash = hash;

            return seq;
        }
        finally
        {
            _gate.Release();
        }
    }

    public async Task<(bool Ok, long? FirstBrokenSeq)> VerifyChainAsync(CancellationToken ct = default)
    {
        await _gate.WaitAsync(ct);
        try
        {
            if (!File.Exists(_filePath))
            {
                return (true, null);
            }

            var prevHash = GenesisPrevHash;
            long expectedSeq = 0;

            await foreach (var line in File.ReadLinesAsync(_filePath, ct))
            {
                if (string.IsNullOrWhiteSpace(line))
                {
                    continue;
                }

                JsonObject row;
                try
                {
                    row = JsonNode.Parse(line)?.AsObject()
                        ?? throw new JsonException("Audit row is null.");
                }
                catch (Exception exception) when (exception is JsonException or FormatException)
                {
                    _log.LogWarning(exception, "Audit verification failed: malformed row at expected seq {ExpectedSeq}.", expectedSeq);
                    return (false, expectedSeq);
                }

                var brokenSeq = TryGetLong(row["seq"], out var seq) ? seq : expectedSeq;
                if (!TryGetLong(row["seq"], out seq))
                {
                    return (false, brokenSeq);
                }

                var storedHash = row["hash"]?.GetValue<string>();
                var storedPrevHash = row["prevHash"]?.GetValue<string>();
                var timestampText = row["timestampUtc"]?.GetValue<string>();
                var op = row["op"]?.GetValue<string>();
                var qbXmlRequest = row["qbXmlRequest"]?.GetValue<string>();
                var responseStatusCode = row["responseStatusCode"]?.GetValue<string>();
                var responseStatusSeverity = row["responseStatusSeverity"]?.GetValue<string>();
                var responseStatusMessage = row["responseStatusMessage"]?.GetValue<string>();
                var requesterId = row["requesterId"]?.GetValue<string>();
                var argsNode = row["args"];

                if (storedHash is null ||
                    storedPrevHash is null ||
                    timestampText is null ||
                    op is null ||
                    qbXmlRequest is null ||
                    responseStatusCode is null ||
                    responseStatusSeverity is null ||
                    responseStatusMessage is null ||
                    requesterId is null ||
                    argsNode is null)
                {
                    return (false, brokenSeq);
                }

                DateTime timestampUtc;
                try
                {
                    timestampUtc = DateTime.Parse(timestampText, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind);
                }
                catch (FormatException exception)
                {
                    _log.LogWarning(exception, "Audit verification failed: invalid timestamp at seq {Seq}.", brokenSeq);
                    return (false, brokenSeq);
                }

                var (_, recomputedHash) = ComputeRecord(
                    seq,
                    timestampUtc,
                    op,
                    writer => argsNode.WriteTo(writer),
                    qbXmlRequest,
                    responseStatusCode,
                    responseStatusSeverity,
                    responseStatusMessage,
                    requesterId,
                    storedPrevHash);

                if (seq != expectedSeq || !string.Equals(storedPrevHash, prevHash, StringComparison.Ordinal) || !string.Equals(recomputedHash, storedHash, StringComparison.Ordinal))
                {
                    return (false, seq);
                }

                prevHash = storedHash;
                expectedSeq = seq + 1;
            }

            return (true, null);
        }
        finally
        {
            _gate.Release();
        }
    }

    private async Task EnsureLoadedAsync(CancellationToken ct)
    {
        if (_loaded)
        {
            return;
        }

        _loaded = true;

        if (!File.Exists(_filePath))
        {
            return;
        }

        string? lastLine = null;
        await foreach (var line in File.ReadLinesAsync(_filePath, ct))
        {
            if (!string.IsNullOrWhiteSpace(line))
            {
                lastLine = line;
            }
        }

        if (lastLine is null)
        {
            return;
        }

        JsonObject row;
        try
        {
            row = JsonNode.Parse(lastLine)?.AsObject()
                ?? throw new JsonException("Audit row is null.");
        }
        catch (Exception exception) when (exception is JsonException or FormatException)
        {
            throw new InvalidOperationException("Existing audit log contains a malformed row.", exception);
        }

        if (!TryGetLong(row["seq"], out var seq) || row["hash"]?.GetValue<string>() is not string hash)
        {
            throw new InvalidOperationException("Existing audit log is missing seq/hash metadata.");
        }

        _lastSeq = seq;
        _lastHash = hash;
    }

    private static (string Canonical, string Hash) ComputeRecord(
        long seq,
        DateTime timestampUtc,
        string op,
        Action<Utf8JsonWriter> writeArgs,
        string qbXmlRequest,
        string responseStatusCode,
        string responseStatusSeverity,
        string responseStatusMessage,
        string requesterId,
        string prevHash)
    {
        using var stream = new MemoryStream();
        using (var writer = new Utf8JsonWriter(stream))
        {
            WriteCanonical(
                writer,
                seq,
                timestampUtc,
                op,
                writeArgs,
                qbXmlRequest,
                responseStatusCode,
                responseStatusSeverity,
                responseStatusMessage,
                requesterId,
                prevHash);
        }

        var bytes = stream.ToArray();
        var canonical = Encoding.UTF8.GetString(bytes);
        var hash = Convert.ToHexString(SHA256.HashData(bytes)).ToLowerInvariant();
        return (canonical, hash);
    }

    private static void WriteCanonical(
        Utf8JsonWriter writer,
        long seq,
        DateTime timestampUtc,
        string op,
        Action<Utf8JsonWriter> writeArgs,
        string qbXmlRequest,
        string responseStatusCode,
        string responseStatusSeverity,
        string responseStatusMessage,
        string requesterId,
        string prevHash)
    {
        writer.WriteStartObject();
        writer.WriteNumber("seq", seq);
        writer.WriteString("timestampUtc", timestampUtc.ToString("O", CultureInfo.InvariantCulture));
        writer.WriteString("op", op);
        writer.WritePropertyName("args");
        writeArgs(writer);
        writer.WriteString("qbXmlRequest", qbXmlRequest);
        writer.WriteString("responseStatusCode", responseStatusCode);
        writer.WriteString("responseStatusSeverity", responseStatusSeverity);
        writer.WriteString("responseStatusMessage", responseStatusMessage);
        writer.WriteString("requesterId", requesterId);
        writer.WriteString("prevHash", prevHash);
        writer.WriteEndObject();
        writer.Flush();
    }

    private static string WithHash(string canonicalMinusHash, string hash) =>
        canonicalMinusHash[..^1] + ",\"hash\":" + JsonSerializer.Serialize(hash) + "}";

    private static string DeriveRequesterId(string? token)
    {
        if (string.IsNullOrWhiteSpace(token))
        {
            return "api";
        }

        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(token));
        return "tok-" + Convert.ToHexString(bytes).ToLowerInvariant()[..8];
    }

    private static bool TryGetLong(JsonNode? node, out long value)
    {
        if (node is JsonValue jsonValue && jsonValue.TryGetValue<long>(out value))
        {
            return true;
        }

        value = default;
        return false;
    }
}

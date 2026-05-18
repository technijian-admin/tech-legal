using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using QbConnectService.Qb;

namespace QbConnectService.Tests;

public sealed class AuditLogTests
{
    [Fact]
    public async Task append_writes_one_line_per_record_and_returns_incrementing_seq()
    {
        var auditDir = CreateTempDir();
        try
        {
            var audit = CreateAuditLog(auditDir);

            var seq0 = await audit.AppendAsync(CreateRecord("msg-0"));
            var seq1 = await audit.AppendAsync(CreateRecord("msg-1"));
            var seq2 = await audit.AppendAsync(CreateRecord("msg-2"));

            Assert.Equal([0L, 1L, 2L], new[] { seq0, seq1, seq2 });
            Assert.Equal(3, File.ReadAllLines(Path.Combine(auditDir, "audit.jsonl")).Length);
        }
        finally
        {
            DeleteDirectory(auditDir);
        }
    }

    [Fact]
    public async Task first_row_prevHash_is_genesis_and_each_row_chains()
    {
        var auditDir = CreateTempDir();
        try
        {
            var audit = CreateAuditLog(auditDir);
            await audit.AppendAsync(CreateRecord("msg-0"));
            await audit.AppendAsync(CreateRecord("msg-1"));
            await audit.AppendAsync(CreateRecord("msg-2"));

            var rows = ReadRows(auditDir);
            Assert.Equal(new string('0', 64), rows[0]["prevHash"]!.GetValue<string>());
            Assert.Equal(rows[0]["hash"]!.GetValue<string>(), rows[1]["prevHash"]!.GetValue<string>());
            Assert.Equal(rows[1]["hash"]!.GetValue<string>(), rows[2]["prevHash"]!.GetValue<string>());
        }
        finally
        {
            DeleteDirectory(auditDir);
        }
    }

    [Fact]
    public async Task each_rows_hash_recomputes()
    {
        var auditDir = CreateTempDir();
        try
        {
            var audit = CreateAuditLog(auditDir);
            await audit.AppendAsync(CreateRecord("msg-0"));
            await audit.AppendAsync(CreateRecord("msg-1"));
            await audit.AppendAsync(CreateRecord("msg-2"));

            foreach (var row in ReadRows(auditDir))
            {
                Assert.Equal(row["hash"]!.GetValue<string>(), RecomputeHash(row));
            }
        }
        finally
        {
            DeleteDirectory(auditDir);
        }
    }

    [Fact]
    public async Task verify_chain_ok_for_untampered_log()
    {
        var auditDir = CreateTempDir();
        try
        {
            var audit = CreateAuditLog(auditDir);
            await audit.AppendAsync(CreateRecord("msg-0"));
            await audit.AppendAsync(CreateRecord("msg-1"));
            await audit.AppendAsync(CreateRecord("msg-2"));

            var result = await audit.VerifyChainAsync();

            Assert.True(result.Ok);
            Assert.Null(result.FirstBrokenSeq);
        }
        finally
        {
            DeleteDirectory(auditDir);
        }
    }

    [Fact]
    public async Task tampering_a_row_breaks_the_chain()
    {
        var auditDir = CreateTempDir();
        try
        {
            var audit = CreateAuditLog(auditDir);
            await audit.AppendAsync(CreateRecord("msg-0"));
            await audit.AppendAsync(CreateRecord("msg-1"));
            await audit.AppendAsync(CreateRecord("msg-2"));

            var filePath = Path.Combine(auditDir, "audit.jsonl");
            var lines = File.ReadAllLines(filePath);
            lines[1] = lines[1].Replace("msg-1", "tampered", StringComparison.Ordinal);
            File.WriteAllLines(filePath, lines);

            var result = await audit.VerifyChainAsync();

            Assert.False(result.Ok);
            Assert.Equal(1L, result.FirstBrokenSeq);
        }
        finally
        {
            DeleteDirectory(auditDir);
        }
    }

    [Fact]
    public async Task requesterId_is_hashed_prefix_not_raw_token()
    {
        var auditDir = CreateTempDir();
        try
        {
            var audit = CreateAuditLog(auditDir, "super-secret-token");
            await audit.AppendAsync(CreateRecord("msg-0"));

            var requesterId = ReadRows(auditDir)[0]["requesterId"]!.GetValue<string>();

            Assert.StartsWith("tok-", requesterId, StringComparison.Ordinal);
            Assert.Equal(12, requesterId.Length);
            Assert.DoesNotContain("super-secret-token", requesterId, StringComparison.Ordinal);
        }
        finally
        {
            DeleteDirectory(auditDir);
        }
    }

    [Fact]
    public async Task blank_audit_path_falls_back_without_throwing()
    {
        var fallbackDir = Path.Combine(Path.GetTempPath(), "QbConnectService", "audit");
        DeleteDirectory(fallbackDir);

        try
        {
            var audit = CreateAuditLog(string.Empty);
            await audit.AppendAsync(CreateRecord("msg-0"));

            Assert.True(File.Exists(Path.Combine(fallbackDir, "audit.jsonl")));
        }
        finally
        {
            DeleteDirectory(fallbackDir);
        }
    }

    private static AuditLog CreateAuditLog(string auditPath, string token = "test-token") =>
        new(
            Options.Create(new AuditOptions { Path = auditPath }),
            Options.Create(new AuditAuthOptions { ApiToken = token }),
            NullLogger<AuditLog>.Instance);

    private static AuditRecord CreateRecord(string message) =>
        new(
            "fake_create",
            new Dictionary<string, object?>
            {
                ["name"] = "FAKE",
                ["message"] = message,
            },
            $"<QBXML>{message}</QBXML>",
            "0",
            "Info",
            message);

    private static List<JsonObject> ReadRows(string auditDir) =>
        File.ReadAllLines(Path.Combine(auditDir, "audit.jsonl"))
            .Where(line => !string.IsNullOrWhiteSpace(line))
            .Select(line => JsonNode.Parse(line)!.AsObject())
            .ToList();

    private static string RecomputeHash(JsonObject row)
    {
        using var stream = new MemoryStream();
        using (var writer = new Utf8JsonWriter(stream))
        {
            writer.WriteStartObject();
            writer.WriteNumber("seq", row["seq"]!.GetValue<long>());
            writer.WriteString(
                "timestampUtc",
                DateTime.Parse(row["timestampUtc"]!.GetValue<string>(), CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind)
                    .ToString("O", CultureInfo.InvariantCulture));
            writer.WriteString("op", row["op"]!.GetValue<string>());
            writer.WriteString("company", row["company"]!.GetValue<string>());
            writer.WritePropertyName("args");
            row["args"]!.WriteTo(writer);
            writer.WriteString("qbXmlRequest", row["qbXmlRequest"]!.GetValue<string>());
            writer.WriteString("responseStatusCode", row["responseStatusCode"]!.GetValue<string>());
            writer.WriteString("responseStatusSeverity", row["responseStatusSeverity"]!.GetValue<string>());
            writer.WriteString("responseStatusMessage", row["responseStatusMessage"]!.GetValue<string>());
            writer.WriteString("requesterId", row["requesterId"]!.GetValue<string>());
            writer.WriteString("prevHash", row["prevHash"]!.GetValue<string>());
            writer.WriteEndObject();
            writer.Flush();
        }

        return Convert.ToHexString(SHA256.HashData(stream.ToArray())).ToLowerInvariant();
    }

    private static string CreateTempDir()
    {
        var path = Path.Combine(Path.GetTempPath(), "qbtest", Guid.NewGuid().ToString());
        Directory.CreateDirectory(path);
        return path;
    }

    private static void DeleteDirectory(string path)
    {
        if (Directory.Exists(path))
        {
            Directory.Delete(path, recursive: true);
        }
    }
}

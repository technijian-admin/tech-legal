using System.Text.Json.Nodes;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using QbConnectService;
using QbConnectService.Qb;

namespace QbConnectService.Tests;

public sealed class VerifyAuditCliTests
{
    [Fact]
    public async Task verify_audit_cli_returns_zero_for_valid_chain()
    {
        var auditDir = CreateTempDir();

        try
        {
            var audit = CreateAuditLog(auditDir);
            await audit.AppendAsync(CreateRecord("msg-0"));
            await audit.AppendAsync(CreateRecord("msg-1"));

            var verify = await audit.VerifyChainAsync();
            Assert.True(verify.Ok);
            Assert.Null(verify.FirstBrokenSeq);

            var output = new StringWriter();
            var error = new StringWriter();
            var exitCode = await Program.RunVerifyAuditAsync(CreateConfiguration(auditDir), output, error);

            Assert.Equal(0, exitCode);
            Assert.Contains("audit chain OK", output.ToString(), StringComparison.Ordinal);
            Assert.Equal(string.Empty, error.ToString());
        }
        finally
        {
            DeleteDirectory(auditDir);
        }
    }

    [Fact]
    public async Task verify_audit_cli_returns_one_for_tampered_chain()
    {
        var auditDir = CreateTempDir();

        try
        {
            var audit = CreateAuditLog(auditDir);
            await audit.AppendAsync(CreateRecord("msg-0"));
            await audit.AppendAsync(CreateRecord("msg-1"));

            var filePath = Path.Combine(auditDir, "audit.jsonl");
            var lines = File.ReadAllLines(filePath);
            lines[1] = lines[1].Replace("msg-1", "tampered", StringComparison.Ordinal);
            File.WriteAllLines(filePath, lines);

            var verify = await audit.VerifyChainAsync();
            Assert.False(verify.Ok);
            Assert.Equal(1L, verify.FirstBrokenSeq);

            var output = new StringWriter();
            var error = new StringWriter();
            var exitCode = await Program.RunVerifyAuditAsync(CreateConfiguration(auditDir), output, error);

            Assert.Equal(1, exitCode);
            Assert.Equal(string.Empty, output.ToString());
            Assert.Contains("audit chain BROKEN at seq 1", error.ToString(), StringComparison.Ordinal);
        }
        finally
        {
            DeleteDirectory(auditDir);
        }
    }

    private static IConfiguration CreateConfiguration(string auditDir) =>
        new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Audit:Path"] = auditDir,
                ["Auth:ApiToken"] = "test-token",
            })
            .Build();

    private static AuditLog CreateAuditLog(string auditDir) =>
        new(
            Options.Create(new AuditOptions { Path = auditDir }),
            Options.Create(new AuditAuthOptions { ApiToken = "test-token" }),
            NullLogger<AuditLog>.Instance);

    private static AuditRecord CreateRecord(string message) =>
        new(
            "create_customer",
            new Dictionary<string, object?>
            {
                ["name"] = "ZZ_SMOKE",
                ["message"] = message,
            },
            $"<QBXML>{message}</QBXML>",
            "0",
            "Info",
            message);

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

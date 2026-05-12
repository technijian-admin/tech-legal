using System.Text.Json;
using Microsoft.Extensions.Configuration;
using QbConnectService;
using QbConnectService.Qb;

namespace QbConnectService.Tests;

public sealed class SampleConfigParityTests
{
    [Fact]
    public void appsettings_sample_contains_every_bound_option_key()
    {
        var samplePath = FindRepoFile("quickbooks", "QbConnectService", "src", "QbConnectService", "appsettings.sample.json");
        using var json = JsonDocument.Parse(File.ReadAllText(samplePath));
        var configuration = new ConfigurationBuilder()
            .AddJsonFile(samplePath, optional: false)
            .Build();

        AssertSectionKeys<ServerOptions>(configuration, json.RootElement, "Server");
        AssertSectionKeys<AuthOptions>(configuration, json.RootElement, "Auth");
        AssertSectionKeys<QbOptions>(configuration, json.RootElement, "Qb");
        AssertSectionKeys<SafetyOptions>(configuration, json.RootElement, "Safety");
        AssertSectionKeys<QbXmlOptions>(configuration, json.RootElement, "QbXml");
        AssertSectionKeys<AuditOptions>(configuration, json.RootElement, "Audit");
        AssertSectionKeys<RequestOptions>(configuration, json.RootElement, "Request");
        AssertSectionKeys<AuditAuthOptions>(configuration, json.RootElement, "Auth");
    }

    [Fact]
    public void env_sample_contains_every_qb_client_key()
    {
        var samplePath = FindRepoFile("quickbooks", "clients", ".env.sample");
        var entries = ParseEnv(samplePath);

        foreach (var key in new[] { "QB_API_BASE_URL", "QB_API_TOKEN", "QB_VERIFY_TLS", "QB_TIMEOUT", "QB_RETRIES" })
        {
            Assert.True(entries.ContainsKey(key), $"Missing '{key}' in quickbooks/clients/.env.sample.");
        }
    }

    private static void AssertSectionKeys<T>(IConfiguration configuration, JsonElement root, string sectionName)
    {
        var section = configuration.GetSection(sectionName);
        var bound = section.Get<T>();
        Assert.NotNull(bound);

        Assert.True(root.TryGetProperty(sectionName, out var rawSection), $"Missing '{sectionName}' section in appsettings.sample.json.");
        Assert.Equal(JsonValueKind.Object, rawSection.ValueKind);

        foreach (var property in typeof(T).GetProperties().Where(property => property.SetMethod is not null && property.SetMethod.IsPublic))
        {
            Assert.True(
                rawSection.TryGetProperty(property.Name, out _),
                $"Missing '{sectionName}:{property.Name}' in appsettings.sample.json.");
        }
    }

    private static Dictionary<string, string> ParseEnv(string path)
    {
        var entries = new Dictionary<string, string>(StringComparer.Ordinal);

        foreach (var rawLine in File.ReadAllLines(path))
        {
            var line = rawLine.Trim();
            if (string.IsNullOrWhiteSpace(line) || line.StartsWith('#'))
            {
                continue;
            }

            var equalsIndex = line.IndexOf('=');
            Assert.True(equalsIndex > 0, $"Malformed env line in {path}: '{rawLine}'.");

            var key = line[..equalsIndex].Trim();
            var value = line[(equalsIndex + 1)..].Trim();
            entries[key] = value;
        }

        return entries;
    }

    private static string FindRepoFile(params string[] relativeSegments)
    {
        var current = new DirectoryInfo(AppContext.BaseDirectory);

        while (current is not null)
        {
            var candidate = Path.Combine(new[] { current.FullName }.Concat(relativeSegments).ToArray());
            if (File.Exists(candidate))
            {
                return candidate;
            }

            current = current.Parent;
        }

        throw new FileNotFoundException($"Could not locate '{Path.Combine(relativeSegments)}' from '{AppContext.BaseDirectory}'.");
    }
}

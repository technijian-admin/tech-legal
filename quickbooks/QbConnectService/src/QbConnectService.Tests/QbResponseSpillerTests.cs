using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Options;
using QbConnectService.Qb;

namespace QbConnectService.Tests;

public sealed class QbResponseSpillerTests
{
    [Fact]
    public void ExceedsThreshold_returns_false_when_payload_is_small()
    {
        var directory = TempDirectory();

        try
        {
            var spiller = Spiller(1_000_000, directory);
            Assert.False(spiller.ExceedsThreshold("<small/>"));
        }
        finally
        {
            DeleteDirectory(directory);
        }
    }

    [Fact]
    public async Task SpillAsync_writes_large_payloads_to_the_configured_directory()
    {
        var directory = TempDirectory();

        try
        {
            var spiller = Spiller(10, directory);
            var payload = new string('x', 5000);

            Assert.True(spiller.ExceedsThreshold(payload));

            var path = await spiller.SpillAsync(payload);

            Assert.True(File.Exists(path));
            Assert.Equal(payload, await File.ReadAllTextAsync(path));
            Assert.StartsWith(directory, path, StringComparison.OrdinalIgnoreCase);
            Assert.EndsWith(".qbxml", path, StringComparison.OrdinalIgnoreCase);
        }
        finally
        {
            DeleteDirectory(directory);
        }
    }

    [Fact]
    public async Task SpillAsync_falls_back_to_Audit_Path_when_SpillPath_is_empty()
    {
        var directory = TempDirectory();

        try
        {
            var config = new ConfigurationBuilder()
                .AddInMemoryCollection(new Dictionary<string, string?> { ["Audit:Path"] = directory })
                .Build();
            var spiller = new QbResponseSpiller(
                Options.Create(new QbXmlOptions { MaxResponseBytes = 10, SpillPath = string.Empty }),
                config);

            var path = await spiller.SpillAsync("<x/>");

            Assert.True(File.Exists(path));
            Assert.StartsWith(directory, path, StringComparison.OrdinalIgnoreCase);
        }
        finally
        {
            DeleteDirectory(directory);
        }
    }

    [Fact]
    public async Task SpillAsync_falls_back_to_temp_when_no_explicit_path_is_configured()
    {
        var spiller = new QbResponseSpiller(
            Options.Create(new QbXmlOptions { MaxResponseBytes = 10, SpillPath = string.Empty }),
            new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>()).Build());
        var expectedRoot = Path.Combine(Path.GetTempPath(), "QbConnectService", "spill");
        string? path = null;

        try
        {
            path = await spiller.SpillAsync("<x/>");

            Assert.True(File.Exists(path));
            Assert.StartsWith(expectedRoot, path, StringComparison.OrdinalIgnoreCase);
        }
        finally
        {
            if (path is not null && File.Exists(path))
            {
                File.Delete(path);
            }

            DeleteDirectory(expectedRoot);
        }
    }

    [Fact]
    public void Threshold_exposes_the_configured_limit()
    {
        var directory = TempDirectory();

        try
        {
            var spiller = Spiller(42, directory);
            Assert.Equal(42, spiller.Threshold);
        }
        finally
        {
            DeleteDirectory(directory);
        }
    }

    private static QbResponseSpiller Spiller(int maxBytes, string spillPath) =>
        new(
            Options.Create(new QbXmlOptions { MaxResponseBytes = maxBytes, SpillPath = spillPath }),
            new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>()).Build());

    private static string TempDirectory() => Path.Combine(Path.GetTempPath(), "qbspill-" + Guid.NewGuid().ToString("N"));

    private static void DeleteDirectory(string path)
    {
        if (Directory.Exists(path))
        {
            Directory.Delete(path, recursive: true);
        }
    }
}

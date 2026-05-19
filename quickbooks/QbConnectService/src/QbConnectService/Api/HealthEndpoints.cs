using Microsoft.Extensions.Options;
using QbConnectService.Qb;
using QbConnectService.Qb.Ops;

namespace QbConnectService.Api;

public static class HealthEndpoints
{
    public static void MapHealthEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapGet("/health", async (
            QbConnectionManager manager,
            OpRegistry registry,
            IOptions<QbOptions> qb,
            IOptions<SafetyOptions> safety,
            IOptions<QbXmlOptions> qbXml,
            IOptions<RequestOptions> req,
            CancellationToken ct) =>
        {
            var probeSeconds = Math.Min(5, Math.Max(1, req.Value.TimeoutSeconds));
            using var cts = CancellationTokenSource.CreateLinkedTokenSource(ct);
            cts.CancelAfter(TimeSpan.FromSeconds(probeSeconds));

            IReadOnlyDictionary<string, object?>? companyInfo = null;
            string[] supportedVersions = [];
            string? quickBooksVersion = null;
            QbError? probeError = null;
            var probeBusy = false;

            try
            {
                if (!registry.TryGet("company_info", out var op))
                {
                    throw new InvalidOperationException("The company_info op is not registered.");
                }

                companyInfo = AssertDictionary(await op.RunAsync(new Dictionary<string, object?>(), cts.Token));
                supportedVersions = ExtractSupportedVersions(companyInfo);
                quickBooksVersion = BuildQuickBooksVersion(companyInfo);
            }
            catch (QbBusyException)
            {
                probeBusy = true;
            }
            catch (QbException exception)
            {
                probeError = exception.Error;
            }
            catch (QbTimeoutException)
            {
                probeError = new QbError(0, "QB_TIMEOUT", "Health probe timed out.", "QuickBooks slow or wedged.");
            }
            catch (OperationCanceledException)
            {
                probeError = new QbError(0, "QB_TIMEOUT", "Health probe timed out.", "QuickBooks slow or wedged.");
            }

            var lastError = probeError ?? manager.LastError;
            // status derives from probe OUTCOME (not from manager.State), because with
            // ReleaseAfterEachRequest=true the state is Disconnected immediately after
            // the probe — which is correct, not degraded.
            var probeOk = probeError is null && !probeBusy && companyInfo is not null;
            var status = probeError is not null || manager.State == QbConnectionState.Poisoned
                ? "down"
                : probeBusy || manager.LastError is not null || !probeOk
                    ? "degraded"
                    : "healthy";

            return Results.Ok(new
            {
                status,
                connectionState = manager.State.ToString(),
                lastProbe = probeOk ? "ok" : (probeBusy ? "busy" : "failed"),
                allowWrites = safety.Value.AllowWrites,
                releaseAfterEachRequest = qb.Value.ReleaseAfterEachRequest,
                sdkVersion = BestVersion(supportedVersions, qbXml.Value.Version),
                qbXmlVersionConfigured = qbXml.Value.Version,
                qbXmlVersionsSupported = supportedVersions,
                companyFile = qb.Value.CompanyFilePath,
                openMode = qb.Value.OpenMode.ToString(),
                openModeInt = (int)qb.Value.OpenMode,
                connectionType = qb.Value.ConnectionType.ToString(),
                connectionTypeInt = (int)qb.Value.ConnectionType,
                quickBooksVersion,
                lastError = lastError is null
                    ? null
                    : new
                    {
                        code = $"0x{lastError.Code:X8}",
                        name = lastError.Name,
                        message = lastError.Message,
                        remediationHint = lastError.RemediationHint,
                    },
                time = DateTimeOffset.UtcNow,
            });
        });
    }

    private static IReadOnlyDictionary<string, object?> AssertDictionary(object? value) =>
        value as IReadOnlyDictionary<string, object?>
        ?? throw new InvalidOperationException("company_info returned an unexpected payload.");

    private static string[] ExtractSupportedVersions(IReadOnlyDictionary<string, object?> companyInfo)
    {
        if (!companyInfo.TryGetValue("supportedQbXmlVersions", out var raw) || raw is null)
        {
            return [];
        }

        if (raw is IReadOnlyDictionary<string, object?> readOnlyDict &&
            readOnlyDict.TryGetValue("SupportedQBXMLVersion", out var nestedReadOnly))
        {
            return NormalizeStrings(nestedReadOnly);
        }

        if (raw is IDictionary<string, object?> dict &&
            dict.TryGetValue("SupportedQBXMLVersion", out var nested))
        {
            return NormalizeStrings(nested);
        }

        return NormalizeStrings(raw);
    }

    private static string[] NormalizeStrings(object? value) =>
        value switch
        {
            string text when !string.IsNullOrWhiteSpace(text) => [text],
            IEnumerable<object?> values => values.Select(v => v?.ToString()).Where(v => !string.IsNullOrWhiteSpace(v)).Cast<string>().ToArray(),
            _ => [],
        };

    private static string? BuildQuickBooksVersion(IReadOnlyDictionary<string, object?> companyInfo)
    {
        var edition = companyInfo.GetValueOrDefault("edition")?.ToString();
        var major = companyInfo.GetValueOrDefault("quickBooksMajorVersion")?.ToString();
        var minor = companyInfo.GetValueOrDefault("quickBooksMinorVersion")?.ToString();
        var version = string.IsNullOrWhiteSpace(major) ? null : string.IsNullOrWhiteSpace(minor) ? major : $"{major}.{minor}";

        return (edition, version) switch
        {
            ({ Length: > 0 } e, { Length: > 0 } v) => $"{e} {v}",
            ({ Length: > 0 } e, _) => e,
            (_, { Length: > 0 } v) => v,
            _ => null,
        };
    }

    private static string BestVersion(string[] supportedVersions, string configuredVersion)
    {
        static Version ParseOrZero(string version) =>
            Version.TryParse(version, out var parsed) ? parsed : new Version(0, 0);

        var best = supportedVersions
            .Where(version => !string.IsNullOrWhiteSpace(version))
            .OrderBy(ParseOrZero)
            .LastOrDefault();

        return string.IsNullOrWhiteSpace(best) ? configuredVersion : best;
    }
}

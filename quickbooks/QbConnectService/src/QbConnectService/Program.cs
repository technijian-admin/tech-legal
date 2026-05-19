using System.Net;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using QbConnectService;
using QbConnectService.Api;
using QbConnectService.Qb;
using QbConnectService.Qb.Ops;

if (args.Contains("--verify-audit", StringComparer.Ordinal))
{
    var verifyArgs = args.Where(arg => !string.Equals(arg, "--verify-audit", StringComparison.Ordinal)).ToArray();
    var configuration = Program.BuildVerifyAuditConfiguration(verifyArgs);
    Environment.ExitCode = await Program.RunVerifyAuditAsync(configuration);
    return;
}

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddWindowsService(options =>
{
    options.ServiceName = "QbConnectService";
});

builder.Services.AddHostedService<QbConnectService.Worker>();

builder.Services.Configure<QbOptions>(builder.Configuration.GetSection("Qb"));
builder.Services.Configure<QbXmlOptions>(builder.Configuration.GetSection("QbXml"));
builder.Services.Configure<RequestOptions>(builder.Configuration.GetSection("Request"));
builder.Services.Configure<ServerOptions>(builder.Configuration.GetSection("Server"));
builder.Services.Configure<AuthOptions>(builder.Configuration.GetSection("Auth"));
builder.Services.Configure<AuditAuthOptions>(builder.Configuration.GetSection("Auth"));
builder.Services.Configure<SafetyOptions>(builder.Configuration.GetSection("Safety"));
builder.Services.Configure<AuditOptions>(builder.Configuration.GetSection("Audit"));
builder.Services.AddProblemDetails();
builder.Services.AddExceptionHandler<ApiExceptionHandler>();
builder.Services.AddSingleton<QbXmlBuilder>();
builder.Services.AddSingleton<QbXmlParser>();
builder.Services.AddSingleton<QbReportParser>();
builder.Services.AddSingleton<QbResponseSpiller>();
builder.Services.AddSingleton<QbListExecutor>();
builder.Services.AddSingleton<AuditLog>();

builder.WebHost.ConfigureKestrel((ctx, kestrel) =>
{
    var server = ctx.Configuration.GetSection("Server").Get<ServerOptions>() ?? new ServerOptions();
    if (server.MaxRequestBodyBytes > 0)
    {
        kestrel.Limits.MaxRequestBodySize = server.MaxRequestBodyBytes;
    }

    foreach (var binding in ServerBinding.ParseHttpsOnly(server.BindUrls))
    {
        kestrel.Listen(binding.Address, binding.Port, listenOptions =>
        {
            if (!string.IsNullOrWhiteSpace(server.CertPath))
            {
                listenOptions.UseHttps(server.CertPath, server.CertPassword);
            }
            else
            {
                listenOptions.UseHttps();
            }
        });
    }

    // NOTE: WebApplicationFactory<Program> swaps Kestrel for TestServer, so these listeners do not run in
    // integration tests. The https-only validation is covered by KestrelHttpsOnlyTests via ServerBinding.
});

if (OperatingSystem.IsWindows() && !builder.Environment.IsEnvironment("Testing"))
{
    builder.Services.AddSingleton<Func<IRequestProcessor>>(_ => () => new QbConnectService.Qb.Com.RealRequestProcessor());
    builder.Services.AddSingleton<IQbProcessManager, WindowsQbProcessManager>();
}

builder.Services.AddSingleton<QbKillTracker>();
builder.Services.AddSingleton<QbConnectionManager>();

// Phase 4: read ops (registered as IReadOp so Phase 5's OpRegistry is IEnumerable<IReadOp> -> dictionary by Name)
builder.Services.AddSingleton<IReadOp, CompanyInfoOp>();
builder.Services.AddSingleton<IReadOp, CompanyPreferencesOp>();
builder.Services.AddSingleton<IReadOp, ReportOp>();
builder.Services.AddSingleton<IReadOp, ListCustomersOp>();
builder.Services.AddSingleton<IReadOp, ListVendorsOp>();
builder.Services.AddSingleton<IReadOp, ListAccountsOp>();
builder.Services.AddSingleton<IReadOp, ListItemsOp>();
builder.Services.AddSingleton<IReadOp, ListInvoicesOp>();
builder.Services.AddSingleton<IReadOp, ListBillsOp>();
builder.Services.AddSingleton<IReadOp, ListPaymentsOp>();
builder.Services.AddSingleton<IReadOp, GetTransactionOp>();
builder.Services.AddSingleton<IReadOp, RunQueryOp>();
builder.Services.AddSingleton<IReadOp, CreateCustomerOp>();
builder.Services.AddSingleton<IReadOp, CreateVendorOp>();
builder.Services.AddSingleton<IReadOp, CreateInvoiceOp>();
builder.Services.AddSingleton<IReadOp, CreateBillOp>();
builder.Services.AddSingleton<IReadOp, CreateCheckOp>();
builder.Services.AddSingleton<IReadOp, ReceivePaymentOp>();
builder.Services.AddSingleton<IReadOp, CreateJournalEntryOp>();
builder.Services.AddSingleton<IReadOp, ModOp>();
builder.Services.AddSingleton<OpRegistry>();

var app = builder.Build();

app.UseExceptionHandler();
app.UseMiddleware<BearerAuthMiddleware>();

app.MapGet("/", () => "QbConnectService is running.");
var api = app.MapGroup("/api");
api.MapHealthEndpoints();
api.MapOpsEndpoints();
api.MapQbXmlEndpoints();
api.MapConnectionEndpoints();

app.Run();

public partial class Program
{
    public static IConfiguration BuildVerifyAuditConfiguration(string[] args)
    {
        var builder = Host.CreateApplicationBuilder(args);
        return builder.Configuration;
    }

    public static async Task<int> RunVerifyAuditAsync(
        IConfiguration configuration,
        TextWriter? output = null,
        TextWriter? error = null,
        CancellationToken ct = default)
    {
        output ??= Console.Out;
        error ??= Console.Error;

        var services = new ServiceCollection();
        services.AddLogging();
        services.Configure<AuditOptions>(configuration.GetSection("Audit"));
        services.Configure<AuditAuthOptions>(configuration.GetSection("Auth"));
        services.AddSingleton<AuditLog>();

        await using var provider = services.BuildServiceProvider();
        var auditLog = provider.GetRequiredService<AuditLog>();
        var result = await auditLog.VerifyChainAsync(ct);

        if (result.Ok)
        {
            await output.WriteLineAsync("audit chain OK");
            return 0;
        }

        await error.WriteLineAsync($"audit chain BROKEN at seq {result.FirstBrokenSeq}");
        return 1;
    }
}

public static class ServerBinding
{
    public static void Validate(string bindUrls)
    {
        _ = ParseHttpsOnly(bindUrls);
    }

    public static IReadOnlyList<ServerListenBinding> ParseHttpsOnly(string bindUrls)
    {
        var urls = bindUrls.Split(';', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        var bindings = new List<ServerListenBinding>(urls.Length);

        foreach (var url in urls)
        {
            var uri = new Uri(url.Replace("+", "0.0.0.0", StringComparison.Ordinal)
                .Replace("*", "0.0.0.0", StringComparison.Ordinal));

            if (!string.Equals(uri.Scheme, Uri.UriSchemeHttps, StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidOperationException($"Server:BindUrls must be https only; got '{url}'.");
            }

            bindings.Add(new ServerListenBinding(ParseAddress(uri.Host), uri.Port, url));
        }

        return bindings;
    }

    private static IPAddress ParseAddress(string host) =>
        host switch
        {
            "0.0.0.0" => IPAddress.Any,
            "localhost" => IPAddress.Loopback,
            _ => IPAddress.Parse(host),
        };
}

public readonly record struct ServerListenBinding(IPAddress Address, int Port, string Url);

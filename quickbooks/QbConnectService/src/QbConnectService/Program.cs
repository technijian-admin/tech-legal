using System.Net;
using QbConnectService;
using QbConnectService.Api;
using QbConnectService.Qb;
using QbConnectService.Qb.Ops;

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
builder.Services.Configure<SafetyOptions>(builder.Configuration.GetSection("Safety"));
builder.Services.AddSingleton<QbXmlBuilder>();
builder.Services.AddSingleton<QbXmlParser>();
builder.Services.AddSingleton<QbReportParser>();
builder.Services.AddSingleton<QbResponseSpiller>();
builder.Services.AddSingleton<QbListExecutor>();

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
}

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

var app = builder.Build();

app.UseMiddleware<BearerAuthMiddleware>();

app.MapGet("/", () => "QbConnectService is running.");
app.MapGet("/api/ping", () => Results.Ok(new { ping = "pong" }));

app.Run();

public partial class Program
{
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

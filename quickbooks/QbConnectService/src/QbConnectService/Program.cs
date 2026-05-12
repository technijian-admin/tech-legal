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
builder.Services.AddSingleton<QbXmlBuilder>();
builder.Services.AddSingleton<QbXmlParser>();
builder.Services.AddSingleton<QbReportParser>();
builder.Services.AddSingleton<QbResponseSpiller>();
builder.Services.AddSingleton<QbListExecutor>();

if (OperatingSystem.IsWindows() && !builder.Environment.IsEnvironment("Testing"))
{
    builder.Services.AddSingleton<Func<IRequestProcessor>>(_ => () => new QbConnectService.Qb.Com.RealRequestProcessor());
}

builder.Services.AddSingleton<QbConnectionManager>();

// Phase 4: read ops (registered as IReadOp so Phase 5's OpRegistry is IEnumerable<IReadOp> -> dictionary by Name)
builder.Services.AddSingleton<IReadOp, CompanyInfoOp>();
builder.Services.AddSingleton<IReadOp, CompanyPreferencesOp>();
builder.Services.AddSingleton<IReadOp, ReportOp>();

var app = builder.Build();

app.MapGet("/", () => "QbConnectService (Phase 1 skeleton). REST API arrives in Phase 5.");

app.Run();

public partial class Program
{
}

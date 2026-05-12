using QbConnectService.Qb;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddWindowsService(options =>
{
    options.ServiceName = "QbConnectService";
});

builder.Services.AddHostedService<QbConnectService.Worker>();

builder.Services.Configure<QbOptions>(builder.Configuration.GetSection("Qb"));
builder.Services.Configure<QbXmlOptions>(builder.Configuration.GetSection("QbXml"));
builder.Services.Configure<RequestOptions>(builder.Configuration.GetSection("Request"));

if (OperatingSystem.IsWindows() && !builder.Environment.IsEnvironment("Testing"))
{
    builder.Services.AddSingleton<Func<IRequestProcessor>>(_ => () => new QbConnectService.Qb.Com.RealRequestProcessor());
}

builder.Services.AddSingleton<QbConnectionManager>();

var app = builder.Build();

app.MapGet("/", () => "QbConnectService (Phase 1 skeleton). REST API arrives in Phase 5.");

app.Run();

public partial class Program
{
}

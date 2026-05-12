using QbConnectService.Qb;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddWindowsService(options =>
{
    options.ServiceName = "QbConnectService";
});

builder.Services.AddHostedService<QbConnectService.Worker>();

builder.Services.Configure<QbOptions>(builder.Configuration.GetSection("Qb"));
builder.Services.Configure<RequestOptions>(builder.Configuration.GetSection("Request"));

var app = builder.Build();

app.MapGet("/", () => "QbConnectService (Phase 1 skeleton). REST API arrives in Phase 5.");

app.Run();

public partial class Program
{
}

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddWindowsService(options =>
{
    options.ServiceName = "QbConnectService";
});

builder.Services.AddHostedService<QbConnectService.Worker>();

// Phase 2 will register the real QbConnectionManager and, on Windows outside tests,
// the RealRequestProcessor implementation here.

var app = builder.Build();

app.MapGet("/", () => "QbConnectService (Phase 1 skeleton). REST API arrives in Phase 5.");

app.Run();

public partial class Program
{
}

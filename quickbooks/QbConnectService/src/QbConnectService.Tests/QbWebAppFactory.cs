using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using QbConnectService.Qb;
using QbConnectService.Qb.Ops;
using QbConnectService.Tests.Fakes;

namespace QbConnectService.Tests;

public class QbWebAppFactory : WebApplicationFactory<Program>
{
    public const string Token = "test-token";

    public bool AllowWrites { get; init; }

    public string AuditDir { get; } = Path.Combine(Path.GetTempPath(), "qbtest", Guid.NewGuid().ToString());

    public FakeRequestProcessor Fake { get; } = new();
    public FakeQbProcessManager FakeProcess { get; } = new();

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
        builder.UseSetting("Auth:ApiToken", Token);
        builder.UseSetting("Safety:AllowWrites", AllowWrites ? "true" : "false");
        builder.UseSetting("Audit:Path", AuditDir);
        builder.UseSetting("Qb:CompanyFilePath", @"C:\co.QBW");
        builder.UseSetting("Request:TimeoutSeconds", "30");
        builder.UseSetting("Request:BusyWaitSeconds", "5");
        builder.ConfigureServices(services =>
        {
            services.AddSingleton<Func<IRequestProcessor>>(_ => () => Fake);
            services.AddSingleton<IQbProcessManager>(_ => FakeProcess);
            services.AddSingleton<IReadOp, FakeWriteOp>();
        });
    }

    public override async ValueTask DisposeAsync()
    {
        await base.DisposeAsync();
        if (Directory.Exists(AuditDir))
        {
            Directory.Delete(AuditDir, recursive: true);
        }
    }

    public static string Fixture(string name) =>
        File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "Fixtures", "qbxml", name));
}

using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using QbConnectService.Qb;
using QbConnectService.Tests.Fakes;

namespace QbConnectService.Tests;

public sealed class QbWebAppFactory : WebApplicationFactory<Program>
{
    public const string Token = "test-token";

    public FakeRequestProcessor Fake { get; } = new();

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
        builder.UseSetting("Auth:ApiToken", Token);
        builder.UseSetting("Safety:AllowWrites", "false");
        builder.UseSetting("Qb:CompanyFilePath", @"C:\co.QBW");
        builder.UseSetting("Request:TimeoutSeconds", "30");
        builder.UseSetting("Request:BusyWaitSeconds", "5");
        builder.ConfigureServices(services =>
        {
            services.AddSingleton<Func<IRequestProcessor>>(_ => () => Fake);
        });
    }
}

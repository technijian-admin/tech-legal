using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using QbConnectService.Qb;
using QbConnectService.Tests.Fakes;

namespace QbConnectService.Tests;

public sealed class HostStartupTests
{
    private const string CompanyQueryRequest =
        "<?xml version=\"1.0\"?><?qbxml version=\"16.0\"?><QBXML><QBXMLMsgsRq onError=\"stopOnError\"><CompanyQueryRq/></QBXMLMsgsRq></QBXML>";

    [Fact]
    public async Task Generic_host_with_the_worker_starts_and_stops_cleanly()
    {
        using var host = Host.CreateDefaultBuilder()
            .ConfigureServices(services => services.AddHostedService<QbConnectService.Worker>())
            .Build();

        await host.StartAsync();

        var lifetime = host.Services.GetRequiredService<IHostApplicationLifetime>();
        Assert.False(lifetime.ApplicationStopping.IsCancellationRequested);

        await host.StopAsync(TimeSpan.FromSeconds(5));
    }

    [Fact]
    public async Task Host_resolves_QbConnectionManager_as_a_singleton_and_disposes_it_cleanly()
    {
        var created = new List<FakeRequestProcessor>();
        var host = Host.CreateDefaultBuilder()
            .ConfigureServices(services =>
            {
                services.AddHostedService<QbConnectService.Worker>();
                services.Configure<QbOptions>(options =>
                {
                    options.AppId = "app";
                    options.AppName = "QbConnectService";
                    options.CompanyFilePath = @"C:\co.QBW";
                });
                services.Configure<RequestOptions>(options =>
                {
                    options.TimeoutSeconds = 30;
                    options.BusyWaitSeconds = 5;
                });
                services.AddSingleton<Func<IRequestProcessor>>(_ => () =>
                {
                    var fake = new FakeRequestProcessor().AddResponse("CompanyQueryRq", "<company/>");
                    created.Add(fake);
                    return fake;
                });
                services.AddSingleton<QbConnectionManager>();
            })
            .Build();

        try
        {
            await host.StartAsync();

            var first = host.Services.GetRequiredService<QbConnectionManager>();
            var second = host.Services.GetRequiredService<QbConnectionManager>();

            Assert.Same(first, second);
            Assert.Equal("<company/>", await first.ExecuteAsync(CompanyQueryRequest));

            await host.StopAsync(TimeSpan.FromSeconds(5));
        }
        finally
        {
            host.Dispose();
        }

        Assert.Single(created);
        Assert.Equal(
            [nameof(IRequestProcessor.EndSession), nameof(IRequestProcessor.CloseConnection), nameof(IDisposable.Dispose)],
            created[0].CallLog[^3..]);
    }

    [Fact]
    public async Task Host_can_start_without_an_IRequestProcessor_factory_because_connection_is_lazy()
    {
        var host = Host.CreateDefaultBuilder()
            .ConfigureServices(services =>
            {
                services.Configure<QbOptions>(_ => { });
                services.Configure<RequestOptions>(_ => { });
                services.AddSingleton<QbConnectionManager>();
            })
            .Build();

        try
        {
            await host.StartAsync();
            await host.StopAsync(TimeSpan.FromSeconds(5));
        }
        finally
        {
            host.Dispose();
        }
    }
}

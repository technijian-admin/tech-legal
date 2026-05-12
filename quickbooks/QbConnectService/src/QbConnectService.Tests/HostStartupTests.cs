using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

namespace QbConnectService.Tests;

public sealed class HostStartupTests
{
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
}

namespace QbConnectService;

public sealed class Worker(ILogger<Worker> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        logger.LogInformation("QbConnectService worker started");

        try
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                logger.LogDebug("QbConnectService worker heartbeat");
                await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);
            }
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
        }
        finally
        {
            logger.LogInformation("QbConnectService worker stopping");
        }
    }
}

using System.Runtime.InteropServices;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace QbConnectService.Qb;

public sealed class QbConnectionManager : IAsyncDisposable
{
    private readonly Func<IRequestProcessor> _factory;
    private readonly QbOptions _qb;
    private readonly RequestOptions _req;
    private readonly ILogger<QbConnectionManager> _log;
    private readonly SemaphoreSlim _gate = new(1, 1);

    private StaThread _sta;
    private IRequestProcessor? _rp;
    private string? _ticket;
    private QbConnectionState _state = QbConnectionState.Disconnected;

    public QbConnectionManager(
        Func<IRequestProcessor> factory,
        IOptions<QbOptions> qb,
        IOptions<RequestOptions> req,
        ILogger<QbConnectionManager> log)
    {
        _factory = factory;
        _qb = qb.Value;
        _req = req.Value;
        _log = log;
        _sta = new StaThread("qb-com-sta");
    }

    public QbError? LastError { get; private set; }

    public QbConnectionState State => _state;

    public async Task<string> ExecuteAsync(string qbXmlRequest, CancellationToken ct = default)
    {
        if (!await _gate.WaitAsync(TimeSpan.FromSeconds(_req.BusyWaitSeconds), ct))
        {
            throw new QbBusyException(TimeSpan.FromSeconds(_req.BusyWaitSeconds));
        }

        try
        {
            await EnsureConnectedAsync();
            return await ProcessWithRetryAsync(qbXmlRequest);
        }
        catch (QbException exception)
        {
            LastError = exception.Error;
            LogMappedError(exception);
            throw;
        }
        finally
        {
            _gate.Release();
        }
    }

    public async Task<string[]> GetSupportedQbXmlVersionsAsync(CancellationToken ct = default)
    {
        if (!await _gate.WaitAsync(TimeSpan.FromSeconds(_req.BusyWaitSeconds), ct))
        {
            throw new QbBusyException(TimeSpan.FromSeconds(_req.BusyWaitSeconds));
        }

        try
        {
            await EnsureConnectedAsync();
            return await _sta
                .Run(() => _rp!.GetSupportedQbXmlVersions(_ticket!))
                .WaitAsync(TimeSpan.FromSeconds(_req.TimeoutSeconds));
        }
        catch (COMException ex)
        {
            var exception = QbException.From(ex);
            LastError = exception.Error;
            LogMappedError(exception);
            throw exception;
        }
        catch (QbException exception)
        {
            LastError = exception.Error;
            LogMappedError(exception);
            throw;
        }
        finally
        {
            _gate.Release();
        }
    }

    public async ValueTask DisposeAsync()
    {
        var gateHeld = false;

        try
        {
            gateHeld = await _gate.WaitAsync(TimeSpan.FromSeconds(5));
        }
        catch
        {
        }

        try
        {
            if (_rp is not null)
            {
                await _sta.Run(() =>
                {
                    try
                    {
                        _rp.EndSession(_ticket!);
                    }
                    catch
                    {
                    }

                    try
                    {
                        _rp.CloseConnection();
                    }
                    catch
                    {
                    }

                    _rp.Dispose();
                });

                _rp = null;
                _ticket = null;
                _state = QbConnectionState.Disconnected;
                _log.LogInformation("Closed the QuickBooks session.");
            }
        }
        catch
        {
        }
        finally
        {
            _sta.Dispose();
            if (gateHeld)
            {
                _gate.Release();
            }

            _gate.Dispose();
        }
    }

    private async Task EnsureConnectedAsync()
    {
        if (_state == QbConnectionState.SessionOpen && _rp is not null)
        {
            return;
        }

        await ConnectAsync();
    }

    private async Task ConnectAsync()
    {
        _state = QbConnectionState.Connecting;
        LastError = null;

        try
        {
            if (_qb.ConnectionType != QbConnectionType.LocalQBD)
            {
                _log.LogWarning(
                    "Ignoring configured QuickBooks connection type {ConnectionType}; forcing LocalQBD.",
                    _qb.ConnectionType);
            }

            if (_qb.OpenMode == QbFileMode.SingleUser)
            {
                _log.LogWarning("Ignoring configured QuickBooks open mode SingleUser; forcing DoNotCare.");
            }

            await OpenFreshConnectionAsync();

            _state = QbConnectionState.SessionOpen;
            _log.LogInformation("Opened the QuickBooks connection and session.");
        }
        catch (COMException ex)
        {
            var exception = QbException.From(ex);
            LastError = exception.Error;
            _state = QbConnectionState.Disconnected;
            throw exception;
        }
        catch (QbException exception)
        {
            LastError = exception.Error;
            _state = QbConnectionState.Disconnected;
            throw;
        }
        catch
        {
            _state = QbConnectionState.Disconnected;
            throw;
        }
    }

    private async Task<string> ProcessWithRetryAsync(string qbXmlRequest)
    {
        try
        {
            return await _sta
                .Run(() => _rp!.ProcessRequest(_ticket!, qbXmlRequest))
                .WaitAsync(TimeSpan.FromSeconds(_req.TimeoutSeconds));
        }
        catch (TimeoutException)
        {
            throw;
        }
        catch (COMException ex) when (QbErrors.IsDeadTicket(ex.HResult))
        {
            _log.LogInformation(
                "Dead ticket 0x{Hresult:X8}; rebuilding the QuickBooks connection and retrying once.",
                ex.HResult);

            await RebuildConnectionAsync();

            try
            {
                return await _sta
                    .Run(() => _rp!.ProcessRequest(_ticket!, qbXmlRequest))
                    .WaitAsync(TimeSpan.FromSeconds(_req.TimeoutSeconds));
            }
            catch (TimeoutException)
            {
                throw;
            }
            catch (COMException retryException)
            {
                throw QbException.From(retryException);
            }
        }
        catch (COMException ex)
        {
            throw QbException.From(ex);
        }
    }

    private async Task RebuildConnectionAsync()
    {
        await DisposeCurrentConnectionAsync();
        _rp = null;
        _ticket = null;
        _state = QbConnectionState.Disconnected;

        await ConnectAsync();
    }

    private Task OpenFreshConnectionAsync() =>
        _sta.Run(() =>
        {
            _rp = _factory();
            _rp.SetUnattendedModePreference(true);
            _rp.OpenConnection(_qb.AppId, _qb.AppName, QbConnectionType.LocalQBD);
            _ticket = _rp.BeginSession(_qb.CompanyFilePath, QbFileMode.DoNotCare);
        });

    private Task DisposeCurrentConnectionAsync() =>
        _sta.Run(() =>
        {
            try
            {
                _rp?.EndSession(_ticket!);
            }
            catch
            {
            }

            try
            {
                _rp?.CloseConnection();
            }
            catch
            {
            }

            try
            {
                _rp?.Dispose();
            }
            catch
            {
            }
        });

    private void LogMappedError(QbException exception)
    {
        _log.LogError(
            exception,
            "{ErrorName} (0x{Code:X8}): {Message} Remediation: {Hint}",
            exception.Error.Name,
            exception.Error.Code,
            exception.Error.Message,
            exception.Error.RemediationHint);
    }
}

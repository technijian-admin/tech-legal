using System.Runtime.InteropServices;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace QbConnectService.Qb;

public sealed class QbConnectionManager : IAsyncDisposable
{
    private readonly Func<IRequestProcessor> _factory;
    private readonly QbOptions _qb;
    private readonly RequestOptions _req;
    private readonly SafetyOptions _safety;
    private readonly ILogger<QbConnectionManager> _log;
    private readonly SemaphoreSlim _gate = new(1, 1);

    private StaThread _sta;
    private IRequestProcessor? _rp;
    private string? _ticket;
    private QbConnectionState _state = QbConnectionState.Disconnected;
    private string? _currentCompanyKey;

    public QbConnectionManager(
        Func<IRequestProcessor> factory,
        IOptions<QbOptions> qb,
        IOptions<RequestOptions> req,
        ILogger<QbConnectionManager> log,
        IOptions<SafetyOptions> safety)
    {
        _factory = factory;
        _qb = qb.Value;
        _req = req.Value;
        _safety = safety.Value;
        _log = log;
        _sta = new StaThread("qb-com-sta");
    }

    public QbError? LastError { get; private set; }

    public QbConnectionState State => _state;

    /// <summary>Currently open company key, or null if no session is open. Useful for tests and diagnostics.</summary>
    public string? CurrentCompanyKey => _currentCompanyKey;

    public async Task<string> ExecuteAsync(string qbXmlRequest, CancellationToken ct = default)
    {
        if (!_safety.AllowWrites && QbWriteDetector.IsWriteRequest(qbXmlRequest))
        {
            throw new QbWriteForbiddenException("Refused write qbXML: Safety:AllowWrites is false.");
        }

        var (requestedKey, company) = _qb.ResolveCompany(QbCompanyContext.Current);

        if (!await _gate.WaitAsync(TimeSpan.FromSeconds(_req.BusyWaitSeconds), ct))
        {
            throw new QbBusyException(TimeSpan.FromSeconds(_req.BusyWaitSeconds));
        }

        try
        {
            await EnsureConnectedForAsync(requestedKey, company);
            return await ProcessWithRetryAsync(qbXmlRequest, requestedKey, company);
        }
        catch (QbException exception)
        {
            LastError = exception.Error;
            LogMappedError(exception);
            throw;
        }
        finally
        {
            if (_qb.ReleaseAfterEachRequest)
            {
                await ReleaseInternalAsync();
            }
            _gate.Release();
        }
    }

    public async Task<string[]> GetSupportedQbXmlVersionsAsync(CancellationToken ct = default)
    {
        var (requestedKey, company) = _qb.ResolveCompany(QbCompanyContext.Current);

        if (!await _gate.WaitAsync(TimeSpan.FromSeconds(_req.BusyWaitSeconds), ct))
        {
            throw new QbBusyException(TimeSpan.FromSeconds(_req.BusyWaitSeconds));
        }

        try
        {
            await EnsureConnectedForAsync(requestedKey, company);
            return await _sta
                .Run(() => _rp!.GetSupportedQbXmlVersions(_ticket!))
                .WaitAsync(TimeSpan.FromSeconds(_req.TimeoutSeconds));
        }
        catch (TimeoutException)
        {
            Poison();
            throw new QbTimeoutException(TimeSpan.FromSeconds(_req.TimeoutSeconds));
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
            if (_qb.ReleaseAfterEachRequest)
            {
                await ReleaseInternalAsync();
            }
            _gate.Release();
        }
    }

    /// <summary>
    /// Explicit release endpoint — drops any open SDK session so the .qbw file is freed in
    /// QB Desktop. Idempotent (no-op if no session is open). Acquires the gate so it serializes
    /// safely against in-flight ExecuteAsync calls.
    /// </summary>
    public async Task ReleaseAsync(CancellationToken ct = default)
    {
        if (!await _gate.WaitAsync(TimeSpan.FromSeconds(_req.BusyWaitSeconds), ct))
        {
            throw new QbBusyException(TimeSpan.FromSeconds(_req.BusyWaitSeconds));
        }

        try
        {
            await ReleaseInternalAsync();
        }
        finally
        {
            _gate.Release();
        }
    }

    /// <summary>
    /// Gate-free release. Caller MUST hold _gate. Swallows COM errors so a release failure
    /// never leaks out of a finally block.
    /// </summary>
    private async Task ReleaseInternalAsync()
    {
        if (_rp is null)
        {
            return;
        }

        try
        {
            await DisposeCurrentConnectionAsync();
        }
        catch
        {
            // Cleanup is best-effort; the next ConnectAsync rebuilds anyway.
        }

        _rp = null;
        _ticket = null;
        _currentCompanyKey = null;
        _state = QbConnectionState.Disconnected;
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
                _currentCompanyKey = null;
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

    private async Task EnsureConnectedForAsync(string requestedKey, QbCompany company)
    {
        if (_state == QbConnectionState.SessionOpen
            && _rp is not null
            && string.Equals(_currentCompanyKey, requestedKey, StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        if (_state == QbConnectionState.SessionOpen && _rp is not null)
        {
            // Active session is for a DIFFERENT company. Close it before opening the new one.
            _log.LogInformation(
                "Switching QuickBooks session from company '{From}' to '{To}'.",
                _currentCompanyKey ?? "(unknown)",
                requestedKey);
            await DisposeCurrentConnectionAsync();
            _rp = null;
            _ticket = null;
            _currentCompanyKey = null;
            _state = QbConnectionState.Disconnected;
        }

        await ConnectAsync(requestedKey, company);
    }

    private async Task ConnectAsync(string requestedKey, QbCompany company)
    {
        _state = QbConnectionState.Connecting;
        LastError = null;

        try
        {
            await OpenFreshConnectionAsync(company);

            _currentCompanyKey = requestedKey;
            _state = QbConnectionState.SessionOpen;
            _log.LogInformation("Opened QuickBooks connection + session for company '{Key}'.", requestedKey);
        }
        catch (COMException ex)
        {
            await CleanupPartialConnectionAsync();
            var exception = QbException.From(ex);
            LastError = exception.Error;
            _state = QbConnectionState.Disconnected;
            throw exception;
        }
        catch (QbException exception)
        {
            await CleanupPartialConnectionAsync();
            LastError = exception.Error;
            _state = QbConnectionState.Disconnected;
            throw;
        }
        catch
        {
            await CleanupPartialConnectionAsync();
            _state = QbConnectionState.Disconnected;
            throw;
        }
    }

    /// <summary>
    /// If a partially-constructed _rp is left over from a failed ConnectAsync (e.g. OpenConnection succeeded
    /// but BeginSession threw), tear it down before the caller retries. Without this, the next ConnectAsync
    /// would overwrite _rp via OpenFreshConnectionAsync, leaking the previous COM ref.
    /// </summary>
    private async Task CleanupPartialConnectionAsync()
    {
        if (_rp is null)
        {
            return;
        }
        try
        {
            await DisposeCurrentConnectionAsync();
        }
        catch
        {
        }
        _rp = null;
        _ticket = null;
        _currentCompanyKey = null;
    }

    private async Task<string> ProcessWithRetryAsync(string qbXmlRequest, string requestedKey, QbCompany company)
    {
        try
        {
            return await _sta
                .Run(() => _rp!.ProcessRequest(_ticket!, qbXmlRequest))
                .WaitAsync(TimeSpan.FromSeconds(_req.TimeoutSeconds));
        }
        catch (TimeoutException)
        {
            Poison();
            throw new QbTimeoutException(TimeSpan.FromSeconds(_req.TimeoutSeconds));
        }
        catch (COMException ex) when (QbErrors.IsDeadTicket(ex.HResult))
        {
            _log.LogInformation(
                "Dead ticket 0x{Hresult:X8}; rebuilding the QuickBooks connection and retrying once.",
                ex.HResult);

            await RebuildConnectionAsync(requestedKey, company);

            try
            {
                return await _sta
                    .Run(() => _rp!.ProcessRequest(_ticket!, qbXmlRequest))
                    .WaitAsync(TimeSpan.FromSeconds(_req.TimeoutSeconds));
            }
            catch (TimeoutException)
            {
                Poison();
                throw new QbTimeoutException(TimeSpan.FromSeconds(_req.TimeoutSeconds));
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

    private async Task RebuildConnectionAsync(string requestedKey, QbCompany company)
    {
        await DisposeCurrentConnectionAsync();
        _rp = null;
        _ticket = null;
        _currentCompanyKey = null;
        _state = QbConnectionState.Disconnected;

        await ConnectAsync(requestedKey, company);
    }

    private Task OpenFreshConnectionAsync(QbCompany company) =>
        _sta.Run(() =>
        {
            _rp = _factory();
            _rp.SetUnattendedModePreference(true);
            _rp.OpenConnection(company.AppId, company.AppName, _qb.ConnectionType);
            _ticket = _rp.BeginSession(company.CompanyFilePath, _qb.OpenMode);
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

    private void Poison()
    {
        _state = QbConnectionState.Poisoned;
        _log.LogWarning(
            "QuickBooks request exceeded {TimeoutSeconds}s; poisoning the session — it will be rebuilt on the next request.",
            _req.TimeoutSeconds);

        var old = _sta;
        _sta = new StaThread("qb-com-sta");

        try
        {
            old.Dispose();
        }
        catch
        {
        }

        _rp = null;
        _ticket = null;
        _currentCompanyKey = null;
    }

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

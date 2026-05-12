using System.Runtime.InteropServices;
using System.Runtime.Versioning;
using QbConnectService.Qb;
using QbConnectService.Qb.Com.Interop;

namespace QbConnectService.Qb.Com;

[SupportedOSPlatform("windows")]
public sealed class RealRequestProcessor : IRequestProcessor
{
    private IRequestProcessor2? _rp;

    public RealRequestProcessor()
    {
        try
        {
            _rp = (IRequestProcessor2)new RequestProcessor2();
        }
        catch (COMException ex)
        {
            throw new QbException(QbErrors.Lookup(ex.HResult), ex);
        }
        catch (InvalidCastException ex)
        {
            throw new QbException(QbErrors.CastFailure(ex.Message), ex);
        }
    }

    public void OpenConnection(string appId, string appName, QbConnectionType connectionType)
    {
        _rp!.OpenConnection2(appId, appName, (int)connectionType);
    }

    public string BeginSession(string companyFilePath, QbFileMode openMode)
    {
        return _rp!.BeginSession(companyFilePath, (int)openMode);
    }

    public string ProcessRequest(string ticket, string qbXmlRequest)
    {
        return _rp!.ProcessRequest(ticket, qbXmlRequest);
    }

    public string[] GetSupportedQbXmlVersions(string ticket)
    {
        return _rp!.QBXMLVersionsForSession(ticket);
    }

    public void EndSession(string ticket)
    {
        _rp!.EndSession(ticket);
    }

    public void CloseConnection()
    {
        _rp!.CloseConnection();
    }

    public void SetUnattendedModePreference(bool required)
    {
        _rp!.AuthPreferences().PutUnattendedModePref(required);
    }

    public void Dispose()
    {
        if (_rp is not null)
        {
            Marshal.FinalReleaseComObject(_rp);
            _rp = null;
        }
    }
}

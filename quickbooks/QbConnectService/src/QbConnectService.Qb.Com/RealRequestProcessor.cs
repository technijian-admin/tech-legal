using System.Runtime.Versioning;
using QbConnectService.Qb;

namespace QbConnectService.Qb.Com;

[SupportedOSPlatform("windows")]
public sealed class RealRequestProcessor : IRequestProcessor
{
    private const string NotYet =
        "RealRequestProcessor is implemented in Phase 2. Phase 1 intentionally ships a throwing stub so the solution builds with no QuickBooks SDK installed.";

    public void OpenConnection(string appId, string appName, QbConnectionType connectionType)
    {
        throw new NotImplementedException(NotYet);
    }

    public string BeginSession(string companyFilePath, QbFileMode openMode)
    {
        throw new NotImplementedException(NotYet);
    }

    public string ProcessRequest(string ticket, string qbXmlRequest)
    {
        throw new NotImplementedException(NotYet);
    }

    public string[] GetSupportedQbXmlVersions(string ticket)
    {
        throw new NotImplementedException(NotYet);
    }

    public void EndSession(string ticket)
    {
        throw new NotImplementedException(NotYet);
    }

    public void CloseConnection()
    {
        throw new NotImplementedException(NotYet);
    }

    public void SetUnattendedModePreference(bool required)
    {
        throw new NotImplementedException(NotYet);
    }

    public void Dispose()
    {
    }
}

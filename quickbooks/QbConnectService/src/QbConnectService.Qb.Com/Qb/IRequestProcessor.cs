namespace QbConnectService.Qb;

/// <summary>Connection type passed to OpenConnection2. Mirrors QBXMLRPConnectionType.</summary>
public enum QbConnectionType
{
    Unknown = 0,
    LocalQBD = 1,
    LocalQBDLaunchUI = 2,
    RemoteQBD = 3,
    RemoteQBOE = 4,
}

/// <summary>File open mode passed to BeginSession. Mirrors QBFileMode.</summary>
public enum QbFileMode
{
    DoNotCare = 0,
    SingleUser = 1,
    MultiUser = 2,
}

/// <summary>
/// Thin, mockable seam over QBXMLRP2.RequestProcessor. NO COM types in this surface so the host and test
/// assemblies build with no QuickBooks SDK installed. The only implementation that touches COM is
/// QbConnectService.Qb.Com.RealRequestProcessor; FakeRequestProcessor in tests is a plain object.
/// </summary>
public interface IRequestProcessor : IDisposable
{
    /// <summary>OpenConnection2(appId, appName, connectionType).</summary>
    void OpenConnection(string appId, string appName, QbConnectionType connectionType);

    /// <summary>BeginSession(companyFilePath, openMode) and return the session ticket.</summary>
    string BeginSession(string companyFilePath, QbFileMode openMode);

    /// <summary>ProcessRequest(ticket, qbXmlRequest) and return the raw qbXML response string.</summary>
    string ProcessRequest(string ticket, string qbXmlRequest);

    /// <summary>QBXMLVersionsForSession(ticket) and return the qbXML spec versions this session accepts.</summary>
    string[] GetSupportedQbXmlVersions(string ticket);

    /// <summary>EndSession(ticket).</summary>
    void EndSession(string ticket);

    /// <summary>CloseConnection().</summary>
    void CloseConnection();

    /// <summary>Wrap PutUnattendedModePref in the real implementation; no-op in the fake.</summary>
    void SetUnattendedModePreference(bool required);
}

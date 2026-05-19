namespace QbConnectService.Qb;

/// <summary>
/// Connection type passed to OpenConnection2. Mirrors the QBXMLRPConnectionTypeE COM enum
/// (NOT the often-cited C header order, which is wrong). Verified against the IDL shipped
/// in C:\Program Files\Intuit\IDN\QBSDK16.0\tools\access\QBXMLRP2e\sources\qbXMLRP2e.idl.
/// </summary>
public enum QbConnectionType
{
    Unknown = 0,
    LocalQBD = 1,
    RemoteQBD = 2,
    LocalQBDLaunchUI = 3,
    RemoteQBOE = 4,
}

/// <summary>
/// File open mode passed to BeginSession. Mirrors the QBFileModeE COM enum (NOT the
/// `qbFileOpenDoNotCare=0, SingleUser=1, MultiUser=2` order commonly published in old C
/// headers — that ordering does NOT match the actual COM type library and silently
/// downgrades MultiUser requests to DoNotCare). Verified against the IDL shipped in
/// C:\Program Files\Intuit\IDN\QBSDK16.0\tools\access\QBXMLRP2e\sources\qbXMLRP2e.idl.
/// </summary>
public enum QbFileMode
{
    SingleUser = 0,
    MultiUser = 1,
    DoNotCare = 2,
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

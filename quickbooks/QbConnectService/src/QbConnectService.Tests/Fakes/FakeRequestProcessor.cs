using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using System.Xml.Linq;
using QbConnectService.Qb;

namespace QbConnectService.Tests.Fakes;

public sealed class FakeRequestProcessor : IRequestProcessor
{
    private readonly Dictionary<string, string> _responses = new(StringComparer.OrdinalIgnoreCase);
    private readonly Queue<Exception> _errors = new();

    public List<string> CallLog { get; } = new();

    public string[] SupportedQbXmlVersions { get; set; } = ["13.0", "16.0"];

    public bool UnattendedModePreference { get; private set; }

    public string? LastAppId { get; private set; }

    public string? LastAppName { get; private set; }

    public QbConnectionType? LastConnectionType { get; private set; }

    public string? LastCompanyFilePath { get; private set; }

    public QbFileMode? LastOpenMode { get; private set; }

    public Func<string, string>? ProcessRequestHook { get; set; }

    public FakeRequestProcessor AddResponse(string requestElementName, string qbXmlResponse)
    {
        _responses[requestElementName] = qbXmlResponse;
        return this;
    }

    public FakeRequestProcessor EnqueueError(Exception ex)
    {
        _errors.Enqueue(ex);
        return this;
    }

    public FakeRequestProcessor EnqueueComError(int hresult, string? message = null)
    {
        _errors.Enqueue(new COMException(message ?? "Scripted COM error.", hresult));
        return this;
    }

    public void ThrowIfScripted([CallerMemberName] string caller = "")
    {
        CallLog.Add(caller);
        if (_errors.Count > 0)
        {
            throw _errors.Dequeue();
        }
    }

    public void OpenConnection(string appId, string appName, QbConnectionType connectionType)
    {
        ThrowIfScripted();
        LastAppId = appId;
        LastAppName = appName;
        LastConnectionType = connectionType;
    }

    public string BeginSession(string companyFilePath, QbFileMode openMode)
    {
        ThrowIfScripted();
        LastCompanyFilePath = companyFilePath;
        LastOpenMode = openMode;
        return "FAKE-TICKET-0001";
    }

    public string ProcessRequest(string ticket, string qbXmlRequest)
    {
        ThrowIfScripted();

        if (ProcessRequestHook is not null)
        {
            return ProcessRequestHook(qbXmlRequest);
        }

        var document = XDocument.Parse(qbXmlRequest);
        var rqName = document.Root?
            .Element("QBXMLMsgsRq")?
            .Elements()
            .FirstOrDefault()?
            .Name.LocalName
            ?? document.Descendants().FirstOrDefault(element => element.Name.LocalName.EndsWith("Rq", StringComparison.Ordinal))?.Name.LocalName;

        if (rqName is not null && _responses.TryGetValue(rqName, out var response))
        {
            return response;
        }

        if (_responses.TryGetValue("*", out var fallback))
        {
            return fallback;
        }

        throw new InvalidOperationException(
            $"FakeRequestProcessor: no canned response for request '{rqName ?? "<unparsed>"}'. Call AddResponse(...).");
    }

    public string[] GetSupportedQbXmlVersions(string ticket)
    {
        ThrowIfScripted();
        return SupportedQbXmlVersions;
    }

    public void EndSession(string ticket)
    {
        ThrowIfScripted();
    }

    public void CloseConnection()
    {
        ThrowIfScripted();
    }

    public void SetUnattendedModePreference(bool required)
    {
        ThrowIfScripted();
        UnattendedModePreference = required;
    }

    public void Dispose()
    {
        CallLog.Add(nameof(Dispose));
    }
}

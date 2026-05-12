using System.Runtime.InteropServices;
using QbConnectService.Qb;
using QbConnectService.Tests.Fakes;

namespace QbConnectService.Tests;

public sealed class FakeRequestProcessorTests
{
    [Fact]
    public void Lifecycle_calls_do_not_throw_and_BeginSession_returns_a_ticket()
    {
        IRequestProcessor requestProcessor = new FakeRequestProcessor();

        requestProcessor.OpenConnection("app-id", "QbConnectService", QbConnectionType.LocalQBD);
        var ticket = requestProcessor.BeginSession(string.Empty, QbFileMode.DoNotCare);
        var versions = requestProcessor.GetSupportedQbXmlVersions(ticket);
        requestProcessor.EndSession(ticket);
        requestProcessor.CloseConnection();
        requestProcessor.Dispose();

        Assert.False(string.IsNullOrWhiteSpace(ticket));
        Assert.Contains("13.0", versions);
    }

    [Fact]
    public void Canned_response_is_returned_keyed_by_request_element_name()
    {
        var fake = new FakeRequestProcessor()
            .AddResponse(
                "CompanyQueryRq",
                "<?xml version=\"1.0\"?><QBXML><QBXMLMsgsRs><CompanyQueryRs statusCode=\"0\" statusSeverity=\"Info\" statusMessage=\"OK\"><CompanyRet><CompanyName>Acme</CompanyName></CompanyRet></CompanyQueryRs></QBXMLMsgsRs></QBXML>");

        var ticket = fake.BeginSession(string.Empty, QbFileMode.DoNotCare);
        var response = fake.ProcessRequest(
            ticket,
            "<?qbxml version=\"13.0\"?><QBXML><QBXMLMsgsRq onError=\"stopOnError\"><CompanyQueryRq/></QBXMLMsgsRq></QBXML>");

        Assert.Contains("Acme", response);
    }

    [Fact]
    public void Scripted_COM_error_is_thrown_then_drained()
    {
        var fake = new FakeRequestProcessor().EnqueueComError(unchecked((int)0x8004040D), "invalid ticket");

        var exception = Assert.Throws<COMException>(() => fake.BeginSession(string.Empty, QbFileMode.DoNotCare));
        Assert.Equal(unchecked((int)0x8004040D), exception.HResult);

        var ticket = fake.BeginSession(string.Empty, QbFileMode.DoNotCare);
        Assert.False(string.IsNullOrWhiteSpace(ticket));
    }

    [Fact]
    public void Unscripted_request_throws_a_helpful_error()
    {
        var fake = new FakeRequestProcessor();
        var ticket = fake.BeginSession(string.Empty, QbFileMode.DoNotCare);

        Assert.Throws<InvalidOperationException>(() =>
            fake.ProcessRequest(
                ticket,
                "<?qbxml version=\"13.0\"?><QBXML><QBXMLMsgsRq><CustomerAddRq/></QBXMLMsgsRq></QBXML>"));
    }
}

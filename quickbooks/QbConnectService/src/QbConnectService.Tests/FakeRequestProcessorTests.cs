using System.Runtime.InteropServices;
using QbConnectService.Qb;
using QbConnectService.Tests.Fakes;

namespace QbConnectService.Tests;

public sealed class FakeRequestProcessorTests
{
    private const string CustomerQueryRequest =
        "<?xml version=\"1.0\"?><QBXML><QBXMLMsgsRq onError=\"stopOnError\"><CustomerQueryRq/></QBXMLMsgsRq></QBXML>";

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

    [Fact]
    public void Response_queue_dequeues_in_order_then_falls_back_to_the_single_response()
    {
        var fake = new FakeRequestProcessor()
            .AddResponse("CustomerQueryRq", "<single/>")
            .AddResponses("CustomerQueryRq", "<page1/>", "<page2/>");

        var ticket = fake.BeginSession(string.Empty, QbFileMode.DoNotCare);

        var first = fake.ProcessRequest(ticket, CustomerQueryRequest);
        var second = fake.ProcessRequest(ticket, CustomerQueryRequest);
        var third = fake.ProcessRequest(ticket, CustomerQueryRequest);

        Assert.Equal("<page1/>", first);
        Assert.Equal("<page2/>", second);
        Assert.Equal("<single/>", third);
    }

    [Fact]
    public void ProcessRequests_captures_each_raw_request()
    {
        var fake = new FakeRequestProcessor()
            .AddResponse("CustomerQueryRq", "<single/>")
            .AddResponses("CustomerQueryRq", "<page1/>", "<page2/>");
        var ticket = fake.BeginSession(string.Empty, QbFileMode.DoNotCare);

        fake.ProcessRequest(ticket, CustomerQueryRequest);
        fake.ProcessRequest(ticket, CustomerQueryRequest);
        fake.ProcessRequest(ticket, CustomerQueryRequest);

        Assert.Equal(3, fake.ProcessRequests.Count);
        Assert.All(fake.ProcessRequests, request => Assert.Contains("CustomerQueryRq", request));
    }

    [Fact]
    public void ProcessRequest_hook_still_wins_and_is_captured()
    {
        var fake = new FakeRequestProcessor
        {
            ProcessRequestHook = _ => "<hooked/>",
        };
        var ticket = fake.BeginSession(string.Empty, QbFileMode.DoNotCare);

        var response = fake.ProcessRequest(ticket, CustomerQueryRequest);

        Assert.Equal("<hooked/>", response);
        Assert.Single(fake.ProcessRequests);
        Assert.Contains("CustomerQueryRq", fake.ProcessRequests[0]);
    }

    [Fact]
    public void Single_response_behavior_and_unscripted_errors_remain_unchanged()
    {
        var fake = new FakeRequestProcessor().AddResponse("CompanyQueryRq", "<co/>");
        var ticket = fake.BeginSession(string.Empty, QbFileMode.DoNotCare);

        var response = fake.ProcessRequest(
            ticket,
            "<?xml version=\"1.0\"?><QBXML><QBXMLMsgsRq onError=\"stopOnError\"><CompanyQueryRq/></QBXMLMsgsRq></QBXML>");

        Assert.Equal("<co/>", response);
        Assert.Throws<InvalidOperationException>(() => fake.ProcessRequest(ticket, CustomerQueryRequest));
    }
}

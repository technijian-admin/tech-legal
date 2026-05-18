using System.Net;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using QbConnectService.Qb;
using QbConnectService.Qb.Ops;
using QbConnectService.Tests.Fakes;

namespace QbConnectService.Tests;

public sealed class QbMultiTenantTests
{
    [Fact]
    public void ResolveCompany_named_key_in_dict_returns_that_company()
    {
        var qb = new QbOptions
        {
            Companies =
            {
                ["co-a"] = new QbCompany { CompanyFilePath = @"D:\a.qbw", AppId = "a", AppName = "App A" },
                ["co-b"] = new QbCompany { CompanyFilePath = @"D:\b.qbw", AppId = "b", AppName = "App B" },
            },
        };

        var (key, company) = qb.ResolveCompany("co-b");

        Assert.Equal("co-b", key);
        Assert.Equal(@"D:\b.qbw", company.CompanyFilePath);
        Assert.Equal("b", company.AppId);
    }

    [Fact]
    public void ResolveCompany_null_key_uses_DefaultCompany_when_set()
    {
        var qb = new QbOptions
        {
            DefaultCompany = "co-a",
            Companies =
            {
                ["co-a"] = new QbCompany { CompanyFilePath = @"D:\a.qbw", AppId = "a", AppName = "App A" },
                ["co-b"] = new QbCompany { CompanyFilePath = @"D:\b.qbw", AppId = "b", AppName = "App B" },
            },
        };

        var (key, company) = qb.ResolveCompany(null);

        Assert.Equal("co-a", key);
        Assert.Equal(@"D:\a.qbw", company.CompanyFilePath);
    }

    [Fact]
    public void ResolveCompany_null_key_and_no_DefaultCompany_falls_back_to_legacy_fields()
    {
        var qb = new QbOptions
        {
            CompanyFilePath = @"C:\legacy.qbw",
            AppId = "legacy",
            AppName = "LegacyApp",
        };

        var (key, company) = qb.ResolveCompany(null);

        Assert.Equal("default", key);
        Assert.Equal(@"C:\legacy.qbw", company.CompanyFilePath);
        Assert.Equal("legacy", company.AppId);
        Assert.Equal("LegacyApp", company.AppName);
    }

    [Fact]
    public void ResolveCompany_unknown_key_throws_ArgumentException()
    {
        var qb = new QbOptions
        {
            Companies =
            {
                ["co-a"] = new QbCompany { CompanyFilePath = @"D:\a.qbw", AppId = "a", AppName = "App A" },
            },
        };

        var ex = Assert.Throws<ArgumentException>(() => qb.ResolveCompany("not-there"));
        Assert.Contains("not-there", ex.Message, StringComparison.Ordinal);
        Assert.Contains("co-a", ex.Message, StringComparison.Ordinal);
    }

    [Fact]
    public async Task Manager_switches_session_when_company_context_changes()
    {
        var created = new List<FakeRequestProcessor>();
        IRequestProcessor Factory()
        {
            var fake = new FakeRequestProcessor();
            fake.AddResponse("*", "<ok/>");
            created.Add(fake);
            return fake;
        }

        var qb = new QbOptions
        {
            DefaultCompany = "co-a",
            Companies =
            {
                ["co-a"] = new QbCompany { CompanyFilePath = @"D:\a.qbw", AppId = "appA", AppName = "Service A" },
                ["co-b"] = new QbCompany { CompanyFilePath = @"D:\b.qbw", AppId = "appB", AppName = "Service B" },
            },
        };
        var manager = new QbConnectionManager(
            Factory,
            Options.Create(qb),
            Options.Create(new RequestOptions { TimeoutSeconds = 30, BusyWaitSeconds = 5 }),
            NullLogger<QbConnectionManager>.Instance,
            Options.Create(new SafetyOptions { AllowWrites = true }));

        const string req = "<?xml version=\"1.0\"?><?qbxml version=\"16.0\"?><QBXML><QBXMLMsgsRq onError=\"stopOnError\"><CompanyQueryRq/></QBXMLMsgsRq></QBXML>";

        using (QbCompanyContext.Push("co-a"))
        {
            await manager.ExecuteAsync(req);
        }
        Assert.Equal("co-a", manager.CurrentCompanyKey);
        Assert.Single(created);
        Assert.Equal("appA", created[0].LastAppId);
        Assert.Equal(@"D:\a.qbw", created[0].LastCompanyFilePath);

        using (QbCompanyContext.Push("co-b"))
        {
            await manager.ExecuteAsync(req);
        }
        Assert.Equal("co-b", manager.CurrentCompanyKey);
        Assert.Equal(2, created.Count);
        Assert.Equal("appB", created[1].LastAppId);
        Assert.Equal(@"D:\b.qbw", created[1].LastCompanyFilePath);

        // Third call back to co-a -> swap again (new RP instance created)
        using (QbCompanyContext.Push("co-a"))
        {
            await manager.ExecuteAsync(req);
        }
        Assert.Equal("co-a", manager.CurrentCompanyKey);
        Assert.Equal(3, created.Count);
        Assert.Equal("appA", created[2].LastAppId);

        await manager.DisposeAsync();
    }

    [Fact]
    public async Task Manager_keeps_same_session_when_company_context_is_unchanged()
    {
        var created = new List<FakeRequestProcessor>();
        IRequestProcessor Factory()
        {
            var fake = new FakeRequestProcessor();
            fake.AddResponse("*", "<ok/>");
            created.Add(fake);
            return fake;
        }

        var qb = new QbOptions
        {
            DefaultCompany = "co-a",
            Companies =
            {
                ["co-a"] = new QbCompany { CompanyFilePath = @"D:\a.qbw", AppId = "appA", AppName = "Service A" },
            },
        };
        var manager = new QbConnectionManager(
            Factory,
            Options.Create(qb),
            Options.Create(new RequestOptions { TimeoutSeconds = 30, BusyWaitSeconds = 5 }),
            NullLogger<QbConnectionManager>.Instance,
            Options.Create(new SafetyOptions { AllowWrites = true }));

        const string req = "<?xml version=\"1.0\"?><?qbxml version=\"16.0\"?><QBXML><QBXMLMsgsRq onError=\"stopOnError\"><CompanyQueryRq/></QBXMLMsgsRq></QBXML>";

        using (QbCompanyContext.Push("co-a"))
        {
            await manager.ExecuteAsync(req);
            await manager.ExecuteAsync(req);
            await manager.ExecuteAsync(req);
        }

        Assert.Single(created);                                          // only one RP created
        Assert.Equal(3, created[0].CallLog.Count(c => c == nameof(IRequestProcessor.ProcessRequest)));
        Assert.Equal(1, created[0].CallLog.Count(c => c == nameof(IRequestProcessor.OpenConnection)));

        await manager.DisposeAsync();
    }

    [Fact]
    public async Task Endpoint_unknown_company_returns_400()
    {
        await using var factory = new QbWebAppFactory();
        using var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", QbWebAppFactory.Token);

        using var content = new StringContent("{}", Encoding.UTF8, "application/json");
        var response = await client.PostAsync("/api/ops/company_info?company=not-there", content);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("not-there", body, StringComparison.Ordinal);
    }

    [Fact]
    public async Task Endpoint_known_company_query_param_echoed_in_response()
    {
        await using var factory = new MultiTenantQbWebAppFactory();
        factory.Fake.AddResponse("HostQueryRq", QbWebAppFactory.Fixture("HostCompanyQueryRs.qbxml"));

        using var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", QbWebAppFactory.Token);

        using var content = new StringContent("{}", Encoding.UTF8, "application/json");
        var response = await client.PostAsync("/api/ops/company_info?company=co-a", content);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Assert.Equal("co-a", doc.RootElement.GetProperty("company").GetString());
    }

    [Fact]
    public async Task Endpoint_X_Qb_Company_header_resolves_company()
    {
        await using var factory = new MultiTenantQbWebAppFactory();
        factory.Fake.AddResponse("HostQueryRq", QbWebAppFactory.Fixture("HostCompanyQueryRs.qbxml"));

        using var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", QbWebAppFactory.Token);
        client.DefaultRequestHeaders.Add("X-Qb-Company", "co-b");

        using var content = new StringContent("{}", Encoding.UTF8, "application/json");
        var response = await client.PostAsync("/api/ops/company_info", content);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Assert.Equal("co-b", doc.RootElement.GetProperty("company").GetString());
    }

    /// <summary>Variant of QbWebAppFactory that ships a real Qb.Companies dict with two entries.</summary>
    private sealed class MultiTenantQbWebAppFactory : QbWebAppFactory
    {
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            base.ConfigureWebHost(builder);
            builder.UseSetting("Qb:DefaultCompany", "co-a");
            builder.UseSetting("Qb:Companies:co-a:CompanyFilePath", @"D:\a.qbw");
            builder.UseSetting("Qb:Companies:co-a:AppId", "appA");
            builder.UseSetting("Qb:Companies:co-a:AppName", "Service A");
            builder.UseSetting("Qb:Companies:co-b:CompanyFilePath", @"D:\b.qbw");
            builder.UseSetting("Qb:Companies:co-b:AppId", "appB");
            builder.UseSetting("Qb:Companies:co-b:AppName", "Service B");
        }
    }
}

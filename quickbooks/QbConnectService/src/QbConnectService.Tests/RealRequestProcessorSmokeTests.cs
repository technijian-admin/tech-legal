using QbConnectService.Qb;
using QbConnectService.Qb.Com;

namespace QbConnectService.Tests;

public sealed class RealRequestProcessorSmokeTests
{
    [Fact]
    public void Constructor_maps_COM_activation_failure_into_QbException()
    {
        if (!OperatingSystem.IsWindows())
        {
            return;
        }

        // RealRequestProcessor uses late-bound COM via Type.GetTypeFromProgID. On the QuickBooks host
        // (or any box that has the QB SDK / Desktop registered), construction SUCCEEDS - nothing to assert.
        // Skip in that case; this test only exercises the no-COM-registered failure-mapping path.
        var registered =
            Type.GetTypeFromProgID("QBXMLRP2.RequestProcessor2") is not null ||
            Type.GetTypeFromProgID("QBXMLRP2.RequestProcessor") is not null;
        if (registered)
        {
            return;
        }

        var exception = Assert.Throws<QbException>(() => new RealRequestProcessor());

        Assert.True(
            exception.Error.Name is "REGDB_E_CLASSNOTREG" or "QB_RP2_CAST_FAILED",
            $"expected a mapped activation-failure error, got {exception.Error.Name}");
    }
}

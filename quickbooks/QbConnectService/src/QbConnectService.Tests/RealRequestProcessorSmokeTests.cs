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

        // Phase 1's placeholder COM GUIDs are intentionally not registered on the test machine, so the only
        // behavior in scope here is that activation fails cleanly as a mapped QbException. Real COM activation
        // against the SDK-generated interop is a Phase 9 concern on the QuickBooks host.
        var exception = Assert.Throws<QbException>(() => new RealRequestProcessor());

        Assert.True(
            exception.Error.Name is "REGDB_E_CLASSNOTREG" or "QB_RP2_CAST_FAILED",
            $"expected a mapped activation-failure error, got {exception.Error.Name}");
    }
}

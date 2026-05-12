using System.Reflection;
using System.Reflection.PortableExecutable;
using System.Runtime.Versioning;

namespace QbConnectService.Tests;

public sealed class BuildConfigTests
{
    [Fact]
    public void Host_assembly_targets_net8_0_windows()
    {
        var assembly = typeof(QbConnectService.Worker).Assembly;
        var targetFramework = assembly.GetCustomAttribute<TargetFrameworkAttribute>()?.FrameworkName ?? string.Empty;
        var targetPlatform = assembly.GetCustomAttribute<TargetPlatformAttribute>()?.PlatformName ?? string.Empty;

        Assert.Contains(".NETCoreApp,Version=v8.0", targetFramework);
        Assert.Contains("windows", targetPlatform, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Host_assembly_is_x86()
    {
        var assemblyPath = typeof(QbConnectService.Worker).Assembly.Location;

        using var stream = File.OpenRead(assemblyPath);
        using var peReader = new PEReader(stream);
        var headers = peReader.PEHeaders;

        Assert.Equal(Machine.I386, headers.CoffHeader.Machine);
        Assert.True(headers.CorHeader is not null && headers.CorHeader.Flags.HasFlag(CorFlags.Requires32Bit));
    }
}

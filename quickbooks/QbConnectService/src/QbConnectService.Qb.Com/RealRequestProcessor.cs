using System.Reflection;
using System.Runtime.InteropServices;
using System.Runtime.Versioning;
using QbConnectService.Qb;

namespace QbConnectService.Qb.Com;

/// <summary>
/// Late-bound COM wrapper for QBXMLRP2.RequestProcessor / RequestProcessor2. Uses Type.InvokeMember (IDispatch
/// path) so the service has NO compile-time dependency on a tlbimp-generated Interop DLL - only the QuickBooks
/// SDK COM registration on the host is required at runtime.
///
/// Implementation notes:
///   - 'dynamic' is intentionally NOT used. The DLR in .NET Core/.NET 5+ does not bind against __ComObject the
///     way .NET Framework did, so 'dynamic' silently returns __ComObject values you cannot then invoke methods
///     on. InvokeMember goes through COM IDispatch and works on every IDispatch interface (including sub-objects
///     such as AuthPreferences()).
///   - All InvokeMember calls use BindingFlags.IgnoreCase. IDispatch::GetIDsOfNames is case-insensitive, so
///     adding IgnoreCase avoids spurious DISP_E_MEMBERNOTFOUND for casing differences across SDK versions.
///   - "Newer-interface only" methods (OpenConnection2, QBXMLVersionsForSession, AuthPreferences) gracefully
///     degrade to either the older equivalent (OpenConnection without connection-type) or a no-op when the
///     activated COM object only exposes the older IRequestProcessor as its default IDispatch.
/// </summary>
[SupportedOSPlatform("windows")]
public sealed class RealRequestProcessor : IRequestProcessor
{
    // IDispatch "this name isn't on this interface" errors. Both can be returned depending on which COM layer
    // reports the lookup miss (Invoke vs GetIDsOfNames). Treat them identically when deciding fall-back paths.
    //   0x80020003 DISP_E_MEMBERNOTFOUND - IDispatch::Invoke says member not found.
    //   0x80020006 DISP_E_UNKNOWNNAME    - IDispatch::GetIDsOfNames says name not in dispatch table.
    private const int DispMemberNotFound = unchecked((int)0x80020003);
    private const int DispUnknownName = unchecked((int)0x80020006);

    private static bool IsNameNotFound(int hresult) =>
        hresult == DispMemberNotFound || hresult == DispUnknownName;

    // Combined flags for late-bound IDispatch calls (case-insensitive method invocation).
    private const BindingFlags InvokeFlags = BindingFlags.InvokeMethod | BindingFlags.IgnoreCase;

    // Combined flags for members that may be declared as either a method or a propget in the type library.
    private const BindingFlags FlexibleFlags =
        BindingFlags.InvokeMethod | BindingFlags.GetProperty | BindingFlags.IgnoreCase;

    private static readonly string[] ProgIds =
    {
        "QBXMLRP2.RequestProcessor2",
        "QBXMLRP2.RequestProcessor",
    };

    private object? _rp;

    public RealRequestProcessor()
    {
        try
        {
            Type? comType = null;
            foreach (var progId in ProgIds)
            {
                comType = Type.GetTypeFromProgID(progId, throwOnError: false);
                if (comType is not null)
                {
                    break;
                }
            }

            if (comType is null)
            {
                throw new COMException(
                    $"No QBXMLRP2 ProgID registered (tried: {string.Join(", ", ProgIds)}). Install the QuickBooks SDK or QuickBooks Desktop on this host.",
                    unchecked((int)0x80040154));
            }

            _rp = Activator.CreateInstance(comType)
                ?? throw new COMException(
                    "Activator.CreateInstance returned null for QBXMLRP2.",
                    unchecked((int)0x80040154));
        }
        catch (COMException ex)
        {
            throw new QbException(QbErrors.Lookup(ex.HResult), ex);
        }
    }

    private object Target => _rp ?? throw new ObjectDisposedException(nameof(RealRequestProcessor));

    public void OpenConnection(string appId, string appName, QbConnectionType connectionType)
    {
        // Prefer OpenConnection2 (IRequestProcessor2 - takes a connection-type parameter). Fall back to the
        // older single-argument OpenConnection when IDispatch only exposes the older IRequestProcessor.
        try
        {
            InvokeVoid(Target, "OpenConnection2", appId, appName, (int)connectionType);
        }
        catch (COMException ex) when (IsNameNotFound(ex.HResult))
        {
            InvokeVoid(Target, "OpenConnection", appId, appName);
        }
    }

    public string BeginSession(string companyFilePath, QbFileMode openMode)
    {
        return Invoke<string>(Target, "BeginSession", companyFilePath, (int)openMode) ?? string.Empty;
    }

    public string ProcessRequest(string ticket, string qbXmlRequest)
    {
        return Invoke<string>(Target, "ProcessRequest", ticket, qbXmlRequest) ?? string.Empty;
    }

    public string[] GetSupportedQbXmlVersions(string ticket)
    {
        // Newer-interface only. Older IRequestProcessor doesn't expose this - return empty.
        object? result;
        try
        {
            result = Invoke<object>(Target, "QBXMLVersionsForSession", ticket);
        }
        catch (COMException ex) when (IsNameNotFound(ex.HResult))
        {
            return Array.Empty<string>();
        }
        return result switch
        {
            string[] sa => sa,
            object[] oa => oa.Select(o => o?.ToString() ?? string.Empty).ToArray(),
            null => Array.Empty<string>(),
            _ => new[] { result.ToString() ?? string.Empty },
        };
    }

    public void EndSession(string ticket)
    {
        InvokeVoid(Target, "EndSession", ticket);
    }

    public void CloseConnection()
    {
        InvokeVoid(Target, "CloseConnection");
    }

    public void SetUnattendedModePreference(bool required)
    {
        // AuthPreferences is only on IRequestProcessor2. If IDispatch only exposes IRequestProcessor (older),
        // we silently skip setting unattended mode - the user can still enable it via QuickBooks Preferences
        // -> Integrated Applications when authorizing the app.
        object? prefs;
        try
        {
            prefs = InvokeFlexible(Target, "AuthPreferences");
        }
        catch (COMException ex) when (IsNameNotFound(ex.HResult))
        {
            return;
        }

        if (prefs is null)
        {
            return;
        }

        try
        {
            InvokeVoid(prefs, "PutUnattendedModePref", required);
        }
        catch (COMException ex) when (IsNameNotFound(ex.HResult))
        {
            // AuthPreferences exists but PutUnattendedModePref doesn't - shouldn't normally happen.
        }
        // DO NOT call Marshal.FinalReleaseComObject(prefs) - some QBXMLRP2 builds return the
        // RequestProcessor itself (or a tear-off interface backed by the same IUnknown) for
        // AuthPreferences. Releasing prefs in that case kills _rp's RCW and the next COM call
        // throws InvalidComObjectException ("no backing class factory"). The RCW for prefs will
        // be GC'd when this method returns; that's safe regardless of whether it aliases _rp.
    }

    public void Dispose()
    {
        if (_rp is not null)
        {
            ReleaseCom(_rp);
            _rp = null;
        }
    }

    // ------------------------------------------------------------------------
    // Late-bound helpers
    // ------------------------------------------------------------------------

    private static T? Invoke<T>(object target, string method, params object?[] args)
    {
        try
        {
            var result = target.GetType().InvokeMember(method, InvokeFlags, binder: null, target: target, args: args);
            return (T?)result;
        }
        catch (TargetInvocationException ex) when (ex.InnerException is not null)
        {
            // Surface the real COM exception so the caller's catch(COMException) actually fires.
            throw ex.InnerException;
        }
    }

    private static void InvokeVoid(object target, string method, params object?[] args)
    {
        try
        {
            target.GetType().InvokeMember(method, InvokeFlags, binder: null, target: target, args: args);
        }
        catch (TargetInvocationException ex) when (ex.InnerException is not null)
        {
            throw ex.InnerException;
        }
    }

    /// <summary>
    /// Lookup that tries both method-invoke and property-get semantics. Used for COM members that may be
    /// declared as either a parameterless method or a propget in the type library.
    /// </summary>
    private static object? InvokeFlexible(object target, string name, params object?[] args)
    {
        try
        {
            return target.GetType().InvokeMember(name, FlexibleFlags, binder: null, target: target, args: args);
        }
        catch (TargetInvocationException ex) when (ex.InnerException is not null)
        {
            throw ex.InnerException;
        }
    }

    /// <summary>
    /// Release a COM RCW safely. Marshal.FinalReleaseComObject throws ArgumentException for non-COM objects, so
    /// guard with IsComObject; any other failure is silently ignored (this is cleanup, not a load-bearing path).
    /// </summary>
    private static void ReleaseCom(object? obj)
    {
        if (obj is null || !Marshal.IsComObject(obj))
        {
            return;
        }
        try
        {
            Marshal.FinalReleaseComObject(obj);
        }
        catch
        {
        }
    }
}

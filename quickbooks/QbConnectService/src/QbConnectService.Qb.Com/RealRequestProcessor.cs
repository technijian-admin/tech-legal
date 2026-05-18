using System.Reflection;
using System.Runtime.InteropServices;
using System.Runtime.Versioning;
using QbConnectService.Qb;

namespace QbConnectService.Qb.Com;

/// <summary>
/// Late-bound COM wrapper for QBXMLRP2.RequestProcessor / RequestProcessor2. Uses Type.InvokeMember (IDispatch
/// path) so the service has NO compile-time dependency on a tlbimp-generated Interop DLL. Only the QuickBooks
/// SDK COM registration on the host is required at runtime - no Windows SDK / tlbimp needed.
///
/// NOTE: 'dynamic' dispatch is intentionally NOT used here - the DLR in .NET Core/.NET 5+ does not bind against
/// __ComObject the way .NET Framework did, so 'dynamic' silently returns __ComObject values you cannot then
/// invoke methods on. InvokeMember goes through the COM IDispatch path and works on every IDispatch interface
/// (including sub-objects like AuthPreferences()).
/// </summary>
[SupportedOSPlatform("windows")]
public sealed class RealRequestProcessor : IRequestProcessor
{
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
        // Prefer OpenConnection2 (IRequestProcessor2 - takes connection type). Fall back to OpenConnection
        // (older IRequestProcessor) when IDispatch only exposes the older interface.
        try
        {
            InvokeVoid(Target, "OpenConnection2", appId, appName, (int)connectionType);
        }
        catch (COMException ex) when (ex.HResult == DispMemberNotFound)
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
        // Newer-interface only. Older IRequestProcessor doesn't expose this - return empty (callers tolerate it).
        object? result;
        try
        {
            result = Invoke<object>(Target, "QBXMLVersionsForSession", ticket);
        }
        catch (COMException ex) when (ex.HResult == DispMemberNotFound)
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
        // -> Integrated Applications when authorizing the app. Service continues normally.
        object? prefs;
        try
        {
            // Try both InvokeMethod and GetProperty - 'AuthPreferences' is declared as a propget in IDL.
            prefs = InvokeFlexible(Target, "AuthPreferences");
        }
        catch (COMException ex) when (ex.HResult == DispMemberNotFound)
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
        catch (COMException ex) when (ex.HResult == DispMemberNotFound)
        {
            // AuthPreferences exists but PutUnattendedModePref doesn't - shouldn't normally happen, ignore.
        }
        finally
        {
            try { Marshal.FinalReleaseComObject(prefs); } catch { }
        }
    }

    public void Dispose()
    {
        if (_rp is not null)
        {
            Marshal.FinalReleaseComObject(_rp);
            _rp = null;
        }
    }

    // DISP_E_MEMBERNOTFOUND - IDispatch::GetIDsOfNames couldn't find the method/property on this interface.
    private const int DispMemberNotFound = unchecked((int)0x80020003);

    private static T? Invoke<T>(object target, string method, params object?[] args)
    {
        try
        {
            var result = target.GetType().InvokeMember(
                method,
                BindingFlags.InvokeMethod,
                binder: null,
                target: target,
                args: args);
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
            target.GetType().InvokeMember(
                method,
                BindingFlags.InvokeMethod,
                binder: null,
                target: target,
                args: args);
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
            return target.GetType().InvokeMember(
                name,
                BindingFlags.InvokeMethod | BindingFlags.GetProperty,
                binder: null,
                target: target,
                args: args);
        }
        catch (TargetInvocationException ex) when (ex.InnerException is not null)
        {
            throw ex.InnerException;
        }
    }
}

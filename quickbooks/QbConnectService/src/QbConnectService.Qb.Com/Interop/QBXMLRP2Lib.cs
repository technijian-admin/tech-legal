using System.Runtime.InteropServices;

namespace QbConnectService.Qb.Com.Interop;

/*
PHASE-1 STUB. This hand-written [ComImport] declaration lets the solution build with NO QuickBooks SDK installed.
In Phase 9, on the QuickBooks host, regenerate the real interop via
tlbimp "%CommonProgramFiles%\Intuit\QuickBooks\QBXMLRP2.dll" /out:..\lib\Interop.QBXMLRP2Lib.dll,
reference that DLL with EmbedInteropTypes=false, and delete this file.

REVIEWER FLAG: QBXMLRP2Lib.cs is intentionally a compile-only stub with placeholder GUIDs. It is NOT finished COM
interop. RealRequestProcessor intentionally throws NotImplementedException for every method in Phase 1. Real COM
interop is built in Phase 2, and the real interop DLL is generated in Phase 9 on the QuickBooks host.

The GUIDs, method order, and supporting sub-objects below are placeholders that merely compile. They are not
verified against the real QBXMLRP2 type library, whose final shape is regenerated in Phase 9.
*/

[ComImport]
[Guid("45F5708E-3B43-4D88-A4B1-65E0F8B4E001")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IRequestProcessor2
{
    void OpenConnection2(
        [MarshalAs(UnmanagedType.BStr)] string appId,
        [MarshalAs(UnmanagedType.BStr)] string appName,
        int connectionType);

    [return: MarshalAs(UnmanagedType.BStr)]
    string BeginSession(
        [MarshalAs(UnmanagedType.BStr)] string companyFile,
        int fileMode);

    [return: MarshalAs(UnmanagedType.BStr)]
    string ProcessRequest(
        [MarshalAs(UnmanagedType.BStr)] string ticket,
        [MarshalAs(UnmanagedType.BStr)] string qbXmlRequest);

    [return: MarshalAs(UnmanagedType.SafeArray, SafeArraySubType = VarEnum.VT_BSTR)]
    string[] QBXMLVersionsForSession([MarshalAs(UnmanagedType.BStr)] string ticket);

    void EndSession([MarshalAs(UnmanagedType.BStr)] string ticket);

    void CloseConnection();

    IAuthPreferences AuthPreferences();
}

[ComImport]
[Guid("45F5708E-3B43-4D88-A4B1-65E0F8B4E002")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IAuthPreferences
{
    void PutUnattendedModePref([MarshalAs(UnmanagedType.Bool)] bool required);
}

[ComImport]
[Guid("45F5708E-3B43-4D88-A4B1-65E0F8B4E003")]
public class RequestProcessor2
{
}

namespace QbConnectService.Qb;

/// <param name="Code">HRESULT (e.g. unchecked((int)0x80040401))</param>
public sealed record QbError(int Code, string Name, string Message, string RemediationHint);

public static class QbErrors
{
    private static readonly IReadOnlyDictionary<int, QbError> Map = new Dictionary<int, QbError>
    {
        [unchecked((int)0x80040401)] = new(unchecked((int)0x80040401), "QB_ACCESS_FAILED",
            "Could not access QuickBooks (connection attempt failed; the QuickBooks install may be incomplete or broken).",
            "Check QuickBooks is installed/repaired under the service account; check the session-0 setup; see qbsdklog.txt."),
        [unchecked((int)0x80040402)] = new(unchecked((int)0x80040402), "QB_UNEXPECTED_ERROR",
            "Unexpected QuickBooks SDK error - see qbsdklog.txt for details.",
            "Pull qbsdklog.txt from the QuickBooks host."),
        [unchecked((int)0x80040408)] = new(unchecked((int)0x80040408), "QB_COULD_NOT_START",
            "Could not start QuickBooks (launch failed; install incomplete or session-0 instability).",
            "Pre-launch QuickBooks under the service account; verify the scheduled-task launch path; see qbsdklog.txt."),
        [unchecked((int)0x8004040A)] = new(unchecked((int)0x8004040A), "QB_DIFFERENT_FILE_OPEN",
            "A different company file is already open on this machine.",
            "Close the other company file, or fix Qb:CompanyFilePath."),
        [unchecked((int)0x8004040D)] = new(unchecked((int)0x8004040D), "QB_INVALID_TICKET",
            "Invalid or expired session ticket (the session was dropped, e.g. QuickBooks restarted).",
            "Transient - the service rebuilds the connection and retries once automatically."),
        [unchecked((int)0x80040410)] = new(unchecked((int)0x80040410), "QB_MODE_MISMATCH",
            "The company file is open in a mode other than the one specified.",
            "A human has the file open single-user; switch the file to multi-user (hosted) mode."),
        [unchecked((int)0x80040414)] = new(unchecked((int)0x80040414), "QB_MODAL_DIALOG",
            "A modal dialog is showing in the QuickBooks UI, blocking the SDK.",
            "Dismiss the dialog on the QuickBooks host and find what is popping it (often an update prompt)."),
        [unchecked((int)0x80040416)] = new(unchecked((int)0x80040416), "QB_NO_FILE_SPECIFIED",
            "QuickBooks is not running and BeginSession did not receive a company-file path.",
            "Set Qb:CompanyFilePath to the full path of the .QBW (UNC if on a share)."),
        [unchecked((int)0x8004041A)] = new(unchecked((int)0x8004041A), "QB_NO_PERMISSION",
            "This application does not have permission to access this company file.",
            "Re-run register-integrated-app.md (Admin, single-user mode)."),
        [unchecked((int)0x80040420)] = new(unchecked((int)0x80040420), "QB_ACCESS_DENIED",
            "The QuickBooks user has denied access (integrated app not authorized / revoked / waiting for permission).",
            "Re-run register-integrated-app.md; check the integrated-apps list in QuickBooks."),
        [unchecked((int)0x80040421)] = new(unchecked((int)0x80040421), "QB_PASSTHROUGH",
            "Message passed through from QuickBooks.",
            "Read the message text; usually a QuickBooks-side condition."),
        [unchecked((int)0x80040422)] = new(unchecked((int)0x80040422), "QB_REQUIRES_SINGLE_USER",
            "This application requires single-user file access mode.",
            "Another app/user shares the file; coordinate access."),
        [unchecked((int)0x80040154)] = new(unchecked((int)0x80040154), "REGDB_E_CLASSNOTREG",
            "QBXMLRP2.RequestProcessor is not registered (QuickBooks SDK not installed, or a 32/64-bit interop mismatch).",
            "Install the QuickBooks SDK on the host; confirm the service runs as x86; see Phase 9 deploy notes."),
        [unchecked((int)0x80010105)] = new(unchecked((int)0x80010105), "RPC_E_SERVERFAULT",
            "The QuickBooks COM server faulted - typically QBW.EXE is holding a different .qbw file and cannot switch in-place.",
            "Stop the existing QBW.EXE process so the next call cold-starts QuickBooks on the requested file. The service can do this automatically when Qb:AutoRecoverFromQbwStuck is enabled (default)."),
    };

    private static readonly HashSet<int> DeadTicket = [unchecked((int)0x8004040D)];

    /// <summary>
    /// HRESULTs for which the recommended fix is "kill QBW.EXE and let the next call cold-start it fresh."
    /// Per the Intuit QB SDK 16.0 Programmer's Guide ("Limitations on Accessing Company Files", page 53):
    /// only one company file at a time is accessible per machine, so QBW.EXE has to be terminated when
    /// (a) a different file is requested, (b) the COM server is in a stuck state, or (c) a modal dialog
    /// is blocking QB's UI thread.
    /// </summary>
    private static readonly HashSet<int> QbwStuck =
    [
        unchecked((int)0x8004040A), // QB_DIFFERENT_FILE_OPEN
        unchecked((int)0x80040414), // QB_MODAL_DIALOG
        unchecked((int)0x80010105), // RPC_E_SERVERFAULT
    ];

    public static bool IsDeadTicket(int hresult) => DeadTicket.Contains(hresult);

    public static bool IsRecoverableByQbwRestart(int hresult) => QbwStuck.Contains(hresult);

    public static QbError Lookup(int hresult) =>
        Map.TryGetValue(hresult, out var error)
            ? error
            : new QbError(
                hresult,
                "QB_UNKNOWN",
                $"Unmapped QuickBooks/COM error 0x{hresult:X8}.",
                "See qbsdklog.txt on the QuickBooks host; consult the QuickBooks SDK error reference.");

    public static QbError CastFailure(string detail) =>
        new(
            unchecked((int)0x80040154),
            "QB_RP2_CAST_FAILED",
            $"Unable to cast the COM object to RequestProcessor2 ({detail}). The QBXMLRP2 type library is missing or the wrong bitness.",
            "Install/repair the QuickBooks SDK on the host; confirm x86; regenerate Interop.QBXMLRP2Lib.dll on the host (Phase 9).");
}

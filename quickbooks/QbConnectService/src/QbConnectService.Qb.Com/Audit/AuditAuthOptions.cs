namespace QbConnectService.Qb;

/// <summary>
/// Mirror of AuthOptions.ApiToken bound from the Auth section, so AuditLog (in Qb.Com) can derive
/// requesterId without a cross-project dependency on the service project.
/// </summary>
public sealed class AuditAuthOptions
{
    public string? ApiToken { get; set; }
}

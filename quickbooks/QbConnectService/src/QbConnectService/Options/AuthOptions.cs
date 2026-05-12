namespace QbConnectService;

public sealed class AuthOptions
{
    /// <summary>
    /// Static LAN bearer token, compared with CryptographicOperations.FixedTimeEquals; from config only, never
    /// source. An empty/null token never matches.
    /// </summary>
    public string? ApiToken { get; set; }
}

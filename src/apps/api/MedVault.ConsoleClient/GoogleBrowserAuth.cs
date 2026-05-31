using System.Diagnostics;
using System.Net;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

namespace MedVault.ConsoleClient;

public sealed class GoogleBrowserAuth
{
    private const string AuthorizationEndpoint = "https://accounts.google.com/o/oauth2/v2/auth";
    private const string TokenEndpoint = "https://oauth2.googleapis.com/token";

    private readonly string _clientId;
    private readonly string _clientSecret;

    public GoogleBrowserAuth(string clientId, string clientSecret)
    {
        _clientId = clientId;
        _clientSecret = clientSecret;
    }

    public async Task<GoogleTokenResult> AuthenticateAsync(CancellationToken cancellationToken = default)
    {
        var codeVerifier = GenerateCodeVerifier();
        var codeChallenge = GenerateCodeChallenge(codeVerifier);

        var port = GetAvailablePort();
        var redirectUri = $"http://localhost:{port}/";

        using var listener = new HttpListener();
        listener.Prefixes.Add(redirectUri);
        listener.Start();

        Console.WriteLine($"  Listening on {redirectUri}");

        var state = Guid.NewGuid().ToString("N");
        var authUrl = BuildAuthorizationUrl(redirectUri, codeChallenge, state);

        Console.WriteLine("  Opening browser for Google Sign-In...");
        Console.WriteLine();
        OpenBrowser(authUrl);

        Console.WriteLine("  Waiting for authentication callback...");
        var code = await WaitForAuthorizationCodeAsync(listener, state, cancellationToken);

        if (string.IsNullOrEmpty(code))
            throw new InvalidOperationException("No authorization code received from Google.");

        ConsoleUI.WriteSuccess("Authorization code received!");
        Console.WriteLine();

        Console.WriteLine("  Exchanging code for tokens...");
        return await ExchangeCodeForTokensAsync(code, redirectUri, codeVerifier, cancellationToken);
    }

    private string BuildAuthorizationUrl(string redirectUri, string codeChallenge, string state)
    {
        var parameters = new Dictionary<string, string>
        {
            ["client_id"] = _clientId,
            ["redirect_uri"] = redirectUri,
            ["response_type"] = "code",
            ["scope"] = "openid email profile",
            ["code_challenge"] = codeChallenge,
            ["code_challenge_method"] = "S256",
            ["state"] = state,
            ["access_type"] = "offline",
            ["prompt"] = "consent"
        };

        var queryString = string.Join("&",
            parameters.Select(p => $"{Uri.EscapeDataString(p.Key)}={Uri.EscapeDataString(p.Value)}"));

        return $"{AuthorizationEndpoint}?{queryString}";
    }

    private static async Task<string?> WaitForAuthorizationCodeAsync(
        HttpListener listener, string expectedState, CancellationToken cancellationToken)
    {
        var context = await listener.GetContextAsync().WaitAsync(TimeSpan.FromMinutes(2), cancellationToken);
        var request = context.Request;
        var query = request.QueryString;

        var receivedState = query["state"];
        var code = query["code"];
        var error = query["error"];

        var response = context.Response;
        string responseHtml;

        if (!string.IsNullOrEmpty(error))
        {
            responseHtml = $"""
                <html><body style="font-family:sans-serif;text-align:center;padding:40px;">
                <h2 style="color:#d32f2f;">❌ Authentication Failed</h2>
                <p>Error: {WebUtility.HtmlEncode(error)}</p>
                <p>You can close this window.</p>
                </body></html>
                """;
        }
        else if (receivedState != expectedState)
        {
            responseHtml = """
                <html><body style="font-family:sans-serif;text-align:center;padding:40px;">
                <h2 style="color:#d32f2f;">❌ State Mismatch</h2>
                <p>The authentication response state did not match.</p>
                <p>You can close this window.</p>
                </body></html>
                """;
            code = null;
        }
        else
        {
            responseHtml = """
                <html><body style="font-family:sans-serif;text-align:center;padding:40px;">
                <h2 style="color:#2e7d32;">✅ Authentication Successful!</h2>
                <p>You can close this window and return to the console app.</p>
                </body></html>
                """;
        }

        var buffer = Encoding.UTF8.GetBytes(responseHtml);
        response.ContentType = "text/html; charset=utf-8";
        response.ContentLength64 = buffer.Length;
        await response.OutputStream.WriteAsync(buffer, cancellationToken);
        response.Close();

        listener.Stop();

        return code;
    }

    private async Task<GoogleTokenResult> ExchangeCodeForTokensAsync(
        string code, string redirectUri, string codeVerifier, CancellationToken cancellationToken)
    {
        using var client = new HttpClient();

        var tokenRequest = new FormUrlEncodedContent(new Dictionary<string, string>
        {
            ["code"] = code,
            ["client_id"] = _clientId,
            ["client_secret"] = _clientSecret,
            ["redirect_uri"] = redirectUri,
            ["grant_type"] = "authorization_code",
            ["code_verifier"] = codeVerifier
        });

        var response = await client.PostAsync(TokenEndpoint, tokenRequest, cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);

        if (!response.IsSuccessStatusCode)
            throw new InvalidOperationException($"Token exchange failed ({(int)response.StatusCode}): {body}");

        using var doc = JsonDocument.Parse(body);
        var root = doc.RootElement;

        return new GoogleTokenResult
        {
            IdToken = root.GetProperty("id_token").GetString()!,
            AccessToken = root.TryGetProperty("access_token", out var at) ? at.GetString() : null,
            RefreshToken = root.TryGetProperty("refresh_token", out var rt) ? rt.GetString() : null,
            ExpiresIn = root.TryGetProperty("expires_in", out var ei) ? ei.GetInt32() : 0
        };
    }

    private static string GenerateCodeVerifier()
    {
        var bytes = RandomNumberGenerator.GetBytes(32);
        return Base64UrlEncode(bytes);
    }

    private static string GenerateCodeChallenge(string codeVerifier)
    {
        var hash = SHA256.HashData(Encoding.ASCII.GetBytes(codeVerifier));
        return Base64UrlEncode(hash);
    }

    private static string Base64UrlEncode(byte[] bytes)
    {
        return Convert.ToBase64String(bytes)
            .Replace('+', '-')
            .Replace('/', '_')
            .TrimEnd('=');
    }

    private static int GetAvailablePort()
    {
        using var listener = new System.Net.Sockets.TcpListener(IPAddress.Loopback, 0);
        listener.Start();
        var port = ((IPEndPoint)listener.LocalEndpoint).Port;
        listener.Stop();
        return port;
    }

    private static void OpenBrowser(string url)
    {
        if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            Process.Start(new ProcessStartInfo(url) { UseShellExecute = true });
        else if (RuntimeInformation.IsOSPlatform(OSPlatform.OSX))
            Process.Start("open", url);
        else
            Process.Start("xdg-open", url);
    }
}

public class GoogleTokenResult
{
    public string IdToken { get; set; } = string.Empty;
    public string? AccessToken { get; set; }
    public string? RefreshToken { get; set; }
    public int ExpiresIn { get; set; }
}

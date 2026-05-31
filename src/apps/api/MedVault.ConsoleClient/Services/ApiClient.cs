using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using MedVault.ConsoleClient.Models;

namespace MedVault.ConsoleClient.Services;

public sealed class ApiClient : IDisposable
{
    private readonly HttpClient _http;
    private readonly JsonSerializerOptions _json;

    public ApiClient(string baseUrl)
    {
        _http = new HttpClient
        {
            BaseAddress = new Uri(baseUrl)
        };
        _json = new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true,
            WriteIndented = true
        };
    }

    public void SetBearerToken(string token)
    {
        _http.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
    }

    public void ClearBearerToken()
    {
        _http.DefaultRequestHeaders.Authorization = null;
    }

    public async Task<ApiResponse<GoogleLoginResponse>?> GoogleLoginAsync(string idToken)
    {
        var response = await _http.PostAsJsonAsync("/auth/google", new { idToken });
        var body = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<ApiResponse<GoogleLoginResponse>>(body, _json);
    }

    public async Task<ApiResponse<RegisterResponse>?> GoogleRegisterAsync(
        string idToken, string firstName, string lastName,
        bool termsAccepted = true, bool privacyPolicyAccepted = true)
    {
        var request = new
        {
            idToken,
            firstName,
            lastName,
            termsAccepted,
            privacyPolicyAccepted
        };
        var response = await _http.PostAsJsonAsync("/auth/google/register", request);
        var body = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<ApiResponse<RegisterResponse>>(body, _json);
    }

    public async Task<(ApiResponse<PkceAuthorizationCodeResponse>? Result, string CodeVerifier)> EmailRegisterAsync(
        string email, string password, string firstName, string lastName,
        bool termsAccepted = true, bool privacyPolicyAccepted = true)
    {
        var codeVerifier = GenerateCodeVerifier();
        var codeChallenge = GenerateCodeChallenge(codeVerifier);

        var request = new
        {
            email,
            password,
            firstName,
            lastName,
            termsAccepted,
            privacyPolicyAccepted,
            codeChallenge,
            codeChallengeMethod = "S256"
        };

        var response = await _http.PostAsJsonAsync("/auth/email/register", request);
        var body = await response.Content.ReadAsStringAsync();
        var result = JsonSerializer.Deserialize<ApiResponse<PkceAuthorizationCodeResponse>>(body, _json);
        return (result, codeVerifier);
    }

    public async Task<(ApiResponse<PkceAuthorizationCodeResponse>? Result, string CodeVerifier)> EmailLoginAsync(
        string email, string password)
    {
        var codeVerifier = GenerateCodeVerifier();
        var codeChallenge = GenerateCodeChallenge(codeVerifier);

        var request = new
        {
            email,
            password,
            codeChallenge,
            codeChallengeMethod = "S256"
        };

        var response = await _http.PostAsJsonAsync("/auth/email/login", request);
        var body = await response.Content.ReadAsStringAsync();
        var result = JsonSerializer.Deserialize<ApiResponse<PkceAuthorizationCodeResponse>>(body, _json);
        return (result, codeVerifier);
    }

    public async Task<ApiResponse<PkceTokenResponse>?> ExchangePkceCodeAsync(
        string authorizationCode, string codeVerifier)
    {
        var request = new { authorizationCode, codeVerifier };
        var response = await _http.PostAsJsonAsync("/auth/pkce/token", request);
        var body = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<ApiResponse<PkceTokenResponse>>(body, _json);
    }

    public async Task<ApiResponse<RefreshTokenResponse>?> RefreshTokenAsync(string refreshToken)
    {
        var response = await _http.PostAsJsonAsync("/auth/refresh-token", new { refreshToken });
        var body = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<ApiResponse<RefreshTokenResponse>>(body, _json);
    }

    public async Task<ApiResponse<object>?> LogoutAsync()
    {
        var response = await _http.PostAsync("/auth/logout", null);
        var body = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<ApiResponse<object>>(body, _json);
    }

    public async Task<ApiResponse<SessionStatusDto>?> GetSessionStatusAsync()
    {
        var response = await _http.GetAsync("/auth/session-status");
        var body = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<ApiResponse<SessionStatusDto>>(body, _json);
    }

    public async Task<string> GetMeAsync()
    {
        var response = await _http.GetAsync("/auth/me");
        return await response.Content.ReadAsStringAsync();
    }

    public static string GenerateCodeVerifier()
    {
        var bytes = RandomNumberGenerator.GetBytes(32);
        return Base64UrlEncode(bytes);
    }

    public static string GenerateCodeChallenge(string codeVerifier)
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

    public void Dispose() => _http.Dispose();
}

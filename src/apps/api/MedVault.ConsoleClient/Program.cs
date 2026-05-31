using MedVault.ConsoleClient;
using MedVault.ConsoleClient.Services;
using Microsoft.Extensions.Configuration;

var config = new ConfigurationBuilder()
    .SetBasePath(AppContext.BaseDirectory)
    .AddJsonFile("appsettings.json", optional: true)
    .Build();

var medvaultApiUrl = config["Apis:MedVaultApi"] ?? "https://localhost:7200";
var documentApiUrl = config["Apis:DocumentApi"] ?? medvaultApiUrl;
var googleClientId = config["Google:ClientId"] ?? "";
var googleClientSecret = config["Google:ClientSecret"] ?? "";

using var api = new ApiClient(medvaultApiUrl);
using var docApi = new DocumentApiClient(documentApiUrl);

string? currentAccessToken = null;
string? currentRefreshToken = null;

ConsoleUI.WriteBanner(medvaultApiUrl, documentApiUrl);

var running = true;
while (running)
{
    ConsoleUI.WriteMainMenu(currentAccessToken is not null);
    var choice = Console.ReadLine()?.Trim();

    try
    {
        switch (choice)
        {
            case "1": await GoogleLogin(); break;
            case "2": await GoogleRegister(); break;
            case "3": await EmailRegister(); break;
            case "4": await EmailLogin(); break;
            case "5": await RefreshToken(); break;
            case "6": await GetSessionStatus(); break;
            case "7": await GetMe(); break;
            case "8": await Logout(); break;
            case "9": DecodeJwt(); break;
            case "10": await DocGetPublic(); break;
            case "11": await DocGetData(); break;
            case "12": await DocGetProfile(); break;
            case "13": await DocInvalidToken(); break;
            case "0":
                running = false;
                Console.WriteLine();
                ConsoleUI.WriteInfo("Goodbye!");
                break;
            default:
                ConsoleUI.WriteWarning("Invalid option. Try again.");
                break;
        }
    }
    catch (HttpRequestException ex)
    {
        ConsoleUI.WriteError($"Connection failed: {ex.Message}");
        ConsoleUI.WriteInfo("Make sure both APIs are running.");
    }
    catch (Exception ex)
    {
        ConsoleUI.WriteError($"{ex.GetType().Name}: {ex.Message}");
    }
}

async Task GoogleLogin()
{
    ConsoleUI.WriteHeader("Google Login");

    var idToken = await ObtainGoogleIdToken();
    if (idToken is null) return;

    ConsoleUI.WriteInfo($"Sending id_token to POST /auth/google ...");
    var result = await api.GoogleLoginAsync(idToken);

    if (result is null || !result.Success)
    {
        var errors = result?.Errors != null ? string.Join(", ", result.Errors) : result?.Message ?? "Unknown error";
        ConsoleUI.WriteError($"Google login failed: {errors}");
        ConsoleUI.WriteWarning("User may not be registered. Try option 2 (Google Register) first.");
        return;
    }

    var data = result.Data!;
    SetTokens(data.AccessToken, data.RefreshToken);

    ConsoleUI.WriteSuccess("Google login successful!");
    ConsoleUI.WriteInfo($"User ID:    {data.User.Id}");
    ConsoleUI.WriteInfo($"Email:      {data.User.Email}");
    ConsoleUI.WriteInfo($"Name:       {data.User.FirstName} {data.User.LastName}");
    ConsoleUI.WriteInfo($"Expires At: {data.AccessTokenExpiresAt:u}");
    ConsoleUI.WriteInfo($"Is New:     {data.IsNewUser}");
}

async Task GoogleRegister()
{
    ConsoleUI.WriteHeader("Google Register");

    var idToken = await ObtainGoogleIdToken();
    if (idToken is null) return;

    var firstName = ConsoleUI.Prompt("First Name");
    var lastName = ConsoleUI.Prompt("Last Name");

    ConsoleUI.WriteInfo("Sending registration to POST /auth/google/register ...");
    var result = await api.GoogleRegisterAsync(idToken, firstName, lastName);

    if (result is null || !result.Success)
    {
        var errors = result?.Errors != null ? string.Join(", ", result.Errors) : result?.Message ?? "Unknown error";
        ConsoleUI.WriteError($"Registration failed: {errors}");
        return;
    }

    var data = result.Data!;
    ConsoleUI.WriteSuccess("Registration successful!");
    ConsoleUI.WriteInfo($"User ID:    {data.User.Id}");
    ConsoleUI.WriteInfo($"Email:      {data.User.Email}");
    ConsoleUI.WriteInfo($"Name:       {data.User.FirstName} {data.User.LastName}");

    ConsoleUI.WriteInfo("Performing automatic Google login to obtain session tokens ...");
    var loginResult = await api.GoogleLoginAsync(idToken);

    if (loginResult is null || !loginResult.Success || loginResult.Data is null)
    {
        var loginErrors = loginResult?.Errors != null ? string.Join(", ", loginResult.Errors) : loginResult?.Message ?? "Unknown error";
        ConsoleUI.WriteError($"Automatic login failed after registration: {loginErrors}");
        return;
    }

    var loginData = loginResult.Data;
    SetTokens(loginData.AccessToken, loginData.RefreshToken);
    ConsoleUI.WriteSuccess("Automatic login successful!");
    ConsoleUI.WriteInfo($"Expires At: {loginData.AccessTokenExpiresAt:u}");
}

async Task EmailRegister()
{
    ConsoleUI.WriteHeader("Email Register (PKCE Flow)");

    var email = ConsoleUI.Prompt("Email");
    var password = ConsoleUI.PromptSecret("Password");
    var firstName = ConsoleUI.Prompt("First Name");
    var lastName = ConsoleUI.Prompt("Last Name");

    ConsoleUI.WriteInfo("Step 1/2: Registering and obtaining authorization code ...");
    var (authResult, codeVerifier) = await api.EmailRegisterAsync(email, password, firstName, lastName);

    if (authResult is null || !authResult.Success || authResult.Data is null)
    {
        var errors = authResult?.Errors != null ? string.Join(", ", authResult.Errors) : authResult?.Message ?? "Unknown error";
        ConsoleUI.WriteError($"Registration failed: {errors}");
        return;
    }

    var authCode = authResult.Data.AuthorizationCode;
    ConsoleUI.WriteSuccess($"Authorization code received (expires in {authResult.Data.ExpiresInSeconds}s)");
    ConsoleUI.WriteInfo($"Is New User: {authResult.Data.IsNewUser}");

    ConsoleUI.WriteInfo("Step 2/2: Exchanging authorization code + PKCE verifier for tokens ...");
    var tokenResult = await api.ExchangePkceCodeAsync(authCode, codeVerifier);

    if (tokenResult is null || !tokenResult.Success || tokenResult.Data is null)
    {
        var errors = tokenResult?.Errors != null ? string.Join(", ", tokenResult.Errors) : tokenResult?.Message ?? "Unknown error";
        ConsoleUI.WriteError($"Token exchange failed: {errors}");
        return;
    }

    var data = tokenResult.Data;
    SetTokens(data.AccessToken, data.RefreshToken);

    ConsoleUI.WriteSuccess("Email registration + PKCE complete!");
    ConsoleUI.WriteInfo($"User ID:    {data.User.Id}");
    ConsoleUI.WriteInfo($"Email:      {data.User.Email}");
    ConsoleUI.WriteInfo($"Name:       {data.User.FirstName} {data.User.LastName}");
    ConsoleUI.WriteInfo($"Expires At: {data.AccessTokenExpiresAt:u}");
}

async Task EmailLogin()
{
    ConsoleUI.WriteHeader("Email Login (PKCE Flow)");

    var email = ConsoleUI.Prompt("Email");
    var password = ConsoleUI.PromptSecret("Password");

    ConsoleUI.WriteInfo("Step 1/2: Authenticating and obtaining authorization code ...");
    var (authResult, codeVerifier) = await api.EmailLoginAsync(email, password);

    if (authResult is null || !authResult.Success || authResult.Data is null)
    {
        var errors = authResult?.Errors != null ? string.Join(", ", authResult.Errors) : authResult?.Message ?? "Unknown error";
        ConsoleUI.WriteError($"Login failed: {errors}");
        return;
    }

    var authCode = authResult.Data.AuthorizationCode;
    ConsoleUI.WriteSuccess($"Authorization code received (expires in {authResult.Data.ExpiresInSeconds}s)");

    ConsoleUI.WriteInfo("Step 2/2: Exchanging authorization code + PKCE verifier for tokens ...");
    var tokenResult = await api.ExchangePkceCodeAsync(authCode, codeVerifier);

    if (tokenResult is null || !tokenResult.Success || tokenResult.Data is null)
    {
        var errors = tokenResult?.Errors != null ? string.Join(", ", tokenResult.Errors) : tokenResult?.Message ?? "Unknown error";
        ConsoleUI.WriteError($"Token exchange failed: {errors}");
        return;
    }

    var data = tokenResult.Data;
    SetTokens(data.AccessToken, data.RefreshToken);

    ConsoleUI.WriteSuccess("Email login + PKCE complete!");
    ConsoleUI.WriteInfo($"User ID:    {data.User.Id}");
    ConsoleUI.WriteInfo($"Email:      {data.User.Email}");
    ConsoleUI.WriteInfo($"Expires At: {data.AccessTokenExpiresAt:u}");
}

async Task RefreshToken()
{
    ConsoleUI.WriteHeader("Refresh Token");

    if (currentRefreshToken is null)
    {
        ConsoleUI.WriteWarning("No refresh token available. Login first.");
        return;
    }

    ConsoleUI.WriteInfo("Sending refresh token to POST /auth/refresh-token ...");
    var result = await api.RefreshTokenAsync(currentRefreshToken);

    if (result is null || !result.Success || result.Data is null)
    {
        var errors = result?.Errors != null ? string.Join(", ", result.Errors) : result?.Message ?? "Unknown error";
        ConsoleUI.WriteError($"Refresh failed: {errors}");
        return;
    }

    var data = result.Data;
    SetTokens(data.AccessToken, data.RefreshToken);

    ConsoleUI.WriteSuccess("Tokens refreshed!");
    ConsoleUI.WriteInfo($"New access token:  {TokenHelper.Truncate(data.AccessToken)}");
    ConsoleUI.WriteInfo($"Expires At:        {data.AccessTokenExpiresAt:u}");
}

async Task GetSessionStatus()
{
    ConsoleUI.WriteHeader("Session Status");

    if (!RequireAuth()) return;

    var result = await api.GetSessionStatusAsync();

    if (result is null || !result.Success || result.Data is null)
    {
        var msg = result?.Message ?? "No active session found.";
        ConsoleUI.WriteWarning(msg);
        return;
    }

    var data = result.Data;
    ConsoleUI.WriteSuccess("Session found:");
    ConsoleUI.WriteInfo($"Session ID: {data.SessionId}");
    ConsoleUI.WriteInfo($"User ID:    {data.UserId}");
    ConsoleUI.WriteInfo($"Created At: {data.CreatedAt:u}");
    ConsoleUI.WriteInfo($"Expires At: {data.ExpiresAt:u}");
    ConsoleUI.WriteInfo($"Is Active:  {data.IsActive}");
    ConsoleUI.WriteInfo($"Device:     {data.DeviceInfo ?? "N/A"}");
}

async Task GetMe()
{
    ConsoleUI.WriteHeader("GET /auth/me — JWT Claims");

    if (!RequireAuth()) return;

    var body = await api.GetMeAsync();
    ConsoleUI.WriteJson("JWT claims from /auth/me:", body);
}

async Task Logout()
{
    ConsoleUI.WriteHeader("Logout");

    if (!RequireAuth()) return;

    var result = await api.LogoutAsync();

    if (result is not null && result.Success)
    {
        ClearTokens();
        ConsoleUI.WriteSuccess("Logged out successfully.");
    }
    else
    {
        ConsoleUI.WriteError($"Logout failed: {result?.Message ?? "Unknown error"}");
    }
}

void DecodeJwt()
{
    ConsoleUI.WriteHeader("Decode Current JWT");

    if (currentAccessToken is null)
    {
        ConsoleUI.WriteWarning("No access token available. Login first.");
        return;
    }

    TokenHelper.DisplayDecodedJwt(currentAccessToken);
}

async Task DocGetPublic()
{
    ConsoleUI.WriteHeader("Document endpoints — GET /public (no auth)");

    var (statusCode, body) = await docApi.GetPublicAsync();
    ConsoleUI.WriteStatusCode(statusCode, "GET /public");
    if (statusCode is >= 200 and < 300)
        ConsoleUI.WriteJson("Response:", body);
    else
        ConsoleUI.WriteError(body);
}

async Task DocGetData()
{
    ConsoleUI.WriteHeader("Document endpoints — GET /data (auth required)");

    if (!RequireAuth()) return;

    var (statusCode, body) = await docApi.GetDataAsync();
    ConsoleUI.WriteStatusCode(statusCode, "GET /data");
    if (statusCode is >= 200 and < 300)
        ConsoleUI.WriteJson("Protected data received:", body);
    else
        ConsoleUI.WriteError($"Access denied ({statusCode}): {body}");
}

async Task DocGetProfile()
{
    ConsoleUI.WriteHeader("Document endpoints — GET /data/profile (auth required)");

    if (!RequireAuth()) return;

    var (statusCode, body) = await docApi.GetDataProfileAsync();
    ConsoleUI.WriteStatusCode(statusCode, "GET /data/profile");
    if (statusCode is >= 200 and < 300)
        ConsoleUI.WriteJson("Profile data:", body);
    else
        ConsoleUI.WriteError($"Access denied ({statusCode}): {body}");
}

async Task DocInvalidToken()
{
    ConsoleUI.WriteHeader("Document endpoints — GET /data with Invalid Token");

    var (statusCode, body) = await docApi.GetDataWithInvalidTokenAsync();
    ConsoleUI.WriteStatusCode(statusCode, "GET /data (invalid token)");

    if (statusCode == 401)
        ConsoleUI.WriteSuccess("Correctly rejected invalid token (401 Unauthorized)");
    else
        ConsoleUI.WriteWarning($"Unexpected status: {statusCode} — {body}");
}

async Task<string?> ObtainGoogleIdToken()
{
    if (!string.IsNullOrWhiteSpace(googleClientId) && !googleClientId.StartsWith("YOUR"))
    {
        try
        {
            var browserAuth = new GoogleBrowserAuth(googleClientId, googleClientSecret);
            var tokenResult = await browserAuth.AuthenticateAsync();
            ConsoleUI.WriteSuccess($"Google id_token obtained via browser!");
            ConsoleUI.WriteInfo($"Token: {TokenHelper.Truncate(tokenResult.IdToken)}");
            return tokenResult.IdToken;
        }
        catch (Exception ex)
        {
            ConsoleUI.WriteError($"Browser auth failed: {ex.Message}");
            ConsoleUI.WriteInfo("Falling back to manual entry.");
        }
    }
    else
    {
        ConsoleUI.WriteWarning("Google ClientId not configured in appsettings.json.");
        ConsoleUI.WriteInfo("Falling back to manual token entry.");
    }

    Console.WriteLine();
    var input = ConsoleUI.Prompt("Paste your Google id_token (or press Enter to cancel)");
    if (string.IsNullOrWhiteSpace(input))
    {
        ConsoleUI.WriteWarning("Cancelled.");
        return null;
    }
    return input;
}

void SetTokens(string accessToken, string refreshToken)
{
    currentAccessToken = accessToken;
    currentRefreshToken = refreshToken;

    api.SetBearerToken(accessToken);
    docApi.SetBearerToken(accessToken);

    ConsoleUI.WriteInfo($"Access token:  {TokenHelper.Truncate(accessToken)}");
    ConsoleUI.WriteInfo($"Refresh token: {TokenHelper.Truncate(refreshToken)}");
}

void ClearTokens()
{
    currentAccessToken = null;
    currentRefreshToken = null;

    api.ClearBearerToken();
    docApi.ClearBearerToken();
}

bool RequireAuth()
{
    if (currentAccessToken is not null) return true;
    ConsoleUI.WriteWarning("Not authenticated. Login first (options 1-4).");
    return false;
}

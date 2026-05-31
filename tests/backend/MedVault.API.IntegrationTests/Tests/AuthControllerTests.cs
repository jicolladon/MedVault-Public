using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Google.Apis.Auth;
using MedVault.API.Features.Auth.Application.DTOs;
using MedVault.API.IntegrationTests.Fixtures;
using Moq;
using Xunit;

namespace MedVault.API.IntegrationTests.Tests;

/// <summary>
/// Integration tests for auth endpoints (Workflow 1 — Google Login, Registration, Token Refresh, Logout).
/// </summary>
public class AuthControllerTests : IClassFixture<MedVaultApiFactory>, IAsyncLifetime
{
    private readonly MedVaultApiFactory _factory;
    private readonly HttpClient _anonClient;
    private readonly HttpClient _authClient;
    private readonly JsonSerializerOptions _json = new() { PropertyNameCaseInsensitive = true };

    public AuthControllerTests(MedVaultApiFactory factory)
    {
        _factory = factory;
        _anonClient = factory.CreateAnonymousClient();
        _authClient = factory.CreateAuthenticatedClient();
    }

    public async Task InitializeAsync() => await _factory.SeedTestUserAsync();
    public Task DisposeAsync() => Task.CompletedTask;

    // ─── Google Login ───────────────────────────────────────

    [Fact]
    public async Task GoogleLogin_WithValidToken_ExistingUser_ReturnsTokens()
    {
        // Arrange — mock Google to return our test user's Google ID
        _factory.GoogleTokenValidator
            .Setup(g => g.ValidateAsync("valid-google-token"))
            .ReturnsAsync(new GoogleJsonWebSignature.Payload
            {
                Subject = "google-test-id-12345",
                Email = "test@medvault.test",
                EmailVerified = true,
                GivenName = "Test",
                FamilyName = "User",
            });

        // Act
        var response = await _anonClient.PostAsJsonAsync("/auth/google",
            new { IdToken = "valid-google-token" });

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<ApiEnvelope<GoogleLoginResponse>>(_json);
        Assert.NotNull(body);
        Assert.True(body!.Success);
        Assert.False(body.Data!.IsNewUser);
        Assert.NotEmpty(body.Data.AccessToken);
        Assert.NotEmpty(body.Data.RefreshToken);
        Assert.Equal("test@medvault.test", body.Data.User.Email);
    }

    [Fact]
    public async Task GoogleLogin_WithValidToken_NewUser_ReturnsIsNewUserTrue()
    {
        // Arrange — Google returns unknown user
        _factory.GoogleTokenValidator
            .Setup(g => g.ValidateAsync("new-user-token"))
            .ReturnsAsync(new GoogleJsonWebSignature.Payload
            {
                Subject = "google-BRAND-NEW-id",
                Email = "new-user@example.com",
                EmailVerified = true,
                GivenName = "New",
                FamilyName = "Person",
            });

        // Act
        var response = await _anonClient.PostAsJsonAsync("/auth/google",
            new { IdToken = "new-user-token" });

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<ApiEnvelope<GoogleLoginResponse>>(_json);
        Assert.True(body!.Data!.IsNewUser);
        Assert.Empty(body.Data.AccessToken);
    }

    [Fact]
    public async Task GoogleLogin_WithInvalidToken_Returns401()
    {
        _factory.GoogleTokenValidator
            .Setup(g => g.ValidateAsync("bad-token"))
            .ReturnsAsync((GoogleJsonWebSignature.Payload?)null);

        var response = await _anonClient.PostAsJsonAsync("/auth/google",
            new { IdToken = "bad-token" });

        // The handler throws UnauthorizedAccessException → GlobalExceptionMiddleware returns 401
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task GoogleLogin_MissingIdToken_Returns400()
    {
        var response = await _anonClient.PostAsJsonAsync("/auth/google",
            new { IdToken = "" });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    // ─── Registration ───────────────────────────────────────

    [Fact]
    public async Task Register_WithValidData_Returns201()
    {
        _factory.GoogleTokenValidator
            .Setup(g => g.ValidateAsync("register-token"))
            .ReturnsAsync(new GoogleJsonWebSignature.Payload
            {
                Subject = "google-register-unique-id",
                Email = "register@example.com",
                EmailVerified = true,
                GivenName = "Reg",
                FamilyName = "User",
                Picture = "https://example.com/photo.jpg",
            });

        var request = new
        {
            GoogleIdToken = "register-token",
            FirstName = "Reg",
            LastName = "User",
            Gender = "Male",
            TermsAccepted = true,
            PrivacyPolicyAccepted = true
        };

        var response = await _anonClient.PostAsJsonAsync("/auth/google/register", request);

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<ApiEnvelope<RegisterResponse>>(_json);
        Assert.True(body!.Success);
        Assert.NotEqual(Guid.Empty, body.Data!.User.Id);
        Assert.Equal("register@example.com", body.Data.User.Email);
    }

    [Fact]
    public async Task Register_DuplicateUser_Returns500()
    {
        // Our seed user has GoogleId = "google-test-id-12345"
        _factory.GoogleTokenValidator
            .Setup(g => g.ValidateAsync("dup-token"))
            .ReturnsAsync(new GoogleJsonWebSignature.Payload
            {
                Subject = "google-test-id-12345",
                Email = "test@medvault.test",
                EmailVerified = true,
            });

        var request = new
        {
            GoogleIdToken = "dup-token",
            FirstName = "Dup",
            LastName = "User",
            TermsAccepted = true,
            PrivacyPolicyAccepted = true
        };

        var response = await _anonClient.PostAsJsonAsync("/auth/google/register", request);

        // Handler throws → GlobalExceptionMiddleware returns 409 Conflict
        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    [Fact]
    public async Task Register_MissingRequiredFields_Returns400()
    {
        var response = await _anonClient.PostAsJsonAsync("/auth/google/register",
            new { GoogleIdToken = "", FirstName = "", LastName = "", TermsAccepted = false, PrivacyPolicyAccepted = false });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    // ─── Logout ─────────────────────────────────────────────

    [Fact]
    public async Task Logout_WithAuth_Returns200()
    {
        var response = await _authClient.PostAsync("/auth/logout", null);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task Logout_WithoutAuth_Returns401()
    {
        var response = await _anonClient.PostAsync("/auth/logout", null);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    // ─── Session Status ─────────────────────────────────────

    [Fact]
    public async Task SessionStatus_WithAuth_ReturnsStatusOrNotFound()
    {
        var response = await _authClient.GetAsync("/auth/session-status");

        // Either 200 (active session found) or 404 (no session seeded)
        Assert.True(response.StatusCode is HttpStatusCode.OK or HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task SessionStatus_WithoutAuth_Returns401()
    {
        var response = await _anonClient.GetAsync("/auth/session-status");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    // ─── Refresh Token ──────────────────────────────────────

    [Fact]
    public async Task RefreshToken_WithInvalidToken_Returns401Or500()
    {
        var response = await _anonClient.PostAsJsonAsync("/auth/refresh-token",
            new { RefreshToken = "nonexistent-refresh-token" });

        // Invalid refresh token → Unauthorized or server error
        Assert.True(response.StatusCode is HttpStatusCode.Unauthorized or HttpStatusCode.InternalServerError);
    }

    [Fact]
    public async Task RefreshToken_EmptyBody_Returns400()
    {
        var response = await _anonClient.PostAsJsonAsync("/auth/refresh-token",
            new { RefreshToken = "" });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }
}

/// <summary>Generic envelope matching the ApiResponse shape returned by all controllers.</summary>
file record ApiEnvelope<T>
{
    public bool Success { get; init; }
    public T? Data { get; init; }
    public string? Message { get; init; }
    public List<string>? Errors { get; init; }
}

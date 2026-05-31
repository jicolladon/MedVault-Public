using MedVault.API.IntegrationTests.Fixtures;
using Microsoft.AspNetCore.Mvc.Testing;
using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Xunit;

namespace MedVault.API.IntegrationTests.Tests;

public class SharingPortalControllerTests : IClassFixture<MedVaultApiFactory>, IAsyncLifetime
{
    private readonly MedVaultApiFactory _factory;
    private readonly HttpClient _authClient;
    private readonly HttpClient _anonClient;

    public SharingPortalControllerTests(MedVaultApiFactory factory)
    {
        _factory = factory;
        _authClient = factory.CreateAuthenticatedClient();
        _anonClient = factory.CreateAnonymousClient();
    }

    public async Task InitializeAsync()
    {
        await _factory.SeedTestUserAsync();
    }

    public Task DisposeAsync() => Task.CompletedTask;

    [Fact]
    public async Task GetSharePortal_WithProtectedLink_ShowsUnlockForm()
    {
        var token = await CreateProtectedShareTokenAsync(requiresTwoFactorApproval: false);

        var response = await _anonClient.GetAsync($"/share/{token}");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var html = await response.Content.ReadAsStringAsync();
        Assert.Contains("name=\"ViewerName\"", html);
        Assert.Contains("name=\"AccessPassword\"", html);
    }

    [Fact]
    public async Task GetSharePortal_WithTwoFactorApproval_DoesNotShowVerificationInput()
    {
        var token = await CreateProtectedShareTokenAsync(requiresTwoFactorApproval: true);

        var response = await _anonClient.GetAsync($"/share/{token}");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var html = await response.Content.ReadAsStringAsync();
        Assert.Contains("name=\"ViewerName\"", html);
        Assert.Contains("name=\"AccessPassword\"", html);
        Assert.DoesNotContain("name=\"VerificationCode\"", html);
    }

    [Fact]
    public async Task PostSharePortal_WithValidCredentials_ShowsSharedInformation()
    {
        var token = await CreateProtectedShareTokenAsync(requiresTwoFactorApproval: false);

        var response = await _anonClient.PostAsync(
            $"/share/{token}",
            new FormUrlEncodedContent(
            [
                new KeyValuePair<string, string>("ViewerName", "Casey Gray"),
                new KeyValuePair<string, string>("AccessPassword", "Responder#2026"),
            ]));

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var html = await response.Content.ReadAsStringAsync();
        Assert.Contains("Test User", html);
        Assert.Contains("Emergency contact", html, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("Latest CBC Report", html);
    }

    [Fact]
    public async Task PostSharePortal_WithWrongCredentials_Returns401()
    {
        var token = await CreateProtectedShareTokenAsync(requiresTwoFactorApproval: false);

        var response = await _anonClient.PostAsync(
            $"/share/{token}",
            new FormUrlEncodedContent(
            [
                new KeyValuePair<string, string>("ViewerName", "Casey Gray"),
                new KeyValuePair<string, string>("AccessPassword", "wrong-password"),
            ]));

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);

        var html = await response.Content.ReadAsStringAsync();
        Assert.Contains("credentials", html, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task PostSharePortal_WithoutViewerName_Returns400()
    {
        var token = await CreateProtectedShareTokenAsync(requiresTwoFactorApproval: false);

        var response = await _anonClient.PostAsync(
            $"/share/{token}",
            new FormUrlEncodedContent(
            [
                new KeyValuePair<string, string>("AccessPassword", "Responder#2026"),
            ]));

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);

        var html = await response.Content.ReadAsStringAsync();
        Assert.Contains("Please enter your name", html, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task GetSharePortal_DemoMode_ReturnsDemoContent()
    {
        var response = await _anonClient.GetAsync("/share/demo");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var html = await response.Content.ReadAsStringAsync();
        Assert.Contains("Demo Mode", html);
        Assert.Contains("Alex Morgan", html);
    }

    private async Task<string> CreateProtectedShareTokenAsync(bool requiresTwoFactorApproval)
    {
        var response = await _authClient.PostAsJsonAsync(
            "/api/user/sharing/physician-links",
            new
            {
                Label = "Emergency physician access",
                PhysicianName = "Dr. Jordan Lee",
                PhysicianEmail = "jordan.lee@example.com",
                Notes = "Urgent assessment",
                Scopes = new[] { "personalInformation", "bloodType", "emergencyContact", "medicalHistory", "medicalDocuments" },
                SharedSnapshot = new
                {
                    PatientInfo = new
                    {
                        DisplayName = "Test User",
                        Initials = "TU",
                        DateOfBirth = "1988-10-11",
                        BloodType = "A+",
                        EmergencyContactName = "Casey Contact",
                        EmergencyContactPhone = "+1-555-7777",
                        EmergencyContactRelationship = "Sibling",
                    },
                    MedicalSummary = new
                    {
                        Allergies = new[]
                        {
                            new
                            {
                                Id = "a1",
                                AllergenName = "Penicillin",
                                AllergyType = "Medication",
                                Severity = "High",
                                IsActive = true,
                            },
                        },
                    },
                    MedicalHistory = new[]
                    {
                        new
                        {
                            Id = "h1",
                            Date = "2026-04-01",
                            Type = "LabResult",
                            Title = "Complete blood count",
                        },
                    },
                    Documents = new[]
                    {
                        new
                        {
                            Id = "d1",
                            Title = "Latest CBC Report",
                            Category = "Lab Results",
                            Description = "CBC panel with differential",
                            DownloadUrl = "https://example.invalid/cbc-report.pdf",
                            UploadedAt = "2026-04-01",
                        },
                    },
                },
                SecuritySettings = new
                {
                    AccessDurationMinutes = 60,
                    PasswordProtected = true,
                    AccessPassword = "Responder#2026",
                    RequiresTwoFactorApproval = requiresTwoFactorApproval,
                    AllowDownload = false,
                    NotifyOnAccess = true,
                },
            });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var payload = await response.Content.ReadAsStringAsync();
        using var document = JsonDocument.Parse(payload);

        var shareUrl = document.RootElement
            .GetProperty("data")
            .GetProperty("shareUrl")
            .GetString();

        Assert.False(string.IsNullOrWhiteSpace(shareUrl));

        var uri = new Uri(shareUrl!, UriKind.Absolute);
        var segment = uri.Segments.Last().Trim('/');

        if (uri.AbsolutePath.StartsWith("/share/", StringComparison.OrdinalIgnoreCase))
        {
            return segment;
        }

        if (uri.AbsolutePath.StartsWith("/s/", StringComparison.OrdinalIgnoreCase))
        {
            var redirectClient = _factory.CreateClient(new WebApplicationFactoryClientOptions
            {
                AllowAutoRedirect = false,
            });

            var resolveResponse = await redirectClient.GetAsync($"/s/{segment}");
            Assert.Equal(HttpStatusCode.Redirect, resolveResponse.StatusCode);

            var location = resolveResponse.Headers.Location;
            Assert.NotNull(location);
            Assert.StartsWith("/share/", location!.OriginalString, StringComparison.OrdinalIgnoreCase);

            return location.OriginalString.Split('/', StringSplitOptions.RemoveEmptyEntries).Last();
        }

        throw new InvalidOperationException($"Unexpected share URL format: {shareUrl}");
    }
}

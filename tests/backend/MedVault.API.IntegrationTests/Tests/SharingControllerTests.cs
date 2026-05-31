using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using MedVault.API.IntegrationTests.Fixtures;
using Xunit;

namespace MedVault.API.IntegrationTests.Tests;

public class SharingControllerTests : IClassFixture<MedVaultApiFactory>, IAsyncLifetime
{
    private readonly MedVaultApiFactory _factory;
    private readonly HttpClient _authClient;
    private readonly HttpClient _anonClient;

    public SharingControllerTests(MedVaultApiFactory factory)
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
    public async Task GetSharedData_WithSnapshot_ReturnsSelectedMedicalContent()
    {
        var token = await CreateProtectedShareTokenAsync(requiresTwoFactorApproval: false);

        var response = await _anonClient.GetAsync(
            $"/api/sharing/{token}?accessPassword=Responder%232026");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        var data = document.RootElement.GetProperty("data");

        Assert.Equal("A+", data.GetProperty("patientInfo").GetProperty("bloodType").GetString());
        Assert.Equal(1, data.GetProperty("medicalSummary").GetProperty("allergies").GetArrayLength());
        Assert.Equal(1, data.GetProperty("documents").GetArrayLength());
        Assert.Equal(
            "Latest CBC Report",
            data.GetProperty("documents")[0].GetProperty("title").GetString());
    }

    [Fact]
    public async Task TwoFactorApprovalFlow_AllowsAccessWithoutVerificationCode()
    {
        var token = await CreateProtectedShareTokenAsync(requiresTwoFactorApproval: true);

        var blockedResponse = await _anonClient.GetAsync(
            $"/api/sharing/{token}?accessPassword=Responder%232026");
        Assert.Equal(HttpStatusCode.Unauthorized, blockedResponse.StatusCode);

        var requestResponse = await _anonClient.PostAsJsonAsync(
            $"/api/sharing/{token}/2fa/request",
            new
            {
                ViewerName = "Dr. Casey Gray",
                AccessPassword = "Responder#2026",
            });

        Assert.Equal(HttpStatusCode.OK, requestResponse.StatusCode);

        using var requestPayload = JsonDocument.Parse(await requestResponse.Content.ReadAsStringAsync());
        var requestId = requestPayload.RootElement
            .GetProperty("data")
            .GetProperty("requestId")
            .GetGuid();

        var pendingResponse = await _anonClient.GetAsync(
            $"/api/sharing/{token}?accessPassword=Responder%232026&accessRequestId={requestId}");
        Assert.Equal(HttpStatusCode.Unauthorized, pendingResponse.StatusCode);

        var approveResponse = await _authClient.PostAsJsonAsync(
            $"/api/user/sharing/two-factor-requests/{requestId}/decision",
            new { Approved = true });
        Assert.Equal(HttpStatusCode.OK, approveResponse.StatusCode);

        var allowedResponse = await _anonClient.GetAsync(
            $"/api/sharing/{token}?accessPassword=Responder%232026&accessRequestId={requestId}");
        Assert.Equal(HttpStatusCode.OK, allowedResponse.StatusCode);
    }

    private async Task<string> CreateProtectedShareTokenAsync(bool requiresTwoFactorApproval)
    {
        var response = await _authClient.PostAsJsonAsync(
            "/api/user/sharing/physician-links",
            new
            {
                Label = "Clinical handoff",
                PhysicianName = "Dr. Jordan Lee",
                PhysicianEmail = "jordan.lee@example.com",
                Notes = "Urgent assessment",
                Scopes = new[]
                {
                    "personalInformation",
                    "bloodType",
                    "medicalInformation",
                    "allergies",
                    "medicalDocuments",
                },
                SharedSnapshot = new
                {
                    PatientInfo = new
                    {
                        DisplayName = "Test User",
                        Initials = "TU",
                        DateOfBirth = "1988-10-11",
                        BloodType = "A+",
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

        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
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

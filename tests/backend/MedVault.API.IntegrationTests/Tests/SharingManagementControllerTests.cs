using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.DependencyInjection;
using MedVault.API.Features.Configuration.Application.DTOs;
using MedVault.API.Features.Configuration.Application.Services;
using MedVault.API.Features.Sharing.Application.DTOs;
using MedVault.API.IntegrationTests.Fixtures;
using Xunit;

namespace MedVault.API.IntegrationTests.Tests;

/// <summary>
/// Integration tests for authenticated sharing management endpoints.
/// </summary>
public class SharingManagementControllerTests : IClassFixture<MedVaultApiFactory>, IAsyncLifetime
{
    private readonly MedVaultApiFactory _factory;
    private readonly HttpClient _authClient;
    private readonly HttpClient _anonClient;
    private readonly JsonSerializerOptions _json = new()
    {
        PropertyNameCaseInsensitive = true,
    };

    public SharingManagementControllerTests(MedVaultApiFactory factory)
    {
        _factory = factory;
        _authClient = factory.CreateAuthenticatedClient();
        _anonClient = factory.CreateAnonymousClient();
    }

    public async Task InitializeAsync()
    {
        await _factory.SeedTestUserAsync();
        await ResetSharingFeatureSettingsAsync();
    }

    public Task DisposeAsync() => Task.CompletedTask;

    private async Task RevokeAllExistingLinksAsync()
    {
        var listResponse = await _authClient.GetAsync("/api/user/sharing/links");
        Assert.Equal(HttpStatusCode.OK, listResponse.StatusCode);

        var listBody = await listResponse.Content
            .ReadFromJsonAsync<ApiEnvelope<List<SharingLinkClientResponse>>>(_json);

        Assert.NotNull(listBody?.Data);

        foreach (var link in listBody!.Data!.Where(item => !item.IsRevoked))
        {
            var revokeResponse = await _authClient.DeleteAsync($"/api/user/sharing/links/{link.LinkId}");
            Assert.Equal(HttpStatusCode.OK, revokeResponse.StatusCode);
        }
    }

    private Task ResetSharingFeatureSettingsAsync() =>
        UpdateSharingFeatureSettingsAsync(
            emergencySharingEnabled: true,
            physicianSharingEnabled: true,
            maxSharingLinksPerUser: 5,
            defaultMaxDocumentsToShare: 10,
            minDocumentsToShareLimit: 0,
            maxDocumentsToShareLimit: 10);

    private Task UpdateSharingFeatureSettingsAsync(
        bool emergencySharingEnabled,
        bool physicianSharingEnabled,
        int maxSharingLinksPerUser,
        int defaultMaxDocumentsToShare,
        int minDocumentsToShareLimit,
        int maxDocumentsToShareLimit)
    {
        using var scope = _factory.Services.CreateScope();
        var systemConfigurationService = scope.ServiceProvider
            .GetRequiredService<ISystemConfigurationService>();

        systemConfigurationService.UpdateSharingSettings(new UpdateSharingFeatureSettingsRequest
        {
            EmergencySharingEnabled = emergencySharingEnabled,
            PhysicianSharingEnabled = physicianSharingEnabled,
            MaxSharingLinksPerUser = maxSharingLinksPerUser,
            DefaultMaxDocumentsToShare = defaultMaxDocumentsToShare,
            MinDocumentsToShareLimit = minDocumentsToShareLimit,
            MaxDocumentsToShareLimit = maxDocumentsToShareLimit,
        });

        return Task.CompletedTask;
    }

    [Fact]
    public async Task GetLinks_Unauthenticated_Returns401()
    {
        var response = await _anonClient.GetAsync("/api/user/sharing/links");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task CreateEmergencyLink_ThenList_ReturnsCreatedLink()
    {
        var createResponse = await _authClient.PostAsJsonAsync(
            "/api/user/sharing/emergency-links",
            new
            {
                Label = "Emergency Team",
                Scopes = new[] { "bloodType", "allergies", "emergencyContact" },
                SharedSnapshot = new
                {
                    PatientInfo = new
                    {
                        DisplayName = "Test User",
                        Initials = "TU",
                        BloodType = "A+",
                        EmergencyContactName = "Alex Contact",
                        EmergencyContactPhone = "+1-555-1000",
                    },
                },
                SecuritySettings = new
                {
                    AccessDurationMinutes = 120,
                    PasswordProtected = false,
                    RequiresTwoFactorApproval = false,
                    AllowDownload = false,
                    NotifyOnAccess = true,
                },
            });

        Assert.Equal(HttpStatusCode.OK, createResponse.StatusCode);

        var createBody = await createResponse.Content
            .ReadFromJsonAsync<ApiEnvelope<SharingLinkClientResponse>>(_json);

        Assert.True(createBody!.Success);
        Assert.NotNull(createBody.Data);
        Assert.Equal("Emergency", createBody.Data!.ShareType);
        Assert.False(string.IsNullOrWhiteSpace(createBody.Data.ShareCode));
        Assert.False(string.IsNullOrWhiteSpace(createBody.Data.ShareUrl));
        Assert.Contains("bloodType", createBody.Data.Scopes);

        var listResponse = await _authClient.GetAsync("/api/user/sharing/links");

        Assert.Equal(HttpStatusCode.OK, listResponse.StatusCode);

        var listBody = await listResponse.Content
            .ReadFromJsonAsync<ApiEnvelope<List<SharingLinkClientResponse>>>(_json);

        Assert.True(listBody!.Success);
        Assert.NotNull(listBody.Data);
        Assert.Contains(listBody.Data!, item => item.LinkId == createBody.Data.LinkId);
    }

    [Fact]
    public async Task CreatePhysician_UpdateAndRevoke_Works()
    {
        var createResponse = await _authClient.PostAsJsonAsync(
            "/api/user/sharing/physician-links",
            new
            {
                Label = "Cardiology Follow Up",
                PhysicianName = "Dr. Jane Smith",
                PhysicianEmail = "jane.smith@example.com",
                Notes = "Follow-up after recent lab work.",
                Scopes = new[] { "medicalInformation", "labResults" },
                SharedSnapshot = new
                {
                    PatientInfo = new
                    {
                        DisplayName = "Test User",
                        Initials = "TU",
                        BloodType = "A+",
                    },
                    MedicalHistory = new[]
                    {
                        new
                        {
                            Id = "h1",
                            Date = "2026-04-01",
                            Type = "LabResult",
                            Title = "CBC",
                        },
                    },
                },
                SecuritySettings = new
                {
                    AccessDurationMinutes = 1440,
                    PasswordProtected = true,
                    AccessPassword = "Responder#2026",
                    RequiresTwoFactorApproval = true,
                    AllowDownload = false,
                    NotifyOnAccess = true,
                },
            });

        Assert.Equal(HttpStatusCode.OK, createResponse.StatusCode);

        var createBody = await createResponse.Content
            .ReadFromJsonAsync<ApiEnvelope<SharingLinkClientResponse>>(_json);

        Assert.True(createBody!.Success);
        var link = createBody.Data!;
        Assert.Equal("Regular", link.ShareType);
        Assert.Equal("Dr. Jane Smith", link.RecipientName);
        Assert.Equal("jane.smith@example.com", link.RecipientEmail);

        var updateResponse = await _authClient.PutAsJsonAsync(
            $"/api/user/sharing/links/{link.LinkId}",
            new
            {
                Label = "Updated label",
                Scopes = new[] { "medicalInformation", "medicalDocuments" },
                SecuritySettings = new
                {
                    AccessDurationMinutes = 60,
                    PasswordProtected = true,
                    RequiresTwoFactorApproval = false,
                    AllowDownload = true,
                    NotifyOnAccess = true,
                },
            });

        Assert.Equal(HttpStatusCode.OK, updateResponse.StatusCode);

        var updateBody = await updateResponse.Content
            .ReadFromJsonAsync<ApiEnvelope<SharingLinkClientResponse>>(_json);

        Assert.True(updateBody!.Success);
        Assert.Equal("Updated label", updateBody.Data!.Label);
        Assert.Contains("medicalDocuments", updateBody.Data.Scopes);
        Assert.Equal(60, updateBody.Data.SecuritySettings.AccessDurationMinutes);

        var revokeResponse = await _authClient.DeleteAsync($"/api/user/sharing/links/{link.LinkId}");

        Assert.Equal(HttpStatusCode.OK, revokeResponse.StatusCode);

        var listResponse = await _authClient.GetAsync("/api/user/sharing/links");
        var listBody = await listResponse.Content
            .ReadFromJsonAsync<ApiEnvelope<List<SharingLinkClientResponse>>>(_json);

        var revoked = listBody!.Data!.Single(item => item.LinkId == link.LinkId);
        Assert.True(revoked.IsRevoked);
        Assert.NotNull(revoked.RevokedAt);
    }

    [Fact]
    public async Task CreatePhysicianLink_WithPasswordProtectionAndMissingPassword_ReturnsBadRequest()
    {
        var response = await _authClient.PostAsJsonAsync(
            "/api/user/sharing/physician-links",
            new
            {
                Label = "Missing password",
                PhysicianName = "Dr. Jane Smith",
                PhysicianEmail = "jane.smith@example.com",
                Scopes = new[] { "medicalInformation" },
                SharedSnapshot = new
                {
                    PatientInfo = new
                    {
                        DisplayName = "Test User",
                        Initials = "TU",
                    },
                },
                SecuritySettings = new
                {
                    AccessDurationMinutes = 60,
                    PasswordProtected = true,
                    RequiresTwoFactorApproval = false,
                    AllowDownload = false,
                    NotifyOnAccess = true,
                },
            });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);

        var responseBody = await response.Content.ReadAsStringAsync();
        Assert.Contains("Access password is required", responseBody, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task CreatePhysicianLink_WithWeakPassword_ReturnsBadRequest()
    {
        var response = await _authClient.PostAsJsonAsync(
            "/api/user/sharing/physician-links",
            new
            {
                Label = "Weak password",
                PhysicianName = "Dr. Jane Smith",
                PhysicianEmail = "jane.smith@example.com",
                Scopes = new[] { "medicalInformation" },
                SharedSnapshot = new
                {
                    PatientInfo = new
                    {
                        DisplayName = "Test User",
                        Initials = "TU",
                    },
                },
                SecuritySettings = new
                {
                    AccessDurationMinutes = 60,
                    PasswordProtected = true,
                    AccessPassword = "password",
                    RequiresTwoFactorApproval = false,
                    AllowDownload = false,
                    NotifyOnAccess = true,
                },
            });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);

        var responseBody = await response.Content.ReadAsStringAsync();
        Assert.Contains("at least one letter and one number", responseBody, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task CreatePhysicianLink_WithMoreThanTenSharedDocuments_ReturnsBadRequest()
    {
        var documents = Enumerable.Range(1, 11)
            .Select(index => new
            {
                Id = $"doc-{index}",
                Title = $"Document {index}",
                Category = "Lab Results",
                FileName = $"result-{index}.pdf",
                ContentType = "application/pdf",
                UploadedAt = "2026-04-01",
            })
            .ToArray();

        var createResponse = await _authClient.PostAsJsonAsync(
            "/api/user/sharing/physician-links",
            new
            {
                Label = "Too many documents",
                PhysicianName = "Dr. Jane Smith",
                PhysicianEmail = "jane.smith@example.com",
                Scopes = new[] { "medicalInformation", "medicalDocuments" },
                SharedSnapshot = new
                {
                    PatientInfo = new
                    {
                        DisplayName = "Test User",
                        Initials = "TU",
                    },
                    Documents = documents,
                },
                SecuritySettings = new
                {
                    AccessDurationMinutes = 1440,
                    PasswordProtected = true,
                    AccessPassword = "Responder#2026",
                    RequiresTwoFactorApproval = false,
                    AllowDownload = false,
                    NotifyOnAccess = true,
                },
            });

        Assert.Equal(HttpStatusCode.BadRequest, createResponse.StatusCode);

        var responseBody = await createResponse.Content.ReadAsStringAsync();
        Assert.Contains("maximum of 10 shared documents", responseBody, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task CreateEmergencyLink_WhenEmergencySharingDisabled_ReturnsForbidden()
    {
        await UpdateSharingFeatureSettingsAsync(
            emergencySharingEnabled: false,
            physicianSharingEnabled: true,
            maxSharingLinksPerUser: 5,
            defaultMaxDocumentsToShare: 10,
            minDocumentsToShareLimit: 0,
            maxDocumentsToShareLimit: 10);

        var response = await _authClient.PostAsJsonAsync(
            "/api/user/sharing/emergency-links",
            new
            {
                Label = "Emergency Team",
                Scopes = new[] { "bloodType" },
                SharedSnapshot = new
                {
                    PatientInfo = new
                    {
                        DisplayName = "Test User",
                        Initials = "TU",
                        BloodType = "A+",
                    },
                },
                SecuritySettings = new
                {
                    AccessDurationMinutes = 120,
                    PasswordProtected = false,
                    RequiresTwoFactorApproval = false,
                    AllowDownload = false,
                    NotifyOnAccess = true,
                },
            });

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task CreatePhysicianLink_WhenDocumentSharingDisabled_ReturnsForbidden()
    {
        await UpdateSharingFeatureSettingsAsync(
            emergencySharingEnabled: true,
            physicianSharingEnabled: true,
            maxSharingLinksPerUser: 5,
            defaultMaxDocumentsToShare: 0,
            minDocumentsToShareLimit: 0,
            maxDocumentsToShareLimit: 0);

        var response = await _authClient.PostAsJsonAsync(
            "/api/user/sharing/physician-links",
            new
            {
                Label = "No docs allowed",
                PhysicianName = "Dr. Jane Smith",
                PhysicianEmail = "jane.smith@example.com",
                Scopes = new[] { "medicalDocuments" },
                SharedSnapshot = new
                {
                    PatientInfo = new
                    {
                        DisplayName = "Test User",
                        Initials = "TU",
                    },
                    Documents = new[]
                    {
                        new
                        {
                            Id = "doc-1",
                            Title = "Document 1",
                            Category = "Lab Results",
                            FileName = "result-1.pdf",
                            ContentType = "application/pdf",
                            UploadedAt = "2026-04-01",
                        },
                    },
                },
                SecuritySettings = new
                {
                    AccessDurationMinutes = 60,
                    PasswordProtected = false,
                    RequiresTwoFactorApproval = false,
                    AllowDownload = false,
                    NotifyOnAccess = true,
                },
            });

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task CreatePhysicianLink_WhenExceedsConfiguredDocumentLimit_ReturnsBadRequest()
    {
        await UpdateSharingFeatureSettingsAsync(
            emergencySharingEnabled: true,
            physicianSharingEnabled: true,
            maxSharingLinksPerUser: 5,
            defaultMaxDocumentsToShare: 2,
            minDocumentsToShareLimit: 0,
            maxDocumentsToShareLimit: 10);

        var response = await _authClient.PostAsJsonAsync(
            "/api/user/sharing/physician-links",
            new
            {
                Label = "Too many for configured limit",
                PhysicianName = "Dr. Jane Smith",
                PhysicianEmail = "jane.smith@example.com",
                Scopes = new[] { "medicalDocuments" },
                SharedSnapshot = new
                {
                    PatientInfo = new
                    {
                        DisplayName = "Test User",
                        Initials = "TU",
                    },
                    Documents = new[]
                    {
                        new
                        {
                            Id = "doc-1",
                            Title = "Document 1",
                            Category = "Lab Results",
                            FileName = "result-1.pdf",
                            ContentType = "application/pdf",
                            UploadedAt = "2026-04-01",
                        },
                        new
                        {
                            Id = "doc-2",
                            Title = "Document 2",
                            Category = "Lab Results",
                            FileName = "result-2.pdf",
                            ContentType = "application/pdf",
                            UploadedAt = "2026-04-01",
                        },
                        new
                        {
                            Id = "doc-3",
                            Title = "Document 3",
                            Category = "Lab Results",
                            FileName = "result-3.pdf",
                            ContentType = "application/pdf",
                            UploadedAt = "2026-04-01",
                        },
                    },
                },
                SecuritySettings = new
                {
                    AccessDurationMinutes = 60,
                    PasswordProtected = false,
                    RequiresTwoFactorApproval = false,
                    AllowDownload = false,
                    NotifyOnAccess = true,
                },
            });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);

        var responseBody = await response.Content.ReadAsStringAsync();
        Assert.Contains("maximum of 2 shared documents", responseBody, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task CreatePhysicianLink_WhenMaxActiveSharingLinksReached_ReturnsBadRequest()
    {
        await RevokeAllExistingLinksAsync();

        await UpdateSharingFeatureSettingsAsync(
            emergencySharingEnabled: true,
            physicianSharingEnabled: true,
            maxSharingLinksPerUser: 1,
            defaultMaxDocumentsToShare: 10,
            minDocumentsToShareLimit: 0,
            maxDocumentsToShareLimit: 10);

        var firstResponse = await _authClient.PostAsJsonAsync(
            "/api/user/sharing/physician-links",
            BuildPhysicianShareRequest("Dr. First", "first@example.com"));

        Assert.Equal(HttpStatusCode.OK, firstResponse.StatusCode);

        var secondResponse = await _authClient.PostAsJsonAsync(
            "/api/user/sharing/physician-links",
            BuildPhysicianShareRequest("Dr. Second", "second@example.com"));

        Assert.Equal(HttpStatusCode.BadRequest, secondResponse.StatusCode);

        var secondBody = await secondResponse.Content.ReadAsStringAsync();
        Assert.Contains("maximum of 1 active sharing links", secondBody, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task CreatePhysicianLink_WhenAtLimitButLinkRevoked_AllowsNewLink()
    {
        await RevokeAllExistingLinksAsync();

        await UpdateSharingFeatureSettingsAsync(
            emergencySharingEnabled: true,
            physicianSharingEnabled: true,
            maxSharingLinksPerUser: 1,
            defaultMaxDocumentsToShare: 10,
            minDocumentsToShareLimit: 0,
            maxDocumentsToShareLimit: 10);

        var firstCreateResponse = await _authClient.PostAsJsonAsync(
            "/api/user/sharing/physician-links",
            BuildPhysicianShareRequest("Dr. One", "one@example.com"));

        Assert.Equal(HttpStatusCode.OK, firstCreateResponse.StatusCode);

        var firstBody = await firstCreateResponse.Content
            .ReadFromJsonAsync<ApiEnvelope<SharingLinkClientResponse>>(_json);

        Assert.NotNull(firstBody?.Data);

        var revokeResponse = await _authClient.DeleteAsync($"/api/user/sharing/links/{firstBody!.Data!.LinkId}");
        Assert.Equal(HttpStatusCode.OK, revokeResponse.StatusCode);

        var secondCreateResponse = await _authClient.PostAsJsonAsync(
            "/api/user/sharing/physician-links",
            BuildPhysicianShareRequest("Dr. Two", "two@example.com"));

        Assert.Equal(HttpStatusCode.OK, secondCreateResponse.StatusCode);
    }

    private static object BuildPhysicianShareRequest(string physicianName, string physicianEmail)
    {
        return new
        {
            Label = "Standard share",
            PhysicianName = physicianName,
            PhysicianEmail = physicianEmail,
            Notes = "Routine check",
            Scopes = new[] { "medicalInformation" },
            SharedSnapshot = new
            {
                PatientInfo = new
                {
                    DisplayName = "Test User",
                    Initials = "TU",
                    BloodType = "A+",
                },
            },
            SecuritySettings = new
            {
                AccessDurationMinutes = 1440,
                PasswordProtected = false,
                RequiresTwoFactorApproval = false,
                AllowDownload = false,
                NotifyOnAccess = true,
            },
        };
    }
}

file sealed record SharingLinkClientResponse
{
    public Guid LinkId { get; init; }
    public string ShareType { get; init; } = string.Empty;
    public string? Label { get; init; }
    public bool IsRevoked { get; init; }
    public DateTime? RevokedAt { get; init; }
    public string ShareCode { get; init; } = string.Empty;
    public string ShareUrl { get; init; } = string.Empty;
    public string? RecipientName { get; init; }
    public string? RecipientEmail { get; init; }
    public List<string> Scopes { get; init; } = [];
    public ShareSecuritySettingsDto SecuritySettings { get; init; } = new();
}

file record ApiEnvelope<T>
{
    public bool Success { get; init; }
    public T? Data { get; init; }
    public string? Message { get; init; }
    public List<string>? Errors { get; init; }
}

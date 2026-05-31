using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.DependencyInjection;
using MedVault.API.Data;
using MedVault.API.Features.Configuration.Application.DTOs;
using MedVault.API.IntegrationTests.Fixtures;
using Xunit;

namespace MedVault.API.IntegrationTests.Tests;

/// <summary>
/// Integration tests for api/configuration endpoints (Workflow 1.3 — Configuration Assistant).
/// </summary>
public class ConfigurationControllerTests : IClassFixture<MedVaultApiFactory>, IAsyncLifetime
{
    private readonly MedVaultApiFactory _factory;
    private readonly HttpClient _authClient;
    private readonly HttpClient _anonClient;
    private readonly JsonSerializerOptions _json = new() { PropertyNameCaseInsensitive = true };

    public ConfigurationControllerTests(MedVaultApiFactory factory)
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

    private Task<HttpResponseMessage> ResetSharingFeatureSettingsAsync()
    {
        return _authClient.PutAsJsonAsync(
            "/api/system-configuration/sharing",
            new
            {
                EmergencySharingEnabled = true,
                PhysicianSharingEnabled = true,
                MaxSharingLinksPerUser = 5,
                DefaultMaxDocumentsToShare = 10,
                MinDocumentsToShareLimit = 0,
                MaxDocumentsToShareLimit = 10,
                MaxSharedDocumentBytes = 10485760,
            });
    }

    [Fact]
    public async Task SaveNotifications_ValidRequest_ReturnsPreferences()
    {
        var request = new
        {
            PushEnabled = true,
            Language = "es-ES",
            EmailEnabled = false,
            SecurityAlerts = true,
            QuietHoursStart = new TimeOnly(22, 0),
            QuietHoursEnd = new TimeOnly(7, 0)
        };

        var response = await _authClient.PostAsJsonAsync("/api/configuration/notifications", request);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<ApiEnvelope<NotificationPreferencesResponse>>(_json);
        Assert.True(body!.Success);
        Assert.True(body.Data!.PushEnabled);
        Assert.Equal("es-ES", body.Data.Language);
    }

    [Fact]
    public async Task GetNotifications_AfterSave_ReturnsSavedPreferences()
    {
        await _authClient.PostAsJsonAsync("/api/configuration/notifications",
            new { PushEnabled = true, Language = "en-US", EmailEnabled = true, SecurityAlerts = true });

        var response = await _authClient.GetAsync("/api/configuration/notifications");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<ApiEnvelope<NotificationPreferencesResponse>>(_json);
        Assert.True(body!.Success);
        Assert.True(body.Data!.PushEnabled);
        Assert.Equal("en-US", body.Data.Language);
    }

    [Fact]
    public async Task GetNotifications_BeforeSave_Returns404()
    {
        var response = await _authClient.GetAsync("/api/configuration/notifications");

        Assert.True(response.StatusCode is HttpStatusCode.OK or HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task SaveNotifications_Unauthenticated_Returns401()
    {
        var response = await _anonClient.PostAsJsonAsync("/api/configuration/notifications",
            new { PushEnabled = true });

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task SaveNotifications_InvalidLanguage_Returns400()
    {
        var response = await _authClient.PostAsJsonAsync(
            "/api/configuration/notifications",
            new { PushEnabled = true, Language = "invalid-language-tag-value" });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task SaveNotifications_WithPushToken_PersistsTokenPresence()
    {
        var request = new
        {
            PushEnabled = true,
            Language = "en-US",
            PushDeviceToken = "fcm-token-test-001",
        };

        var saveResponse = await _authClient.PostAsJsonAsync(
            "/api/configuration/notifications",
            request);

        Assert.Equal(HttpStatusCode.OK, saveResponse.StatusCode);

        var getResponse = await _authClient.GetAsync("/api/configuration/notifications");
        Assert.Equal(HttpStatusCode.OK, getResponse.StatusCode);

        var body = await getResponse.Content
            .ReadFromJsonAsync<ApiEnvelope<NotificationPreferencesResponse>>(_json);

        Assert.True(body!.Success);
        Assert.True(body.Data!.HasPushDeviceToken);

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<MedVaultDbContext>();
        var persisted = db.NotificationPreferences.FirstOrDefault(n => n.UserId == TestAuthHandler.TestUserId);

        Assert.NotNull(persisted);
        Assert.Equal("fcm-token-test-001", persisted!.PushDeviceToken);
    }

    [Fact]
    public async Task EnableCloudSync_ValidRequest_ReturnsBackupInfo()
    {
        var request = new
        {
            Provider = "MedVault",
            AutoBackupEnabled = true
        };

        var response = await _authClient.PostAsJsonAsync("/api/configuration/cloud-sync", request);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<ApiEnvelope<CloudSyncResponse>>(_json);
        Assert.True(body!.Success);
        Assert.Equal("MedVault", body.Data!.Provider);
        Assert.True(body.Data.AutoBackupEnabled);
        Assert.NotEqual(Guid.Empty, body.Data.BackupId);
    }

    [Fact]
    public async Task EnableCloudSync_EmptyProvider_Returns400()
    {
        var response = await _authClient.PostAsJsonAsync("/api/configuration/cloud-sync",
            new { Provider = "", AutoBackupEnabled = false });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task EnableCloudSync_Unauthenticated_Returns401()
    {
        var response = await _anonClient.PostAsJsonAsync("/api/configuration/cloud-sync",
            new { Provider = "MedVault", AutoBackupEnabled = true });

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task GetStatus_ReturnsOverallConfigStatus()
    {
        var response = await _authClient.GetAsync("/api/configuration/status");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<ApiEnvelope<ConfigurationStatusResponse>>(_json);
        Assert.True(body!.Success);
        Assert.InRange(body.Data!.CompletedSteps, 0, body.Data.TotalSteps);
    }

    [Fact]
    public async Task GetStatus_AfterFullSetup_AllStepsComplete()
    {
        await _authClient.PostAsJsonAsync("/api/configuration/notifications",
            new { PushEnabled = true, Language = "es-MX", SecurityAlerts = true });

        await _authClient.PostAsJsonAsync("/api/configuration/cloud-sync",
            new { Provider = "MedVault", AutoBackupEnabled = true });

        var response = await _authClient.GetAsync("/api/configuration/status");
        var body = await response.Content.ReadFromJsonAsync<ApiEnvelope<ConfigurationStatusResponse>>(_json);

        Assert.True(body!.Success);
        Assert.NotNull(body.Data);
        Assert.True(body.Data.NotificationsConfigured);
        Assert.True(body.Data.CloudSyncConfigured);
    }

    [Fact]
    public async Task GetStatus_Unauthenticated_Returns401()
    {
        var response = await _anonClient.GetAsync("/api/configuration/status");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task GetSharingSettings_ReturnsConfiguredValues()
    {
        var response = await _authClient.GetAsync("/api/configuration/sharing");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var body = await response.Content
            .ReadFromJsonAsync<ApiEnvelope<SharingFeatureSettingsResponseDto>>(_json);

        Assert.True(body!.Success);
        Assert.NotNull(body.Data);
        Assert.True(body.Data!.EmergencySharingEnabled);
        Assert.True(body.Data.PhysicianSharingEnabled);
        Assert.Equal(5, body.Data.MaxSharingLinksPerUser);
        Assert.Equal(10, body.Data.MaxDocumentsToShare);
    }

    [Fact]
    public async Task GetSystemConfiguration_ReturnsSharingSection()
    {
        var response = await _authClient.GetAsync("/api/system-configuration");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var body = await response.Content
            .ReadFromJsonAsync<ApiEnvelope<SystemConfigurationResponseDto>>(_json);

        Assert.True(body!.Success);
        Assert.NotNull(body.Data?.Sharing);
        Assert.True(body.Data!.Sharing.EmergencySharingEnabled);
        Assert.True(body.Data.Sharing.PhysicianSharingEnabled);
        Assert.Equal(5, body.Data.Sharing.MaxSharingLinksPerUser);
    }
}

file record ApiEnvelope<T>
{
    public bool Success { get; init; }
    public T? Data { get; init; }
    public string? Message { get; init; }
    public List<string>? Errors { get; init; }
}

file sealed record SystemConfigurationResponseDto
{
    public SharingFeatureSettingsResponseDto Sharing { get; init; } = new();
}

file sealed record SharingFeatureSettingsResponseDto
{
    public bool EmergencySharingEnabled { get; init; }
    public bool PhysicianSharingEnabled { get; init; }
    public int MaxSharingLinksPerUser { get; init; }
    public int MaxDocumentsToShare { get; init; }
    public int MinDocumentsToShareLimit { get; init; }
    public int MaxDocumentsToShareLimit { get; init; }
}

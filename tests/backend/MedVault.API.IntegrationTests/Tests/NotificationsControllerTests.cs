using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.Extensions.DependencyInjection;
using MedVault.API.Data;
using MedVault.API.Features.Notifications.Application.DTOs;
using MedVault.API.Features.Notifications.Domain;
using MedVault.API.IntegrationTests.Fixtures;
using Xunit;

namespace MedVault.API.IntegrationTests.Tests;

/// <summary>
/// Integration tests for api/notifications endpoints.
/// </summary>
public class NotificationsControllerTests : IClassFixture<MedVaultApiFactory>, IAsyncLifetime
{
    private readonly MedVaultApiFactory _factory;
    private readonly HttpClient _authClient;
    private readonly HttpClient _anonClient;
    private readonly JsonSerializerOptions _json = new()
    {
        PropertyNameCaseInsensitive = true,
        Converters = { new JsonStringEnumConverter() }
    };

    public NotificationsControllerTests(MedVaultApiFactory factory)
    {
        _factory = factory;
        _authClient = factory.CreateAuthenticatedClient();
        _anonClient = factory.CreateAnonymousClient();
    }

    public async Task InitializeAsync()
    {
        await _factory.SeedTestUserAsync();
        await SeedNotificationsAsync();
    }

    public Task DisposeAsync() => Task.CompletedTask;

    [Fact]
    public async Task GetNotifications_Authenticated_ReturnsUserNotifications()
    {
        await SeedNotificationsAsync();

        var response = await _authClient.GetAsync("/api/notifications");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var body = await response.Content
            .ReadFromJsonAsync<ApiEnvelope<List<NotificationItemResponse>>>(_json);

        Assert.True(body!.Success);
        Assert.NotNull(body.Data);
        Assert.True(body.Data!.Count >= 2);
        Assert.Contains(body.Data, n => n.Type == NotificationType.ShareRequest);
        Assert.All(body.Data, n => Assert.False(string.IsNullOrWhiteSpace(n.Language)));
        Assert.All(body.Data, n => Assert.False(string.IsNullOrWhiteSpace(n.Title)));
        Assert.All(body.Data, n => Assert.False(string.IsNullOrWhiteSpace(n.Subtitle)));
        Assert.All(body.Data, n => Assert.False(string.IsNullOrWhiteSpace(n.Description)));
    }

    [Fact]
    public async Task GetNotifications_Unauthenticated_Returns401()
    {
        var response = await _anonClient.GetAsync("/api/notifications");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task MarkAsRead_ExistingNotification_ReturnsUpdatedNotification()
    {
        await SeedNotificationsAsync();

        var notificationId = await GetUnreadNotificationIdAsync();

        var response = await _authClient.PostAsync($"/api/notifications/{notificationId}/read", content: null);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var body = await response.Content
            .ReadFromJsonAsync<ApiEnvelope<NotificationItemResponse>>(_json);

        Assert.True(body!.Success);
        Assert.True(body.Data!.IsRead);
        Assert.NotNull(body.Data.ReadAt);
        Assert.False(string.IsNullOrWhiteSpace(body.Data.Subtitle));
    }

    [Fact]
    public async Task MarkAsRead_NonExistingNotification_Returns404()
    {
        var response = await _authClient.PostAsync($"/api/notifications/{Guid.NewGuid()}/read", content: null);

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task MarkAllAsRead_ReturnsUpdatedCount()
    {
        await SeedNotificationsAsync();

        var response = await _authClient.PostAsync("/api/notifications/read-all", content: null);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var body = await response.Content
            .ReadFromJsonAsync<ApiEnvelope<MarkAllNotificationsAsReadResponse>>(_json);

        Assert.True(body!.Success);
        Assert.True(body.Data!.UpdatedCount >= 0);

        var listResponse = await _authClient.GetAsync("/api/notifications");
        var listBody = await listResponse.Content
            .ReadFromJsonAsync<ApiEnvelope<List<NotificationItemResponse>>>(_json);

        Assert.DoesNotContain(listBody!.Data!, n => !n.IsRead);
    }

    [Fact]
    public async Task DeleteNotification_ExistingNotification_RemovesNotification()
    {
        await SeedNotificationsAsync();

        var notificationId = await GetUnreadNotificationIdAsync();

        var deleteResponse = await _authClient.DeleteAsync($"/api/notifications/{notificationId}");

        Assert.Equal(HttpStatusCode.OK, deleteResponse.StatusCode);

        var listResponse = await _authClient.GetAsync("/api/notifications");
        var listBody = await listResponse.Content
            .ReadFromJsonAsync<ApiEnvelope<List<NotificationItemResponse>>>(_json);

        Assert.DoesNotContain(listBody!.Data!, n => n.Id == notificationId);
    }

    [Fact]
    public async Task DeleteNotification_NonExistingNotification_Returns404()
    {
        var response = await _authClient.DeleteAsync($"/api/notifications/{Guid.NewGuid()}");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    private async Task<Guid> GetUnreadNotificationIdAsync()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<MedVaultDbContext>();

        var notification = db.UserNotifications
            .OrderBy(n => n.CreatedAt)
            .First(n => n.UserId == TestAuthHandler.TestUserId);

        if (notification.ReadAt.HasValue)
        {
            notification.ReadAt = null;
            await db.SaveChangesAsync();
        }

        return notification.Id;
    }

    private async Task SeedNotificationsAsync()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<MedVaultDbContext>();

        var userId = TestAuthHandler.TestUserId;
        var existing = db.UserNotifications.Where(n => n.UserId == userId).ToList();
        if (existing.Count > 0)
        {
            db.UserNotifications.RemoveRange(existing);
            await db.SaveChangesAsync();
        }

        db.UserNotifications.AddRange(
            new UserNotificationEntity
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Type = NotificationType.ShareRequest,
                Language = "en-US",
                Title = "Share request",
                Subtitle = "You have {unreadCount} unread notifications",
                Description = "Dr. Jane Smith requested access to your data.",
                ActorName = "Dr. Jane Smith",
                CreatedAt = DateTime.UtcNow.AddHours(-1),
                ReadAt = null
            },
            new UserNotificationEntity
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Type = NotificationType.SecurityAlert,
                Language = "en-US",
                Title = "Security alert",
                Subtitle = "You have {unreadCount} unread notifications",
                Description = "A suspicious activity was detected.",
                ActorName = null,
                CreatedAt = DateTime.UtcNow.AddHours(-3),
                ReadAt = DateTime.UtcNow.AddHours(-2)
            });

        await db.SaveChangesAsync();
    }
}

file record ApiEnvelope<T>
{
    public bool Success { get; init; }
    public T? Data { get; init; }
    public string? Message { get; init; }
    public List<string>? Errors { get; init; }
}

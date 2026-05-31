using MedVault.API.Features.Notifications.Domain;

namespace MedVault.API.Features.Notifications.Application.DTOs;

public sealed record NotificationItemResponse
{
    public Guid Id { get; init; }
    public NotificationType Type { get; init; }
    public string? Language { get; init; }
    public string? Title { get; init; }
    public string? Subtitle { get; init; }
    public string? Description { get; init; }
    public string? ActorName { get; init; }
    public DateTime CreatedAt { get; init; }
    public DateTime? ReadAt { get; init; }
    public bool IsRead { get; init; }
}

public sealed record MarkAllNotificationsAsReadResponse
{
    public int UpdatedCount { get; init; }
}


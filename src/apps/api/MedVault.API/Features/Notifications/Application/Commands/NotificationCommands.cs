using MedVault.API.Common.CQRS;
using MedVault.API.Features.Notifications.Application.DTOs;

namespace MedVault.API.Features.Notifications.Application.Commands;

public sealed record MarkNotificationAsReadCommand(
    Guid UserId,
    Guid NotificationId) : ICommand<NotificationItemResponse?>;

public sealed record MarkAllNotificationsAsReadCommand(
    Guid UserId) : ICommand<MarkAllNotificationsAsReadResponse>;

public sealed record DeleteNotificationCommand(
    Guid UserId,
    Guid NotificationId) : ICommand<bool>;


using MedVault.API.Common.CQRS;
using MedVault.API.Features.Notifications.Application.DTOs;

namespace MedVault.API.Features.Notifications.Application.Queries;

public sealed record GetNotificationsQuery(
    Guid UserId) : IQuery<IReadOnlyList<NotificationItemResponse>>;


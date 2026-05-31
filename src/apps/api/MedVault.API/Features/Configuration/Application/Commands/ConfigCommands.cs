using MedVault.API.Common.CQRS;
using MedVault.API.Features.Configuration.Application.DTOs;

namespace MedVault.API.Features.Configuration.Application.Commands;

public sealed record SaveNotificationPreferencesCommand(
    Guid UserId,
    SaveNotificationPreferencesRequest Data) : ICommand<NotificationPreferencesResponse>;

public sealed record EnableCloudSyncCommand(
    Guid UserId,
    EnableCloudSyncRequest Data) : ICommand<CloudSyncResponse>;


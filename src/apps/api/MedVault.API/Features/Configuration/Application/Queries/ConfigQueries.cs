using MedVault.API.Common.CQRS;
using MedVault.API.Features.Configuration.Application.DTOs;

namespace MedVault.API.Features.Configuration.Application.Queries;

public sealed record GetConfigurationStatusQuery(
    Guid UserId) : IQuery<ConfigurationStatusResponse>;

public sealed record GetNotificationPreferencesQuery(
    Guid UserId) : IQuery<NotificationPreferencesResponse?>;


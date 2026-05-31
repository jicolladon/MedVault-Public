using MedVault.API.Common.CQRS;
using MedVault.API.Features.UserProfile.Application.DTOs;

namespace MedVault.API.Features.UserProfile.Application.Queries;

public sealed record GetUserProfileQuery(Guid UserId) : IQuery<UserProfileResponse?>;

public sealed record GetProfileCompletenessQuery(Guid UserId) : IQuery<ProfileCompletenessResponse>;

public sealed record GetEmergencyContactsQuery(Guid UserId) : IQuery<IReadOnlyList<EmergencyContactResponse>>;


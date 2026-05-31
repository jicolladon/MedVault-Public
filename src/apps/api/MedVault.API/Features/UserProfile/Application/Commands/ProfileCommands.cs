using MedVault.API.Common.CQRS;
using MedVault.API.Features.UserProfile.Application.DTOs;

namespace MedVault.API.Features.UserProfile.Application.Commands;

public sealed record UpdateUserProfileCommand(
    Guid UserId,
    UpdateProfileRequest Data) : ICommand<UserProfileResponse>;

public sealed record AddEmergencyContactCommand(
    Guid UserId,
    UpsertEmergencyContactRequest Data) : ICommand<EmergencyContactResponse>;

public sealed record UpdateEmergencyContactCommand(
    Guid UserId,
    string ContactId,
    UpsertEmergencyContactRequest Data) : ICommand<EmergencyContactResponse>;

public sealed record DeleteEmergencyContactCommand(
    Guid UserId,
    string ContactId) : ICommand<bool>;

public sealed record ReplaceEmergencyContactsCommand(
    Guid UserId,
    ReplaceEmergencyContactsRequest Data) : ICommand<IReadOnlyList<EmergencyContactResponse>>;


using MedVault.API.Features.Shared.Domain;

namespace MedVault.API.Features.UserProfile.Application.DTOs;

public sealed record UserProfileResponse
{
    public Guid UserId { get; init; }
    public string Email { get; init; } = default!;
    public string DisplayName { get; init; } = default!;
    public string FirstName { get; init; } = default!;
    public string LastName { get; init; } = default!;
    public DateOnly? DateOfBirth { get; init; }
    public Gender? Gender { get; init; }
    public string? ProfilePictureUrl { get; init; }
    public string? PhoneNumber { get; init; }
    public string? AddressLine1 { get; init; }
    public string? AddressLine2 { get; init; }
    public string? City { get; init; }
    public string? State { get; init; }
    public string? PostalCode { get; init; }
    public string? Country { get; init; }
    public string? EmergencyContactName { get; init; }
    public string? EmergencyContactPhone { get; init; }
    public string? EmergencyContactRelationship { get; init; }
    public string? BloodType { get; init; }
    public List<EmergencyContactResponse> EmergencyContacts { get; init; } = [];
    public int ProfileCompleteness { get; init; }
    public string PrivacyLevel { get; init; } = "Standard";
    public DateTime CreatedAt { get; init; }
    public DateTime? UpdatedAt { get; init; }
}

public sealed record UpdateProfileRequest
{
    public string? DisplayName { get; init; }
    public string? Email { get; init; }
    public string? ProfilePictureUrl { get; init; }
    public string? FirstName { get; init; }
    public string? LastName { get; init; }
    public DateOnly? DateOfBirth { get; init; }
    public Gender? Gender { get; init; }
    public string? PhoneNumber { get; init; }
    public string? AddressLine1 { get; init; }
    public string? AddressLine2 { get; init; }
    public string? City { get; init; }
    public string? State { get; init; }
    public string? PostalCode { get; init; }
    public string? Country { get; init; }
    public string? EmergencyContactName { get; init; }
    public string? EmergencyContactPhone { get; init; }
    public string? EmergencyContactRelationship { get; init; }
    public string? BloodType { get; init; }
}

public sealed record EmergencyContactResponse
{
    public string ContactId { get; init; } = default!;
    public string Name { get; init; } = default!;
    public string Relationship { get; init; } = default!;
    public string Phone { get; init; } = default!;
    public string? Email { get; init; }
    public bool IsPrimary { get; init; }
    public DateTime CreatedAt { get; init; }
    public DateTime UpdatedAt { get; init; }
}

public sealed record UpsertEmergencyContactRequest
{
    public string? ContactId { get; init; }
    public string Name { get; init; } = default!;
    public string Relationship { get; init; } = default!;
    public string Phone { get; init; } = default!;
    public string? Email { get; init; }
    public bool IsPrimary { get; init; }
}

public sealed record ReplaceEmergencyContactsRequest
{
    public List<UpsertEmergencyContactRequest> Contacts { get; init; } = [];
}

public sealed record ProfileCompletenessResponse
{
    public int Percentage { get; init; }
    public List<string> MissingFields { get; init; } = [];
    public List<string> CompletedSections { get; init; } = [];
}


using Microsoft.AspNetCore.Identity;

namespace MedVault.API.Features.Auth.Domain;

public class AppUser : IdentityUser<Guid>
{
    public string? GoogleId { get; set; }
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    public string FullName => $"{FirstName} {LastName}".Trim();
    public string? ProfilePictureUrl { get; set; }
    public DateOnly? DateOfBirth { get; set; }
    public string? Gender { get; set; }
    public string? AddressLine1 { get; set; }
    public string? AddressLine2 { get; set; }
    public string? City { get; set; }
    public string? State { get; set; }
    public string? PostalCode { get; set; }
    public string? Country { get; set; }
    public string? EmergencyContactName { get; set; }
    public string? EmergencyContactPhone { get; set; }
    public string? EmergencyContactRelationship { get; set; }
    public string? BloodType { get; set; }
    public bool TermsAccepted { get; set; }
    public DateTime? TermsAcceptedDate { get; set; }
    public bool PrivacyPolicyAccepted { get; set; }
    public DateTime? PrivacyPolicyAcceptedDate { get; set; }
    public string AccountStatus { get; set; } = "Active";
    public DateTime? LastLoginDate { get; set; }
    public DateTime? LastLogoutDate { get; set; }
    public DateTime? LastActivityDate { get; set; }
    public DateTime? LastProfileUpdate { get; set; }
    public int ProfileCompleteness { get; set; }
    public string? TimeZone { get; set; }
    public string? Language { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public Guid? UpdatedBy { get; set; }
    public ICollection<RefreshTokenEntity> RefreshTokens { get; set; } = [];
    public ICollection<UserSessionEntity> Sessions { get; set; } = [];
    public ICollection<UserConsentEntity> Consents { get; set; } = [];
}


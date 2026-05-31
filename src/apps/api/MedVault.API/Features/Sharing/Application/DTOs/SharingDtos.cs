using MedVault.API.Features.Shared.Domain;
using System.Text.Json.Serialization;

namespace MedVault.API.Features.Sharing.Application.DTOs;

public sealed record SharedDataResponse
{
    public string Token { get; init; } = default!;
    public SharedPatientInfo PatientInfo { get; init; } = default!;
    public string AccessLevel { get; init; } = default!;
    public DateTime ExpiresAt { get; init; }
    public DateTime SharedAt { get; init; }
    public string SharedBy { get; init; } = default!;
    public MedicalSummaryDto MedicalSummary { get; init; } = default!;
    public List<MedicalHistoryEntryDto> MedicalHistory { get; init; } = [];
    public List<SharedDocumentDto> Documents { get; init; } = [];
}

public sealed record SharedPatientInfo
{
    public string DisplayName { get; init; } = default!;
    public string Initials { get; init; } = default!;
    public string? DateOfBirth { get; init; }
    public Gender? Gender { get; init; }
    public string? BloodType { get; init; }
    public string? EmergencyContactName { get; init; }
    public string? EmergencyContactPhone { get; init; }
    public string? EmergencyContactRelationship { get; init; }
}

public sealed record MedicalSummaryDto
{
    public List<SharedAllergyDto> Allergies { get; init; } = [];
    public List<SharedMedicationDto> ActiveMedications { get; init; } = [];
    public List<SharedConditionDto> Conditions { get; init; } = [];
    public List<SharedVaccinationDto> Vaccinations { get; init; } = [];
}

public sealed record SharedAllergyDto
{
    public string Id { get; init; } = default!;
    public string AllergenName { get; init; } = default!;
    public string AllergyType { get; init; } = default!;
    public string Severity { get; init; } = default!;
    public string? Reaction { get; init; }
    public string? DiagnosedDate { get; init; }
    public bool IsActive { get; init; }
}

public sealed record SharedMedicationDto
{
    public string Id { get; init; } = default!;
    public string MedicationName { get; init; } = default!;
    public string? GenericName { get; init; }
    public string? Dosage { get; init; }
    public string? Frequency { get; init; }
    public string? Route { get; init; }
    public string? PrescribedBy { get; init; }
    public string? StartDate { get; init; }
    public string? EndDate { get; init; }
    public bool IsActive { get; init; }
}

public sealed record SharedConditionDto
{
    public string Id { get; init; } = default!;
    public string ConditionName { get; init; } = default!;
    public string? IcdCode { get; init; }
    public string? DiagnosedDate { get; init; }
    public string Status { get; init; } = default!;
    public string? TreatmentPlan { get; init; }
}

public sealed record SharedVaccinationDto
{
    public string Id { get; init; } = default!;
    public string VaccineName { get; init; } = default!;
    public string? Manufacturer { get; init; }
    public string? LotNumber { get; init; }
    public string AdministeredDate { get; init; } = default!;
    public int DoseNumber { get; init; }
    public string? AdministeredBy { get; init; }
    public string? NextDoseDate { get; init; }
}

public sealed record MedicalHistoryEntryDto
{
    public string Id { get; init; } = default!;
    public string Date { get; init; } = default!;
    public string Type { get; init; } = default!;
    public string Title { get; init; } = default!;
    public string? Description { get; init; }
    public string? Provider { get; init; }
    public string? Facility { get; init; }
    public string? Notes { get; init; }
    public string? Severity { get; init; }
}

public sealed record SharedDocumentDto
{
    public string Id { get; init; } = default!;
    public string Title { get; init; } = default!;
    public string? Category { get; init; }
    public string? Description { get; init; }
    public string? FileName { get; init; }
    public string? ContentType { get; init; }
    public int? FileSizeBytes { get; init; }
    public string? ContentBase64 { get; init; }
    public string? ContentFileId { get; init; }
    public string? DownloadUrl { get; init; }
    public string? UploadedAt { get; init; }
}

public sealed record ShareSnapshotDto
{
    public SharedPatientInfo? PatientInfo { get; init; }
    public MedicalSummaryDto MedicalSummary { get; init; } = new();
    public List<MedicalHistoryEntryDto> MedicalHistory { get; init; } = [];
    public List<SharedDocumentDto> Documents { get; init; } = [];
}

public sealed record ShareSecuritySettingsDto
{
    public int AccessDurationMinutes { get; init; }
    public bool PasswordProtected { get; init; }
    public bool RequiresTwoFactorApproval { get; init; }
    public bool AllowDownload { get; init; }
    public bool NotifyOnAccess { get; init; } = true;

    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? AccessPassword { get; init; }

    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? VerificationCode { get; init; }
}

public sealed record ShareSecretSettingsDto
{
    public string? PasswordHash { get; init; }
    public string? VerificationCodeHash { get; init; }
}

public sealed record CreateEmergencyShareLinkRequest
{
    public string? Label { get; init; }
    public List<string> Scopes { get; init; } = [];
    public ShareSecuritySettingsDto SecuritySettings { get; init; } = new();
    public ShareSnapshotDto? SharedSnapshot { get; init; }
}

public sealed record CreatePhysicianShareLinkRequest
{
    public string? Label { get; init; }
    public string PhysicianName { get; init; } = string.Empty;
    public string? PhysicianEmail { get; init; }
    public string? Notes { get; init; }
    public List<string> Scopes { get; init; } = [];
    public ShareSecuritySettingsDto SecuritySettings { get; init; } = new();
    public ShareSnapshotDto? SharedSnapshot { get; init; }
}

public sealed record UpdateShareLinkRequest
{
    public string? Label { get; init; }
    public List<string> Scopes { get; init; } = [];
    public ShareSecuritySettingsDto SecuritySettings { get; init; } = new();
    public ShareSnapshotDto? SharedSnapshot { get; init; }
}

public sealed record ShareLinkManagementResponse
{
    public Guid LinkId { get; init; }
    public string ShareType { get; init; } = string.Empty;
    public string AccessLevel { get; init; } = string.Empty;
    public string? Label { get; init; }
    public DateTime CreatedAt { get; init; }
    public DateTime ExpiresAt { get; init; }
    public bool IsRevoked { get; init; }
    public DateTime? RevokedAt { get; init; }
    public int AccessCount { get; init; }
    public DateTime? LastAccessedAt { get; init; }
    public string? PublicToken { get; init; }
    public string ShareCode { get; init; } = string.Empty;
    public string? RecipientName { get; init; }
    public string? RecipientEmail { get; init; }
    public string? Notes { get; init; }
    public List<string> Scopes { get; init; } = [];
    public ShareSecuritySettingsDto SecuritySettings { get; init; } = new();
}

public sealed record ShareAccessLogItemResponse
{
    public Guid Id { get; init; }
    public Guid ShareLinkId { get; init; }
    public DateTime AccessedAt { get; init; }
    public string? ViewerName { get; init; }
    public string? ViewerIpAddress { get; init; }
    public string? ViewerUserAgent { get; init; }
}

public sealed record SharePayloadDto
{
    public string Audience { get; init; } = string.Empty;
    public string? RecipientName { get; init; }
    public string? RecipientEmail { get; init; }
    public string? Notes { get; init; }
    public List<string> Scopes { get; init; } = [];
    public ShareSecuritySettingsDto SecuritySettings { get; init; } = new();
    public ShareSecretSettingsDto SecretSettings { get; init; } = new();
    public ShareSnapshotDto? SharedSnapshot { get; init; }
}

public sealed record ShareTokenValidationDto
{
    public bool IsValid { get; init; }
    public string? AccessLevel { get; init; }
    public DateTime? ExpiresAt { get; init; }
    public string? Message { get; init; }
    public bool RequiresPassword { get; init; }
    public bool RequiresVerificationCode { get; init; }
    public bool RequiresTwoFactorApproval { get; init; }
}

public sealed record RequestTwoFactorApprovalRequest
{
    public string ViewerName { get; init; } = string.Empty;
    public string? AccessPassword { get; init; }
}

public sealed record TwoFactorApprovalRequestResponse
{
    public Guid RequestId { get; init; }
    public Guid ShareLinkId { get; init; }
    public string ViewerName { get; init; } = string.Empty;
    public DateTime RequestedAt { get; init; }
    public DateTime ExpiresAt { get; init; }
    public string Status { get; init; } = string.Empty;
}

public sealed record TwoFactorApprovalStatusResponse
{
    public Guid RequestId { get; init; }
    public string Status { get; init; } = string.Empty;
    public DateTime RequestedAt { get; init; }
    public DateTime ExpiresAt { get; init; }
    public DateTime? DecisionAt { get; init; }
    public string? Message { get; init; }
}

public sealed record PendingTwoFactorApprovalItemResponse
{
    public Guid RequestId { get; init; }
    public Guid ShareLinkId { get; init; }
    public string ShareCode { get; init; } = string.Empty;
    public string ViewerName { get; init; } = string.Empty;
    public string? ViewerIpAddress { get; init; }
    public DateTime RequestedAt { get; init; }
    public DateTime ExpiresAt { get; init; }
    public string Status { get; init; } = string.Empty;
}

public sealed record DecideTwoFactorApprovalRequest
{
    public bool Approved { get; init; }
}

public sealed record TwoFactorApprovalDecisionResponse
{
    public Guid RequestId { get; init; }
    public Guid ShareLinkId { get; init; }
    public string Status { get; init; } = string.Empty;
    public DateTime DecisionAt { get; init; }
}


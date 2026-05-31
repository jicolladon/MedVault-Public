using System.Text.Json;
using MedVault.API.Features.Sharing.Application.DTOs;

namespace MedVault.API.Features.Sharing.Application.Handlers;

internal static class SharePayloadMapper
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);
    private const int MaxSharedDocumentSizeBytes = 10 * 1024 * 1024;
    private const int MaxSharedDocumentContentBase64Length = 14_000_000;

    public static string Serialize(SharePayloadDto payload)
    {
        return JsonSerializer.Serialize(payload, JsonOptions);
    }

    public static SharePayloadDto Deserialize(string rawPayload)
    {
        return JsonSerializer.Deserialize<SharePayloadDto>(rawPayload, JsonOptions) ?? new SharePayloadDto();
    }

    public static SharePayloadDto CreateEmergencyPayload(CreateEmergencyShareLinkRequest request)
    {
        return new SharePayloadDto
        {
            Audience = "Emergency",
            Scopes = request.Scopes.Select(NormalizeScope).Distinct(StringComparer.Ordinal).ToList(),
            SecuritySettings = request.SecuritySettings,
            SharedSnapshot = NormalizeSnapshot(request.SharedSnapshot),
        };
    }

    public static SharePayloadDto CreatePhysicianPayload(CreatePhysicianShareLinkRequest request)
    {
        return new SharePayloadDto
        {
            Audience = "Regular",
            RecipientName = request.PhysicianName.Trim(),
            RecipientEmail = TrimOrNull(request.PhysicianEmail, 320),
            Notes = string.IsNullOrWhiteSpace(request.Notes) ? null : request.Notes.Trim(),
            Scopes = request.Scopes.Select(NormalizeScope).Distinct(StringComparer.Ordinal).ToList(),
            SecuritySettings = request.SecuritySettings,
            SharedSnapshot = NormalizeSnapshot(request.SharedSnapshot),
        };
    }

    public static SharePayloadDto UpdatePayload(SharePayloadDto currentPayload, UpdateShareLinkRequest request)
    {
        return currentPayload with
        {
            Scopes = request.Scopes.Select(NormalizeScope).Distinct(StringComparer.Ordinal).ToList(),
            SecuritySettings = request.SecuritySettings,
            SharedSnapshot = request.SharedSnapshot is null
                ? currentPayload.SharedSnapshot
                : NormalizeSnapshot(request.SharedSnapshot),
        };
    }

    public static ShareLinkManagementResponse ToManagementResponse(ShareTokenSnapshot snapshot)
    {
        return new ShareLinkManagementResponse
        {
            LinkId = snapshot.Id,
            ShareType = snapshot.ShareType,
            AccessLevel = snapshot.AccessLevel,
            Label = snapshot.Label,
            CreatedAt = snapshot.CreatedAt,
            ExpiresAt = snapshot.ExpiresAt,
            IsRevoked = snapshot.IsRevoked,
            RevokedAt = snapshot.RevokedAt,
            AccessCount = snapshot.AccessCount,
            LastAccessedAt = snapshot.LastAccessedAt,
            PublicToken = snapshot.PublicToken,
            ShareCode = snapshot.ShareCode,
            RecipientName = snapshot.Payload.RecipientName,
            RecipientEmail = snapshot.Payload.RecipientEmail,
            Notes = snapshot.Payload.Notes,
            Scopes = snapshot.Payload.Scopes,
            SecuritySettings = SanitizeSecuritySettings(snapshot.Payload.SecuritySettings),
        };
    }

    public static ShareSecuritySettingsDto SanitizeSecuritySettings(ShareSecuritySettingsDto settings)
    {
        return settings with
        {
            AccessPassword = null,
            VerificationCode = null,
        };
    }

    public static string BuildShareCode(string token)
    {
        if (string.IsNullOrWhiteSpace(token))
        {
            return string.Empty;
        }

        var compact = token.Replace("-", string.Empty, StringComparison.Ordinal)
            .Replace("_", string.Empty, StringComparison.Ordinal)
            .ToUpperInvariant();

        return compact.Length <= 8 ? compact : compact[..8];
    }

    private static string NormalizeScope(string scope)
    {
        var trimmed = scope.Trim();
        if (trimmed.Length == 0)
        {
            return trimmed;
        }

        var normalized = char.ToLowerInvariant(trimmed[0]) + trimmed[1..];
        return normalized switch
        {
            "chronicConditions" => "diagnoses",
            "vaccinations" => "vaccines",
            _ => normalized,
        };
    }

    private static ShareSnapshotDto? NormalizeSnapshot(ShareSnapshotDto? snapshot)
    {
        if (snapshot is null)
        {
            return null;
        }

        return new ShareSnapshotDto
        {
            PatientInfo = snapshot.PatientInfo is null
                ? null
                : new SharedPatientInfo
                {
                    DisplayName = TrimOrEmpty(snapshot.PatientInfo.DisplayName, 200),
                    Initials = TrimOrEmpty(snapshot.PatientInfo.Initials, 12),
                    DateOfBirth = TrimOrNull(snapshot.PatientInfo.DateOfBirth, 20),
                    Gender = snapshot.PatientInfo.Gender,
                    BloodType = TrimOrNull(snapshot.PatientInfo.BloodType, 20),
                    EmergencyContactName = TrimOrNull(snapshot.PatientInfo.EmergencyContactName, 200),
                    EmergencyContactPhone = TrimOrNull(snapshot.PatientInfo.EmergencyContactPhone, 40),
                    EmergencyContactRelationship = TrimOrNull(snapshot.PatientInfo.EmergencyContactRelationship, 80),
                },
            MedicalSummary = new MedicalSummaryDto
            {
                Allergies = snapshot.MedicalSummary.Allergies
                    .Take(200)
                    .Select(item => item with
                    {
                        Id = TrimOrEmpty(item.Id, 80),
                        AllergenName = TrimOrEmpty(item.AllergenName, 200),
                        AllergyType = TrimOrEmpty(item.AllergyType, 120),
                        Severity = TrimOrEmpty(item.Severity, 80),
                        Reaction = TrimOrNull(item.Reaction, 300),
                        DiagnosedDate = TrimOrNull(item.DiagnosedDate, 30),
                    })
                    .ToList(),
                ActiveMedications = snapshot.MedicalSummary.ActiveMedications
                    .Take(300)
                    .Select(item => item with
                    {
                        Id = TrimOrEmpty(item.Id, 80),
                        MedicationName = TrimOrEmpty(item.MedicationName, 200),
                        GenericName = TrimOrNull(item.GenericName, 200),
                        Dosage = TrimOrNull(item.Dosage, 80),
                        Frequency = TrimOrNull(item.Frequency, 120),
                        Route = TrimOrNull(item.Route, 80),
                        PrescribedBy = TrimOrNull(item.PrescribedBy, 200),
                        StartDate = TrimOrNull(item.StartDate, 30),
                        EndDate = TrimOrNull(item.EndDate, 30),
                    })
                    .ToList(),
                Conditions = snapshot.MedicalSummary.Conditions
                    .Take(200)
                    .Select(item => item with
                    {
                        Id = TrimOrEmpty(item.Id, 80),
                        ConditionName = TrimOrEmpty(item.ConditionName, 200),
                        IcdCode = TrimOrNull(item.IcdCode, 40),
                        DiagnosedDate = TrimOrNull(item.DiagnosedDate, 30),
                        Status = TrimOrEmpty(item.Status, 80),
                        TreatmentPlan = TrimOrNull(item.TreatmentPlan, 400),
                    })
                    .ToList(),
                Vaccinations = snapshot.MedicalSummary.Vaccinations
                    .Take(200)
                    .Select(item => item with
                    {
                        Id = TrimOrEmpty(item.Id, 80),
                        VaccineName = TrimOrEmpty(item.VaccineName, 200),
                        Manufacturer = TrimOrNull(item.Manufacturer, 200),
                        LotNumber = TrimOrNull(item.LotNumber, 80),
                        AdministeredDate = TrimOrEmpty(item.AdministeredDate, 30),
                        AdministeredBy = TrimOrNull(item.AdministeredBy, 200),
                        NextDoseDate = TrimOrNull(item.NextDoseDate, 30),
                    })
                    .ToList(),
            },
            MedicalHistory = snapshot.MedicalHistory
                .Take(500)
                .Select(item => item with
                {
                    Id = TrimOrEmpty(item.Id, 80),
                    Date = TrimOrEmpty(item.Date, 30),
                    Type = TrimOrEmpty(item.Type, 80),
                    Title = TrimOrEmpty(item.Title, 240),
                    Description = TrimOrNull(item.Description, 2000),
                    Provider = TrimOrNull(item.Provider, 200),
                    Facility = TrimOrNull(item.Facility, 200),
                    Notes = TrimOrNull(item.Notes, 2000),
                    Severity = TrimOrNull(item.Severity, 80),
                })
                .ToList(),
            Documents = snapshot.Documents
                .Take(10)
                .Select(item => item with
                {
                    Id = TrimOrEmpty(item.Id, 80),
                    Title = TrimOrEmpty(item.Title, 240),
                    Category = TrimOrNull(item.Category, 120),
                    Description = TrimOrNull(item.Description, 1200),
                    FileName = TrimOrNull(item.FileName, 300),
                    ContentType = TrimOrNull(item.ContentType, 120),
                    FileSizeBytes = NormalizeFileSize(item.FileSizeBytes),
                    ContentBase64 = NormalizeDocumentContent(item.ContentBase64, item.FileSizeBytes),
                    ContentFileId = TrimOrNull(item.ContentFileId, 80),
                    DownloadUrl = TrimOrNull(item.DownloadUrl, 2000),
                    UploadedAt = TrimOrNull(item.UploadedAt, 30),
                })
                .ToList(),
        };
    }

    private static string? TrimOrNull(string? value, int maxLength)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        return value.Trim()[..Math.Min(value.Trim().Length, maxLength)];
    }

    private static string TrimOrEmpty(string? value, int maxLength)
    {
        var cleaned = TrimOrNull(value, maxLength);
        return cleaned ?? string.Empty;
    }

    private static int? NormalizeFileSize(int? value)
    {
        if (value is null || value <= 0)
        {
            return null;
        }

        return Math.Min(value.Value, MaxSharedDocumentSizeBytes);
    }

    private static string? NormalizeDocumentContent(string? contentBase64, int? fileSizeBytes)
    {
        if (fileSizeBytes is > MaxSharedDocumentSizeBytes)
        {
            return null;
        }

        if (string.IsNullOrWhiteSpace(contentBase64))
        {
            return null;
        }

        var trimmed = contentBase64.Trim();
        if (trimmed.Length > MaxSharedDocumentContentBase64Length)
        {
            return null;
        }

        return trimmed;
    }
}

internal sealed record ShareTokenSnapshot(
    Guid Id,
    string ShareType,
    string AccessLevel,
    string? Label,
    DateTime CreatedAt,
    DateTime ExpiresAt,
    bool IsRevoked,
    DateTime? RevokedAt,
    int AccessCount,
    DateTime? LastAccessedAt,
    string? PublicToken,
    string ShareCode,
    SharePayloadDto Payload);


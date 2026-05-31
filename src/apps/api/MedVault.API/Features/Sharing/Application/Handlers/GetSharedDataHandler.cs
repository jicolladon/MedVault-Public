using Microsoft.EntityFrameworkCore;
using MedVault.API.Common.CQRS;
using MedVault.API.Data;
using MedVault.API.Features.Sharing.Application.DTOs;
using MedVault.API.Features.Sharing.Application.Interfaces;
using MedVault.API.Features.Sharing.Application.Queries;
using MedVault.API.Features.Sharing.Domain;
using MedVault.API.Features.Shared.Domain;

namespace MedVault.API.Features.Sharing.Application.Handlers;

public class GetSharedDataHandler : IQueryHandler<GetSharedDataQuery, SharedDataResponse>
{
    private readonly MedVaultDbContext _db;
    private readonly IShareProtectionService _shareProtection;

    public GetSharedDataHandler(
        MedVaultDbContext db,
        IShareProtectionService shareProtection)
    {
        _db = db;
        _shareProtection = shareProtection;
    }

    public async Task<SharedDataResponse> HandleAsync(
        GetSharedDataQuery query, CancellationToken cancellationToken = default)
    {
        var tokenHash = _shareProtection.HashToken(query.Token);
        var shareToken = await _db.ShareTokens
            .Include(t => t.User)
            .FindByPublicTokenAsync(query.Token, tokenHash, cancellationToken)
            ?? throw new KeyNotFoundException("Share token not found.");

        if (shareToken.IsRevoked)
        {
            throw new InvalidOperationException("This share link has been revoked.");
        }

        if (shareToken.ExpiresAt < DateTime.UtcNow)
        {
            throw new InvalidOperationException("This share link has expired.");
        }

        var payload = ReadPayload(shareToken.EncryptedPayload);
        await EnforceAccessSecurityAsync(shareToken, payload, query, cancellationToken);
        var allowedScopes = payload.Scopes.ToHashSet(StringComparer.OrdinalIgnoreCase);

        var includePersonalInfo = HasAnyScope(allowedScopes, "personalInformation", "medicalInformation");
        var includeBloodType = HasAnyScope(allowedScopes, "bloodType", "medicalInformation");
        var includeEmergencyContact = HasAnyScope(allowedScopes, "emergencyContact", "medicalInformation");
        var includeMedicalSummary = HasAnyScope(
            allowedScopes,
            "medicalInformation",
            "allergies",
            "medications",
            "diagnoses",
            "chronicConditions",
            "vaccines",
            "vaccinations");
        var includeMedicalHistory = HasAnyScope(
            allowedScopes,
            "medicalInformation",
            "medicalHistory",
            "labResults");
        var includeMedicalDocuments = HasAnyScope(
            allowedScopes,
            "medicalInformation",
            "medicalDocuments");

        var user = shareToken.User;
        var snapshot = payload.SharedSnapshot;
        var snapshotPatient = snapshot?.PatientInfo;
        var primaryEmergencyContact = includeEmergencyContact
            ? await _db.UserEmergencyContacts
                .AsNoTracking()
                .Where(contact => contact.UserId == user.Id)
                .OrderByDescending(contact => contact.IsPrimary)
                .ThenBy(contact => contact.CreatedAt)
                .Select(contact => new
                {
                    contact.Name,
                    contact.Phone,
                    contact.Relationship,
                })
                .FirstOrDefaultAsync(cancellationToken)
            : null;
        var patientInfo = new SharedPatientInfo
        {
            DisplayName = string.IsNullOrWhiteSpace(snapshotPatient?.DisplayName)
                ? user.FullName
                : snapshotPatient.DisplayName,
            Initials = string.IsNullOrWhiteSpace(snapshotPatient?.Initials)
                ? GetInitials(user.FirstName, user.LastName)
                : snapshotPatient.Initials,
            DateOfBirth = includePersonalInfo
                ? snapshotPatient?.DateOfBirth ?? user.DateOfBirth?.ToString("yyyy-MM-dd")
                : null,
            Gender = includePersonalInfo
                ? snapshotPatient?.Gender ?? user.Gender.ToGender()
                : null,
            BloodType = includeBloodType
                ? snapshotPatient?.BloodType ?? user.BloodType
                : null,
            EmergencyContactName = includeEmergencyContact
                ? snapshotPatient?.EmergencyContactName
                    ?? primaryEmergencyContact?.Name
                    ?? user.EmergencyContactName
                : null,
            EmergencyContactPhone = includeEmergencyContact
                ? snapshotPatient?.EmergencyContactPhone
                    ?? primaryEmergencyContact?.Phone
                    ?? user.EmergencyContactPhone
                : null,
            EmergencyContactRelationship = includeEmergencyContact
                ? snapshotPatient?.EmergencyContactRelationship
                    ?? primaryEmergencyContact?.Relationship
                    ?? user.EmergencyContactRelationship
                : null,
        };

        var medicalSummary = includeMedicalSummary
            ? new MedicalSummaryDto
            {
                Allergies = snapshot?.MedicalSummary.Allergies ?? [],
                ActiveMedications = snapshot?.MedicalSummary.ActiveMedications ?? [],
                Conditions = snapshot?.MedicalSummary.Conditions ?? [],
                Vaccinations = snapshot?.MedicalSummary.Vaccinations ?? [],
            }
            : new MedicalSummaryDto();

        var medicalHistory = includeMedicalHistory
            ? snapshot?.MedicalHistory ?? []
            : [];

        var documents = includeMedicalDocuments
            ? snapshot?.Documents ?? []
            : [];

        return new SharedDataResponse
        {
            Token = query.Token,
            PatientInfo = patientInfo,
            AccessLevel = shareToken.AccessLevel,
            ExpiresAt = shareToken.ExpiresAt,
            SharedAt = shareToken.CreatedAt,
            SharedBy = user.FullName,
            MedicalSummary = medicalSummary,
            MedicalHistory = medicalHistory,
            Documents = documents,
        };
    }

    private SharePayloadDto ReadPayload(string? encryptedPayload)
    {
        if (string.IsNullOrWhiteSpace(encryptedPayload))
        {
            return new SharePayloadDto();
        }

        try
        {
            var rawPayload = _shareProtection.UnprotectPayload(encryptedPayload);
            return SharePayloadMapper.Deserialize(rawPayload);
        }
        catch
        {
            return new SharePayloadDto();
        }
    }

    private async Task EnforceAccessSecurityAsync(
        ShareTokenEntity shareToken,
        SharePayloadDto payload,
        GetSharedDataQuery query,
        CancellationToken cancellationToken)
    {
        if (payload.SecuritySettings.PasswordProtected)
        {
            if (string.IsNullOrWhiteSpace(payload.SecretSettings.PasswordHash))
            {
                throw new UnauthorizedAccessException("This share link requires a password.");
            }

            if (string.IsNullOrWhiteSpace(query.AccessPassword)
                || !_shareProtection.VerifySecret(query.AccessPassword.Trim(), payload.SecretSettings.PasswordHash))
            {
                throw new UnauthorizedAccessException("Invalid share password.");
            }
        }

        if (payload.SecuritySettings.RequiresTwoFactorApproval)
        {
            if (query.AccessRequestId is null)
            {
                throw new UnauthorizedAccessException("Two-factor approval request is required.");
            }

            var request = await _db.ShareAccessApprovalRequests
                .FirstOrDefaultAsync(
                    entry => entry.Id == query.AccessRequestId.Value
                        && entry.ShareTokenId == shareToken.Id,
                    cancellationToken);

            if (request is null)
            {
                throw new UnauthorizedAccessException("Two-factor approval request was not found.");
            }

            if (request.Status == ShareAccessApprovalStatus.Pending
                && request.ExpiresAt <= DateTime.UtcNow)
            {
                request.Status = ShareAccessApprovalStatus.Expired;
                request.DecisionAt = DateTime.UtcNow;
                await _db.SaveChangesAsync(cancellationToken);
            }

            if (request.Status == ShareAccessApprovalStatus.Pending)
            {
                throw new UnauthorizedAccessException("Waiting for patient approval.");
            }

            if (request.Status == ShareAccessApprovalStatus.Denied)
            {
                throw new UnauthorizedAccessException("Access denied by patient.");
            }

            if (request.Status == ShareAccessApprovalStatus.Expired)
            {
                throw new UnauthorizedAccessException("Two-factor approval request expired.");
            }

            if (request.Status != ShareAccessApprovalStatus.Approved)
            {
                throw new UnauthorizedAccessException("Two-factor approval is required.");
            }
        }
    }

    private static bool HasAnyScope(HashSet<string> scopes, params string[] expectedScopes)
    {
        if (scopes.Count == 0)
        {
            return true;
        }

        return expectedScopes.Any(scopes.Contains);
    }

    private static string GetInitials(string? firstName, string? lastName)
    {
        var first = !string.IsNullOrEmpty(firstName) ? firstName[0].ToString().ToUpper() : "";
        var last = !string.IsNullOrEmpty(lastName) ? lastName[0].ToString().ToUpper() : "";
        return $"{first}{last}";
    }
}


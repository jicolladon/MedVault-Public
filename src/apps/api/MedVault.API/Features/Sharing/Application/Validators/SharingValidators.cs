using FluentValidation;
using MedVault.API.Features.Sharing.Application.DTOs;

namespace MedVault.API.Features.Sharing.Application.Validators;

public sealed class ShareSecuritySettingsValidator : AbstractValidator<ShareSecuritySettingsDto>
{
    public ShareSecuritySettingsValidator(bool requireSecretsWhenEnabled = false)
    {
        RuleFor(x => x.AccessDurationMinutes)
            .InclusiveBetween(5, 60 * 24 * 30)
            .WithMessage("Access duration must be between 5 minutes and 30 days.");

        RuleFor(x => x.AccessPassword)
            .NotEmpty().WithMessage("Access password is required when password protection is enabled.")
            .When(x => requireSecretsWhenEnabled && x.PasswordProtected);

        RuleFor(x => x.AccessPassword)
            .MinimumLength(8)
            .MaximumLength(128)
            .When(x => x.PasswordProtected && !string.IsNullOrWhiteSpace(x.AccessPassword));

        RuleFor(x => x.AccessPassword)
            .Matches("^(?=.*[A-Za-z])(?=.*\\d).+$")
            .WithMessage("Access password must include at least one letter and one number.")
            .When(x => x.PasswordProtected && !string.IsNullOrWhiteSpace(x.AccessPassword));

        RuleFor(x => x.VerificationCode)
            .MinimumLength(4)
            .MaximumLength(32)
            .Matches("^[A-Za-z0-9-]+$")
            .WithMessage("Verification code can only contain letters, numbers, and dashes.")
            .When(x => x.RequiresTwoFactorApproval && !string.IsNullOrWhiteSpace(x.VerificationCode));
    }
}

public sealed class ShareSnapshotValidator : AbstractValidator<ShareSnapshotDto>
{
    public ShareSnapshotValidator()
    {
        RuleFor(x => x)
            .Must(HaveAnySharedContent)
            .WithMessage("Shared snapshot must include at least one selected data section.");

        RuleFor(x => x.Documents)
            .Must(items => items.Count <= 10)
            .WithMessage("A maximum of 10 shared documents is allowed.");

        RuleFor(x => x.MedicalHistory)
            .Must(items => items.Count <= 500)
            .WithMessage("A maximum of 500 medical history entries is allowed.");

        RuleForEach(x => x.Documents)
            .SetValidator(new SharedDocumentValidator());
    }

    private static bool HaveAnySharedContent(ShareSnapshotDto snapshot)
    {
        if (snapshot.PatientInfo is not null)
        {
            if (!string.IsNullOrWhiteSpace(snapshot.PatientInfo.DateOfBirth)
                || snapshot.PatientInfo.Gender is not null
                || !string.IsNullOrWhiteSpace(snapshot.PatientInfo.BloodType)
                || !string.IsNullOrWhiteSpace(snapshot.PatientInfo.EmergencyContactName)
                || !string.IsNullOrWhiteSpace(snapshot.PatientInfo.EmergencyContactPhone)
                || !string.IsNullOrWhiteSpace(snapshot.PatientInfo.EmergencyContactRelationship))
            {
                return true;
            }
        }

        return snapshot.MedicalSummary.Allergies.Count > 0
            || snapshot.MedicalSummary.ActiveMedications.Count > 0
            || snapshot.MedicalSummary.Conditions.Count > 0
            || snapshot.MedicalSummary.Vaccinations.Count > 0
            || snapshot.MedicalHistory.Count > 0
            || snapshot.Documents.Count > 0;
    }
}

public sealed class SharedDocumentValidator : AbstractValidator<SharedDocumentDto>
{
    private const int MaxSharedDocumentSizeBytes = 10 * 1024 * 1024;
    private const int MaxSharedDocumentContentBase64Length = 14_000_000;

    public SharedDocumentValidator()
    {
        RuleFor(x => x.Id)
            .NotEmpty()
            .MaximumLength(80);

        RuleFor(x => x.Title)
            .NotEmpty()
            .MaximumLength(240);

        RuleFor(x => x.Category)
            .MaximumLength(120)
            .When(x => x.Category is not null);

        RuleFor(x => x.Description)
            .MaximumLength(1200)
            .When(x => x.Description is not null);

        RuleFor(x => x.FileName)
            .MaximumLength(300)
            .When(x => x.FileName is not null);

        RuleFor(x => x.ContentType)
            .MaximumLength(120)
            .When(x => x.ContentType is not null);

        RuleFor(x => x.FileSizeBytes)
            .InclusiveBetween(1, MaxSharedDocumentSizeBytes)
            .When(x => x.FileSizeBytes is not null);

        RuleFor(x => x.ContentBase64)
            .MaximumLength(MaxSharedDocumentContentBase64Length)
            .Must(BeValidBase64)
            .WithMessage("Document content must be a valid base64 string.")
            .When(x => x.ContentBase64 is not null);

        RuleFor(x => x.ContentFileId)
            .NotEmpty()
            .WithMessage("Content file ID is required for document sharing.")
            .When(x => x.ContentFileId is not null);

        RuleFor(x => x.ContentType)
            .NotEmpty()
            .WithMessage("Content type is required for document sharing.")
            .When(x => x.ContentFileId is not null || x.ContentBase64 is not null);

        RuleFor(x => x.FileSizeBytes)
            .NotNull()
            .WithMessage("File size is required for document sharing.")
            .When(x => x.ContentFileId is not null || x.ContentBase64 is not null);

        RuleFor(x => x.DownloadUrl)
            .MaximumLength(2000)
            .When(x => x.DownloadUrl is not null);

    }

    private static bool BeValidBase64(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return false;
        }

        try
        {
            _ = Convert.FromBase64String(value);
            return true;
        }
        catch (FormatException)
        {
            return false;
        }
    }
}

public sealed class CreateEmergencyShareLinkRequestValidator : AbstractValidator<CreateEmergencyShareLinkRequest>
{
    private static readonly HashSet<string> AllowedScopes =
    [
        "personalInformation",
        "medicalInformation",
        "bloodType",
        "allergies",
        "medications",
        "diagnoses",
        "chronicConditions",
        "vaccines",
        "vaccinations",
        "emergencyContact",
        "labResults",
        "medicalDocuments",
        "medicalHistory"
    ];

    public CreateEmergencyShareLinkRequestValidator()
    {
        RuleFor(x => x.Label)
            .MaximumLength(200)
            .When(x => x.Label is not null);

        RuleFor(x => x.Scopes)
            .NotEmpty().WithMessage("At least one sharing scope is required.")
            .Must(scopes => scopes.Count <= 25)
            .WithMessage("A maximum of 25 sharing scopes is allowed.");

        RuleForEach(x => x.Scopes)
            .Must(BeValidScope)
            .WithMessage("One or more sharing scopes are invalid.");

        RuleFor(x => x.SecuritySettings)
            .SetValidator(new ShareSecuritySettingsValidator(requireSecretsWhenEnabled: true));

        RuleFor(x => x.SharedSnapshot)
            .NotNull().WithMessage("Shared snapshot is required.")
            .SetValidator(new ShareSnapshotValidator()!);
    }

    private static bool BeValidScope(string? scope)
    {
        if (string.IsNullOrWhiteSpace(scope))
        {
            return false;
        }

        return AllowedScopes.Contains(scope.Trim());
    }
}

public sealed class CreatePhysicianShareLinkRequestValidator : AbstractValidator<CreatePhysicianShareLinkRequest>
{
    private static readonly HashSet<string> AllowedScopes =
    [
        "personalInformation",
        "medicalInformation",
        "bloodType",
        "allergies",
        "medications",
        "diagnoses",
        "chronicConditions",
        "vaccines",
        "vaccinations",
        "emergencyContact",
        "labResults",
        "medicalDocuments",
        "medicalHistory"
    ];

    public CreatePhysicianShareLinkRequestValidator()
    {
        RuleFor(x => x.Label)
            .MaximumLength(200)
            .When(x => x.Label is not null);

        RuleFor(x => x.PhysicianName)
            .NotEmpty().WithMessage("Physician name is required.")
            .MaximumLength(150);

        RuleFor(x => x.PhysicianEmail)
            .EmailAddress().WithMessage("Physician email must be valid.")
            .MaximumLength(320)
            .When(x => !string.IsNullOrWhiteSpace(x.PhysicianEmail));

        RuleFor(x => x.Notes)
            .MaximumLength(1000)
            .When(x => x.Notes is not null);

        RuleFor(x => x.Scopes)
            .NotEmpty().WithMessage("At least one sharing scope is required.")
            .Must(scopes => scopes.Count <= 25)
            .WithMessage("A maximum of 25 sharing scopes is allowed.");

        RuleForEach(x => x.Scopes)
            .Must(BeValidScope)
            .WithMessage("One or more sharing scopes are invalid.");

        RuleFor(x => x.SecuritySettings)
            .SetValidator(new ShareSecuritySettingsValidator(requireSecretsWhenEnabled: true));

        RuleFor(x => x.SharedSnapshot)
            .NotNull().WithMessage("Shared snapshot is required.")
            .SetValidator(new ShareSnapshotValidator()!);
    }

    private static bool BeValidScope(string? scope)
    {
        if (string.IsNullOrWhiteSpace(scope))
        {
            return false;
        }

        return AllowedScopes.Contains(scope.Trim());
    }
}

public sealed class UpdateShareLinkRequestValidator : AbstractValidator<UpdateShareLinkRequest>
{
    private static readonly HashSet<string> AllowedScopes =
    [
        "personalInformation",
        "medicalInformation",
        "bloodType",
        "allergies",
        "medications",
        "diagnoses",
        "chronicConditions",
        "vaccines",
        "vaccinations",
        "emergencyContact",
        "labResults",
        "medicalDocuments",
        "medicalHistory"
    ];

    public UpdateShareLinkRequestValidator()
    {
        RuleFor(x => x.Label)
            .MaximumLength(200)
            .When(x => x.Label is not null);

        RuleFor(x => x.Scopes)
            .NotEmpty().WithMessage("At least one sharing scope is required.")
            .Must(scopes => scopes.Count <= 25)
            .WithMessage("A maximum of 25 sharing scopes is allowed.");

        RuleForEach(x => x.Scopes)
            .Must(BeValidScope)
            .WithMessage("One or more sharing scopes are invalid.");

        RuleFor(x => x.SecuritySettings)
            .SetValidator(new ShareSecuritySettingsValidator());

        RuleFor(x => x.SharedSnapshot)
            .SetValidator(new ShareSnapshotValidator()!)
            .When(x => x.SharedSnapshot is not null);
    }

    private static bool BeValidScope(string? scope)
    {
        if (string.IsNullOrWhiteSpace(scope))
        {
            return false;
        }

        return AllowedScopes.Contains(scope.Trim());
    }
}


using FluentValidation;
using MedVault.API.Features.Configuration.Application.DTOs;

namespace MedVault.API.Features.Configuration.Application.Validators;

public sealed class SaveNotificationPreferencesRequestValidator : AbstractValidator<SaveNotificationPreferencesRequest>
{
    public SaveNotificationPreferencesRequestValidator()
    {
        RuleFor(x => x.PushDeviceToken)
            .MaximumLength(2048)
            .When(x => x.PushDeviceToken is not null)
            .WithMessage("Push device token exceeds the supported length.");

        RuleFor(x => x.Language)
            .MaximumLength(10)
            .Matches("^[a-zA-Z]{2,3}(-[a-zA-Z]{2,4})?$")
            .When(x => !string.IsNullOrWhiteSpace(x.Language))
            .WithMessage("Language must use a valid short locale format such as en, es-ES, or ca-ES.");

        RuleFor(x => x)
            .Must(x =>
                (x.QuietHoursStart is null && x.QuietHoursEnd is null)
                || (x.QuietHoursStart is not null && x.QuietHoursEnd is not null))
            .WithMessage("Quiet hours require both start and end values.");

        RuleFor(x => x)
            .Must(x => x.QuietHoursStart is null || x.QuietHoursStart != x.QuietHoursEnd)
            .WithMessage("Quiet hours start and end cannot be the same time.");
    }
}

public sealed class EnableCloudSyncRequestValidator : AbstractValidator<EnableCloudSyncRequest>
{
    private static readonly string[] ValidProviders = ["MedVault", "GoogleDrive", "iCloud"];

    public EnableCloudSyncRequestValidator()
    {
        RuleFor(x => x.Provider)
            .NotEmpty()
            .Must(p => ValidProviders.Contains(p))
            .WithMessage($"Provider must be one of: {string.Join(", ", ValidProviders)}");
    }
}

public sealed class UpdateSharingFeatureSettingsRequestValidator : AbstractValidator<UpdateSharingFeatureSettingsRequest>
{
    public UpdateSharingFeatureSettingsRequestValidator()
    {
        RuleFor(x => x.MaxSharingLinksPerUser)
            .InclusiveBetween(0, 100)
            .WithMessage("Maximum sharing links per user must be between 0 and 100.");

        RuleFor(x => x.MinDocumentsToShareLimit)
            .InclusiveBetween(0, 10)
            .WithMessage("Minimum documents to share limit must be between 0 and 10.");

        RuleFor(x => x.MaxDocumentsToShareLimit)
            .InclusiveBetween(0, 10)
            .WithMessage("Maximum documents to share limit must be between 0 and 10.");

        RuleFor(x => x.MaxDocumentsToShareLimit)
            .GreaterThanOrEqualTo(x => x.MinDocumentsToShareLimit)
            .WithMessage("Maximum documents to share limit must be greater than or equal to the minimum limit.");

        RuleFor(x => x.DefaultMaxDocumentsToShare)
            .InclusiveBetween(0, 10)
            .WithMessage("Default max documents to share must be between 0 and 10.");

        RuleFor(x => x.DefaultMaxDocumentsToShare)
            .GreaterThanOrEqualTo(x => x.MinDocumentsToShareLimit)
            .WithMessage("Default max documents to share must be greater than or equal to the minimum limit.");

        RuleFor(x => x.DefaultMaxDocumentsToShare)
            .LessThanOrEqualTo(x => x.MaxDocumentsToShareLimit)
            .WithMessage("Default max documents to share must be less than or equal to the maximum limit.");

        RuleFor(x => x.MaxSharedDocumentBytes)
            .InclusiveBetween(1024, 10 * 1024 * 1024)
            .WithMessage("Maximum shared document size must be between 1 KB and 10 MB.");
    }
}


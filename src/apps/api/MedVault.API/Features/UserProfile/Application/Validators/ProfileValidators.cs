using FluentValidation;
using MedVault.API.Features.UserProfile.Application.DTOs;

namespace MedVault.API.Features.UserProfile.Application.Validators;

public sealed class UpdateProfileRequestValidator : AbstractValidator<UpdateProfileRequest>
{
    private static readonly string[] ValidBloodTypes =
        ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"];

    public UpdateProfileRequestValidator()
    {
        RuleFor(x => x.FirstName)
            .MaximumLength(100)
            .When(x => x.FirstName is not null);

        RuleFor(x => x.DisplayName)
            .NotEmpty()
            .MaximumLength(150)
            .When(x => x.DisplayName is not null);

        RuleFor(x => x.Email)
            .EmailAddress()
            .MaximumLength(320)
            .When(x => x.Email is not null);

        RuleFor(x => x.ProfilePictureUrl)
            .Must(url => Uri.TryCreate(url, UriKind.Absolute, out _))
            .WithMessage("Profile picture URL must be a valid absolute URL.")
            .When(x => x.ProfilePictureUrl is not null);

        RuleFor(x => x.LastName)
            .MaximumLength(100)
            .When(x => x.LastName is not null);

        RuleFor(x => x.DateOfBirth)
            .LessThan(DateOnly.FromDateTime(DateTime.UtcNow))
            .WithMessage("Date of birth must be in the past.")
            .When(x => x.DateOfBirth.HasValue);

        RuleFor(x => x.PhoneNumber)
            .Matches(@"^\+?[\d\s\-()]{7,20}$")
            .WithMessage("Invalid phone number format.")
            .When(x => x.PhoneNumber is not null);

        RuleFor(x => x.PostalCode)
            .MaximumLength(20)
            .When(x => x.PostalCode is not null);

        RuleFor(x => x.Country)
            .MaximumLength(100)
            .When(x => x.Country is not null);

        RuleFor(x => x.BloodType)
            .Must(bt => ValidBloodTypes.Contains(bt))
            .WithMessage($"Blood type must be one of: {string.Join(", ", ValidBloodTypes)}")
            .When(x => x.BloodType is not null);

        RuleFor(x => x.EmergencyContactPhone)
            .Matches(@"^\+?[\d\s\-()]{7,20}$")
            .WithMessage("Invalid emergency contact phone format.")
            .When(x => x.EmergencyContactPhone is not null);
    }
}

public sealed class UpsertEmergencyContactRequestValidator : AbstractValidator<UpsertEmergencyContactRequest>
{
    public UpsertEmergencyContactRequestValidator()
    {
        RuleFor(x => x.ContactId)
            .MaximumLength(128)
            .When(x => x.ContactId is not null);

        RuleFor(x => x.Name)
            .NotEmpty()
            .MaximumLength(100);

        RuleFor(x => x.Relationship)
            .NotEmpty()
            .MaximumLength(50);

        RuleFor(x => x.Phone)
            .NotEmpty()
            .Matches(@"^\+?[\d\s\-()]{7,20}$")
            .WithMessage("Invalid emergency contact phone format.");

        RuleFor(x => x.Email)
            .EmailAddress()
            .MaximumLength(320)
            .When(x => x.Email is not null);
    }
}

public sealed class ReplaceEmergencyContactsRequestValidator : AbstractValidator<ReplaceEmergencyContactsRequest>
{
    public ReplaceEmergencyContactsRequestValidator()
    {
        RuleFor(x => x.Contacts)
            .Must(contacts => contacts.Count <= 20)
            .WithMessage("A maximum of 20 emergency contacts is allowed.");

        RuleFor(x => x.Contacts)
            .Must(contacts => contacts.Count(c => c.IsPrimary) <= 1)
            .WithMessage("Only one emergency contact can be marked as primary.");

        RuleForEach(x => x.Contacts)
            .SetValidator(new UpsertEmergencyContactRequestValidator());
    }
}


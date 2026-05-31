using FluentValidation;
using MedVault.API.Features.Auth.Application.DTOs;

namespace MedVault.API.Features.Auth.Application.Validators;

public static class PkceConstants
{
    public const int MinLength = 43;
    public const int MaxLength = 128;
    public const string AllowedPattern = "^[A-Za-z0-9\\-._~]+$";
}

public class GoogleLoginRequestValidator : AbstractValidator<GoogleLoginRequest>
{
    public GoogleLoginRequestValidator()
    {
        RuleFor(x => x.IdToken)
            .NotEmpty().WithMessage("Google ID token is required.");
    }
}

public class RegisterRequestValidator : AbstractValidator<RegisterRequest>
{
    public RegisterRequestValidator()
    {
        RuleFor(x => x.GoogleIdToken)
            .NotEmpty().WithMessage("Google ID token is required.");

        RuleFor(x => x.FirstName)
            .NotEmpty().WithMessage("First name is required.")
            .MaximumLength(100);

        RuleFor(x => x.LastName)
            .NotEmpty().WithMessage("Last name is required.")
            .MaximumLength(100);

        RuleFor(x => x.DateOfBirth)
            .Must(d => d == null || d.Value < DateTime.UtcNow)
            .WithMessage("Date of birth must be in the past.");

        RuleFor(x => x.PhoneNumber)
            .MaximumLength(30);

        RuleFor(x => x.TermsAccepted)
            .Equal(true).WithMessage("You must accept the Terms of Service.");

        RuleFor(x => x.PrivacyPolicyAccepted)
            .Equal(true).WithMessage("You must accept the Privacy Policy.");
    }
}

public class RefreshTokenRequestValidator : AbstractValidator<RefreshTokenRequest>
{
    public RefreshTokenRequestValidator()
    {
        RuleFor(x => x.RefreshToken)
            .NotEmpty().WithMessage("Refresh token is required.");
    }
}

public class EmailRegisterRequestValidator : AbstractValidator<EmailRegisterRequest>
{
    public EmailRegisterRequestValidator()
    {
        RuleFor(x => x.Email)
            .NotEmpty().EmailAddress();

        RuleFor(x => x.Password)
            .NotEmpty()
            .MinimumLength(8)
            .MaximumLength(128);

        RuleFor(x => x.FirstName)
            .NotEmpty()
            .MaximumLength(100);

        RuleFor(x => x.LastName)
            .NotEmpty()
            .MaximumLength(100);

        RuleFor(x => x.TermsAccepted)
            .Equal(true).WithMessage("You must accept the Terms of Service.");

        RuleFor(x => x.PrivacyPolicyAccepted)
            .Equal(true).WithMessage("You must accept the Privacy Policy.");

        RuleFor(x => x.CodeChallenge)
            .NotEmpty()
            .MinimumLength(PkceConstants.MinLength)
            .MaximumLength(PkceConstants.MaxLength)
            .Matches(PkceConstants.AllowedPattern)
            .WithMessage("Code challenge format is invalid.");

        RuleFor(x => x.CodeChallengeMethod)
            .Must(m => m is "S256" or "plain")
            .WithMessage("Code challenge method must be S256 or plain.");
    }
}

public class EmailLoginRequestValidator : AbstractValidator<EmailLoginRequest>
{
    public EmailLoginRequestValidator()
    {
        RuleFor(x => x.Email)
            .NotEmpty().EmailAddress();

        RuleFor(x => x.Password)
            .NotEmpty()
            .MinimumLength(8)
            .MaximumLength(128);

        RuleFor(x => x.CodeChallenge)
            .NotEmpty()
            .MinimumLength(PkceConstants.MinLength)
            .MaximumLength(PkceConstants.MaxLength)
            .Matches(PkceConstants.AllowedPattern)
            .WithMessage("Code challenge format is invalid.");

        RuleFor(x => x.CodeChallengeMethod)
            .Must(m => m is "S256" or "plain")
            .WithMessage("Code challenge method must be S256 or plain.");
    }
}

public class PkceAuthorizationCodeRequestValidator : AbstractValidator<PkceAuthorizationCodeRequest>
{
    public PkceAuthorizationCodeRequestValidator()
    {
        RuleFor(x => x.AuthorizationCode)
            .NotEmpty();

        RuleFor(x => x.CodeVerifier)
            .NotEmpty()
            .MinimumLength(PkceConstants.MinLength)
            .MaximumLength(PkceConstants.MaxLength)
            .Matches(PkceConstants.AllowedPattern)
            .WithMessage("Code verifier format is invalid.");
    }
}


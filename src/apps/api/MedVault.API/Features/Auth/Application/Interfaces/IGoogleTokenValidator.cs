using Google.Apis.Auth;

namespace MedVault.API.Features.Auth.Application.Interfaces;

public interface IGoogleTokenValidator
{
    Task<GoogleJsonWebSignature.Payload?> ValidateAsync(string idToken);
}


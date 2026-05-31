using MedVault.API.Features.Auth.Domain;
using System.Security.Claims;

namespace MedVault.API.Features.Auth.Application.Interfaces;

public interface IJwtTokenService
{
    string GenerateAccessToken(AppUser user);
    string GenerateRefreshToken();
    ClaimsPrincipal? ValidateAccessToken(string token);
    DateTime GetAccessTokenExpiration();
}


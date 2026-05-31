using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using FluentValidation;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MedVault.API.Common.Models;
using MedVault.API.Data;
using MedVault.API.Features.Auth.Application.DTOs;
using MedVault.API.Features.Auth.Application.Interfaces;
using MedVault.API.Features.Auth.Domain;

namespace MedVault.API.Features.Auth.Presentation;

public class EmailAuthController : AuthControllerBase
{
    private static readonly Regex PkceVerifierRegex = new("^[A-Za-z0-9\\-._~]+$", RegexOptions.Compiled);

    private readonly IValidator<EmailRegisterRequest> _emailRegisterValidator;
    private readonly IValidator<EmailLoginRequest> _emailLoginValidator;
    private readonly IValidator<PkceAuthorizationCodeRequest> _pkceCodeValidator;
    private readonly UserManager<AppUser> _userManager;
    private readonly MedVaultDbContext _db;
    private readonly IJwtTokenService _jwtService;
    private readonly IPkceAuthorizationCodeStore _pkceCodeStore;

    public EmailAuthController(
        IValidator<EmailRegisterRequest> emailRegisterValidator,
        IValidator<EmailLoginRequest> emailLoginValidator,
        IValidator<PkceAuthorizationCodeRequest> pkceCodeValidator,
        UserManager<AppUser> userManager,
        MedVaultDbContext db,
        IJwtTokenService jwtService,
        IPkceAuthorizationCodeStore pkceCodeStore)
    {
        _emailRegisterValidator = emailRegisterValidator;
        _emailLoginValidator = emailLoginValidator;
        _pkceCodeValidator = pkceCodeValidator;
        _userManager = userManager;
        _db = db;
        _jwtService = jwtService;
        _pkceCodeStore = pkceCodeStore;
    }

    [HttpPost("email/register")]
    [ProducesResponseType(typeof(ApiResponse<PkceAuthorizationCodeResponse>), 201)]
    [ProducesResponseType(typeof(ApiResponse), 400)]
    public async Task<IActionResult> RegisterWithEmail([FromBody] EmailRegisterRequest request, CancellationToken ct)
    {
        var validation = await _emailRegisterValidator.ValidateAsync(request, ct);
        if (!validation.IsValid)
            return BadRequest(ApiResponse.Fail(validation.Errors.Select(e => e.ErrorMessage).ToList()));

        var existing = await _userManager.FindByEmailAsync(request.Email);
        if (existing is not null)
            return Conflict(ApiResponse.Fail("A user with this email already exists."));

        var user = new AppUser
        {
            Id = Guid.NewGuid(),
            UserName = request.Email,
            Email = request.Email,
            EmailConfirmed = true,
            FirstName = request.FirstName,
            LastName = request.LastName,
            TermsAccepted = request.TermsAccepted,
            TermsAcceptedDate = DateTime.UtcNow,
            PrivacyPolicyAccepted = request.PrivacyPolicyAccepted,
            PrivacyPolicyAcceptedDate = DateTime.UtcNow,
            AccountStatus = "Active",
            LastLoginDate = DateTime.UtcNow,
            LastActivityDate = DateTime.UtcNow,
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow,
            ProfileCompleteness = CalculateProfileCompleteness(request.FirstName, request.LastName)
        };

        var createResult = await _userManager.CreateAsync(user, request.Password);
        if (!createResult.Succeeded)
        {
            var errors = createResult.Errors.Select(e => e.Description).ToList();
            return BadRequest(ApiResponse.Fail(errors));
        }

        _db.UserConsents.AddRange(
            new UserConsentEntity
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                ConsentType = "Terms",
                ConsentGiven = true,
                ConsentDate = DateTime.UtcNow,
                IpAddress = GetIpAddress(),
                UserAgent = GetUserAgent(),
                ConsentVersion = "1.0"
            },
            new UserConsentEntity
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                ConsentType = "Privacy",
                ConsentGiven = true,
                ConsentDate = DateTime.UtcNow,
                IpAddress = GetIpAddress(),
                UserAgent = GetUserAgent(),
                ConsentVersion = "1.0"
            }
        );

        await _db.SaveChangesAsync(ct);

        var authCode = _pkceCodeStore.CreateCode(new PkceAuthorizationCodeRecord(
            user.Id,
            request.CodeChallenge,
            request.CodeChallengeMethod,
            GetIpAddress(),
            GetUserAgent(),
            true));

        return StatusCode(201, ApiResponse<PkceAuthorizationCodeResponse>.Ok(
            new PkceAuthorizationCodeResponse(authCode, 300, true),
            "Registration successful. Exchange authorization code with PKCE verifier."));
    }

    [HttpPost("email/login")]
    [ProducesResponseType(typeof(ApiResponse<PkceAuthorizationCodeResponse>), 200)]
    [ProducesResponseType(typeof(ApiResponse), 401)]
    public async Task<IActionResult> LoginWithEmail([FromBody] EmailLoginRequest request, CancellationToken ct)
    {
        var validation = await _emailLoginValidator.ValidateAsync(request, ct);
        if (!validation.IsValid)
            return BadRequest(ApiResponse.Fail(validation.Errors.Select(e => e.ErrorMessage).ToList()));

        var user = await _userManager.FindByEmailAsync(request.Email);
        if (user is null || !user.IsActive)
            return Unauthorized(ApiResponse.Fail("Invalid email or password."));

        var isPasswordValid = await _userManager.CheckPasswordAsync(user, request.Password);
        if (!isPasswordValid)
            return Unauthorized(ApiResponse.Fail("Invalid email or password."));

        user.LastLoginDate = DateTime.UtcNow;
        user.LastActivityDate = DateTime.UtcNow;
        await _userManager.UpdateAsync(user);

        var authCode = _pkceCodeStore.CreateCode(new PkceAuthorizationCodeRecord(
            user.Id,
            request.CodeChallenge,
            request.CodeChallengeMethod,
            GetIpAddress(),
            GetUserAgent(),
            false));

        return Ok(ApiResponse<PkceAuthorizationCodeResponse>.Ok(
            new PkceAuthorizationCodeResponse(authCode, 300, false),
            "Authorization code issued. Exchange with PKCE verifier."));
    }

    [HttpPost("pkce/token")]
    [ProducesResponseType(typeof(ApiResponse<PkceTokenResponse>), 200)]
    [ProducesResponseType(typeof(ApiResponse), 401)]
    public async Task<IActionResult> ExchangePkceCode([FromBody] PkceAuthorizationCodeRequest request, CancellationToken ct)
    {
        var validation = await _pkceCodeValidator.ValidateAsync(request, ct);
        if (!validation.IsValid)
            return BadRequest(ApiResponse.Fail(validation.Errors.Select(e => e.ErrorMessage).ToList()));

        if (!_pkceCodeStore.TryRedeemCode(request.AuthorizationCode, out var record) || record is null)
            return Unauthorized(ApiResponse.Fail("Invalid or expired authorization code."));

        if (!IsPkceVerifierValid(request.CodeVerifier, record.CodeChallenge, record.CodeChallengeMethod))
            return Unauthorized(ApiResponse.Fail("Invalid PKCE code verifier."));

        var user = await _userManager.Users.FirstOrDefaultAsync(u => u.Id == record.UserId, ct);
        if (user is null || !user.IsActive)
            return Unauthorized(ApiResponse.Fail("User is not active."));

        user.LastActivityDate = DateTime.UtcNow;
        await _userManager.UpdateAsync(user);

        var tokenResponse = await IssueTokensAsync(user, record.IpAddress ?? GetIpAddress(), record.UserAgent ?? GetUserAgent(), ct);

        return Ok(ApiResponse<PkceTokenResponse>.Ok(tokenResponse));
    }

    private async Task<PkceTokenResponse> IssueTokensAsync(AppUser user, string? ipAddress, string? userAgent, CancellationToken ct)
    {
        var accessToken = _jwtService.GenerateAccessToken(user);
        var refreshToken = _jwtService.GenerateRefreshToken();
        var accessTokenExpiresAt = _jwtService.GetAccessTokenExpiration();
        var refreshTokenDays = int.TryParse(HttpContext.RequestServices.GetRequiredService<IConfiguration>()["Jwt:RefreshTokenExpirationDays"], out var days)
            ? days
            : 30;

        _db.RefreshTokens.Add(new RefreshTokenEntity
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            Token = HashToken(refreshToken),
            IssuedAt = DateTime.UtcNow,
            ExpiresAt = DateTime.UtcNow.AddDays(refreshTokenDays),
            IsActive = true
        });

        _db.UserSessions.Add(new UserSessionEntity
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            SessionToken = HashToken(accessToken),
            IpAddress = ipAddress,
            UserAgent = userAgent,
            CreatedAt = DateTime.UtcNow,
            LastActivityAt = DateTime.UtcNow,
            ExpiresAt = accessTokenExpiresAt,
            IsActive = true
        });

        await _db.SaveChangesAsync(ct);

        return new PkceTokenResponse(
            accessToken,
            refreshToken,
            accessTokenExpiresAt,
            new UserSummaryDto(
                user.Id,
                user.Email ?? string.Empty,
                user.FirstName,
                user.LastName,
                user.ProfilePictureUrl,
                user.ProfileCompleteness
            )
        );
    }

    private static string HashToken(string token)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(token));
        return Convert.ToBase64String(bytes);
    }

    private static bool IsPkceVerifierValid(string verifier, string codeChallenge, string method)
    {
        if (string.IsNullOrWhiteSpace(verifier) || !PkceVerifierRegex.IsMatch(verifier))
            return false;

        if (method == "plain")
            return string.Equals(verifier, codeChallenge, StringComparison.Ordinal);

        if (!string.Equals(method, "S256", StringComparison.Ordinal))
            return false;

        var bytes = SHA256.HashData(Encoding.ASCII.GetBytes(verifier));
        var derived = Convert.ToBase64String(bytes)
            .Replace('+', '-')
            .Replace('/', '_')
            .TrimEnd('=');

        return string.Equals(derived, codeChallenge, StringComparison.Ordinal);
    }

    private static int CalculateProfileCompleteness(string firstName, string lastName)
    {
        var fields = new[] { firstName, lastName };
        var filled = fields.Count(f => !string.IsNullOrWhiteSpace(f));
        return (int)((double)filled / fields.Length * 100);
    }
}


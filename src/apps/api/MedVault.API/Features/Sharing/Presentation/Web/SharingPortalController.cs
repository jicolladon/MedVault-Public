using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.DependencyInjection;
using MedVault.API.Common.CQRS;
using MedVault.API.Data;
using MedVault.API.Features.Sharing.Application.Commands;
using MedVault.API.Features.Sharing.Application.DTOs;
using MedVault.API.Features.Sharing.Application.Handlers;
using MedVault.API.Features.Sharing.Application.Interfaces;
using MedVault.API.Features.Sharing.Application.Queries;
using System.Security.Cryptography;
using System.Text;

namespace MedVault.API.Features.Sharing.Presentation.Web;

[AllowAnonymous]
[ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
public sealed class SharingPortalController : Controller
{
    private const string AccessPasswordCookiePrefix = "mv_share_pwd_";
    private const string VerificationCodeCookiePrefix = "mv_share_code_";
    private const string AccessRequestCookiePrefix = "mv_share_req_";
    private static readonly TimeSpan SharedDataCacheDuration = TimeSpan.FromSeconds(60);

    private readonly IQueryHandler<ValidateShareTokenQuery, ShareTokenValidationDto> _validateHandler;
    private readonly IQueryHandler<GetSharedDataQuery, SharedDataResponse> _getDataHandler;
    private readonly ICommandHandler<RequestTwoFactorApprovalCommand, TwoFactorApprovalRequestResponse> _requestTwoFactorHandler;
    private readonly IQueryHandler<GetTwoFactorApprovalStatusQuery, TwoFactorApprovalStatusResponse> _getTwoFactorStatusHandler;
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly IConfiguration _configuration;
    private readonly MedVaultDbContext _db;
    private readonly IShareProtectionService _shareProtection;
    private readonly IDataProtector _credentialProtector;
    private readonly IMemoryCache _cache;
    private readonly ILogger<SharingPortalController> _logger;

    public SharingPortalController(
        IQueryHandler<ValidateShareTokenQuery, ShareTokenValidationDto> validateHandler,
        IQueryHandler<GetSharedDataQuery, SharedDataResponse> getDataHandler,
        ICommandHandler<RequestTwoFactorApprovalCommand, TwoFactorApprovalRequestResponse> requestTwoFactorHandler,
        IQueryHandler<GetTwoFactorApprovalStatusQuery, TwoFactorApprovalStatusResponse> getTwoFactorStatusHandler,
        IServiceScopeFactory scopeFactory,
        IConfiguration configuration,
        MedVaultDbContext db,
        IShareProtectionService shareProtection,
        IDataProtectionProvider dataProtectionProvider,
        IMemoryCache cache,
        ILogger<SharingPortalController> logger)
    {
        _validateHandler = validateHandler;
        _getDataHandler = getDataHandler;
        _requestTwoFactorHandler = requestTwoFactorHandler;
        _getTwoFactorStatusHandler = getTwoFactorStatusHandler;
        _scopeFactory = scopeFactory;
        _configuration = configuration;
        _db = db;
        _shareProtection = shareProtection;
        _credentialProtector = dataProtectionProvider.CreateProtector("SharingPortalDocumentCredentials.v1");
        _cache = cache;
        _logger = logger;
    }

    [HttpGet("/s/{shareCode}")]
    public async Task<IActionResult> ResolveShortLink(
        string shareCode,
        [FromQuery] string? lang,
        CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(shareCode))
        {
            return NotFound();
        }

        var normalizedCode = shareCode.Trim().ToUpperInvariant();
        var matchedToken = await _db.ShareTokens
            .AsNoTracking()
            .Where(t => t.ShareCode == normalizedCode
                        && !t.IsRevoked
                        && t.ExpiresAt >= DateTime.UtcNow)
            .Select(t => t.Token)
            .FirstOrDefaultAsync(ct);
        if (string.IsNullOrWhiteSpace(matchedToken))
        {
            matchedToken = await _db.ShareTokens
                .AsNoTracking()
                .Where(t => t.ShareCode == null
                            && !t.IsRevoked
                            && t.ExpiresAt >= DateTime.UtcNow)
                .Select(t => t.Token)
                .AsAsyncEnumerable()
                .FirstOrDefaultAsync(
                    token => string.Equals(
                        SharePayloadMapper.BuildShareCode(token),
                        normalizedCode,
                        StringComparison.OrdinalIgnoreCase),
                    ct);
        }

        if (string.IsNullOrWhiteSpace(matchedToken))
        {
            return NotFound();
        }

        var queryString = string.IsNullOrWhiteSpace(lang)
            ? string.Empty
            : $"?lang={Uri.EscapeDataString(lang)}";

        return Redirect($"/share/{Uri.EscapeDataString(matchedToken)}{queryString}");
    }

    [HttpGet("/share/{token}")]
    public async Task<IActionResult> Index(
        string token,
        [FromQuery] string? lang,
        CancellationToken ct)
    {
        return await RenderAsync(token, lang, new ShareUnlockInputModel(), unlockAttempted: false, ct);
    }

    [HttpPost("/share/{token}")]
    public async Task<IActionResult> Unlock(
        string token,
        [FromQuery] string? lang,
        [FromForm] ShareUnlockInputModel input,
        CancellationToken ct)
    {
        return await RenderAsync(token, lang, input, unlockAttempted: true, ct);
    }

    [HttpGet("/share/{token}/documents/{documentId}/content")]
    public async Task<IActionResult> GetDocumentContent(
        string token,
        string documentId,
        [FromQuery] string? lang,
        CancellationToken ct)
    {
        var language = SharingPortalLocalization.ResolveLanguage(lang, Request);
        var labels = SharingPortalLocalization.GetLabels(language);

        if (string.IsNullOrWhiteSpace(documentId))
        {
            return BadRequest(new { message = labels["DocumentNotFound"] });
        }

        SharedDataResponse? data;
        if (IsDemoToken(token))
        {
            data = BuildDemoPayload();
        }
        else
        {
            data = await GetOrLoadSharedDataAsync(token, ct);
            if (data is null)
            {
                return NotFound(new { message = labels["InvalidLink"] });
            }
        }

        var document = data.Documents.FirstOrDefault(item =>
            string.Equals(item.Id, documentId, StringComparison.Ordinal));
        if (document is null)
        {
            return NotFound(new { message = labels["DocumentNotFound"] });
        }

        string? contentBase64 = document.ContentBase64;
        if (string.IsNullOrWhiteSpace(contentBase64)
            && !string.IsNullOrWhiteSpace(document.ContentFileId)
            && !IsDemoToken(token))
        {
            var tokenHash = _shareProtection.HashToken(token);
            var shareToken = await _db.ShareTokens
                .AsNoTracking()
                .FindByPublicTokenAsync(token, tokenHash, ct);

            if (shareToken is not null)
            {
                contentBase64 = await ShareDocumentContentStore.LoadDocumentContentBase64Async(
                    _db,
                    _shareProtection,
                    shareToken.Id,
                    document.ContentFileId,
                    ct);
            }
        }

        return Ok(new SharedDocumentContentResponse
        {
            DocumentId = document.Id,
            Title = document.Title,
            FileName = document.FileName,
            ContentType = document.ContentType,
            ContentBase64 = contentBase64,
            ContentFileId = document.ContentFileId,
            DownloadUrl = document.DownloadUrl,
            HasInlineContent = !string.IsNullOrWhiteSpace(contentBase64)
                && !string.IsNullOrWhiteSpace(document.ContentType),
        });
    }

    private async Task<SharedDataResponse?> GetOrLoadSharedDataAsync(
        string token,
        CancellationToken ct)
    {
        var cacheKey = $"share_data_{token}";
        if (_cache.TryGetValue<SharedDataResponse>(cacheKey, out var cached) && cached is not null)
        {
            return cached;
        }

        var accessPassword = GetStoredCredentialCookie(AccessPasswordCookiePrefix, token);
        var verificationCode = GetStoredCredentialCookie(VerificationCodeCookiePrefix, token);
        var accessRequestId = GetStoredCredentialCookie(AccessRequestCookiePrefix, token);
        var parsedAccessRequestId = Guid.TryParse(accessRequestId, out var requestId)
            ? requestId
            : (Guid?)null;

        try
        {
            var data = await _getDataHandler.HandleAsync(
                new GetSharedDataQuery(token, accessPassword, verificationCode, parsedAccessRequestId),
                ct);

            _cache.Set(cacheKey, data, SharedDataCacheDuration);
            return data;
        }
        catch (Exception ex) when (ex is UnauthorizedAccessException or KeyNotFoundException or InvalidOperationException)
        {
            _logger.LogDebug(ex, "Failed to load shared data for document content request.");
            return null;
        }
    }

    private async Task<IActionResult> RenderAsync(
        string token,
        string? requestedLanguage,
        ShareUnlockInputModel input,
        bool unlockAttempted,
        CancellationToken ct)
    {
        var language = SharingPortalLocalization.ResolveLanguage(requestedLanguage, Request);
        var labels = SharingPortalLocalization.GetLabels(language);

        if (IsDemoToken(token))
        {
            return View("Index", new SharingPortalViewModel
            {
                Token = token,
                Language = language,
                IsDemoMode = true,
                SharedData = BuildDemoPayload(),
                Labels = labels,
            });
        }

        var validation = await _validateHandler.HandleAsync(new ValidateShareTokenQuery(token), ct);
        if (!validation.IsValid)
        {
            return BuildErrorView(
                token,
                language,
                labels,
                validation.Message,
                unlockInput: input,
                statusCode: InferStatusCode(validation.Message));
        }

        var requiresPassword = validation.RequiresPassword;
        var requiresStaticVerificationCode = validation.RequiresVerificationCode && !validation.RequiresTwoFactorApproval;
        var requiresTwoFactorApproval = validation.RequiresTwoFactorApproval;
        var requiresRuntimeApproval = requiresTwoFactorApproval;
        const bool requiresViewerName = true;

        if (!unlockAttempted)
        {
            return View("Index", new SharingPortalViewModel
            {
                Token = token,
                Language = language,
                RequiresTwoFactorApproval = requiresTwoFactorApproval,
                RequiresPassword = requiresPassword,
                RequiresVerificationCode = requiresStaticVerificationCode,
                RequiresViewerName = requiresViewerName,
                ExpiresAt = validation.ExpiresAt,
                UnlockInput = input,
                Labels = labels,
            });
        }

        if (unlockAttempted)
        {
            input.ViewerName = input.ViewerName?.Trim();

            input.AccessPassword ??= GetStoredCredentialCookie(AccessPasswordCookiePrefix, token);
            input.VerificationCode ??= GetStoredCredentialCookie(VerificationCodeCookiePrefix, token);
            if (input.AccessRequestId is null)
            {
                var requestIdCookie = GetStoredCredentialCookie(AccessRequestCookiePrefix, token);
                if (Guid.TryParse(requestIdCookie, out var parsedRequestId))
                {
                    input.AccessRequestId = parsedRequestId;
                }
            }

            if (string.IsNullOrWhiteSpace(input.ViewerName))
            {
                return BuildErrorView(
                    token,
                    language,
                    labels,
                    labels["ViewerNameRequired"],
                    input,
                    statusCode: StatusCodes.Status400BadRequest,
                    requiresPassword,
                    requiresStaticVerificationCode,
                    requiresViewerName,
                    requiresTwoFactorApproval,
                    validation.ExpiresAt);
            }

            if (requiresPassword && string.IsNullOrWhiteSpace(input.AccessPassword))
            {
                return BuildErrorView(
                    token,
                    language,
                    labels,
                    labels["Unauthorized"],
                    input,
                    statusCode: StatusCodes.Status401Unauthorized,
                    requiresPassword,
                    requiresStaticVerificationCode,
                    requiresViewerName,
                    requiresTwoFactorApproval,
                    validation.ExpiresAt);
            }

            if (requiresRuntimeApproval && input.AccessRequestId is null)
            {
                try
                {
                    var approvalRequest = await _requestTwoFactorHandler.HandleAsync(
                        new RequestTwoFactorApprovalCommand(
                            Token: token,
                            ViewerName: input.ViewerName,
                            AccessPassword: input.AccessPassword,
                            IpAddress: ExtractViewerIpAddress(),
                            UserAgent: Request.Headers.UserAgent.ToString()),
                        ct);

                    input.AccessRequestId = approvalRequest.RequestId;
                    StoreUnlockCredentials(token, input, requiresPassword, false);
                    SetCredentialCookie(AccessRequestCookiePrefix, token, approvalRequest.RequestId.ToString());

                    return View("Index", new SharingPortalViewModel
                    {
                        Token = token,
                        Language = language,
                        RequiresTwoFactorApproval = true,
                        RequiresPassword = requiresPassword,
                        RequiresVerificationCode = false,
                        RequiresViewerName = requiresViewerName,
                        IsTwoFactorPending = true,
                        TwoFactorStatus = approvalRequest.Status,
                        TwoFactorMessage = labels["TwoFactorPending"],
                        ExpiresAt = validation.ExpiresAt,
                        UnlockInput = input,
                        Labels = labels,
                    });
                }
                catch (Exception ex) when (ex is UnauthorizedAccessException or KeyNotFoundException or InvalidOperationException)
                {
                    return BuildErrorView(
                        token,
                        language,
                        labels,
                        ex.Message,
                        input,
                        statusCode: ex is KeyNotFoundException
                            ? StatusCodes.Status404NotFound
                            : ex is InvalidOperationException
                                ? StatusCodes.Status410Gone
                                : StatusCodes.Status401Unauthorized,
                        requiresPassword,
                        requiresStaticVerificationCode,
                        requiresViewerName,
                        true,
                        validation.ExpiresAt);
                }
            }

            if (requiresRuntimeApproval && input.AccessRequestId is not null)
            {
                try
                {
                    var approvalStatus = await _getTwoFactorStatusHandler.HandleAsync(
                        new GetTwoFactorApprovalStatusQuery(token, input.AccessRequestId.Value),
                        ct);

                    if (string.Equals(approvalStatus.Status, "pending", StringComparison.OrdinalIgnoreCase))
                    {
                        return View("Index", new SharingPortalViewModel
                        {
                            Token = token,
                            Language = language,
                            RequiresTwoFactorApproval = true,
                            RequiresPassword = requiresPassword,
                            RequiresVerificationCode = false,
                            RequiresViewerName = requiresViewerName,
                            IsTwoFactorPending = true,
                            TwoFactorStatus = approvalStatus.Status,
                            TwoFactorMessage = ResolveFriendlyMessage(labels, approvalStatus.Message ?? labels["TwoFactorPending"]),
                            ExpiresAt = validation.ExpiresAt,
                            UnlockInput = input,
                            Labels = labels,
                        });
                    }

                    if (string.Equals(approvalStatus.Status, "denied", StringComparison.OrdinalIgnoreCase)
                        || string.Equals(approvalStatus.Status, "expired", StringComparison.OrdinalIgnoreCase))
                    {
                        return BuildErrorView(
                            token,
                            language,
                            labels,
                            approvalStatus.Message,
                            input,
                            statusCode: string.Equals(approvalStatus.Status, "expired", StringComparison.OrdinalIgnoreCase)
                                ? StatusCodes.Status410Gone
                                : StatusCodes.Status401Unauthorized,
                            requiresPassword,
                            requiresStaticVerificationCode,
                            requiresViewerName,
                            true,
                            validation.ExpiresAt);
                    }
                }
                catch (KeyNotFoundException)
                {
                    return BuildErrorView(
                        token,
                        language,
                        labels,
                        labels["TwoFactorRequestMissing"],
                        input,
                        statusCode: StatusCodes.Status404NotFound,
                        requiresPassword,
                        requiresStaticVerificationCode,
                        requiresViewerName,
                        true,
                        validation.ExpiresAt);
                }

            }

            if (requiresStaticVerificationCode && string.IsNullOrWhiteSpace(input.VerificationCode))
            {
                return BuildErrorView(
                    token,
                    language,
                    labels,
                    labels["VerificationCodeRequired"],
                    input,
                    statusCode: StatusCodes.Status401Unauthorized,
                    requiresPassword,
                    true,
                    requiresViewerName,
                    requiresTwoFactorApproval,
                    validation.ExpiresAt);
            }
        }
        var viewerIp = ExtractViewerIpAddress();
        var viewerUserAgent = Request.Headers.UserAgent.ToString();

        try
        {
            var data = await _getDataHandler.HandleAsync(
                new GetSharedDataQuery(token, input.AccessPassword, input.VerificationCode, input.AccessRequestId),
                ct);
            _cache.Set($"share_data_{token}", data, SharedDataCacheDuration);
            _ = Task.Run(async () =>
            {
                try
                {
                    using var scope = _scopeFactory.CreateScope();
                    var logAccessHandler = scope.ServiceProvider
                        .GetRequiredService<ICommandHandler<LogShareAccessCommand, bool>>();

                    await logAccessHandler.HandleAsync(
                        new LogShareAccessCommand(
                            token,
                            input.ViewerName,
                            viewerIp,
                            viewerUserAgent),
                        CancellationToken.None);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to log share access for token.");
                }
            });

            StoreUnlockCredentials(token, input, requiresPassword, requiresStaticVerificationCode);
            var viewData = data with
            {
                Documents = data.Documents
                    .Select(d => d with { ContentBase64 = null, ContentFileId = null })
                    .ToList(),
            };

            return View("Index", new SharingPortalViewModel
            {
                Token = token,
                Language = language,
                RequiresTwoFactorApproval = requiresTwoFactorApproval,
                RequiresPassword = requiresPassword,
                RequiresVerificationCode = requiresStaticVerificationCode,
                RequiresViewerName = requiresViewerName,
                ExpiresAt = validation.ExpiresAt,
                SharedData = viewData,
                UnlockInput = input,
                Labels = labels,
            });
        }
        catch (UnauthorizedAccessException ex)
        {
            return BuildErrorView(
                token,
                language,
                labels,
                ex.Message,
                input,
                statusCode: StatusCodes.Status401Unauthorized,
                requiresPassword,
                requiresStaticVerificationCode,
                requiresViewerName,
                requiresTwoFactorApproval,
                validation.ExpiresAt);
        }
        catch (KeyNotFoundException)
        {
            return BuildErrorView(
                token,
                language,
                labels,
                labels["InvalidLink"],
                input,
                statusCode: StatusCodes.Status404NotFound,
                requiresPassword,
                requiresStaticVerificationCode,
                requiresViewerName,
                requiresTwoFactorApproval,
                validation.ExpiresAt);
        }
        catch (InvalidOperationException ex)
        {
            return BuildErrorView(
                token,
                language,
                labels,
                ResolveFriendlyMessage(labels, ex.Message),
                input,
                statusCode: StatusCodes.Status410Gone,
                requiresPassword,
                requiresStaticVerificationCode,
                requiresViewerName,
                requiresTwoFactorApproval,
                validation.ExpiresAt);
        }
        catch
        {
            return BuildErrorView(
                token,
                language,
                labels,
                labels["UnexpectedError"],
                input,
                statusCode: StatusCodes.Status500InternalServerError,
                requiresPassword,
                requiresStaticVerificationCode,
                requiresViewerName,
                requiresTwoFactorApproval,
                validation.ExpiresAt);
        }
    }

    private IActionResult BuildErrorView(
        string token,
        string language,
        IReadOnlyDictionary<string, string> labels,
        string? sourceMessage,
        ShareUnlockInputModel unlockInput,
        int statusCode,
        bool requiresPassword = false,
        bool requiresVerificationCode = false,
        bool requiresViewerName = false,
        bool requiresTwoFactorApproval = false,
        DateTime? expiresAt = null)
    {
        Response.StatusCode = statusCode;

        return View("Index", new SharingPortalViewModel
        {
            Token = token,
            Language = language,
            RequiresTwoFactorApproval = requiresTwoFactorApproval,
            RequiresPassword = requiresPassword,
            RequiresVerificationCode = requiresVerificationCode,
            RequiresViewerName = requiresViewerName,
            ErrorMessage = ResolveFriendlyMessage(labels, sourceMessage),
            ExpiresAt = expiresAt,
            UnlockInput = unlockInput,
            Labels = labels,
        });
    }

    private static string ResolveFriendlyMessage(IReadOnlyDictionary<string, string> labels, string? sourceMessage)
    {
        if (string.IsNullOrWhiteSpace(sourceMessage))
        {
            return labels["UnexpectedError"];
        }

        if (sourceMessage.Contains("expired", StringComparison.OrdinalIgnoreCase))
        {
            return labels["ExpiredLink"];
        }

        if (sourceMessage.Contains("revoked", StringComparison.OrdinalIgnoreCase))
        {
            return labels["RevokedLink"];
        }

        if (sourceMessage.Contains("not found", StringComparison.OrdinalIgnoreCase))
        {
            return labels["InvalidLink"];
        }

        if (sourceMessage.Contains("waiting", StringComparison.OrdinalIgnoreCase)
            || sourceMessage.Contains("pending", StringComparison.OrdinalIgnoreCase))
        {
            return labels["TwoFactorPending"];
        }

        if (sourceMessage.Contains("denied", StringComparison.OrdinalIgnoreCase))
        {
            return labels["TwoFactorDenied"];
        }

        if (sourceMessage.Contains("request", StringComparison.OrdinalIgnoreCase)
            && sourceMessage.Contains("required", StringComparison.OrdinalIgnoreCase))
        {
            return labels["TwoFactorRequestMissing"];
        }

        if (sourceMessage.Contains("password", StringComparison.OrdinalIgnoreCase)
            || sourceMessage.Contains("verification", StringComparison.OrdinalIgnoreCase)
            || sourceMessage.Contains("credentials", StringComparison.OrdinalIgnoreCase))
        {
            return labels["Unauthorized"];
        }

        return sourceMessage;
    }

    private static int InferStatusCode(string? sourceMessage)
    {
        if (string.IsNullOrWhiteSpace(sourceMessage))
        {
            return StatusCodes.Status404NotFound;
        }

        if (sourceMessage.Contains("expired", StringComparison.OrdinalIgnoreCase)
            || sourceMessage.Contains("revoked", StringComparison.OrdinalIgnoreCase))
        {
            return StatusCodes.Status410Gone;
        }

        if (sourceMessage.Contains("not found", StringComparison.OrdinalIgnoreCase))
        {
            return StatusCodes.Status404NotFound;
        }

        return StatusCodes.Status400BadRequest;
    }

    private string? ExtractViewerIpAddress()
    {
        var forwardedFor = Request.Headers["X-Forwarded-For"].ToString();
        if (!string.IsNullOrWhiteSpace(forwardedFor))
        {
            var firstAddress = forwardedFor
                .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                .FirstOrDefault();
            if (!string.IsNullOrWhiteSpace(firstAddress))
            {
                return firstAddress;
            }
        }

        var realIp = Request.Headers["X-Real-IP"].ToString();
        if (!string.IsNullOrWhiteSpace(realIp))
        {
            return realIp.Trim();
        }

        return HttpContext.Connection.RemoteIpAddress?.ToString();
    }

    private bool IsDemoToken(string token)
    {
        var enabled = _configuration.GetValue<bool>("Sharing:DemoModeEnabled");
        return enabled && string.Equals(token, "demo", StringComparison.OrdinalIgnoreCase);
    }

    private void StoreUnlockCredentials(
        string token,
        ShareUnlockInputModel input,
        bool requiresPassword,
        bool requiresVerificationCode)
    {
        if (requiresPassword && !string.IsNullOrWhiteSpace(input.AccessPassword))
        {
            SetCredentialCookie(AccessPasswordCookiePrefix, token, input.AccessPassword);
        }

        if (requiresVerificationCode && !string.IsNullOrWhiteSpace(input.VerificationCode))
        {
            SetCredentialCookie(VerificationCodeCookiePrefix, token, input.VerificationCode);
        }

        if (input.AccessRequestId is not null)
        {
            SetCredentialCookie(AccessRequestCookiePrefix, token, input.AccessRequestId.Value.ToString());
        }
    }

    private void SetCredentialCookie(string prefix, string token, string plainValue)
    {
        var protectedValue = _credentialProtector.Protect(plainValue);
        Response.Cookies.Append(
            BuildCredentialCookieName(prefix, token),
            protectedValue,
            new CookieOptions
            {
                HttpOnly = true,
                Secure = Request.IsHttps,
                SameSite = SameSiteMode.Lax,
                MaxAge = TimeSpan.FromMinutes(30),
                Path = "/share",
            });
    }

    private string? GetStoredCredentialCookie(string prefix, string token)
    {
        if (!Request.Cookies.TryGetValue(BuildCredentialCookieName(prefix, token), out var protectedValue)
            || string.IsNullOrWhiteSpace(protectedValue))
        {
            return null;
        }

        try
        {
            return _credentialProtector.Unprotect(protectedValue);
        }
        catch (CryptographicException)
        {
            return null;
        }
    }

    private static string BuildCredentialCookieName(string prefix, string token)
    {
        var hashBytes = SHA256.HashData(Encoding.UTF8.GetBytes(token));
        var hash = Convert.ToHexString(hashBytes).ToLowerInvariant();
        return $"{prefix}{hash[..16]}";
    }

    private static SharedDataResponse BuildDemoPayload()
    {
        return new SharedDataResponse
        {
            Token = "demo",
            AccessLevel = "EmergencyOnly",
            ExpiresAt = DateTime.UtcNow.AddDays(30),
            SharedAt = DateTime.UtcNow,
            SharedBy = "MedVault Demo",
            PatientInfo = new SharedPatientInfo
            {
                DisplayName = "Alex Morgan",
                Initials = "AM",
                DateOfBirth = "1990-06-20",
                Gender = Features.Shared.Domain.Gender.Male,
                BloodType = "O+",
                EmergencyContactName = "Jordan Morgan",
                EmergencyContactPhone = "+1 (555) 302-1148",
                EmergencyContactRelationship = "Spouse",
            },
            MedicalSummary = new MedicalSummaryDto
            {
                Allergies =
                [
                    new SharedAllergyDto
                    {
                        Id = "a1",
                        AllergenName = "Penicillin",
                        AllergyType = "Medication",
                        Severity = "High",
                        Reaction = "Anaphylaxis",
                        IsActive = true,
                    }
                ],
                ActiveMedications =
                [
                    new SharedMedicationDto
                    {
                        Id = "m1",
                        MedicationName = "Metformin",
                        Dosage = "500mg",
                        Frequency = "Twice daily",
                        IsActive = true,
                    }
                ],
                Conditions =
                [
                    new SharedConditionDto
                    {
                        Id = "c1",
                        ConditionName = "Type 2 Diabetes",
                        Status = "Active",
                    }
                ],
                Vaccinations = [],
            },
            MedicalHistory =
            [
                new MedicalHistoryEntryDto
                {
                    Id = "h1",
                    Date = "2026-03-02",
                    Type = "Emergency",
                    Title = "Acute allergic reaction",
                    Description = "Stabilized with epinephrine and antihistamines.",
                    Provider = "Dr. Jane Cooper",
                    Facility = "City Emergency Unit",
                    Severity = "High",
                }
            ],
            Documents =
            [
                new SharedDocumentDto
                {
                    Id = "d1",
                    Title = "Latest lab report",
                    Category = "Lab Results",
                    Description = "Comprehensive blood chemistry panel.",
                    FileName = "lab-report-2026-03-01.png",
                    ContentType = "image/png",
                    FileSizeBytes = 70,
                    ContentBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4",
                    DownloadUrl = "https://example.invalid/demo/lab-report-2026-03-01.pdf",
                    UploadedAt = "2026-03-01",
                }
            ],
        };
    }

    private sealed record SharedDocumentContentResponse
    {
        public string DocumentId { get; init; } = string.Empty;
        public string Title { get; init; } = string.Empty;
        public string? FileName { get; init; }
        public string? ContentType { get; init; }
        public string? ContentBase64 { get; init; }
        public string? ContentFileId { get; init; }
        public string? DownloadUrl { get; init; }
        public bool HasInlineContent { get; init; }
    }
}


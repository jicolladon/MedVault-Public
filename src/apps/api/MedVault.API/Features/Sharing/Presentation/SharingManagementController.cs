using System.Security.Claims;
using FluentValidation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MedVault.API.Common.CQRS;
using MedVault.API.Common.Models;
using MedVault.API.Features.Configuration.Application.Services;
using MedVault.API.Features.Sharing.Application.Commands;
using MedVault.API.Features.Sharing.Application.DTOs;
using MedVault.API.Features.Sharing.Application.Queries;

namespace MedVault.API.Features.Sharing.Presentation;

[ApiController]
[Route("api/user/sharing")]
[Authorize]
public class SharingManagementController : ControllerBase
{
    private readonly IQueryHandler<GetMyShareLinksQuery, IReadOnlyList<ShareLinkManagementResponse>> _getLinksHandler;
    private readonly IQueryHandler<GetShareAccessLogsQuery, IReadOnlyList<ShareAccessLogItemResponse>> _getAccessLogsHandler;
    private readonly ICommandHandler<CreateEmergencyShareLinkCommand, ShareLinkManagementResponse> _createEmergencyHandler;
    private readonly ICommandHandler<CreatePhysicianShareLinkCommand, ShareLinkManagementResponse> _createPhysicianHandler;
    private readonly ICommandHandler<UpdateShareLinkCommand, ShareLinkManagementResponse> _updateLinkHandler;
    private readonly ICommandHandler<RevokeShareLinkCommand, bool> _revokeLinkHandler;
    private readonly IQueryHandler<GetPendingTwoFactorApprovalsQuery, IReadOnlyList<PendingTwoFactorApprovalItemResponse>> _getPendingTwoFactorHandler;
    private readonly ICommandHandler<DecideTwoFactorApprovalCommand, TwoFactorApprovalDecisionResponse> _decideTwoFactorHandler;
    private readonly IValidator<CreateEmergencyShareLinkRequest> _createEmergencyValidator;
    private readonly IValidator<CreatePhysicianShareLinkRequest> _createPhysicianValidator;
    private readonly IValidator<UpdateShareLinkRequest> _updateValidator;
    private readonly ISystemConfigurationService _systemConfigurationService;
    private readonly IConfiguration _configuration;

    public SharingManagementController(
        IQueryHandler<GetMyShareLinksQuery, IReadOnlyList<ShareLinkManagementResponse>> getLinksHandler,
        IQueryHandler<GetShareAccessLogsQuery, IReadOnlyList<ShareAccessLogItemResponse>> getAccessLogsHandler,
        ICommandHandler<CreateEmergencyShareLinkCommand, ShareLinkManagementResponse> createEmergencyHandler,
        ICommandHandler<CreatePhysicianShareLinkCommand, ShareLinkManagementResponse> createPhysicianHandler,
        ICommandHandler<UpdateShareLinkCommand, ShareLinkManagementResponse> updateLinkHandler,
        ICommandHandler<RevokeShareLinkCommand, bool> revokeLinkHandler,
        IQueryHandler<GetPendingTwoFactorApprovalsQuery, IReadOnlyList<PendingTwoFactorApprovalItemResponse>> getPendingTwoFactorHandler,
        ICommandHandler<DecideTwoFactorApprovalCommand, TwoFactorApprovalDecisionResponse> decideTwoFactorHandler,
        IValidator<CreateEmergencyShareLinkRequest> createEmergencyValidator,
        IValidator<CreatePhysicianShareLinkRequest> createPhysicianValidator,
        IValidator<UpdateShareLinkRequest> updateValidator,
        ISystemConfigurationService systemConfigurationService,
        IConfiguration configuration)
    {
        _getLinksHandler = getLinksHandler;
        _getAccessLogsHandler = getAccessLogsHandler;
        _createEmergencyHandler = createEmergencyHandler;
        _createPhysicianHandler = createPhysicianHandler;
        _updateLinkHandler = updateLinkHandler;
        _revokeLinkHandler = revokeLinkHandler;
        _getPendingTwoFactorHandler = getPendingTwoFactorHandler;
        _decideTwoFactorHandler = decideTwoFactorHandler;
        _createEmergencyValidator = createEmergencyValidator;
        _createPhysicianValidator = createPhysicianValidator;
        _updateValidator = updateValidator;
        _systemConfigurationService = systemConfigurationService;
        _configuration = configuration;
    }

    [HttpGet("links")]
    [ProducesResponseType(typeof(ApiResponse<IReadOnlyList<SharingLinkClientResponse>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetLinks(CancellationToken ct)
    {
        var links = await _getLinksHandler.HandleAsync(new GetMyShareLinksQuery(GetUserId()), ct);
        var response = links.Select(MapForClient).ToList();
        return Ok(ApiResponse<IReadOnlyList<SharingLinkClientResponse>>.Ok(response));
    }

    [HttpGet("links/{linkId:guid}/access-logs")]
    [ProducesResponseType(typeof(ApiResponse<IReadOnlyList<ShareAccessLogItemResponse>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAccessLogs(Guid linkId, CancellationToken ct)
    {
        var logs = await _getAccessLogsHandler.HandleAsync(
            new GetShareAccessLogsQuery(GetUserId(), linkId),
            ct);

        return Ok(ApiResponse<IReadOnlyList<ShareAccessLogItemResponse>>.Ok(logs));
    }

    [HttpPost("emergency-links")]
    [ProducesResponseType(typeof(ApiResponse<SharingLinkClientResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> CreateEmergencyLink(
        [FromBody] CreateEmergencyShareLinkRequest request,
        CancellationToken ct)
    {
        if (!_systemConfigurationService.GetSharingSettings().EmergencySharingEnabled)
        {
            return StatusCode(
                StatusCodes.Status403Forbidden,
                ApiResponse.Fail("Emergency sharing is disabled by system configuration."));
        }

        var validation = await _createEmergencyValidator.ValidateAsync(request, ct);
        if (!validation.IsValid)
        {
            return BadRequest(ApiResponse.Fail(validation.Errors.Select(e => e.ErrorMessage).ToList()));
        }

        var documentValidationFailure = ValidateDocumentLimit(request.SharedSnapshot);
        if (documentValidationFailure is not null)
        {
            return documentValidationFailure;
        }

        ShareLinkManagementResponse result;
        try
        {
            result = await _createEmergencyHandler.HandleAsync(
                new CreateEmergencyShareLinkCommand(GetUserId(), request),
                ct);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse.Fail(ex.Message));
        }

        return Ok(ApiResponse<SharingLinkClientResponse>.Ok(MapForClient(result), "Emergency sharing link created."));
    }

    [HttpPost("physician-links")]
    [ProducesResponseType(typeof(ApiResponse<SharingLinkClientResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> CreatePhysicianLink(
        [FromBody] CreatePhysicianShareLinkRequest request,
        CancellationToken ct)
    {
        if (!_systemConfigurationService.GetSharingSettings().PhysicianSharingEnabled)
        {
            return StatusCode(
                StatusCodes.Status403Forbidden,
                ApiResponse.Fail("Physician sharing is disabled by system configuration."));
        }

        var validation = await _createPhysicianValidator.ValidateAsync(request, ct);
        if (!validation.IsValid)
        {
            return BadRequest(ApiResponse.Fail(validation.Errors.Select(e => e.ErrorMessage).ToList()));
        }

        var documentValidationFailure = ValidateDocumentLimit(request.SharedSnapshot);
        if (documentValidationFailure is not null)
        {
            return documentValidationFailure;
        }

        ShareLinkManagementResponse result;
        try
        {
            result = await _createPhysicianHandler.HandleAsync(
                new CreatePhysicianShareLinkCommand(GetUserId(), request),
                ct);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse.Fail(ex.Message));
        }

        return Ok(ApiResponse<SharingLinkClientResponse>.Ok(MapForClient(result), "Physician sharing link created."));
    }

    [HttpPut("links/{linkId:guid}")]
    [ProducesResponseType(typeof(ApiResponse<SharingLinkClientResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> UpdateLink(
        Guid linkId,
        [FromBody] UpdateShareLinkRequest request,
        CancellationToken ct)
    {
        var validation = await _updateValidator.ValidateAsync(request, ct);
        if (!validation.IsValid)
        {
            return BadRequest(ApiResponse.Fail(validation.Errors.Select(e => e.ErrorMessage).ToList()));
        }

        var documentValidationFailure = ValidateDocumentLimit(request.SharedSnapshot);
        if (documentValidationFailure is not null)
        {
            return documentValidationFailure;
        }

        var result = await _updateLinkHandler.HandleAsync(
            new UpdateShareLinkCommand(GetUserId(), linkId, request),
            ct);

        return Ok(ApiResponse<SharingLinkClientResponse>.Ok(MapForClient(result), "Sharing link updated."));
    }

    [HttpDelete("links/{linkId:guid}")]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> RevokeLink(Guid linkId, CancellationToken ct)
    {
        var revoked = await _revokeLinkHandler.HandleAsync(
            new RevokeShareLinkCommand(GetUserId(), linkId),
            ct);

        if (!revoked)
        {
            return NotFound(ApiResponse.Fail("Sharing link not found."));
        }

        return Ok(ApiResponse.Ok("Sharing link revoked."));
    }

    [HttpGet("two-factor-requests/pending")]
    [ProducesResponseType(typeof(ApiResponse<IReadOnlyList<PendingTwoFactorApprovalItemResponse>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetPendingTwoFactorRequests(CancellationToken ct)
    {
        var requests = await _getPendingTwoFactorHandler.HandleAsync(
            new GetPendingTwoFactorApprovalsQuery(GetUserId()),
            ct);

        return Ok(ApiResponse<IReadOnlyList<PendingTwoFactorApprovalItemResponse>>.Ok(requests));
    }

    [HttpPost("two-factor-requests/{requestId:guid}/decision")]
    [ProducesResponseType(typeof(ApiResponse<TwoFactorApprovalDecisionResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DecideTwoFactorRequest(
        Guid requestId,
        [FromBody] DecideTwoFactorApprovalRequest request,
        CancellationToken ct)
    {
        try
        {
            var decision = await _decideTwoFactorHandler.HandleAsync(
                new DecideTwoFactorApprovalCommand(GetUserId(), requestId, request.Approved),
                ct);

            return Ok(ApiResponse<TwoFactorApprovalDecisionResponse>.Ok(decision));
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(ApiResponse.Fail(ex.Message));
        }
        catch (KeyNotFoundException)
        {
            return NotFound(ApiResponse.Fail("Two-factor approval request not found."));
        }
    }

    private SharingLinkClientResponse MapForClient(ShareLinkManagementResponse response)
    {
        var shareUrl = BuildShareUrl(response.PublicToken, response.ShareCode);

        return new SharingLinkClientResponse
        {
            LinkId = response.LinkId,
            ShareType = response.ShareType,
            AccessLevel = response.AccessLevel,
            Label = response.Label,
            CreatedAt = response.CreatedAt,
            ExpiresAt = response.ExpiresAt,
            IsRevoked = response.IsRevoked,
            RevokedAt = response.RevokedAt,
            AccessCount = response.AccessCount,
            LastAccessedAt = response.LastAccessedAt,
            ShareCode = response.ShareCode,
            ShareUrl = shareUrl,
            QrPayload = shareUrl,
            RecipientName = response.RecipientName,
            RecipientEmail = response.RecipientEmail,
            Notes = response.Notes,
            Scopes = response.Scopes,
            SecuritySettings = response.SecuritySettings,
        };
    }

    private string BuildShareUrl(string? publicToken, string? shareCode)
    {
        if (string.IsNullOrWhiteSpace(publicToken) && string.IsNullOrWhiteSpace(shareCode))
        {
            return string.Empty;
        }

        var configuredBaseUrl = _configuration["Sharing:PublicBaseUrl"];
        var baseUrl = !string.IsNullOrWhiteSpace(configuredBaseUrl)
            ? configuredBaseUrl.TrimEnd('/')
            : $"{Request.Scheme}://{Request.Host}";
        var path = !string.IsNullOrWhiteSpace(shareCode)
            ? $"/s/{shareCode}"
            : $"/share/{publicToken}";

        return $"{baseUrl}{path}";
    }

    private IActionResult? ValidateDocumentLimit(ShareSnapshotDto? snapshot)
    {
        var selectedDocuments = snapshot?.Documents.Count ?? 0;
        if (selectedDocuments == 0)
        {
            return null;
        }

        var sharingSettings = _systemConfigurationService.GetSharingSettings();
        if (sharingSettings.MaxDocumentsToShare == 0)
        {
            return StatusCode(
                StatusCodes.Status403Forbidden,
                ApiResponse.Fail("Document sharing is disabled by system configuration."));
        }

        if (selectedDocuments > sharingSettings.MaxDocumentsToShare)
        {
            return BadRequest(ApiResponse.Fail(
                $"A maximum of {sharingSettings.MaxDocumentsToShare} shared documents is allowed by system configuration."));
        }

        var oversizedDocument = snapshot!.Documents
            .FirstOrDefault(document =>
                document.FileSizeBytes is not null
                && document.FileSizeBytes.Value > sharingSettings.MaxSharedDocumentBytes);
        if (oversizedDocument is not null)
        {
            var fileName = string.IsNullOrWhiteSpace(oversizedDocument.FileName)
                ? oversizedDocument.Title
                : oversizedDocument.FileName;
            return BadRequest(ApiResponse.Fail(
                $"Cannot share '{fileName}'. File size {FormatBytes(oversizedDocument.FileSizeBytes!.Value)} exceeds the configured maximum of {FormatBytes(sharingSettings.MaxSharedDocumentBytes)}."));
        }

        return null;
    }

    private static string FormatBytes(int bytes)
    {
        if (bytes < 1024)
        {
            return $"{bytes} B";
        }

        var kb = bytes / 1024d;
        if (kb < 1024)
        {
            return $"{kb:0.#} KB";
        }

        var mb = kb / 1024d;
        return $"{mb:0.#} MB";
    }

    private Guid GetUserId() =>
        Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub")
            ?? throw new UnauthorizedAccessException("User ID not found in token."));

    public sealed record SharingLinkClientResponse
    {
        public Guid LinkId { get; init; }
        public string ShareType { get; init; } = string.Empty;
        public string AccessLevel { get; init; } = string.Empty;
        public string? Label { get; init; }
        public DateTime CreatedAt { get; init; }
        public DateTime ExpiresAt { get; init; }
        public bool IsRevoked { get; init; }
        public DateTime? RevokedAt { get; init; }
        public int AccessCount { get; init; }
        public DateTime? LastAccessedAt { get; init; }
        public string ShareCode { get; init; } = string.Empty;
        public string ShareUrl { get; init; } = string.Empty;
        public string QrPayload { get; init; } = string.Empty;
        public string? RecipientName { get; init; }
        public string? RecipientEmail { get; init; }
        public string? Notes { get; init; }
        public List<string> Scopes { get; init; } = [];
        public ShareSecuritySettingsDto SecuritySettings { get; init; } = new();
    }
}


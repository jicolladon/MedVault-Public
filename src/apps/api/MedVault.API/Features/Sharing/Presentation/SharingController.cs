using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MedVault.API.Common.CQRS;
using MedVault.API.Common.Models;
using MedVault.API.Features.Sharing.Application.Commands;
using MedVault.API.Features.Sharing.Application.DTOs;
using MedVault.API.Features.Sharing.Application.Queries;

namespace MedVault.API.Features.Sharing.Presentation;

[ApiController]
[Route("api/sharing")]
[AllowAnonymous]
public class SharingController : ControllerBase
{
    private readonly IQueryHandler<ValidateShareTokenQuery, ShareTokenValidationDto> _validateHandler;
    private readonly IQueryHandler<GetSharedDataQuery, SharedDataResponse> _getDataHandler;
    private readonly ICommandHandler<RequestTwoFactorApprovalCommand, TwoFactorApprovalRequestResponse> _requestTwoFactorHandler;
    private readonly IQueryHandler<GetTwoFactorApprovalStatusQuery, TwoFactorApprovalStatusResponse> _getTwoFactorStatusHandler;
    private readonly ICommandHandler<LogShareAccessCommand, bool> _logAccessHandler;

    public SharingController(
        IQueryHandler<ValidateShareTokenQuery, ShareTokenValidationDto> validateHandler,
        IQueryHandler<GetSharedDataQuery, SharedDataResponse> getDataHandler,
        ICommandHandler<RequestTwoFactorApprovalCommand, TwoFactorApprovalRequestResponse> requestTwoFactorHandler,
        IQueryHandler<GetTwoFactorApprovalStatusQuery, TwoFactorApprovalStatusResponse> getTwoFactorStatusHandler,
        ICommandHandler<LogShareAccessCommand, bool> logAccessHandler)
    {
        _validateHandler = validateHandler;
        _getDataHandler = getDataHandler;
        _requestTwoFactorHandler = requestTwoFactorHandler;
        _getTwoFactorStatusHandler = getTwoFactorStatusHandler;
        _logAccessHandler = logAccessHandler;
    }

    [HttpGet("{token}/validate")]
    [ProducesResponseType(typeof(ApiResponse<ShareTokenValidationDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Validate(string token, CancellationToken ct)
    {
        var result = await _validateHandler.HandleAsync(new ValidateShareTokenQuery(token), ct);
        return Ok(ApiResponse<ShareTokenValidationDto>.Ok(result));
    }

    [HttpGet("{token}")]
    [ProducesResponseType(typeof(ApiResponse<SharedDataResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status410Gone)]
    public async Task<IActionResult> GetSharedData(
        string token,
        [FromQuery] string? accessPassword,
        [FromQuery] string? verificationCode,
        [FromQuery] Guid? accessRequestId,
        CancellationToken ct)
    {
        try
        {
            var data = await _getDataHandler.HandleAsync(
                new GetSharedDataQuery(token, accessPassword, verificationCode, accessRequestId),
                ct);
            return Ok(ApiResponse<SharedDataResponse>.Ok(data));
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(ApiResponse<object>.Fail(ex.Message));
        }
        catch (KeyNotFoundException)
        {
            return NotFound(ApiResponse<object>.Fail("Share token not found."));
        }
        catch (InvalidOperationException ex)
        {
            return StatusCode(StatusCodes.Status410Gone,
                ApiResponse<object>.Fail(ex.Message));
        }
    }

    [HttpPost("{token}/2fa/request")]
    [ProducesResponseType(typeof(ApiResponse<TwoFactorApprovalRequestResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status410Gone)]
    public async Task<IActionResult> RequestTwoFactorApproval(
        string token,
        [FromBody] RequestTwoFactorApprovalRequest request,
        CancellationToken ct)
    {
        try
        {
            var ip = HttpContext.Connection.RemoteIpAddress?.ToString();
            var userAgent = Request.Headers.UserAgent.ToString();
            var response = await _requestTwoFactorHandler.HandleAsync(
                new RequestTwoFactorApprovalCommand(
                    Token: token,
                    ViewerName: request.ViewerName,
                    AccessPassword: request.AccessPassword,
                    IpAddress: ip,
                    UserAgent: userAgent),
                ct);

            return Ok(ApiResponse<TwoFactorApprovalRequestResponse>.Ok(response));
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(ApiResponse<object>.Fail(ex.Message));
        }
        catch (KeyNotFoundException)
        {
            return NotFound(ApiResponse<object>.Fail("Share token not found."));
        }
        catch (InvalidOperationException ex)
        {
            return StatusCode(StatusCodes.Status410Gone, ApiResponse<object>.Fail(ex.Message));
        }
    }

    [HttpGet("{token}/2fa/{requestId:guid}/status")]
    [ProducesResponseType(typeof(ApiResponse<TwoFactorApprovalStatusResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetTwoFactorApprovalStatus(
        string token,
        Guid requestId,
        CancellationToken ct)
    {
        try
        {
            var response = await _getTwoFactorStatusHandler.HandleAsync(
                new GetTwoFactorApprovalStatusQuery(token, requestId),
                ct);

            return Ok(ApiResponse<TwoFactorApprovalStatusResponse>.Ok(response));
        }
        catch (KeyNotFoundException)
        {
            return NotFound(ApiResponse<object>.Fail("Two-factor approval request not found."));
        }
    }

    [HttpPost("{token}/access-log")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    public async Task<IActionResult> LogAccess(
        string token,
        [FromQuery] string? viewerName,
        CancellationToken ct)
    {
        var ip = HttpContext.Connection.RemoteIpAddress?.ToString();
        var userAgent = Request.Headers.UserAgent.ToString();

        var result = await _logAccessHandler.HandleAsync(
            new LogShareAccessCommand(token, viewerName, ip, userAgent), ct);

        return Ok(ApiResponse<bool>.Ok(result));
    }
}


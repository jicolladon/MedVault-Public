using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using FluentValidation;
using MedVault.API.Common.CQRS;
using MedVault.API.Common.Models;
using MedVault.API.Features.Configuration.Application.Commands;
using MedVault.API.Features.Configuration.Application.DTOs;
using MedVault.API.Features.Configuration.Application.Queries;
using MedVault.API.Features.Configuration.Application.Services;

namespace MedVault.API.Features.Configuration.Presentation;

[ApiController]
[Route("api/configuration")]
[Authorize]
public class ConfigurationController : ControllerBase
{
    private readonly ICommandHandler<SaveNotificationPreferencesCommand, NotificationPreferencesResponse> _notifHandler;
    private readonly ICommandHandler<EnableCloudSyncCommand, CloudSyncResponse> _syncHandler;
    private readonly IQueryHandler<GetConfigurationStatusQuery, ConfigurationStatusResponse> _statusHandler;
    private readonly IQueryHandler<GetNotificationPreferencesQuery, NotificationPreferencesResponse?> _getNotifHandler;
    private readonly IValidator<SaveNotificationPreferencesRequest> _notifValidator;
    private readonly IValidator<EnableCloudSyncRequest> _syncValidator;
    private readonly ISystemConfigurationService _systemConfigurationService;
    private readonly ILogger<ConfigurationController> _logger;

    public ConfigurationController(
        ICommandHandler<SaveNotificationPreferencesCommand, NotificationPreferencesResponse> notifHandler,
        ICommandHandler<EnableCloudSyncCommand, CloudSyncResponse> syncHandler,
        IQueryHandler<GetConfigurationStatusQuery, ConfigurationStatusResponse> statusHandler,
        IQueryHandler<GetNotificationPreferencesQuery, NotificationPreferencesResponse?> getNotifHandler,
        IValidator<SaveNotificationPreferencesRequest> notifValidator,
        IValidator<EnableCloudSyncRequest> syncValidator,
        ISystemConfigurationService systemConfigurationService,
        ILogger<ConfigurationController> logger)
    {
        _notifHandler = notifHandler;
        _syncHandler = syncHandler;
        _statusHandler = statusHandler;
        _getNotifHandler = getNotifHandler;
        _notifValidator = notifValidator;
        _syncValidator = syncValidator;
        _systemConfigurationService = systemConfigurationService;
        _logger = logger;
    }

    [HttpPost("notifications")]
    [ProducesResponseType(typeof(ApiResponse<NotificationPreferencesResponse>), 200)]
    public async Task<IActionResult> SaveNotifications(
        [FromBody] SaveNotificationPreferencesRequest request, CancellationToken ct)
    {
        var validation = await _notifValidator.ValidateAsync(request, ct);
        if (!validation.IsValid)
        {
            return BadRequest(ApiResponse.Fail(validation.Errors.Select(e => e.ErrorMessage).ToList()));
        }

        try
        {
            var userId = GetUserId();
            var command = new SaveNotificationPreferencesCommand(userId, request);
            var result = await _notifHandler.HandleAsync(command, ct);

            _logger.LogInformation(
                "Notification preferences saved for user {UserId}. PushEnabled={PushEnabled}, Language={Language}",
                userId,
                result.PushEnabled,
                result.Language);

            return Ok(ApiResponse<NotificationPreferencesResponse>.Ok(result));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to save notification preferences.");
            return StatusCode(
                StatusCodes.Status500InternalServerError,
                ApiResponse.Fail("Unable to save notification preferences at this time."));
        }
    }

    [HttpGet("notifications")]
    [ProducesResponseType(typeof(ApiResponse<NotificationPreferencesResponse>), 200)]
    public async Task<IActionResult> GetNotifications(CancellationToken ct)
    {
        try
        {
            var userId = GetUserId();
            var query = new GetNotificationPreferencesQuery(userId);
            var result = await _getNotifHandler.HandleAsync(query, ct);
            if (result is null)
            {
                return NotFound(ApiResponse.Fail("No notification preferences configured."));
            }

            _logger.LogInformation(
                "Notification preferences retrieved for user {UserId}. Language={Language}",
                userId,
                result.Language);

            return Ok(ApiResponse<NotificationPreferencesResponse>.Ok(result));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to load notification preferences.");
            return StatusCode(
                StatusCodes.Status500InternalServerError,
                ApiResponse.Fail("Unable to load notification preferences at this time."));
        }
    }

    [HttpPost("cloud-sync")]
    [ProducesResponseType(typeof(ApiResponse<CloudSyncResponse>), 200)]
    public async Task<IActionResult> EnableCloudSync(
        [FromBody] EnableCloudSyncRequest request, CancellationToken ct)
    {
        var validation = await _syncValidator.ValidateAsync(request, ct);
        if (!validation.IsValid)
            return BadRequest(ApiResponse.Fail(validation.Errors.Select(e => e.ErrorMessage).ToList()));

        var command = new EnableCloudSyncCommand(GetUserId(), request);
        var result = await _syncHandler.HandleAsync(command, ct);
        return Ok(ApiResponse<CloudSyncResponse>.Ok(result));
    }

    [HttpGet("status")]
    [ProducesResponseType(typeof(ApiResponse<ConfigurationStatusResponse>), 200)]
    public async Task<IActionResult> GetStatus(CancellationToken ct)
    {
        var query = new GetConfigurationStatusQuery(GetUserId());
        var result = await _statusHandler.HandleAsync(query, ct);
        return Ok(ApiResponse<ConfigurationStatusResponse>.Ok(result));
    }

    [HttpGet("sharing")]
    [ProducesResponseType(typeof(ApiResponse<SharingFeatureSettingsResponse>), 200)]
    public IActionResult GetSharingSettings()
    {
        var result = _systemConfigurationService.GetSharingSettings();
        return Ok(ApiResponse<SharingFeatureSettingsResponse>.Ok(result));
    }

    private Guid GetUserId() =>
        Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub")
            ?? throw new UnauthorizedAccessException("User ID not found in token."));
}


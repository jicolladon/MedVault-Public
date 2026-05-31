using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using MedVault.API.Common.CQRS;
using MedVault.API.Common.Models;
using MedVault.API.Features.Notifications.Application.Commands;
using MedVault.API.Features.Notifications.Application.DTOs;
using MedVault.API.Features.Notifications.Application.Queries;

namespace MedVault.API.Features.Notifications.Presentation;

[ApiController]
[Route("api/notifications")]
[Authorize]
public sealed class NotificationsController : ControllerBase
{
    private readonly IQueryHandler<GetNotificationsQuery, IReadOnlyList<NotificationItemResponse>> _getNotificationsHandler;
    private readonly ICommandHandler<MarkNotificationAsReadCommand, NotificationItemResponse?> _markAsReadHandler;
    private readonly ICommandHandler<MarkAllNotificationsAsReadCommand, MarkAllNotificationsAsReadResponse> _markAllAsReadHandler;
    private readonly ICommandHandler<DeleteNotificationCommand, bool> _deleteNotificationHandler;
    private readonly ILogger<NotificationsController> _logger;

    public NotificationsController(
        IQueryHandler<GetNotificationsQuery, IReadOnlyList<NotificationItemResponse>> getNotificationsHandler,
        ICommandHandler<MarkNotificationAsReadCommand, NotificationItemResponse?> markAsReadHandler,
        ICommandHandler<MarkAllNotificationsAsReadCommand, MarkAllNotificationsAsReadResponse> markAllAsReadHandler,
        ICommandHandler<DeleteNotificationCommand, bool> deleteNotificationHandler,
        ILogger<NotificationsController> logger)
    {
        _getNotificationsHandler = getNotificationsHandler;
        _markAsReadHandler = markAsReadHandler;
        _markAllAsReadHandler = markAllAsReadHandler;
        _deleteNotificationHandler = deleteNotificationHandler;
        _logger = logger;
    }

    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<IReadOnlyList<NotificationItemResponse>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetNotifications(CancellationToken ct)
    {
        try
        {
            var userId = GetUserId();
            var notifications = await _getNotificationsHandler.HandleAsync(new GetNotificationsQuery(userId), ct);

            _logger.LogInformation(
                "Retrieved {Count} notifications for user {UserId}",
                notifications.Count,
                userId);

            return Ok(ApiResponse<IReadOnlyList<NotificationItemResponse>>.Ok(notifications));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to retrieve notifications.");
            return StatusCode(
                StatusCodes.Status500InternalServerError,
                ApiResponse.Fail("Unable to retrieve notifications at this time."));
        }
    }

    [HttpPost("{notificationId:guid}/read")]
    [ProducesResponseType(typeof(ApiResponse<NotificationItemResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> MarkAsRead(Guid notificationId, CancellationToken ct)
    {
        try
        {
            var userId = GetUserId();
            var notification = await _markAsReadHandler.HandleAsync(
                new MarkNotificationAsReadCommand(userId, notificationId),
                ct);

            if (notification is null)
            {
                return NotFound(ApiResponse.Fail("Notification not found."));
            }

            _logger.LogInformation(
                "Notification {NotificationId} marked as read for user {UserId}",
                notificationId,
                userId);

            return Ok(ApiResponse<NotificationItemResponse>.Ok(notification));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to mark notification {NotificationId} as read.", notificationId);
            return StatusCode(
                StatusCodes.Status500InternalServerError,
                ApiResponse.Fail("Unable to mark notification as read at this time."));
        }
    }

    [HttpPost("read-all")]
    [ProducesResponseType(typeof(ApiResponse<MarkAllNotificationsAsReadResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> MarkAllAsRead(CancellationToken ct)
    {
        try
        {
            var userId = GetUserId();
            var result = await _markAllAsReadHandler.HandleAsync(
                new MarkAllNotificationsAsReadCommand(userId),
                ct);

            _logger.LogInformation(
                "User {UserId} marked {Count} notifications as read",
                userId,
                result.UpdatedCount);

            return Ok(ApiResponse<MarkAllNotificationsAsReadResponse>.Ok(result));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to mark all notifications as read.");
            return StatusCode(
                StatusCodes.Status500InternalServerError,
                ApiResponse.Fail("Unable to mark all notifications as read at this time."));
        }
    }

    [HttpDelete("{notificationId:guid}")]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteNotification(Guid notificationId, CancellationToken ct)
    {
        try
        {
            var userId = GetUserId();
            var deleted = await _deleteNotificationHandler.HandleAsync(
                new DeleteNotificationCommand(userId, notificationId),
                ct);

            if (!deleted)
            {
                return NotFound(ApiResponse.Fail("Notification not found."));
            }

            _logger.LogInformation(
                "Notification {NotificationId} deleted for user {UserId}",
                notificationId,
                userId);

            return Ok(ApiResponse.Ok("Notification deleted successfully."));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to delete notification {NotificationId}.", notificationId);
            return StatusCode(
                StatusCodes.Status500InternalServerError,
                ApiResponse.Fail("Unable to delete notification at this time."));
        }
    }

    private Guid GetUserId()
    {
        return Guid.Parse(
            User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub")
            ?? throw new UnauthorizedAccessException("User ID not found in token."));
    }
}


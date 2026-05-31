using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MedVault.API.Common.CQRS;
using MedVault.API.Common.Models;
using MedVault.API.Features.Auth.Application.Commands;
using MedVault.API.Features.Auth.Application.DTOs;
using MedVault.API.Features.Auth.Application.Queries;

namespace MedVault.API.Features.Auth.Presentation;

public class SessionController : AuthControllerBase
{
    private readonly ICommandHandler<LogoutCommand, bool> _logoutHandler;
    private readonly IQueryHandler<GetSessionStatusQuery, SessionStatusDto?> _sessionStatusHandler;

    public SessionController(
        ICommandHandler<LogoutCommand, bool> logoutHandler,
        IQueryHandler<GetSessionStatusQuery, SessionStatusDto?> sessionStatusHandler)
    {
        _logoutHandler = logoutHandler;
        _sessionStatusHandler = sessionStatusHandler;
    }

    [Authorize]
    [HttpPost("logout")]
    [ProducesResponseType(typeof(ApiResponse), 200)]
    public async Task<IActionResult> Logout(CancellationToken ct)
    {
        var userId = GetUserId();
        var accessToken = HttpContext.Request.Headers.Authorization.ToString().Replace("Bearer ", "");
        var command = new LogoutCommand(userId, accessToken);
        await _logoutHandler.HandleAsync(command, ct);
        return Ok(ApiResponse.Ok("Logged out successfully."));
    }

    [Authorize]
    [HttpGet("session-status")]
    [ProducesResponseType(typeof(ApiResponse<SessionStatusDto>), 200)]
    public async Task<IActionResult> SessionStatus(CancellationToken ct)
    {
        var userId = GetUserId();
        var query = new GetSessionStatusQuery(userId);
        var result = await _sessionStatusHandler.HandleAsync(query, ct);

        if (result is null)
            return NotFound(ApiResponse.Fail("No active session found."));

        return Ok(ApiResponse<SessionStatusDto>.Ok(result));
    }

    [Authorize]
    [HttpGet("me")]
    [ProducesResponseType(200)]
    public IActionResult Me()
    {
        var claims = User.Claims.ToDictionary(c => c.Type, c => c.Value);
        return Ok(claims);
    }
}


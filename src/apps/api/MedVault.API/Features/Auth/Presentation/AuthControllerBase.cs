using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;

namespace MedVault.API.Features.Auth.Presentation;

[ApiController]
[Route("auth")]
public abstract class AuthControllerBase : ControllerBase
{
    protected Guid GetUserId() =>
        Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub")
            ?? throw new UnauthorizedAccessException("User ID not found in token."));

    protected string? GetIpAddress() =>
        HttpContext.Connection.RemoteIpAddress?.ToString();

    protected string? GetUserAgent() =>
        HttpContext.Request.Headers.UserAgent.ToString();
}


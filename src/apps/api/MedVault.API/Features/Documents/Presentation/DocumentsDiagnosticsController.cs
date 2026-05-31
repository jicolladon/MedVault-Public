using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MedVault.API.Features.Documents.Presentation;

[ApiController]
public sealed class DocumentsDiagnosticsController : ControllerBase
{
    [HttpGet("public")]
    public IActionResult Public()
        => Ok(new { Message = "This is a public endpoint on MedVault.API", Timestamp = DateTime.UtcNow });

    [Authorize]
    [HttpGet("data")]
    public IActionResult Data()
    {
        var claims = User.Claims
            .Select(c => new { c.Type, c.Value })
            .ToList();

        return Ok(new
        {
            Message = "Protected data from MedVault.API",
            Timestamp = DateTime.UtcNow,
            Claims = claims
        });
    }

    [Authorize]
    [HttpGet("data/profile")]
    public IActionResult DataProfile()
    {
        return Ok(new
        {
            Sub = User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? User.FindFirst("sub")?.Value,
            Email = User.FindFirst(ClaimTypes.Email)?.Value ?? User.FindFirst("email")?.Value,
            Role = User.FindFirst(ClaimTypes.Role)?.Value ?? User.FindFirst("role")?.Value,
            GoogleId = User.FindFirst("google_id")?.Value
        });
    }
}


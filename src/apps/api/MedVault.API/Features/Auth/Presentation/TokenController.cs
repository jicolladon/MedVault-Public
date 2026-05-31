using FluentValidation;
using Microsoft.AspNetCore.Mvc;
using MedVault.API.Common.CQRS;
using MedVault.API.Common.Models;
using MedVault.API.Features.Auth.Application.Commands;
using MedVault.API.Features.Auth.Application.DTOs;

namespace MedVault.API.Features.Auth.Presentation;

public class TokenController : AuthControllerBase
{
    private readonly ICommandHandler<RefreshTokenCommand, RefreshTokenResponse> _refreshHandler;
    private readonly IValidator<RefreshTokenRequest> _refreshValidator;

    public TokenController(
        ICommandHandler<RefreshTokenCommand, RefreshTokenResponse> refreshHandler,
        IValidator<RefreshTokenRequest> refreshValidator)
    {
        _refreshHandler = refreshHandler;
        _refreshValidator = refreshValidator;
    }

    [HttpPost("refresh-token")]
    [ProducesResponseType(typeof(ApiResponse<RefreshTokenResponse>), 200)]
    [ProducesResponseType(typeof(ApiResponse), 401)]
    public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequest request, CancellationToken ct)
    {
        var validation = await _refreshValidator.ValidateAsync(request, ct);
        if (!validation.IsValid)
            return BadRequest(ApiResponse.Fail(validation.Errors.Select(e => e.ErrorMessage).ToList()));

        var command = new RefreshTokenCommand(request.RefreshToken);
        var result = await _refreshHandler.HandleAsync(command, ct);
        return Ok(ApiResponse<RefreshTokenResponse>.Ok(result));
    }
}


using FluentValidation;
using Microsoft.AspNetCore.Mvc;
using MedVault.API.Common.CQRS;
using MedVault.API.Common.Models;
using MedVault.API.Features.Auth.Application.Commands;
using MedVault.API.Features.Auth.Application.DTOs;

namespace MedVault.API.Features.Auth.Presentation;

public class GoogleAuthController : AuthControllerBase
{
    private readonly ICommandHandler<GoogleLoginCommand, GoogleLoginResponse> _loginHandler;
    private readonly ICommandHandler<RegisterWithGoogleCommand, RegisterResponse> _registerHandler;
    private readonly IValidator<GoogleLoginRequest> _loginValidator;
    private readonly IValidator<RegisterRequest> _registerValidator;

    public GoogleAuthController(
        ICommandHandler<GoogleLoginCommand, GoogleLoginResponse> loginHandler,
        ICommandHandler<RegisterWithGoogleCommand, RegisterResponse> registerHandler,
        IValidator<GoogleLoginRequest> loginValidator,
        IValidator<RegisterRequest> registerValidator)
    {
        _loginHandler = loginHandler;
        _registerHandler = registerHandler;
        _loginValidator = loginValidator;
        _registerValidator = registerValidator;
    }

    [HttpPost("google")]
    [ProducesResponseType(typeof(ApiResponse<GoogleLoginResponse>), 200)]
    [ProducesResponseType(typeof(ApiResponse), 401)]
    public async Task<IActionResult> GoogleLogin([FromBody] GoogleLoginRequest request, CancellationToken ct)
    {
        var validation = await _loginValidator.ValidateAsync(request, ct);
        if (!validation.IsValid)
            return BadRequest(ApiResponse.Fail(validation.Errors.Select(e => e.ErrorMessage).ToList()));

        var command = new GoogleLoginCommand(request.IdToken, GetIpAddress(), GetUserAgent());
        var result = await _loginHandler.HandleAsync(command, ct);
        return Ok(ApiResponse<GoogleLoginResponse>.Ok(result));
    }

    [HttpPost("google/register")]
    [ProducesResponseType(typeof(ApiResponse<RegisterResponse>), 201)]
    [ProducesResponseType(typeof(ApiResponse), 400)]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request, CancellationToken ct)
    {
        var validation = await _registerValidator.ValidateAsync(request, ct);
        if (!validation.IsValid)
            return BadRequest(ApiResponse.Fail(validation.Errors.Select(e => e.ErrorMessage).ToList()));

        var command = new RegisterWithGoogleCommand(request, GetIpAddress(), GetUserAgent());
        var result = await _registerHandler.HandleAsync(command, ct);
        return StatusCode(201, ApiResponse<RegisterResponse>.Ok(result, "Registration successful."));
    }
}


using FluentValidation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MedVault.API.Common.Models;
using MedVault.API.Features.Configuration.Application.DTOs;
using MedVault.API.Features.Configuration.Application.Services;

namespace MedVault.API.Features.Configuration.Presentation;

[ApiController]
[Route("api/system-configuration")]
[Authorize]
public class SystemConfigurationController : ControllerBase
{
    private readonly ISystemConfigurationService _systemConfigurationService;
    private readonly IValidator<UpdateSharingFeatureSettingsRequest> _updateSharingValidator;

    public SystemConfigurationController(
        ISystemConfigurationService systemConfigurationService,
        IValidator<UpdateSharingFeatureSettingsRequest> updateSharingValidator)
    {
        _systemConfigurationService = systemConfigurationService;
        _updateSharingValidator = updateSharingValidator;
    }

    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<SystemConfigurationResponse>), StatusCodes.Status200OK)]
    public IActionResult GetSystemConfiguration()
    {
        var response = _systemConfigurationService.GetSystemConfiguration();
        return Ok(ApiResponse<SystemConfigurationResponse>.Ok(response));
    }
}


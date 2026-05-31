using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using FluentValidation;
using MedVault.API.Common.CQRS;
using MedVault.API.Common.Models;
using MedVault.API.Features.UserProfile.Application.Commands;
using MedVault.API.Features.UserProfile.Application.DTOs;
using MedVault.API.Features.UserProfile.Application.Queries;

namespace MedVault.API.Features.UserProfile.Presentation;

[ApiController]
[Route("api/user")]
[Authorize]
public class UserProfileController : ControllerBase
{
    private readonly IQueryHandler<GetUserProfileQuery, UserProfileResponse?> _getProfileHandler;
    private readonly IQueryHandler<GetProfileCompletenessQuery, ProfileCompletenessResponse> _completenessHandler;
    private readonly IQueryHandler<GetEmergencyContactsQuery, IReadOnlyList<EmergencyContactResponse>> _getEmergencyContactsHandler;
    private readonly ICommandHandler<UpdateUserProfileCommand, UserProfileResponse> _updateProfileHandler;
    private readonly ICommandHandler<AddEmergencyContactCommand, EmergencyContactResponse> _addEmergencyContactHandler;
    private readonly ICommandHandler<UpdateEmergencyContactCommand, EmergencyContactResponse> _updateEmergencyContactHandler;
    private readonly ICommandHandler<DeleteEmergencyContactCommand, bool> _deleteEmergencyContactHandler;
    private readonly ICommandHandler<ReplaceEmergencyContactsCommand, IReadOnlyList<EmergencyContactResponse>> _replaceEmergencyContactsHandler;
    private readonly IValidator<UpdateProfileRequest> _updateValidator;
    private readonly IValidator<UpsertEmergencyContactRequest> _contactValidator;
    private readonly IValidator<ReplaceEmergencyContactsRequest> _replaceContactsValidator;

    public UserProfileController(
        IQueryHandler<GetUserProfileQuery, UserProfileResponse?> getProfileHandler,
        IQueryHandler<GetProfileCompletenessQuery, ProfileCompletenessResponse> completenessHandler,
        IQueryHandler<GetEmergencyContactsQuery, IReadOnlyList<EmergencyContactResponse>> getEmergencyContactsHandler,
        ICommandHandler<UpdateUserProfileCommand, UserProfileResponse> updateProfileHandler,
        ICommandHandler<AddEmergencyContactCommand, EmergencyContactResponse> addEmergencyContactHandler,
        ICommandHandler<UpdateEmergencyContactCommand, EmergencyContactResponse> updateEmergencyContactHandler,
        ICommandHandler<DeleteEmergencyContactCommand, bool> deleteEmergencyContactHandler,
        ICommandHandler<ReplaceEmergencyContactsCommand, IReadOnlyList<EmergencyContactResponse>> replaceEmergencyContactsHandler,
        IValidator<UpdateProfileRequest> updateValidator,
        IValidator<UpsertEmergencyContactRequest> contactValidator,
        IValidator<ReplaceEmergencyContactsRequest> replaceContactsValidator)
    {
        _getProfileHandler = getProfileHandler;
        _completenessHandler = completenessHandler;
        _getEmergencyContactsHandler = getEmergencyContactsHandler;
        _updateProfileHandler = updateProfileHandler;
        _addEmergencyContactHandler = addEmergencyContactHandler;
        _updateEmergencyContactHandler = updateEmergencyContactHandler;
        _deleteEmergencyContactHandler = deleteEmergencyContactHandler;
        _replaceEmergencyContactsHandler = replaceEmergencyContactsHandler;
        _updateValidator = updateValidator;
        _contactValidator = contactValidator;
        _replaceContactsValidator = replaceContactsValidator;
    }

    [HttpGet("profile")]
    [ProducesResponseType(typeof(ApiResponse<UserProfileResponse>), 200)]
    public async Task<IActionResult> GetMyProfile(CancellationToken ct)
    {
        var userId = GetUserId();
        var query = new GetUserProfileQuery(userId);
        var result = await _getProfileHandler.HandleAsync(query, ct);

        if (result is null)
            return NotFound(ApiResponse.Fail("Profile not found."));

        return Ok(ApiResponse<UserProfileResponse>.Ok(result));
    }

    [HttpGet("profile/{userId:guid}")]
    [ProducesResponseType(typeof(ApiResponse<UserProfileResponse>), 200)]
    public async Task<IActionResult> GetProfile(Guid userId, CancellationToken ct)
    {
        var query = new GetUserProfileQuery(userId);
        var result = await _getProfileHandler.HandleAsync(query, ct);

        if (result is null)
            return NotFound(ApiResponse.Fail("Profile not found."));

        return Ok(ApiResponse<UserProfileResponse>.Ok(result));
    }

    [HttpPut("profile")]
    [ProducesResponseType(typeof(ApiResponse<UserProfileResponse>), 200)]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileRequest request, CancellationToken ct)
    {
        var validation = await _updateValidator.ValidateAsync(request, ct);
        if (!validation.IsValid)
            return BadRequest(ApiResponse.Fail(validation.Errors.Select(e => e.ErrorMessage).ToList()));

        var userId = GetUserId();
        var command = new UpdateUserProfileCommand(userId, request);
        var result = await _updateProfileHandler.HandleAsync(command, ct);
        return Ok(ApiResponse<UserProfileResponse>.Ok(result, "Profile updated successfully."));
    }

    [HttpGet("profile/completeness")]
    [ProducesResponseType(typeof(ApiResponse<ProfileCompletenessResponse>), 200)]
    public async Task<IActionResult> GetCompleteness(CancellationToken ct)
    {
        var userId = GetUserId();
        var query = new GetProfileCompletenessQuery(userId);
        var result = await _completenessHandler.HandleAsync(query, ct);
        return Ok(ApiResponse<ProfileCompletenessResponse>.Ok(result));
    }

    [HttpGet("profile/emergency-contacts")]
    [ProducesResponseType(typeof(ApiResponse<IReadOnlyList<EmergencyContactResponse>>), 200)]
    public async Task<IActionResult> GetEmergencyContacts(CancellationToken ct)
    {
        var query = new GetEmergencyContactsQuery(GetUserId());
        var result = await _getEmergencyContactsHandler.HandleAsync(query, ct);
        return Ok(ApiResponse<IReadOnlyList<EmergencyContactResponse>>.Ok(result));
    }

    [HttpPost("profile/emergency-contacts")]
    [ProducesResponseType(typeof(ApiResponse<EmergencyContactResponse>), 200)]
    public async Task<IActionResult> AddEmergencyContact(
        [FromBody] UpsertEmergencyContactRequest request,
        CancellationToken ct)
    {
        var validation = await _contactValidator.ValidateAsync(request, ct);
        if (!validation.IsValid)
            return BadRequest(ApiResponse.Fail(validation.Errors.Select(e => e.ErrorMessage).ToList()));

        var command = new AddEmergencyContactCommand(GetUserId(), request);
        var result = await _addEmergencyContactHandler.HandleAsync(command, ct);
        return Ok(ApiResponse<EmergencyContactResponse>.Ok(result));
    }

    [HttpPut("profile/emergency-contacts/{contactId}")]
    [ProducesResponseType(typeof(ApiResponse<EmergencyContactResponse>), 200)]
    public async Task<IActionResult> UpdateEmergencyContact(
        string contactId,
        [FromBody] UpsertEmergencyContactRequest request,
        CancellationToken ct)
    {
        var validation = await _contactValidator.ValidateAsync(request, ct);
        if (!validation.IsValid)
            return BadRequest(ApiResponse.Fail(validation.Errors.Select(e => e.ErrorMessage).ToList()));

        var command = new UpdateEmergencyContactCommand(GetUserId(), contactId, request);
        var result = await _updateEmergencyContactHandler.HandleAsync(command, ct);
        return Ok(ApiResponse<EmergencyContactResponse>.Ok(result));
    }

    [HttpDelete("profile/emergency-contacts/{contactId}")]
    [ProducesResponseType(typeof(ApiResponse), 200)]
    public async Task<IActionResult> DeleteEmergencyContact(string contactId, CancellationToken ct)
    {
        var command = new DeleteEmergencyContactCommand(GetUserId(), contactId);
        var deleted = await _deleteEmergencyContactHandler.HandleAsync(command, ct);
        if (!deleted)
            return NotFound(ApiResponse.Fail("Emergency contact not found."));

        return Ok(ApiResponse.Ok());
    }

    [HttpPut("profile/emergency-contacts")]
    [ProducesResponseType(typeof(ApiResponse<IReadOnlyList<EmergencyContactResponse>>), 200)]
    public async Task<IActionResult> ReplaceEmergencyContacts(
        [FromBody] ReplaceEmergencyContactsRequest request,
        CancellationToken ct)
    {
        var validation = await _replaceContactsValidator.ValidateAsync(request, ct);
        if (!validation.IsValid)
            return BadRequest(ApiResponse.Fail(validation.Errors.Select(e => e.ErrorMessage).ToList()));

        var command = new ReplaceEmergencyContactsCommand(GetUserId(), request);
        var result = await _replaceEmergencyContactsHandler.HandleAsync(command, ct);
        return Ok(ApiResponse<IReadOnlyList<EmergencyContactResponse>>.Ok(result));
    }

    private Guid GetUserId() =>
        Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub")
            ?? throw new UnauthorizedAccessException("User ID not found in token."));
}


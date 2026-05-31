using MedVault.API.Common.CQRS;
using MedVault.API.Features.Sharing.Application.DTOs;

namespace MedVault.API.Features.Sharing.Application.Commands;

public sealed record CreateEmergencyShareLinkCommand(
    Guid UserId,
    CreateEmergencyShareLinkRequest Data) : ICommand<ShareLinkManagementResponse>;


using MedVault.API.Common.CQRS;
using MedVault.API.Features.Sharing.Application.DTOs;

namespace MedVault.API.Features.Sharing.Application.Commands;

public sealed record CreatePhysicianShareLinkCommand(
    Guid UserId,
    CreatePhysicianShareLinkRequest Data) : ICommand<ShareLinkManagementResponse>;


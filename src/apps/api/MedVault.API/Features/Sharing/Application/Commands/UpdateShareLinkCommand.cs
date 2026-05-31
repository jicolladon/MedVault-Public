using MedVault.API.Common.CQRS;
using MedVault.API.Features.Sharing.Application.DTOs;

namespace MedVault.API.Features.Sharing.Application.Commands;

public sealed record UpdateShareLinkCommand(
    Guid UserId,
    Guid LinkId,
    UpdateShareLinkRequest Data) : ICommand<ShareLinkManagementResponse>;


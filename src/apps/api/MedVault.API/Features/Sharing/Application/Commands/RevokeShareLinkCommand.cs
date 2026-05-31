using MedVault.API.Common.CQRS;

namespace MedVault.API.Features.Sharing.Application.Commands;

public sealed record RevokeShareLinkCommand(
    Guid UserId,
    Guid LinkId) : ICommand<bool>;


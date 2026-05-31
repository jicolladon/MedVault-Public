using MedVault.API.Common.CQRS;

namespace MedVault.API.Features.Auth.Application.Commands;

public record LogoutCommand(Guid UserId, string? AccessToken) : ICommand<bool>;


using MedVault.API.Common.CQRS;

namespace MedVault.API.Features.Sharing.Application.Commands;

public sealed record LogShareAccessCommand(
    string Token,
    string? ViewerName,
    string? IpAddress,
    string? UserAgent) : ICommand<bool>;


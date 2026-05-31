using MedVault.API.Common.CQRS;
using MedVault.API.Features.Sharing.Application.DTOs;

namespace MedVault.API.Features.Sharing.Application.Commands;

public sealed record RequestTwoFactorApprovalCommand(
    string Token,
    string ViewerName,
    string? AccessPassword,
    string? IpAddress,
    string? UserAgent) : ICommand<TwoFactorApprovalRequestResponse>;

public sealed record DecideTwoFactorApprovalCommand(
    Guid UserId,
    Guid RequestId,
    bool Approved) : ICommand<TwoFactorApprovalDecisionResponse>;

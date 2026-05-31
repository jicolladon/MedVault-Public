using MedVault.API.Common.CQRS;
using MedVault.API.Features.Sharing.Application.DTOs;

namespace MedVault.API.Features.Sharing.Application.Queries;

public sealed record GetTwoFactorApprovalStatusQuery(
    string Token,
    Guid RequestId) : IQuery<TwoFactorApprovalStatusResponse>;

public sealed record GetPendingTwoFactorApprovalsQuery(
    Guid UserId) : IQuery<IReadOnlyList<PendingTwoFactorApprovalItemResponse>>;

using MedVault.API.Common.CQRS;
using MedVault.API.Features.Sharing.Application.DTOs;

namespace MedVault.API.Features.Sharing.Application.Queries;

public sealed record GetMyShareLinksQuery(Guid UserId) : IQuery<IReadOnlyList<ShareLinkManagementResponse>>;


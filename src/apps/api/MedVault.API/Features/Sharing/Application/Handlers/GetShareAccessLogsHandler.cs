using Microsoft.EntityFrameworkCore;
using MedVault.API.Common.CQRS;
using MedVault.API.Data;
using MedVault.API.Features.Sharing.Application.DTOs;
using MedVault.API.Features.Sharing.Application.Queries;

namespace MedVault.API.Features.Sharing.Application.Handlers;

public sealed class GetShareAccessLogsHandler
    : IQueryHandler<GetShareAccessLogsQuery, IReadOnlyList<ShareAccessLogItemResponse>>
{
    private readonly MedVaultDbContext _db;

    public GetShareAccessLogsHandler(MedVaultDbContext db)
    {
        _db = db;
    }

    public async Task<IReadOnlyList<ShareAccessLogItemResponse>> HandleAsync(
        GetShareAccessLogsQuery query,
        CancellationToken cancellationToken = default)
    {
        return await _db.ShareAccessLogs
            .AsNoTracking()
            .Where(log => log.ShareTokenId == query.LinkId && log.ShareToken.UserId == query.UserId)
            .OrderByDescending(log => log.AccessedAt)
            .Select(log => new ShareAccessLogItemResponse
            {
                Id = log.Id,
                ShareLinkId = log.ShareTokenId,
                AccessedAt = log.AccessedAt,
                ViewerName = log.ViewerName,
                ViewerIpAddress = log.ViewerIpAddress,
                ViewerUserAgent = log.ViewerUserAgent,
            })
            .ToListAsync(cancellationToken);
    }
}


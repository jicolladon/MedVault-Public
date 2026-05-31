using Microsoft.EntityFrameworkCore;
using MedVault.API.Features.Sharing.Domain;

namespace MedVault.API.Features.Sharing.Application.Handlers;

internal static class ShareTokenLookupExtensions
{
    public static async Task<ShareTokenEntity?> FindByPublicTokenAsync(
        this IQueryable<ShareTokenEntity> source,
        string token,
        string tokenHash,
        CancellationToken cancellationToken = default)
    {
        var shareToken = await source.FirstOrDefaultAsync(
            entry => entry.TokenHash == tokenHash,
            cancellationToken);

        if (shareToken is not null)
        {
            return shareToken;
        }

        return await source.FirstOrDefaultAsync(
            entry => entry.Token == token,
            cancellationToken);
    }
}

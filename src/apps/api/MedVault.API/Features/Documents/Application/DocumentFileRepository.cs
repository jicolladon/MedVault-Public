using MedVault.API.Data;
using MedVault.API.Features.Documents.Domain;
using Microsoft.EntityFrameworkCore;

namespace MedVault.API.Features.Documents.Application;

public sealed class DocumentFileRepository(MedVaultDbContext context) : IDocumentFileRepository
{
    public async Task<DocumentFileEntity?> GetFileWithContentAsync(Guid fileId, CancellationToken ct = default)
    {
        return await context.DocumentFiles
            .Include(f => f.Document)
            .Include(f => f.Content)
            .FirstOrDefaultAsync(f => f.Id == fileId, ct);
    }

    public async Task AddAsync(DocumentFileEntity file, CancellationToken ct = default)
    {
        await context.DocumentFiles.AddAsync(file, ct);
    }

    public async Task RemoveAsync(Guid fileId, CancellationToken ct = default)
    {
        var file = await context.DocumentFiles.FirstOrDefaultAsync(f => f.Id == fileId, ct);
        if (file != null)
            context.DocumentFiles.Remove(file);
    }

    public async Task<bool> SaveAsync(CancellationToken ct = default)
    {
        return await context.SaveChangesAsync(ct) > 0;
    }
}

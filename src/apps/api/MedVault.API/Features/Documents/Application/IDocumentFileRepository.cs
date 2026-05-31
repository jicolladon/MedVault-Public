using MedVault.API.Features.Documents.Domain;

namespace MedVault.API.Features.Documents.Application;

public interface IDocumentFileRepository
{
    Task<DocumentFileEntity?> GetFileWithContentAsync(Guid fileId, CancellationToken ct = default);
    Task AddAsync(DocumentFileEntity file, CancellationToken ct = default);
    Task RemoveAsync(Guid fileId, CancellationToken ct = default);
    Task<bool> SaveAsync(CancellationToken ct = default);
}

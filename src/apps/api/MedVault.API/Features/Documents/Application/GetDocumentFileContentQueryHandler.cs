using MedVault.API.Common.CQRS;
using MedVault.API.Features.Documents.Application;

namespace MedVault.API.Features.Documents.Application;

public sealed class GetDocumentFileContentQueryHandler(
    IDocumentFileRepository repository,
    ILogger<GetDocumentFileContentQueryHandler> logger) : IQueryHandler<GetDocumentFileContentQuery, DocumentFileContentView>
{
    public async Task<DocumentFileContentView> HandleAsync(GetDocumentFileContentQuery query, CancellationToken cancellationToken = default)
    {
        var file = await repository.GetFileWithContentAsync(query.DocumentFileId, cancellationToken);
        if (file?.Content?.EncryptedPayload is null)
        {
            logger.LogWarning("Document file {FileId} not found or has no content", query.DocumentFileId);
            throw new KeyNotFoundException($"Document file {query.DocumentFileId} not found");
        }

        return new DocumentFileContentView(
            file.Content.EncryptedPayload,
            file.MimeType,
            file.FileName
        );
    }
}

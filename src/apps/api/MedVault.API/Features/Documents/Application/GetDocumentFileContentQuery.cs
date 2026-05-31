using MedVault.API.Common.CQRS;
using MedVault.API.Features.Documents.Application;

namespace MedVault.API.Features.Documents.Application;

public sealed record GetDocumentFileContentQuery(Guid DocumentFileId) : IQuery<DocumentFileContentView>;

public sealed record DocumentFileContentView(
    byte[] Payload,
    string? MimeType,
    string FileName
);


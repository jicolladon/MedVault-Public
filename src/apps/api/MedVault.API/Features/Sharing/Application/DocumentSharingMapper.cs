using MedVault.API.Features.Documents.Domain;
using MedVault.API.Features.Sharing.Application.DTOs;

namespace MedVault.API.Features.Sharing.Application;

public static class DocumentSharingMapper
{
    public static SharedDocumentDto ToSharedDocumentDto(DocumentFileEntity file)
    {
        return new SharedDocumentDto
        {
            Id = file.Id.ToString(),
            Title = file.Document.Title,
            Category = file.Document.Category,
            Description = file.Document.Description,
            FileName = file.FileName,
            ContentType = file.MimeType,
            FileSizeBytes = (int)file.FileSizeBytes,
            ContentFileId = file.Id.ToString(),
            UploadedAt = file.CreatedAt.ToString("O")
        };
    }
}

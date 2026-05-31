using MedVault.API.Features.Sharing.Domain;

namespace MedVault.API.Features.Documents.Domain;

public sealed class MedicalDocumentEntity
{
    public Guid Id { get; set; }
    public Guid? ShareTokenId { get; set; }
    public Guid UserId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public DateTime? DocumentDate { get; set; }
    public string Category { get; set; } = string.Empty;
    public string? Tags { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public ICollection<DocumentFileEntity> Files { get; set; } = [];
    public ShareTokenEntity? ShareToken { get; set; }
}

public sealed class DocumentFileEntity
{
    public Guid Id { get; set; }
    public Guid DocumentId { get; set; }
    public string FileName { get; set; } = string.Empty;
    public string? FileExtension { get; set; }
    public string? MimeType { get; set; }
    public long FileSizeBytes { get; set; }
    public int SortOrder { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public MedicalDocumentEntity Document { get; set; } = null!;
    public DocumentFileContentEntity? Content { get; set; }
}

public sealed class DocumentFileContentEntity
{
    public Guid FileId { get; set; }
    public byte[] EncryptedPayload { get; set; } = [];
    public string? EncryptionKeyId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public DocumentFileEntity File { get; set; } = null!;
}

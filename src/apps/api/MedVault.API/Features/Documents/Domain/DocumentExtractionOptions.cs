namespace MedVault.API.Features.Documents.Domain;

public sealed class DocumentExtractionOptions
{
    public const string SectionName = "DocumentExtraction";

    public int MaxTotalFileSizeBytes { get; set; } = 10 * 1024 * 1024;

    public int ExternalTimeoutSeconds { get; set; } = 30;

    public List<string> AllowedMimeTypes { get; set; } =
    [
        "application/pdf",
        "image/jpeg",
        "image/png",
        "image/jpg",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "text/plain"
    ];
}


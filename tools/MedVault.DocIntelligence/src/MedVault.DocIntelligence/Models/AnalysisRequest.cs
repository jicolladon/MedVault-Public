namespace MedVault.DocIntelligence.Models;

/// <summary>
/// Request to analyze a medical document.
/// </summary>
public sealed class AnalysisRequest
{
    /// <summary>
    /// The file content stream.
    /// </summary>
    public required Stream FileContent { get; init; }

    /// <summary>
    /// Original file name (used for type detection and metadata).
    /// </summary>
    public required string FileName { get; init; }

    public required string FileExtension { get; init; }

    /// <summary>
    /// MIME content type (e.g. "application/pdf", "image/jpeg").
    /// If not provided, it will be inferred from the file extension.
    /// </summary>
    public string? ContentType { get; init; }

    /// <summary>
    /// Whether to include the raw extracted text in the result.
    /// Defaults to false to save space.
    /// </summary>
    public bool IncludeRawText { get; init; } = false;

    /// <summary>
    /// Optional override for the system prompt used by the AI.
    /// </summary>
    public string? SystemPrompt { get; init; }

    /// <summary>
    /// Optional override for the user prompt template used by the AI.
    /// Must include {0} placeholder for extracted text.
    /// </summary>
    public string? UserPromptTemplate { get; init; }
}

namespace MedVault.DocIntelligence.Parsing;

/// <summary>
/// Represents the result of parsing/extracting text from a document.
/// </summary>
public sealed class ParsedDocument
{
    /// <summary>
    /// The full extracted text from the document.
    /// </summary>
    public string ExtractedText { get; set; } = string.Empty;

    /// <summary>
    /// Text extracted per page (for multi-page documents like PDFs).
    /// </summary>
    public List<string> Pages { get; set; } = [];

    /// <summary>
    /// File-level metadata (page count, dimensions, author, etc.).
    /// </summary>
    public Dictionary<string, string> FileMetadata { get; set; } = [];

    /// <summary>
    /// Whether any OCR was used during extraction.
    /// </summary>
    public bool OcrUsed { get; set; }
}

namespace MedVault.DocIntelligence.Parsing;

/// <summary>
/// Interface for extracting text from documents of a specific type.
/// </summary>
public interface IDocumentParser
{
    /// <summary>
    /// Content types this parser supports (e.g. "application/pdf", "image/jpeg").
    /// </summary>
    IReadOnlyCollection<string> SupportedContentTypes { get; }

    /// <summary>
    /// Extracts text and metadata from a document.
    /// </summary>
    /// <param name="content">The document content stream.</param>
    /// <param name="contentType">The MIME type of the document.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>Parsed document with extracted text and metadata.</returns>
    Task<ParsedDocument> ParseAsync(Stream content, string contentType, CancellationToken cancellationToken = default);
}

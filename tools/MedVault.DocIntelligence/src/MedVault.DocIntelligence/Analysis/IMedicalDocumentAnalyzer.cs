using MedVault.DocIntelligence.Models;

namespace MedVault.DocIntelligence.Analysis;

/// <summary>
/// Main interface for analyzing medical documents.
/// Orchestrates document parsing, AI analysis, and result extraction.
/// </summary>
public interface IMedicalDocumentAnalyzer
{
    /// <summary>
    /// Analyzes a medical document and returns structured metadata.
    /// </summary>
    /// <param name="request">The analysis request containing the file to analyze.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>Structured analysis result with document type, summary, and extracted fields.</returns>
    Task<DocumentAnalysisResult> AnalyzeAsync(AnalysisRequest request, CancellationToken cancellationToken = default);

    /// <summary>
    /// Analyzes multiple medical documents together as a single combined context.
    /// Useful for multi-page or multi-image submissions.
    /// </summary>
    /// <param name="requests">The analysis requests containing the files to analyze.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>Structured analysis result with document type, summary, and extracted fields.</returns>
    Task<DocumentAnalysisResult> AnalyzeBatchAsync(IEnumerable<AnalysisRequest> requests, CancellationToken cancellationToken = default);

    /// <summary>
    /// Analyzes a medical document with attached files (e.g., images, PDFs) and returns structured metadata.
    /// </summary>
    /// <param name="requests">The analysis requests containing the files and attachments to analyze.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>Structured analysis result with document type, summary, and extracted fields.</returns>

    Task<DocumentAnalysisResult> AnalyzeAttachingFilesAsync(IEnumerable<AnalysisRequest> requests, CancellationToken cancellationToken = default);
}

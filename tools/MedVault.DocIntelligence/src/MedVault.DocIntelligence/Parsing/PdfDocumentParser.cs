using System.Text;
using Microsoft.Extensions.Logging;
using UglyToad.PdfPig;
using UglyToad.PdfPig.Content;

namespace MedVault.DocIntelligence.Parsing;

/// <summary>
/// Parses PDF documents using PdfPig for text extraction.
/// Falls back to OCR (via <see cref="ImageDocumentParser"/>) for scanned PDFs with minimal text.
/// </summary>
public sealed class PdfDocumentParser : IDocumentParser
{
    private const int MinTextLengthPerPage = 20;

    private readonly ImageDocumentParser? _ocrFallback;
    private readonly ILogger<PdfDocumentParser> _logger;

    public PdfDocumentParser(ILogger<PdfDocumentParser> logger, ImageDocumentParser? ocrFallback = null)
    {
        _logger = logger;
        _ocrFallback = ocrFallback;
    }

    public IReadOnlyCollection<string> SupportedContentTypes => ["application/pdf"];

    public async Task<ParsedDocument> ParseAsync(Stream content, string contentType, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Parsing PDF document...");

        // PdfPig requires a seekable stream; buffer if needed
        using var memoryStream = new MemoryStream();
        await content.CopyToAsync(memoryStream, cancellationToken);
        memoryStream.Position = 0;

        var result = new ParsedDocument();
        var fullText = new StringBuilder();
        var hasMinimalText = false;

        try
        {
            using var document = PdfDocument.Open(memoryStream);

            result.FileMetadata["pageCount"] = document.NumberOfPages.ToString();

            if (document.Information?.Author is not null)
                result.FileMetadata["author"] = document.Information.Author;

            if (document.Information?.Title is not null)
                result.FileMetadata["title"] = document.Information.Title;

            if (document.Information?.CreationDate is not null)
                result.FileMetadata["creationDate"] = document.Information.CreationDate;

            foreach (Page page in document.GetPages())
            {
                cancellationToken.ThrowIfCancellationRequested();

                var pageText = page.Text ?? string.Empty;
                result.Pages.Add(pageText);

                if (pageText.Length < MinTextLengthPerPage)
                {
                    hasMinimalText = true;
                }

                fullText.AppendLine(pageText);
            }

            result.ExtractedText = fullText.ToString().Trim();
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _logger.LogWarning(ex, "PdfPig failed to extract text; will attempt OCR if available.");
            hasMinimalText = true;
            result.ExtractedText = string.Empty;
        }

        // If the PDF has minimal text (likely scanned), try OCR
        if (hasMinimalText && string.IsNullOrWhiteSpace(result.ExtractedText) && _ocrFallback is not null)
        {
            _logger.LogInformation("PDF has minimal text, falling back to OCR...");
            memoryStream.Position = 0;

            // OCR the entire PDF stream as an image (Tesseract can handle some PDF formats)
            // For production use, you'd render each page to an image first
            try
            {
                var ocrResult = await _ocrFallback.ParseAsync(memoryStream, "image/tiff", cancellationToken);
                result.ExtractedText = ocrResult.ExtractedText;
                result.OcrUsed = true;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "OCR fallback also failed for scanned PDF.");
            }
        }

        _logger.LogInformation("PDF parsing complete. Extracted {CharCount} characters from {PageCount} pages.",
            result.ExtractedText.Length, result.Pages.Count);

        return result;
    }
}

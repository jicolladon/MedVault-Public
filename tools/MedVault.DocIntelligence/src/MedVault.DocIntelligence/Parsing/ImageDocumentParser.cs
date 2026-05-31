using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MedVault.DocIntelligence.Configuration;
using Tesseract;

namespace MedVault.DocIntelligence.Parsing;

/// <summary>
/// Parses image documents (JPEG, PNG, TIFF, BMP) using Tesseract OCR.
/// Requires Tesseract trained data files (tessdata) to be available on disk.
/// </summary>
public sealed class ImageDocumentParser : IDocumentParser, IDisposable
{
    private readonly ILogger<ImageDocumentParser> _logger;
    private readonly OcrOptions _ocrOptions;
    private TesseractEngine? _engine;
    private bool _disposed;

    public ImageDocumentParser(ILogger<ImageDocumentParser> logger, IOptions<OcrOptions> ocrOptions)
    {
        _logger = logger;
        _ocrOptions = ocrOptions.Value;
    }

    public IReadOnlyCollection<string> SupportedContentTypes =>
    [
        "image/jpeg",
        "image/png",
        "image/tiff",
        "image/bmp",
        "image/gif"
    ];

    public async Task<ParsedDocument> ParseAsync(Stream content, string contentType, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Parsing image document via OCR (content type: {ContentType})...", contentType);

        var result = new ParsedDocument
        {
            OcrUsed = true
        };

        // Read the image into a byte array
        using var memoryStream = new MemoryStream();
        await content.CopyToAsync(memoryStream, cancellationToken);
        var imageBytes = memoryStream.ToArray();

        result.FileMetadata["contentType"] = contentType;
        result.FileMetadata["fileSizeBytes"] = imageBytes.Length.ToString();

        try
        {
            var engine = GetOrCreateEngine();

            using var pix = Pix.LoadFromMemory(imageBytes);
            result.FileMetadata["width"] = pix.Width.ToString();
            result.FileMetadata["height"] = pix.Height.ToString();

            using var page = engine.Process(pix);
            var text = page.GetText();

            result.ExtractedText = text?.Trim() ?? string.Empty;
            result.Pages.Add(result.ExtractedText);

            var confidence = page.GetMeanConfidence();
            result.FileMetadata["ocrConfidence"] = confidence.ToString("F2");

            _logger.LogInformation("OCR complete. Extracted {CharCount} characters with {Confidence:P0} confidence.",
                result.ExtractedText.Length, confidence);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _logger.LogError(ex, "Tesseract OCR failed. Ensure tessdata is available at: {DataPath}", _ocrOptions.TesseractDataPath);
            result.ExtractedText = string.Empty;
            result.FileMetadata["ocrError"] = ex.Message;
        }

        return result;
    }

    private TesseractEngine GetOrCreateEngine()
    {
        if (_engine is not null) return _engine;

        _logger.LogDebug("Initializing Tesseract engine (data: {DataPath}, lang: {Language})...",
            _ocrOptions.TesseractDataPath, _ocrOptions.Language);

        _engine = new TesseractEngine(
            _ocrOptions.TesseractDataPath,
            _ocrOptions.Language,
            EngineMode.Default);

        return _engine;
    }

    public void Dispose()
    {
        if (_disposed) return;
        _engine?.Dispose();
        _disposed = true;
    }
}

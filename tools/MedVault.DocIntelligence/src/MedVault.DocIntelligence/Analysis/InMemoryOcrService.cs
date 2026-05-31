using Microsoft.Extensions.Logging;
using System.Text;

namespace MedVault.DocIntelligence.Analysis;

public sealed class OcrResult
{
    public string Text { get; set; } = string.Empty;

    public double Confidence { get; set; }
}


public class DocumentExtractionException : Exception
{
    public DocumentExtractionException(string message)
        : base(message)
    {
    }

    public DocumentExtractionException(string message, Exception innerException)
        : base(message, innerException)
    {
    }
}

public sealed class OcrProcessingException : DocumentExtractionException
{
    public OcrProcessingException(string message)
        : base(message)
    {
    }

    public OcrProcessingException(string message, Exception innerException)
        : base(message, innerException)
    {
    }
}


public interface IOcrService
{
    Task<OcrResult> ExtractTextAsync(IEnumerable<(Stream Stream, string FileName, string? ContentType)> files);
}

public sealed class InMemoryOcrService : IOcrService
{
    public InMemoryOcrService(ILogger<InMemoryOcrService> logger)
    {
        _logger = logger;
    }

    private readonly ILogger<InMemoryOcrService> _logger;
    private const int MaxInspectionBytesPerFile = 50 * 1024 * 1024;

    public async Task<OcrResult> ExtractTextAsync(IEnumerable<(Stream Stream, string FileName, string? ContentType)> files)
    {
        var mergedText = new StringBuilder();
        var confidenceSignals = new List<double>();

        foreach (var file in files)
        {
            using var memory = new MemoryStream();
            await file.Stream.CopyToAsync(memory);

            var bytes = memory.ToArray();
            var text = ExtractBestEffortText(bytes, file.ContentType);
            var inspected = bytes.Take(MaxInspectionBytesPerFile).ToArray();
            var printableRatio = CalculatePrintableRatio(inspected);

            if (!string.IsNullOrWhiteSpace(text))
            {
                mergedText.AppendLine($"--- FILE: {file.FileName} ---");
                mergedText.AppendLine(text.Trim());
                mergedText.AppendLine();
            }
            else
            {
                mergedText.AppendLine($"--- FILE: {file.FileName} ---");
                mergedText.AppendLine($"[No OCR text extracted from MIME type '{file.ContentType}']");
                mergedText.AppendLine();
            }

            confidenceSignals.Add(printableRatio >= 0.6 ? 0.9 : printableRatio >= 0.25 ? 0.6 : 0.35);
        }

        var textOutput = mergedText.ToString().Trim();
        if (string.IsNullOrWhiteSpace(textOutput))
        {
            throw new OcrProcessingException("OCR did not produce any text.");
        }

        var confidence = confidenceSignals.Count == 0
            ? 0.4
            : confidenceSignals.Average();

        _logger.LogInformation("OCR extraction completed for {FileCount} files with confidence {Confidence:0.00}",
            confidenceSignals.Count,
            confidence);

        return new OcrResult
        {
            Text = textOutput,
            Confidence = Math.Clamp(confidence, 0.0, 1.0)
        };
    }

    private static string ExtractBestEffortText(byte[] bytes, string? contentType)
    {
        if (bytes.Length == 0)
        {
            return string.Empty;
        }

        if (!string.IsNullOrWhiteSpace(contentType) && contentType.StartsWith("text/", StringComparison.OrdinalIgnoreCase))
        {
            return Encoding.UTF8.GetString(bytes);
        }

        var utf8 = Encoding.UTF8.GetString(bytes);
        var filtered = new string(utf8.Where(ch =>
            ch == '\n' || ch == '\r' || ch == '\t' ||
            (ch >= 32 && ch <= 126)).ToArray());

        if (filtered.Length >= 30)
        {
            return filtered;
        }

        return string.Empty;
    }

    private static double CalculatePrintableRatio(byte[] bytes)
    {
        if (bytes.Length == 0)
        {
            return 0;
        }

        var printable = bytes.Count(b =>
            b == 9 || b == 10 || b == 13 ||
            (b >= 32 && b <= 126));

        return printable / (double)bytes.Length;
    }
}

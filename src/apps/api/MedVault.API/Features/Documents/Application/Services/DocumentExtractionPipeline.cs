using MedVault.API.Features.Documents.Application.DTOs;
using MedVault.DocIntelligence.Analysis;
using MedVault.DocIntelligence.Models;
using MedVault.DocIntelligence.Prompts;
using Newtonsoft.Json;
using UglyToad.PdfPig;

namespace MedVault.API.Features.Documents.Application.Services;

public sealed class DocumentExtractionPipeline(
    IMedicalDocumentAnalyzer analyzer,
    ILogger<DocumentExtractionPipeline> logger) : IDocumentExtractionPipeline
{
    public async Task<ExtractionResult> ExtractAsync(
        IEnumerable<IFormFile> files,
        string preferredLanguage,
        string systemPrompt,
        string userPromptTemplate)
    {
        var fileList = files.Where(file => file is not null).ToList();
        if (fileList.Count == 0)
        {
            throw new OcrProcessingException("No files were provided for document extraction.");
        }

        var analyses = new List<DocumentAnalysisResult>(capacity: 1);
        var requests = new List<AnalysisRequest>(fileList.Count);
        var streams = new List<Stream>(fileList.Count);

        foreach (var file in fileList)
        {
            var stream = file.OpenReadStream();
            streams.Add(stream);

            requests.Add(new AnalysisRequest
            {
                FileContent = stream,
                FileName = file.FileName,
                FileExtension = Path.GetExtension(file.FileName),
                ContentType = ResolveContentType(file),
                IncludeRawText = false,
                SystemPrompt = systemPrompt,
                UserPromptTemplate = userPromptTemplate
            });
        }

        try
        {
            var analysis = await analyzer.AnalyzeAttachingFilesAsync(requests);
            analyses.Add(analysis);
        }
        finally
        {
            foreach (var stream in streams)
            {
                await stream.DisposeAsync();
            }
        }

        var structured = BuildStructuredExtraction(analyses);

        logger.LogInformation(
            "Document extraction finished for {FileCount} files. Confidence: {Confidence:0.00}",
            fileList.Count,
            structured.Confidence);

        return structured;
    }

    public Task<ExtractionResult> ExtractAsync(IEnumerable<IFormFile> files, string preferredLanguage)
    {
        var jsonResultFormat = PromptTemplates.GetSystemPrompt(ExtractionResultExtensions.JsonSchema);
        return ExtractAsync(files, preferredLanguage, systemPrompt: jsonResultFormat, userPromptTemplate: PromptTemplates.UserPromptTemplate);
    }

    private static ExtractionResult BuildStructuredExtraction(IReadOnlyList<DocumentAnalysisResult> analyses)
    {
        var data = JsonConvert.DeserializeObject<ExtractionResult>(
            analyses.Select(result => result.JsonStringResult?.ToString())
                .FirstOrDefault(json => !string.IsNullOrWhiteSpace(json)) ?? string.Empty);

        return data ?? new ExtractionResult
        {
            IsMedical = false,
            DocumentType = "Unknown",
            Tags = new List<string>(),
            Date = null,
            IssuerName = string.Empty,
            Metadata = new MedicalMetadata(),
            Summary = string.Empty,
            Confidence = analyses.Select(a => a.Confidence).DefaultIfEmpty(0).Average(),
            RequiresUserConfirmation = false
        };
    }

    private static string ResolveContentType(IFormFile file)
    {
        if (!string.IsNullOrWhiteSpace(file.ContentType) &&
            !string.Equals(file.ContentType, "application/octet-stream", StringComparison.OrdinalIgnoreCase))
        {
            return file.ContentType;
        }

        return Path.GetExtension(file.FileName).ToLowerInvariant() switch
        {
            ".pdf" => "application/pdf",
            ".jpg" => "image/jpeg",
            ".jpeg" => "image/jpeg",
            ".png" => "image/png",
            ".docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            ".xlsx" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            ".txt" => "text/plain",
            _ => file.ContentType ?? string.Empty
        };
    }

    private static DateTime? ParseDocumentDate(string? documentDate)
    {
        if (string.IsNullOrWhiteSpace(documentDate))
        {
            return null;
        }

        if (DateTime.TryParse(documentDate, out var parsed))
        {
            return DateTime.SpecifyKind(parsed.Date, DateTimeKind.Utc);
        }

        return null;
    }

    private static string HumanizeDocumentType(MedicalDocumentType documentType)
    {
        var raw = documentType.ToString();
        if (documentType == MedicalDocumentType.Unknown)
        {
            return "Unknown";
        }

        var builder = new System.Text.StringBuilder(raw.Length + 8);
        for (var index = 0; index < raw.Length; index++)
        {
            var current = raw[index];
            if (index > 0 && char.IsUpper(current) && !char.IsUpper(raw[index - 1]))
            {
                builder.Append(' ');
            }

            builder.Append(current);
        }

        return builder.ToString();
    }

    private static (string? MinRange, string? MaxRange) ParseReferenceRange(string? referenceRange, string? unit)
    {
        if (string.IsNullOrWhiteSpace(referenceRange))
        {
            return (null, null);
        }

        var trimmed = referenceRange.Trim();

        if (trimmed.StartsWith('<'))
        {
            var max = trimmed.TrimStart('<', '=', ' ');
            return (null, CleanRangeValue(max, unit));
        }

        if (trimmed.StartsWith('>'))
        {
            var min = trimmed.TrimStart('>', '=', ' ');
            return (CleanRangeValue(min, unit), null);
        }

        var toIndex = trimmed.IndexOf(" to ", StringComparison.OrdinalIgnoreCase);
        if (toIndex >= 0)
        {
            var left = trimmed[..toIndex];
            var right = trimmed[(toIndex + 4)..];
            return (CleanRangeValue(left, unit), CleanRangeValue(right, unit));
        }

        var parts = trimmed.Split('-', 2, StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length == 2)
        {
            return (CleanRangeValue(parts[0], unit), CleanRangeValue(parts[1], unit));
        }

        return (CleanRangeValue(trimmed, unit), null);
    }

    private static string? CleanRangeValue(string? value, string? unit)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        var cleaned = value.Trim();
        if (!string.IsNullOrWhiteSpace(unit) &&
            cleaned.EndsWith(unit, StringComparison.OrdinalIgnoreCase))
        {
            cleaned = cleaned[..^unit.Length].Trim();
        }

        return cleaned;
    }

    private static bool IsMedicationField(ExtractedField field) => IsMatch(field, "med", "prescription", "drug", "dose");

    private static bool IsLabResultField(ExtractedField field) => IsMatch(field, "lab", "test", "result", "blood", "urine", "chemistry");

    private static bool IsAllergyField(ExtractedField field) => IsMatch(field, "allerg");

    private static bool IsDiagnosisField(ExtractedField field) => IsMatch(field, "diagnos", "condition");

    private static bool IsVaccinationField(ExtractedField field) => IsMatch(field, "vaccin", "immuniz");

    private static bool IsMatch(ExtractedField field, params string[] terms)
    {
        var haystack = string.Join(' ', new[] { field.Name, field.Value, field.Category, field.Unit, field.ReferenceRange }
                .Where(value => !string.IsNullOrWhiteSpace(value)))
            .ToLowerInvariant();

        return terms.Any(term => haystack.Contains(term, StringComparison.OrdinalIgnoreCase));
    }

    private static string ChoosePrimaryText(string? firstChoice, string? secondChoice)
        => !string.IsNullOrWhiteSpace(firstChoice) ? firstChoice.Trim() : secondChoice?.Trim() ?? string.Empty;

    private static string ComposeValue(string? value, string? unit)
    {
        var parts = new[] { value?.Trim(), unit?.Trim() }
            .Where(part => !string.IsNullOrWhiteSpace(part))
            .ToArray();

        return string.Join(' ', parts);
    }

}


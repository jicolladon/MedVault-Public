using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MedVault.DocIntelligence.Models;
using MedVault.DocIntelligence.Parsing;
using MedVault.DocIntelligence.Prompts;
using MedVault.DocIntelligence.Configuration;

namespace MedVault.DocIntelligence.Analysis;

/// <summary>
/// Orchestrates document parsing and AI analysis to produce structured medical document results.
/// Flow: Parse document → Build prompt → Call AI → Deserialize JSON response.
/// </summary>
public sealed class MedicalDocumentAnalyzer : IMedicalDocumentAnalyzer
{
    private readonly DocumentParserFactory _parserFactory;
    private readonly IAiProvider _aiProvider;
    private readonly ILogger<MedicalDocumentAnalyzer> _logger;

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        AllowTrailingCommas = true,
        ReadCommentHandling = JsonCommentHandling.Skip
    };

    public MedicalDocumentAnalyzer(
        DocumentParserFactory parserFactory,
        IAiProvider aiProvider,
        ILogger<MedicalDocumentAnalyzer> logger)
    {
        _parserFactory = parserFactory;
        _aiProvider = aiProvider;
        _logger = logger;
    }

    public async Task<DocumentAnalysisResult> AnalyzeAttachingFilesAsync(IEnumerable<AnalysisRequest> request, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        var files = request.Select(x => (x.FileContent, x.FileExtension)).ToList();

        _logger.LogInformation("Starting analysis of documents: {FileNames}", string.Join(", ", request.Select(r => r.FileName)));

        var systemPrompt = ResolveSystemPrompt(request.First().SystemPrompt);
        var userPrompt = """
            Analyze the attached medical documents as a whole, considering all files together.
            Extract relevant information and provide a structured summary. Focus on identifying document types, key medical details, and any actionable insights.
            Consider the context across all documents to improve accuracy.
            Return the analysis in a structured JSON format with fields for document type, confidence level, key findings, and any relevant notes.
            """;
        var aiResponse = await _aiProvider.GetCompletitionAsync(
            systemPrompt,
            userPrompt,
            files,
            cancellationToken);

        var result = DeserializeResult(aiResponse);

        _logger.LogInformation("Analysis complete. Document type: Confidence: {Confidence:P0}", result.Confidence);

        return result;
    }

    public async Task<DocumentAnalysisResult> AnalyzeAsync(AnalysisRequest request, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        _logger.LogInformation("Starting analysis of document: {FileName}", request.FileName);

        // Step 1: Parse the document to extract text
        var parsedDocument = await ParseDocumentAsync(request, cancellationToken);

        if (string.IsNullOrWhiteSpace(parsedDocument.ExtractedText))
        {
            _logger.LogWarning("No text could be extracted from document: {FileName}", request.FileName);
            return CreateEmptyResult(
                "No text could be extracted from this document. The file may be corrupted, empty, or in an unsupported format.",
                "Document parsing returned empty text.");
        }

        _logger.LogInformation("Extracted {CharCount} characters from document. Sending to AI for analysis...",
            parsedDocument.ExtractedText.Length);

        // Step 3: Build prompt and send to AI
        var systemPrompt = ResolveSystemPrompt(request.SystemPrompt);
        var userPrompt = BuildUserPrompt(request.UserPromptTemplate, parsedDocument.ExtractedText);
        var aiResponse = await _aiProvider.GetCompletionAsync(
            systemPrompt,
            userPrompt,
            cancellationToken);

        // Step 4: Deserialize AI response to structured result
        var result = DeserializeResult(aiResponse);

        // Step 5: Optionally attach raw text
        if (request.IncludeRawText)
        {
            result.RawText = parsedDocument.ExtractedText;
        }

        _logger.LogInformation("Analysis complete. Document type: Confidence: {Confidence:P0}", result.Confidence);

        return result;
    }

    public async Task<DocumentAnalysisResult> AnalyzeBatchAsync(
        IEnumerable<AnalysisRequest> requests,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(requests);

        var requestList = requests.Where(request => request is not null).ToList();
        if (requestList.Count == 0)
        {
            throw new ArgumentException("At least one analysis request is required.", nameof(requests));
        }

        var extractedTexts = new List<(string FileName, string Text)>(requestList.Count);

        foreach (var request in requestList)
        {
            _logger.LogInformation("Starting analysis of document: {FileName}", request.FileName);

            var parsedDocument = await ParseDocumentAsync(request, cancellationToken);
            if (string.IsNullOrWhiteSpace(parsedDocument.ExtractedText))
            {
                _logger.LogWarning("No text could be extracted from document: {FileName}", request.FileName);
                continue;
            }

            _logger.LogInformation("Extracted {CharCount} characters from document: {FileName}",
                parsedDocument.ExtractedText.Length,
                request.FileName);

            extractedTexts.Add((request.FileName, parsedDocument.ExtractedText));
        }

        var combinedText = BuildCombinedText(extractedTexts);
        if (string.IsNullOrWhiteSpace(combinedText))
        {
            return CreateEmptyResult(
                "No text could be extracted from the provided documents. The files may be corrupted, empty, or in an unsupported format.",
                "Document parsing returned empty text for all files.");
        }

        var systemPromptOverride = requestList
            .Select(request => request.SystemPrompt)
            .FirstOrDefault(prompt => !string.IsNullOrWhiteSpace(prompt));

        var userPromptTemplateOverride = requestList
            .Select(request => request.UserPromptTemplate)
            .FirstOrDefault(template => !string.IsNullOrWhiteSpace(template));

        var systemPrompt = ResolveSystemPrompt(systemPromptOverride);
        var userPrompt = BuildUserPrompt(userPromptTemplateOverride, combinedText);

        var aiResponse = await _aiProvider.GetCompletionAsync(
            systemPrompt,
            userPrompt,
            cancellationToken);

        var result = DeserializeResult(aiResponse);

        if (requestList.Any(request => request.IncludeRawText))
        {
            result.RawText = combinedText;
        }

        _logger.LogInformation("Batch analysis complete. Confidence: {Confidence:P0}", result.Confidence);

        return result;
    }

    /// <summary>
    /// Deserializes the AI JSON response into a <see cref="DocumentAnalysisResult"/>.
    /// Handles common AI response quirks (markdown fences, leading/trailing whitespace).
    /// </summary>
    private DocumentAnalysisResult DeserializeResult(string aiResponse)
    {
        // Clean up common AI response issues
        var json = aiResponse.Trim();

        // Remove markdown code fences if the AI wraps JSON in ```json ... ```
        if (json.StartsWith("```"))
        {
            var firstNewline = json.IndexOf('\n');
            if (firstNewline > 0)
                json = json[(firstNewline + 1)..];

            if (json.EndsWith("```"))
                json = json[..^3];

            json = json.Trim();
        }

        try
        {
            var result = JsonSerializer.Deserialize<DocumentAnalysisResult>(json, JsonOptions);

            if (result is null)
            {
                _logger.LogWarning("AI response deserialized to null. Raw response: {Response}", aiResponse);
                return CreateFallbackResult(aiResponse);
            }

            return result;
        }
        catch (JsonException ex)
        {
            _logger.LogError(ex, "Failed to deserialize AI response as JSON. Raw response: {Response}", aiResponse);
            return CreateFallbackResult(aiResponse);
        }
    }

    private static DocumentAnalysisResult CreateFallbackResult(string aiResponse) => new()
    {
        ErrorMessage = "The AI response could not be parsed into a structured format.",
        AiResponse = aiResponse,
        Confidence = 0f,
        Notes = $"Raw AI response (first 500 chars): {aiResponse[..Math.Min(aiResponse.Length, 500)]}"
    };

    private static DocumentAnalysisResult CreateEmptyResult(string summary, string notes) => new()
    {
        ErrorMessage = summary,
        Confidence = 0f,
        Notes = notes
    };

    private async Task<ParsedDocument> ParseDocumentAsync(AnalysisRequest request, CancellationToken cancellationToken)
    {
        var contentType = _parserFactory.ResolveContentType(request.FileName, request.ContentType);
        _logger.LogDebug("Resolved content type: {ContentType}", contentType);

        var parser = _parserFactory.GetParser(contentType);
        return await parser.ParseAsync(request.FileContent, contentType, cancellationToken);
    }

    private static string BuildCombinedText(IEnumerable<(string FileName, string Text)> entries)
    {
        var builder = new StringBuilder();
        var index = 1;

        foreach (var entry in entries)
        {
            if (builder.Length > 0)
            {
                builder.AppendLine();
                builder.AppendLine();
            }

            builder.AppendLine($"=== DOCUMENT {index}: {entry.FileName} ===");
            builder.AppendLine(entry.Text);
            index++;
        }

        return builder.ToString();
    }

    private string BuildUserPrompt(string? userPromptTemplateOverride, string extractedText)
    {
        var template = userPromptTemplateOverride;
        if (string.IsNullOrWhiteSpace(template))
        {
            return PromptTemplates.BuildUserPrompt(extractedText);
        }

        if (string.IsNullOrWhiteSpace(template))
        {
            return PromptTemplates.BuildUserPrompt(extractedText);
        }

        if (!template.Contains("{0}", StringComparison.Ordinal))
        {
            _logger.LogWarning("User prompt template is missing the {Placeholder} placeholder. Appending extracted text.", "{0}");
            return string.Concat(template.TrimEnd(), "\n\n", extractedText);
        }

        return template.Replace("{0}", extractedText, StringComparison.Ordinal);
    }

    private string ResolveSystemPrompt(string? systemPromptOverride)
    {
        if (!string.IsNullOrWhiteSpace(systemPromptOverride))
        {
            return systemPromptOverride;
        }

        return PromptTemplates.GetSystemPrompt();
    }
}

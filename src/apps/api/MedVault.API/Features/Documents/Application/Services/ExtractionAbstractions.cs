using MedVault.API.Features.Documents.Application.DTOs;
using MedVault.DocIntelligence.Analysis;

namespace MedVault.API.Features.Documents.Application.Services;

public interface IStructuredValidator
{
    ExtractionResult ValidateAndParse(string json);
}

public interface ITranslationService
{
    Task<ExtractionResult> TranslateAsync(ExtractionResult data, string language);
}

public interface IDocumentExtractionPipeline
{
    Task<ExtractionResult> ExtractAsync(
        IEnumerable<IFormFile> files,
        string preferredLanguage
        );

    Task<ExtractionResult> ExtractAsync(
        IEnumerable<IFormFile> files,
        string preferredLanguage,
        string systemPrompt,
        string userPromptTemplate
        );
}

public sealed class LlmProcessingException : DocumentExtractionException
{
    public LlmProcessingException(string message)
        : base(message)
    {
    }

    public LlmProcessingException(string message, Exception innerException)
        : base(message, innerException)
    {
    }
}

public sealed class StructuredValidationException : DocumentExtractionException
{
    public StructuredValidationException(string message)
        : base(message)
    {
    }
}


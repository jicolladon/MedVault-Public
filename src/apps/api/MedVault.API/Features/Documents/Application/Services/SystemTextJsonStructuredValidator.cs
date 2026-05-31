using MedVault.API.Features.Documents.Application.DTOs;
using Newtonsoft.Json;

namespace MedVault.API.Features.Documents.Application.Services;

public sealed class SystemTextJsonStructuredValidator : IStructuredValidator
{
    public ExtractionResult ValidateAndParse(string json)
    {
        return JsonConvert.DeserializeObject<ExtractionResult>(json)
            ?? throw new StructuredValidationException("Failed to parse JSON into ExtractionResult.");
    }
}


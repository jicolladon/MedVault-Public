using MedVault.API.Common.Models;
using MedVault.API.Features.Configuration.Application.Services;
using MedVault.API.Features.Documents.Application.DTOs;
using MedVault.API.Features.Documents.Application.Services;
using MedVault.API.Features.Documents.Domain;
using MedVault.DocIntelligence.Analysis;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

namespace MedVault.API.Features.Documents.Presentation;

[ApiController]
[Route("api/documents")]
[Authorize]
public sealed class DocumentsController : ControllerBase
{
    private readonly IDocumentExtractionPipeline _extractionPipeline;
    private readonly ISystemConfigurationService _systemConfigurationService;
    private readonly DocumentExtractionOptions _extractionOptions;
    private readonly ILogger<DocumentsController> _logger;

    public DocumentsController(
        IDocumentExtractionPipeline extractionPipeline,
        ISystemConfigurationService systemConfigurationService,
        IOptions<DocumentExtractionOptions> extractionOptions,
        ILogger<DocumentsController> logger)
    {
        _extractionPipeline = extractionPipeline;
        _systemConfigurationService = systemConfigurationService;
        _extractionOptions = extractionOptions.Value;
        _logger = logger;
    }

    [HttpPost("extract")]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(ApiResponse<ExtractionResult>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status413PayloadTooLarge)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status415UnsupportedMediaType)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status422UnprocessableEntity)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status503ServiceUnavailable)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status502BadGateway)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status504GatewayTimeout)]
    public async Task<IActionResult> Extract([FromForm] ExtractDocumentsRequest request)
    {
        var documentSettings = _systemConfigurationService.GetDocumentSettings();
        if (!documentSettings.DocumentExtractDataEnabled)
        {
            return StatusCode(
                StatusCodes.Status503ServiceUnavailable,
                ApiResponse.Fail("Document extraction is currently disabled by system configuration."));
        }

        if (documentSettings.DemonstrationModeEnabled)
        {
            _logger.LogInformation("Document extraction request received with {FileCount} files.", request.Files.Count);
            var result = new ExtractionResult()
            {
                IsMedical = true,
                DocumentType = "Medical Report",
                Tags = new List<string> { "Report", "Medical" },
                Date = DateTime.UtcNow,
                IssuerName = "HealthCare Inc.",
                Metadata = new MedicalMetadata
                {
                    Allergies = new List<AllergyInfo>
                    {
                        new AllergyInfo
                        {
                            Allergen = "Peanuts",
                            Reaction = "Anaphylaxis",
                            Severity = AllergySeverity.Severe
                        }
                    },
                    Medications = new List<MedicationInfo>
                    {
                        new MedicationInfo
                        {
                            Name = "Ibuprofen",
                            Dosage = "200 mg",
                            Frequency = "Every 6 hours",
                            Notes = "Take with food",
                            StartDate = DateTime.UtcNow,
                            EndDate = DateTime.UtcNow.AddDays(7),
                        }
                    },
                    Diagnoses = new List<DiagnosisInfo>
                    {
                        new DiagnosisInfo
                        {
                            Name = "Hypertension",
                            DiagnosisDate = DateTime.UtcNow,
                            Duration = "Chronic",
                            Notes = "Patient has a history of high blood pressure."
                        }
                    },
                    Vaccinations = new List<VaccinationInfo>
                    {
                        new VaccinationInfo
                        {
                            VaccineName = "Influenza",
                            Dates = new List<DateTime> { DateTime.UtcNow.AddMonths(-3) },
                        }
                    },
                    LabResults = new List<LabResultInfo>
                    {
                        new LabResultInfo
                        {
                            TestName = "Complete Blood Count",
                            Category = "Hematology",
                            Notes = "All values are within normal ranges.",
                            TestDate = DateTime.UtcNow.AddDays(-1),
                            TestValues = new List<LabTestValue>()
                            {
                                new LabTestValue
                                {
                                    Name = "White Blood Cells",
                                    Value = "5.5",
                                    Unit = "x10^9/L",
                                    MinRange = "4.0",
                                    MaxRange = "11.0"
                                },
                                new LabTestValue
                                {
                                    Name = "Hemoglobin",
                                    Value = "13.2",
                                    Unit = "g/dL",
                                    MinRange = "13.5",
                                    MaxRange = "17.5"
                                },
                                new LabTestValue
                                {
                                    Name = "Platelets",
                                    Value = "250",
                                    Unit = "x10^9/L",
                                    MinRange = "150",
                                    MaxRange = "450"
                                }
                            }
                        }
                    }
                },
                Summary = "This is general document about your health care status, with the latest blood test results, vaccinations and other main information",
                Confidence = 0.95,
                RequiresUserConfirmation = false

            };
            return Ok(ApiResponse<ExtractionResult>.Ok(result));
        }

        var files = ResolveFiles(request.Files);
        if (files.Count == 0)
        {
            return BadRequest(ApiResponse.Fail("At least one file is required."));
        }

        var totalBytes = files.Sum(file => file.Length);
        if (totalBytes > _extractionOptions.MaxTotalFileSizeBytes)
        {
            return StatusCode(
                StatusCodes.Status413PayloadTooLarge,
                ApiResponse.Fail($"Max upload size is {_extractionOptions.MaxTotalFileSizeBytes} bytes."));
        }

        var unsupportedFiles = files
            .Where(file => !IsMimeTypeAllowed(ResolveMimeType(file)))
            .Select(file => file.FileName)
            .ToList();

        if (unsupportedFiles.Count > 0)
        {
            return StatusCode(
                StatusCodes.Status415UnsupportedMediaType,
                ApiResponse.Fail(
                    "One or more uploaded files have unsupported MIME types.",
                    unsupportedFiles));
        }

        try
        {
            var result = await _extractionPipeline.ExtractAsync(
                files,
                request.PreferredLanguage
                );
            return Ok(ApiResponse<ExtractionResult>.Ok(result));
        }
        catch (StructuredValidationException exception)
        {
            _logger.LogWarning(exception, "Structured extraction validation failed.");
            return UnprocessableEntity(ApiResponse.Fail("LLM output failed schema validation."));
        }
        catch (OcrProcessingException exception)
        {
            _logger.LogWarning(exception, "OCR processing failed.");
            return StatusCode(StatusCodes.Status502BadGateway, ApiResponse.Fail("OCR failed for uploaded files."));
        }
        catch (LlmProcessingException exception)
        {
            _logger.LogWarning(exception, "LLM processing failed.");
            var isTimeout = exception.Message.Contains("timed out", StringComparison.OrdinalIgnoreCase);
            return StatusCode(
                isTimeout ? StatusCodes.Status504GatewayTimeout : StatusCodes.Status502BadGateway,
                ApiResponse.Fail(isTimeout ? "LLM timed out." : "LLM extraction failed."));
        }
        catch (DocumentExtractionException exception)
        {
            _logger.LogWarning(exception, "Document extraction failed.");
            return StatusCode(StatusCodes.Status502BadGateway, ApiResponse.Fail(exception.Message));
        }
    }

    private List<IFormFile> ResolveFiles(List<IFormFile> files)
    {
        return files;
    }

    private bool IsMimeTypeAllowed(string mimeType)
    {
        if (string.IsNullOrWhiteSpace(mimeType))
        {
            return false;
        }

        return _extractionOptions.AllowedMimeTypes.Any(
            allowed => string.Equals(allowed, mimeType, StringComparison.OrdinalIgnoreCase));
    }

    private static string ResolveMimeType(IFormFile file)
    {
        if (!string.IsNullOrWhiteSpace(file.ContentType) &&
            !string.Equals(file.ContentType, "application/octet-stream", StringComparison.OrdinalIgnoreCase))
        {
            return file.ContentType;
        }

        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        return extension switch
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
}


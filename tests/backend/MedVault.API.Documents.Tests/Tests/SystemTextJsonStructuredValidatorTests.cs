using MedVault.API.Features.Documents.Application.Services;
using Xunit;

namespace MedVault.API.Documents.Tests.Tests;

public sealed class SystemTextJsonStructuredValidatorTests
{
    private readonly SystemTextJsonStructuredValidator _validator = new();

    [Fact]
    public void ValidateAndParse_ValidJson_ReturnsStronglyTypedModel()
    {
        var json = """
            {
              "isMedical": true,
              "documentType": "Prescription",
              "date": "2026-04-12",
              "issuerName": "North Hospital",
              "metadata": {
                "medications": [
                  { "name": "Amoxicillin", "dosage": "500 mg" }
                ],
                "labResults": [
                  { "testName": "Hemoglobin", "value": "13.2", "unit": "g/dL" }
                ],
                "allergies": [],
                "diagnoses": [],
                "vaccinations": []
              },
              "summary": "Prescription with one medication.",
              "llmConfidence": 0.88
            }
            """;

        var result = _validator.ValidateAndParse(json);

        Assert.True(result.IsMedical);
        Assert.Equal("Prescription", result.DocumentType);
        Assert.Equal(new DateTime(2026, 4, 12, 0, 0, 0, DateTimeKind.Utc), result.Date);
        Assert.Equal("North Hospital", result.IssuerName);
        Assert.Single(result.Metadata.Medications);
        Assert.Single(result.Metadata.LabResults);
        Assert.Equal(0.88, result.Confidence, 3);
    }

    [Fact]
    public void ValidateAndParse_MissingRequiredField_ThrowsValidationException()
    {
        var json = """
            {
              "isMedical": true,
              "date": null,
              "issuerName": "North Hospital",
              "metadata": {
                "medications": [],
                "labResults": [],
                "allergies": [],
                "diagnoses": [],
                "vaccinations": []
              },
              "summary": "Missing document type."
            }
            """;

        Assert.Throws<StructuredValidationException>(() => _validator.ValidateAndParse(json));
    }

    [Fact]
    public void ValidateAndParse_InvalidDateFormat_ThrowsValidationException()
    {
        var json = """
            {
              "isMedical": true,
              "documentType": "Lab Report",
              "date": "12/04/2026",
              "issuerName": "North Hospital",
              "metadata": {
                "medications": [],
                "labResults": [],
                "allergies": [],
                "diagnoses": [],
                "vaccinations": []
              },
              "summary": "Date format is invalid."
            }
            """;

        Assert.Throws<StructuredValidationException>(() => _validator.ValidateAndParse(json));
    }
}

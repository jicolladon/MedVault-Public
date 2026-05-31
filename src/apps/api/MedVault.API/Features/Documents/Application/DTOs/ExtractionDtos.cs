using Microsoft.AspNetCore.Mvc;

namespace MedVault.API.Features.Documents.Application.DTOs;

public sealed class ExtractDocumentsRequest
{
    [FromForm(Name = "files")]
    public List<IFormFile> Files { get; init; } = [];

    [FromForm(Name = "preferredLanguage")]
    public string PreferredLanguage { get; init; } = "en";
}
public static class ExtractionResultExtensions
{
    public static string JsonSchema => """
        {
            "IsMedical": bool, - Indicates if the document is medical in nature
            "DocumentType": string, - The type of document (e.g., "Lab Report", "Prescription", "Unknown")
            "Tags": [string], - List of tags or keywords extracted from the document
            "Date": string (ISO 8601 format) or null, - The date associated
            "IssuerName": string, - The name of the issuer of the document (e.g., hospital, clinic)
            "Summary": string, - A brief summary of the document's content
            "Confidence": double (0.0 to 1.0), - Confidence score of the extraction results
            "RequiresUserConfirmation": bool - Indicates if the results require user confirmation due to low confidence or potential ambiguity
            "Metadata": {
                "Medications": [
                    {
                        "Name": string, - Name of the medication
                        "Dosage": string, - Dosage information (e.g., "200 mg")
                        "Frequency": string, - Frequency of administration (e.g., "twice a day")
                        "StartDate": string (ISO 8601 format) or null, - Start date of the medication
                        "EndDate": string (ISO 8601 format) or null, - End date of the medication
                        "Notes": string - Additional notes about the medication
                    }
                ],
                "LabResults": [
                    {
                        "TestName": string, - Name of the lab test
                        "Notes": string, - Additional notes about the lab test
                        "TestDate": string (ISO 8601 format) or null, - Date of the lab test
                        "Category": string - Category of the lab test (e.g., "Blood Test", "Urine Test")
                        "TestValues": [
                            {
                                "Name": string, - Name of the individual test value (e.g., "Hemoglobin")
                                "Value": string, - Value of the test result (e.g., "13.2")
                                "Unit": string, - Unit of the test result (e.g., "g/dL")
                                "MinRange": string, - Minimum reference range for the test value
                                "MaxRange": string - Maximum reference range for the test value
                            }
                        ]
                    }
                ],
                "Allergies": [
                    {
                        "Allergen": string, - Name of the allergen
                        "Reaction": string, - Description of the allergic reaction
                        "Severity": string ("Mild", "Moderate", "Severe"), - Severity of the allergy
                        "Notes": string - Additional notes about the allergy
                    }
                ],
                "Diagnoses": [
                    {
                        "Name": string, - Name of the diagnosis
                        "Notes": string, - Additional notes about the diagnosis
                        "DiagnosisDate": string (ISO 8601 format) or null, - Date of diagnosis
                        "Duration": string - Duration of the condition (e.g., "2 weeks", "chronic")
                    }
                ],
                "Vaccinations": [
                    {
                        "VaccineName": string, - Name of the vaccine or the disease it protects against
                        "Dates": [string] (ISO 8601 format) - List of vaccination dates
                    }
                ]
            }
        }
        """;
}

public sealed class ExtractionResult
{
    public bool IsMedical { get; set; }

    public string DocumentType { get; set; } = string.Empty;

    public List<string> Tags { get; set; } = new();

    public DateTime? Date { get; set; }

    public string IssuerName { get; set; } = string.Empty;

    public MedicalMetadata Metadata { get; set; } = new();

    public string Summary { get; set; } = string.Empty;

    public double Confidence { get; set; }

    public bool RequiresUserConfirmation { get; set; } = true;
}

public sealed class MedicalMetadata
{
    public List<MedicationInfo> Medications { get; set; } = [];

    public List<LabResultInfo> LabResults { get; set; } = [];

    public List<AllergyInfo> Allergies { get; set; } = [];

    public List<DiagnosisInfo> Diagnoses { get; set; } = [];

    public List<VaccinationInfo> Vaccinations { get; set; } = [];
}

public sealed class MedicationInfo
{
    public string Name { get; set; } = string.Empty;

    public string Dosage { get; set; } = string.Empty;
    public string Frequency { get; set; } = string.Empty;
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public string Notes { get; set; } = string.Empty;
}

public sealed class LabResultInfo
{
    public string TestName { get; set; } = string.Empty;

    public List<LabTestValue> TestValues { get; set; } = [];
    public string Notes { get; set; }
    public DateTime? TestDate { get; set; }
    public string Category { get; set; } = string.Empty;
}

public sealed class LabTestValue
{
    public string Name { get; set; }
    public string Value { get; set; } = string.Empty;
    public string? Unit { get; set; } = string.Empty;
    public string? MinRange { get; set; } = string.Empty;
    public string? MaxRange { get; set; } = string.Empty;
}

public sealed class AllergyInfo
{
    public string Allergen { get; set; } = string.Empty;

    public string Reaction { get; set; } = string.Empty;

    public AllergySeverity Severity { get; set; }
    public string Notes { get; set; } = string.Empty;
}

public enum AllergySeverity
{
    Mild,
    Moderate,
    Severe
}

public sealed class DiagnosisInfo
{
    public string Name { get; set; } = string.Empty;

    public string Notes { get; set; } = string.Empty;
    public DateTime? DiagnosisDate { get; set; }

    public string Duration { get; set; } = string.Empty;

}

public sealed class VaccinationInfo
{
    public string VaccineName { get; set; } = string.Empty;

    public List<DateTime> Dates { get; set; } = new();
}


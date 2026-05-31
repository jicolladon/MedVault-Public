using System.Text.Json;
using FluentAssertions;
using MedVault.DocIntelligence.Models;

namespace MedVault.DocIntelligence.Tests.Models;

public class DocumentAnalysisResultTests
{
    [Fact]
    public void Serialize_WithFullResult_ProducesValidJson()
    {
        var result = new DocumentAnalysisResult
        {
            DocumentType = MedicalDocumentType.BloodTest,
            Summary = "Complete blood count results.",
            DocumentDate = "2025-06-15",
            PatientName = "John Doe",
            DoctorName = "Dr. Smith",
            Institution = "City Hospital",
            Confidence = 0.95f,
            Fields =
            [
                new ExtractedField
                {
                    Name = "Hemoglobin",
                    Value = "14.2",
                    Unit = "g/dL",
                    ReferenceRange = "12.0-17.5",
                    Category = "Hematology",
                    IsAbnormal = false
                }
            ]
        };

        var json = JsonSerializer.Serialize(result);

        json.Should().NotBeNullOrEmpty();

        var deserialized = JsonSerializer.Deserialize<DocumentAnalysisResult>(json);
        deserialized.Should().NotBeNull();
        deserialized!.DocumentType.Should().Be(MedicalDocumentType.BloodTest);
        deserialized.Fields.Should().HaveCount(1);
        deserialized.Fields[0].Name.Should().Be("Hemoglobin");
    }

    [Fact]
    public void Deserialize_WithEnumAsString_ParsesCorrectly()
    {
        var json = """
        {
            "documentType": "Diagnosis",
            "summary": "Test",
            "confidence": 0.8,
            "fields": []
        }
        """;

        var result = JsonSerializer.Deserialize<DocumentAnalysisResult>(json);

        result.Should().NotBeNull();
        result!.DocumentType.Should().Be(MedicalDocumentType.Diagnosis);
    }

    [Fact]
    public void Deserialize_WithNullOptionalFields_SucceedsWithDefaults()
    {
        var json = """
        {
            "documentType": "Unknown",
            "summary": "Minimal",
            "confidence": 0.5,
            "fields": []
        }
        """;

        var result = JsonSerializer.Deserialize<DocumentAnalysisResult>(json);

        result.Should().NotBeNull();
        result!.PatientName.Should().BeNull();
        result.DoctorName.Should().BeNull();
        result.Institution.Should().BeNull();
        result.RawText.Should().BeNull();
        result.Notes.Should().BeNull();
    }

    [Fact]
    public void Default_HasEmptyFieldsList()
    {
        var result = new DocumentAnalysisResult();

        result.Fields.Should().NotBeNull();
        result.Fields.Should().BeEmpty();
        result.DocumentType.Should().Be(MedicalDocumentType.Unknown);
    }

    [Fact]
    public void ExtractedField_SerializesAllProperties()
    {
        var field = new ExtractedField
        {
            Name = "Glucose",
            Value = "95",
            Unit = "mg/dL",
            ReferenceRange = "70-100",
            Category = "Biochemistry",
            IsAbnormal = false
        };

        var json = JsonSerializer.Serialize(field);
        var deserialized = JsonSerializer.Deserialize<ExtractedField>(json);

        deserialized.Should().NotBeNull();
        deserialized!.Name.Should().Be("Glucose");
        deserialized.Value.Should().Be("95");
        deserialized.Unit.Should().Be("mg/dL");
        deserialized.ReferenceRange.Should().Be("70-100");
        deserialized.Category.Should().Be("Biochemistry");
        deserialized.IsAbnormal.Should().BeFalse();
    }
}

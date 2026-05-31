using System.Text.Json;
using FluentAssertions;
using MedVault.DocIntelligence.Analysis;
using MedVault.DocIntelligence.Configuration;
using MedVault.DocIntelligence.Models;
using MedVault.DocIntelligence.Parsing;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Moq;

namespace MedVault.DocIntelligence.Tests.Analysis;

public class MedicalDocumentAnalyzerTests
{
    private readonly Mock<IAiProvider> _aiProviderMock;
    private readonly Mock<IDocumentParser> _pdfParserMock;
    private readonly DocumentParserFactory _parserFactory;
    private readonly MedicalDocumentAnalyzer _analyzer;

    public MedicalDocumentAnalyzerTests()
    {
        _aiProviderMock = new Mock<IAiProvider>();

        _pdfParserMock = new Mock<IDocumentParser>();
        _pdfParserMock.Setup(p => p.SupportedContentTypes)
            .Returns(new[] { "application/pdf" });

        var parsers = new List<IDocumentParser> { _pdfParserMock.Object };
        _parserFactory = new DocumentParserFactory(parsers, Mock.Of<ILogger<DocumentParserFactory>>());

        _analyzer = new MedicalDocumentAnalyzer(
            _parserFactory,
            _aiProviderMock.Object,
            Options.Create(new PromptOptions()),
            Mock.Of<ILogger<MedicalDocumentAnalyzer>>());
    }

    [Fact]
    public async Task AnalyzeAsync_WithBloodTestPdf_ReturnsStructuredResult()
    {
        // Arrange
        var parsedDocument = new ParsedDocument
        {
            ExtractedText = "Patient: John Doe\nDate: 2025-01-15\nHemoglobin: 14.2 g/dL (12.0-17.5)\nGlucose: 95 mg/dL (70-100)",
            Pages = ["Patient: John Doe\nDate: 2025-01-15\nHemoglobin: 14.2 g/dL (12.0-17.5)\nGlucose: 95 mg/dL (70-100)"],
            FileMetadata = new Dictionary<string, string> { ["pageCount"] = "1" }
        };

        _pdfParserMock
            .Setup(p => p.ParseAsync(It.IsAny<Stream>(), "application/pdf", It.IsAny<CancellationToken>()))
            .ReturnsAsync(parsedDocument);

        var aiResponse = JsonSerializer.Serialize(new DocumentAnalysisResult
        {
            DocumentType = MedicalDocumentType.BloodTest,
            Summary = "Blood test results for John Doe dated January 15, 2025.",
            DocumentDate = "2025-01-15",
            PatientName = "John Doe",
            Confidence = 0.95f,
            Fields =
            [
                new ExtractedField { Name = "Hemoglobin", Value = "14.2", Unit = "g/dL", ReferenceRange = "12.0-17.5", Category = "Hematology", IsAbnormal = false },
                new ExtractedField { Name = "Glucose", Value = "95", Unit = "mg/dL", ReferenceRange = "70-100", Category = "Biochemistry", IsAbnormal = false }
            ]
        });

        _aiProviderMock
            .Setup(p => p.GetCompletionAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(aiResponse);

        using var stream = new MemoryStream([0x01]);
        var request = new AnalysisRequest
        {
            FileContent = stream,
            FileName = "blood-test.pdf"
        };

        // Act
        var result = await _analyzer.AnalyzeAsync(request);

        // Assert
        result.Should().NotBeNull();
        result.DocumentType.Should().Be(MedicalDocumentType.BloodTest);
        result.Summary.Should().Contain("Blood test");
        result.PatientName.Should().Be("John Doe");
        result.DocumentDate.Should().Be("2025-01-15");
        result.Confidence.Should().BeGreaterThan(0.9f);
        result.Fields.Should().HaveCount(2);
        result.Fields.Should().Contain(f => f.Name == "Hemoglobin" && f.Value == "14.2");
        result.Fields.Should().Contain(f => f.Name == "Glucose" && f.Value == "95");
    }

    [Fact]
    public async Task AnalyzeAsync_WithDiagnosis_ReturnsStructuredResult()
    {
        // Arrange
        var parsedDocument = new ParsedDocument
        {
            ExtractedText = "Diagnosis: Type 2 Diabetes\nDoctor: Dr. Smith\nDate: 2025-03-10\nHospital: City General",
            Pages = ["Diagnosis: Type 2 Diabetes\nDoctor: Dr. Smith\nDate: 2025-03-10\nHospital: City General"]
        };

        _pdfParserMock
            .Setup(p => p.ParseAsync(It.IsAny<Stream>(), "application/pdf", It.IsAny<CancellationToken>()))
            .ReturnsAsync(parsedDocument);

        var aiResponse = JsonSerializer.Serialize(new DocumentAnalysisResult
        {
            DocumentType = MedicalDocumentType.Diagnosis,
            Summary = "Type 2 Diabetes diagnosis by Dr. Smith at City General Hospital.",
            DocumentDate = "2025-03-10",
            PatientName = null,
            DoctorName = "Dr. Smith",
            Institution = "City General",
            Confidence = 0.88f,
            Fields =
            [
                new ExtractedField { Name = "Diagnosis", Value = "Type 2 Diabetes", Category = "Diagnosis" },
                new ExtractedField { Name = "DoctorName", Value = "Dr. Smith", Category = "Metadata" },
                new ExtractedField { Name = "Hospital", Value = "City General", Category = "Metadata" }
            ]
        });

        _aiProviderMock
            .Setup(p => p.GetCompletionAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(aiResponse);

        using var stream = new MemoryStream([0x01]);
        var request = new AnalysisRequest
        {
            FileContent = stream,
            FileName = "diagnosis.pdf"
        };

        // Act
        var result = await _analyzer.AnalyzeAsync(request);

        // Assert
        result.Should().NotBeNull();
        result.DocumentType.Should().Be(MedicalDocumentType.Diagnosis);
        result.DoctorName.Should().Be("Dr. Smith");
        result.Institution.Should().Be("City General");
        result.Fields.Should().Contain(f => f.Name == "Diagnosis" && f.Value == "Type 2 Diabetes");
    }

    [Fact]
    public async Task AnalyzeAsync_WithEmptyDocument_ReturnsUnknownType()
    {
        // Arrange
        _pdfParserMock
            .Setup(p => p.ParseAsync(It.IsAny<Stream>(), "application/pdf", It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ParsedDocument { ExtractedText = "" });

        using var stream = new MemoryStream([0x01]);
        var request = new AnalysisRequest
        {
            FileContent = stream,
            FileName = "empty.pdf"
        };

        // Act
        var result = await _analyzer.AnalyzeAsync(request);

        // Assert
        result.Should().NotBeNull();
        result.DocumentType.Should().Be(MedicalDocumentType.Unknown);
        result.Confidence.Should().Be(0f);
        result.Summary.Should().Contain("No text could be extracted");
    }

    [Fact]
    public async Task AnalyzeAsync_WithInvalidAiResponse_ReturnsFallbackResult()
    {
        // Arrange
        _pdfParserMock
            .Setup(p => p.ParseAsync(It.IsAny<Stream>(), "application/pdf", It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ParsedDocument { ExtractedText = "Some text" });

        _aiProviderMock
            .Setup(p => p.GetCompletionAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync("This is not valid JSON at all!");

        using var stream = new MemoryStream([0x01]);
        var request = new AnalysisRequest
        {
            FileContent = stream,
            FileName = "test.pdf"
        };

        // Act
        var result = await _analyzer.AnalyzeAsync(request);

        // Assert
        result.Should().NotBeNull();
        result.DocumentType.Should().Be(MedicalDocumentType.Unknown);
        result.Confidence.Should().Be(0f);
        result.Notes.Should().Contain("Raw AI response");
    }

    [Fact]
    public async Task AnalyzeAsync_WithMarkdownWrappedJson_ParsesCorrectly()
    {
        // Arrange - AI sometimes wraps JSON in ```json ... ```
        var parsedDocument = new ParsedDocument
        {
            ExtractedText = "Some medical text",
            Pages = ["Some medical text"]
        };

        _pdfParserMock
            .Setup(p => p.ParseAsync(It.IsAny<Stream>(), "application/pdf", It.IsAny<CancellationToken>()))
            .ReturnsAsync(parsedDocument);

        var validResult = new DocumentAnalysisResult
        {
            DocumentType = MedicalDocumentType.Prescription,
            Summary = "Prescription for medication.",
            Confidence = 0.85f,
            Fields = [new ExtractedField { Name = "Medication", Value = "Ibuprofen 400mg" }]
        };
        var jsonInner = JsonSerializer.Serialize(validResult);
        var wrappedResponse = $"```json\n{jsonInner}\n```";

        _aiProviderMock
            .Setup(p => p.GetCompletionAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(wrappedResponse);

        using var stream = new MemoryStream([0x01]);
        var request = new AnalysisRequest
        {
            FileContent = stream,
            FileName = "prescription.pdf"
        };

        // Act
        var result = await _analyzer.AnalyzeAsync(request);

        // Assert
        result.Should().NotBeNull();
        result.DocumentType.Should().Be(MedicalDocumentType.Prescription);
        result.Summary.Should().Contain("Prescription");
    }

    [Fact]
    public async Task AnalyzeAsync_WithIncludeRawText_AttachesExtractedText()
    {
        // Arrange
        const string expectedText = "Raw document text here";
        _pdfParserMock
            .Setup(p => p.ParseAsync(It.IsAny<Stream>(), "application/pdf", It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ParsedDocument { ExtractedText = expectedText });

        _aiProviderMock
            .Setup(p => p.GetCompletionAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(JsonSerializer.Serialize(new DocumentAnalysisResult
            {
                DocumentType = MedicalDocumentType.LabResult,
                Summary = "Lab results.",
                Confidence = 0.9f
            }));

        using var stream = new MemoryStream([0x01]);
        var request = new AnalysisRequest
        {
            FileContent = stream,
            FileName = "lab.pdf",
            IncludeRawText = true
        };

        // Act
        var result = await _analyzer.AnalyzeAsync(request);

        // Assert
        result.RawText.Should().Be(expectedText);
    }

    [Fact]
    public async Task AnalyzeAsync_WithoutIncludeRawText_DoesNotAttachText()
    {
        // Arrange
        _pdfParserMock
            .Setup(p => p.ParseAsync(It.IsAny<Stream>(), "application/pdf", It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ParsedDocument { ExtractedText = "Some text" });

        _aiProviderMock
            .Setup(p => p.GetCompletionAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(JsonSerializer.Serialize(new DocumentAnalysisResult
            {
                DocumentType = MedicalDocumentType.LabResult,
                Summary = "Lab results.",
                Confidence = 0.9f
            }));

        using var stream = new MemoryStream([0x01]);
        var request = new AnalysisRequest
        {
            FileContent = stream,
            FileName = "lab.pdf",
            IncludeRawText = false
        };

        // Act
        var result = await _analyzer.AnalyzeAsync(request);

        // Assert
        result.RawText.Should().BeNull();
    }

    [Fact]
    public async Task AnalyzeAsync_CallsParserAndAiProviderInOrder()
    {
        // Arrange
        var callOrder = new List<string>();

        _pdfParserMock
            .Setup(p => p.ParseAsync(It.IsAny<Stream>(), "application/pdf", It.IsAny<CancellationToken>()))
            .Callback(() => callOrder.Add("parser"))
            .ReturnsAsync(new ParsedDocument { ExtractedText = "Text" });

        _aiProviderMock
            .Setup(p => p.GetCompletionAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .Callback(() => callOrder.Add("ai"))
            .ReturnsAsync(JsonSerializer.Serialize(new DocumentAnalysisResult
            {
                DocumentType = MedicalDocumentType.Unknown,
                Summary = "Test",
                Confidence = 0.5f
            }));

        using var stream = new MemoryStream([0x01]);
        var request = new AnalysisRequest
        {
            FileContent = stream,
            FileName = "test.pdf"
        };

        // Act
        await _analyzer.AnalyzeAsync(request);

        // Assert
        callOrder.Should().ContainInOrder("parser", "ai");
    }

    [Fact]
    public async Task AnalyzeAsync_WithNullRequest_ThrowsArgumentNullException()
    {
        await Assert.ThrowsAsync<ArgumentNullException>(
            () => _analyzer.AnalyzeAsync(null!));
    }

    [Fact]
    public async Task AnalyzeAsync_WithPromptOverrides_UsesOverrides()
    {
        // Arrange
        _pdfParserMock
            .Setup(p => p.ParseAsync(It.IsAny<Stream>(), "application/pdf", It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ParsedDocument { ExtractedText = "Test text" });

        var systemPrompt = "Custom system prompt";
        var userTemplate = "CUSTOM TEMPLATE: {0}";

        _aiProviderMock
            .Setup(p => p.GetCompletionAsync(systemPrompt, It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(JsonSerializer.Serialize(new DocumentAnalysisResult
            {
                DocumentType = MedicalDocumentType.Unknown,
                Summary = "Test",
                Confidence = 0.5f
            }));

        using var stream = new MemoryStream([0x01]);
        var request = new AnalysisRequest
        {
            FileContent = stream,
            FileName = "test.pdf",
            SystemPrompt = systemPrompt,
            UserPromptTemplate = userTemplate
        };

        // Act
        await _analyzer.AnalyzeAsync(request);

        // Assert
        _aiProviderMock.Verify(
            p => p.GetCompletionAsync(
                systemPrompt,
                It.Is<string>(value => value.Contains("CUSTOM TEMPLATE") && value.Contains("Test text")),
                It.IsAny<CancellationToken>()),
            Times.Once);
    }
}

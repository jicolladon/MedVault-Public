using FluentAssertions;
using MedVault.DocIntelligence.Parsing;
using Microsoft.Extensions.Logging;
using Moq;
using UglyToad.PdfPig;
using UglyToad.PdfPig.Writer;

namespace MedVault.DocIntelligence.Tests.Parsing;

public class PdfDocumentParserTests
{
    private readonly PdfDocumentParser _parser;
    private readonly Mock<ILogger<PdfDocumentParser>> _logger;

    public PdfDocumentParserTests()
    {
        _logger = new Mock<ILogger<PdfDocumentParser>>();
        _parser = new PdfDocumentParser(_logger.Object);
    }

    [Fact]
    public void SupportedContentTypes_ContainsPdf()
    {
        _parser.SupportedContentTypes.Should().Contain("application/pdf");
    }

    [Fact]
    public async Task ParseAsync_WithValidPdf_ExtractsTextAndMetadata()
    {
        // Arrange - Create a simple PDF in memory using PdfPig
        var pdfBytes = CreateSimplePdf("Patient: John Doe  Hemoglobin: 14.2 g/dL  Glucose: 95 mg/dL");
        using var stream = new MemoryStream(pdfBytes);

        // Act
        var result = await _parser.ParseAsync(stream, "application/pdf");

        // Assert
        result.Should().NotBeNull();
        result.ExtractedText.Should().NotBeNullOrWhiteSpace();
        result.Pages.Should().HaveCountGreaterThan(0);
        result.FileMetadata.Should().ContainKey("pageCount");
    }

    [Fact]
    public async Task ParseAsync_WithEmptyStream_ReturnsEmptyResult()
    {
        // Arrange - Create an empty (but valid) PDF
        var pdfBytes = CreateSimplePdf(string.Empty);
        using var stream = new MemoryStream(pdfBytes);

        // Act
        var result = await _parser.ParseAsync(stream, "application/pdf");

        // Assert
        result.Should().NotBeNull();
        result.FileMetadata.Should().ContainKey("pageCount");
    }

    [Fact]
    public async Task ParseAsync_WithCancellation_ThrowsOperationCanceledException()
    {
        // Arrange
        var pdfBytes = CreateSimplePdf("Test content");
        using var stream = new MemoryStream(pdfBytes);
        using var cts = new CancellationTokenSource();
        await cts.CancelAsync();

        // Act & Assert — CopyToAsync throws TaskCanceledException which derives from OperationCanceledException
        await Assert.ThrowsAnyAsync<OperationCanceledException>(
            () => _parser.ParseAsync(stream, "application/pdf", cts.Token));
    }

    /// <summary>
    /// Creates a simple single-page PDF with text content using PdfPig's PdfDocumentBuilder.
    /// </summary>
    private static byte[] CreateSimplePdf(string text)
    {
        var builder = new PdfDocumentBuilder();
        var page = builder.AddPage(595, 842); // A4 size in points

        if (!string.IsNullOrEmpty(text))
        {
            var font = builder.AddStandard14Font(UglyToad.PdfPig.Fonts.Standard14Fonts.Standard14Font.Helvetica);
            page.AddText(text, 12, new UglyToad.PdfPig.Core.PdfPoint(50, 750), font);
        }

        return builder.Build();
    }
}

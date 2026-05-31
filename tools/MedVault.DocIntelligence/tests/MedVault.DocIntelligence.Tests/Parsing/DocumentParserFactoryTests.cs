using FluentAssertions;
using MedVault.DocIntelligence.Parsing;
using Microsoft.Extensions.Logging;
using Moq;

namespace MedVault.DocIntelligence.Tests.Parsing;

public class DocumentParserFactoryTests
{
    private readonly DocumentParserFactory _factory;
    private readonly Mock<IDocumentParser> _pdfParser;
    private readonly Mock<IDocumentParser> _imageParser;

    public DocumentParserFactoryTests()
    {
        _pdfParser = new Mock<IDocumentParser>();
        _pdfParser.Setup(p => p.SupportedContentTypes)
            .Returns(new[] { "application/pdf" });

        _imageParser = new Mock<IDocumentParser>();
        _imageParser.Setup(p => p.SupportedContentTypes)
            .Returns(new[] { "image/jpeg", "image/png", "image/tiff", "image/bmp", "image/gif" });

        var parsers = new List<IDocumentParser> { _pdfParser.Object, _imageParser.Object };
        var logger = Mock.Of<ILogger<DocumentParserFactory>>();

        _factory = new DocumentParserFactory(parsers, logger);
    }

    [Fact]
    public void GetParser_WithPdfContentType_ReturnsPdfParser()
    {
        var parser = _factory.GetParser("application/pdf");

        parser.Should().Be(_pdfParser.Object);
    }

    [Theory]
    [InlineData("image/jpeg")]
    [InlineData("image/png")]
    [InlineData("image/tiff")]
    [InlineData("image/bmp")]
    [InlineData("image/gif")]
    public void GetParser_WithImageContentType_ReturnsImageParser(string contentType)
    {
        var parser = _factory.GetParser(contentType);

        parser.Should().Be(_imageParser.Object);
    }

    [Fact]
    public void GetParser_WithUnsupportedContentType_ThrowsNotSupportedException()
    {
        var act = () => _factory.GetParser("application/xml");

        act.Should().Throw<NotSupportedException>()
            .WithMessage("*application/xml*");
    }

    [Theory]
    [InlineData("report.pdf", null, "application/pdf")]
    [InlineData("scan.jpg", null, "image/jpeg")]
    [InlineData("scan.jpeg", null, "image/jpeg")]
    [InlineData("photo.png", null, "image/png")]
    [InlineData("document.tiff", null, "image/tiff")]
    [InlineData("document.tif", null, "image/tiff")]
    [InlineData("photo.bmp", null, "image/bmp")]
    [InlineData("image.gif", null, "image/gif")]
    public void ResolveContentType_WithFileExtension_ReturnsCorrectContentType(
        string fileName, string? providedContentType, string expectedContentType)
    {
        var result = _factory.ResolveContentType(fileName, providedContentType);

        result.Should().Be(expectedContentType);
    }

    [Fact]
    public void ResolveContentType_WithProvidedContentType_ReturnsProvided()
    {
        var result = _factory.ResolveContentType("file.xyz", "custom/type");

        result.Should().Be("custom/type");
    }

    [Fact]
    public void ResolveContentType_WithUnsupportedExtension_ThrowsNotSupportedException()
    {
        var act = () => _factory.ResolveContentType("file.docx", null);

        act.Should().Throw<NotSupportedException>()
            .WithMessage("*Unsupported file extension*");
    }

    [Fact]
    public void ResolveContentType_WithNoExtension_ThrowsArgumentException()
    {
        var act = () => _factory.ResolveContentType("filenoext", null);

        act.Should().Throw<ArgumentException>()
            .WithMessage("*Cannot determine content type*");
    }

    [Fact]
    public void SupportedExtensions_ContainsExpectedExtensions()
    {
        var extensions = DocumentParserFactory.SupportedExtensions;

        extensions.Should().Contain(".pdf");
        extensions.Should().Contain(".jpg");
        extensions.Should().Contain(".jpeg");
        extensions.Should().Contain(".png");
        extensions.Should().Contain(".tiff");
        extensions.Should().Contain(".tif");
        extensions.Should().Contain(".bmp");
        extensions.Should().Contain(".gif");
    }
}

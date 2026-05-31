using Microsoft.Extensions.Logging;

namespace MedVault.DocIntelligence.Parsing;

/// <summary>
/// Resolves the correct <see cref="IDocumentParser"/> based on content type or file extension.
/// </summary>
public sealed class DocumentParserFactory
{
    private readonly IEnumerable<IDocumentParser> _parsers;
    private readonly ILogger<DocumentParserFactory> _logger;

    /// <summary>
    /// Maps file extensions to MIME content types for auto-detection.
    /// </summary>
    private static readonly Dictionary<string, string> ExtensionToContentType = new(StringComparer.OrdinalIgnoreCase)
    {
        [".pdf"] = "application/pdf",
        [".jpg"] = "image/jpeg",
        [".jpeg"] = "image/jpeg",
        [".png"] = "image/png",
        [".tiff"] = "image/tiff",
        [".tif"] = "image/tiff",
        [".bmp"] = "image/bmp",
        [".gif"] = "image/gif"
    };

    public DocumentParserFactory(IEnumerable<IDocumentParser> parsers, ILogger<DocumentParserFactory> logger)
    {
        _parsers = parsers;
        _logger = logger;
    }

    /// <summary>
    /// Gets the appropriate parser for a given content type.
    /// </summary>
    public IDocumentParser GetParser(string contentType)
    {
        var parser = _parsers.FirstOrDefault(p =>
            p.SupportedContentTypes.Contains(contentType, StringComparer.OrdinalIgnoreCase));

        if (parser is null)
        {
            _logger.LogError("No parser found for content type: {ContentType}", contentType);
            throw new NotSupportedException($"No document parser available for content type: {contentType}");
        }

        _logger.LogDebug("Resolved parser {ParserType} for content type {ContentType}",
            parser.GetType().Name, contentType);

        return parser;
    }

    /// <summary>
    /// Resolves content type from a file name's extension.
    /// Returns the provided <paramref name="contentType"/> if not null,
    /// otherwise infers from the file extension.
    /// </summary>
    public string ResolveContentType(string fileName, string? contentType)
    {
        if (!string.IsNullOrWhiteSpace(contentType))
            return contentType;

        var extension = Path.GetExtension(fileName);
        if (string.IsNullOrWhiteSpace(extension))
            throw new ArgumentException($"Cannot determine content type for file without extension: {fileName}");

        if (ExtensionToContentType.TryGetValue(extension, out var resolved))
            return resolved;

        throw new NotSupportedException($"Unsupported file extension: {extension}");
    }

    /// <summary>
    /// Gets all supported file extensions.
    /// </summary>
    public static IReadOnlyCollection<string> SupportedExtensions => ExtensionToContentType.Keys.ToList().AsReadOnly();
}

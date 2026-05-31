namespace MedVault.DocIntelligence.Configuration;

/// <summary>
/// Root configuration options for MedVault DocIntelligence.
/// Bind to the "DocIntelligence" section in configuration.
/// </summary>
public sealed class DocIntelligenceOptions
{
    /// <summary>
    /// Configuration section name.
    /// </summary>
    public const string SectionName = "DocIntelligence";

    /// <summary>
    /// AI provider configuration.
    /// </summary>
    public AiProviderOptions AiProvider { get; set; } = new();

    /// <summary>
    /// OCR / Tesseract configuration.
    /// </summary>
    public OcrOptions Ocr { get; set; } = new();

}

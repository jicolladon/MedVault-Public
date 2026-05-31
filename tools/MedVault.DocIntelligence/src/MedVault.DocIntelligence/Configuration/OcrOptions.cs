namespace MedVault.DocIntelligence.Configuration;

/// <summary>
/// Configuration for Tesseract OCR.
/// </summary>
public sealed class OcrOptions
{
    /// <summary>
    /// Path to the tessdata directory containing trained language data files.
    /// If relative, resolved from the application base directory.
    /// </summary>
    public string TesseractDataPath { get; set; } = "./tessdata";

    /// <summary>
    /// Tesseract language(s) to use (e.g. "eng", "spa", "eng+spa").
    /// </summary>
    public string Language { get; set; } = "eng";
}

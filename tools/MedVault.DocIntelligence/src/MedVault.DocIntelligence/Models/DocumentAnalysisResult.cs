using System.Text.Json.Serialization;

namespace MedVault.DocIntelligence.Models;

/// <summary>
/// The complete result of analyzing a medical document.
/// Contains classification, summary, structured fields, and metadata.
/// </summary>
public sealed class DocumentAnalysisResult
{
    [JsonPropertyName("aiResponse")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? AiResponse { get; set; }

    [JsonPropertyName("errorMessage")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? ErrorMessage { get; set; }

    [JsonPropertyName("jsonStringResult")]
    public object? JsonStringResult { get; set; }

    /// <summary>
    /// The raw text that was extracted from the document before AI analysis.
    /// </summary>
    [JsonPropertyName("rawText")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? RawText { get; set; }

    /// <summary>
    /// AI confidence score for the analysis (0.0 to 1.0).
    /// </summary>
    [JsonPropertyName("confidence")]
    public float Confidence { get; set; }

    /// <summary>
    /// Additional notes or warnings from the AI analysis.
    /// </summary>
    [JsonPropertyName("notes")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? Notes { get; set; }
}

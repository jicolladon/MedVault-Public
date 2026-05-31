using System.Text.Json.Serialization;

namespace MedVault.DocIntelligence.Models;

/// <summary>
/// Represents a single extracted key-value field from a medical document.
/// For lab results this might be a test name with its value, unit, and reference range.
/// For diagnoses this might be a structured piece of clinical information.
/// </summary>
public sealed class ExtractedField
{
    /// <summary>
    /// The field name / key (e.g. "Hemoglobin", "Glucose", "Diagnosis", "DoctorName").
    /// </summary>
    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// The extracted value (e.g. "14.2", "Normal", "Type 2 Diabetes").
    /// </summary>
    [JsonPropertyName("value")]
    public string Value { get; set; } = string.Empty;

    /// <summary>
    /// Optional measurement unit (e.g. "g/dL", "mg/dL", "mmol/L").
    /// </summary>
    [JsonPropertyName("unit")]
    public string? Unit { get; set; }

    /// <summary>
    /// Optional reference range for lab values (e.g. "12.0-17.5", "70-100").
    /// </summary>
    [JsonPropertyName("referenceRange")]
    public string? ReferenceRange { get; set; }

    /// <summary>
    /// Optional minimum value for lab reference ranges (e.g. "12.0").
    /// </summary>
    [JsonPropertyName("minRange")]
    public string? MinRange { get; set; }

    /// <summary>
    /// Optional maximum value for lab reference ranges (e.g. "17.5").
    /// </summary>
    [JsonPropertyName("maxRange")]
    public string? MaxRange { get; set; }

    /// <summary>
    /// Optional category grouping (e.g. "Hematology", "Biochemistry", "Metadata").
    /// </summary>
    [JsonPropertyName("category")]
    public string? Category { get; set; }

    /// <summary>
    /// Whether this value is flagged as abnormal / out of range.
    /// </summary>
    [JsonPropertyName("isAbnormal")]
    public bool? IsAbnormal { get; set; }
}

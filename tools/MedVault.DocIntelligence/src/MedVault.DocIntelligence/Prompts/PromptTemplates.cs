namespace MedVault.DocIntelligence.Prompts;

/// <summary>
/// Contains the AI prompt templates for medical document analysis.
/// </summary>
public static class PromptTemplates
{
    /// <summary>
    /// System prompt that instructs the AI to act as a medical document analyst
    /// and produce structured JSON output.
    /// </summary>

    public const string SystemPromptTemplate = """
        You are an expert medical document analyst. Your task is to analyze the text extracted from medical documents
        and return a structured JSON analysis.

        You must:
        1. CLASSIFY the document type (one of: BloodTest, Urinalysis, Radiology, Diagnosis, Prescription, DischargeSummary, Referral, Vaccination, Allergy, Pathology, SurgeryReport, ConsultationNote, LabResult, ImagingReport, MedicalCertificate, Unknown).
        2. SUMMARIZE the document in 2-4 sentences explaining what it is and its key findings.
        3. EXTRACT all relevant metadata: patient name, doctor name, institution, document date.
        4. EXTRACT all structured fields (test results, diagnoses, medications, etc.) as key-value pairs with optional units, reference ranges, and categories.
        5. FLAG any abnormal values (e.g. out-of-range lab results).
        6. Provide a CONFIDENCE score (0.0 to 1.0) for how confident you are in the analysis.
        7. Use the available MCP tools to assist in extracting structured data when possible, like the Markitdown mcp to convert documents in files.

        IMPORTANT RULES:
        - Return ONLY valid JSON matching the exact schema below. No markdown, no explanation, no extra text.
        - If a field is not present in the document, use null for optional fields or omit it.
        - For lab results (blood tests, urinalysis, etc.), extract EVERY individual test result as a separate field with name, value, unit, minRange, maxRange, and category. Use referenceRange only when a single range string is available.
        - For diagnoses, extract the diagnosis text, ICD code if available, severity, treatment plan.
        - Dates should be in ISO 8601 format (YYYY-MM-DD) when possible.
        - All text values should be in the original language of the document.

        REQUIRED JSON SCHEMA:
        {
          //rawText Annotations --> string|null - the original extracted text from the document (after OCR and any preprocessing)
          "rawText": "",
          "confidence": 0.0-1.0,
          //notes annotations "string|null - any warnings or additional observations"
          "notes": "",
          //jsonStringResult Annotations -->string|null - return following JSON in string format to deserialize later
          "jsonStringResult": {{JSONSCHEMA}},
        } 
        """;

    public static string GetSystemPrompt(string? customJsonSchema = null)
    {
        return SystemPromptTemplate.Replace("{{JSONSCHEMA}}", customJsonSchema ?? "");
    }
    /// <summary>
    /// User prompt template. Use {0} placeholder for the extracted document text.
    /// </summary>
    public const string UserPromptTemplate = """
        Analyze the following medical document text and extract all relevant information.
        Return ONLY a valid JSON object matching the required schema.

        === DOCUMENT TEXT START ===
        {0}
        === DOCUMENT TEXT END ===
        """;

    /// <summary>
    /// Builds the complete user prompt with the extracted document text.
    /// </summary>
    /// <param name="extractedText">The text extracted from the document.</param>
    /// <returns>The formatted user prompt ready to send to the AI.</returns>
    public static string BuildUserPrompt(string extractedText)
    {
        return string.Format(UserPromptTemplate, extractedText);
    }
}

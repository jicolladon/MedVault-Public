using FluentAssertions;
using MedVault.DocIntelligence.Prompts;

namespace MedVault.DocIntelligence.Tests.Prompts;

public class PromptTemplatesTests
{
    [Fact]
    public void SystemPrompt_IsNotEmpty()
    {
        PromptTemplates.SystemPrompt.Should().NotBeNullOrWhiteSpace();
    }

    [Fact]
    public void SystemPrompt_ContainsJsonSchemaDescription()
    {
        PromptTemplates.SystemPrompt.Should().Contain("documentType");
        PromptTemplates.SystemPrompt.Should().Contain("summary");
        PromptTemplates.SystemPrompt.Should().Contain("fields");
        PromptTemplates.SystemPrompt.Should().Contain("confidence");
    }

    [Fact]
    public void SystemPrompt_ContainsAllDocumentTypes()
    {
        PromptTemplates.SystemPrompt.Should().Contain("BloodTest");
        PromptTemplates.SystemPrompt.Should().Contain("Diagnosis");
        PromptTemplates.SystemPrompt.Should().Contain("Prescription");
        PromptTemplates.SystemPrompt.Should().Contain("Radiology");
        PromptTemplates.SystemPrompt.Should().Contain("LabResult");
    }

    [Fact]
    public void SystemPrompt_InstructsJsonOnlyResponse()
    {
        PromptTemplates.SystemPrompt.Should().Contain("ONLY valid JSON");
    }

    [Fact]
    public void UserPromptTemplate_ContainsPlaceholder()
    {
        PromptTemplates.UserPromptTemplate.Should().Contain("{0}");
    }

    [Fact]
    public void BuildUserPrompt_InsertsExtractedText()
    {
        var extractedText = "Patient: Jane Doe\nHemoglobin: 13.5 g/dL";

        var result = PromptTemplates.BuildUserPrompt(extractedText);

        result.Should().Contain(extractedText);
        result.Should().Contain("DOCUMENT TEXT START");
        result.Should().Contain("DOCUMENT TEXT END");
    }

    [Fact]
    public void BuildUserPrompt_WithEmptyText_StillBuildsPrompt()
    {
        var result = PromptTemplates.BuildUserPrompt(string.Empty);

        result.Should().Contain("DOCUMENT TEXT START");
        result.Should().Contain("DOCUMENT TEXT END");
    }

    [Fact]
    public void BuildUserPrompt_WithSpecialCharacters_PreservesText()
    {
        var textWithSpecials = "Resultado: Glucosa → 95 mg/dL\nRango: 70–100 mg/dL\nPaciente: José García";

        var result = PromptTemplates.BuildUserPrompt(textWithSpecials);

        result.Should().Contain("José García");
        result.Should().Contain("95 mg/dL");
    }
}

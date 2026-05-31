using FluentAssertions;
using MedVault.DocIntelligence.Configuration;

namespace MedVault.DocIntelligence.Tests.Configuration;

public class ConfigurationTests
{
    [Fact]
    public void DocIntelligenceOptions_HasCorrectSectionName()
    {
        DocIntelligenceOptions.SectionName.Should().Be("DocIntelligence");
    }

    [Fact]
    public void DocIntelligenceOptions_DefaultValues_AreReasonable()
    {
        var options = new DocIntelligenceOptions();

        options.AiProvider.Should().NotBeNull();
        options.Ocr.Should().NotBeNull();
        options.Prompts.Should().NotBeNull();
    }

    [Fact]
    public void AiProviderOptions_DefaultValues_AreReasonable()
    {
        var options = new AiProviderOptions();

        options.Provider.Should().Be(AiProviderType.OpenAI);
        options.ModelId.Should().Be("gpt-4o");
        options.Temperature.Should().BeInRange(0f, 1f);
        options.MaxTokens.Should().BeGreaterThan(0);
    }

    [Fact]
    public void OcrOptions_DefaultValues_AreReasonable()
    {
        var options = new OcrOptions();

        options.TesseractDataPath.Should().NotBeNullOrWhiteSpace();
        options.Language.Should().Be("eng");
    }

    [Fact]
    public void PromptOptions_DefaultValues_AreReasonable()
    {
        var options = new PromptOptions();

        options.SystemPrompt.Should().NotBeNullOrWhiteSpace();
        options.UserPromptTemplate.Should().NotBeNullOrWhiteSpace();
    }

    [Theory]
    [InlineData(AiProviderType.OpenAI)]
    [InlineData(AiProviderType.AzureOpenAI)]
    [InlineData(AiProviderType.Ollama)]
    public void AiProviderType_HasExpectedValues(AiProviderType providerType)
    {
        Enum.IsDefined(providerType).Should().BeTrue();
    }
}

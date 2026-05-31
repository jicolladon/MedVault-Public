using Azure.AI.OpenAI;
using MedVault.DocIntelligence.Analysis;
using MedVault.DocIntelligence.Configuration;
using MedVault.DocIntelligence.Parsing;
using Microsoft.Extensions.AI;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using OpenAI;
using OpenAI.Chat;
using System.ClientModel;

namespace MedVault.DocIntelligence.Extensions;

/// <summary>
/// Extension methods for registering MedVault DocIntelligence services.
/// </summary>
public static class ServiceCollectionExtensions
{
    /// <summary>
    /// Registers all MedVault DocIntelligence services including document parsers,
    /// AI provider, and the medical document analyzer.
    /// </summary>
    /// <param name="services">The service collection.</param>
    /// <param name="configuration">Application configuration (reads "DocIntelligence" section).</param>
    /// <returns>The service collection for chaining.</returns>
    public static IServiceCollection AddDocIntelligence(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        // Bind configuration
        var section = configuration.GetSection(DocIntelligenceOptions.SectionName);
        services.Configure<DocIntelligenceOptions>(section);
        services.Configure<AiProviderOptions>(section.GetSection(nameof(DocIntelligenceOptions.AiProvider)));
        services.Configure<OcrOptions>(section.GetSection(nameof(DocIntelligenceOptions.Ocr)));

        // Register document parsers
        services.AddSingleton<ImageDocumentParser>();
        services.AddSingleton<PdfDocumentParser>();
        services.AddSingleton<IDocumentParser>(sp => sp.GetRequiredService<PdfDocumentParser>());
        services.AddSingleton<IDocumentParser>(sp => sp.GetRequiredService<ImageDocumentParser>());
        services.AddSingleton<DocumentParserFactory>();

        // Register chat client with the configured AI provider
        services.AddSingleton<IChatClient>(sp =>
        {
            var options = sp.GetRequiredService<IOptions<AiProviderOptions>>().Value;
            return CreateChatClient(options);
        });

        // Register AI provider and analyzer
        services.AddSingleton<IAiProvider, AgentFrameworkAiProvider>();
        services.AddSingleton<IMedicalDocumentAnalyzer, MedicalDocumentAnalyzer>();
        services.AddSingleton<IOcrService, InMemoryOcrService>();
        return services;
    }

    /// <summary>
    /// Creates a chat client configured for the specified AI provider.
    /// </summary>
    private static IChatClient CreateChatClient(AiProviderOptions options)
    {
        switch (options.Provider)
        {
            case AiProviderType.OpenAI:
                ValidateRequired(options.ApiKey, "ApiKey is required for Azure OpenAI provider.");
                ValidateRequired(options.Endpoint, "Endpoint is required for Azure OpenAI provider.");
                ValidateRequired(options.ModelId, "ModelId is required for Azure OpenAI provider.");
                return new ChatClient(
                    options.ModelId,
                    new ApiKeyCredential(options.ApiKey!),
                    new OpenAIClientOptions { Endpoint = new Uri(options.Endpoint!) }
                ).AsIChatClient();

            case AiProviderType.AzureOpenAI:
                ValidateRequired(options.ApiKey, "ApiKey is required for Azure OpenAI provider.");
                ValidateRequired(options.Endpoint, "Endpoint is required for Azure OpenAI provider.");
                ValidateRequired(options.DeploymentName, "DeploymentName is required for Azure OpenAI provider.");
                return new AzureOpenAIClient(
                    new Uri(options.Endpoint!),
                    new ApiKeyCredential(options.ApiKey!)
                ).GetChatClient(options.DeploymentName!)
                 .AsIChatClient();

            case AiProviderType.Ollama:
                ValidateRequired(options.Endpoint, "Endpoint is required for Ollama provider.");
                return new OllamaChatClient(
                    new Uri(options.Endpoint!),
                    modelId: options.ModelId);

            default:
                throw new InvalidOperationException($"Unsupported AI provider type: {options.Provider}");
        }
    }

    private static void ValidateRequired(string? value, string errorMessage)
    {
        if (string.IsNullOrWhiteSpace(value))
            throw new InvalidOperationException(errorMessage);
    }
}

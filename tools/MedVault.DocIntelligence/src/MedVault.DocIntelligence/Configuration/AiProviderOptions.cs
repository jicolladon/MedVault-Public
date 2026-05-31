namespace MedVault.DocIntelligence.Configuration;

/// <summary>
/// Configuration for the AI provider.
/// </summary>
public sealed class AiProviderOptions
{
    /// <summary>
    /// Which AI provider to use.
    /// </summary>
    public AiProviderType Provider { get; set; } = AiProviderType.OpenAI;

    /// <summary>
    /// The model identifier (e.g. "gpt-4o", "llama3.1", "gpt-4").
    /// </summary>
    public string ModelId { get; set; } = "gpt-4o";

    /// <summary>
    /// API key for OpenAI or Azure OpenAI. Not needed for Ollama.
    /// </summary>
    public string? ApiKey { get; set; }

    /// <summary>
    /// Endpoint URL. Required for Azure OpenAI and Ollama.
    /// For Ollama, typically "http://localhost:11434".
    /// For Azure OpenAI, the resource endpoint (e.g. "https://your-resource.openai.azure.com").
    /// </summary>
    public string? Endpoint { get; set; }

    /// <summary>
    /// Azure OpenAI deployment name. Only used with <see cref="AiProviderType.AzureOpenAI"/>.
    /// </summary>
    public string? DeploymentName { get; set; }

    /// <summary>
    /// Temperature for AI responses (0.0 = deterministic, 1.0 = creative).
    /// Lower is better for structured data extraction.
    /// </summary>
    public float Temperature { get; set; } = 0.1f;

    /// <summary>
    /// Maximum tokens in the AI response.
    /// </summary>
    public int MaxTokens { get; set; } = 44096;
}

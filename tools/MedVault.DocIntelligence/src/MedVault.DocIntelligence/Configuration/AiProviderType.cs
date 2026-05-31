namespace MedVault.DocIntelligence.Configuration;

/// <summary>
/// Supported AI provider types.
/// </summary>
public enum AiProviderType
{
    /// <summary>
    /// OpenAI API (api.openai.com) — GPT-4o, GPT-4, GPT-3.5 etc.
    /// </summary>
    OpenAI = 0,

    /// <summary>
    /// Azure OpenAI Service — deployed models in Azure.
    /// </summary>
    AzureOpenAI,

    /// <summary>
    /// Ollama — local/self-hosted open-source models (Llama, Mistral, etc.).
    /// </summary>
    Ollama
}

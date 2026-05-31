namespace MedVault.DocIntelligence.Analysis;

/// <summary>
/// Abstraction over AI chat completion providers.
/// Enables easy mocking in tests and provider swapping.
/// </summary>
public interface IAiProvider
{
    /// <summary>
    /// Sends a system prompt and user message to the AI and returns the response text.
    /// </summary>
    /// <param name="systemPrompt">The system/instruction prompt.</param>
    /// <param name="userMessage">The user message containing the document text.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The AI's text response (expected to be JSON).</returns>
    Task<string> GetCompletionAsync(string systemPrompt, string userMessage, CancellationToken cancellationToken = default);
    Task<string> GetCompletitionAsync(string systemPrompt,
       string userPrompt, List<(Stream, string)> files, CancellationToken cancellationToken);
}

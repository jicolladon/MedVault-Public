using DocumentFormat.OpenXml.Packaging;
using MedVault.DocIntelligence.Configuration;
using Microsoft.Agents.AI;
using Microsoft.Extensions.AI;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using System.Diagnostics;
using System.Text;
using System.Text.Json;
using UglyToad.PdfPig;

namespace MedVault.DocIntelligence.Analysis;

/// <summary>
/// AI provider implementation using Microsoft Agent Framework.
/// Supports OpenAI, Azure OpenAI, and Ollama through chat clients.
/// </summary>
public sealed class AgentFrameworkAiProvider : IAiProvider
{
    private readonly IChatClient _chatClient;
    private readonly AiProviderOptions _options;
    private readonly ILogger<AgentFrameworkAiProvider> _logger;
    private readonly IOcrService _ocrService;

    public AgentFrameworkAiProvider(IChatClient chatClient,
        IOcrService ocrService,
        IOptions<AiProviderOptions> options,
        ILogger<AgentFrameworkAiProvider> logger)
    {
        _chatClient = chatClient;
        _options = options.Value;
        _logger = logger;
        _ocrService = ocrService;
    }

    public async Task<string> GetCompletitionAsync(string systemPrompt,
        string userPrompt, List<(Stream, string)> files, CancellationToken cancellationToken)
    {
        //files are files like pdf, docs, images, txt that must be attached to the agent context, because they are the source to extract the information
        _logger.LogInformation("Sending request to AI provider {Provider} with model {ModelId} and {FileCount} attached files...",
            _options.Provider, _options.ModelId, files.Count);

        var agent = _chatClient.AsAIAgent(instructions: systemPrompt, name: "MedVaultDocIntelligenceAgent");

        var runOptions = new ChatClientAgentRunOptions(new ChatOptions
        {
            Temperature = _options.Temperature,
            MaxOutputTokens = _options.MaxTokens,
            ResponseFormat = Microsoft.Extensions.AI.ChatResponseFormat.Json
        });

        var chatMessages = new List<Microsoft.Extensions.AI.ChatMessage>
        {
        };

        foreach (var file in files)
        {
            var (stream, fileType) = file;
            var userMessage = await GetUserChatMessageAsync(stream, fileType);
            chatMessages.Add(userMessage);
        }

        var chatUserMessage = new ChatMessage(ChatRole.User, userPrompt);
        chatMessages.Add(chatUserMessage);

        var result = await agent.RunAsync(
            chatMessages,
            options: runOptions,
            cancellationToken: cancellationToken);

        return result.ToString();

    }

    private static ChatMessage ExtractPdfText(Stream stream)
    {
        using var pdf = PdfDocument.Open(stream);

        var sb = new StringBuilder();

        foreach (var page in pdf.GetPages().Take(3))
        {
            sb.AppendLine(page.Text);
        }

        return new ChatMessage(ChatRole.User, sb.ToString());
    }

    private static ChatMessage ExtractDocxText(Stream stream)
    {
        using var document =
            WordprocessingDocument.Open(stream, false);

        var body = document.MainDocumentPart?.Document.Body;

        return new ChatMessage(ChatRole.User, body?.InnerText ?? string.Empty);
    }

    private static async Task<ChatMessage> ExtractPlainText(Stream stream)
    {
        using var reader = new StreamReader(stream);

        return new ChatMessage(ChatRole.User, await reader.ReadToEndAsync());
    }

    public static async Task<ChatMessage> ExtractImage(Stream stream, string mediaType)
    {
        using var memory = new MemoryStream();
        await stream.CopyToAsync(memory);
        var imageBytes = memory.ToArray();
        var content = new DataContent(imageBytes, mediaType);
        return new ChatMessage(ChatRole.User, [content]);
    }

    public async Task<ChatMessage> GetUserChatMessageAsync(Stream content, string fileType)
    {
        if(content == null)
        {
            throw new ArgumentNullException(nameof(content));
        }
        switch (fileType.ToLowerInvariant())
        {
            case ".pdf":
                return ExtractPdfText(content);
            case ".doc":
            case ".docx":
                return ExtractDocxText(content);           
            case ".txt":
                return await ExtractPlainText(content);
            case ".jpg":
            case ".jpeg":
            case ".png":
                return await ExtractImage(content, fileType);
            default:
                throw new NotSupportedException($"File type '{fileType}' is not supported.");
        }
    }
    public async Task<string> GetCompletionAsync(string systemPrompt, string userMessage, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Sending request to AI provider {Provider} with model {ModelId}...",
            _options.Provider, _options.ModelId);

        //var normalizedUserMessage = await TryConvertToMarkdownWithMarkItDownMcpAsync(userMessage, cancellationToken);
        var agent = _chatClient.AsAIAgent(instructions: systemPrompt, name: "MedVaultDocIntelligenceAgent");

        var runOptions = new ChatClientAgentRunOptions(new ChatOptions
        {
            Temperature = _options.Temperature,
            MaxOutputTokens = _options.MaxTokens,
            ResponseFormat = Microsoft.Extensions.AI.ChatResponseFormat.Json
        });

        var result = await agent.RunAsync(
            userMessage,
            options: runOptions,
            cancellationToken: cancellationToken);

        var responseText = result.Text ?? result.ToString() ?? string.Empty;

        _logger.LogInformation("AI response received ({CharCount} characters).", responseText.Length);
        _logger.LogDebug("AI raw response: {Response}", responseText);

        return responseText;
    }

    private async Task<string> TryConvertToMarkdownWithMarkItDownMcpAsync(string input, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(input))
        {
            return input;
        }

        // Opt-in to avoid changing current behavior unexpectedly.
        // Set MEDVAULT_ENABLE_MARKITDOWN_MCP=true to enable this preprocessing step.
        if (!bool.TryParse(Environment.GetEnvironmentVariable("MEDVAULT_ENABLE_MARKITDOWN_MCP"), out var enabled) || !enabled)
        {
            return input;
        }

        using var timeoutCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeoutCts.CancelAfter(TimeSpan.FromSeconds(15));

        var tempPath = Path.Combine(Path.GetTempPath(), $"medvault-markitdown-{Guid.NewGuid():N}.txt");

        try
        {
            await File.WriteAllTextAsync(tempPath, input, timeoutCts.Token);

            var startInfo = new ProcessStartInfo
            {
                FileName = "uvx",
                Arguments = "markitdown-mcp@0.0.1a4",
                RedirectStandardInput = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            using var process = Process.Start(startInfo);
            if (process is null)
            {
                _logger.LogWarning("Could not start markitdown MCP process. Falling back to original input.");
                return input;
            }

            var initialized = await InitializeMcpSessionAsync(process, timeoutCts.Token);
            if (!initialized)
            {
                _logger.LogWarning("MarkItDown MCP initialization failed. Falling back to original input.");
                return input;
            }

            var toolName = await ResolveToolNameAsync(process, timeoutCts.Token);
            if (string.IsNullOrWhiteSpace(toolName))
            {
                _logger.LogWarning("No usable tool found in markitdown MCP server. Falling back to original input.");
                return input;
            }

            var toolResult = await CallMcpToolAsync(process, toolName, tempPath, input, timeoutCts.Token);
            if (string.IsNullOrWhiteSpace(toolResult))
            {
                _logger.LogWarning("MarkItDown MCP returned empty output. Falling back to original input.");
                return input;
            }

            _logger.LogInformation("Input was normalized with microsoft/markitdown MCP ({Chars} chars).", toolResult.Length);
            return toolResult;
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("MarkItDown MCP conversion timed out. Falling back to original input.");
            return input;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "MarkItDown MCP conversion failed. Falling back to original input.");
            return input;
        }
        finally
        {
            try
            {
                if (File.Exists(tempPath))
                {
                    File.Delete(tempPath);
                }
            }
            catch
            {
                // Best-effort cleanup.
            }
        }
    }

    private static async Task<bool> InitializeMcpSessionAsync(Process process, CancellationToken cancellationToken)
    {
        const int initializeId = 1;
        var initializeRequest = JsonSerializer.Serialize(new
        {
            jsonrpc = "2.0",
            id = initializeId,
            method = "initialize",
            @params = new
            {
                protocolVersion = "2024-11-05",
                clientInfo = new { name = "MedVault.DocIntelligence", version = "1.0.0" },
                capabilities = new { }
            }
        });

        await process.StandardInput.WriteLineAsync(initializeRequest);
        var initializeResponse = await ReadJsonRpcResponseAsync(process, initializeId, cancellationToken);
        if (initializeResponse is null || initializeResponse.Value.TryGetProperty("error", out _))
        {
            return false;
        }

        var initializedNotification = JsonSerializer.Serialize(new
        {
            jsonrpc = "2.0",
            method = "notifications/initialized",
            @params = new { }
        });

        await process.StandardInput.WriteLineAsync(initializedNotification);
        await process.StandardInput.FlushAsync();

        return true;
    }

    private static async Task<string?> ResolveToolNameAsync(Process process, CancellationToken cancellationToken)
    {
        const int listToolsId = 2;
        var listToolsRequest = JsonSerializer.Serialize(new
        {
            jsonrpc = "2.0",
            id = listToolsId,
            method = "tools/list",
            @params = new { }
        });

        await process.StandardInput.WriteLineAsync(listToolsRequest);
        await process.StandardInput.FlushAsync();

        var listToolsResponse = await ReadJsonRpcResponseAsync(process, listToolsId, cancellationToken);
        if (listToolsResponse is null ||
            listToolsResponse.Value.TryGetProperty("error", out _) ||
            !listToolsResponse.Value.TryGetProperty("result", out var resultElement) ||
            !resultElement.TryGetProperty("tools", out var toolsElement) ||
            toolsElement.ValueKind != JsonValueKind.Array)
        {
            return null;
        }

        string? fallback = null;

        foreach (var tool in toolsElement.EnumerateArray())
        {
            if (!tool.TryGetProperty("name", out var nameElement) || nameElement.ValueKind != JsonValueKind.String)
            {
                continue;
            }

            var name = nameElement.GetString();
            if (string.IsNullOrWhiteSpace(name))
            {
                continue;
            }

            fallback ??= name;

            if (name.Contains("markdown", StringComparison.OrdinalIgnoreCase) ||
                name.Contains("convert", StringComparison.OrdinalIgnoreCase) ||
                name.Contains("markitdown", StringComparison.OrdinalIgnoreCase))
            {
                return name;
            }
        }

        return fallback;
    }

    private static async Task<string?> CallMcpToolAsync(
        Process process,
        string toolName,
        string tempPath,
        string originalInput,
        CancellationToken cancellationToken)
    {
        const int callToolId = 3;

        var callRequest = JsonSerializer.Serialize(new
        {
            jsonrpc = "2.0",
            id = callToolId,
            method = "tools/call",
            @params = new
            {
                name = toolName,
                arguments = new
                {
                    path = tempPath,
                    filePath = tempPath,
                    input = originalInput,
                    text = originalInput,
                    content = originalInput
                }
            }
        });

        await process.StandardInput.WriteLineAsync(callRequest);
        await process.StandardInput.FlushAsync();

        var response = await ReadJsonRpcResponseAsync(process, callToolId, cancellationToken);
        if (response is null || response.Value.TryGetProperty("error", out _))
        {
            return null;
        }

        if (!response.Value.TryGetProperty("result", out var resultElement))
        {
            return null;
        }

        if (resultElement.TryGetProperty("content", out var contentElement) && contentElement.ValueKind == JsonValueKind.Array)
        {
            foreach (var content in contentElement.EnumerateArray())
            {
                if (content.TryGetProperty("text", out var textElement) && textElement.ValueKind == JsonValueKind.String)
                {
                    var value = textElement.GetString();
                    if (!string.IsNullOrWhiteSpace(value))
                    {
                        return value;
                    }
                }
            }
        }

        if (resultElement.TryGetProperty("structuredContent", out var structuredContent) && structuredContent.ValueKind == JsonValueKind.String)
        {
            return structuredContent.GetString();
        }

        return resultElement.ToString();
    }

    private static async Task<JsonElement?> ReadJsonRpcResponseAsync(Process process, int expectedId, CancellationToken cancellationToken)
    {
        while (!cancellationToken.IsCancellationRequested)
        {
            var line = await process.StandardOutput.ReadLineAsync().WaitAsync(cancellationToken);
            if (string.IsNullOrWhiteSpace(line))
            {
                if (process.HasExited)
                {
                    return null;
                }

                continue;
            }

            JsonDocument document;
            try
            {
                document = JsonDocument.Parse(line);
            }
            catch
            {
                continue;
            }

            using (document)
            {
                var root = document.RootElement;
                if (!root.TryGetProperty("id", out var idElement))
                {
                    continue;
                }

                if (idElement.ValueKind == JsonValueKind.Number && idElement.TryGetInt32(out var numericId) && numericId == expectedId)
                {
                    return root.Clone();
                }

                if (idElement.ValueKind == JsonValueKind.String &&
                    int.TryParse(idElement.GetString(), out var textId) &&
                    textId == expectedId)
                {
                    return root.Clone();
                }
            }
        }

        return null;
    }
}

using System.Text.Json;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using MedVault.DocIntelligence.Analysis;
using MedVault.DocIntelligence.Extensions;
using MedVault.DocIntelligence.Models;

namespace MedVault.DocIntelligence.Console;

/// <summary>
/// Console application for testing MedVault DocIntelligence document analysis.
/// Usage: dotnet run -- "path/to/medical-document.pdf"
/// </summary>
public static class Program
{
    private static readonly JsonSerializerOptions PrintOptions = new()
    {
        WriteIndented = true,
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull
    };

    public static async Task<int> Main(string[] args)
    {
        if (args.Length == 0 || args[0] is "--help" or "-h")
        {
            PrintUsage();
            return args.Length == 0 ? 1 : 0;
        }

        var filePath = args[0];
        var includeRawText = args.Contains("--raw");

        if (!File.Exists(filePath))
        {
            System.Console.Error.WriteLine($"Error: File not found: {filePath}");
            return 1;
        }

        try
        {
            // Build host with DI and configuration
            var host = Host.CreateDefaultBuilder(args)
                .ConfigureServices((context, services) =>
                {
                    services.AddDocIntelligence(context.Configuration);
                })
                .ConfigureLogging(logging =>
                {
                    logging.SetMinimumLevel(
                        args.Contains("--verbose") ? LogLevel.Debug : LogLevel.Warning);
                })
                .Build();

            var analyzer = host.Services.GetRequiredService<IMedicalDocumentAnalyzer>();

            System.Console.WriteLine($"Analyzing: {Path.GetFileName(filePath)}");
            System.Console.WriteLine(new string('─', 60));

            // Open file and analyze
            await using var fileStream = File.OpenRead(filePath);
            var request = new AnalysisRequest
            {
                FileContent = fileStream,
                FileName = Path.GetFileName(filePath),
                IncludeRawText = includeRawText
            };

            var result = await analyzer.AnalyzeAsync(request);

            // Print result as formatted JSON
            var json = JsonSerializer.Serialize(result, PrintOptions);
            System.Console.WriteLine(json);

            System.Console.WriteLine(new string('─', 60));
            System.Console.WriteLine($"Document Type: {result.DocumentType}");
            System.Console.WriteLine($"Confidence:    {result.Confidence:P0}");
            System.Console.WriteLine($"Fields:        {result.Fields.Count}");

            return 0;
        }
        catch (Exception ex)
        {
            System.Console.Error.WriteLine($"Error: {ex.Message}");
            if (args.Contains("--verbose"))
                System.Console.Error.WriteLine(ex.ToString());
            return 2;
        }
    }

    private static void PrintUsage()
    {
        System.Console.WriteLine("""
            MedVault DocIntelligence - Medical Document Analyzer
            ====================================================

            Usage:
              MedVault.DocIntelligence.Console <file-path> [options]

            Arguments:
              <file-path>    Path to the medical document (PDF, JPEG, PNG, TIFF, BMP)

            Options:
              --raw          Include raw extracted text in the output
              --verbose      Enable detailed logging output
              --help, -h     Show this help message

            Examples:
              dotnet run -- "./samples/blood-test.pdf"
              dotnet run -- "./samples/diagnosis.jpg" --raw --verbose

            Configuration:
              Configure AI provider in appsettings.json or appsettings.Development.json.
              See README.md for detailed setup instructions for each provider.
            """);
    }
}

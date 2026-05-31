# MedVault.DocIntelligence

AI-powered medical document analyzer that extracts structured metadata from medical documents (PDFs, images) using Microsoft Agent Framework.

## Architecture

```
MedVault.DocIntelligence/
├── src/
│   ├── MedVault.DocIntelligence/          # Core library
│   │   ├── Analysis/                      # AI orchestration (IMedicalDocumentAnalyzer, IAiProvider)
│   │   ├── Configuration/                 # Options pattern (AI provider, OCR settings)
│   │   ├── Extensions/                    # DI registration (AddDocIntelligence)
│   │   ├── Models/                        # Domain models (DocumentAnalysisResult, ExtractedField)
│   │   ├── Parsing/                       # Document parsers (PDF via PdfPig, Images via Tesseract OCR)
│   │   └── Prompts/                       # AI prompt templates
│   └── MedVault.DocIntelligence.Console/  # CLI test application
└── tests/
    └── MedVault.DocIntelligence.Tests/    # Unit tests (xUnit + Moq + FluentAssertions)
```

### Processing Flow

```
Document (PDF/Image) → Parser (PdfPig/Tesseract) → Extracted Text → AI Prompt → Agent Framework → Structured JSON
```

1. **Parsing**: PdfPig extracts text from PDFs; Tesseract OCR handles scanned PDFs and images
2. **Prompt**: System prompt instructs the AI to classify, summarize, and extract structured fields
3. **AI Analysis**: Agent Framework sends the prompt to the configured provider (OpenAI, Azure OpenAI, or Ollama)
4. **Result**: AI response is deserialized into `DocumentAnalysisResult` with typed fields

## Supported File Types

| Extension    | Content Type    | Parser                  |
| ------------ | --------------- | ----------------------- |
| `.pdf`       | application/pdf | PdfPig (+ OCR fallback) |
| `.jpg/.jpeg` | image/jpeg      | Tesseract OCR           |
| `.png`       | image/png       | Tesseract OCR           |
| `.tiff/.tif` | image/tiff      | Tesseract OCR           |
| `.bmp`       | image/bmp       | Tesseract OCR           |
| `.gif`       | image/gif       | Tesseract OCR           |

## AI Provider Configuration

Configure the provider in `appsettings.json` under the `DocIntelligence` section:

### OpenAI

```json
{
  "DocIntelligence": {
    "AiProvider": {
      "Provider": "OpenAI",
      "ModelId": "gpt-4o",
      "ApiKey": "sk-your-api-key-here",
      "Temperature": 0.1,
      "MaxTokens": 4096
    }
  }
}
```

### Azure OpenAI

```json
{
  "DocIntelligence": {
    "AiProvider": {
      "Provider": "AzureOpenAI",
      "ModelId": "gpt-4o",
      "ApiKey": "your-azure-api-key",
      "Endpoint": "https://your-resource.openai.azure.com",
      "DeploymentName": "gpt-4o-deployment",
      "Temperature": 0.1,
      "MaxTokens": 4096
    }
  }
}
```

### Ollama (Local)

```json
{
  "DocIntelligence": {
    "AiProvider": {
      "Provider": "Ollama",
      "ModelId": "llama3.2",
      "Endpoint": "http://localhost:11434",
      "Temperature": 0.1,
      "MaxTokens": 4096
    }
  }
}
```

> **Note**: For Ollama, install and run [Ollama](https://ollama.com) locally, then pull a model:
>
> ```bash
> ollama pull llama3.2
> ```

### OCR Configuration (Optional)

For image/scanned PDF processing, Tesseract OCR requires trained data files:

```json
{
  "DocIntelligence": {
    "Ocr": {
      "TesseractDataPath": "./tessdata",
      "Language": "eng"
    }
  }
}
```

Download tessdata from: https://github.com/tesseract-ocr/tessdata

## Getting Started

### Prerequisites

- .NET 10 SDK
- An AI provider (OpenAI API key, Azure OpenAI deployment, or Ollama running locally)
- (Optional) Tesseract tessdata files for OCR

### Build

```bash
cd tools/MedVault.DocIntelligence
dotnet build
```

### Run Tests

```bash
dotnet test
```

### Run Console App

```bash
# Analyze a PDF
dotnet run --project src/MedVault.DocIntelligence.Console -- "path/to/blood-test.pdf"

# With raw text output and verbose logging
dotnet run --project src/MedVault.DocIntelligence.Console -- "path/to/document.pdf" --raw --verbose

# Show help
dotnet run --project src/MedVault.DocIntelligence.Console -- --help
```

## Example Output

```json
{
  "documentType": "BloodTest",
  "summary": "Complete blood count (CBC) and basic metabolic panel for patient John Doe, performed on 2025-01-15 at City General Hospital. Most values are within normal range. Slightly elevated glucose noted.",
  "documentDate": "2025-01-15",
  "patientName": "John Doe",
  "doctorName": "Dr. Maria Garcia",
  "institution": "City General Hospital",
  "confidence": 0.95,
  "fields": [
    {
      "name": "Hemoglobin",
      "value": "14.2",
      "unit": "g/dL",
      "referenceRange": "12.0-17.5",
      "category": "Hematology",
      "isAbnormal": false
    },
    {
      "name": "White Blood Cells",
      "value": "7.5",
      "unit": "x10³/µL",
      "referenceRange": "4.5-11.0",
      "category": "Hematology",
      "isAbnormal": false
    },
    {
      "name": "Glucose",
      "value": "115",
      "unit": "mg/dL",
      "referenceRange": "70-100",
      "category": "Biochemistry",
      "isAbnormal": true
    },
    {
      "name": "Creatinine",
      "value": "1.0",
      "unit": "mg/dL",
      "referenceRange": "0.7-1.3",
      "category": "Biochemistry",
      "isAbnormal": false
    }
  ]
}
```

## Using the Library in Your Code

```csharp
// Register services
services.AddDocIntelligence(configuration);

// Inject and use
public class MyService(IMedicalDocumentAnalyzer analyzer)
{
    public async Task ProcessDocumentAsync(Stream fileStream, string fileName)
    {
        var request = new AnalysisRequest
        {
            FileContent = fileStream,
            FileName = fileName,
            IncludeRawText = false
        };

        var result = await analyzer.AnalyzeAsync(request);

        Console.WriteLine($"Type: {result.DocumentType}");
        Console.WriteLine($"Summary: {result.Summary}");

        foreach (var field in result.Fields)
        {
            Console.WriteLine($"  {field.Name}: {field.Value} {field.Unit}");
        }
    }
}
```

## Extending with New Providers

The `IAiProvider` interface allows adding custom AI providers:

```csharp
public class MyCustomProvider : IAiProvider
{
    public async Task<string> GetCompletionAsync(
        string systemPrompt, string userMessage, CancellationToken ct)
    {
        // Your custom AI call here
    }
}
```

Register it in DI:

```csharp
services.AddSingleton<IAiProvider, MyCustomProvider>();
```

## Tech Stack

| Component        | Technology                     |
| ---------------- | ------------------------------ |
| AI Orchestration | Microsoft Agent Framework      |
| PDF Parsing      | UglyToad.PdfPig                |
| OCR              | Tesseract (.NET wrapper)       |
| DI/Config        | Microsoft.Extensions.\*        |
| Testing          | xUnit + Moq + FluentAssertions |
| Target Framework | .NET 10                        |

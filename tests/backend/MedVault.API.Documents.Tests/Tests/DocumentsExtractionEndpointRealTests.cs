using System.Net;
using System.Net.Http.Json;
using System.Net.Http.Headers;
using MedVault.API.Common.Models;
using MedVault.API.Features.Documents.Application.DTOs;
using MedVault.API.Documents.Tests.Fixtures;
using Xunit;
using Newtonsoft.Json;

namespace MedVault.API.Documents.Tests.Tests;

public sealed class DocumentsExtractionEndpointRealTests : IClassFixture<MedVaultDocumentApiOllamaFactory>
{
    private readonly MedVaultDocumentApiOllamaFactory _factory;

    public DocumentsExtractionEndpointRealTests(MedVaultDocumentApiOllamaFactory factory)
    {
        _factory = factory;
    }

    [Theory]
    //[InlineData("en", new string[] { "Resources/sample-report.pdf" })]
    [InlineData("es", new string[] { "Resources/sinformes_CONA0860121002_20180322.pdf" })]
    [InlineData("es", new string[] { "Resources/informes_CONA0860121002_20201204.pdf" })]
    [InlineData("es", new string[] { "Resources/informes_CONA0860121002_20201219.pdf" })]
    [InlineData("es", new string[] { "Resources/informes_CONA0860121002_20210211.pdf" })]
    [InlineData("es", new string[] { "Resources/informes_CONA0860121002_20220307.pdf" })]
    [InlineData("es", new string[] { "Resources/informes_CONA0860121002_20230803.pdf" })]
    [InlineData("es", new string[] { "Resources/informes_CONA0860121002_20260114.pdf" })]
    [InlineData("es", new string[] { "Resources/justificant_immunitzacio_CONA0860121002_260509.pdf" })]

    public async Task Extract_WithValidMultipartRequest_ReturnsExtractionResult(string language, string[] filePaths)
    {
        using var client = _factory.CreateAuthenticatedClient();
        using var content = BuildExtractionContent(language, filePaths.ToList());

        var response = await client.PostAsync("/api/documents/extract", content);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var body = await response.Content.ReadAsStringAsync();
        var extractionResult = JsonConvert.DeserializeObject<ApiResponse<ExtractionResult>>(body, new JsonSerializerSettings()
        {
            NullValueHandling = NullValueHandling.Ignore,
            //Enum as string converter if needed
            Converters = new List<JsonConverter> {
                new Newtonsoft.Json.Converters.StringEnumConverter()
            }
        });

        Assert.NotNull(body);
        Assert.NotNull(extractionResult);
    }


    private static MultipartFormDataContent BuildExtractionContent(string preferredLanguage, List<string> filePaths)
    {
        var content = new MultipartFormDataContent();
        content.Add(new StringContent(preferredLanguage), "preferredLanguage");

        var attachedFiles = 0;
        foreach (var path in filePaths)
        {
            if (string.IsNullOrWhiteSpace(path) || !File.Exists(path))
            {
                continue;
            }

            var bytes = File.ReadAllBytes(path);
            var fileName = Path.GetFileName(path);
            var fileContent = new ByteArrayContent(bytes);
            fileContent.Headers.ContentType = new MediaTypeHeaderValue(ResolveMimeType(fileName));
            content.Add(fileContent, "files", fileName);
            attachedFiles += 1;
        }

        if (attachedFiles == 0)
        {
            var fallbackFile = new ByteArrayContent("fake-pdf-content"u8.ToArray());
            fallbackFile.Headers.ContentType = new MediaTypeHeaderValue("application/pdf");
            content.Add(fallbackFile, "files", "report.pdf");
        }

        return content;
    }

    private static string ResolveMimeType(string fileName)
    {
        var extension = Path.GetExtension(fileName).ToLowerInvariant();
        return extension switch
        {
            ".pdf" => "application/pdf",
            ".jpg" => "image/jpeg",
            ".jpeg" => "image/jpeg",
            ".png" => "image/png",
            ".docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            ".xlsx" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            ".txt" => "text/plain",
            _ => "application/octet-stream"
        };
    }
}

using System.Net;
using System.Net.Http.Json;
using System.Net.Http.Headers;
using MedVault.API.Common.Models;
using MedVault.API.Features.Documents.Application.DTOs;
using MedVault.API.Features.Documents.Application.Services;
using MedVault.API.Documents.Tests.Fixtures;
using Xunit;

namespace MedVault.API.Documents.Tests.Tests;

public sealed class DocumentsExtractionEndpointTests : IClassFixture<MedVaultDocumentApiFactory>
{
    // Add one or more absolute file paths here when you want to run with real documents.
    // Example:
    // private static readonly string[] RouteFilePaths =
    // [
    //     @"F:\\Projects\\healthId_passport\\tests\\assets\\sample1.pdf",
    //     @"F:\\Projects\\healthId_passport\\tests\\assets\\sample2.jpg"
    // ];
    private static readonly string[] RouteFilePaths = [];

    private readonly MedVaultDocumentApiFactory _factory;

    public DocumentsExtractionEndpointTests(MedVaultDocumentApiFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Extract_WithValidMultipartRequest_ReturnsExtractionResult()
    {
        _factory.StubPipeline.Handler = (_, _, _, _) => Task.FromResult(new ExtractionResult
        {
            IsMedical = true,
            DocumentType = "Lab Report",
            Date = new DateTime(2026, 4, 1, 0, 0, 0, DateTimeKind.Utc),
            IssuerName = "Test Lab",
            Metadata = new MedicalMetadata(),
            Summary = "Structured summary",
            Confidence = 0.92,
            RequiresUserConfirmation = true
        });

        using var client = _factory.CreateAuthenticatedClient();
        using var content = BuildExtractionContent("en");

        var response = await client.PostAsync("/api/documents/extract", content);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var body = await response.Content.ReadFromJsonAsync<ApiResponse<ExtractionResult>>();
        Assert.NotNull(body);
        Assert.True(body!.Success);
        Assert.NotNull(body.Data);
        Assert.True(body.Data!.RequiresUserConfirmation);
        Assert.Equal("Lab Report", body.Data.DocumentType);
    }

    [Fact]
    public async Task Extract_WithUnsupportedMimeType_Returns415()
    {
        using var client = _factory.CreateAuthenticatedClient();
        using var content = new MultipartFormDataContent();
        content.Add(new StringContent("en"), "preferredLanguage");

        var fileContent = new ByteArrayContent([1, 2, 3, 4]);
        fileContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue("application/octet-stream");
        content.Add(fileContent, "files", "payload.exe");

        var response = await client.PostAsync("/api/documents/extract", content);

        Assert.Equal(HttpStatusCode.UnsupportedMediaType, response.StatusCode);

        var body = await response.Content.ReadFromJsonAsync<ApiResponse>();
        Assert.NotNull(body);
        Assert.False(body!.Success);
    }

    [Fact]
    public async Task Extract_WhenValidatorFails_Returns422()
    {
        _factory.StubPipeline.Handler = (_, _,_,_) => throw new StructuredValidationException("Invalid JSON");

        using var client = _factory.CreateAuthenticatedClient();
        using var content = BuildExtractionContent("en");

        var response = await client.PostAsync("/api/documents/extract", content);

        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);

        var body = await response.Content.ReadFromJsonAsync<ApiResponse>();
        Assert.NotNull(body);
        Assert.False(body!.Success);
    }

    private static MultipartFormDataContent BuildExtractionContent(string preferredLanguage)
    {
        var content = new MultipartFormDataContent();
        content.Add(new StringContent(preferredLanguage), "preferredLanguage");

        var attachedFiles = 0;
        foreach (var path in RouteFilePaths)
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

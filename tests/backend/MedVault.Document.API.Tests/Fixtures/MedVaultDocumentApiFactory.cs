using MedVault.API.Features.Documents.Application.DTOs;
using MedVault.API.Features.Documents.Application.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;

namespace MedVault.Document.API.Tests.Fixtures;

public sealed class StubDocumentExtractionPipeline : IDocumentExtractionPipeline
{
    public Func<IEnumerable<IFormFile>, string, string?, string?, Task<ExtractionResult>> Handler { get; set; } =
        (_, _, _, _) => Task.FromResult(new ExtractionResult
        {
            IsMedical = true,
            DocumentType = "Lab Report",
            Date = new DateTime(2026, 4, 12, 0, 0, 0, DateTimeKind.Utc),
            IssuerName = "MedVault Clinic",
            Metadata = new MedicalMetadata
            {
                Medications =
                [
                    new MedicationInfo
                    {
                        Name = "Ibuprofen",
                        Dosage = "200 mg"
                    }
                ]
            },
            Summary = "Lab report contains medication references.",
            Confidence = 0.86,
            RequiresUserConfirmation = true
        });

    public Task<ExtractionResult> ExtractAsync(
        IEnumerable<IFormFile> files,
        string preferredLanguage,
        string? systemPrompt,
        string? userPromptTemplate)
        => Handler(files, preferredLanguage, systemPrompt, userPromptTemplate);
}

public sealed class MedVaultDocumentApiFactory : WebApplicationFactory<Program>
{
    public StubDocumentExtractionPipeline StubPipeline { get; } = new();

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");

        builder.ConfigureServices(services =>
        {
            services.AddAuthentication(options =>
            {
                options.DefaultAuthenticateScheme = "Test";
                options.DefaultChallengeScheme = "Test";
            }).AddScheme<AuthenticationSchemeOptions, TestAuthHandler>("Test", _ => { });

            var descriptor = services.SingleOrDefault(
                registration => registration.ServiceType == typeof(IDocumentExtractionPipeline));
            if (descriptor is not null)
            {
                services.Remove(descriptor);
            }

            services.AddSingleton(StubPipeline);
            services.AddScoped<IDocumentExtractionPipeline>(provider =>
                provider.GetRequiredService<StubDocumentExtractionPipeline>());
        });
    }

    public HttpClient CreateAuthenticatedClient()
    {
        var client = CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", "test-token");
        return client;
    }
}

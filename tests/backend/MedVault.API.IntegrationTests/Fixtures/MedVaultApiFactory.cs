using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Moq;
using Google.Apis.Auth;
using MedVault.API.Data;
using MedVault.API.Features.Auth.Application.Interfaces;
using MedVault.API.Features.Auth.Domain;
using Microsoft.AspNetCore.Identity;
using Testcontainers.MsSql;
using Xunit;

namespace MedVault.API.IntegrationTests.Fixtures;

/// <summary>
/// WebApplicationFactory configured for MedVault.API integration tests.
/// - Spins up a real SQL Server via Testcontainers (Docker).
/// - Each test class gets its own database on the shared container.
/// - Replaces JWT auth with a test handler that always authenticates.
/// - Mocks IGoogleTokenValidator so Google token calls succeed deterministically.
/// </summary>
public class MedVaultApiFactory : WebApplicationFactory<Program>, IAsyncLifetime
{
    // ── Shared SQL Server container (one per test run) ──────
    private static readonly MsSqlContainer SqlContainer = new MsSqlBuilder(
            "mcr.microsoft.com/mssql/server:2022-latest")
        .Build();

    private static int _refCount;
    private static readonly SemaphoreSlim _containerLock = new(1, 1);

    /// <summary>Shared mock — configure per-test via Setup().</summary>
    public Mock<IGoogleTokenValidator> GoogleTokenValidator { get; } = new();

    /// <summary>Unique DB name per factory instance to prevent cross-class data leaks.</summary>
    private readonly string _dbName = $"MedVaultTest_{Guid.NewGuid():N}";

    // ── IAsyncLifetime — container + schema management ──────

    public async Task InitializeAsync()
    {
        // Start the shared container only once (thread-safe)
        await _containerLock.WaitAsync();
        try
        {
            if (Interlocked.Increment(ref _refCount) == 1)
                await SqlContainer.StartAsync();
        }
        finally { _containerLock.Release(); }

        // Trigger host build (calls ConfigureWebHost), then create schema
        using var scope = Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<MedVaultDbContext>();
        await db.Database.EnsureCreatedAsync();
    }

    async Task IAsyncLifetime.DisposeAsync()
    {
        await base.DisposeAsync();

        await _containerLock.WaitAsync();
        try
        {
            if (Interlocked.Decrement(ref _refCount) == 0)
                await SqlContainer.DisposeAsync();
        }
        finally { _containerLock.Release(); }
    }

    // ── Host configuration ──────────────────────────────────

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        // Build a test-specific connection string pointing to our unique database
        var testConnectionString = new SqlConnectionStringBuilder(
            SqlContainer.GetConnectionString())
        {
            InitialCatalog = _dbName,
            TrustServerCertificate = true
        }.ConnectionString;

        builder.UseEnvironment("Testing");

        // ── Override configuration (connection string + JWT) ────────
        builder.ConfigureAppConfiguration((_, config) =>
        {
            config.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["ConnectionStrings:DefaultConnection"] = testConnectionString,
                ["Jwt:SecretKey"] = "TEST-ONLY-SECRET-KEY-MUST-BE-AT-LEAST-32-CHARS-LONG!!",
                ["Jwt:Key"] = "TEST-ONLY-SECRET-KEY-MUST-BE-AT-LEAST-32-CHARS-LONG!!",
                ["Jwt:Issuer"] = "MedVault.API.Test",
                ["Jwt:Audience"] = "MedVault.Client.Test",
                ["Jwt:AccessTokenExpirationMinutes"] = "60",
                ["Jwt:RefreshTokenExpirationDays"] = "7",
                ["Sharing:DemoModeEnabled"] = "true",
                ["FeatureSettings:Sharing:EmergencySharingEnabled"] = "true",
                ["FeatureSettings:Sharing:PhysicianSharingEnabled"] = "true",
                ["FeatureSettings:Sharing:MaxSharingLinksPerUser"] = "5",
                ["FeatureSettings:Sharing:DefaultMaxDocumentsToShare"] = "10",
                ["FeatureSettings:Sharing:MinDocumentsToShareLimit"] = "0",
                ["FeatureSettings:Sharing:MaxDocumentsToShareLimit"] = "10",
            });
        });

        builder.ConfigureServices(services =>
        {
            // ── Replace Google token validator with mock ────────────────
            var googleDescriptor = services.SingleOrDefault(
                d => d.ServiceType == typeof(IGoogleTokenValidator));
            if (googleDescriptor != null) services.Remove(googleDescriptor);

            services.AddSingleton(_ => GoogleTokenValidator.Object);

            // ── Replace authentication with test handler ────────────────
            services.AddAuthentication(options =>
            {
                options.DefaultAuthenticateScheme = "Test";
                options.DefaultChallengeScheme = "Test";
            })
            .AddScheme<AuthenticationSchemeOptions, TestAuthHandler>("Test", _ => { });
        });
    }

    /// <summary>
    /// Seeds a default Identity user matching <see cref="TestAuthHandler.TestUserId"/>
    /// so that authorized endpoints can find the user in the database.
    /// Call this once per test class from the constructor or an async initializer.
    /// </summary>
    public async Task SeedTestUserAsync()
    {
        using var scope = Services.CreateScope();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<AppUser>>();
        var db = scope.ServiceProvider.GetRequiredService<MedVaultDbContext>();

        var existingUser = await userManager.FindByIdAsync(TestAuthHandler.TestUserId.ToString());
        if (existingUser != null) return;

        var user = new AppUser
        {
            Id = TestAuthHandler.TestUserId,
            UserName = "test@medvault.test",
            NormalizedUserName = "TEST@MEDVAULT.TEST",
            Email = "test@medvault.test",
            NormalizedEmail = "TEST@MEDVAULT.TEST",
            EmailConfirmed = true,
            FirstName = "Test",
            LastName = "User",
            GoogleId = "google-test-id-12345",
            SecurityStamp = Guid.NewGuid().ToString(),
            AccountStatus = "Active",
            CreatedAt = DateTime.UtcNow,
        };

        // Use db.Users.Add to avoid password requirement
        db.Users.Add(user);
        await db.SaveChangesAsync();
    }

    /// <summary>Creates a client that includes a Bearer token recognized by TestAuthHandler.</summary>
    public HttpClient CreateAuthenticatedClient()
    {
        var client = CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", "test-integration-token");
        return client;
    }

    /// <summary>Creates a client without auth headers (for anonymous endpoint tests).</summary>
    public HttpClient CreateAnonymousClient() => CreateClient();
}

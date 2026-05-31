using System.Text;
using System.Text.Json.Serialization;
using FluentValidation;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.Extensions.Options;
using MedVault.API.Common.Extensions;
using MedVault.API.Common.Middleware;
using MedVault.API.Data;
using MedVault.API.Features.Auth.Application.Interfaces;
using MedVault.API.Features.Auth.Domain;
using MedVault.API.Features.Auth.Infrastructure;
using MedVault.API.Features.Configuration.Application.Services;
using MedVault.API.Features.Configuration.Domain;
using MedVault.API.Features.Documents.Application;
using MedVault.API.Features.Documents.Application.Services;
using MedVault.API.Features.Documents.Domain;
using MedVault.API.Features.Notifications.Application.Interfaces;
using MedVault.API.Features.Notifications.Infrastructure;
using MedVault.API.Features.Sharing.Application.Interfaces;
using MedVault.API.Features.Sharing.Hubs;
using MedVault.API.Features.Sharing.Infrastructure;
using MedVault.DocIntelligence.Extensions;
using Serilog;

Log.Logger = new LoggerConfiguration()
    .WriteTo.Console()
    .CreateBootstrapLogger();

try
{
    Log.Information("Starting MedVault API bootstrap");

    var builder = WebApplication.CreateBuilder(args);
    Log.Information("WebApplicationBuilder created");

    builder.Host.UseSerilog((context, services, configuration) => configuration
        .ReadFrom.Configuration(context.Configuration)
        .ReadFrom.Services(services)
        .Enrich.FromLogContext());
    Log.Information("Serilog host configuration applied");
    builder.AddServiceDefaults();
    Log.Information("Service defaults registered");
    var dbConnectionString = builder.Configuration.GetConnectionString("DefaultConnection")
        ?? builder.Configuration.GetConnectionString("DatabaseConnection")
        ?? throw new InvalidOperationException("Neither ConnectionStrings:DefaultConnection nor ConnectionStrings:DatabaseConnection is configured.");
    Log.Information("Database connection string resolved from configuration");

    builder.Services.AddDbContext<MedVaultDbContext>(options =>
        options.UseSqlServer(dbConnectionString));
    Log.Information("DbContext registration completed");
    builder.Services.AddIdentity<AppUser, IdentityRole<Guid>>(options =>
        {
            options.User.RequireUniqueEmail = true;
            options.Password.RequireDigit = false;
            options.Password.RequiredLength = 8;
            options.Password.RequireNonAlphanumeric = false;
            options.Password.RequireUppercase = false;
            options.Password.RequireLowercase = false;
            options.Lockout.MaxFailedAccessAttempts = 5;
            options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(15);
        })
        .AddEntityFrameworkStores<MedVaultDbContext>()
        .AddDefaultTokenProviders();
    var jwtKey = builder.Configuration["Jwt:Key"]
        ?? throw new InvalidOperationException("Jwt:Key is not configured.");
    Log.Information("JWT key configuration resolved");

    builder.Services.AddAuthentication(options =>
        {
            options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
            options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
        })
        .AddJwtBearer(options =>
        {
            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidateLifetime = true,
                ValidateIssuerSigningKey = true,
                ValidIssuer = builder.Configuration["Jwt:Issuer"],
                ValidAudience = builder.Configuration["Jwt:Audience"],
                IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
                ClockSkew = TimeSpan.FromMinutes(1)
            };
        });

    builder.Services.AddAuthorization();

    builder.Services.AddLocalization(options => options.ResourcesPath = "Resources");
    builder.Services.Configure<RequestLocalizationOptions>(options =>
    {
        var supportedCultures = new[] { "en", "en-US", "es", "es-ES", "ca", "ca-ES" };
        options.SetDefaultCulture("en")
            .AddSupportedCultures(supportedCultures)
            .AddSupportedUICultures(supportedCultures);
    });

    builder.Services
        .AddOptions<FeatureSettingsOptions>()
        .Bind(builder.Configuration.GetSection(FeatureSettingsOptions.SectionName));

    builder.Services
        .AddOptions<PushNotificationsOptions>()
        .Bind(builder.Configuration.GetSection(PushNotificationsOptions.SectionName));

    builder.Services
        .AddOptions<ShareLinksCleanupOptions>()
        .Bind(builder.Configuration.GetSection(ShareLinksCleanupOptions.SectionName));

    builder.Services
        .AddOptions<DocumentExtractionOptions>()
        .Bind(builder.Configuration.GetSection(DocumentExtractionOptions.SectionName));
    builder.Services.AddMemoryCache();
    builder.Services.AddScoped<IJwtTokenService, JwtTokenService>();
    builder.Services.AddScoped<IGoogleTokenValidator, GoogleTokenValidator>();
    builder.Services.AddSingleton<IPkceAuthorizationCodeStore, PkceAuthorizationCodeStore>();
    builder.Services.AddScoped<IShareProtectionService, ShareProtectionService>();
    builder.Services.AddScoped<IDocumentFileRepository, DocumentFileRepository>();
    builder.Services.AddSingleton<IPushNotificationSender, FirebasePushNotificationSender>();
    builder.Services.AddSingleton<ISystemConfigurationService, SystemConfigurationService>();
    builder.Services.AddHostedService<ShareLinksCleanupHostedService>();
    builder.Services.AddDocIntelligence(builder.Configuration);
    builder.Services.AddScoped<IDocumentExtractionPipeline, DocumentExtractionPipeline>();
    builder.Services.AddCqrsHandlers();
    builder.Services.AddValidatorsFromAssemblyContaining<Program>();
    builder.Services.AddControllersWithViews()
        .AddJsonOptions(options =>
        {
            options.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
            options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
            options.JsonSerializerOptions.DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull;
        });
    builder.Services.AddSignalR();
    builder.Services.AddEndpointsApiExplorer();
    builder.Services.AddOpenApi();
    builder.Services.AddSwaggerGen();
    var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>()
        ?? throw new InvalidOperationException("Cors:AllowedOrigins is not configured.");
    Log.Information("CORS allowed origins resolved with {OriginCount} entries", allowedOrigins.Length);

    builder.Services.AddCors(options =>
    {
        options.AddPolicy("MedVaultCors", policy =>
        {
            if (allowedOrigins.Contains("*"))
            {
                policy.SetIsOriginAllowed(_ => true);
            }
            else
            {
                policy.WithOrigins(allowedOrigins);
            }

            policy.AllowAnyMethod()
                  .AllowAnyHeader()
                  .AllowCredentials();
        });
    });
    Log.Information("Building web application host");
    var app = builder.Build();
    Log.Information("Web application host built");
    app.UseMiddleware<GlobalExceptionMiddleware>();
    Log.Information("Middleware pipeline configuration started");

    if (app.Environment.IsDevelopment())
    {
        app.MapOpenApi();
        app.UseSwagger();
        app.UseSwaggerUI(c => c.SwaggerEndpoint("/swagger/v1/swagger.json", "MedVault API v1"));
    }

    app.UseHttpsRedirection();
    app.UseRequestLocalization(app.Services.GetRequiredService<IOptions<RequestLocalizationOptions>>().Value);
    app.UseCors("MedVaultCors");
    app.UseMiddleware<JwtLoggingMiddleware>();
    app.UseAuthentication();
    app.UseAuthorization();
    app.UseMiddleware<AuditLoggingMiddleware>();

    app.MapControllers();
    app.MapHub<SharingSyncHub>("/hubs/sharing-sync");

    app.MapDefaultEndpoints();
    Log.Information("Endpoint mapping completed");
    if (app.Environment.IsDevelopment())
    {
        Log.Information("Development environment detected. Checking pending database migrations");
        using var scope = app.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<MedVaultDbContext>();

        var pendingMigrations = (await db.Database.GetPendingMigrationsAsync()).ToArray();
        if (pendingMigrations.Length == 0)
        {
            Log.Information("No pending database migrations");
        }
        else
        {
            Log.Information("Applying {MigrationCount} pending database migration(s): {Migrations}", pendingMigrations.Length, string.Join(", ", pendingMigrations));
            try
            {
                await db.Database.MigrateAsync();
                Log.Information("Database migrations applied successfully");
            }
            catch (Exception ex)
            {
                Log.Error(ex, "Database migration failed during startup");
                throw;
            }
        }
    }
    else
    {
        Log.Information("Skipping database migration check outside Development environment");
    }

    Log.Information("MedVault API bootstrap completed. Starting host.");
    await app.RunAsync();
}
catch (Exception ex)
{
    Log.Fatal(ex, "MedVault API failed during bootstrap/startup.");
}
finally
{
    Log.CloseAndFlush();
}

public partial class Program;


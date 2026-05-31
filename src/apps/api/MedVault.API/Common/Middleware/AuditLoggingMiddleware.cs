using System.Security.Claims;
using MedVault.API.Common.Models;
using MedVault.API.Data;

namespace MedVault.API.Common.Middleware;

public sealed class AuditLoggingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<AuditLoggingMiddleware> _logger;
    private readonly IServiceScopeFactory _scopeFactory;
    private static readonly HashSet<string> AuditedMethods = ["POST", "PUT", "PATCH", "DELETE"];

    public AuditLoggingMiddleware(
        RequestDelegate next,
        ILogger<AuditLoggingMiddleware> logger,
        IServiceScopeFactory scopeFactory)
    {
        _next = next;
        _logger = logger;
        _scopeFactory = scopeFactory;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        await _next(context);
        if (!AuditedMethods.Contains(context.Request.Method))
            return;

        var userIdClaim = context.User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? context.User.FindFirstValue("sub");

        if (userIdClaim is null || !Guid.TryParse(userIdClaim, out var userId))
            return;

        try
        {
            await using var scope = _scopeFactory.CreateAsyncScope();
            var db = scope.ServiceProvider.GetRequiredService<MedVaultDbContext>();

            var auditLog = new AuditLogEntity
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Action = $"{context.Request.Method} {context.Request.Path}",
                EntityType = ExtractEntityType(context.Request.Path),
                IpAddress = context.Connection.RemoteIpAddress?.ToString(),
                UserAgent = context.Request.Headers.UserAgent.ToString(),
                StatusCode = context.Response.StatusCode,
                Timestamp = DateTime.UtcNow
            };

            db.AuditLogs.Add(auditLog);
            await db.SaveChangesAsync();

            _logger.LogInformation(
                "AUDIT_EVENT UserId={UserId} Action={Action} EntityType={EntityType} StatusCode={StatusCode} IpAddress={IpAddress}",
                auditLog.UserId,
                auditLog.Action,
                auditLog.EntityType,
                auditLog.StatusCode,
                auditLog.IpAddress);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to write audit log for {Method} {Path}",
                context.Request.Method, context.Request.Path);
        }
    }

    private static string ExtractEntityType(PathString path)
    {
        var segments = path.Value?.Split('/', StringSplitOptions.RemoveEmptyEntries);
        return segments is { Length: >= 2 } ? segments[1] : "Unknown";
    }
}


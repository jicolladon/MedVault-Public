namespace MedVault.API.Common.Middleware;

public class JwtLoggingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<JwtLoggingMiddleware> _logger;

    public JwtLoggingMiddleware(RequestDelegate next, ILogger<JwtLoggingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var authHeader = context.Request.Headers.Authorization.FirstOrDefault();

        if (!string.IsNullOrEmpty(authHeader) && authHeader.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
        {
            _logger.LogInformation(
                "JWT Bearer token present on {Method} {Path}",
                context.Request.Method,
                context.Request.Path);
        }
        else
        {
            _logger.LogDebug(
                "No Bearer token on {Method} {Path}",
                context.Request.Method,
                context.Request.Path);
        }

        await _next(context);

        if (context.Response.StatusCode == StatusCodes.Status401Unauthorized)
        {
            _logger.LogWarning(
                "Unauthorized response for {Method} {Path}",
                context.Request.Method,
                context.Request.Path);
        }
        else if (context.Response.StatusCode == StatusCodes.Status403Forbidden)
        {
            _logger.LogWarning(
                "Forbidden response for {Method} {Path}",
                context.Request.Method,
                context.Request.Path);
        }
    }
}


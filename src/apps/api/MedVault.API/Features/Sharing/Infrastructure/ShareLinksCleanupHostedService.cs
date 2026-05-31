using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using MedVault.API.Data;

namespace MedVault.API.Features.Sharing.Infrastructure;

public sealed class ShareLinksCleanupOptions
{
    public const string SectionName = "Maintenance:ShareLinksCleanup";

    public bool Enabled { get; set; } = true;
    public int IntervalMinutes { get; set; } = 60;
    public int BatchSize { get; set; } = 500;

    public int EffectiveIntervalMinutes => IntervalMinutes <= 0 ? 60 : IntervalMinutes;
    public int EffectiveBatchSize => BatchSize <= 0 ? 500 : BatchSize;
}

public sealed class ShareLinksCleanupHostedService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly IOptionsMonitor<ShareLinksCleanupOptions> _optionsMonitor;
    private readonly ILogger<ShareLinksCleanupHostedService> _logger;

    public ShareLinksCleanupHostedService(
        IServiceScopeFactory scopeFactory,
        IOptionsMonitor<ShareLinksCleanupOptions> optionsMonitor,
        ILogger<ShareLinksCleanupHostedService> logger)
    {
        _scopeFactory = scopeFactory;
        _optionsMonitor = optionsMonitor;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Share links cleanup hosted service started.");

        while (!stoppingToken.IsCancellationRequested)
        {
            var options = _optionsMonitor.CurrentValue;

            if (options.Enabled)
            {
                try
                {
                    var removed = await CleanupExpiredOrRevokedLinksAsync(
                        options,
                        stoppingToken);

                    if (removed > 0)
                    {
                        _logger.LogInformation(
                            "Share links cleanup removed {RemovedCount} expired/revoked links.",
                            removed);
                    }
                }
                catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
                {
                    break;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Share links cleanup failed.");
                }
            }

            var delay = TimeSpan.FromMinutes(options.EffectiveIntervalMinutes);
            await Task.Delay(delay, stoppingToken);
        }

        _logger.LogInformation("Share links cleanup hosted service stopped.");
    }

    private async Task<int> CleanupExpiredOrRevokedLinksAsync(
        ShareLinksCleanupOptions options,
        CancellationToken cancellationToken)
    {
        using var scope = _scopeFactory.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<MedVaultDbContext>();

        var now = DateTime.UtcNow;
        var totalRemoved = 0;
        var batchSize = options.EffectiveBatchSize;

        while (!cancellationToken.IsCancellationRequested)
        {
            var removed = await db.ShareTokens
                .Where(token => token.IsRevoked || token.ExpiresAt <= now)
                .Take(batchSize)
                .ExecuteDeleteAsync(cancellationToken);

            totalRemoved += removed;

            if (removed < batchSize)
            {
                break;
            }
        }

        return totalRemoved;
    }
}


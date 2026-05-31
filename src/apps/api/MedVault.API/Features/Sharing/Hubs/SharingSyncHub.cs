using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace MedVault.API.Features.Sharing.Hubs;

[AllowAnonymous]
public class SharingSyncHub : Hub
{
    private readonly ILogger<SharingSyncHub> _logger;

    public SharingSyncHub(ILogger<SharingSyncHub> logger)
    {
        _logger = logger;
    }

    public async Task JoinShareGroup(string token)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"share-{token}");
        _logger.LogInformation("Connection {ConnectionId} joined share group for token {Token}",
            Context.ConnectionId, token[..Math.Min(8, token.Length)] + "...");
    }

    public async Task LeaveShareGroup(string token)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"share-{token}");
        _logger.LogInformation("Connection {ConnectionId} left share group for token {Token}",
            Context.ConnectionId, token[..Math.Min(8, token.Length)] + "...");
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        _logger.LogInformation("Connection {ConnectionId} disconnected", Context.ConnectionId);
        await base.OnDisconnectedAsync(exception);
    }
}

public record SyncMessage(string Type, string? Payload, DateTime Timestamp);


namespace MedVault.API.Features.Sharing.Domain;

public class ShareAccessLogEntity
{
    public Guid Id { get; set; }
    public Guid ShareTokenId { get; set; }

    public string? ViewerName { get; set; }

    public string? ViewerIpAddress { get; set; }

    public string? ViewerUserAgent { get; set; }

    public DateTime AccessedAt { get; set; } = DateTime.UtcNow;
    public ShareTokenEntity ShareToken { get; set; } = null!;
}


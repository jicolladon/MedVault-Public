namespace MedVault.API.Features.Sharing.Domain;

public enum ShareAccessApprovalStatus
{
    Pending = 0,
    Approved = 1,
    Denied = 2,
    Expired = 3,
}

public class ShareAccessApprovalRequestEntity
{
    public Guid Id { get; set; }
    public Guid ShareTokenId { get; set; }

    public string ViewerName { get; set; } = string.Empty;

    public string? ViewerIpAddress { get; set; }
    public string? ViewerUserAgent { get; set; }

    public string ApprovalCodeHash { get; set; } = string.Empty;

    public string ApprovalCodeHint { get; set; } = string.Empty;

    public ShareAccessApprovalStatus Status { get; set; } = ShareAccessApprovalStatus.Pending;
    public DateTime RequestedAt { get; set; } = DateTime.UtcNow;
    public DateTime ExpiresAt { get; set; }
    public DateTime? DecisionAt { get; set; }
    public ShareTokenEntity ShareToken { get; set; } = null!;
}

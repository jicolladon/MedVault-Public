using MedVault.API.Features.Auth.Domain;

namespace MedVault.API.Features.Sharing.Domain;

public class ShareTokenEntity
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }

    public string Token { get; set; } = null!;

    public string? TokenHash { get; set; }

    public string? ShareCode { get; set; }

    public string AccessLevel { get; set; } = "ViewOnly";

    public string ShareType { get; set; } = "Regular";

    public DateTime ExpiresAt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public bool IsRevoked { get; set; }

    public DateTime? RevokedAt { get; set; }

    public string? Label { get; set; }

    public string? EncryptedPayload { get; set; }

    public int AccessCount { get; set; }

    public DateTime? LastAccessedAt { get; set; }
    public AppUser User { get; set; } = null!;
    public ICollection<ShareAccessLogEntity> AccessLogs { get; set; } = [];
    public ICollection<ShareAccessApprovalRequestEntity> AccessApprovalRequests { get; set; } = [];
}


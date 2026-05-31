using MedVault.API.Features.Sharing.Application.DTOs;

namespace MedVault.API.Features.Sharing.Presentation.Web;

public sealed class SharingPortalViewModel
{
    public string Token { get; init; } = string.Empty;
    public string Language { get; init; } = "en";
    public bool IsDemoMode { get; init; }
    public bool RequiresTwoFactorApproval { get; init; }
    public bool RequiresPassword { get; init; }
    public bool RequiresVerificationCode { get; init; }
    public bool RequiresViewerName { get; init; }
    public bool IsTwoFactorPending { get; init; }
    public string? TwoFactorStatus { get; init; }
    public string? TwoFactorMessage { get; init; }
    public string? ErrorMessage { get; init; }
    public DateTime? ExpiresAt { get; init; }
    public SharedDataResponse? SharedData { get; init; }
    public ShareUnlockInputModel UnlockInput { get; init; } = new();
    public IReadOnlyDictionary<string, string> Labels { get; init; } = new Dictionary<string, string>();

    public string Label(string key)
    {
        return Labels.TryGetValue(key, out var value) ? value : key;
    }
}

public sealed class ShareUnlockInputModel
{
    public string? ViewerName { get; set; }
    public string? AccessPassword { get; set; }
    public string? VerificationCode { get; set; }
    public Guid? AccessRequestId { get; set; }
}


using MedVault.API.Features.Auth.Domain;

namespace MedVault.API.Features.Configuration.Domain;

public class BackupMetadataEntity
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string? BackupType { get; set; }
    public string? Provider { get; set; }
    public bool AutoBackupEnabled { get; set; }
    public string? FilePath { get; set; }
    public long? FileSizeBytes { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
    public bool IsRestored { get; set; }
    public DateTime? RestoredAt { get; set; }
    public string? Status { get; set; }
    public AppUser User { get; set; } = null!;
}


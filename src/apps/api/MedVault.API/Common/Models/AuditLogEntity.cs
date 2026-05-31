namespace MedVault.API.Common.Models;

public class AuditLogEntity
{
    public Guid Id { get; set; }
    public Guid? UserId { get; set; }
    public string Action { get; set; } = null!;
    public string? EntityType { get; set; }
    public string? EntityId { get; set; }
    public string? Endpoint { get; set; }
    public string? HttpMethod { get; set; }
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
    public int? StatusCode { get; set; }
    public string? AdditionalData { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}


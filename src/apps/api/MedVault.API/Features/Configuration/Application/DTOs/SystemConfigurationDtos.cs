namespace MedVault.API.Features.Configuration.Application.DTOs;

public sealed record SharingFeatureSettingsResponse
{
    public bool EmergencySharingEnabled { get; init; }
    public bool PhysicianSharingEnabled { get; init; }
    public int MaxSharingLinksPerUser { get; init; }
    public int MaxDocumentsToShare { get; init; }
    public int MinDocumentsToShareLimit { get; init; }
    public int MaxDocumentsToShareLimit { get; init; }
    public int MaxSharedDocumentBytes { get; init; }
}

public sealed record DocumentFeatureSettingsResponse
{
    public bool DocumentExtractDataEnabled { get; init; }
    public int MaxFilesPerDocument { get; init; }
    public bool DemonstrationModeEnabled { get; init; }
}

public sealed record SystemConfigurationResponse
{
    public SharingFeatureSettingsResponse Sharing { get; init; } = new();
    public DocumentFeatureSettingsResponse Documents { get; init; } = new();
}

public sealed record UpdateSharingFeatureSettingsRequest
{
    public bool EmergencySharingEnabled { get; init; }
    public bool PhysicianSharingEnabled { get; init; }
    public int MaxSharingLinksPerUser { get; init; }
    public int DefaultMaxDocumentsToShare { get; init; }
    public int MinDocumentsToShareLimit { get; init; }
    public int MaxDocumentsToShareLimit { get; init; }
    public int MaxSharedDocumentBytes { get; init; }
}


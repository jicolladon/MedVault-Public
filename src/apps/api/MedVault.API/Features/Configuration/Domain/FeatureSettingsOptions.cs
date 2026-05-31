namespace MedVault.API.Features.Configuration.Domain;

public sealed class FeatureSettingsOptions
{
    public const string SectionName = "FeatureSettings";

    public SharingFeatureSettingsOptions Sharing { get; set; } = new();
    public DocumentFeatureSettingsOptions Documents { get; set; } = new();
}

public sealed class SharingFeatureSettingsOptions
{
    public bool EmergencySharingEnabled { get; set; } = true;
    public bool PhysicianSharingEnabled { get; set; } = true;
    public int MaxSharingLinksPerUser { get; set; } = 5;
    public int DefaultMaxDocumentsToShare { get; set; } = 10;
    public int MinDocumentsToShareLimit { get; set; } = 0;
    public int MaxDocumentsToShareLimit { get; set; } = 10;
    public int MaxSharedDocumentBytes { get; set; } = 10 * 1024 * 1024;
}

public sealed class DocumentFeatureSettingsOptions
{
    public bool DocumentExtractDataEnabled { get; set; } = true;
    public int MaxFilesPerDocument { get; set; } = 5;
    public bool DemonstrationModeEnabled { get; set; }
}


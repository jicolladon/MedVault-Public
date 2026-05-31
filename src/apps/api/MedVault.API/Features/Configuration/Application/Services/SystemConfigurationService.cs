using Microsoft.Extensions.Options;
using MedVault.API.Features.Configuration.Application.DTOs;
using MedVault.API.Features.Configuration.Domain;

namespace MedVault.API.Features.Configuration.Application.Services;

public interface ISystemConfigurationService
{
    SystemConfigurationResponse GetSystemConfiguration();
    SharingFeatureSettingsResponse GetSharingSettings();
    DocumentFeatureSettingsResponse GetDocumentSettings();
    SharingFeatureSettingsResponse UpdateSharingSettings(UpdateSharingFeatureSettingsRequest request);
}

public sealed class SystemConfigurationService : ISystemConfigurationService
{
    private const int DefaultMaxSharingLinksPerUser = 5;
    private const int AbsoluteMaxSharingLinksPerUser = 100;
    private const int AbsoluteMaxDocumentsLimit = 10;
    private const int DefaultMaxSharedDocumentBytes = 10 * 1024 * 1024;
    private const int AbsoluteMinSharedDocumentBytes = 1024;
    private const int AbsoluteMaxSharedDocumentBytes = 10 * 1024 * 1024;
    private const int DefaultMaxFilesPerDocument = 5;

    private readonly object _sync = new();
    private SharingFeatureSettingsResponse _sharingSettings;
    private DocumentFeatureSettingsResponse _documentSettings;

    public SystemConfigurationService(IOptions<FeatureSettingsOptions> options)
    {
        _sharingSettings = Normalize(options.Value.Sharing);
        _documentSettings = Normalize(options.Value.Documents);
    }

    public SystemConfigurationResponse GetSystemConfiguration()
    {
        lock (_sync)
        {
            return new SystemConfigurationResponse
            {
                Sharing = _sharingSettings,
                Documents = _documentSettings,
            };
        }
    }

    public SharingFeatureSettingsResponse GetSharingSettings()
    {
        lock (_sync)
        {
            return _sharingSettings;
        }
    }

    public DocumentFeatureSettingsResponse GetDocumentSettings()
    {
        lock (_sync)
        {
            return _documentSettings;
        }
    }

    public SharingFeatureSettingsResponse UpdateSharingSettings(UpdateSharingFeatureSettingsRequest request)
    {
        var next = Normalize(request);

        lock (_sync)
        {
            _sharingSettings = next;
            return _sharingSettings;
        }
    }

    private static SharingFeatureSettingsResponse Normalize(SharingFeatureSettingsOptions options)
    {
        return Normalize(new UpdateSharingFeatureSettingsRequest
        {
            EmergencySharingEnabled = options.EmergencySharingEnabled,
            PhysicianSharingEnabled = options.PhysicianSharingEnabled,
            MaxSharingLinksPerUser = options.MaxSharingLinksPerUser,
            DefaultMaxDocumentsToShare = options.DefaultMaxDocumentsToShare,
            MinDocumentsToShareLimit = options.MinDocumentsToShareLimit,
            MaxDocumentsToShareLimit = options.MaxDocumentsToShareLimit,
            MaxSharedDocumentBytes = options.MaxSharedDocumentBytes,
        });
    }

    private static DocumentFeatureSettingsResponse Normalize(DocumentFeatureSettingsOptions options)
    {
        var maxFiles = options.MaxFilesPerDocument <= 0
            ? DefaultMaxFilesPerDocument
            : options.MaxFilesPerDocument;

        return new DocumentFeatureSettingsResponse
        {
            DocumentExtractDataEnabled = options.DocumentExtractDataEnabled,
            MaxFilesPerDocument = maxFiles,
            DemonstrationModeEnabled = options.DemonstrationModeEnabled
        };
    }

    private static SharingFeatureSettingsResponse Normalize(UpdateSharingFeatureSettingsRequest request)
    {
        var maxSharingLinksPerUser = Clamp(
            request.MaxSharingLinksPerUser,
            0,
            AbsoluteMaxSharingLinksPerUser);

        var minLimit = Clamp(request.MinDocumentsToShareLimit, 0, AbsoluteMaxDocumentsLimit);
        var maxLimit = Clamp(request.MaxDocumentsToShareLimit, 0, AbsoluteMaxDocumentsLimit);
        if (maxLimit < minLimit)
        {
            maxLimit = minLimit;
        }

        var selectedMax = Clamp(request.DefaultMaxDocumentsToShare, minLimit, maxLimit);
        var requestedMaxSharedDocumentBytes = request.MaxSharedDocumentBytes <= 0
            ? DefaultMaxSharedDocumentBytes
            : request.MaxSharedDocumentBytes;
        var maxSharedDocumentBytes = Clamp(
            requestedMaxSharedDocumentBytes,
            AbsoluteMinSharedDocumentBytes,
            AbsoluteMaxSharedDocumentBytes);

        return new SharingFeatureSettingsResponse
        {
            EmergencySharingEnabled = request.EmergencySharingEnabled,
            PhysicianSharingEnabled = request.PhysicianSharingEnabled,
            MaxSharingLinksPerUser = request.MaxSharingLinksPerUser == 0
                ? 0
                : (maxSharingLinksPerUser == 0 ? DefaultMaxSharingLinksPerUser : maxSharingLinksPerUser),
            MaxDocumentsToShare = selectedMax,
            MinDocumentsToShareLimit = minLimit,
            MaxDocumentsToShareLimit = maxLimit,
            MaxSharedDocumentBytes = maxSharedDocumentBytes,
        };
    }

    private static int Clamp(int value, int min, int max)
    {
        if (value < min)
        {
            return min;
        }

        if (value > max)
        {
            return max;
        }

        return value;
    }
}


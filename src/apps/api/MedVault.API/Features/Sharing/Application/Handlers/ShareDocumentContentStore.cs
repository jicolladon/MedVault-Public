using System.Text;
using Microsoft.EntityFrameworkCore;
using MedVault.API.Data;
using MedVault.API.Features.Documents.Domain;
using MedVault.API.Features.Sharing.Application.DTOs;
using MedVault.API.Features.Sharing.Application.Interfaces;

namespace MedVault.API.Features.Sharing.Application.Handlers;

internal static class ShareDocumentContentStore
{
    public static async Task<SharePayloadDto> PersistForShareTokenAsync(
        MedVaultDbContext db,
        IShareProtectionService shareProtection,
        Guid shareTokenId,
        Guid userId,
        SharePayloadDto payload,
        CancellationToken cancellationToken)
    {
        var snapshot = payload.SharedSnapshot;
        if (snapshot is null)
        {
            return payload;
        }

        var existingDocuments = await db.MedicalDocuments
            .Include(document => document.Files)
                .ThenInclude(file => file.Content)
            .Where(document => document.ShareTokenId == shareTokenId)
            .ToListAsync(cancellationToken);

        var existingFilesById = existingDocuments
            .SelectMany(document => document.Files)
            .ToDictionary(file => file.Id);

        var retainedFileIds = new HashSet<Guid>();
        var normalizedDocuments = new List<SharedDocumentDto>(snapshot.Documents.Count);

        for (var index = 0; index < snapshot.Documents.Count; index++)
        {
            var document = snapshot.Documents[index];
            Guid? contentFileId = null;

            if (Guid.TryParse(document.ContentFileId, out var parsedFileId))
            {
                contentFileId = parsedFileId;
            }

            if (!string.IsNullOrWhiteSpace(document.ContentBase64))
            {
                var base64Payload = document.ContentBase64.Trim();
                byte[] contentBytes;
                try
                {
                    contentBytes = Convert.FromBase64String(base64Payload);
                }
                catch (FormatException)
                {
                    throw new InvalidOperationException(
                        $"Document '{document.Title}' has invalid base64 content.");
                }

                var now = DateTime.UtcNow;
                var medicalDocument = new MedicalDocumentEntity
                {
                    Id = Guid.NewGuid(),
                    ShareTokenId = shareTokenId,
                    UserId = userId,
                    Title = document.Title,
                    Description = document.Description,
                    Category = string.IsNullOrWhiteSpace(document.Category) ? "Shared" : document.Category!,
                    CreatedAt = now,
                    UpdatedAt = now,
                };

                var fileId = Guid.NewGuid();
                var storedFileName = string.IsNullOrWhiteSpace(document.FileName)
                    ? $"{document.Title}.bin"
                    : document.FileName!;

                var fileEntity = new DocumentFileEntity
                {
                    Id = fileId,
                    DocumentId = medicalDocument.Id,
                    FileName = storedFileName,
                    FileExtension = Path.GetExtension(storedFileName),
                    MimeType = document.ContentType,
                    FileSizeBytes = document.FileSizeBytes ?? contentBytes.LongLength,
                    SortOrder = index,
                    CreatedAt = now,
                    UpdatedAt = now,
                    Content = new DocumentFileContentEntity
                    {
                        FileId = fileId,
                        EncryptedPayload = Encoding.UTF8.GetBytes(shareProtection.ProtectPayload(base64Payload)),
                        CreatedAt = now,
                        UpdatedAt = now,
                    },
                };

                medicalDocument.Files.Add(fileEntity);
                db.MedicalDocuments.Add(medicalDocument);

                contentFileId = fileId;
                retainedFileIds.Add(fileId);
            }
            else if (contentFileId.HasValue && existingFilesById.ContainsKey(contentFileId.Value))
            {
                retainedFileIds.Add(contentFileId.Value);
            }
            else
            {
                contentFileId = null;
            }

            normalizedDocuments.Add(document with
            {
                ContentBase64 = null,
                ContentFileId = contentFileId?.ToString(),
            });
        }

        if (existingDocuments.Count > 0)
        {
            var orphanDocuments = existingDocuments
                .Where(document => document.Files.All(file => !retainedFileIds.Contains(file.Id)))
                .ToList();

            if (orphanDocuments.Count > 0)
            {
                db.MedicalDocuments.RemoveRange(orphanDocuments);
            }
        }

        return payload with
        {
            SharedSnapshot = snapshot with
            {
                Documents = normalizedDocuments,
            },
        };
    }

    public static async Task<string?> LoadDocumentContentBase64Async(
        MedVaultDbContext db,
        IShareProtectionService shareProtection,
        Guid shareTokenId,
        string? contentFileId,
        CancellationToken cancellationToken)
    {
        if (!Guid.TryParse(contentFileId, out var fileId))
        {
            return null;
        }

        var encryptedPayload = await db.DocumentFileContents
            .AsNoTracking()
            .Where(content =>
                content.FileId == fileId &&
                content.File.Document.ShareTokenId == shareTokenId)
            .Select(content => content.EncryptedPayload)
            .FirstOrDefaultAsync(cancellationToken);

        if (encryptedPayload is null || encryptedPayload.Length == 0)
        {
            return null;
        }

        var protectedPayload = Encoding.UTF8.GetString(encryptedPayload);
        return shareProtection.UnprotectPayload(protectedPayload);
    }
}

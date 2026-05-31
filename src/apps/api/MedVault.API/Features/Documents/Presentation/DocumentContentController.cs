using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MedVault.API.Features.Documents.Application;

namespace MedVault.API.Features.Documents.Presentation;

[ApiController]
[Route("api/documents")]
public class DocumentContentController(
    IDocumentFileRepository repository,
    ILogger<DocumentContentController> logger) : ControllerBase
{
    /// <summary>
    /// Get decrypted document file content by ID (authorized users only).
    /// </summary>
    [HttpGet("{documentFileId:guid}/content")]
    [Authorize]
    public async Task<IActionResult> GetDocumentContent(Guid documentFileId, CancellationToken ct)
    {
        try
        {
            var file = await repository.GetFileWithContentAsync(documentFileId, ct);
            if (file?.Content?.EncryptedPayload is null)
                return NotFound();

            return File(
                file.Content.EncryptedPayload,
                file.MimeType ?? "application/octet-stream",
                file.FileName);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error retrieving document content {FileId}", documentFileId);
            return StatusCode(StatusCodes.Status500InternalServerError);
        }
    }
}

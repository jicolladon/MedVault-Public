using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using MedVault.API.Common.CQRS;
using MedVault.API.Data;
using MedVault.API.Features.UserProfile.Application.Commands;
using MedVault.API.Features.UserProfile.Application.DTOs;
using MedVault.API.Features.UserProfile.Domain;

namespace MedVault.API.Features.UserProfile.Application.Handlers;

public sealed class AddEmergencyContactCommandHandler
    : ICommandHandler<AddEmergencyContactCommand, EmergencyContactResponse>
{
    private readonly MedVaultDbContext _db;
    private readonly ILogger<AddEmergencyContactCommandHandler> _logger;

    public AddEmergencyContactCommandHandler(
        MedVaultDbContext db,
        ILogger<AddEmergencyContactCommandHandler> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task<EmergencyContactResponse> HandleAsync(
        AddEmergencyContactCommand command,
        CancellationToken ct)
    {
        var data = command.Data;
        var contactId = string.IsNullOrWhiteSpace(data.ContactId)
            ? Guid.NewGuid().ToString("N")
            : data.ContactId.Trim();

        var isPrimary = data.IsPrimary;
        var existingCount = await _db.UserEmergencyContacts
            .AsNoTracking()
            .CountAsync(c => c.UserId == command.UserId, ct);
        if (existingCount == 0)
        {
            isPrimary = true;
        }

        if (isPrimary)
        {
            await UnsetPrimaryForUser(command.UserId, ct);
        }

        var now = DateTime.UtcNow;
        var entity = new UserEmergencyContactEntity
        {
            Id = Guid.NewGuid(),
            UserId = command.UserId,
            ContactId = contactId,
            Name = data.Name.Trim(),
            Relationship = data.Relationship.Trim(),
            Phone = data.Phone.Trim(),
            Email = string.IsNullOrWhiteSpace(data.Email) ? null : data.Email.Trim(),
            IsPrimary = isPrimary,
            CreatedAt = now,
            UpdatedAt = now
        };

        _db.UserEmergencyContacts.Add(entity);
        await _db.SaveChangesAsync(ct);

        _logger.LogInformation("Emergency contact added for user {UserId}: {ContactId}", command.UserId, entity.ContactId);

        return ToDto(entity);
    }

    private async Task UnsetPrimaryForUser(Guid userId, CancellationToken ct)
    {
        var contacts = await _db.UserEmergencyContacts
            .Where(c => c.UserId == userId && c.IsPrimary)
            .ToListAsync(ct);

        foreach (var contact in contacts)
        {
            contact.IsPrimary = false;
            contact.UpdatedAt = DateTime.UtcNow;
        }
    }

    private static EmergencyContactResponse ToDto(UserEmergencyContactEntity entity)
    {
        return new EmergencyContactResponse
        {
            ContactId = entity.ContactId,
            Name = entity.Name,
            Relationship = entity.Relationship,
            Phone = entity.Phone,
            Email = entity.Email,
            IsPrimary = entity.IsPrimary,
            CreatedAt = entity.CreatedAt,
            UpdatedAt = entity.UpdatedAt
        };
    }
}

public sealed class UpdateEmergencyContactCommandHandler
    : ICommandHandler<UpdateEmergencyContactCommand, EmergencyContactResponse>
{
    private readonly MedVaultDbContext _db;

    public UpdateEmergencyContactCommandHandler(MedVaultDbContext db)
    {
        _db = db;
    }

    public async Task<EmergencyContactResponse> HandleAsync(
        UpdateEmergencyContactCommand command,
        CancellationToken ct)
    {
        var entity = await _db.UserEmergencyContacts
            .FirstOrDefaultAsync(c => c.UserId == command.UserId && c.ContactId == command.ContactId, ct)
            ?? throw new KeyNotFoundException("Emergency contact not found.");

        if (command.Data.IsPrimary)
        {
            var currentPrimary = await _db.UserEmergencyContacts
                .Where(c => c.UserId == command.UserId && c.IsPrimary && c.ContactId != command.ContactId)
                .ToListAsync(ct);
            foreach (var primaryContact in currentPrimary)
            {
                primaryContact.IsPrimary = false;
                primaryContact.UpdatedAt = DateTime.UtcNow;
            }
        }

        entity.Name = command.Data.Name.Trim();
        entity.Relationship = command.Data.Relationship.Trim();
        entity.Phone = command.Data.Phone.Trim();
        entity.Email = string.IsNullOrWhiteSpace(command.Data.Email) ? null : command.Data.Email.Trim();
        entity.IsPrimary = command.Data.IsPrimary;
        entity.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync(ct);

        return new EmergencyContactResponse
        {
            ContactId = entity.ContactId,
            Name = entity.Name,
            Relationship = entity.Relationship,
            Phone = entity.Phone,
            Email = entity.Email,
            IsPrimary = entity.IsPrimary,
            CreatedAt = entity.CreatedAt,
            UpdatedAt = entity.UpdatedAt
        };
    }
}

public sealed class DeleteEmergencyContactCommandHandler
    : ICommandHandler<DeleteEmergencyContactCommand, bool>
{
    private readonly MedVaultDbContext _db;

    public DeleteEmergencyContactCommandHandler(MedVaultDbContext db)
    {
        _db = db;
    }

    public async Task<bool> HandleAsync(DeleteEmergencyContactCommand command, CancellationToken ct)
    {
        var entity = await _db.UserEmergencyContacts
            .FirstOrDefaultAsync(c => c.UserId == command.UserId && c.ContactId == command.ContactId, ct);

        if (entity is null)
        {
            return false;
        }

        var wasPrimary = entity.IsPrimary;
        _db.UserEmergencyContacts.Remove(entity);
        await _db.SaveChangesAsync(ct);

        if (wasPrimary)
        {
            var newPrimary = await _db.UserEmergencyContacts
                .Where(c => c.UserId == command.UserId)
                .OrderBy(c => c.CreatedAt)
                .FirstOrDefaultAsync(ct);

            if (newPrimary is not null)
            {
                newPrimary.IsPrimary = true;
                newPrimary.UpdatedAt = DateTime.UtcNow;
                await _db.SaveChangesAsync(ct);
            }
        }

        return true;
    }
}

public sealed class ReplaceEmergencyContactsCommandHandler
    : ICommandHandler<ReplaceEmergencyContactsCommand, IReadOnlyList<EmergencyContactResponse>>
{
    private readonly MedVaultDbContext _db;

    public ReplaceEmergencyContactsCommandHandler(MedVaultDbContext db)
    {
        _db = db;
    }

    public async Task<IReadOnlyList<EmergencyContactResponse>> HandleAsync(
        ReplaceEmergencyContactsCommand command,
        CancellationToken ct)
    {
        var existing = await _db.UserEmergencyContacts
            .Where(c => c.UserId == command.UserId)
            .ToListAsync(ct);
        if (existing.Count > 0)
        {
            _db.UserEmergencyContacts.RemoveRange(existing);
        }

        var contacts = command.Data.Contacts;
        if (contacts.Count > 0 && contacts.All(c => !c.IsPrimary))
        {
            contacts[0] = contacts[0] with { IsPrimary = true };
        }

        var now = DateTime.UtcNow;
        var entities = contacts.Select(data => new UserEmergencyContactEntity
        {
            Id = Guid.NewGuid(),
            UserId = command.UserId,
            ContactId = string.IsNullOrWhiteSpace(data.ContactId)
                ? Guid.NewGuid().ToString("N")
                : data.ContactId!.Trim(),
            Name = data.Name.Trim(),
            Relationship = data.Relationship.Trim(),
            Phone = data.Phone.Trim(),
            Email = string.IsNullOrWhiteSpace(data.Email) ? null : data.Email.Trim(),
            IsPrimary = data.IsPrimary,
            CreatedAt = now,
            UpdatedAt = now
        })
        .ToList();

        if (entities.Count > 0)
        {
            _db.UserEmergencyContacts.AddRange(entities);
        }

        await _db.SaveChangesAsync(ct);

        return entities
            .OrderByDescending(c => c.IsPrimary)
            .ThenBy(c => c.CreatedAt)
            .Select(c => new EmergencyContactResponse
            {
                ContactId = c.ContactId,
                Name = c.Name,
                Relationship = c.Relationship,
                Phone = c.Phone,
                Email = c.Email,
                IsPrimary = c.IsPrimary,
                CreatedAt = c.CreatedAt,
                UpdatedAt = c.UpdatedAt
            })
            .ToList();
    }
}


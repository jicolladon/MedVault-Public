using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using MedVault.API.Common.Models;
using MedVault.API.Features.Auth.Domain;
using MedVault.API.Features.Configuration.Domain;
using MedVault.API.Features.Documents.Domain;
using MedVault.API.Features.Notifications.Domain;
using MedVault.API.Features.Sharing.Domain;
using MedVault.API.Features.UserProfile.Domain;

namespace MedVault.API.Data;

public class MedVaultDbContext : IdentityDbContext<AppUser, IdentityRole<Guid>, Guid>
{
    public MedVaultDbContext(DbContextOptions<MedVaultDbContext> options) : base(options) { }
    public DbSet<RefreshTokenEntity> RefreshTokens => Set<RefreshTokenEntity>();
    public DbSet<UserSessionEntity> UserSessions => Set<UserSessionEntity>();
    public DbSet<BlacklistedTokenEntity> BlacklistedTokens => Set<BlacklistedTokenEntity>();
    public DbSet<UserConsentEntity> UserConsents => Set<UserConsentEntity>();
    public DbSet<UserPreferencesEntity> UserPreferences => Set<UserPreferencesEntity>();
    public DbSet<ProfileChangeHistoryEntity> ProfileChangeHistory => Set<ProfileChangeHistoryEntity>();
    public DbSet<UserEmergencyContactEntity> UserEmergencyContacts => Set<UserEmergencyContactEntity>();
    public DbSet<UserNotificationPreferenceEntity> NotificationPreferences => Set<UserNotificationPreferenceEntity>();
    public DbSet<BackupMetadataEntity> BackupMetadata => Set<BackupMetadataEntity>();
    public DbSet<UserNotificationEntity> UserNotifications => Set<UserNotificationEntity>();
    public DbSet<ShareTokenEntity> ShareTokens => Set<ShareTokenEntity>();
    public DbSet<ShareAccessLogEntity> ShareAccessLogs => Set<ShareAccessLogEntity>();
    public DbSet<ShareAccessApprovalRequestEntity> ShareAccessApprovalRequests => Set<ShareAccessApprovalRequestEntity>();
    public DbSet<AuditLogEntity> AuditLogs => Set<AuditLogEntity>();
    public DbSet<MedicalDocumentEntity> MedicalDocuments => Set<MedicalDocumentEntity>();
    public DbSet<DocumentFileEntity> DocumentFiles => Set<DocumentFileEntity>();
    public DbSet<DocumentFileContentEntity> DocumentFileContents => Set<DocumentFileContentEntity>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);
        builder.ApplyConfigurationsFromAssembly(typeof(MedVaultDbContext).Assembly);
        builder.Entity<AppUser>(e => e.ToTable("Users"));
        builder.Entity<IdentityRole<Guid>>(e => e.ToTable("Roles"));
        builder.Entity<IdentityUserRole<Guid>>(e => e.ToTable("UserRoles"));
        builder.Entity<IdentityUserClaim<Guid>>(e => e.ToTable("UserClaims"));
        builder.Entity<IdentityUserLogin<Guid>>(e => e.ToTable("UserLogins"));
        builder.Entity<IdentityRoleClaim<Guid>>(e => e.ToTable("RoleClaims"));
        builder.Entity<IdentityUserToken<Guid>>(e => e.ToTable("UserTokens"));
    }
}


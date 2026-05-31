using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MedVault.API.Features.Configuration.Domain;
using MedVault.API.Common.Models;

namespace MedVault.API.Features.Configuration.Infrastructure;

public class NotificationPreferenceConfiguration : IEntityTypeConfiguration<UserNotificationPreferenceEntity>
{
    public void Configure(EntityTypeBuilder<UserNotificationPreferenceEntity> builder)
    {
        builder.ToTable("NotificationPreferences");
        builder.HasKey(n => n.Id);

        builder.Property(n => n.Language).HasMaxLength(10);
        builder.Property(n => n.PushDeviceToken).HasMaxLength(2048);
        builder.Property(n => n.QuietHoursStart).HasColumnType("time");
        builder.Property(n => n.QuietHoursEnd).HasColumnType("time");

        builder.HasOne(n => n.User)
            .WithMany()
            .HasForeignKey(n => n.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(n => n.UserId).IsUnique();
    }
}

public class BackupMetadataConfiguration : IEntityTypeConfiguration<BackupMetadataEntity>
{
    public void Configure(EntityTypeBuilder<BackupMetadataEntity> builder)
    {
        builder.ToTable("BackupMetadata");
        builder.HasKey(b => b.Id);

        builder.Property(b => b.BackupType).HasMaxLength(20);
        builder.Property(b => b.Provider).HasMaxLength(50);
        builder.Property(b => b.FilePath).HasMaxLength(2048);
        builder.Property(b => b.Status).HasMaxLength(20);

        builder.HasOne(b => b.User)
            .WithMany()
            .HasForeignKey(b => b.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(b => b.UserId);
    }
}

public class AuditLogConfiguration : IEntityTypeConfiguration<AuditLogEntity>
{
    public void Configure(EntityTypeBuilder<AuditLogEntity> builder)
    {
        builder.ToTable("AuditLogs");
        builder.HasKey(a => a.Id);

        builder.Property(a => a.Action).HasMaxLength(200).IsRequired();
        builder.Property(a => a.EntityType).HasMaxLength(100);
        builder.Property(a => a.EntityId).HasMaxLength(100);
        builder.Property(a => a.Endpoint).HasMaxLength(500);
        builder.Property(a => a.HttpMethod).HasMaxLength(10);
        builder.Property(a => a.IpAddress).HasMaxLength(45);
        builder.Property(a => a.UserAgent).HasMaxLength(1000);
        builder.Property(a => a.AdditionalData).HasColumnType("nvarchar(max)");
        builder.Property(a => a.Timestamp).HasDefaultValueSql("GETUTCDATE()");

        builder.HasIndex(a => a.UserId);
        builder.HasIndex(a => a.Timestamp);
        builder.HasIndex(a => a.Action);
    }
}


using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MedVault.API.Features.UserProfile.Domain;

namespace MedVault.API.Features.UserProfile.Infrastructure;

public class UserPreferencesConfiguration : IEntityTypeConfiguration<UserPreferencesEntity>
{
    public void Configure(EntityTypeBuilder<UserPreferencesEntity> builder)
    {
        builder.ToTable("UserPreferences");
        builder.HasKey(p => p.Id);

        builder.Property(p => p.PrivacyLevel).HasMaxLength(30);
        builder.Property(p => p.NotificationPreferences).HasColumnType("nvarchar(max)");
        builder.Property(p => p.DisplayPreferences).HasColumnType("nvarchar(max)");

        builder.HasOne(p => p.User)
            .WithMany()
            .HasForeignKey(p => p.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(p => p.UserId).IsUnique();
    }
}

public class ProfileChangeHistoryConfiguration : IEntityTypeConfiguration<ProfileChangeHistoryEntity>
{
    public void Configure(EntityTypeBuilder<ProfileChangeHistoryEntity> builder)
    {
        builder.ToTable("ProfileChangeHistory");
        builder.HasKey(h => h.Id);

        builder.Property(h => h.FieldName).HasMaxLength(100).IsRequired();
        builder.Property(h => h.OldValue).HasMaxLength(2000);
        builder.Property(h => h.NewValue).HasMaxLength(2000);
        builder.Property(h => h.IpAddress).HasMaxLength(45);
        builder.Property(h => h.UserAgent).HasMaxLength(1000);

        builder.HasOne(h => h.User)
            .WithMany()
            .HasForeignKey(h => h.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(h => h.UserId);
        builder.HasIndex(h => h.ChangedAt);
    }
}

public class UserEmergencyContactConfiguration : IEntityTypeConfiguration<UserEmergencyContactEntity>
{
    public void Configure(EntityTypeBuilder<UserEmergencyContactEntity> builder)
    {
        builder.ToTable("UserEmergencyContacts");
        builder.HasKey(c => c.Id);

        builder.Property(c => c.ContactId).HasMaxLength(128).IsRequired();
        builder.Property(c => c.Name).HasMaxLength(100).IsRequired();
        builder.Property(c => c.Relationship).HasMaxLength(50).IsRequired();
        builder.Property(c => c.Phone).HasMaxLength(30).IsRequired();
        builder.Property(c => c.Email).HasMaxLength(320);

        builder.HasOne(c => c.User)
            .WithMany()
            .HasForeignKey(c => c.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(c => c.UserId);
        builder.HasIndex(c => new { c.UserId, c.ContactId }).IsUnique();
    }
}


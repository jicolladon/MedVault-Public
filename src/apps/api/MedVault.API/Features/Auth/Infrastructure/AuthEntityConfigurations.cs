using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MedVault.API.Features.Auth.Domain;

namespace MedVault.API.Features.Auth.Infrastructure;

public class AppUserConfiguration : IEntityTypeConfiguration<AppUser>
{
    public void Configure(EntityTypeBuilder<AppUser> builder)
    {
        builder.Property(u => u.GoogleId).HasMaxLength(256);
        builder.HasIndex(u => u.GoogleId).IsUnique().HasFilter("[GoogleId] IS NOT NULL");

        builder.Property(u => u.FirstName).HasMaxLength(100);
        builder.Property(u => u.LastName).HasMaxLength(100);
        builder.Ignore(u => u.FullName);
        builder.Property(u => u.ProfilePictureUrl).HasMaxLength(2048);
        builder.Property(u => u.Gender).HasMaxLength(20);

        builder.Property(u => u.AddressLine1).HasMaxLength(500);
        builder.Property(u => u.AddressLine2).HasMaxLength(500);
        builder.Property(u => u.City).HasMaxLength(100);
        builder.Property(u => u.State).HasMaxLength(100);
        builder.Property(u => u.PostalCode).HasMaxLength(20);
        builder.Property(u => u.Country).HasMaxLength(100);

        builder.Property(u => u.EmergencyContactName).HasMaxLength(200);
        builder.Property(u => u.EmergencyContactPhone).HasMaxLength(30);
        builder.Property(u => u.EmergencyContactRelationship).HasMaxLength(50);
        builder.Property(u => u.BloodType).HasMaxLength(10);

        builder.Property(u => u.AccountStatus).HasMaxLength(20).HasDefaultValue("Active");
        builder.Property(u => u.TimeZone).HasMaxLength(50);
        builder.Property(u => u.Language).HasMaxLength(10);

        builder.Property(u => u.CreatedAt).HasDefaultValueSql("GETUTCDATE()");
        builder.Property(u => u.UpdatedAt).HasDefaultValueSql("GETUTCDATE()");
    }
}

public class RefreshTokenConfiguration : IEntityTypeConfiguration<RefreshTokenEntity>
{
    public void Configure(EntityTypeBuilder<RefreshTokenEntity> builder)
    {
        builder.ToTable("RefreshTokens");
        builder.HasKey(r => r.Id);

        builder.Property(r => r.Token).HasMaxLength(512).IsRequired();
        builder.HasIndex(r => r.Token).IsUnique();

        builder.Property(r => r.DeviceId).HasMaxLength(256);
        builder.Property(r => r.DeviceFingerprint).HasMaxLength(512);
        builder.Property(r => r.RevokedReason).HasMaxLength(500);

        builder.HasOne(r => r.User)
            .WithMany(u => u.RefreshTokens)
            .HasForeignKey(r => r.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(r => r.UserId);
        builder.HasIndex(r => new { r.UserId, r.IsActive });
    }
}

public class UserSessionConfiguration : IEntityTypeConfiguration<UserSessionEntity>
{
    public void Configure(EntityTypeBuilder<UserSessionEntity> builder)
    {
        builder.ToTable("UserSessions");
        builder.HasKey(s => s.Id);

        builder.Property(s => s.SessionToken).HasMaxLength(512).IsRequired();
        builder.HasIndex(s => s.SessionToken).IsUnique();

        builder.Property(s => s.DeviceInfo).HasMaxLength(1000);
        builder.Property(s => s.IpAddress).HasMaxLength(45);
        builder.Property(s => s.UserAgent).HasMaxLength(1000);

        builder.HasOne(s => s.User)
            .WithMany(u => u.Sessions)
            .HasForeignKey(s => s.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(s => s.UserId);
        builder.HasIndex(s => new { s.UserId, s.IsActive });
    }
}

public class BlacklistedTokenConfiguration : IEntityTypeConfiguration<BlacklistedTokenEntity>
{
    public void Configure(EntityTypeBuilder<BlacklistedTokenEntity> builder)
    {
        builder.ToTable("BlacklistedTokens");
        builder.HasKey(b => b.Id);

        builder.Property(b => b.Token).HasMaxLength(512).IsRequired();
        builder.HasIndex(b => b.Token).IsUnique();
        builder.Property(b => b.Reason).HasMaxLength(500);

        builder.HasOne(b => b.User)
            .WithMany()
            .HasForeignKey(b => b.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(b => b.ExpiresAt);
    }
}

public class UserConsentConfiguration : IEntityTypeConfiguration<UserConsentEntity>
{
    public void Configure(EntityTypeBuilder<UserConsentEntity> builder)
    {
        builder.ToTable("UserConsents");
        builder.HasKey(c => c.Id);

        builder.Property(c => c.ConsentType).HasMaxLength(50).IsRequired();
        builder.Property(c => c.IpAddress).HasMaxLength(45);
        builder.Property(c => c.UserAgent).HasMaxLength(1000);
        builder.Property(c => c.ConsentVersion).HasMaxLength(20);

        builder.HasOne(c => c.User)
            .WithMany(u => u.Consents)
            .HasForeignKey(c => c.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(c => new { c.UserId, c.ConsentType });
    }
}


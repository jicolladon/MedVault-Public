using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MedVault.API.Features.Sharing.Domain;

public class ShareTokenConfiguration : IEntityTypeConfiguration<ShareTokenEntity>
{
    public void Configure(EntityTypeBuilder<ShareTokenEntity> builder)
    {
        builder.ToTable("ShareTokens");

        builder.HasKey(e => e.Id);

        builder.HasIndex(e => e.Token).IsUnique();
        builder.HasIndex(e => e.TokenHash).IsUnique().HasFilter("[TokenHash] IS NOT NULL");
        builder.HasIndex(e => e.ShareCode).HasFilter("[ShareCode] IS NOT NULL");
        builder.HasIndex(e => e.UserId);
        builder.HasIndex(e => new { e.UserId, e.IsRevoked, e.ExpiresAt });

        builder.Property(e => e.Token).HasMaxLength(512).IsRequired();
        builder.Property(e => e.TokenHash).HasMaxLength(128);
        builder.Property(e => e.ShareCode).HasMaxLength(8);
        builder.Property(e => e.AccessLevel).HasMaxLength(20).IsRequired();
        builder.Property(e => e.ShareType).HasMaxLength(30).IsRequired();
        builder.Property(e => e.Label).HasMaxLength(200);
        builder.Property(e => e.EncryptedPayload);
        builder.Property(e => e.AccessCount).HasDefaultValue(0);

        builder.HasOne(e => e.User)
            .WithMany()
            .HasForeignKey(e => e.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(e => e.AccessLogs)
            .WithOne(e => e.ShareToken)
            .HasForeignKey(e => e.ShareTokenId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(e => e.AccessApprovalRequests)
            .WithOne(e => e.ShareToken)
            .HasForeignKey(e => e.ShareTokenId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

public class ShareAccessLogConfiguration : IEntityTypeConfiguration<ShareAccessLogEntity>
{
    public void Configure(EntityTypeBuilder<ShareAccessLogEntity> builder)
    {
        builder.ToTable("ShareAccessLogs");

        builder.HasKey(e => e.Id);

        builder.HasIndex(e => e.ShareTokenId);
        builder.HasIndex(e => new { e.ShareTokenId, e.AccessedAt });

        builder.Property(e => e.ViewerName).HasMaxLength(120);
        builder.Property(e => e.ViewerIpAddress).HasMaxLength(50);
        builder.Property(e => e.ViewerUserAgent).HasMaxLength(500);
    }
}

public class ShareAccessApprovalRequestConfiguration : IEntityTypeConfiguration<ShareAccessApprovalRequestEntity>
{
    public void Configure(EntityTypeBuilder<ShareAccessApprovalRequestEntity> builder)
    {
        builder.ToTable("ShareAccessApprovalRequests");

        builder.HasKey(e => e.Id);

        builder.HasIndex(e => e.ShareTokenId);
        builder.HasIndex(e => new { e.ShareTokenId, e.Status, e.ExpiresAt });
        builder.HasIndex(e => new { e.Status, e.ExpiresAt });

        builder.Property(e => e.ViewerName).HasMaxLength(120).IsRequired();
        builder.Property(e => e.ViewerIpAddress).HasMaxLength(50);
        builder.Property(e => e.ViewerUserAgent).HasMaxLength(500);
        builder.Property(e => e.ApprovalCodeHash).HasMaxLength(300).IsRequired();
        builder.Property(e => e.ApprovalCodeHint).HasMaxLength(12).IsRequired();
        builder.Property(e => e.Status).HasConversion<int>();
    }
}


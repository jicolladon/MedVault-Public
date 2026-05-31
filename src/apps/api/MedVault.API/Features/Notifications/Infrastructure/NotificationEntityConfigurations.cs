using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MedVault.API.Features.Notifications.Domain;

namespace MedVault.API.Features.Notifications.Infrastructure;

public sealed class UserNotificationEntityConfiguration : IEntityTypeConfiguration<UserNotificationEntity>
{
    public void Configure(EntityTypeBuilder<UserNotificationEntity> builder)
    {
        builder.ToTable("UserNotifications");
        builder.HasKey(n => n.Id);

        builder.Property(n => n.Type)
            .HasConversion<string>()
            .HasMaxLength(64);

        builder.Property(n => n.Language)
            .HasMaxLength(10);

        builder.Property(n => n.Title)
            .HasMaxLength(200);

        builder.Property(n => n.Subtitle)
            .HasMaxLength(300);

        builder.Property(n => n.Description)
            .HasMaxLength(1000);

        builder.Property(n => n.ActorName)
            .HasMaxLength(200);

        builder.Property(n => n.CreatedAt)
            .HasDefaultValueSql("GETUTCDATE()");

        builder.HasOne(n => n.User)
            .WithMany()
            .HasForeignKey(n => n.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(n => new { n.UserId, n.CreatedAt });
        builder.HasIndex(n => new { n.UserId, n.ReadAt });
    }
}


using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MedVault.API.Features.Documents.Domain;

public class MedicalDocumentEntityConfiguration : IEntityTypeConfiguration<MedicalDocumentEntity>
{
    public void Configure(EntityTypeBuilder<MedicalDocumentEntity> builder)
    {
        builder.ToTable("MedicalDocuments");
        builder.HasKey(e => e.Id);

        builder.Property(e => e.Title).HasMaxLength(240).IsRequired();
        builder.Property(e => e.Description).HasMaxLength(1200);
        builder.Property(e => e.Category).HasMaxLength(120).IsRequired();
        builder.Property(e => e.Tags).HasMaxLength(500);
        builder.Property(e => e.CreatedAt).HasDefaultValueSql("GETUTCDATE()");
        builder.Property(e => e.UpdatedAt).HasDefaultValueSql("GETUTCDATE()");

        builder.HasIndex(e => e.ShareTokenId);
        builder.HasIndex(e => e.UserId);
        builder.HasIndex(e => new { e.UserId, e.CreatedAt });
        builder.HasIndex(e => new { e.UserId, e.Category });
        builder.HasIndex(e => new { e.ShareTokenId, e.CreatedAt });

        builder.HasMany(e => e.Files)
            .WithOne(f => f.Document)
            .HasForeignKey(f => f.DocumentId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(e => e.ShareToken)
            .WithMany()
            .HasForeignKey(e => e.ShareTokenId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

public class DocumentFileEntityConfiguration : IEntityTypeConfiguration<DocumentFileEntity>
{
    public void Configure(EntityTypeBuilder<DocumentFileEntity> builder)
    {
        builder.ToTable("DocumentFiles");
        builder.HasKey(e => e.Id);

        builder.Property(e => e.FileName).HasMaxLength(300).IsRequired();
        builder.Property(e => e.FileExtension).HasMaxLength(10);
        builder.Property(e => e.MimeType).HasMaxLength(120);
        builder.Property(e => e.CreatedAt).HasDefaultValueSql("GETUTCDATE()");
        builder.Property(e => e.UpdatedAt).HasDefaultValueSql("GETUTCDATE()");

        builder.HasIndex(e => e.DocumentId);
        builder.HasIndex(e => new { e.DocumentId, e.SortOrder });

        builder.HasOne(e => e.Content)
            .WithOne(c => c.File)
            .HasForeignKey<DocumentFileContentEntity>(c => c.FileId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

public class DocumentFileContentEntityConfiguration : IEntityTypeConfiguration<DocumentFileContentEntity>
{
    public void Configure(EntityTypeBuilder<DocumentFileContentEntity> builder)
    {
        builder.ToTable("DocumentFileContents");
        builder.HasKey(e => e.FileId);

        builder.Property(e => e.EncryptedPayload).IsRequired();
        builder.Property(e => e.EncryptionKeyId).HasMaxLength(80);
        builder.Property(e => e.CreatedAt).HasDefaultValueSql("GETUTCDATE()");
        builder.Property(e => e.UpdatedAt).HasDefaultValueSql("GETUTCDATE()");

        builder.HasIndex(e => e.CreatedAt);
    }
}

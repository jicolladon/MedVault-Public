using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MedVault.API.Migrations
{
    /// <inheritdoc />
    public partial class AssociateDocumentsToShareToken : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "ShareTokenId",
                table: "MedicalDocuments",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_MedicalDocuments_ShareTokenId",
                table: "MedicalDocuments",
                column: "ShareTokenId");

            migrationBuilder.CreateIndex(
                name: "IX_MedicalDocuments_ShareTokenId_CreatedAt",
                table: "MedicalDocuments",
                columns: new[] { "ShareTokenId", "CreatedAt" });

            migrationBuilder.AddForeignKey(
                name: "FK_MedicalDocuments_ShareTokens_ShareTokenId",
                table: "MedicalDocuments",
                column: "ShareTokenId",
                principalTable: "ShareTokens",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_MedicalDocuments_ShareTokens_ShareTokenId",
                table: "MedicalDocuments");

            migrationBuilder.DropIndex(
                name: "IX_MedicalDocuments_ShareTokenId",
                table: "MedicalDocuments");

            migrationBuilder.DropIndex(
                name: "IX_MedicalDocuments_ShareTokenId_CreatedAt",
                table: "MedicalDocuments");

            migrationBuilder.DropColumn(
                name: "ShareTokenId",
                table: "MedicalDocuments");
        }
    }
}

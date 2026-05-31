using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MedVault.API.Migrations
{

    public partial class AddSharingManagementSecurity : Migration
    {

        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "AccessCount",
                table: "ShareTokens",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "EncryptedPayload",
                table: "ShareTokens",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "LastAccessedAt",
                table: "ShareTokens",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ShareType",
                table: "ShareTokens",
                type: "nvarchar(30)",
                maxLength: 30,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "TokenHash",
                table: "ShareTokens",
                type: "nvarchar(128)",
                maxLength: 128,
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_ShareTokens_TokenHash",
                table: "ShareTokens",
                column: "TokenHash",
                unique: true,
                filter: "[TokenHash] IS NOT NULL");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_ShareTokens_TokenHash",
                table: "ShareTokens");

            migrationBuilder.DropColumn(
                name: "AccessCount",
                table: "ShareTokens");

            migrationBuilder.DropColumn(
                name: "EncryptedPayload",
                table: "ShareTokens");

            migrationBuilder.DropColumn(
                name: "LastAccessedAt",
                table: "ShareTokens");

            migrationBuilder.DropColumn(
                name: "ShareType",
                table: "ShareTokens");

            migrationBuilder.DropColumn(
                name: "TokenHash",
                table: "ShareTokens");
        }
    }
}


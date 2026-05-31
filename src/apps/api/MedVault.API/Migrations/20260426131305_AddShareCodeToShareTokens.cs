using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MedVault.API.Migrations
{

    public partial class AddShareCodeToShareTokens : Migration
    {

        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ShareCode",
                table: "ShareTokens",
                type: "nvarchar(8)",
                maxLength: 8,
                nullable: true);

            migrationBuilder.Sql(
                """
                UPDATE [ShareTokens]
                SET [ShareCode] = UPPER(LEFT(REPLACE(REPLACE([Token], '-', ''), '_', ''), 8))
                WHERE [ShareCode] IS NULL AND [Token] IS NOT NULL;
                """);

            migrationBuilder.CreateIndex(
                name: "IX_ShareTokens_ShareCode",
                table: "ShareTokens",
                column: "ShareCode",
                filter: "[ShareCode] IS NOT NULL");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_ShareTokens_ShareCode",
                table: "ShareTokens");

            migrationBuilder.DropColumn(
                name: "ShareCode",
                table: "ShareTokens");
        }
    }
}


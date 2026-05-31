using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MedVault.API.Migrations
{
    /// <inheritdoc />
    public partial class OptimizeHotPathIndexes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateIndex(
                name: "IX_UserNotifications_UserId_ReadAt",
                table: "UserNotifications",
                columns: new[] { "UserId", "ReadAt" });

            migrationBuilder.CreateIndex(
                name: "IX_ShareTokens_UserId_IsRevoked_ExpiresAt",
                table: "ShareTokens",
                columns: new[] { "UserId", "IsRevoked", "ExpiresAt" });

            migrationBuilder.CreateIndex(
                name: "IX_ShareAccessLogs_ShareTokenId_AccessedAt",
                table: "ShareAccessLogs",
                columns: new[] { "ShareTokenId", "AccessedAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_UserNotifications_UserId_ReadAt",
                table: "UserNotifications");

            migrationBuilder.DropIndex(
                name: "IX_ShareTokens_UserId_IsRevoked_ExpiresAt",
                table: "ShareTokens");

            migrationBuilder.DropIndex(
                name: "IX_ShareAccessLogs_ShareTokenId_AccessedAt",
                table: "ShareAccessLogs");
        }
    }
}

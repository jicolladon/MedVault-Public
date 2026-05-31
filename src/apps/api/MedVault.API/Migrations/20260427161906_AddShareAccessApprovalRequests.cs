using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MedVault.API.Migrations
{

    public partial class AddShareAccessApprovalRequests : Migration
    {

        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "ShareAccessApprovalRequests",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ShareTokenId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ViewerName = table.Column<string>(type: "nvarchar(120)", maxLength: 120, nullable: false),
                    ViewerIpAddress = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                    ViewerUserAgent = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    ApprovalCodeHash = table.Column<string>(type: "nvarchar(300)", maxLength: 300, nullable: false),
                    ApprovalCodeHint = table.Column<string>(type: "nvarchar(12)", maxLength: 12, nullable: false),
                    Status = table.Column<int>(type: "int", nullable: false),
                    RequestedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    DecisionAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ShareAccessApprovalRequests", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ShareAccessApprovalRequests_ShareTokens_ShareTokenId",
                        column: x => x.ShareTokenId,
                        principalTable: "ShareTokens",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ShareAccessApprovalRequests_ShareTokenId",
                table: "ShareAccessApprovalRequests",
                column: "ShareTokenId");

            migrationBuilder.CreateIndex(
                name: "IX_ShareAccessApprovalRequests_ShareTokenId_Status_ExpiresAt",
                table: "ShareAccessApprovalRequests",
                columns: new[] { "ShareTokenId", "Status", "ExpiresAt" });

            migrationBuilder.CreateIndex(
                name: "IX_ShareAccessApprovalRequests_Status_ExpiresAt",
                table: "ShareAccessApprovalRequests",
                columns: new[] { "Status", "ExpiresAt" });
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ShareAccessApprovalRequests");
        }
    }
}


using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MedVault.API.Migrations
{

    public partial class AddPushDeviceTokenToNotificationPreferences : Migration
    {

        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "PushDeviceToken",
                table: "NotificationPreferences",
                type: "nvarchar(2048)",
                maxLength: 2048,
                nullable: true);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "PushDeviceToken",
                table: "NotificationPreferences");
        }
    }
}


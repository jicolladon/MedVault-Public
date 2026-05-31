using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MedVault.API.Migrations
{

    public partial class AddNotificationLocalizationContent : Migration
    {

        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Description",
                table: "UserNotifications",
                type: "nvarchar(1000)",
                maxLength: 1000,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Language",
                table: "UserNotifications",
                type: "nvarchar(10)",
                maxLength: 10,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Subtitle",
                table: "UserNotifications",
                type: "nvarchar(300)",
                maxLength: 300,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Title",
                table: "UserNotifications",
                type: "nvarchar(200)",
                maxLength: 200,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Language",
                table: "NotificationPreferences",
                type: "nvarchar(10)",
                maxLength: 10,
                nullable: true);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Description",
                table: "UserNotifications");

            migrationBuilder.DropColumn(
                name: "Language",
                table: "UserNotifications");

            migrationBuilder.DropColumn(
                name: "Subtitle",
                table: "UserNotifications");

            migrationBuilder.DropColumn(
                name: "Title",
                table: "UserNotifications");

            migrationBuilder.DropColumn(
                name: "Language",
                table: "NotificationPreferences");
        }
    }
}


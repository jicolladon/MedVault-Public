param(
    [Parameter(Mandatory=$true)]
    [string]$MigrationName
)

Write-Host "Adding Entity Framework migration: $MigrationName"
dotnet ef migrations add $MigrationName --project src/apps/api/MedVault.API --startup-project src/apps/api/MedVault.API

Write-Host "To revert this migration, run: Remove-Migration.ps1"

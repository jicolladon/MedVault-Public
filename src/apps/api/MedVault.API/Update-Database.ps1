Write-Host "Updating database schema"
dotnet ef database update --project src/apps/api/MedVault.API --startup-project src/apps/api/MedVault.API

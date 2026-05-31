# Entity Framework Core Migrations

This guide explains how to manage database migrations for the MedVault API project.

## Creating a new Migration

To create a new migration after making changes to entity classes, open a terminal in the root level of the repository (or inside `src/apps/api/MedVault.API/`) and run:

```bash
dotnet ef migrations add <MigrationName> --project src/apps/api/MedVault.API --startup-project src/apps/api/MedVault.API
```

Example: `dotnet ef migrations add AddPatientDataFields --project src/apps/api/MedVault.API --startup-project src/apps/api/MedVault.API`

This will generate the migration files inside `src/apps/api/MedVault.API/Migrations`.

## Applying Migrations

The project is already configured so that it runs latest migrations automatically when it stats up on Development (`app.Environment.IsDevelopment()`).

If you need to apply migrations to a database manually, run:

```bash
dotnet ef database update --project src/apps/api/MedVault.API --startup-project src/apps/api/MedVault.API
```

## Removing the last Migration

If you added a new migration and made a mistake, you can remove it (as long as it wasn't applied to the db yet) by running:

```bash
dotnet ef migrations remove --project src/apps/api/MedVault.API --startup-project src/apps/api/MedVault.API
```

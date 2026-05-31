# ─────────────────────────────────────────────────────────────
# MedVault.API — Multi-stage Docker build
# Build context: repository root (healthId_passport/)
# ─────────────────────────────────────────────────────────────

# === Stage 1: Build ===
FROM mcr.microsoft.com/dotnet/sdk:10.0-preview AS build
WORKDIR /src

# Copy project files first for layer caching
COPY src/apps/api/MedVault.ServiceDefaults/MedVault.ServiceDefaults.csproj src/apps/api/MedVault.ServiceDefaults/
COPY src/apps/api/MedVault.API/MedVault.API.csproj src/apps/api/MedVault.API/
COPY tools/MedVault.DocIntelligence/src/MedVault.DocIntelligence/MedVault.DocIntelligence.csproj tools/MedVault.DocIntelligence/src/MedVault.DocIntelligence/
RUN dotnet restore src/apps/api/MedVault.API/MedVault.API.csproj

# Copy all source files
COPY src/apps/api/MedVault.ServiceDefaults/ src/apps/api/MedVault.ServiceDefaults/
COPY src/apps/api/MedVault.API/ src/apps/api/MedVault.API/
COPY tools/MedVault.DocIntelligence/src/MedVault.DocIntelligence/ tools/MedVault.DocIntelligence/src/MedVault.DocIntelligence/

# Build and publish
RUN dotnet publish src/apps/api/MedVault.API/MedVault.API.csproj \
    -c Release \
    -o /app/publish \
    --no-restore

# === Stage 2: Runtime ===
FROM mcr.microsoft.com/dotnet/aspnet:10.0-preview AS runtime
WORKDIR /app

EXPOSE 8080
EXPOSE 8081

# Non-root user for security
USER $APP_UID

COPY --from=build /app/publish .

ENTRYPOINT ["dotnet", "MedVault.API.dll"]

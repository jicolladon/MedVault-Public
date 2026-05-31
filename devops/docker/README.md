# Docker Setup for MedVault APIs

This folder contains the container setup to run the backend stack locally:

- SQL Server (`sqlserver`)
- MedVault API (`medvault-api`)

## Files in this folder

- `docker-compose.yml`: Orchestrates all services.
- `MedVault.API.Dockerfile`: Builds MedVault API image.
- `.env.example`: Environment variable template.

## Prerequisites

- Docker Desktop (or Docker Engine + Compose plugin)
- At least ~4 GB RAM available for Docker

Validate installation:

```bash
docker --version
docker compose version
```

## Quick start

From repository root (`healthId_passport`):

1. Create your env file:

```bash
copy devops\docker\.env.example devops\docker\.env
```

2. Start all services:

```bash
docker compose -f devops/docker/docker-compose.yml up -d --build
```

3. Check status:

```bash
docker compose -f devops/docker/docker-compose.yml ps
```

4. View logs:

```bash
docker compose -f devops/docker/docker-compose.yml logs -f
```

## Endpoints

- MedVault API: `http://localhost:5100`
- MedVault API Swagger: `http://localhost:5100/swagger`
- SQL Server: `localhost:1433`

## JWT behavior

JWT settings are configured on MedVault API (`Jwt__Key`, issuer, and audience) and are used across all protected endpoints, including document extraction.

## Environment variables

Use `devops/docker/.env` to override defaults.

Common values:

- `SQL_SA_PASSWORD`: SQL Server SA password (must meet SQL complexity rules)
- `JWT_KEY`: Shared JWT signing/validation key
- `API_PORT`, `SQL_PORT`: Host ports
- `GOOGLE_CLIENT_ID`: Optional for Google auth scenarios

## SQL Server notes

- SQL Server runs as `mcr.microsoft.com/mssql/server:2022-latest`.
- Data is persisted in Docker volume `sqlserver-data`.
- MedVault API waits until SQL healthcheck passes before starting.

## Stop and cleanup

Stop containers:

```bash
docker compose -f devops/docker/docker-compose.yml down
```

Stop + remove volumes (deletes local SQL data):

```bash
docker compose -f devops/docker/docker-compose.yml down -v
```

## Rebuild images only

```bash
docker compose -f devops/docker/docker-compose.yml build
```

## Troubleshooting

### Port already in use

Change ports in `devops/docker/.env` (for example `API_PORT=5110`) and restart.

### SQL container unhealthy

- Verify `SQL_SA_PASSWORD` complexity in `.env`
- Check logs:

```bash
docker compose -f devops/docker/docker-compose.yml logs sqlserver
```

### JWT rejected

Ensure `JWT_KEY`, issuer, and audience are configured correctly for MedVault API in Compose/env.

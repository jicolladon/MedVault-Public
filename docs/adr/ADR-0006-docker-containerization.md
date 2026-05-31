# ADR-0006: Standardize Service Packaging With Docker

- Status: Accepted
- Date: 2026-04-06

## Context

MedVault services must run consistently across local development, testing, and cloud environments while supporting repeatable deployments.

## Decision

Adopt Docker containerization for backend and sharing-web services, with local orchestration via Docker Compose.

## Consequences

Positive:

- Environment consistency across team and pipelines.
- Easier deployment portability and rollback strategy.
- Clear service boundaries and runtime dependencies.

Trade-offs:

- Container security and image governance become mandatory responsibilities.
- Local development may require additional resource tuning.

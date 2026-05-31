# ADR-0007: Use Azure As The Primary Hosting Platform

- Status: Accepted
- Date: 2026-04-06

## Context

The system requires managed services for APIs, database, storage, secret management, and observability with clear support for multiple isolated environments.

## Decision

Use Azure as the primary hosting platform for MVP deployment, while preserving architecture portability to equivalent cloud services.

## Consequences

Positive:

- Integrated managed services for application hosting, data, and monitoring.
- Strong support for environment segregation and operational governance.
- Clear path for enterprise-grade scaling.

Trade-offs:

- Platform-specific service configuration knowledge is required.
- Cost governance and resource policy controls must be actively managed.

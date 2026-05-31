# ADR-0002: Use ASP.NET Core For Core Backend Services

- Status: Accepted
- Date: 2026-04-06

## Context

The platform requires secure REST APIs for authentication, profile data, sharing controls, and audit logging. The architecture must support maintainability, testing, and strong security posture.

## Decision

Use ASP.NET Core as the main backend framework for MedVault core APIs.

## Consequences

Positive:

- Mature web API stack with strong performance and tooling.
- Good fit for layered architecture and policy-based security.
- Native compatibility with common enterprise hosting and observability stacks.

Trade-offs:

- Requires disciplined API versioning and contract governance to avoid drift.
- Team must enforce consistent architecture practices across services.

# ADR-0001: Use Flutter As The Mobile Platform

- Status: Accepted
- Date: 2026-04-06

## Context

MedVault needs a mobile-first user experience for patient-owned medical data with support for Android-first delivery and future iOS expansion. The team requires one maintainable codebase and a fast UI iteration cycle.

## Decision

Use Flutter as the primary mobile development framework.

## Consequences

Positive:

- Single codebase for multi-platform evolution.
- Strong UI composition model and rapid feature delivery.
- Good ecosystem for secure storage, notifications, and mobile UX patterns.

Trade-offs:

- Team expertise must stay current with Flutter/Dart ecosystem changes.
- Native platform edge-cases may require platform channel integrations.

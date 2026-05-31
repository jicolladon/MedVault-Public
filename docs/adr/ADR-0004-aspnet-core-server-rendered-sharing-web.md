# ADR-0004: Use Server-Rendered ASP.NET Core For The Sharing Web Portal

- Status: Accepted
- Date: 2026-04-06

## Context

The professional-facing sharing flow must prioritize fast first-render, strict access controls, and low operational overhead in MVP.

## Decision

Implement the sharing web portal using server-rendered ASP.NET Core (Razor Pages or MVC) rather than a separate SPA framework for MVP.

## Consequences

Positive:

- Reduced first-load complexity for urgent access scenarios.
- Strong server-side control over authorization, token expiry, and audit integration.
- Lower runtime and deployment complexity in early phases.

Trade-offs:

- Less client-side interaction flexibility without additional frontend layering.
- Potential future migration effort if rich browser interactions become a priority.

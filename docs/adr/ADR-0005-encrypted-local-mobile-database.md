# ADR-0005: Encrypt On-Device Clinical Data Storage

- Status: Accepted
- Date: 2026-04-06

## Context

MedVault requires offline availability of critical medical data while preserving confidentiality on potentially compromised devices.

## Decision

Use an encrypted local database approach for mobile cached clinical data (for example SQLCipher or equivalent encrypted store).

## Consequences

Positive:

- Stronger data-at-rest protection on-device.
- Enables offline-first emergency access without plain-text persistence.
- Aligns with privacy-by-design expectations.

Trade-offs:

- Key lifecycle management complexity on mobile platforms.
- Additional performance overhead compared to plain local storage.

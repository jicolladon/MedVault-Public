# ADR-0003: Separate Document AI Processing Into Its Own API

- Status: Accepted
- Date: 2026-04-06

## Context

Document OCR and AI extraction workloads have different runtime characteristics, scaling needs, and failure modes compared to transactional profile and sharing operations.

## Decision

Implement document ingestion and extraction as an independent service (`MedVault.Document.API`) separate from the transactional core API.

## Consequences

Positive:

- Independent scaling and deployment cadence.
- Better fault isolation between AI workloads and core transactions.
- Clearer operational ownership and performance tuning.

Trade-offs:

- Additional service boundary and integration complexity.
- Requires careful schema/version governance for extracted payload contracts.

# Contributing to MedVault

Thank you for your interest in contributing to MedVault. This document explains how to make contributions consistent, reviewable, and easy to integrate.

## Before You Start

- Read the project [README.md](README.md) and relevant docs in the `docs/` folder.
- Search existing issues and pull requests to avoid duplication.

## Quick Start

1. Fork the repository and clone your fork.
2. Add the upstream remote (the original repo) and keep your fork in sync.
3. Create a feature branch from `develop`.

Example flow:

```bash
git checkout develop
git pull upstream develop
git checkout -b feature/short-description
# Make changes, run linters/tests
git add .
git commit -m "Short summary of change"
git push origin feature/short-description
# Open a Pull Request targeting the `develop` branch
```

## Branching & Workflow

- Base work on the `develop` branch unless instructed otherwise.
- Branch name patterns:
  - `feature/<short-description>`
  - `fix/<short-description>`
  - `chore/<short-description>`

Keep branches small and focused so reviews stay fast.

## Commit Messages

- Use imperative present tense: `Add user login` (not `Added` or `Adding`).
- Keep the subject line <= 72 characters.
- Format: short title, blank line, optional body explaining why the change was made.

Consider using Conventional Commits (optional): `feat:`, `fix:`, `chore:`, `docs:`.

## Pull Requests

- Target branch: `develop` (unless the issue/maintainer asks otherwise).
- PR title should summarize the change and, if applicable, include the issue number.
- PR description should include:
  - Summary of changes and motivation
  - How to test or reproduce
  - Links to issues or user stories
  - Screenshots or logs for UI/behavior changes

PR Checklist:

- [ ] Tests added or updated for new behavior
- [ ] Linting and formatting passed locally
- [ ] Documentation updated if public APIs changed

Suggested PR template:

```
Summary:

Related issue / Story:

How to test:

Checklist: Tests / Lint / Docs
```

## Filing Issues

- Search existing issues first.
- When filing, include:
  - A concise title
  - Steps to reproduce
  - Expected vs actual behavior
  - Relevant logs, stack traces, and environment (OS, .NET/Flutter versions, etc.)

## Code Style & Linters

- Follow language-specific style in each subproject (see `src/` and `docs/`).
- Run formatters and linters before committing (e.g., `dotnet format`, `flutter format`, `eslint`, etc.).
- Add or modify linter/config files only with justification and approval.

## Testing & Continuous Integration

- Run tests locally in the relevant `tests/` folders before pushing.
- All CI checks must pass before merging. If a test is flaky, open an issue rather than silencing it.

## Documentation

- Update documentation in `docs/`, `final_desing/`, or other relevant markdown files when behavior or public interfaces change.
- Keep user-facing docs (README, QUICKSTART) accurate and minimal.

## Reviews & Approvals

- Be respectful and constructive in code reviews.
- Provide rationale for requested changes; reference style or design guidance when possible.
- Follow repository rules for required reviewers/approvals (maintainers may require more than one approver).

## Security & Secrets

- Never commit secrets, credentials, or private keys to the repository.
- For suspected vulnerabilities or sensitive data exposure, contact maintainers privately if possible.

## Licensing & Code of Conduct

- Contributions are subject to the repository license in the root of this project.
- Abide by any `CODE_OF_CONDUCT.md` present in the repository. Treat all contributors with respect.

## Contact / Maintainers

- If you need help with process decisions, open an issue and tag the maintainers listed in the repository, or use the communication channel referenced in the README.

---

Thank you for improving MedVault — clear, small, and well-tested contributions make it easier for maintainers to review and ship improvements.

# Contributing to LutziVentoyCasts

Thanks for contributing. This project provides precise, reproducible guides/casts around Ventoy workflows (creation, troubleshooting, persistence, secure boot, multi-ISO hygiene). Keep contributions accurate, minimal, and verifiable.

## Quick Path
1. **Open an issue** (bug/feature/content) before large changes.
2. **Fork** and create a branch: `feature/<short>` or `fix/<short>`.
3. **Keep PRs small** and focused. Link the issue: `Fixes #123`.
4. Pass **lint/tests/build** locally. Include demo logs or screenshots for tutorials.

## Scope & Quality Bar
- Tutorials and scripts must be **repeatable** on a clean host.
- Document **host OS**, **Ventoy version**, **firmware/secure boot settings**, and **hardware caveats**.
- Prefer **evidence-based** steps (hashes, command outputs, screenshots).
- Security-sensitive content (e.g., signed boot chains, shim/MOK) must include a **threat model** and rollback plan.

## Repo Layout
- `casts/`        – Markdown transcripts, step lists, and assets per cast
- `scripts/`      – Helper scripts used in casts (idempotent, with `--dry-run`)
- `assets/`       – Images/diagrams used in docs
- `tests/`        – Script tests and link checks
- `docs/`         – Reference material and FAQs

## Dev Setup
- git clone https://github.com/LutziGoz/LVC-LutziVentoyCasts.git
- cd LutziVentoyCasts
- python -m venv .venv && source .venv/bin/activate
- pip install -U pip wheel
- pip install -r requirements.txt
- pre-commit install  # optional, recommended

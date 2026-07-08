# Security Policy

## Supported versions

This project is pre-1.0 and released from `main`. Security fixes are applied to
the latest release line only.

| Version | Supported |
| ------- | --------- |
| 0.6.x   | ✅        |
| < 0.6   | ❌        |

## Reporting a vulnerability

**Please do not report security vulnerabilities through public GitHub issues,
discussions, or pull requests.**

Instead, use GitHub's private vulnerability reporting:

1. Go to the [Security tab](https://github.com/CyberdyneCorp/excalidraw-native/security/advisories/new).
2. Click **Report a vulnerability** and provide the details below.

Please include, where possible:

- The affected component (iOS/Swift, web/TypeScript, Android/Kotlin, or the
  collaboration relay) and version/commit.
- A description of the issue and its impact.
- Steps to reproduce or a proof of concept.
- Any suggested remediation.

We will acknowledge your report, keep you informed of progress, and coordinate a
fix and disclosure timeline with you. Please give us a reasonable window to
address the issue before any public disclosure.

## Scope notes

Some deployment-affecting limitations are known and documented in the README's
**Known gaps**, and are not considered vulnerabilities on their own:

- The collaboration relay stores scene state **in memory** (no durable
  persistence) and does **not** provide end-to-end encryption.
- The Android client's collaboration transport currently uses cleartext
  `ws://` and a demo relay URL; use a `wss://` relay and appropriate transport
  security for any non-local deployment.

Reports that harden these areas are welcome.

# Contributing to excalidraw-native

Thanks for your interest in contributing! This repo hosts three from-scratch
native ports of [Excalidraw](https://excalidraw.com) — **iOS/Swift**,
**web/TypeScript + Svelte**, and **Android/Kotlin** — that share the
`.excalidraw` file format, a custom real-time collaboration protocol, and a
language-neutral [OpenSpec](openspec/) contract.

## Ground rules

- **Behavior is specified once, in OpenSpec.** Any change to observable behavior
  (a new capability, a changed requirement) goes through an OpenSpec change in
  [`openspec/`](openspec/) and then lands in the relevant client(s). Run
  `openspec validate --specs` before opening a PR.
- **Every bug fix ships with a regression test** in the same PR.
- **Update the docs/specs** when behavior changes (README, `docs/`, or the
  affected OpenSpec spec).
- **Keep the clients in parity.** The three implementations are kept behaviorally
  aligned by shared specs and fixtures; a change to shared behavior should be
  reflected (or explicitly scoped) across the affected clients.

## Project layout

```
Sources/ · App/      iOS / iPadOS (Swift / SwiftUI)
web/                 web client + packages + Node relay (pnpm workspace)
android/             Android client (Kotlin + Jetpack Compose, Gradle)
openspec/            the cross-language behavioral contract
Fixtures/            shared golden fixtures asserted by every client
```

## Building & testing

### iOS / Swift
```bash
swift build
swift test
# or the coverage-gated run used in CI:
./scripts/coverage.sh 90
```
Lint/format: `swiftlint lint --strict` and `swiftformat --lint .`.

### Web (TypeScript + Svelte)
```bash
cd web
pnpm install --frozen-lockfile
pnpm build:libs
pnpm typecheck
pnpm test          # unit tests
# end-to-end (needs Playwright browsers):
pnpm --filter excalidraw-web-app exec playwright install --with-deps chromium
pnpm --filter excalidraw-web-app test:e2e
```
Format: `pnpm biome format --write .`.

### Android (Kotlin + Compose)
```bash
cd android
./gradlew test            # pure-JVM unit tests (all modules)
./gradlew assembleDebug   # build the debug APK
```
Live-collaboration integration tests are opt-in — start the Node relay
(`node web/server/dist/index.js`, or `pnpm --filter @cyberdynecorp/... build`
first) and run with `RELAY_URL=ws://127.0.0.1:3001 ./gradlew :collab-kotlin:test`.

## Pull requests

1. Branch off `main`.
2. Make the change **plus its tests**; update specs/docs if behavior changed.
3. Ensure the relevant suite is green locally (CI runs Swift, web, and Android).
4. Use clear, conventional commit subjects (`feat:`, `fix:`, `docs:`, `chore:`,
   `ci:`, `test:`); describe **what changed and why** in the body.
5. Open the PR with a descriptive body (the template will prompt you).

## Reporting bugs / requesting features

Open an issue using the provided templates. For security issues, **do not open a
public issue** — see [SECURITY.md](SECURITY.md).

By contributing, you agree that your contributions are licensed under the
repository's [MIT License](LICENSE).

## Context

The product today is two clients over one shared design:

- **iOS/Swift** — a pure, UI-free core (`ExcalidrawMath → ExcalidrawModel →
  ExcalidrawGeometry · RoughKit · FreehandKit → ExcalidrawRender →
  ExcalidrawMetal · ExcalidrawEditor → ExcalidrawUI`) with a SwiftUI shell.
- **web/Svelte** — the Svelte 5 `web-client` host wrapping the same shared editor
  behavior (via the TS packages), exercised by the same behavioral capability
  specs.

Both interoperate through two contracts: the `.excalidraw` **file format** and
the **Yjs collaboration wire protocol** (`collaboration`, `collaboration-yjs`).

Android has no native client. The decision (confirmed with the maintainer) is a
**full independent Kotlin + Jetpack Compose rewrite** — no Swift reuse, no
cross-compilation, no WebView. The two shared contracts are the only things
Android reuses, and it reuses them as *specifications*, not code.

Constraints:
- Must satisfy the existing platform-agnostic behavioral specs (`data-model`,
  `drawing-tools`, `selection-and-transform`, `editing-history`,
  `hand-drawn-rendering`, `scene-rendering`, `file-format`, `collaboration`,
  `collaboration-yjs`) as a *conformance target*, reimplemented in Kotlin.
- Must render on-device with touch + stylus ergonomics comparable to iOS.
- Must sync live and losslessly with existing iOS/web peers — a mixed room must
  converge.

## Goals / Non-Goals

**Goals:**
- A native, offline-capable Android editor with full v1 parity: all drawing
  tools, selection/transform, undo/redo, hand-drawn rendering, export.
- Live Yjs collaboration interoperable with iOS and web in the same room.
- `.excalidraw` round-trip fidelity: scenes authored on any client open on
  Android unchanged, and Android-authored scenes open elsewhere unchanged
  (including unmodelled fields via `customData`/appState passthrough).
- A Kotlin module graph mirroring the Swift core's layering, so the shared specs
  map cleanly onto Kotlin modules and stay independently testable.

**Non-Goals:**
- Reusing or cross-compiling the Swift/TypeScript code (explicitly rejected).
- A GPU (Vulkan) rendering backend in v1 — Compose Canvas (Skia) only; a GPU
  backend is a possible later change, mirroring how Metal is optional on iOS.
- Changing the `.excalidraw` format or the Yjs wire protocol. Android conforms to
  them as-is; any ambiguity is resolved by matching observed iOS/web behavior.
- SDF/GPU text, incremental-redraw GPU optimizations (out of scope, as on iOS).
- Tablet/foldable-specific adaptive layouts beyond what parity requires (a later
  change, analogous to iOS iPad adaptivity).

## Decisions

### Decision: Independent Kotlin rewrite over cross-compilation or Skip
Reimplement the core in Kotlin rather than cross-compiling the Swift core (Swift
Android SDK/NDK) or transpiling SwiftUI with Skip.
- **Why:** The maintainer selected an independent rewrite. It avoids a bleeding-
  edge Swift-on-Android toolchain in the release path, keeps the Android app on
  idiomatic Kotlin/Compose that Android developers can own, and decouples Android
  release cadence from the Swift build. The shared *specs* (not shared code) keep
  the two implementations aligned.
- **Alternatives considered:** (a) Swift core + Kotlin UI over JNI — max code
  reuse but ties Android to an immature toolchain and a C ABI boundary; (b) Skip
  transpile — highest UI reuse but couples us to Skip's SwiftUI subset and its
  release cadence; (c) Kotlin Multiplatform — the core is Swift, not Kotlin, so
  KMP offers no reuse without a rewrite anyway.
- **Trade-off:** Two implementations of the same behavior must be kept in sync.
  Mitigated by the shared behavioral specs being the single source of truth and
  by cross-client golden/interop tests in CI.

### Decision: Kotlin module graph mirrors the Swift core layering
```
android/
  core-math/        (ExcalidrawMath analogue: points, vectors, transforms)
  core-model/       (ExcalidrawModel: element model + .excalidraw coding,
                     lenient decode, customData/appState passthrough)
  core-geometry/    (ExcalidrawGeometry: hit-testing, bounds, curves)
  rough-kotlin/     (RoughKit port: hachure/fills, sloppiness, seeded RNG)
  freehand-kotlin/  (FreehandKit/perfect-freehand port: pressure outlines)
  render-compose/   (scene renderer on Compose Canvas / Skia)
  editor/           (ExcalidrawEditor analogue: pure, Compose-free state machine)
  collab-yjs/       (Yjs adapter: id-keyed map, tombstones, fractional index)
  app/              (Jetpack Compose UI host, input, navigation, export)
```
- **Why:** Each Kotlin module maps 1:1 onto an existing capability spec, so the
  behavioral specs are directly testable per module and the `editor` module stays
  UI-free (mirroring the Swift `ExcalidrawEditor` "no core coupling" rule). This
  makes the "reimplement to the same spec" contract mechanically checkable.

### Decision: Compose Canvas (Skia) as the sole v1 renderer
Render the scene with Jetpack Compose's `Canvas`/`drawWithCache` (Skia) using a
layered cache strategy analogous to the iOS Core Graphics `SceneRenderer`.
- **Why:** Skia gives crisp vector rendering, matches the "Core Graphics default,
  Metal optional" iOS shape, and avoids a GPU backend in v1. Text stays on a
  Compose text layer (never rasterized into the vector cache), matching the iOS
  "text never tessellated to GPU" rule for crispness at any zoom.
- **Alternative considered:** Android `View`/`Canvas` (older API) — rejected for
  worse composability with the Compose UI shell.

### Decision: Yjs interop via a Kotlin y-crdt binding, conforming to the existing wire protocol
Use a Kotlin/JVM binding to y-crdt (Yjs' Rust core) — or a vetted Kotlin Yjs
port — behind a `collab-yjs` adapter that implements the same document shape the
`collaboration-yjs` spec mandates: an id-keyed per-element map, soft-delete
tombstones, and fractional index as the z-order source of truth.
- **Why:** The wire protocol and CRDT document shape are fixed by the existing
  clients. Reusing a real y-crdt implementation guarantees update/merge
  compatibility so a mixed iOS/web/Android room converges. The adapter keeps CRDT
  concerns out of the `editor` module (the spec's "no core coupling" rule).
- **Trade-off:** Adds a native (JNI) dependency if using the Rust core. Mitigated
  by isolating it behind the `collab-yjs` module and covering it with cross-peer
  interop tests.

### Decision: Conformance proven by cross-client tests, not by shared code
Parity is enforced with (a) per-module Kotlin unit tests against the behavioral
specs, (b) golden round-trip tests that load a corpus of iOS/web-authored
`.excalidraw` scenes and assert byte-meaningful equivalence after decode/encode,
and (c) a live cross-peer collaboration test where an Android client and an
iOS/web client edit the same room and must converge.
- **Why:** With no shared code, tests are the only guarantee the two
  implementations stay aligned. The golden corpus is shared across clients.

## Risks / Trade-offs

- **Two implementations drift** → Shared behavioral specs are the single source
  of truth; cross-client golden + interop tests run in CI on every change; any
  divergence is a failing test, not a silent bug.
- **Hand-drawn look diverges from iOS/web** (independent rough/freehand ports) →
  Golden-image tolerance tests against reference renders; accept "visually
  faithful, not line-identical" (same standard the iOS specs already set).
- **Yjs binding maturity / JNI complexity on Android** → Prefer the vetted y-crdt
  core behind a thin adapter; gate collaboration behind interop tests; fall back
  to a pure-Kotlin Yjs port only if it passes the same cross-peer convergence
  suite.
- **`.excalidraw` unmodelled-field loss** (a common rewrite bug) → The
  `data-model` "lossless preservation" requirement is a hard conformance target;
  round-trip tests assert `customData`/appState passthrough.
- **Scope creep from "full parity"** → v1 parity is bounded to the enumerated
  shared specs; adaptive tablet layouts, GPU backend, and SDF text are explicit
  non-goals deferred to later changes.

## Migration Plan

Additive only — no change to existing clients or contracts.
1. Land the `android/` Gradle project skeleton and module graph (no behavior).
2. Implement `core-math`, `core-model` (+ `.excalidraw` coding), `core-geometry`
   with unit tests; prove round-trip against the shared golden corpus.
3. Implement `rough-kotlin`, `freehand-kotlin`, `render-compose`; golden-image
   tests.
4. Implement `editor` (UI-free) + the Compose `app` host; parity UI tests.
5. Implement `collab-yjs`; cross-peer interop test against iOS/web.
6. Add the Android CI job (assemble, unit, instrumented/UI, ktlint/detekt,
   golden round-trip, interop).
7. Update `openspec/project.md` baseline to multi-platform.

Rollback: the Android module is self-contained; dropping the `android/` tree and
its CI job removes it with zero impact on iOS/web.

## Open Questions

- Which Yjs implementation on Android — a JNI binding to the y-crdt Rust core, or
  a pure-Kotlin Yjs port? Decide by running both through the cross-peer
  convergence suite; pick the one that passes with the least footprint.
- Export formats for v1 — confirm parity set (PNG and `.excalidraw` at minimum;
  SVG parity with iOS TBD).
- Minimum Android API level and stylus support matrix (target modern Compose;
  pin the floor during skeleton bring-up).

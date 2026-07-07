## Why

The product ships an iOS/Swift app and a Svelte web client that share one pure
editor core plus a common `.excalidraw` file format and Yjs collaboration wire
protocol. Android — the largest remaining mobile platform — has no first-class
client. We want a native Android app so Android users get the same finger- and
stylus-friendly editor and can collaborate live with iOS and web peers, not a
wrapped WebView.

## What Changes

- Introduce a **native Android client**, built as an **independent Kotlin +
  Jetpack Compose application** (`android/` module tree). It does **not** reuse
  the Swift core; it is a ground-up reimplementation in Kotlin.
- The client renders with **Compose Canvas (Skia)** and targets **full editor
  parity with the iOS app**: all drawing tools, selection/transform, editing
  history (undo/redo), hand-drawn rendering, and export.
- Port the hand-drawn look to Kotlin: a **Kotlin rough.js port** (hachure/fills,
  sloppiness, seeded RNG) and a **perfect-freehand port** (pressure outlines),
  visually faithful to the existing renderers.
- Implement **live Yjs real-time collaboration** so Android peers join the same
  rooms and sync bidirectionally with iOS and web peers over the existing wire
  protocol.
- The two shared cross-client contracts — the **`.excalidraw` file format** and
  the **Yjs collaboration wire protocol** — become explicit, client-agnostic
  interop contracts that the Android reimplementation MUST satisfy (round-trip
  and cross-peer conformance).
- Update the OpenSpec **baseline context** (`openspec/project.md`): the project
  is no longer iOS-only — it is a multi-platform product (iOS/Swift, web/Svelte,
  Android/Kotlin) unified by the shared format and wire protocol. The existing
  Swift/iOS baseline specs remain intact and authoritative for the Swift core.

## Capabilities

### New Capabilities
- `android-client`: The Kotlin + Jetpack Compose Android host and its
  Android-specific obligations — Compose Canvas (Skia) rendering, touch/stylus
  input and navigation, an independent Kotlin reimplementation that MUST match
  the shared behavioral specs (`data-model`, `drawing-tools`,
  `selection-and-transform`, `editing-history`, `hand-drawn-rendering`,
  `scene-rendering`), `.excalidraw` file-format round-trip conformance, Yjs
  collaboration interop with iOS/web peers, and export. Analogous to
  `web-client`, but reimplements (rather than wraps) the shared behavior.

### Modified Capabilities
<!-- None. The shared behavioral capabilities (data-model, file-format,
     collaboration, collaboration-yjs, drawing-tools, selection-and-transform,
     editing-history, hand-drawn-rendering, scene-rendering) already describe
     platform-agnostic behavior and cross-engine/cross-client contracts; Android
     conformance is asserted inside the new `android-client` spec rather than by
     changing their requirements. `openspec/project.md` is baseline context, not
     a capability spec, and is updated as part of this change's tasks. -->

## Impact

- **New code:** `android/` Gradle project — Kotlin/Compose app module, a Kotlin
  domain/model module (`.excalidraw` element model + coding), a Kotlin geometry
  module, Kotlin ports of rough.js and perfect-freehand, a Compose Canvas
  renderer, an editor state machine, and a Yjs collaboration adapter (via a
  Kotlin Yjs/y-crdt binding or equivalent).
- **Contracts (unchanged behavior, now cross-client):** `.excalidraw` file
  format and the Yjs collaboration wire protocol. No changes to the Swift or web
  clients are required for parity; any protocol clarifications discovered during
  interop testing are captured as conformance requirements, not protocol changes.
- **Docs / baseline:** `openspec/project.md` updated to describe the
  multi-platform architecture and the Android target.
- **CI:** a new Android job (Gradle assemble + unit tests + instrumented/UI
  tests + ktlint/detekt) added alongside the existing Swift and web jobs. Golden
  cross-client round-trip tests (open iOS/web-authored scenes on Android and
  vice versa) and a live cross-peer collaboration test.
- **Dependencies:** Android SDK/NDK toolchain, Jetpack Compose, a Kotlin Yjs
  binding, Gradle.

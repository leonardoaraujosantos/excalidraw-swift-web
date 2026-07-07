## Why

The product ships an iOS/Swift app and a Svelte web client that share the
`.excalidraw` file format and a **custom versioned-reconciliation WebSocket
protocol** (protocol v1) for real-time collaboration. Android — the largest
remaining mobile platform — has no first-class client. We want a native Android
app so Android users get the same finger- and stylus-friendly editor and can
collaborate live with iOS and web peers, not a wrapped WebView.

> **Note on the collaboration contract.** The iOS↔web interop path is **not**
> Yjs. iOS (`ExcalidrawCollab`) is pure Swift over a `URLSessionWebSocketTask`,
> and web (`excalidraw-svelte/protocol`) is pure TypeScript over a `WebSocket`;
> both speak the same JSON `Message` union (protocol v1) and reconcile elements
> by last-writer-wins on `(version desc, versionNonce asc)`. Yjs
> (`@cyberdynecorp/excalidraw-yjs`) is an **optional, web-only** provider adapter
> — not the cross-client contract. Android therefore needs **no NDK and no CRDT
> library**: it reimplements the same JSON WebSocket protocol in pure Kotlin.

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
- Implement **live real-time collaboration in pure Kotlin** — a reimplementation
  of the existing **custom WebSocket protocol** (protocol v1: `join`,
  `room-state`, `peer-joined/left`, `presence`, `pointer`, `element-updates`,
  `scene-snapshot`, `ping`/`ack`) plus the shared last-writer-wins reconcile
  (`version`/`versionNonce`) — so Android peers join the same rooms and converge
  bidirectionally with iOS and web peers through the existing Node relay. No NDK,
  no Yjs/CRDT dependency.
- The two shared cross-client contracts — the **`.excalidraw` file format** and
  the **custom versioned-reconciliation WebSocket protocol** — become explicit,
  client-agnostic interop contracts that the Android reimplementation MUST
  satisfy (round-trip and cross-peer conformance).
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
  `scene-rendering`), `.excalidraw` file-format round-trip conformance,
  collaboration interop with iOS/web peers over the custom WebSocket protocol
  (protocol v1 + LWW reconcile), and export. Analogous to `web-client`, but
  reimplements (rather than wraps) the shared behavior.

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
  renderer, an editor state machine, and a pure-Kotlin **collaboration module**
  (`collab-kotlin`): the protocol-v1 `Message` codec, the LWW `reconcile`, and a
  WebSocket client (OkHttp).
- **Contracts (unchanged behavior, now cross-client):** the `.excalidraw` file
  format and the custom versioned-reconciliation WebSocket protocol (v1). No
  changes to the Swift or web clients are required for parity; any protocol
  clarifications discovered during interop testing are captured as conformance
  requirements, not protocol changes.
- **Docs / baseline:** `openspec/project.md` updated to describe the
  multi-platform architecture and the Android target.
- **CI:** a new Android job (Gradle assemble + unit tests + instrumented/UI
  tests + ktlint/detekt) added alongside the existing Swift and web jobs. Golden
  cross-client round-trip tests (open iOS/web-authored scenes on Android and
  vice versa) and a live cross-peer collaboration test against the Node relay.
- **Dependencies:** Android SDK toolchain, Jetpack Compose, OkHttp (WebSocket),
  Gradle. **No NDK, no Yjs/CRDT library.**

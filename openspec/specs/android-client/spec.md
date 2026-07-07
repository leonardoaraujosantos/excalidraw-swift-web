# android-client Specification

## Purpose
TBD - created by archiving change add-native-android-client. Update Purpose after archive.
## Requirements
### Requirement: Native Kotlin/Compose Android host

The system SHALL provide a native Android client implemented as an independent
Kotlin + Jetpack Compose application, without reusing or cross-compiling the
Swift or TypeScript code. The client SHALL be organized as a Kotlin module graph
mirroring the shared core layering (math → model → geometry · rough · freehand →
render → editor → collab → app), where the editor state machine module is
Compose-free (no UI-framework coupling), analogous to `ExcalidrawEditor`.

#### Scenario: App launches to an editable canvas
- **WHEN** the Android app is launched on a supported device
- **THEN** it SHALL present an interactive drawing canvas backed by the Kotlin
  editor state machine, with no dependency on a WebView or on Swift-compiled code

#### Scenario: Editor core is UI-framework-free
- **GIVEN** the Kotlin editor module
- **WHEN** its unit tests run
- **THEN** they SHALL exercise editing behavior with no Jetpack Compose or
  Android UI dependency, matching the shared editor "no core coupling" contract

### Requirement: Compose Canvas (Skia) scene rendering

The Android client SHALL render the scene using Jetpack Compose Canvas (Skia)
with a layered caching strategy, SHALL keep text on a Compose text layer rather
than rasterizing it into the vector cache (so text stays crisp at any zoom), and
SHALL match the shared `scene-rendering` behavior. A GPU (Vulkan) backend is out
of scope for v1.

#### Scenario: Scene renders with cached vector layers
- **GIVEN** a loaded scene with shapes, freehand strokes, and text
- **WHEN** the canvas is drawn and then panned/zoomed
- **THEN** vector elements SHALL render through the Skia layer cache and text
  SHALL remain crisp (not pixelated) at increased zoom

#### Scenario: Rendering matches the shared renderer within tolerance
- **GIVEN** a reference scene and its golden render from the iOS/web renderer
- **WHEN** the Android renderer draws the same scene
- **THEN** the output SHALL match the golden within the accepted visual tolerance
  (visually faithful, not required to be line-identical)

### Requirement: Full editor parity with drawing, selection, transform, and history

The Android client SHALL reimplement, in Kotlin, the shared behavioral
capabilities to full v1 parity with the iOS app: all drawing tools
(`drawing-tools`), selection and transform (`selection-and-transform`), and
editing history with undo/redo (`editing-history`). These reimplementations
SHALL satisfy the same platform-agnostic requirements as the Swift core.

#### Scenario: Create, select, transform, and undo
- **GIVEN** the Android editor
- **WHEN** the user draws a shape, selects it, moves/resizes it, then invokes undo
- **THEN** each drawing tool SHALL produce the same element model as the shared
  spec requires, selection/transform SHALL behave per `selection-and-transform`,
  and undo/redo SHALL restore prior states per `editing-history`

#### Scenario: Touch and stylus input
- **GIVEN** a device with touch and stylus
- **WHEN** the user draws with a finger and with a stylus (including pressure)
- **THEN** the client SHALL route both to the active tool, using stylus pressure
  for freehand stroke width where the tool supports it

### Requirement: Kotlin hand-drawn rendering (rough.js and perfect-freehand ports)

The Android client SHALL include Kotlin ports of the rough.js hand-drawn
generator (hachure and solid fills, sloppiness/roughness, seeded RNG for stable
regeneration) and of perfect-freehand (pressure-based stroke outlines), producing
output visually faithful to the shared `hand-drawn-rendering` capability.

#### Scenario: Seeded roughness is stable
- **GIVEN** an element with a fixed roughness seed
- **WHEN** it is regenerated across renders
- **THEN** the hand-drawn geometry SHALL be identical for the same seed (stable,
  not re-randomized each frame)

#### Scenario: Freehand stroke follows pressure
- **GIVEN** a freehand stroke captured with varying pressure
- **WHEN** it is outlined by the Kotlin perfect-freehand port
- **THEN** the outline width SHALL vary with pressure, matching the shared
  freehand behavior within visual tolerance

### Requirement: `.excalidraw` file-format round-trip conformance

The Android client SHALL read and write the `.excalidraw` file format per the
shared `file-format` and `data-model` specs, including lenient decoding of
missing keys (defaults rather than failure) and lossless preservation of
unmodelled data (element `customData` and unknown app-state keys). Scenes
authored on any client SHALL open on Android unchanged, and Android-authored
scenes SHALL open on iOS/web unchanged.

#### Scenario: Cross-client scene opens unchanged
- **GIVEN** a `.excalidraw` scene authored on iOS or the web client
- **WHEN** it is opened on Android and re-saved without edits
- **THEN** all modelled elements SHALL render equivalently and all unmodelled
  fields (`customData`, unknown app-state keys) SHALL survive the round-trip
  unchanged

#### Scenario: Partial/older file loads with defaults
- **GIVEN** a `.excalidraw` file that omits some keys (older or partial schema)
- **WHEN** it is opened on Android
- **THEN** the missing keys SHALL take default values and the scene SHALL load
  rather than failing

### Requirement: Live collaboration interop with iOS and web peers

The Android client SHALL join collaboration rooms over the existing custom
WebSocket protocol (protocol v1) and SHALL interoperate with iOS and web peers in
the same room through the existing Node relay. It SHALL implement the shared
`Message` union in pure Kotlin — `join`, `room-state`, `peer-joined`,
`peer-left`, `presence`, `pointer`, `element-updates`, `scene-snapshot`, `ping`,
`ack` — encoded as JSON that is wire-compatible with the Swift and TypeScript
clients (the room is selected by the `join` message, not the URL). It SHALL
reconcile concurrent edits by the shared last-writer-wins rule — higher
`version` wins, ties break on the lower `versionNonce` — so mixed-client edits
converge on all peers with no CRDT and no central authority. Local edits SHALL
bump `version` and assign a fresh `versionNonce` before broadcast as
`element-updates`. Transport and reconcile concerns SHALL be isolated from the
editor core (no core coupling). The Android client SHALL NOT require Yjs, a CRDT
library, or the NDK.

#### Scenario: Mixed-client room converges
- **WHEN** an Android client and an iOS or web client edit the same room
  concurrently (add, move, delete)
- **THEN** each edit is broadcast as `element-updates` with a bumped
  `version`/`versionNonce`, and after exchange all peers SHALL reconcile to the
  same element set by the shared last-writer-wins rule

#### Scenario: Late joiner receives full state
- **GIVEN** an existing room with content authored by iOS/web peers
- **WHEN** an Android client sends `join`
- **THEN** the relay SHALL reply with `room-state` carrying the current roster
  and scene, and the Android client SHALL render it and then stay in sync with
  subsequent `element-updates`

#### Scenario: Wire compatibility with the shared protocol
- **GIVEN** a protocol-v1 JSON message produced by the Swift or TypeScript client
- **WHEN** the Android codec decodes it, and re-encodes an equivalent message
- **THEN** the message SHALL decode without loss and the re-encoded form SHALL be
  accepted by the relay and the other clients (byte-compatible canonical JSON)

### Requirement: Export

The Android client SHALL export the current scene to at least PNG and
`.excalidraw`, producing files openable by the other clients. Exported
`.excalidraw` SHALL preserve unmodelled data per the round-trip requirement.

#### Scenario: Export to PNG and .excalidraw
- **GIVEN** a scene on the Android canvas
- **WHEN** the user exports to PNG and to `.excalidraw`
- **THEN** the PNG SHALL depict the rendered scene and the `.excalidraw` file
  SHALL open on iOS/web with all modelled and unmodelled data intact


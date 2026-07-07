# Excalidraw — Android client (Kotlin + Jetpack Compose)

An independent native Android reimplementation of Excalidraw. It shares **no
code** with the Swift/iOS or web clients — only the two cross-client contracts:
the `.excalidraw` file format and the custom versioned-reconciliation WebSocket
collaboration protocol (protocol v1; **not** Yjs). See
`openspec/specs/android-client/spec.md` and the `add-native-android-client`
OpenSpec change for the behavioral contract, and `../openspec/project.md` for
the multi-platform overview.

## Status — single-user editor + live collaboration (verified on emulator)

- `.excalidraw` model with **lenient decode** (missing keys default; tolerant
  arrow bindings) and **lossless round-trip** of unmodelled data
  (`customData`, unknown app-state keys) — unit-tested in `:core-model`.
- Compose **Canvas (Skia)** renderer for rectangle, ellipse, diamond, line,
  arrow, freedraw, and text; text stays on the Compose text layer (crisp at any
  zoom).
- Interactive editor loop: pan/pinch-zoom (Select), and drag-to-create for
  rectangle / ellipse / diamond plus freehand Draw.
- **Hand-drawn look:** Kotlin ports of rough.js (`:rough-kotlin` — sketchy
  strokes + hachure fills, seeded RNG) and perfect-freehand (`:freehand-kotlin`
  — variable-width ink outlines), wired into the renderer. Unit-tested (9 + 6
  tests).
- **Selection/transform + history:** `:editor` (pure, Compose-free) — tap-select,
  drag-move, corner-handle resize, undo/redo, soft-delete. (8 tests)
- **Export:** PNG (rasterized from the renderer) + `.excalidraw` (lossless).
- **Live collaboration:** `:collab-kotlin` — a pure-Kotlin reimplementation of
  the custom protocol-v1 WebSocket JSON codec + last-writer-wins reconcile +
  OkHttp client. **No NDK, no Yjs/CRDT.** Interoperates with the iOS and web
  clients through the existing Node relay (verified live against the real
  TypeScript relay: mixed-room convergence + a web-peer edit rendering on the
  Android emulator). (9 tests incl. cross-relay integration)

**Not yet (later milestones):** presence/cursors UI, full tool set, stylus
pressure, golden-image reference tests. Tracked in
`../openspec/changes/add-native-android-client/tasks.md`.

## Toolchain

- **JDK:** 17 (auto-provisioned by the Gradle Foojay toolchain resolver if only a
  newer JDK is installed).
- **Gradle:** 8.11.1 (wrapper). **AGP:** 8.7.3. **Kotlin:** 2.0.21.
- **Android:** `compileSdk`/`targetSdk` 35, `minSdk` 26. Verified on an API-34
  emulator (Pixel 3a, arm64).

## Build & test

```bash
cd android

# Unit tests (pure JVM, no device needed)
./gradlew :core-model:test

# Build the debug APK
./gradlew :app:assembleDebug

# Install & launch on a running emulator/device
adb install -r app/build/outputs/apk/debug/app-debug.apk
adb shell am start -n com.excalidraw.android/.MainActivity
```

## Modules

| Module        | Role                                                            |
|---------------|----------------------------------------------------------------|
| `:core-model`     | `.excalidraw` element model, coding, lenient decode, factory |
| `:rough-kotlin`   | rough.js port — sketchy strokes + hachure fills (pure JVM)   |
| `:freehand-kotlin`| perfect-freehand port — variable-width ink (pure JVM)       |
| `:app`            | Jetpack Compose host, Skia renderer, gestures, tools        |

The remaining modules from the design (`core-math`, `core-geometry`,
`render-compose`, `editor`, `collab-yjs`) are added as later milestones land.

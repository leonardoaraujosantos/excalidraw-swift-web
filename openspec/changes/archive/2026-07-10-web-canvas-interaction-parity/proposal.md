# Web Canvas Interaction Parity

## Why

A Playwright side-by-side audit of the Svelte web client against excalidraw.com
(2026-07-10, see `docs/WEB_PARITY_ROADMAP.md`) confirmed four gaps that block
everyday drawing: double-clicking a shape does not open a label editor (and the
typed characters leak into single-letter tool shortcuts), the arrow tool gives
no binding affordances even though bindings work in the model, dark theme
leaves element strokes near-black on the dark canvas (drawings become
invisible), and double-clicking empty canvas creates nothing where excalidraw
creates a text element in place.

## What Changes

- Double-clicking a bindable container (rectangle, diamond, ellipse) with the
  selection tool creates a centered bound text label if none exists, or edits
  the existing one — same editor path used today for sticky notes and tables.
- Double-clicking empty canvas creates a new text element at that point and
  opens the in-place editor.
- While the arrow (or line) tool is active or a linear endpoint is being
  dragged, the bindable shape under the cursor is highlighted; arrow endpoints
  started or released on or near a shape bind to it (proximity binding), not
  only on exact edge hits.
- Dark theme renders elements with theme-adjusted colors (excalidraw-style
  inversion) so strokes and fills stay legible on the dark background; exports
  keep the underlying scene colors.
- Single-letter tool shortcuts are suppressed while any text editor is open or
  focused (regression guard for the label/canvas-text editors).

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `web-client`: new host requirements — double-click creates/edits container
  labels, double-click on empty canvas creates text, and keyboard tool
  shortcuts are inert while a text editor is open.
- `arrows-and-bindings`: new requirement for suggested-binding affordances —
  hover highlight of the bindable shape while a linear tool is active or an
  endpoint is dragged, and proximity binding on start/release near a shape.
- `scene-rendering`: the theme requirement extends beyond the background —
  element stroke/background colors are mapped for dark theme so content stays
  legible; file data and exports keep canonical colors.

## Impact

- `web/packages/excalidraw-svelte`: `EditorStore.doubleClickAt` (label
  create-if-missing, canvas text), `EditorController` (proximity binding,
  suggested-binding state), renderer/overlay (highlight ring, dark-theme color
  mapping).
- `web/apps/web`: `App.svelte` (shortcut guard), `Canvas.svelte` (unchanged
  wiring, overlay already drawn via `renderOverlay`).
- E2E: new Playwright specs in `web/apps/web/e2e/` covering all four behaviors;
  unit tests in `excalidraw-svelte` for controller/store logic.
- iOS/Android clients are not touched; the modified shared-capability
  requirements describe editor behavior the Swift core already exhibits or
  that is scoped to rendering hosts (delta specs note web-first rollout).
- **No schema, file-format, or collaboration-protocol changes** (investigated;
  see design.md "Cross-client & protocol compatibility"): labels reuse the
  existing bound-text fields the sticky-note path already writes, the relay
  and Yjs layers sync them as ordinary element updates, suggested-binding
  highlight and theme mapping are ephemeral/paint-time only, iOS already
  models bound text, and Android round-trips the fields losslessly via its
  raw-JSON element storage.

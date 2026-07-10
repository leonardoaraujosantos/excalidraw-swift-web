# Design — Web Canvas Interaction Parity

## Context

A Playwright audit against excalidraw.com (`docs/WEB_PARITY_ROADMAP.md`)
showed the web client's editor core is already sound where it matters: bound
text works for sticky notes and tables (`beginBoundTextEdit`), arrows created
between shapes record `FixedPointBinding`s and reroute when targets move, and
bindable-target detection exists in the shared geometry layer. The four gaps
are all in the interaction/rendering surface:

- `EditorStore.doubleClickAt` only routes to *existing* bound text, charts, or
  linear editing — it never creates a label or a canvas text element.
- No UI state exposes "this shape would bind" while the arrow tool is active,
  so the overlay draws nothing.
- `SceneRenderer` (TS port) paints a theme-aware background but passes element
  colors through untouched, so default near-black strokes vanish in dark mode.
- Single-letter shortcuts in `App.svelte` fire whenever no editor is open —
  which is exactly the state the missing editors leave you in.

## Goals / Non-Goals

**Goals:**

- Double-click labels on bindable containers and text on empty canvas, using
  the existing on-canvas `<textarea>` editor path end to end.
- Visible suggested-binding highlight driven by the existing bindable-target
  detection; endpoints bind on release as they already do.
- Dark-theme element color mapping compatible with excalidraw's inversion,
  with canonical colors preserved in the model and exports.
- Playwright e2e coverage for each behavior (regression tests are mandatory).

**Non-Goals:**

- Properties-panel, context-menu, and app-chrome parity (roadmap Phases 2–3).
- Flowchart quick-create anchors / Cmd+arrow node spawning (Phase 4).
- Changing iOS/Android behavior; delta specs describe editor-level behavior
  the Swift core largely has — any Swift work is tracked separately.
- Arrow-label editing via double-click (excalidraw supports labels on arrows;
  deferred to keep this change small — containers only).

## Decisions

**D1 — Label creation extends `doubleClickAt`, reusing the sticky-note path.**
Priority chain becomes: existing bound-text hit → chart hit → linear hit →
*bindable container hit → create empty bound text + `beginBoundTextEdit`* →
*empty canvas → create unbound text at point + open editor*. Creation happens
inside one history transaction so undo removes the label atomically.
`commitText` gains a cleanup rule: committing an empty value on a label
deletes the text element and removes its entry from the container's
`boundElements` (the model already keeps empty *bound* text otherwise, per
`drawing-tools`; a never-typed-in label is the exception).
*Alternative considered:* a separate "label tool" — rejected; parity behavior
is double-click, and the editor plumbing already exists.

**D2 — Suggested binding is controller state, drawn by the overlay.**
The controller tracks `suggestedBindingID: string | null`, updated from the
existing pointer-move path (`trackPointer` already fires on every move) when a
linear tool is active or a linear endpoint drag is in flight, using the
existing smallest-containing-bindable lookup with expanded bounds. The store
bumps `revision` only when the ID changes. `renderOverlay` draws the
highlight (accent-colored outline following the target's shape, honoring
rotation) so no host wiring changes — `Canvas.svelte` already calls
`renderOverlay` every frame.
*Alternative considered:* host-side hit-testing in `Canvas.svelte` — rejected;
binding rules live in the editor core and must stay client-agnostic.

**D3 — Dark theme via per-color mapping, not a canvas filter.**
Implement `themeColor(hex, theme)` in the renderer applying excalidraw's
`invert(93%) hue-rotate(180deg)` transform arithmetically per color, memoized.
It is applied at paint time to strokes, fills, freedraw outlines, text, and
arrowheads; never to bitmap images; never to the model.
*Alternative considered:* CSS/`ctx.filter` on the canvas (excalidraw's actual
mechanism) — rejected: `ctx.filter` support is uneven (Safari), a whole-canvas
filter would also invert the selection overlay and images (excalidraw needs
counter-filters for those), and a pure function is unit-testable.

**D4 — Shortcut guard hardening.**
`App.svelte` already ignores shortcuts when `store.editingText !== null` or
the event target is an input/textarea. Keep that, and make the new editors set
`editingText` synchronously before the next keydown can be observed. Escape
in the editor commits without switching tools. The e2e regression asserts the
"Hello"-switches-to-ellipse bug stays dead.

## Cross-client & protocol compatibility (investigated 2026-07-10)

None of the four features changes the `.excalidraw` schema, the relay wire
protocol, or the Yjs document mapping. Evidence, per surface:

- **File format.** Labels reuse the exact fields the sticky-note/table path
  already writes (`controller.ts` `insertStickyNote`: text with
  `containerId` + `verticalAlign: "middle"`, container with
  `boundElements: [{ id, type: "text" }]`) — standard schema-v2 fields that
  excalidraw.com authored files already contain. No new keys.
- **Relay protocol.** `protocol/messages.ts` defines element-level messages
  (`ElementUpdates`, `SceneSnapshot`, `Presence`, `Pointer`, …) with no
  app-state or theme payloads. A label is just two element upserts; nothing
  else changes shape.
- **Yjs.** `excalidraw-yjs/mapping.ts` mirrors elements into a per-element
  `Y.Map` and already treats `boundElements`, bindings, and `customData` as
  atomic JSON values; new elements and container updates flow through
  `syncElementsToDoc` in one tagged transaction. No mapping rule changes.
- **iOS.** Bound text, binding detection, and theme-aware rendering are
  baseline Swift behaviors (the shared specs were reverse-engineered from
  iOS); no Swift code is touched. iOS has no realtime collab yet (Phase 8),
  so the collab surface is web-only today.
- **Android.** The Kotlin model stores each element as a raw `JsonObject`
  behind a typed `ElementView`, so `containerId`/`boundElements` round-trip
  losslessly per the `android-client` round-trip requirement. Android does
  not yet *model* bound text (no `containerId` reader): web-authored labels
  render as plain text elements at their stored x/y (visually inside the
  shape) but won't re-center if the container is resized on Android. This is
  a pre-existing fidelity gap (sticky notes, tables, and Mermaid labels
  already hit it), not introduced by this change; it stays tracked in the
  Android parity work.
- **Ephemeral state.** Suggested-binding highlight lives in the controller
  and overlay only; dark-theme mapping is paint-time only and theme is never
  synced. Interop scenarios asserting all of this were added to the three
  delta specs.

## Risks / Trade-offs

- [Label wrapping/metrics differ from excalidraw.com] → reuse the existing
  bound-text layout used by sticky notes/tables (already round-trips with
  excalidraw files); add a fixture-based render test.
- [Empty-label cleanup could orphan `boundElements` entries] → cleanup runs in
  the same transaction as commit; unit test asserts container state after
  cancel.
- [Arithmetic inversion drifts from excalidraw's filter output] → validate
  `themeColor` against the filter formula for the default palette in unit
  tests; drift only affects on-screen dark rendering, never stored colors.
- [Highlight redraw churn on every pointer move] → revision bumps only on
  suggestedBindingID *changes*; the app already polls revision at 40ms.

## Migration Plan

No data or wire-format changes; `.excalidraw` round-trip is untouched.
Ship as one PR; revert is a clean rollback. After merge, sync delta specs
into `openspec/specs/` via the archive flow.

## Open Questions

- Should double-click also create labels on `text`/`image`/`frame` bindable
  targets? excalidraw.com limits labels to shapes (and arrows); this change
  scopes to rectangle/diamond/ellipse and defers arrows.
- Exact highlight styling (stroke width/color vs excalidraw's) — match
  excalidraw's `#68b1ec`-style ring as closely as the overlay palette allows.

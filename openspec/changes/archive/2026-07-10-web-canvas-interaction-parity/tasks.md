## 1. Container labels & canvas text (double-click)

- [x] 1.1 Add a create-if-missing bound-label step to `EditorStore.doubleClickAt`: on a bindable container hit (rectangle/diamond/ellipse) with no bound text, create an empty centered bound text (`containerId`, `boundElements` registration) in one transaction and open it via `beginBoundTextEdit`
- [x] 1.2 Add the empty-canvas fallback to `doubleClickAt`: create an unbound text element at the scene point and open the on-canvas editor (existing chart/linear/bound-text priorities unchanged)
- [x] 1.3 Extend `commitText` cleanup: committing an empty value on a never-filled label deletes the text element and unregisters it from the container's `boundElements`
- [x] 1.4 Unit tests in `excalidraw-svelte`: label created+centered on dblclick, existing label edited, empty commit leaves no orphan, undo removes label atomically, dblclick priorities (chart/linear/bound-text/canvas-text)

## 2. Suggested-binding affordances

- [x] 2.1 Add `suggestedBindingID` controller state updated from the pointer-move path while a linear tool is active or a linear endpoint drag is in flight (smallest containing bindable, expanded bounds); bump revision only on change
- [x] 2.2 Render the highlight in `renderOverlay`: accent outline following the target's shape (rect/diamond/ellipse, honoring rotation); clears on tool change, pointer-out, drag end
- [x] 2.3 Unit tests: highlight state set/cleared for arrow tool hover, endpoint drag, non-linear tools never set it

## 3. Dark-theme element color mapping

- [x] 3.1 Implement memoized `themeColor(hex, theme)` (excalidraw `invert(93%) hue-rotate(180deg)` arithmetic) in the renderer package with unit tests against the default palette
- [x] 3.2 Apply the mapping at paint time to strokes, fills, freedraw outlines, text, and arrowheads; never to bitmap images; verify SVG export and `documentJSON` keep canonical colors
- [x] 3.3 Render test: dark-theme frame shows light ink on dark background for a default-stroke scene; light theme unchanged (golden/pixel-count assertion)

## 4. Shortcut guard

- [x] 4.1 Audit `App.svelte` keydown paths: all single-key commands (tool letters, delete/backspace) are inert while `editingText !== null` or an editor element is focused; Escape commits without changing the active tool
- [x] 4.2 Ensure new editors set `editingText` synchronously on double-click so no keystroke can race the guard

## 5. Interop regression tests

- [x] 5.1 Unit test: a scene with a web-created label serializes to `.excalidraw` with only schema-v2 fields (`containerId`, `boundElements`) and re-imports identically (fixture also opens on excalidraw.com — manual check noted in PR)
- [x] 5.2 Collab test (existing relay + Yjs test harnesses): creating a label syncs both elements to a peer; toggling dark theme and hovering a suggested binding produce zero outbound messages/doc updates

## 6. End-to-end regression suite

- [x] 6.1 Playwright: double-click rectangle → type "Hello" → commit → bound label rendered, active tool unchanged (kills the "o→ellipse" bug)
- [x] 6.2 Playwright: double-click empty canvas → type → text element persists; double-click chart/line still routes to chart/linear editing
- [x] 6.3 Playwright: arrow-tool hover highlights the shape (screenshot assertion), drawn arrow binds, moving the target reroutes the arrow
- [x] 6.4 Playwright: dark-theme toggle keeps a default-stroke drawing visible (pixel sample), export JSON colors unchanged

## 7. Docs & spec sync

- [x] 7.1 Update `web/README.md` (or app README) interaction notes and `docs/WEB_PARITY_ROADMAP.md` Phase 1 status
- [x] 7.2 Validate the change (`openspec validate`), then archive/sync delta specs into `openspec/specs/` after merge

## 8. Click-to-connect & anchor placeholders (follow-up)

- [x] 8.1 Draw four anchor placeholders (side midpoints, rotated) on the suggested-binding shape in the overlay
- [x] 8.2 Click (no drag) with a linear tool starts a pending arrow — snapped to the nearest anchor within its grab radius — whose end follows the cursor via `trackPointer`
- [x] 8.3 Next click completes the arrow (anchor-snapped, bound both ends, selected, tool reverts); click-in-place discards; Escape / tool switch cancels with no history
- [x] 8.4 Unit tests (click-click flow, anchor snap, cancel paths, anchor geometry) and a Playwright e2e driving the full source-click → destination-click flow

## 9. Label editor centring (follow-up)

- [x] 9.1 Centre the bound-label editor caret in the container (text-align + line-height-aware padding, re-centring per line); `setEditingText` bumps the revision so hosts re-derive
- [x] 9.2 E2E asserting centred caret and per-line re-centring

## 10. Excalidraw-style chrome, shortcuts, and binding-target fix (follow-up)

- [x] 10.1 Number-key shortcuts (1 select, 2 rect, 3 diamond, 4 ellipse, 5 arrow, 6 line, 7 draw, 8 text, 9 image, 0 eraser) alongside letters; Cmd/Ctrl+digit ignored
- [x] 10.2 Excalidraw-style UI: floating icon toolbar island with shortcut badges + hint line, contextual left style panel, bottom-left zoom/undo islands, bottom-right theme/export island, full-bleed canvas, themed islands in dark mode
- [x] 10.3 Hand tool pans the viewport (was a no-op); unit + e2e coverage
- [x] 10.4 Destination/source clicks inside a shape snap to its nearest anchor so arrows never terminate mid-shape
- [x] 10.5 Bindable-target fix: container-bound labels are not bindable — hover, anchors, and bindings target the shape, never its label (MODIFIED baseline requirement + regression test)
- [x] 10.6 Marquee-selection e2e coordinates updated for the floating panel; number-shortcut + hand-pan e2e added

## 11. Text editor commit-on-outside-click (follow-up)

- [x] 11.1 A canvas press while any text editor is open commits the edit and is consumed — it never draws, selects, or spawns a second editor (the text tool previously dropped the typed text because the canvas pointerdown fired before the textarea blur)
- [x] 11.2 Unit tests (text tool + label editor) and a Playwright e2e for the outside-click commit

## 12. Toolbar Note + collapsible style panel (follow-up)

- [x] 12.1 Sticky-note button on the main toolbar island (icon, keeps `gen-note` testid; Table/Chart/Mermaid stay in the generators island)
- [x] 12.2 Left style panel collapsible and collapsed by default: sliders toggle island expands it; "Styles" header with a chevron collapses it; e2e `openPanel` helper + smoke tests updated
- [x] 12.3 Editor focus fix: replaced the `autofocus` attribute (skipped when the opening button keeps focus — Note-button labels silently dropped typing) with a mount action that focuses and places the caret at the end
- [x] 12.4 Table, Chart, and Mermaid moved onto the main toolbar as icon buttons (testids unchanged); generators island removed
- [x] 12.5 "More tools" dropdown on the toolbar (excalidraw-style): Frame tool (F) and Laser pointer (K) plus a Generate section with Sticky note, Table, Chart, and Mermaid diagram; closes on selection, outside click, or Escape; button highlights while open or when frame/laser is active; e2e helpers (`selectTool`, `insertGenerator`) open it transparently

## 13. Sticky-note label fitting & font scaling (follow-up)

- [x] 13.1 `wrapTextLines` in text-measure: word wrap to a max width with per-character breaking of over-long words (unit tested)
- [x] 13.2 Label commits wrap to the container's inner width (raw input kept in `originalText`) and grow the container around its centre when the wrapped block is taller
- [x] 13.3 Resizing a labelled container scales the label font by the area ratio (from gesture-start originals) and re-wraps to the new width; labels excluded from plain geometric scaling
- [x] 13.4 Unit tests: wrap + grow on commit, font scales up/down with corner resizes while the text keeps fitting


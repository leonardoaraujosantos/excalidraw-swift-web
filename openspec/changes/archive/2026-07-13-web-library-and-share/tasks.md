## 1. Store: library

- [x] 1.1 `libraryItems` state + `localStorage` persistence (guarded for non-DOM), `importLibrary(json)` (merges; accepts `.excalidrawlib` and `.excalidraw`), `exportLibrary(): string`
- [x] 1.2 `insertLibraryItem(index, at?)` via the existing paste path (re-id, group, select); `addSelectionToLibrary()`; `removeLibraryItem(index)`
- [x] 1.3 Unit tests: import merges (v1 + v2), insert adds a selected group without touching the library, add-selection/remove, export round-trips, persistence guarded

## 2. Store: share

- [x] 2.1 `collabRoom` / `isCollaborating` / `collabPeers` view over the active session (single source of truth with the status bar)

## 3. UI

- [x] 3.1 `Library.svelte`: item previews (SVG thumbnails), click-to-insert, import/export buttons, add-selection, remove; panel toggle in the chrome
- [x] 3.2 Share dialog in `Excalidraw.svelte`: start session (host `collab` prop), invite link + copy, peer list, Leave; hidden when no `collab` prop
- [x] 3.3 `uiOptions.library` / `uiOptions.share` flags; "Add selection to library" in the context menu

## 4. Demo app wiring

- [x] 4.1 The demo passes a `collab` prop that starts its relay (or Yjs) session and builds the invite link the app already understands

## 5. Verification

- [x] 5.1 E2E: import a `.excalidrawlib`, insert an item (scene grows, group selected), add selection to library, remove, export download
- [x] 5.2 E2E: the library survives a reload
- [x] 5.3 E2E: share dialog starts a session, shows an invite link; a second browser context opens it and both converge with each other listed as peers; Leave stops it
- [x] 5.4 E2E: `uiOptions: { library: false, share: false }` hides both without removing store capability

## 6. Docs & spec sync

- [x] 6.1 README (library + share, new `uiOptions` flags) and `docs/WEB_PARITY_ROADMAP.md` — Phase 4 complete, roadmap done
- [x] 6.2 `openspec validate` clean; archive after merge

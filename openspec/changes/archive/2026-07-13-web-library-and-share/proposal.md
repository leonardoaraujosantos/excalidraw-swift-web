# Library Panel & Share Dialog

## Why

The last two items on the excalidraw.com parity roadmap (Phase 4).

- **Library**: the `.excalidrawlib` codec is implemented and tested
  (`decodeLibrary`/`encodeLibrary`, reading v1 + v2, writing v2), but nothing
  in the UI uses it — a user cannot import a library, insert an item, or save
  a selection as a reusable item.
- **Share**: both collaboration backends work (the LWW relay and the Yjs
  adapter), but a room can only be joined by **hand-editing URL parameters**
  (`?relay=…&room=…` or `?yjs=…`). There is no way to start a session, get an
  invite link, see who is connected, or leave.

## What Changes

- **Library panel** — a side panel listing library items as previews:
  - **Import** `.excalidrawlib` files (also accepts `.excalidraw` scenes as a
    single item), merging into the current library.
  - **Insert** an item by clicking it: its elements are stamped onto the
    canvas (re-id'd, grouped, centred at the cursor/viewport) and selected.
  - **Add selection to library** (also from the context menu), and **remove**
    an item.
  - **Export** the library back to a `.excalidrawlib` file.
  - Items persist across reloads in `localStorage` (host-side, not in the
    document), so a library survives a refresh.
- **Share dialog** — start/stop a collaboration session from the UI:
  - Choose the backend already configured by the host (relay or Yjs), start a
    room with a generated name, and show the **invite link** (the same URL
    parameters the app already understands) with a copy button.
  - Show the connected **peers** and a **Leave** action that stops the session.
  - Joining via a link keeps working exactly as today.
- `uiOptions` gains `library` and `share` flags (default on) so embedders can
  hide either.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `web-client`: new host requirements — the library panel (import, insert,
  add selection, remove, export, persistence) and the share dialog (start,
  invite link, peers, leave).
- `web-embedding`: `uiOptions` gains `library` and `share` flags.

## Impact

- `web/packages/excalidraw-svelte`: `EditorStore` library state
  (`libraryItems`, `importLibrary`, `insertLibraryItem`, `addSelectionToLibrary`,
  `removeLibraryItem`, `exportLibrary`) over the existing codec; a
  `collabRoom`/`collabLink` view of the active session; unit tests.
- `web/packages/excalidraw-svelte/src/ui`: `Library.svelte` panel and a share
  dialog inside `Excalidraw.svelte`; new `uiOptions` flags.
- `web/apps/web`: the demo passes a collab factory so the dialog can start a
  session with the app's relay/Yjs wiring.
- E2E: import → insert → add-to-library → export → persistence; share dialog
  start → link → peers → leave (two browser contexts, as the collab suite
  already does).
- No schema, file-format, or protocol changes — `.excalidrawlib` is the
  existing format and the collab wire protocol is untouched; iOS/Android
  unaffected.

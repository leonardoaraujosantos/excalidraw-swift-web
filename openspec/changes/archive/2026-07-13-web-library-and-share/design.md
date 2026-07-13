# Design — Library Panel & Share Dialog

## Context

Both features are UI over finished core code. `decodeLibrary`/`encodeLibrary`
handle `.excalidrawlib` v1 + v2 and are unit-tested; `CollabSession`,
`startCollab`/`stopCollab`, `peers`, and both backends (LWW relay, Yjs
adapter) work — the demo app already joins rooms from URL parameters, and the
live-collab e2e suite drives two browsers through them.

## Goals / Non-Goals

**Goals:** a library panel (import, insert, add selection, remove, export,
persistence); a share dialog (start, invite link, peers, leave); `uiOptions`
flags for both.

**Non-Goals:** a public/remote library browser (excalidraw.com's library
gallery); library item names/tags; server-side room management or auth;
changing the wire protocol.

## Decisions

**D1 — Library items are plain element groups, held in host state.** The store
keeps `libraryItems: ExcalidrawElement[][]`, exactly the codec's shape. They
are *not* part of the scene or the document — a library is a user asset, not
document content — so no schema or collab impact. Persistence is
`localStorage` under one key, written on every mutation and read on
construction (guarded for non-DOM environments so unit tests and SSR are
unaffected).

**D2 — Insert re-uses the clipboard paste path.** `insertLibraryItem(index,
at?)` encodes the item's elements through the existing `.excalidraw` file
encoder and feeds them to `controller.paste`, which already re-ids, offsets,
groups, and selects. That guarantees an inserted item behaves exactly like a
pasted one (bindings preserved, ids unique), with no second implementation to
keep in sync.

**D3 — The share dialog does not own the transport.** The component takes an
optional `collab` prop: `{ start(room): void; link(room): string }` supplied
by the host (the demo wires its relay/Yjs code into it). The component
generates a room name, calls `start`, shows `link(room)`, and reads peers from
`store.collab.peers`. This keeps the transport choice — relay vs Yjs, which
URL, which auth — a host concern, and keeps the package free of app-specific
wiring. When no `collab` prop is given, the share entry is hidden.

**D4 — Peers come from the store, not the dialog.** `store.collab.peers` is
already the presence source the status bar renders; the dialog reads the same
derived list, so there is one source of truth.

## Risks / Trade-offs

- [`localStorage` unavailable (SSR, privacy mode)] → all access is wrapped in a
  try/catch; the library then simply doesn't persist.
- [Two-browser share e2e is slow] → it reuses the existing collab-live harness
  pattern (one relay, two contexts) which the suite already runs.
- [Library growth is unbounded] → out of scope; items are small element groups
  and the user controls them.

## Migration Plan

No data or protocol changes; one PR. Existing URL-parameter joining keeps
working unchanged.

## Open Questions

None.

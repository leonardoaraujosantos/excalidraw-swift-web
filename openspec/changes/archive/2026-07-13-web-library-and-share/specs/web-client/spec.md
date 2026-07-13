## ADDED Requirements

### Requirement: Library panel

The client SHALL offer a library panel that lists the current library's items as previews and supports: **importing** `.excalidrawlib` files (merging their items into the library, and accepting an `.excalidraw` scene as a single item), **inserting** an item onto the canvas by clicking it (elements re-id'd, grouped, placed in view, and left selected), **adding the current selection** as a new item, **removing** an item, and **exporting** the library back to a `.excalidrawlib` file. The library SHALL persist across reloads on the host (browser storage), SHALL NOT be written into the document, and importing SHALL never modify the scene.

#### Scenario: Import, insert, and export
- **WHEN** the user imports a `.excalidrawlib` file with two items, clicks the
  first item, and exports the library
- **THEN** the panel SHALL list two items, the click SHALL add that item's
  elements to the scene as a selected group, and the export SHALL produce a
  `.excalidrawlib` file containing both items

#### Scenario: Add the selection to the library and persist it
- **WHEN** the user selects two elements, adds them to the library, and reloads
  the page
- **THEN** the library SHALL still list that item, and the scene SHALL be
  unaffected by the addition

#### Scenario: Remove an item
- **WHEN** the user removes a library item
- **THEN** it SHALL disappear from the panel and from subsequent exports, and
  the scene SHALL be unchanged

### Requirement: Share dialog

The client SHALL offer a share dialog that starts a collaboration session on the host's configured backend, generating a room and presenting the **invite link** (a URL the app can join) with a copy action; while a session is active it SHALL list the connected peers and offer **Leave**, which stops the session and leaves the scene intact. Joining through an invite link SHALL behave exactly as joining through the URL does today.

#### Scenario: Start a session and invite a peer
- **WHEN** the user starts a session from the share dialog and a second browser
  opens the presented invite link
- **THEN** both clients SHALL be in the same room, edits SHALL converge, and
  each SHALL list the other as a peer

#### Scenario: Leaving ends the session
- **WHEN** a user in a session chooses Leave
- **THEN** the session SHALL stop, the peer list SHALL clear, and the local
  scene SHALL remain unchanged

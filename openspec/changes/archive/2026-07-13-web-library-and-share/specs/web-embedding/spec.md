## ADDED Requirements

### Requirement: Library and share are gateable

`uiOptions` SHALL accept `library` and `share` flags (default on) that show or hide the library panel and the share dialog. Hiding them SHALL NOT remove the underlying capability from an embedder driving the store (library import/insert/export and `startCollab` remain available).

#### Scenario: Embedder hides both
- **WHEN** a client renders the editor with `library: false` and `share: false`
- **THEN** neither the library panel nor the share dialog SHALL be reachable,
  while `store.importLibrary(...)` and `store.startCollab(...)` still work

## ADDED Requirements

### Requirement: Dark-theme element color mapping

When the dark theme is active, the renderer SHALL map element stroke and background colors so content stays legible on the dark canvas background (excalidraw-compatible inversion: dark inks render light, light fills render dark, hues preserved), while the scene model SHALL keep the canonical (light-theme) color values. Exports (SVG, PNG, `.excalidraw` JSON) SHALL use the canonical colors unless a dark export is explicitly requested. The mapping SHALL apply to all painted element parts — strokes, fills, freedraw outlines, text, and arrowheads — and SHALL NOT alter bitmap image content.

#### Scenario: Default ink is visible in dark theme
- **WHEN** an element drawn with the default near-black stroke is rendered in
  dark theme
- **THEN** its painted stroke SHALL be a light color clearly visible against
  the dark background (not near-black on near-black)

#### Scenario: Model and exports keep canonical colors
- **WHEN** the theme is toggled to dark and the scene is exported
- **THEN** element `strokeColor`/`backgroundColor` values in the scene and in
  the export SHALL be unchanged from their light-theme values

#### Scenario: Round-trip with excalidraw.com is unaffected
- **WHEN** a document authored in dark theme is saved and reopened on
  excalidraw.com
- **THEN** the elements SHALL show the same canonical colors excalidraw.com
  would show for that file in the corresponding theme

#### Scenario: Collaborators are unaffected by a peer's theme
- **WHEN** a user in dark theme edits a shared scene while a collaborator uses
  light theme (relay or Yjs session)
- **THEN** the collaborator SHALL receive only canonical element colors — the
  theme SHALL NOT be broadcast and SHALL NOT alter any synced element field

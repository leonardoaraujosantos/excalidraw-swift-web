## ADDED Requirements

### Requirement: Double-click creates or edits a container label

Double-clicking a bindable container (rectangle, diamond, ellipse) with the selection tool SHALL open the on-canvas text editor for that container's bound label: when the container already has a bound text the editor SHALL open with its current content, and when it has none the system SHALL create an empty bound text element (centered, `containerId` set, container registered in `boundElements`) and open the editor on it. Committing a non-empty value SHALL render the label centered in the container; committing an empty value on a newly created label SHALL remove the label element and leave the container unchanged.

#### Scenario: Double-click adds a label to a plain shape
- **WHEN** the user double-clicks inside a rectangle that has no bound text
- **THEN** a text editor SHALL open over the shape, and typing "Hello" then
  committing SHALL leave a bound text "Hello" centered in the rectangle

#### Scenario: The editor caret starts centred in the shape
- **WHEN** the label editor opens over a container (double-clicked shape,
  sticky note, or table cell)
- **THEN** the caret SHALL sit at the container's centre — text centred
  horizontally and the input region vertically centred — and SHALL stay
  centred as lines are added

#### Scenario: Double-click edits an existing label
- **WHEN** the user double-clicks a shape that already has a bound label
- **THEN** the editor SHALL open pre-filled with the label text, and the
  committed edit SHALL replace the label content

#### Scenario: Cancelling a new label leaves no orphan
- **WHEN** the user double-clicks a plain shape and commits without typing
- **THEN** no text element SHALL remain in the scene and the container's
  `boundElements` SHALL not reference a deleted label

#### Scenario: Labels interop with files and collaboration unchanged
- **WHEN** a label is created and the scene is saved to `.excalidraw`, synced
  over the relay protocol, or synced over Yjs
- **THEN** the label SHALL travel as an ordinary schema-v2 text element
  (`containerId` set, container's `boundElements` updated) with no new file
  fields, message types, or Yjs mapping rules, and SHALL open correctly on
  excalidraw.com and the iOS client

### Requirement: Container labels fit their container

A bound label SHALL always fit inside its container: on commit the raw input (preserved in `originalText`) SHALL be word-wrapped to the container's inner width (over-long words broken by character), and if the wrapped block is taller than the container the container SHALL grow around its centre to fit it. Resizing a labelled container SHALL scale the label's font size by the container's size change (area ratio) and re-wrap the label to the new width, so a bigger sticky note shows bigger text and a smaller one smaller text, never overflowing.

#### Scenario: A long label wraps and the note grows
- **WHEN** the user types a label wider than the sticky note
- **THEN** the committed label SHALL wrap to the note's width, the note SHALL
  grow vertically if needed, and no glyph SHALL render outside the note

#### Scenario: Resizing the note scales its text
- **WHEN** the user drags a labelled note's corner handle outward, then inward
- **THEN** the label's font size SHALL grow, then shrink, with the text
  re-wrapped to keep fitting the note at every size

### Requirement: Double-click on empty canvas creates a text element

Double-clicking empty canvas with the selection tool SHALL create a new unbound text element at the double-clicked scene point and open the on-canvas text editor for it. Committing a non-empty value SHALL keep the text element; committing an empty value SHALL remove it (matching the existing empty-unbound text rule in `drawing-tools`).

#### Scenario: Quick text via double-click
- **WHEN** the user double-clicks an empty area of the canvas and types
  "Quick text" then commits
- **THEN** a text element "Quick text" SHALL exist at that point and remain
  after the editor closes

#### Scenario: Existing double-click behaviors keep priority
- **WHEN** the user double-clicks a chart group, a line/arrow, or a container
  with bound text
- **THEN** chart editing, linear point editing, or label editing SHALL begin
  respectively, and no canvas text element SHALL be created

### Requirement: Number-key tool shortcuts

The web client SHALL select tools with excalidraw's number shortcuts — 1 selection, 2 rectangle, 3 diamond, 4 ellipse, 5 arrow, 6 line, 7 draw (freedraw), 8 text, 9 insert image, 0 eraser — alongside the existing letter shortcuts, and the toolbar SHALL display each tool's shortcut as a badge on its button. Number keys with a platform modifier held (Cmd/Ctrl) SHALL NOT switch tools.

#### Scenario: Digits select the excalidraw tool order
- **WHEN** the user presses "2", "5", then "1" with no editor open
- **THEN** the active tool SHALL become rectangle, then arrow, then selection

### Requirement: Hand tool pans the canvas

With the hand tool active, pointer drags SHALL pan the viewport (scroll follows the drag) and SHALL NOT create, select, or modify any element.

#### Scenario: Hand drag scrolls the view
- **WHEN** the hand tool is active and the user drags right and down
- **THEN** the viewport scroll SHALL follow the drag and the scene SHALL be
  unchanged

### Requirement: Clicking outside commits the open text editor

While an on-canvas text editor is open (text tool, canvas double-click, or a container label), a pointer press on the canvas SHALL commit the edit exactly as Enter does, and that press SHALL be consumed — it SHALL NOT draw, change the selection, or open another editor. Enter, Escape, and focus loss SHALL commit identically.

#### Scenario: Text-tool text commits on an outside click
- **WHEN** the user picks the text tool, clicks the canvas, types "Hi", and
  clicks elsewhere on the canvas
- **THEN** a single text element "Hi" SHALL exist, no second editor or text
  element SHALL be created by the outside click, and the selection tool SHALL
  be active

### Requirement: Tool shortcuts are inert while editing text

While any on-canvas text editor (label, canvas text, table cell, sticky note) is open or focused, single-letter tool shortcuts and other single-key editor commands (delete/backspace element deletion, tool switching) SHALL NOT fire; keystrokes SHALL go to the editor only. Escape SHALL commit/close the editor without changing the active tool.

#### Scenario: Typing a label never switches tools
- **WHEN** a text editor is open and the user types "Hello"
- **THEN** the active tool SHALL be unchanged after the editor closes (the
  "o" MUST NOT activate the ellipse tool)

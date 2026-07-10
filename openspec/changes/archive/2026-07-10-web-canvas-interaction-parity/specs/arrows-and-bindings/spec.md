## MODIFIED Requirements

### Requirement: Bindable target detection and binding point
The system SHALL treat rectangle, diamond, ellipse, text, image, frame, magicframe, embeddable, and iframe elements as bindable targets — except text bound to a container (a label), which SHALL NOT be a bindable target (arrows bind to the container, never its label) — and SHALL find the smallest bindable element whose expanded bounds contain a given point, excluding a supplied set of elements (src: Sources/ExcalidrawGeometry/Binding.swift:12).

#### Scenario: Smallest containing bindable is chosen
- GIVEN a point inside the expanded bounds of multiple bindable elements
- WHEN a bindable target is requested
- THEN the system SHALL return the smallest such element, excluding any supplied elements (src: Tests/ExcalidrawGeometryTests/HitTestTests.swift:80)

#### Scenario: A labelled shape binds as the shape, not the label
- GIVEN a rectangle with a bound text label covering its centre
- WHEN an arrow endpoint is placed (or hovers) over the label
- THEN the suggested binding, anchor snapping, and the recorded binding SHALL
  target the rectangle, and the label text SHALL never be a binding target

## ADDED Requirements

### Requirement: Suggested-binding highlight

While a linear tool (arrow or line) is active, or a linear element's endpoint is being dragged, the system SHALL expose the bindable element under the pointer (using the existing bindable-target detection) as a suggested binding, and the renderer's overlay SHALL draw a highlight around that element's outline so the user can see that an endpoint started or released there will bind. The highlight SHALL clear when the pointer leaves the target's expanded bounds, when the tool changes to a non-linear tool, or when the drag ends. Suggested-binding state SHALL be ephemeral UI state: it SHALL NOT be written to elements, serialized into `.excalidraw` files, or broadcast over any collaboration protocol.

#### Scenario: Hovering a shape with the arrow tool highlights it
- **WHEN** the arrow tool is active and the pointer moves inside a
  rectangle's expanded bounds
- **THEN** the overlay SHALL draw a binding highlight around the rectangle,
  and moving the pointer away SHALL remove it

#### Scenario: Dragging an endpoint highlights the candidate target
- **WHEN** the user drags an arrow endpoint over a bindable shape
- **THEN** the overlay SHALL highlight that shape while the endpoint is over
  it, and the released endpoint SHALL bind to it (per the existing binding-on-
  creation requirement)

#### Scenario: Highlight never renders for non-linear tools
- **WHEN** the selection or rectangle tool is active and the pointer moves
  over a bindable shape
- **THEN** no suggested-binding highlight SHALL be drawn

#### Scenario: Highlight state never leaves the client
- **WHEN** a shape is highlighted as a suggested binding and the scene is
  saved or synced to a collaborator
- **THEN** the saved file and the peer's scene SHALL be byte-identical to the
  un-highlighted case (no element fields, file keys, or protocol messages
  carry the highlight)

### Requirement: Click-to-connect with anchor placeholders

While a linear tool is active and a bindable shape is the suggested binding, the overlay SHALL draw four anchor placeholders at the shape's side midpoints (rotated with the shape) marking where an arrow can start or stop. A click (pointer down and up without dragging) with a linear tool SHALL start a pending arrow at the clicked point — snapped to the nearest anchor when within its grab radius or when the click lands inside a bindable shape — whose end SHALL follow the cursor as a live preview; the next click SHALL complete the arrow at that point (snapped by the same rule, so an arrow never terminates in the middle of a shape, then bound per the binding-on-creation requirement), select it, and revert to the selection tool. Escape or switching tools SHALL abandon the pending arrow, removing the preview element and recording no history; drag-created arrows SHALL be unaffected by this mode. The pending preview SHALL remain local UI state until completion (it syncs like any element once committed).

#### Scenario: Anchors appear on the hovered shape
- **WHEN** the arrow tool is active and a rectangle is the suggested binding
- **THEN** the overlay SHALL draw four anchor placeholders at the rectangle's
  side midpoints, which disappear with the highlight

#### Scenario: Click source, click destination
- **WHEN** the user clicks a shape's right-edge anchor with the arrow tool,
  moves the cursor, and clicks inside another shape
- **THEN** an arrow SHALL be created from the anchor to the clicked point,
  bound to both shapes, with the arrow selected and the selection tool active

#### Scenario: Escape abandons the pending arrow
- **WHEN** the user click-starts an arrow and presses Escape (or switches tool)
- **THEN** the preview element SHALL be removed, no arrow SHALL remain in the
  scene, and undo history SHALL be unchanged

import ExcalidrawModel
import Foundation
import RoughKit

/// Memoizes generated `Drawable`s per element, regenerating when any
/// shape-determining property changes. Mirrors upstream `ShapeCache` (a
/// `WeakMap` keyed by element identity). Keying on the element value rather than
/// `version` matters because live interaction updates (drag/resize) change
/// geometry via `Scene.replace` without bumping `version`.
public final class ShapeCache {
    private struct Entry {
        var element: ExcalidrawElement
        var drawable: Drawable?
    }

    private var entries: [String: Entry] = [:]

    public init() {}

    /// Return the cached drawable for `element`, regenerating whenever the
    /// element differs from the cached one (or was never cached).
    public func drawable(for element: ExcalidrawElement) -> Drawable? {
        let id = element.id
        if let entry = entries[id], entry.element == element {
            return entry.drawable
        }
        let drawable = ElementDrawable.drawable(for: element)
        entries[id] = Entry(element: element, drawable: drawable)
        return drawable
    }

    public func invalidate(id: String) {
        entries[id] = nil
    }

    public func removeAll() {
        entries.removeAll()
    }

    var count: Int {
        entries.count
    }
}

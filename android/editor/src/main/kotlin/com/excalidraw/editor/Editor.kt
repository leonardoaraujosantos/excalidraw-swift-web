package com.excalidraw.editor

import com.excalidraw.model.ElementFactory
import com.excalidraw.model.ElementView
import com.excalidraw.model.Reconcile
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/** Resize handles on the selection bounding box. */
enum class Handle { TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT }

/**
 * The pure, UI-framework-free editor state machine: the ordered element list,
 * the current selection, and undo/redo history. The Compose app drives it and
 * reads [elements]/[selection] to render; it holds no Android or Compose types
 * (the shared "no core coupling" contract). Element mutations produce new
 * `.excalidraw` objects via [ElementGeometry].
 */
class Editor {
    var elements: List<JsonObject> = emptyList()
        private set
    var selection: Set<String> = emptySet()
        private set

    /** Non-deleted elements (soft-deletes stay in [elements] for collab convergence). */
    val visibleElements: List<JsonObject>
        get() = elements.filterNot { ElementView(it).isDeleted }

    private val undoStack = ArrayDeque<List<JsonObject>>()
    private val redoStack = ArrayDeque<List<JsonObject>>()

    /** Snapshot of [elements] captured at the start of a drag transform. */
    private var baseline: List<JsonObject>? = null

    val canUndo: Boolean get() = undoStack.isNotEmpty()
    val canRedo: Boolean get() = redoStack.isNotEmpty()

    fun load(list: List<JsonObject>) {
        elements = list
        selection = emptySet()
        undoStack.clear()
        redoStack.clear()
        baseline = null
    }

    private fun idOf(obj: JsonObject): String = ElementView(obj).id

    private fun pushHistory() {
        undoStack.addLast(elements)
        redoStack.clear()
    }

    // --- Discrete operations (each is one undo step) ---

    fun add(obj: JsonObject) {
        pushHistory()
        elements = elements + obj
        selection = setOf(idOf(obj))
    }

    /** Soft-delete (isDeleted=true + bumped version) so the deletion propagates to peers. */
    fun deleteSelection() {
        if (selection.isEmpty()) return
        pushHistory()
        elements = elements.map {
            if (idOf(it) in selection) {
                ElementFactory.bumped(JsonObject(it + mapOf("isDeleted" to JsonPrimitive(true))))
            } else {
                it
            }
        }
        selection = emptySet()
    }

    /** Elements changed since [beginTransform]/[since] with bumped versions — the collab broadcast set. */
    fun changedSince(since: List<JsonObject>): List<JsonObject> {
        val prior = since.associateBy { idOf(it) }
        return elements.filter { el ->
            val before = prior[idOf(el)]
            before == null || ElementView(before).version != ElementView(el).version
        }
    }

    // --- Selection ---

    /** Select the topmost element hit at the point, or clear if none. Returns the id. */
    fun selectAt(px: Double, py: Double, tolerance: Double = 6.0): String? {
        val hit = elements.lastOrNull {
            val v = ElementView(it)
            !v.isDeleted && ElementGeometry.hitTest(v, px, py, tolerance)
        }
        selection = if (hit != null) setOf(idOf(hit)) else emptySet()
        return hit?.let(::idOf)
    }

    fun clearSelection() {
        selection = emptySet()
    }

    fun selectionBounds(): Box? =
        Box.union(selectedElements().map { ElementGeometry.bounds(ElementView(it)) })

    private fun selectedElements(): List<JsonObject> = elements.filter { idOf(it) in selection }

    // --- Continuous transforms (one undo step per gesture) ---

    fun beginTransform() {
        baseline = elements
        pushHistory()
    }

    fun translateSelection(totalDx: Double, totalDy: Double) {
        val base = baseline ?: return
        elements = base.map {
            if (idOf(it) in selection) ElementGeometry.translate(it, totalDx, totalDy) else it
        }
    }

    fun resizeSelection(handle: Handle, totalDx: Double, totalDy: Double) {
        val base = baseline ?: return
        val from = Box.union(base.filter { idOf(it) in selection }.map { ElementGeometry.bounds(ElementView(it)) })
            ?: return
        var (minX, minY, maxX, maxY) = from
        when (handle) {
            Handle.TOP_LEFT -> { minX += totalDx; minY += totalDy }
            Handle.TOP_RIGHT -> { maxX += totalDx; minY += totalDy }
            Handle.BOTTOM_LEFT -> { minX += totalDx; maxY += totalDy }
            Handle.BOTTOM_RIGHT -> { maxX += totalDx; maxY += totalDy }
        }
        if (maxX - minX < 2.0 || maxY - minY < 2.0) return // avoid inversion/collapse
        val to = Box(minX, minY, maxX, maxY)
        elements = base.map {
            if (idOf(it) in selection) ElementGeometry.resize(it, from, to) else it
        }
    }

    fun endTransform() {
        // Bump version + nonce on the transformed elements so the edit outranks
        // peers' copies under last-writer-wins when broadcast.
        if (baseline != null && selection.isNotEmpty()) {
            elements = elements.map { if (idOf(it) in selection) ElementFactory.bumped(it) else it }
        }
        baseline = null
    }

    /** Merge a peer's element batch by the shared last-writer-wins reconcile rule. */
    fun applyRemote(remote: List<JsonObject>) {
        elements = Reconcile.reconcileElements(elements, remote)
        pruneSelection()
    }

    // --- History ---

    fun undo(): Boolean {
        val prev = undoStack.removeLastOrNull() ?: return false
        redoStack.addLast(elements)
        elements = prev
        pruneSelection()
        return true
    }

    fun redo(): Boolean {
        val next = redoStack.removeLastOrNull() ?: return false
        undoStack.addLast(elements)
        elements = next
        pruneSelection()
        return true
    }

    private fun pruneSelection() {
        val ids = elements.map(::idOf).toSet()
        selection = selection.intersect(ids)
    }
}

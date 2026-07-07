package com.excalidraw.editor

import com.excalidraw.model.ElementView
import kotlinx.serialization.json.JsonObject

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

    fun deleteSelection() {
        if (selection.isEmpty()) return
        pushHistory()
        elements = elements.filterNot { idOf(it) in selection }
        selection = emptySet()
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
        baseline = null
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

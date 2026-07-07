package com.excalidraw.android

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.geometry.Offset
import com.excalidraw.editor.Box
import com.excalidraw.editor.Editor
import com.excalidraw.editor.Handle
import com.excalidraw.model.ExcalidrawFile
import kotlinx.serialization.json.JsonObject

enum class Tool(val label: String) {
    SELECT("Select"),
    RECTANGLE("Rect"),
    ELLIPSE("Ellipse"),
    DIAMOND("Diamond"),
    DRAW("Draw"),
}

/** A remote collaborator's cursor: display name, CSS color, and scene position (null until they move). */
data class RemoteCursor(val name: String, val colorHex: String, val scene: Offset?)

/**
 * App-layer bridge between the pure [Editor] state machine and Compose. Camera
 * and active tool live here; the element list, selection, and history live in
 * [editor]. A [revision] counter is bumped on every editor mutation so the
 * Compose canvas recomposes (the editor itself holds no Compose types).
 */
class SceneState {
    val editor = Editor()

    var tool by mutableStateOf(Tool.SELECT)
    var offset by mutableStateOf(Offset.Zero)
    var scale by mutableStateOf(1f)

    /** Read this in composables that render editor state so they resubscribe. */
    var revision by mutableStateOf(0)
        private set

    private var appState: JsonObject = JsonObject(emptyMap())
    private var files: JsonObject = JsonObject(emptyMap())

    /** Set by [CollabSession] while connected: broadcast a batch of changed elements. */
    var onLocalChange: ((List<JsonObject>) -> Unit)? = null

    /** Set by [CollabSession] while connected: broadcast this peer's cursor (scene coords). */
    var onLocalPointer: ((Offset) -> Unit)? = null

    /** Remote peers' live cursors, keyed by peerId (observable for the canvas overlay). */
    val remoteCursors = mutableStateMapOf<String, RemoteCursor>()

    fun broadcastPointer(scenePoint: Offset) { onLocalPointer?.invoke(scenePoint) }

    private fun bump() { revision++ }

    /** Public revision bump for off-thread callbacks (e.g. collab connect state). */
    fun bumpRevision() { revision++ }

    private fun broadcast(changed: List<JsonObject>) {
        if (changed.isNotEmpty()) onLocalChange?.invoke(changed)
    }

    /** Reconcile a peer's element batch into the scene (no re-broadcast). */
    fun applyRemote(elements: List<JsonObject>) {
        editor.applyRemote(elements)
        bump()
    }

    fun load(file: ExcalidrawFile) {
        editor.load(file.elements)
        appState = file.appState
        files = file.files
        bump()
    }

    fun toFile(): ExcalidrawFile =
        ExcalidrawFile(elements = editor.elements, appState = appState, files = files)

    // --- Camera ---

    fun toScene(screen: Offset): Offset =
        Offset((screen.x - offset.x) / scale, (screen.y - offset.y) / scale)

    fun sceneToScreen(x: Double, y: Double): Offset =
        Offset((x.toFloat() * scale) + offset.x, (y.toFloat() * scale) + offset.y)

    fun zoomBy(factor: Float) { scale = (scale * factor).coerceIn(0.1f, 10f) }

    fun resetCamera() { offset = Offset.Zero; scale = 1f }

    // --- Editing (each bumps revision) ---

    fun add(obj: JsonObject) { editor.add(obj); bump(); broadcast(listOf(obj)) }

    fun hitId(scene: Offset): String? =
        editor.let {
            // read-only hit-test without mutating selection
            it.elements.lastOrNull { e ->
                val v = com.excalidraw.model.ElementView(e)
                !v.isDeleted && com.excalidraw.editor.ElementGeometry.hitTest(v, scene.x.toDouble(), scene.y.toDouble(), 8.0 / scale)
            }?.let { e -> com.excalidraw.model.ElementView(e).id }
        }

    fun selectAtScene(scene: Offset) { editor.selectAt(scene.x.toDouble(), scene.y.toDouble(), 8.0 / scale); bump() }

    fun clearSelection() { editor.clearSelection(); bump() }

    fun beginTransform() { editor.beginTransform() }
    fun translateSelection(dx: Double, dy: Double) { editor.translateSelection(dx, dy); bump() }
    fun resizeSelection(handle: Handle, dx: Double, dy: Double) { editor.resizeSelection(handle, dx, dy); bump() }

    fun endTransform() {
        val ids = editor.selection
        editor.endTransform()
        bump()
        broadcast(editor.elements.filter { com.excalidraw.model.ElementView(it).id in ids })
    }

    fun deleteSelection() {
        val ids = editor.selection
        editor.deleteSelection()
        bump()
        broadcast(editor.elements.filter { com.excalidraw.model.ElementView(it).id in ids })
    }
    fun undo() { if (editor.undo()) bump() }
    fun redo() { if (editor.redo()) bump() }

    val hasSelection: Boolean get() = editor.selection.isNotEmpty()

    fun selectionBounds(): Box? = editor.selectionBounds()

    /** Corner handle whose screen position is within [radiusPx] of the point, or null. */
    fun handleAt(screen: Offset, radiusPx: Float): Handle? {
        val b = selectionBounds() ?: return null
        val corners = mapOf(
            Handle.TOP_LEFT to sceneToScreen(b.minX, b.minY),
            Handle.TOP_RIGHT to sceneToScreen(b.maxX, b.minY),
            Handle.BOTTOM_LEFT to sceneToScreen(b.minX, b.maxY),
            Handle.BOTTOM_RIGHT to sceneToScreen(b.maxX, b.maxY),
        )
        return corners.entries.firstOrNull { (_, pos) ->
            val dx = pos.x - screen.x
            val dy = pos.y - screen.y
            dx * dx + dy * dy <= radiusPx * radiusPx
        }?.key
    }
}

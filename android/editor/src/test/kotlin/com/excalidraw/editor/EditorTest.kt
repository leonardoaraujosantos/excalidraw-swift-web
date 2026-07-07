package com.excalidraw.editor

import com.excalidraw.model.ElementFactory
import com.excalidraw.model.ElementView
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class EditorTest {

    private fun editorWith(vararg ids: String): Editor {
        val e = Editor()
        e.load(ids.mapIndexed { i, id ->
            ElementFactory.rectangle(i * 100.0, 0.0, 80.0, 60.0, id = id, seed = (i + 1).toLong())
        })
        return e
    }

    @Test
    fun addSelectsAndUndoRedoRoundTrips() {
        val e = Editor()
        e.add(ElementFactory.rectangle(0.0, 0.0, 50.0, 50.0, id = "a", seed = 1))
        assertEquals(setOf("a"), e.selection)
        assertEquals(1, e.elements.size)
        assertTrue(e.undo())
        assertEquals(0, e.elements.size)
        assertTrue(e.redo())
        assertEquals(1, e.elements.size)
        assertFalse(e.redo())
    }

    @Test
    fun selectAtHitsTopmostElement() {
        // Two overlapping rects at same spot; the later one wins.
        val e = Editor()
        e.load(
            listOf(
                ElementFactory.rectangle(0.0, 0.0, 100.0, 100.0, id = "under", seed = 1),
                ElementFactory.rectangle(0.0, 0.0, 100.0, 100.0, id = "over", seed = 2),
            ),
        )
        assertEquals("over", e.selectAt(50.0, 50.0))
        assertEquals(setOf("over"), e.selection)
        assertNull(e.selectAt(999.0, 999.0))
        assertTrue(e.selection.isEmpty())
    }

    @Test
    fun translateMovesOnlySelectionAndIsOneUndoStep() {
        val e = editorWith("a", "b")
        e.selectAt(40.0, 30.0) // hits "a" at (0,0,80,60)
        assertEquals(setOf("a"), e.selection)

        e.beginTransform()
        e.translateSelection(10.0, 20.0)
        e.translateSelection(25.0, 40.0) // accumulates from baseline, not previous
        e.endTransform()

        val a = e.elements.first { ElementView(it).id == "a" }
        val b = e.elements.first { ElementView(it).id == "b" }
        assertEquals(25.0, ElementView(a).x, 0.0001)
        assertEquals(40.0, ElementView(a).y, 0.0001)
        assertEquals(100.0, ElementView(b).x, 0.0001) // unchanged

        assertTrue(e.undo()) // single step restores pre-drag position
        assertEquals(0.0, ElementView(e.elements.first { ElementView(it).id == "a" }).x, 0.0001)
    }

    @Test
    fun resizeScalesSelectionBounds() {
        val e = editorWith("a")
        e.selectAt(40.0, 30.0)
        val before = e.selectionBounds()!!
        assertEquals(80.0, before.width, 0.0001)

        e.beginTransform()
        e.resizeSelection(Handle.BOTTOM_RIGHT, 80.0, 60.0) // double the size
        e.endTransform()

        val after = e.selectionBounds()!!
        assertEquals(160.0, after.width, 0.0001)
        assertEquals(120.0, after.height, 0.0001)
        assertEquals(0.0, after.minX, 0.0001) // anchored at top-left
    }

    @Test
    fun deleteSoftDeletesSelectionAndUndoRestores() {
        val e = editorWith("a", "b")
        e.selectAt(40.0, 30.0)
        val deletedId = e.selection.single()
        e.deleteSelection()
        // Soft-delete: element stays in the list (for collab convergence) but is hidden.
        assertEquals(2, e.elements.size)
        assertEquals(1, e.visibleElements.size)
        val deleted = e.elements.first { ElementView(it).id == deletedId }
        assertTrue(ElementView(deleted).isDeleted)
        assertEquals(2, ElementView(deleted).version) // bumped so peers converge on the deletion
        assertTrue(e.selection.isEmpty())
        assertTrue(e.undo())
        assertEquals(2, e.visibleElements.size)
    }

    @Test
    fun endTransformBumpsVersionForBroadcast() {
        val e = editorWith("a")
        e.selectAt(40.0, 30.0)
        val before = ElementView(e.elements.first()).version
        e.beginTransform()
        e.translateSelection(10.0, 10.0)
        e.endTransform()
        assertTrue(ElementView(e.elements.first()).version > before)
    }

    @Test
    fun applyRemoteReconcilesByLastWriterWins() {
        val e = editorWith("a")
        val local = e.elements.first()
        // Remote copy of "a" with a higher version and moved x should win.
        val remote = ElementFactory.bumped(
            ElementGeometry.translate(local, 500.0, 0.0),
        )
        e.applyRemote(listOf(remote))
        val merged = e.elements.first { ElementView(it).id == "a" }
        assertEquals(500.0, ElementView(merged).x, 0.0001)
        assertEquals(1, e.elements.size)
    }

    @Test
    fun resizeScalesPointsOfLineElements() {
        val e = Editor()
        e.load(listOf(ElementFactory.freedraw(listOf(0.0 to 0.0, 100.0 to 50.0), id = "f", seed = 1)))
        e.selectAt(50.0, 25.0)
        e.beginTransform()
        e.resizeSelection(Handle.BOTTOM_RIGHT, 100.0, 50.0) // double
        e.endTransform()
        val v = ElementView(e.elements.first())
        // last relative point should have doubled
        assertEquals(200.0, v.points.last().first, 0.0001)
        assertEquals(100.0, v.points.last().second, 0.0001)
    }
}

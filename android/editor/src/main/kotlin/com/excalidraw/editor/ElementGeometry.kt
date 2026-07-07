package com.excalidraw.editor

import com.excalidraw.model.ElementView
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.doubleOrNull

/** Axis-aligned bounding box in scene coordinates. */
data class Box(val minX: Double, val minY: Double, val maxX: Double, val maxY: Double) {
    val width: Double get() = maxX - minX
    val height: Double get() = maxY - minY

    fun contains(px: Double, py: Double, pad: Double = 0.0): Boolean =
        px >= minX - pad && px <= maxX + pad && py >= minY - pad && py <= maxY + pad

    companion object {
        fun union(boxes: List<Box>): Box? {
            if (boxes.isEmpty()) return null
            return Box(
                boxes.minOf { it.minX },
                boxes.minOf { it.minY },
                boxes.maxOf { it.maxX },
                boxes.maxOf { it.maxY },
            )
        }
    }
}

/** Bounds, hit-testing, and transforms over `.excalidraw` element objects. */
object ElementGeometry {

    fun bounds(v: ElementView): Box {
        val pts = v.points
        if (pts.isNotEmpty()) {
            val xs = pts.map { v.x + it.first }
            val ys = pts.map { v.y + it.second }
            return Box(xs.min(), ys.min(), xs.max(), ys.max())
        }
        return Box(v.x, v.y, v.x + v.width, v.y + v.height)
    }

    /** Hit-test against the element's bounds with a padding tolerance (in scene units). */
    fun hitTest(v: ElementView, px: Double, py: Double, tolerance: Double = 6.0): Boolean =
        bounds(v).contains(px, py, tolerance)

    fun translate(obj: JsonObject, dx: Double, dy: Double): JsonObject {
        val x = num(obj, "x") + dx
        val y = num(obj, "y") + dy
        return JsonObject(obj + mapOf("x" to JsonPrimitive(x), "y" to JsonPrimitive(y)))
    }

    /** Rescale an element so its old bounds [from] map onto new bounds [to]. */
    fun resize(obj: JsonObject, from: Box, to: Box): JsonObject {
        val sx = if (from.width != 0.0) to.width / from.width else 1.0
        val sy = if (from.height != 0.0) to.height / from.height else 1.0
        val oldX = num(obj, "x")
        val oldY = num(obj, "y")
        val newX = to.minX + (oldX - from.minX) * sx
        val newY = to.minY + (oldY - from.minY) * sy
        val overrides = mutableMapOf<String, JsonElement>(
            "x" to JsonPrimitive(newX),
            "y" to JsonPrimitive(newY),
            "width" to JsonPrimitive(num(obj, "width") * sx),
            "height" to JsonPrimitive(num(obj, "height") * sy),
        )
        (obj["points"] as? JsonArray)?.let { pts ->
            overrides["points"] = JsonArray(
                pts.map { p ->
                    val arr = p as? JsonArray ?: return@map p
                    if (arr.size < 2) return@map p
                    val dx = arr[0].jsonDouble() * sx
                    val dy = arr[1].jsonDouble() * sy
                    JsonArray(listOf(JsonPrimitive(dx), JsonPrimitive(dy)))
                },
            )
        }
        return JsonObject(obj + overrides)
    }

    private fun num(obj: JsonObject, key: String): Double =
        (obj[key] as? JsonPrimitive)?.doubleOrNull ?: 0.0

    private fun JsonElement.jsonDouble(): Double = (this as? JsonPrimitive)?.doubleOrNull ?: 0.0
}

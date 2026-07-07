package com.excalidraw.collab

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put

/**
 * Encode/decode protocol messages on the wire (JSON v1), byte-compatible with the
 * Swift `CollabCodec` and TypeScript `codec`. The `type` tag discriminates the
 * union; `join`/`room-state` carry a `protocol` key. Written by hand (rather than
 * via `@Serializable` polymorphism) so the exact field names and shapes match the
 * other clients — the relay's TypeScript `decode` must accept our frames.
 */
object CollabCodec {

    private val json = Json { ignoreUnknownKeys = true; isLenient = true }

    class ProtocolError(message: String) : Exception(message)

    fun encode(message: CollabMessage): String = json.encodeToString(JsonElement.serializer(), toJson(message))

    /** Recursively key-sorted encoding — matches Swift `.sortedKeys` for conformance fixtures. */
    fun canonicalEncode(message: CollabMessage): String = canonical(toJson(message))

    fun decode(text: String): CollabMessage {
        val root = try {
            json.parseToJsonElement(text).jsonObject
        } catch (e: Exception) {
            throw ProtocolError("invalid JSON: ${e.message}")
        }
        val type = (root["type"] as? JsonPrimitive)?.content
            ?: throw ProtocolError("missing type")
        fun str(key: String) = root[key]!!.jsonPrimitive.content
        fun int(key: String) = root[key]!!.jsonPrimitive.content.toInt()
        fun long(key: String) = root[key]!!.jsonPrimitive.content.toLong()
        fun elems(key: String) = root[key]!!.jsonArray.map { it.jsonObject }
        return when (type) {
            "join" -> CollabMessage.Join(int("protocol"), str("room"), peer(root["peer"]!!))
            "leave" -> CollabMessage.Leave(str("peerId"))
            "room-state" -> CollabMessage.RoomState(
                int("protocol"), str("you"),
                root["peers"]!!.jsonArray.map(::peer), elems("elements"),
            )
            "peer-joined" -> CollabMessage.PeerJoined(peer(root["peer"]!!))
            "peer-left" -> CollabMessage.PeerLeft(str("peerId"))
            "presence" -> CollabMessage.PresenceUpdate(str("peerId"), presence(root["presence"]!!))
            "pointer" -> CollabMessage.Pointer(str("peerId"), pointerPos(root["pointer"]!!))
            "element-updates" -> CollabMessage.ElementUpdates(elems("elements"))
            "scene-snapshot" -> CollabMessage.SceneSnapshot(elems("elements"))
            "ping" -> CollabMessage.Ping(long("t"))
            "ack" -> CollabMessage.Ack(long("t"))
            else -> throw ProtocolError("unknown message type: $type")
        }
    }

    // --- to JsonObject ---

    private fun toJson(m: CollabMessage): JsonObject = buildJsonObject {
        when (m) {
            is CollabMessage.Join -> {
                put("type", "join"); put("protocol", m.protocol); put("room", m.room); put("peer", peerJson(m.peer))
            }
            is CollabMessage.Leave -> { put("type", "leave"); put("peerId", m.peerId) }
            is CollabMessage.RoomState -> {
                put("type", "room-state"); put("protocol", m.protocol); put("you", m.you)
                put("peers", JsonArray(m.peers.map(::peerJson))); put("elements", JsonArray(m.elements))
            }
            is CollabMessage.PeerJoined -> { put("type", "peer-joined"); put("peer", peerJson(m.peer)) }
            is CollabMessage.PeerLeft -> { put("type", "peer-left"); put("peerId", m.peerId) }
            is CollabMessage.PresenceUpdate -> {
                put("type", "presence"); put("peerId", m.peerId); put("presence", presenceJson(m.presence))
            }
            is CollabMessage.Pointer -> { put("type", "pointer"); put("peerId", m.peerId); put("pointer", pointerJson(m.pointer)) }
            is CollabMessage.ElementUpdates -> { put("type", "element-updates"); put("elements", JsonArray(m.elements)) }
            is CollabMessage.SceneSnapshot -> { put("type", "scene-snapshot"); put("elements", JsonArray(m.elements)) }
            is CollabMessage.Ping -> { put("type", "ping"); put("t", m.t) }
            is CollabMessage.Ack -> { put("type", "ack"); put("t", m.t) }
        }
    }

    private fun peerJson(p: Peer): JsonObject = buildJsonObject {
        put("id", p.id); put("name", p.name); put("color", p.color)
    }

    private fun pointerJson(p: PointerPos): JsonObject = buildJsonObject { put("x", p.x); put("y", p.y) }

    private fun presenceJson(p: Presence): JsonObject = buildJsonObject {
        put("pointer", p.pointer?.let(::pointerJson) ?: JsonNull) // explicit null, matching the TS schema
        put("selectedIds", buildJsonArray { p.selectedIds.forEach { add(JsonPrimitive(it)) } })
        put("tool", p.tool)
    }

    // --- from JsonElement ---

    private fun peer(e: JsonElement): Peer = e.jsonObject.let {
        Peer(it["id"]!!.jsonPrimitive.content, it["name"]!!.jsonPrimitive.content, it["color"]!!.jsonPrimitive.content)
    }

    private fun pointerPos(e: JsonElement): PointerPos = e.jsonObject.let {
        PointerPos(it["x"]!!.jsonPrimitive.doubleOrNull ?: 0.0, it["y"]!!.jsonPrimitive.doubleOrNull ?: 0.0)
    }

    private fun presence(e: JsonElement): Presence = e.jsonObject.let { o ->
        val ptr = o["pointer"]?.takeIf { it !is JsonNull }?.let(::pointerPos)
        Presence(ptr, o["selectedIds"]!!.jsonArray.map { it.jsonPrimitive.content }, o["tool"]!!.jsonPrimitive.content)
    }

    // --- canonical (sorted-key) serialization ---

    private fun canonical(e: JsonElement): String = when (e) {
        is JsonObject -> e.entries.sortedBy { it.key }
            .joinToString(",", "{", "}") { "${JsonPrimitive(it.key)}:${canonical(it.value)}" }
        is JsonArray -> e.joinToString(",", "[", "]", transform = ::canonical)
        else -> e.toString()
    }
}

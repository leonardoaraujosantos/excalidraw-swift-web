package com.excalidraw.collab

import kotlinx.serialization.json.JsonObject

/** Wire protocol version — must match the Swift/TS `PROTOCOL_VERSION`. */
const val PROTOCOL_VERSION: Int = 1

/** A collaborator's stable identity (cursor + roster entry). */
data class Peer(val id: String, val name: String, val color: String)

/** A live pointer position in scene coordinates. */
data class PointerPos(val x: Double, val y: Double)

/** A peer's broadcast presence: cursor, selection, active tool. */
data class Presence(val pointer: PointerPos?, val selectedIds: List<String>, val tool: String)

/**
 * The collaboration message union — wire-compatible with the Swift
 * `CollabMessage` enum and the TypeScript `Message` union (protocol v1). Elements
 * ride as full [JsonObject]s so nothing is lost across the wire.
 */
sealed interface CollabMessage {
    data class Join(val protocol: Int, val room: String, val peer: Peer) : CollabMessage
    data class Leave(val peerId: String) : CollabMessage
    data class RoomState(
        val protocol: Int,
        val you: String,
        val peers: List<Peer>,
        val elements: List<JsonObject>,
    ) : CollabMessage
    data class PeerJoined(val peer: Peer) : CollabMessage
    data class PeerLeft(val peerId: String) : CollabMessage
    data class PresenceUpdate(val peerId: String, val presence: Presence) : CollabMessage
    data class Pointer(val peerId: String, val pointer: PointerPos) : CollabMessage
    data class ElementUpdates(val elements: List<JsonObject>) : CollabMessage
    data class SceneSnapshot(val elements: List<JsonObject>) : CollabMessage
    data class Ping(val t: Long) : CollabMessage
    data class Ack(val t: Long) : CollabMessage
}

package com.excalidraw.android

import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import androidx.compose.ui.geometry.Offset
import com.excalidraw.collab.CollabClient
import com.excalidraw.collab.CollabMessage
import com.excalidraw.collab.Peer
import com.excalidraw.collab.PointerPos
import kotlinx.serialization.json.JsonObject
import kotlin.random.Random

/**
 * Bridges the pure-Kotlin [CollabClient] to the app's [SceneState]. Incoming
 * `room-state`/`element-updates`/`scene-snapshot` are reconciled into the scene
 * (on the main thread); local edits are broadcast as `element-updates`. The
 * client and reconcile logic are transport-only — this class just marshals
 * between the socket thread and Compose.
 */
class CollabSession(
    private val scene: SceneState,
    private val url: String,
    private val room: String,
    displayName: String = "Android",
) {
    private val main = Handler(Looper.getMainLooper())
    private val peer = Peer(
        id = "android-${Random.nextInt(100000, 999999)}",
        name = displayName,
        color = PEER_COLORS.random(),
    )

    var connected: Boolean = false
        private set

    // lateinit so the handler (below) can reference `client` without a
    // circular initializer; it is only used from callbacks that fire post-connect.
    private lateinit var client: CollabClient

    /** id → Peer for known remote collaborators (name/color for their cursor). */
    private val roster = HashMap<String, Peer>()
    private var selfId: String? = null

    private val handlers = object : CollabClient.Handlers {
        override fun onOpen() {
            main.post { connected = true; scene.bumpRevision() }
            // Push our current scene so existing peers reconcile us in.
            client.sendElementUpdates(scene.editor.elements)
        }

        override fun onMessage(message: CollabMessage) {
            when (message) {
                is CollabMessage.RoomState -> {
                    selfId = message.you
                    val others = message.peers.filter { it.id != message.you }
                    others.forEach { roster[it.id] = it }
                    val ids = others.map { it.id }.toSet()
                    main.post {
                        scene.remoteCursors.keys.retainAll(ids)
                        others.forEach { putCursor(it, null) }
                    }
                    applyRemote(message.elements)
                }
                is CollabMessage.ElementUpdates -> applyRemote(message.elements)
                is CollabMessage.SceneSnapshot -> applyRemote(message.elements)
                is CollabMessage.PeerJoined -> {
                    if (message.peer.id != selfId) {
                        roster[message.peer.id] = message.peer
                        main.post { putCursor(message.peer, null) }
                    }
                }
                is CollabMessage.PeerLeft -> {
                    roster.remove(message.peerId)
                    main.post { scene.remoteCursors.remove(message.peerId) }
                }
                is CollabMessage.Pointer -> updateCursor(message.peerId, message.pointer)
                is CollabMessage.PresenceUpdate -> updateCursor(message.peerId, message.presence.pointer)
                else -> {}
            }
        }

        override fun onClosed(reason: String) {
            main.post { connected = false; scene.remoteCursors.clear(); scene.bumpRevision() }
        }
    }

    private fun putCursor(p: Peer, at: Offset?) {
        scene.remoteCursors[p.id] = RemoteCursor(p.name, p.color, at ?: scene.remoteCursors[p.id]?.scene)
    }

    private fun updateCursor(peerId: String, pointer: PointerPos?) {
        if (peerId == selfId || pointer == null) return
        val p = roster[peerId]
        main.post {
            scene.remoteCursors[peerId] = RemoteCursor(
                p?.name ?: peerId,
                p?.color ?: "#868e96",
                Offset(pointer.x.toFloat(), pointer.y.toFloat()),
            )
        }
    }

    init {
        client = CollabClient(url = url, room = room, peer = peer, handlers = handlers)
    }

    private fun applyRemote(elements: List<JsonObject>) {
        main.post { scene.applyRemote(elements) }
    }

    private var lastPointerSent = 0L

    fun connect() {
        // Broadcast local edits as they happen.
        scene.onLocalChange = { changed -> client.sendElementUpdates(changed) }
        // Broadcast this peer's cursor, throttled to ~25/s.
        scene.onLocalPointer = { p ->
            val now = SystemClock.uptimeMillis()
            if (now - lastPointerSent >= 40L) {
                lastPointerSent = now
                client.send(CollabMessage.Pointer(peer.id, PointerPos(p.x.toDouble(), p.y.toDouble())))
            }
        }
        client.connect()
    }

    fun disconnect() {
        scene.onLocalChange = null
        scene.onLocalPointer = null
        client.close()
        connected = false
        scene.remoteCursors.clear()
    }

    companion object {
        private val PEER_COLORS = listOf("#e64980", "#1971c2", "#2f9e44", "#f08c00", "#7048e8")
    }
}

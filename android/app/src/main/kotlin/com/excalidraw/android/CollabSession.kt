package com.excalidraw.android

import android.os.Handler
import android.os.Looper
import com.excalidraw.collab.CollabClient
import com.excalidraw.collab.CollabMessage
import com.excalidraw.collab.Peer
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

    private val handlers = object : CollabClient.Handlers {
        override fun onOpen() {
            main.post { connected = true; scene.bumpRevision() }
            // Push our current scene so existing peers reconcile us in.
            client.sendElementUpdates(scene.editor.elements)
        }

        override fun onMessage(message: CollabMessage) {
            when (message) {
                is CollabMessage.RoomState -> applyRemote(message.elements)
                is CollabMessage.ElementUpdates -> applyRemote(message.elements)
                is CollabMessage.SceneSnapshot -> applyRemote(message.elements)
                else -> {} // presence/pointer/peer-* not surfaced in this milestone
            }
        }

        override fun onClosed(reason: String) {
            main.post { connected = false; scene.bumpRevision() }
        }
    }

    init {
        client = CollabClient(url = url, room = room, peer = peer, handlers = handlers)
    }

    private fun applyRemote(elements: List<JsonObject>) {
        main.post { scene.applyRemote(elements) }
    }

    fun connect() {
        // Broadcast local edits as they happen.
        scene.onLocalChange = { changed -> client.sendElementUpdates(changed) }
        client.connect()
    }

    fun disconnect() {
        scene.onLocalChange = null
        client.close()
        connected = false
    }

    companion object {
        private val PEER_COLORS = listOf("#e64980", "#1971c2", "#2f9e44", "#f08c00", "#7048e8")
    }
}

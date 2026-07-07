package com.excalidraw.collab

import kotlinx.serialization.json.JsonObject
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import java.util.concurrent.TimeUnit

/**
 * A pure-Kotlin collaboration client speaking the custom protocol-v1 WebSocket
 * JSON over OkHttp — the same wire the iOS (Swift) and web (TS) clients use. It
 * connects to the existing Node relay, sends `join`, and surfaces decoded
 * messages via [Handlers]. It holds no editor/UI types: callers reconcile
 * incoming `element-updates`/`room-state` into their scene (`Reconcile`).
 */
class CollabClient(
    private val url: String,
    private val room: String,
    private val peer: Peer,
    private val handlers: Handlers,
) {
    interface Handlers {
        fun onOpen() {}
        fun onMessage(message: CollabMessage)
        fun onClosed(reason: String) {}
    }

    // OkHttp is an internal transport detail; it is not part of the public API.
    private val client: OkHttpClient = defaultClient()
    private var socket: WebSocket? = null

    fun connect() {
        val request = Request.Builder().url(url).build()
        socket = client.newWebSocket(request, object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                send(CollabMessage.Join(PROTOCOL_VERSION, room, peer))
                handlers.onOpen()
            }

            override fun onMessage(webSocket: WebSocket, text: String) {
                val message = try {
                    CollabCodec.decode(text)
                } catch (_: Exception) {
                    return // ignore malformed frames, like the relay does
                }
                // Answer liveness pings locally so the relay/peer sees us alive.
                if (message is CollabMessage.Ping) send(CollabMessage.Ack(message.t))
                handlers.onMessage(message)
            }

            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                handlers.onClosed(reason)
            }

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                handlers.onClosed(t.message ?: "failure")
            }
        })
    }

    fun send(message: CollabMessage) {
        socket?.send(CollabCodec.encode(message))
    }

    /** Broadcast a batch of changed elements to the room. */
    fun sendElementUpdates(elements: List<JsonObject>) {
        if (elements.isNotEmpty()) send(CollabMessage.ElementUpdates(elements))
    }

    fun sendPresence(peerId: String, presence: Presence) = send(CollabMessage.PresenceUpdate(peerId, presence))

    fun close() {
        socket?.close(1000, null)
        socket = null
    }

    companion object {
        private fun defaultClient(): OkHttpClient =
            OkHttpClient.Builder()
                .pingInterval(20, TimeUnit.SECONDS)
                .readTimeout(0, TimeUnit.MILLISECONDS)
                .build()
    }
}

package com.excalidraw.collab

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assume.assumeNotNull
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

/**
 * Live cross-client convergence against a running relay. Opt-in: set `RELAY_URL`
 * (e.g. `ws://127.0.0.1:3001`) to run it; skipped otherwise so the normal unit
 * build needs no server.
 *
 * When the relay is the real TypeScript relay (`web/server`, which decodes with
 * `excalidraw-svelte/protocol` and reconciles with the TS `reconcileElements`),
 * a green run proves the Kotlin wire format is byte-compatible with the
 * TypeScript/Swift clients *and* that a mixed room converges.
 */
class RelayIntegrationTest {

    private val relayUrl: String? = System.getenv("RELAY_URL")

    private fun element(id: String, version: Int, x: Int): JsonObject =
        Json.parseToJsonElement(
            """{"id":"$id","type":"rectangle","x":$x,"y":0,"width":10,"height":10,"version":$version,"versionNonce":${version * 7}}""",
        ).jsonObject

    @Test
    fun twoPeersConvergeThroughRelay() {
        assumeNotNull(relayUrl)
        val room = "it-${System.nanoTime()}"

        val bGotRoomState = CountDownLatch(1)
        val bGotUpdate = CountDownLatch(1)
        val received = AtomicReference<JsonObject?>()

        val peerB = CollabClient(
            relayUrl!!, room, Peer("B", "Bob", "#1971c2"),
            object : CollabClient.Handlers {
                override fun onMessage(message: CollabMessage) {
                    when (message) {
                        is CollabMessage.RoomState -> bGotRoomState.countDown()
                        is CollabMessage.ElementUpdates -> {
                            received.set(message.elements.firstOrNull { it["id"]!!.jsonPrimitive.content == "shared-1" })
                            if (received.get() != null) bGotUpdate.countDown()
                        }
                        else -> {}
                    }
                }
            },
        )
        val peerA = CollabClient(
            relayUrl, room, Peer("A", "Ada", "#e64980"),
            object : CollabClient.Handlers {
                override fun onMessage(message: CollabMessage) {}
            },
        )

        try {
            peerB.connect()
            assertTrue("B never got room-state", bGotRoomState.await(10, TimeUnit.SECONDS))
            peerA.connect()
            Thread.sleep(400) // let A's join settle on the relay
            peerA.sendElementUpdates(listOf(element("shared-1", 3, 250)))

            assertTrue("B never received A's element", bGotUpdate.await(10, TimeUnit.SECONDS))
            val el = received.get()!!
            assertEquals("250", el["x"]!!.jsonPrimitive.content)
            assertEquals(3, el["version"]!!.jsonPrimitive.content.toInt())
        } finally {
            peerA.close()
            peerB.close()
        }
    }

    @Test
    fun lateJoinerReceivesSceneInRoomState() {
        assumeNotNull(relayUrl)
        val room = "it-late-${System.nanoTime()}"

        val aReady = CountDownLatch(1)
        val peerA = CollabClient(
            relayUrl!!, room, Peer("A", "Ada", "#e64980"),
            object : CollabClient.Handlers {
                override fun onMessage(message: CollabMessage) {
                    if (message is CollabMessage.RoomState) aReady.countDown()
                }
            },
        )

        val lateRoomState = AtomicReference<CollabMessage.RoomState?>()
        val lateReady = CountDownLatch(1)
        val late = CollabClient(
            relayUrl, room, Peer("L", "Late", "#2f9e44"),
            object : CollabClient.Handlers {
                override fun onMessage(message: CollabMessage) {
                    if (message is CollabMessage.RoomState) { lateRoomState.set(message); lateReady.countDown() }
                }
            },
        )

        try {
            peerA.connect()
            assertTrue(aReady.await(10, TimeUnit.SECONDS))
            peerA.sendElementUpdates(listOf(element("seed-1", 1, 42)))
            Thread.sleep(500) // relay reconciles into its room snapshot

            late.connect()
            assertTrue("late joiner never got room-state", lateReady.await(10, TimeUnit.SECONDS))
            val elements = lateRoomState.get()!!.elements
            assertTrue(
                "room-state should carry the previously-sent element",
                elements.any { it["id"]!!.jsonPrimitive.content == "seed-1" },
            )
        } finally {
            peerA.close()
            late.close()
        }
    }
}

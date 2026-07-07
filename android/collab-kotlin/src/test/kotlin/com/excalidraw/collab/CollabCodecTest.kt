package com.excalidraw.collab

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class CollabCodecTest {

    private fun element(id: String, version: Int, nonce: Long): JsonObject =
        Json.parseToJsonElement(
            """{"id":"$id","type":"rectangle","x":0,"y":0,"width":10,"height":10,"version":$version,"versionNonce":$nonce}""",
        ).jsonObject

    private val peer = Peer("p1", "Ada", "#e64980")

    @Test
    fun joinEncodesWithProtocolKey() {
        val json = Json.parseToJsonElement(CollabCodec.encode(CollabMessage.Join(1, "room-7", peer))).jsonObject
        assertEquals("join", json["type"]!!.jsonPrimitive.content)
        assertEquals(1, json["protocol"]!!.jsonPrimitive.content.toInt())
        assertEquals("room-7", json["room"]!!.jsonPrimitive.content)
        assertEquals("p1", json["peer"]!!.jsonObject["id"]!!.jsonPrimitive.content)
    }

    @Test
    fun everyMessageTypeRoundTrips() {
        val messages = listOf(
            CollabMessage.Join(1, "r", peer),
            CollabMessage.Leave("p1"),
            CollabMessage.RoomState(1, "p1", listOf(peer), listOf(element("a", 3, 42))),
            CollabMessage.PeerJoined(peer),
            CollabMessage.PeerLeft("p2"),
            CollabMessage.PresenceUpdate("p1", Presence(PointerPos(1.0, 2.0), listOf("a", "b"), "selection")),
            CollabMessage.Pointer("p1", PointerPos(3.5, 4.5)),
            CollabMessage.ElementUpdates(listOf(element("a", 2, 7))),
            CollabMessage.SceneSnapshot(listOf(element("a", 1, 1), element("b", 1, 2))),
            CollabMessage.Ping(1234L),
            CollabMessage.Ack(1234L),
        )
        for (m in messages) {
            assertEquals("round-trip failed for $m", m, CollabCodec.decode(CollabCodec.encode(m)))
        }
    }

    @Test
    fun presenceEmitsExplicitNullPointer() {
        val encoded = CollabCodec.encode(CollabMessage.PresenceUpdate("p1", Presence(null, emptyList(), "hand")))
        val presence = Json.parseToJsonElement(encoded).jsonObject["presence"]!!.jsonObject
        assertTrue("pointer key must be present", presence.containsKey("pointer"))
        assertTrue("pointer must be JSON null", presence["pointer"].toString() == "null")
        // and decode restores a null pointer
        val decoded = CollabCodec.decode(encoded) as CollabMessage.PresenceUpdate
        assertNull(decoded.presence.pointer)
    }

    @Test
    fun elementUpdatesPreservesFullElementObjects() {
        val el = Json.parseToJsonElement(
            """{"id":"a","type":"rectangle","x":1,"y":2,"width":3,"height":4,"version":5,"versionNonce":9,"customData":{"keep":"me"}}""",
        ).jsonObject
        val decoded = CollabCodec.decode(CollabCodec.encode(CollabMessage.ElementUpdates(listOf(el)))) as CollabMessage.ElementUpdates
        val back = decoded.elements.single()
        assertEquals("me", back["customData"]!!.jsonObject["keep"]!!.jsonPrimitive.content)
        assertEquals(5, back["version"]!!.jsonPrimitive.content.toInt())
    }

    @Test
    fun decodesRelayShapedRoomStateFixture() {
        // A frame exactly as the TypeScript relay emits it (keys in TS order).
        val fixture = """
            {"type":"room-state","protocol":1,"you":"p1",
             "peers":[{"id":"p1","name":"Ada","color":"#e64980"}],
             "elements":[{"id":"a","type":"rectangle","x":0,"y":0,"width":10,"height":10,"version":1,"versionNonce":5}]}
        """.trimIndent()
        val msg = CollabCodec.decode(fixture) as CollabMessage.RoomState
        assertEquals(1, msg.protocol)
        assertEquals("p1", msg.you)
        assertEquals("Ada", msg.peers.single().name)
        assertEquals("a", msg.elements.single()["id"]!!.jsonPrimitive.content)
    }

    @Test
    fun canonicalEncodeSortsKeysRecursively() {
        val canon = CollabCodec.canonicalEncode(CollabMessage.Join(1, "r", peer))
        // keys appear in sorted order: peer{color,id,name}, then protocol, room, type
        assertEquals(
            """{"peer":{"color":"#e64980","id":"p1","name":"Ada"},"protocol":1,"room":"r","type":"join"}""",
            canon,
        )
    }

    @Test
    fun rejectsUnknownType() {
        try {
            CollabCodec.decode("""{"type":"bogus"}""")
            throw AssertionError("expected ProtocolError")
        } catch (e: CollabCodec.ProtocolError) {
            assertTrue(e.message!!.contains("bogus"))
        }
    }
}

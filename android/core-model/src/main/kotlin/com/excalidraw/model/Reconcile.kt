package com.excalidraw.model

import kotlinx.serialization.json.JsonObject

/**
 * Element reconciliation — the deterministic, symmetric last-writer-wins rule
 * shared bit-for-bit with the Swift (`ExcalidrawCollab.Reconcile`) and
 * TypeScript (`excalidraw-svelte/protocol/reconcile`) clients: higher `version`
 * wins; ties break on the lower `versionNonce`. Both peers pick the same winner
 * with no central authority or CRDT, so a mixed iOS/web/Android room converges.
 */
object Reconcile {

    /** Whether [remote] should replace the same-id [local] element. */
    fun preferRemote(local: JsonObject, remote: JsonObject): Boolean {
        val lv = ElementView(local).version
        val rv = ElementView(remote).version
        if (rv != lv) return rv > lv
        return ElementView(remote).versionNonce < ElementView(local).versionNonce
    }

    fun reconcile(local: JsonObject, remote: JsonObject): JsonObject =
        if (preferRemote(local, remote)) remote else local

    private fun idOf(obj: JsonObject): String = ElementView(obj).id

    /**
     * Merge [remote] into [local] by id, preserving local order (winners
     * substituted in place) and appending remote-only elements in order.
     */
    fun reconcileElements(local: List<JsonObject>, remote: List<JsonObject>): List<JsonObject> {
        val remoteById = remote.associateBy(::idOf)
        val seen = HashSet<String>()
        val merged = ArrayList<JsonObject>(local.size + remote.size)
        for (localEl in local) {
            val id = idOf(localEl)
            val remoteEl = remoteById[id]
            merged.add(if (remoteEl == null) localEl else reconcile(localEl, remoteEl))
            seen.add(id)
        }
        for (remoteEl in remote) {
            if (seen.add(idOf(remoteEl))) merged.add(remoteEl)
        }
        return merged
    }

    /** Only the elements that actually changed (new id, or the remote version won). */
    fun changedByReconcile(local: List<JsonObject>, remote: List<JsonObject>): List<JsonObject> {
        val localById = local.associateBy(::idOf)
        return remote.filter { remoteEl ->
            val localEl = localById[idOf(remoteEl)]
            localEl == null || preferRemote(localEl, remoteEl)
        }
    }
}

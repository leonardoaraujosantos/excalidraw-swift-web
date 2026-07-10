import { EditorStore } from "@cyberdynecorp/excalidraw-svelte";
import { Point } from "@cyberdynecorp/excalidraw-svelte/math";
import { describe, expect, it } from "vitest";
import * as Y from "yjs";
import { YjsCollab } from "./yjs-collab.js";

/**
 * Interop guard for the web-canvas-interaction-parity change: double-click
 * labels travel over Yjs as ordinary elements, while theme toggles and
 * suggested-binding hovers are ephemeral and write nothing to the doc.
 */

function drawRect(store: EditorStore): void {
  store.selectTool("rectangle");
  store.pointer("down", new Point(100, 100));
  store.pointer("move", new Point(300, 200));
  store.pointer("up", new Point(300, 200));
  store.selectTool("selection");
}

function addLabel(store: EditorStore, value: string): void {
  store.doubleClickAt(new Point(200, 150));
  store.setEditingText(value);
  store.commitText();
}

describe("label interop over Yjs", () => {
  it("a double-click label syncs container and text to a peer", () => {
    const storeA = new EditorStore();
    const storeB = new EditorStore();
    const docA = new Y.Doc();
    const docB = new Y.Doc();
    new YjsCollab(storeA, docA).start();
    new YjsCollab(storeB, docB).start();

    drawRect(storeA);
    addLabel(storeA, "Hello");
    Y.applyUpdate(docB, Y.encodeStateAsUpdate(docA)); // A → B over the "wire"

    const text = storeB.scene.visibleElements.find((e) => e.type === "text");
    const container = storeB.scene.visibleElements.find((e) => e.type === "rectangle");
    expect(text?.text).toBe("Hello");
    expect(text?.containerId).toBe(container?.id);
    expect(container?.boundElements).toEqual([{ id: text?.id, type: "text" }]);
  });

  it("theme toggles and suggested-binding hovers write nothing to the doc", () => {
    const store = new EditorStore();
    const doc = new Y.Doc();
    new YjsCollab(store, doc).start();
    drawRect(store);

    let updates = 0;
    doc.on("update", () => {
      updates++;
    });
    store.toggleTheme();
    store.selectTool("arrow");
    store.trackPointer(new Point(200, 150)); // suggests the rectangle
    store.trackPointer(new Point(2000, 2000)); // clears the suggestion

    expect(updates).toBe(0);
  });
});

import * as Y from "yjs";

/**
 * A minimal same-origin Yjs provider over `BroadcastChannel` — zero server, no
 * native deps. It syncs a `Y.Doc` across browser tabs/pages sharing an origin:
 * local updates are broadcast; a joining peer requests the current state and
 * existing peers reply with a diff (so a reload re-hydrates from a live peer).
 *
 * This is the demo app's bundled provider (and what the Yjs E2E uses). The
 * adapter itself is provider-agnostic — in production bring y-websocket,
 * Hocuspocus, or a custom gateway and pass its `Y.Doc` to `YjsCollab`.
 */
type Message =
  | { t: "update"; u: Uint8Array }
  | { t: "query"; sv: Uint8Array };

export class BroadcastChannelProvider {
  private readonly channel: BroadcastChannel;

  constructor(
    private readonly doc: Y.Doc,
    room: string,
  ) {
    this.channel = new BroadcastChannel(`excalidraw-yjs:${room}`);
    this.channel.onmessage = (event: MessageEvent<Message>) => this.onMessage(event.data);
    this.doc.on("update", this.onUpdate);
    // Ask any live peer for the state we're missing (late-join / reload).
    this.channel.postMessage({ t: "query", sv: Y.encodeStateVector(this.doc) } satisfies Message);
  }

  private readonly onUpdate = (update: Uint8Array, origin: unknown): void => {
    if (origin === this) return; // don't echo updates we just applied
    this.channel.postMessage({ t: "update", u: update } satisfies Message);
  };

  private onMessage(message: Message): void {
    if (message.t === "update") {
      Y.applyUpdate(this.doc, message.u, this);
    } else {
      // Reply with everything the requester is missing.
      const diff = Y.encodeStateAsUpdate(this.doc, message.sv);
      this.channel.postMessage({ t: "update", u: diff } satisfies Message);
    }
  }

  destroy(): void {
    this.doc.off("update", this.onUpdate);
    this.channel.close();
  }
}

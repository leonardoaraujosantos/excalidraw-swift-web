<script lang="ts">
// The library panel: reusable element groups (.excalidrawlib). Items are a
// user asset — never part of the document — and persist in browser storage.
import { commonBounds } from "../geometry/index.js";
import type { ExcalidrawElement } from "../model/index.js";
import { Scene } from "../model/index.js";
import { exportSvg } from "../render/index.js";
import type { EditorStore } from "../svelte/editor-store.js";

const { store, rev, onClose }: { store: EditorStore; rev: number; onClose: () => void } = $props();

const items = $derived.by(() => {
  void rev;
  return store.libraryItems;
});

/** A small SVG preview of an item, scaled to fit the tile. */
function preview(elements: ExcalidrawElement[]): string {
  const box = commonBounds(elements);
  if (box === null) return "";
  return exportSvg(new Scene(elements.map((el) => ({ ...el }))), 8, "transparent");
}

let fileInput: HTMLInputElement;
let importError = $state<string | null>(null);

function onImport(e: Event): void {
  const file = (e.currentTarget as HTMLInputElement).files?.[0];
  (e.currentTarget as HTMLInputElement).value = "";
  if (file === undefined) return;
  importError = null;
  const reader = new FileReader();
  reader.onload = () => {
    const added = store.importLibrary(reader.result as string);
    if (added === 0) importError = "No library items found in that file.";
  };
  reader.readAsText(file);
}

function exportLibrary(): void {
  const blob = new Blob([store.exportLibrary()], { type: "application/json" });
  const a = document.createElement("a");
  a.href = URL.createObjectURL(blob);
  a.download = "library.excalidrawlib";
  a.click();
  URL.revokeObjectURL(a.href);
}
</script>

<aside class="island library" data-testid="library-panel">
  <header>
    <h3>Library</h3>
    <button class="tool slim" data-testid="library-close" title="Close library" aria-label="Close library" onclick={onClose}>×</button>
  </header>

  <div class="row wrap">
    <button class="chip" data-testid="library-import" onclick={() => fileInput.click()}>Import…</button>
    <button class="chip" data-testid="library-add" disabled={store.selectedCount === 0} onclick={() => store.addSelectionToLibrary()}>Add selection</button>
    <button class="chip" data-testid="library-export" disabled={items.length === 0} onclick={exportLibrary}>Export</button>
  </div>
  <input bind:this={fileInput} type="file" accept=".excalidrawlib,.excalidraw,application/json" hidden onchange={onImport} />
  {#if importError !== null}
    <p class="error" data-testid="library-error">{importError}</p>
  {/if}

  {#if items.length === 0}
    <p class="empty">Nothing here yet — select something and choose <em>Add selection</em>, or import a <code>.excalidrawlib</code>.</p>
  {:else}
    <div class="grid">
      {#each items as item, i (i)}
        <div class="tile">
          <button
            class="tile-insert"
            data-testid={`library-item-${i}`}
            title="Insert into the canvas"
            onclick={() => store.insertLibraryItem(i)}
          >
            <!-- eslint-disable-next-line svelte/no-at-html-tags — locally generated SVG -->
            {@html preview(item)}
          </button>
          <button
            class="tile-remove"
            data-testid={`library-remove-${i}`}
            title="Remove from the library"
            aria-label="Remove from the library"
            onclick={() => store.removeLibraryItem(i)}
          >×</button>
        </div>
      {/each}
    </div>
  {/if}
</aside>

<style>
  .library {
    position: absolute;
    top: 80px;
    right: 16px;
    z-index: 6;
    width: 260px;
    max-height: calc(100% - 160px);
    overflow-y: auto;
    padding: 12px 14px;
    display: flex;
    flex-direction: column;
    gap: 10px;
  }
  header { display: flex; align-items: center; justify-content: space-between; }
  h3 { margin: 0; font-size: 13px; font-weight: 600; }
  .row { display: flex; gap: 6px; }
  .row.wrap { flex-wrap: wrap; }
  .empty { margin: 0; font-size: 12.5px; color: var(--excal-muted); line-height: 1.5; }
  .error { margin: 0; font-size: 12.5px; color: #e03131; }
  .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
  .tile { position: relative; }
  .tile-insert {
    width: 100%;
    height: 76px;
    display: grid;
    place-items: center;
    padding: 6px;
    border: 1px solid var(--excal-border);
    border-radius: 8px;
    background: transparent;
    cursor: pointer;
    overflow: hidden;
  }
  .tile-insert:hover { background: var(--excal-hover); }
  /* The preview carries a viewBox, so a 100% box scales it to fit the tile
     (max-width/height alone leaves the intrinsic px size and clips). */
  .tile-insert :global(svg) { width: 100%; height: 100%; }
  .tile-remove {
    position: absolute;
    top: -6px;
    right: -6px;
    width: 18px;
    height: 18px;
    display: grid;
    place-items: center;
    padding: 0;
    font-size: 12px;
    line-height: 1;
    color: var(--excal-ink);
    background: var(--excal-island);
    border: 1px solid var(--excal-border);
    border-radius: 50%;
    cursor: pointer;
    opacity: 0;
  }
  .tile:hover .tile-remove { opacity: 1; }
</style>

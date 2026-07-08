# @cyberdynecorp/excalidraw-svelte

The web (TypeScript / Svelte 5) implementation of the [Excalidraw port](https://github.com/CyberdyneCorp/excalidraw-native) — the twin of the native Swift/SwiftUI port, sharing the same data model, `.excalidraw` v2 file format, and collaboration wire protocol.

A single package with **subpath exports** for each layer, so you install one dependency and import only what you use (tree-shakeable, `sideEffects: false`):

| Import | Layer |
| --- | --- |
| `@cyberdynecorp/excalidraw-svelte` | Reactive Svelte 5 editor store (the headline API) |
| `@cyberdynecorp/excalidraw-svelte/svelte` | Same as the root entry |
| `@cyberdynecorp/excalidraw-svelte/editor` | Framework-agnostic editor: tools, commands, transforms, bindings |
| `@cyberdynecorp/excalidraw-svelte/render` | Canvas2D + SVG rendering, rough.js options, PNG scene-embed |
| `@cyberdynecorp/excalidraw-svelte/geometry` | Hit-testing, bounding boxes, snapping, elbow arrows, shape recognition |
| `@cyberdynecorp/excalidraw-svelte/model` | Element model, scene, `.excalidraw` v2 restore/round-trip, libraries |
| `@cyberdynecorp/excalidraw-svelte/math` | Points, vectors, matrices, numeric primitives |
| `@cyberdynecorp/excalidraw-svelte/protocol` | Collaboration wire format: messages, codec, reconciliation |

The collaboration **relay server** ships separately as [`@cyberdynecorp/excalidraw-relay`](https://github.com/CyberdyneCorp/excalidraw-native/tree/main/web/server) (it's a Node WebSocket server, not a browser library).

## Install (GitHub Packages)

These packages are published to the CyberdyneCorp GitHub Packages registry. Add an `.npmrc` next to your `package.json`:

```ini
@cyberdynecorp:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=${GITHUB_TOKEN}
```

Then export a token with `read:packages` and install:

```sh
export GITHUB_TOKEN=$(gh auth token)
npm install @cyberdynecorp/excalidraw-svelte
```

## Usage

```ts
import { EditorStore } from "@cyberdynecorp/excalidraw-svelte";
import { reconcileElements } from "@cyberdynecorp/excalidraw-svelte/protocol";
import type { ExcalidrawElement } from "@cyberdynecorp/excalidraw-svelte/model";
import { Point } from "@cyberdynecorp/excalidraw-svelte/math";
```

## License

MIT © Cyberdyne Corp AI

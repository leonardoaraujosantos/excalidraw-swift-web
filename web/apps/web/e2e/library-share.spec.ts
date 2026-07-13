import { type RelayHandle, startRelay } from "@cyberdynecorp/excalidraw-relay";
import { expect, test } from "@playwright/test";
import { drag, elementCount, ready, selectTool } from "./helpers.js";

/** Library panel & share dialog (web-library-and-share) — the last Phase 4
 * items: reusable `.excalidrawlib` items, and starting a collaboration session
 * from the UI instead of by hand-editing URL parameters. */

function readStore<T>(page, fn: (s: never) => T): Promise<T> {
  return page.evaluate(
    ([f]) => new Function("s", `return (${f})(s)`)((window as never as { __store: never }).__store),
    [fn.toString()] as const,
  );
}

const libraryCount = (page) =>
  readStore(page, (s: never) => (s as { libraryItems: unknown[] }).libraryItems.length);

/** A two-item `.excalidrawlib` document. */
const LIBRARY_FILE = JSON.stringify({
  type: "excalidrawlib",
  version: 2,
  libraryItems: [
    { elements: [{ id: "l1", type: "rectangle", x: 0, y: 0, width: 60, height: 40 }] },
    { elements: [{ id: "l2", type: "ellipse", x: 0, y: 0, width: 50, height: 50 }] },
  ],
});

test.describe("library", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
    await ready(page);
    // Each test starts from an empty library (it persists across reloads).
    await readStore(page, (s: never) => {
      (s as { libraryItems: unknown[] }).libraryItems = [];
    });
  });

  test("import a .excalidrawlib, insert an item, and export", async ({ page }) => {
    await page.getByTestId("app-menu").click();
    await page.getByTestId("menu-library").click();
    await expect(page.getByTestId("library-panel")).toBeVisible();

    await page.setInputFiles('[data-testid="library-panel"] input[type="file"]', {
      name: "shapes.excalidrawlib",
      mimeType: "application/json",
      buffer: Buffer.from(LIBRARY_FILE),
    });
    await expect.poll(async () => await libraryCount(page)).toBe(2);
    await expect(page.getByTestId("library-item-0")).toBeVisible();

    // Clicking an item stamps it on the canvas as a selected group.
    expect(await elementCount(page)).toBe(0);
    await page.getByTestId("library-item-0").click();
    await expect.poll(async () => await elementCount(page)).toBe(1);
    expect(await readStore(page, (s: never) => (s as { selectedCount: number }).selectedCount)).toBe(
      1,
    );
    expect(await libraryCount(page)).toBe(2); // the item stays in the library

    const download = page.waitForEvent("download");
    await page.getByTestId("library-export").click();
    expect((await download).suggestedFilename()).toBe("library.excalidrawlib");
  });

  test("add the selection to the library, and it survives a reload", async ({ page }) => {
    await selectTool(page, "rectangle");
    await drag(page, { x: 0.3, y: 0.3 }, { x: 0.5, y: 0.5 }); // stays selected

    await page.getByTestId("app-menu").click();
    await page.getByTestId("menu-library").click();
    await page.getByTestId("library-add").click();
    await expect.poll(async () => await libraryCount(page)).toBe(1);
    expect(await elementCount(page)).toBe(1); // the scene is untouched

    // Persistence: the library is host state, not document content.
    await page.reload();
    await ready(page);
    expect(await libraryCount(page)).toBe(1);
  });

  test("remove an item", async ({ page }) => {
    await page.evaluate((lib) => {
      (window as never as { __store: { importLibrary(j: string): number } }).__store.importLibrary(
        lib,
      );
    }, LIBRARY_FILE);
    await page.getByTestId("app-menu").click();
    await page.getByTestId("menu-library").click();
    await expect.poll(async () => await libraryCount(page)).toBe(2);

    await page.getByTestId("library-remove-0").click({ force: true });
    await expect.poll(async () => await libraryCount(page)).toBe(1);
  });
});

test.describe("share", () => {
  let relay: RelayHandle;
  let port = 0;

  test.beforeAll(async () => {
    relay = startRelay(0);
    await new Promise<void>((resolve) => relay.wss.on("listening", resolve));
    const addr = relay.wss.address();
    port = typeof addr === "object" && addr !== null ? addr.port : 0;
  });
  test.afterAll(async () => {
    await relay.close();
  });

  test("start a session from the dialog; a second browser joins the link", async ({ browser }) => {
    const relayUrl = `ws://127.0.0.1:${port}`;
    const alice = await browser.newPage();
    await alice.goto(`/?relay=${encodeURIComponent(relayUrl)}&name=Alice`);
    await ready(alice);

    // Start a session from the UI (no URL hand-editing).
    await alice.getByTestId("app-menu").click();
    await alice.getByTestId("menu-share").click();
    await expect(alice.getByTestId("share-dialog")).toBeVisible();
    await alice.getByTestId("share-start").click();

    const link = await alice.getByTestId("share-link").inputValue();
    expect(link).toContain("room=");
    await expect
      .poll(async () =>
        alice.evaluate(
          () =>
            (window as never as { __store: { isCollaborating: boolean } }).__store.isCollaborating,
        ),
      )
      .toBe(true);

    // A second browser opens the invite link and both converge.
    const bob = await browser.newPage();
    await bob.goto(link.replace(/name=Alice/, "name=Bob") + "&name=Bob");
    await ready(bob);

    await alice.getByTestId("share-close").click();
    await selectTool(alice, "rectangle");
    await drag(alice, { x: 0.3, y: 0.3 }, { x: 0.5, y: 0.5 });

    await expect.poll(async () => await elementCount(bob)).toBe(1); // edits converge
    await expect
      .poll(async () =>
        alice.evaluate(
          () => (window as never as { __store: { collabPeers: unknown[] } }).__store.collabPeers.length,
        ),
      )
      .toBeGreaterThan(0); // each sees the other

    // Leaving stops the session and leaves the scene alone.
    await alice.getByTestId("app-menu").click();
    await alice.getByTestId("menu-share").click();
    await alice.getByTestId("share-leave").click();
    expect(
      await alice.evaluate(
        () => (window as never as { __store: { isCollaborating: boolean } }).__store.isCollaborating,
      ),
    ).toBe(false);
    expect(await elementCount(alice)).toBe(1);

    await alice.close();
    await bob.close();
  });
});

test("an embedder can hide the library and share (uiOptions)", async ({ page }) => {
  await page.goto("/embed.html?noLibraryShare=1");
  await ready(page);

  await expect(page.getByTestId("app-menu")).toBeVisible();
  await page.getByTestId("app-menu").click();
  await expect(page.getByTestId("menu-library")).toHaveCount(0);
  await expect(page.getByTestId("menu-share")).toHaveCount(0);

  // Hiding the chrome does not remove the capability.
  const imported = await page.evaluate((lib) => {
    const st = (window as never as { __store: { importLibrary(j: string): number } }).__store;
    return st.importLibrary(lib);
  }, LIBRARY_FILE);
  expect(imported).toBe(2);
});

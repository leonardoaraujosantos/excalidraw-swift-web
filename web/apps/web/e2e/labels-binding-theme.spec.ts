import { expect, test } from "@playwright/test";
import { drag, ready, selectTool, shot } from "./helpers.js";

/**
 * Regression suite for the web-canvas-interaction-parity change: double-click
 * labels, canvas text, suggested-binding affordances, and dark-theme element
 * legibility. Mirrors the excalidraw.com behaviours from the 2026-07 audit.
 */

test.beforeEach(async ({ page }) => {
  await page.goto("/");
  await ready(page);
});

async function canvasPoint(page, fx: number, fy: number) {
  const box = (await page.getByTestId("canvas").boundingBox())!;
  return { x: box.x + box.width * fx, y: box.y + box.height * fy };
}

/** Read arbitrary store state (beyond the typed helpers' StoreView). */
function readStore<T>(page, fn: (s: never) => T): Promise<T> {
  return page.evaluate(
    ([f]) => new Function("s", `return (${f})(s)`)((window as never as { __store: never }).__store),
    [fn.toString()] as const,
  );
}

test("double-clicking a shape adds a bound label without switching tools", async ({ page }) => {
  await selectTool(page, "rectangle");
  await drag(page, { x: 0.3, y: 0.3 }, { x: 0.5, y: 0.5 });
  await selectTool(page, "selection");

  const c = await canvasPoint(page, 0.4, 0.4);
  await page.mouse.dblclick(c.x, c.y);
  await expect(page.getByTestId("text-editor")).toBeVisible();

  await page.keyboard.type("Hello");
  await page.keyboard.press("Enter");
  await expect(page.getByTestId("text-editor")).toHaveCount(0);

  const label = await readStore(page, (s: never) => {
    const st = s as {
      scene: { visibleElements: { type: string; text?: string; containerId?: string | null }[] };
    };
    return st.scene.visibleElements.find((e) => e.type === "text") ?? null;
  });
  expect(label?.text).toBe("Hello");
  expect(label?.containerId).not.toBeNull();
  // The "o" in "Hello" must not have activated the ellipse tool.
  expect(await readStore(page, (s: never) => (s as { activeTool: string }).activeTool)).toBe(
    "selection",
  );
  await shot(page, "label-on-shape");
});

test("the label editor caret starts centred in the shape", async ({ page }) => {
  await selectTool(page, "rectangle");
  await drag(page, { x: 0.3, y: 0.3 }, { x: 0.5, y: 0.5 });
  await selectTool(page, "selection");
  const c = await canvasPoint(page, 0.4, 0.4);
  await page.mouse.dblclick(c.x, c.y);

  const editor = page.getByTestId("text-editor");
  await expect(editor).toBeVisible();
  const style = await editor.evaluate((el) => {
    const cs = getComputedStyle(el);
    return {
      textAlign: cs.textAlign,
      padTop: Number.parseFloat(cs.paddingTop),
      height: Number.parseFloat(cs.height),
    };
  });
  // Horizontally centred text, vertically centred line block: for a one-line
  // empty label the top padding is (container height − 25px line) / 2.
  expect(style.textAlign).toBe("center");
  expect(style.padTop).toBeCloseTo((style.height - 25) / 2, 0);

  // Adding a line re-centres: padding shrinks by half a line height.
  await page.keyboard.type("a");
  await page.keyboard.press("Shift+Enter");
  await page.keyboard.type("b");
  await page.waitForTimeout(150); // the 40ms revision poll re-renders the padding
  const padTwoLines = await editor.evaluate((el) =>
    Number.parseFloat(getComputedStyle(el).paddingTop),
  );
  expect(padTwoLines).toBeCloseTo(style.padTop - 12.5, 0);
  await page.keyboard.press("Escape");
});

test("double-clicking empty canvas creates a text element in place", async ({ page }) => {
  const p = await canvasPoint(page, 0.7, 0.7);
  await page.mouse.dblclick(p.x, p.y);
  await expect(page.getByTestId("text-editor")).toBeVisible();
  await page.keyboard.type("Quick text");
  await page.keyboard.press("Escape"); // Escape commits too

  const text = await readStore(page, (s: never) => {
    const st = s as {
      scene: { visibleElements: { type: string; text?: string; containerId?: string | null }[] };
    };
    return st.scene.visibleElements.find((e) => e.type === "text") ?? null;
  });
  expect(text?.text).toBe("Quick text");
  expect(text?.containerId).toBeNull();
});

test("text-tool text commits when clicking outside the editor", async ({ page }) => {
  await selectTool(page, "text");
  const at = await canvasPoint(page, 0.4, 0.4);
  await page.mouse.click(at.x, at.y);
  await expect(page.getByTestId("text-editor")).toBeVisible();
  await page.keyboard.type("Hi");

  // Click elsewhere on the canvas: the edit commits, nothing else happens.
  const away = await canvasPoint(page, 0.7, 0.7);
  await page.mouse.click(away.x, away.y);
  await expect(page.getByTestId("text-editor")).toHaveCount(0);

  const texts = await readStore(page, (s: never) => {
    const st = s as { scene: { visibleElements: { type: string; text?: string }[] } };
    return st.scene.visibleElements.filter((e) => e.type === "text").map((e) => e.text);
  });
  expect(texts).toEqual(["Hi"]);
  expect(await readStore(page, (s: never) => (s as { activeTool: string }).activeTool)).toBe(
    "selection",
  );
});

test("double-clicking a line still enters point editing (priority regression)", async ({
  page,
}) => {
  await selectTool(page, "line");
  await drag(page, { x: 0.2, y: 0.8 }, { x: 0.4, y: 0.9 });
  await selectTool(page, "selection");

  const start = await canvasPoint(page, 0.2, 0.8);
  await page.mouse.dblclick(start.x, start.y);
  expect(
    await readStore(page, (s: never) => (s as { isLinearEditing: boolean }).isLinearEditing),
  ).toBe(true);
  expect(
    await readStore(page, (s: never) => (s as { editingText: unknown }).editingText),
  ).toBeNull();
});

test("arrow tool suggests bindings on hover and bound arrows follow moved shapes", async ({
  page,
}) => {
  await selectTool(page, "rectangle");
  await drag(page, { x: 0.3, y: 0.35 }, { x: 0.44, y: 0.55 });
  await selectTool(page, "rectangle");
  await drag(page, { x: 0.62, y: 0.35 }, { x: 0.76, y: 0.55 });

  // Hovering with the arrow tool highlights the shape under the cursor.
  await selectTool(page, "arrow");
  const inFirst = await canvasPoint(page, 0.37, 0.45);
  await page.mouse.move(inFirst.x, inFirst.y, { steps: 3 });
  const suggested = await readStore(
    page,
    (s: never) =>
      (s as { controller: { suggestedBindingID: string | null } }).controller.suggestedBindingID,
  );
  expect(suggested).not.toBeNull();
  await page.waitForTimeout(120); // let the 40ms revision poll repaint the ring
  await shot(page, "arrow-hover-highlight");

  // Moving away clears it.
  const away = await canvasPoint(page, 0.1, 0.9);
  await page.mouse.move(away.x, away.y, { steps: 3 });
  expect(
    await readStore(
      page,
      (s: never) =>
        (s as { controller: { suggestedBindingID: string | null } }).controller.suggestedBindingID,
    ),
  ).toBeNull();

  // An arrow drawn between the shapes binds on both ends…
  await drag(page, { x: 0.445, y: 0.45 }, { x: 0.615, y: 0.45 });
  const bindings = await readStore(page, (s: never) => {
    const st = s as {
      scene: { visibleElements: { type: string; startBinding?: unknown; endBinding?: unknown }[] };
    };
    const a = st.scene.visibleElements.find((e) => e.type === "arrow");
    return { start: a?.startBinding ?? null, end: a?.endBinding ?? null };
  });
  expect(bindings.start).not.toBeNull();
  expect(bindings.end).not.toBeNull();

  // …and follows when the target is dragged by its edge.
  await selectTool(page, "selection");
  await drag(page, { x: 0.69, y: 0.35 }, { x: 0.69, y: 0.65 });
  const arrowHeight = await readStore(page, (s: never) => {
    const st = s as { scene: { visibleElements: { type: string; height: number }[] } };
    return st.scene.visibleElements.find((e) => e.type === "arrow")?.height ?? 0;
  });
  expect(arrowHeight).toBeGreaterThan(50);
});

test("click-to-connect: click the source shape, then click the destination", async ({ page }) => {
  await selectTool(page, "rectangle");
  await drag(page, { x: 0.3, y: 0.35 }, { x: 0.44, y: 0.55 });
  await selectTool(page, "rectangle");
  await drag(page, { x: 0.62, y: 0.35 }, { x: 0.76, y: 0.55 });
  await selectTool(page, "arrow");

  // Click (no drag) on the first shape's right-edge anchor…
  const src = await canvasPoint(page, 0.44, 0.45);
  await page.mouse.move(src.x, src.y, { steps: 3 });
  await page.mouse.click(src.x, src.y);
  expect(
    await readStore(
      page,
      (s: never) =>
        (s as { controller: { pendingLinearID: string | null } }).controller.pendingLinearID,
    ),
  ).not.toBeNull();

  // …hover toward the destination (live preview + its anchors show)…
  const mid = await canvasPoint(page, 0.55, 0.45);
  await page.mouse.move(mid.x, mid.y, { steps: 4 });
  await page.waitForTimeout(120);
  await shot(page, "click-connect-preview");

  // …and click inside the second shape to finish, bound on both ends.
  const dst = await canvasPoint(page, 0.69, 0.45);
  await page.mouse.move(dst.x, dst.y, { steps: 4 });
  await page.mouse.click(dst.x, dst.y);
  const arrow = await readStore(page, (s: never) => {
    const st = s as {
      scene: { visibleElements: { type: string; startBinding?: unknown; endBinding?: unknown }[] };
    };
    const a = st.scene.visibleElements.find((e) => e.type === "arrow");
    return a ? { start: a.startBinding ?? null, end: a.endBinding ?? null } : null;
  });
  expect(arrow?.start).not.toBeNull();
  expect(arrow?.end).not.toBeNull();
  expect(await readStore(page, (s: never) => (s as { activeTool: string }).activeTool)).toBe(
    "selection",
  );
});

test("number shortcuts select tools and the hand tool pans", async ({ page }) => {
  const activeTool = () =>
    readStore(page, (s: never) => (s as { activeTool: string }).activeTool);
  await page.keyboard.press("2");
  expect(await activeTool()).toBe("rectangle");
  await page.keyboard.press("5");
  expect(await activeTool()).toBe("arrow");
  await page.keyboard.press("8");
  expect(await activeTool()).toBe("text");
  await page.keyboard.press("1");
  expect(await activeTool()).toBe("selection");

  // The hand tool pans the canvas by dragging.
  await page.keyboard.press("h");
  await drag(page, { x: 0.5, y: 0.5 }, { x: 0.6, y: 0.6 });
  const scroll = await readStore(
    page,
    (s: never) => (s as { viewport: { scrollX: number } }).viewport.scrollX,
  );
  expect(scroll).toBeGreaterThan(50);
});

test("dark theme keeps drawings visible and exports stay canonical", async ({ page }) => {
  await selectTool(page, "rectangle");
  await drag(page, { x: 0.3, y: 0.3 }, { x: 0.6, y: 0.6 });
  await page.getByTestId("theme").click();

  // Sample the canvas along the rectangle's top edge: in dark theme the
  // mapped stroke must be light against the dark background.
  const box = (await page.getByTestId("canvas").boundingBox())!;
  const maxLuma = await page.evaluate(
    ([w]) => {
      const canvas = document.querySelector('[data-testid="canvas"]') as HTMLCanvasElement;
      const ctx = canvas.getContext("2d")!;
      const dpr = window.devicePixelRatio || 1;
      // A horizontal strip crossing the top edge of the rectangle (30%..60% x,
      // 30% y of the canvas), a few pixels tall to absorb the sloppy stroke.
      const y0 = Math.floor(0.3 * (canvas.height / dpr) - 6) * dpr;
      const data = ctx.getImageData(
        Math.floor(0.32 * w * dpr),
        y0,
        Math.floor(0.2 * w * dpr),
        12 * dpr,
      ).data;
      let max = 0;
      for (let i = 0; i < data.length; i += 4) {
        const luma = 0.2126 * data[i]! + 0.7152 * data[i + 1]! + 0.0722 * data[i + 2]!;
        if (luma > max) max = luma;
      }
      return max;
    },
    [box.width] as const,
  );
  expect(maxLuma).toBeGreaterThan(150); // light ink present, not black-on-black
  await shot(page, "dark-theme-visible");

  // The document JSON still carries canonical (light-theme) colours.
  const stroke = await readStore(page, (s: never) => {
    const doc = JSON.parse((s as { documentJSON(): string }).documentJSON()) as {
      elements: { type: string; strokeColor: string }[];
    };
    return doc.elements.find((e) => e.type === "rectangle")?.strokeColor;
  });
  expect(stroke).toBe("#1e1e1e");
});

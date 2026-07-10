import { describe, expect, it } from "vitest";
import { FontFamily } from "./model/enums.js";
import { fontFamilyCss, fontString, measureTextWidth, wrapTextLines } from "./text-measure.js";

describe("text-measure", () => {
  it("maps font families to the right CSS stacks (parity with iOS fallbacks)", () => {
    expect(fontFamilyCss(FontFamily.default)).toContain("Excalifont");
    expect(fontFamilyCss(FontFamily.default)).toContain("cursive");
    expect(fontFamilyCss(FontFamily.virgil)).toContain("Bradley Hand");
    expect(fontFamilyCss(FontFamily.cascadia)).toContain("monospace");
    expect(fontFamilyCss(FontFamily.comicShanns)).toContain("monospace");
    expect(fontFamilyCss(FontFamily.helvetica)).toContain("sans-serif");
    // Unknown ids fall back to the hand-drawn stack.
    expect(fontFamilyCss(999)).toContain("Excalifont");
  });

  it("builds a Canvas/CSS font shorthand", () => {
    expect(fontString(20, FontFamily.default)).toBe(`20px ${fontFamilyCss(FontFamily.default)}`);
  });

  it("falls back to the fontSize·0.6 heuristic without a DOM", () => {
    // Under vitest's node environment there is no `document`, so the heuristic
    // is used — this keeps unit tests and golden fixtures deterministic.
    expect(measureTextWidth("hello", 20, FontFamily.default)).toBeCloseTo(5 * 20 * 0.6, 6);
    // Width is the widest line.
    expect(measureTextWidth("hi\nlonger line", 10, FontFamily.default)).toBeCloseTo(
      "longer line".length * 10 * 0.6,
      6,
    );
    expect(measureTextWidth("", 20, FontFamily.default)).toBe(0);
  });
});

describe("wrapTextLines", () => {
  // Non-DOM heuristic: width = chars × fontSize × 0.6 → 12px/char at size 20.
  it("wraps words to the max width and breaks over-long words by character", () => {
    const lines = wrapTextLines("aa bb cc", 20, 5, 60); // 5 chars max per line
    expect(lines).toEqual(["aa bb", "cc"]);

    const broken = wrapTextLines("abcdefghij", 20, 5, 48); // 4 chars per line
    expect(broken).toEqual(["abcd", "efgh", "ij"]);
    expect(broken.every((l) => l.length * 12 <= 48)).toBe(true);
  });

  it("honours explicit newlines and never drops characters", () => {
    const lines = wrapTextLines("one two\nthree", 20, 5, 1000);
    expect(lines).toEqual(["one two", "three"]);
    expect(wrapTextLines("", 20, 5, 100)).toEqual([""]);
  });
});

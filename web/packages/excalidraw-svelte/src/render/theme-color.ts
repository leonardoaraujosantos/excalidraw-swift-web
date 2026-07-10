/**
 * Dark-theme colour mapping for painted element parts.
 *
 * The scene model always stores canonical (light-theme) colours; when the dark
 * theme is active the renderer maps each colour at paint time with the
 * arithmetic equivalent of excalidraw.com's canvas filter
 * `invert(93%) hue-rotate(180deg)`. Doing the math per colour (instead of a
 * whole-canvas `ctx.filter`) keeps images and the interactive overlay
 * untouched, works on every browser, and is unit-testable.
 */
import type { Theme } from "./scene-renderer.js";

const darkCache = new Map<string, string>();

/** Map a canonical colour for painting under `theme`. Non-hex values (e.g.
 * `"transparent"`) pass through unchanged; alpha digits are preserved. */
export function themeColor(color: string, theme: Theme): string {
  if (theme === "light") return color;
  let mapped = darkCache.get(color);
  if (mapped === undefined) {
    mapped = darkMapped(color);
    darkCache.set(color, mapped);
  }
  return mapped;
}

function darkMapped(color: string): string {
  const parsed = parseHex(color);
  if (parsed === null) return color;
  // invert(93%): c' = 0.93 − 0.86·c per channel.
  const [r, g, b] = parsed.rgb.map((c) => 0.93 - 0.86 * c) as [number, number, number];
  // hue-rotate(180deg): the SVG feColorMatrix hueRotate matrix at 180°.
  const rr = clamp01(-0.574 * r + 1.43 * g + 0.144 * b);
  const gg = clamp01(0.426 * r + 0.43 * g + 0.144 * b);
  const bb = clamp01(0.426 * r + 1.43 * g - 0.856 * b);
  return `#${hex2(rr)}${hex2(gg)}${hex2(bb)}${parsed.alpha}`;
}

function clamp01(v: number): number {
  return v < 0 ? 0 : v > 1 ? 1 : v;
}

function hex2(unit: number): string {
  return Math.round(unit * 255)
    .toString(16)
    .padStart(2, "0");
}

/** Parse `#rgb`, `#rgba`, `#rrggbb`, or `#rrggbbaa`; alpha kept as raw digits. */
function parseHex(color: string): { rgb: number[]; alpha: string } | null {
  if (!color.startsWith("#")) return null;
  const body = color.slice(1);
  if (body.length === 3 || body.length === 4) {
    const digits = body.split("");
    if (digits.some((d) => Number.isNaN(Number.parseInt(d, 16)))) return null;
    const rgb = digits.slice(0, 3).map((d) => Number.parseInt(d + d, 16) / 255);
    const a = digits[3];
    return { rgb, alpha: a === undefined ? "" : a + a };
  }
  if (body.length === 6 || body.length === 8) {
    const pairs = [body.slice(0, 2), body.slice(2, 4), body.slice(4, 6)];
    const rgb = pairs.map((p) => Number.parseInt(p, 16) / 255);
    if (rgb.some(Number.isNaN)) return null;
    return { rgb, alpha: body.slice(6) };
  }
  return null;
}

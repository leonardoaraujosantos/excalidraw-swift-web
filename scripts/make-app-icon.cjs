// Generate the iOS app icon using the project's own rough.js engine, so the
// app's hand-drawn rendering style draws its own icon. Outputs an SVG composited
// on a violet gradient; rsvg-convert turns it into the 1024 PNG.
const roughModule = require(require.resolve("roughjs", { paths: [require("node:path").join(__dirname, "..", "web")] }));
const rough = roughModule.default ?? roughModule;
const gen = rough.generator();

function opsToPath(drawable, kind) {
  // kind: "stroke" → outline sets ("path"); "fill" → hachure sets ("fillSketch")
  const want = kind === "fill" ? "fillSketch" : "path";
  let d = "";
  for (const set of drawable.sets) {
    if (set.type !== want) continue;
    for (const op of set.ops) {
      const p = op.data;
      if (op.op === "move") d += `M${p[0]} ${p[1]} `;
      else if (op.op === "lineTo") d += `L${p[0]} ${p[1]} `;
      else if (op.op === "bcurveTo") d += `C${p[0]} ${p[1]} ${p[2]} ${p[3]} ${p[4]} ${p[5]} `;
    }
  }
  return d.trim();
}

const INK = "#ffffff"; // hand-drawn shapes are white on the violet ground
const CORAL = "#ff8787";
const YELLOW = "#ffd43b";
const TEAL = "#63e6be";

// A friendly little diagram: a sketchy "node" rectangle, an accent circle, and a
// connecting hand-drawn arrow — the universal whiteboard motif.
const shapes = [];
function add(drawable, { stroke, sw, fill }) {
  const outline = opsToPath(drawable, "stroke");
  const hatch = opsToPath(drawable, "fill");
  if (hatch) shapes.push(`<path d="${hatch}" fill="none" stroke="${fill}" stroke-width="4" stroke-linecap="round" opacity="0.9"/>`);
  if (outline) shapes.push(`<path d="${outline}" fill="none" stroke="${stroke}" stroke-width="${sw}" stroke-linecap="round" stroke-linejoin="round"/>`);
}

const ro = { roughness: 1.15, bowing: 1.4, seed: 7 };
// Rectangle node (top-left)
add(gen.rectangle(196, 250, 380, 250, { ...ro, stroke: INK, strokeWidth: 12 }), { stroke: INK, sw: 12 });
// Accent circle (bottom-right), hachure-filled coral
add(gen.ellipse(720, 690, 250, 250, { ...ro, seed: 11, stroke: INK, strokeWidth: 12, fill: CORAL, fillStyle: "hachure", hachureGap: 22, fillWeight: 5 }), { stroke: INK, sw: 12, fill: CORAL });
// Small diamond accent (top-right), teal
add(gen.polygon([[760, 250], [850, 340], [760, 430], [670, 340]], { ...ro, seed: 3, stroke: INK, strokeWidth: 10, fill: TEAL, fillStyle: "hachure", hachureGap: 18, fillWeight: 4 }), { stroke: INK, sw: 10, fill: TEAL });
// Hand-drawn arrow from rectangle to circle
add(gen.linearPath([[470, 470], [600, 600]], { ...ro, seed: 5, stroke: YELLOW, strokeWidth: 13 }), { stroke: YELLOW, sw: 13 });
// Arrowhead (two clear strokes back from the tip)
add(gen.linearPath([[600, 600], [543, 592]], { ...ro, seed: 6, stroke: YELLOW, strokeWidth: 13 }), { stroke: YELLOW, sw: 13 });
add(gen.linearPath([[600, 600], [592, 543]], { ...ro, seed: 8, stroke: YELLOW, strokeWidth: 13 }), { stroke: YELLOW, sw: 13 });

const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#7048e8"/>
      <stop offset="1" stop-color="#5f3dc4"/>
    </linearGradient>
  </defs>
  <rect x="0" y="0" width="1024" height="1024" fill="url(#bg)"/>
  ${shapes.join("\n  ")}
</svg>`;

const path=require("node:path");require("node:fs").writeFileSync(path.join(__dirname,"app-icon.svg"), svg);
console.log("wrote icon.svg with", shapes.length, "paths. Now run: rsvg-convert -w 1024 -h 1024 icon.svg | python3 flatten -> icon-1024.png");

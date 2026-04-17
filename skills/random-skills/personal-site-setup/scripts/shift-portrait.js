#!/usr/bin/env node
/**
 * shift-portrait.js — align a portrait's paper/background tone to the page color.
 *
 * Reads the four corner blocks of a source JPEG to estimate the background
 * color, computes the per-channel delta to the target hex, and applies that
 * uniform shift to every pixel. Preserves texture and shading — only the
 * paper tone slides to match.
 *
 * Usage:
 *   node shift-portrait.js <source.jpg> <output.jpg> [target-hex]
 *
 * Example:
 *   node shift-portrait.js raw.jpg assets/portrait.jpg "#fbf7eb"
 *   node shift-portrait.js raw.jpg assets/portrait.jpg "#0f1115"   # dark theme
 *
 * Dependencies:
 *   npm install jimp@0.22
 */

const Jimp = require("jimp");

const DEFAULT_TARGET = "#fbf7eb";
const MAX_SIDE = 720;

function parseHex(hex) {
  const m = /^#?([0-9a-fA-F]{6})$/.exec(hex.trim());
  if (!m) throw new Error(`not a 6-digit hex: ${hex}`);
  const n = parseInt(m[1], 16);
  return { r: (n >> 16) & 0xff, g: (n >> 8) & 0xff, b: n & 0xff };
}

async function main() {
  const [, , src, out, targetArg] = process.argv;
  if (!src || !out) {
    console.error("usage: node shift-portrait.js <source.jpg> <output.jpg> [target-hex]");
    process.exit(1);
  }
  const TARGET = parseHex(targetArg || DEFAULT_TARGET);

  const img = await Jimp.read(src);
  const w = img.bitmap.width;
  const h = img.bitmap.height;

  const boxes = [
    { x0: 0,       y0: 0,       x1: 20,  y1: 20 },
    { x0: w - 20,  y0: 0,       x1: w,   y1: 20 },
    { x0: 0,       y0: h - 20,  x1: 20,  y1: h  },
    { x0: w - 20,  y0: h - 20,  x1: w,   y1: h  },
  ];
  let rSum = 0, gSum = 0, bSum = 0, n = 0;
  for (const b of boxes) {
    for (let y = b.y0; y < b.y1; y++) {
      for (let x = b.x0; x < b.x1; x++) {
        const c = Jimp.intToRGBA(img.getPixelColor(x, y));
        rSum += c.r; gSum += c.g; bSum += c.b; n++;
      }
    }
  }
  const avg = { r: rSum / n, g: gSum / n, b: bSum / n };
  const toHex = (v) => Math.round(v).toString(16).padStart(2, "0");
  console.log(
    `paper avg: rgb(${avg.r.toFixed(0)},${avg.g.toFixed(0)},${avg.b.toFixed(0)}) #${toHex(avg.r)}${toHex(avg.g)}${toHex(avg.b)}`
  );
  console.log(`target   : rgb(${TARGET.r},${TARGET.g},${TARGET.b}) #${toHex(TARGET.r)}${toHex(TARGET.g)}${toHex(TARGET.b)}`);

  const dR = TARGET.r - avg.r;
  const dG = TARGET.g - avg.g;
  const dB = TARGET.b - avg.b;
  console.log(`delta    : (${dR.toFixed(1)}, ${dG.toFixed(1)}, ${dB.toFixed(1)})`);

  img.scan(0, 0, w, h, function (x, y, idx) {
    const d = this.bitmap.data;
    d[idx]     = Math.max(0, Math.min(255, d[idx]     + dR));
    d[idx + 1] = Math.max(0, Math.min(255, d[idx + 1] + dG));
    d[idx + 2] = Math.max(0, Math.min(255, d[idx + 2] + dB));
  });

  if (Math.max(w, h) > MAX_SIDE) {
    if (w >= h) img.resize(MAX_SIDE, Jimp.AUTO);
    else        img.resize(Jimp.AUTO, MAX_SIDE);
  }

  img.quality(88);
  await img.writeAsync(out);
  console.log(`wrote ${out}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});

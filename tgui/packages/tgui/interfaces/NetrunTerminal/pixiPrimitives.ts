import type { Container, Graphics } from 'pixi.js';

import type { GraphPoint } from './mapLayout';

export type PixiLibrary = typeof import('pixi.js');
export const pixiColor = (value: string | undefined, fallback: number) =>
  value && /^#[0-9a-f]{6}$/i.test(value) ? Number.parseInt(value.slice(1), 16) : fallback;
export const edgeColor = (kind: string, online = true) => !online ? 0x52636e
  : kind === 'relay' ? 0x46c9bd : kind === 'apc' ? 0x4f86a3 : 0x3a6a85;
/** World-unit cable widths at working zoom (GRAPH_TILE is 144 units, default zoom .7). */
export const edgeWidth = (kind: string) => kind === 'relay' ? 3.4 : kind === 'apc' ? 2.2 : 1.6;
export const edgeAlpha = (kind: string, online = true) => !online ? .2 : kind === 'endpoint' ? .2 : kind === 'apc' ? .4 : .48;
/** Quantized zoom level for strokes: below .6 widths double per halving so links stay visible. */
export const strokeLod = (zoom: number) => Math.max(1, 2 ** Math.ceil(Math.log2(.6 / Math.max(zoom, 1e-6))));

export function markerPath(graphic: Graphics, type: string, x: number, y: number, scale = 1) {
  if (type === 'apc') { graphic.rect(x - 11 * scale, y - 11 * scale, 22 * scale, 22 * scale); }
  else if (type === 'gateway' || type === 'relay') {
    for (let i = 0; i < 6; i++) {
      const angle = i * Math.PI / 3;
      const px = x + Math.cos(angle) * 14 * scale, py = y + Math.sin(angle) * 14 * scale;
      if (!i) { graphic.moveTo(px, py); } else { graphic.lineTo(px, py); }
    }
    graphic.closePath();
  } else if (type === 'server' || type === 'terminal') {
    graphic.moveTo(x, y - 12 * scale).lineTo(x + 12 * scale, y)
      .lineTo(x, y + 12 * scale).lineTo(x - 12 * scale, y).closePath();
  } else { graphic.circle(x, y, 8 * scale); }
  return graphic;
}

/** Graphics has no native dash style. Preserve offline/route meaning without SVG. */
export function segmentPath(graphic: Graphics, a: GraphPoint, b: GraphPoint, dash = 0, gap = dash) {
  if (!dash) { graphic.moveTo(a.px, a.py).lineTo(b.px, b.py); return; }
  const distance = Math.hypot(b.px - a.px, b.py - a.py);
  if (!distance) { return; }
  const dx = (b.px - a.px) / distance, dy = (b.py - a.py) / distance;
  for (let offset = 0; offset < distance; offset += dash + gap) {
    const end = Math.min(distance, offset + dash);
    graphic.moveTo(a.px + dx * offset, a.py + dy * offset).lineTo(a.px + dx * end, a.py + dy * end);
  }
}

export const destroyDisplay = (value: Container) =>
  value.destroy({ children: true, texture: true, textureSource: true, context: true });

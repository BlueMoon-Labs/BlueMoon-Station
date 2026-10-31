import { GRAPH_GLYPH_RADIUS } from './graphLayout';
import { PlacedNode } from './graphScene';
import { GraphViewport } from './graphViewport';

export type LabelRect = { left: number; top: number; right: number; bottom: number };
export type GraphLabel = { node: PlacedNode; text: string; rect: LabelRect };
export const intersects = (a: LabelRect, b: LabelRect) => a.left < b.right && b.left < a.right && a.top < b.bottom && b.top < a.bottom;

/** Screen-space rectangle occupancy shared by glyphs and labels. No priority bypasses collisions. */
class LabelOccupancy {
  private cells = new Map<string, LabelRect[]>();
  private keys(rect: LabelRect) {
    const keys: string[] = [];
    for (let x = Math.floor(rect.left / 64); x <= Math.floor(rect.right / 64); x++) {
      for (let y = Math.floor(rect.top / 64); y <= Math.floor(rect.bottom / 64); y++) { keys.push(`${x},${y}`); }
    }
    return keys;
  }
  add(rect: LabelRect) {
    for (const key of this.keys(rect)) { const cell = this.cells.get(key) || []; cell.push(rect); this.cells.set(key, cell); }
  }
  blocked(rect: LabelRect) { return this.keys(rect).some((key) => this.cells.get(key)?.some((other) => intersects(rect, other))); }
}

export const layoutLabels = (nodes: PlacedNode[], view: GraphViewport, width: number, height: number,
  measure: (text: string) => number, priority: (node: PlacedNode) => number,
  textFor: (node: PlacedNode) => string = (node) => node.name, maxLabels = Infinity): GraphLabel[] => {
  if (view.zoom < .5) { return []; }
  const occupied = new LabelOccupancy(), labels: GraphLabel[] = [];
  const radius = GRAPH_GLYPH_RADIUS * view.zoom;
  for (const node of nodes) {
    const point = view.project(node);
    occupied.add({ left: point.px - radius - 4, right: point.px + radius + 4, top: point.py - radius - 4, bottom: point.py + radius + 4 });
  }
  for (const node of [...nodes].sort((a, b) => priority(b) - priority(a) || a.address.localeCompare(b.address))) {
    // On large maps text measurement and glyph uploads are much more costly
    // than the network strokes. Preserve all markers, but bound labels.
    if (labels.length >= maxLabels) { break; }
    const point = view.project(node);
    const original = textFor(node);
    let text = original;
    while (text.length && measure(text) > 200) { text = text.slice(0, -1); }
    if (text !== original) { text = `${text.slice(0, -1)}…`; }
    const labelWidth = measure(text) + 8, labelHeight = 19;
    const offsets = [[-labelWidth / 2, radius + 5], [radius + 5, -labelHeight / 2], [-labelWidth / 2, -radius - 5 - labelHeight], [-radius - 5 - labelWidth, -labelHeight / 2]];
    for (const [dx, dy] of offsets) {
      const rect = { left: point.px + dx, top: point.py + dy, right: point.px + dx + labelWidth, bottom: point.py + dy + labelHeight };
      if (rect.left < 0 || rect.top < 0 || rect.right > width || rect.bottom > height || occupied.blocked(rect)) { continue; }
      occupied.add({ left: rect.left - 4, top: rect.top - 4, right: rect.right + 4, bottom: rect.bottom + 4 });
      labels.push({ node, text, rect }); break;
    }
  }
  return labels;
};

import type { GraphPoint, LayoutNode } from './mapLayout';
import { NetEdge } from './types';

export const GRAPH_TILE = 144;
/** Local marker slots within/around a physical station tile. */
export const GRAPH_GAP = 72;
export const GRAPH_GLYPH_RADIUS = 24;
type CachedPoint = GraphPoint & { anchorX: number; anchorY: number; physical: string };
export type GraphLayoutCache = {
  positions: Map<string, CachedPoint>;
  occupied: Set<string>;
  anchors: Map<string, number>;
  unblocked: boolean;
};
export const createGraphLayoutCache = (): GraphLayoutCache => ({ positions: new Map(), occupied: new Set(), anchors: new Map(), unblocked: true });
const EMPTY_BLOCKED: ReadonlySet<string> = new Set();
export const graphAdjacency = (nodes: LayoutNode[], edges: NetEdge[]) => {
  const adjacency = new Map(nodes.map((node) => [node.address, new Set<string>()]));
  for (const edge of edges) {
    if (edge.from !== edge.to && adjacency.has(edge.from) && adjacency.has(edge.to)) {
      adjacency.get(edge.from).add(edge.to); adjacency.get(edge.to).add(edge.from);
    }
  }
  return adjacency;
};

const spiral = (slot: number): GraphPoint => {
  if (!slot) { return { px: 0, py: 0 }; }
  const r = Math.ceil((Math.sqrt(slot + 1) - 1) / 2);
  const t = (slot - (2 * r - 1) ** 2 + r) % (8 * r);
  let x: number, y: number;
  if (t < 2 * r) { x = -r + t; y = r; }
  else if (t < 4 * r) { x = r; y = 3 * r - t; }
  else if (t < 6 * r) { x = 5 * r - t; y = -r; }
  else { x = -r; y = t - 7 * r; }
  return { px: x * GRAPH_GAP, py: y * GRAPH_GAP };
};
const key = (point: GraphPoint) => `${point.px},${point.py}`;
const physical = (node: LayoutNode) => `${node.x || 0},${node.y || 0},${node.z || 0}`;
const anchorFor = (node: LayoutNode) => ({
  px: (Number.isFinite(node.x) ? node.x : 0) * GRAPH_TILE,
  py: -(Number.isFinite(node.y) ? node.y : 0) * GRAPH_TILE,
  physical: physical(node),
});
const countAnchor = (anchors: Map<string, number>, at: string, delta: number) => {
  const count = (anchors.get(at) || 0) + delta;
  if (count) { anchors.set(at, count); } else { anchors.delete(at); }
};

/** Physical station coordinates, north up. Only stacked markers receive local display offsets. */
export class GraphLayout {
  constructor(readonly cache = createGraphLayoutCache()) {}
  clear() { this.cache.positions.clear(); this.cache.occupied.clear(); this.cache.anchors.clear(); this.cache.unblocked = true; }

  update(nodes: LayoutNode[], _edges: NetEdge[], blocked: ReadonlySet<string> = EMPTY_BLOCKED): Map<string, GraphPoint> {
    // Walking around the station normally moves only a handful of implants or
    // carried devices. Preserve the indexed slots and sort only those movers,
    // instead of allocating/sorting anchors for the entire station every step.
    if (!blocked.size && this.cache.unblocked && this.cache.positions.size) {
      const addresses = new Set(nodes.map((node) => node.address));
      const removed = [...this.cache.positions.keys()].filter((address) => !addresses.has(address));
      const movers = nodes.filter((node) => this.cache.positions.get(node.address)?.physical !== physical(node));
      if (!movers.length && !removed.length) { return this.cache.positions; }
      const { occupied, anchors } = this.cache;
      const positions = new Map(this.cache.positions);
      for (const address of [...removed, ...movers.map((node) => node.address)]) {
        const before = positions.get(address);
        if (!before) { continue; }
        occupied.delete(key(before));
        countAnchor(anchors, `${before.anchorX},${before.anchorY}`, -1);
        positions.delete(address);
      }
      const nextAnchors = new Map(movers.map((node) => [node.address, anchorFor(node)]));
      for (const anchor of nextAnchors.values()) { countAnchor(anchors, key(anchor), 1); }
      const cursors = new Map<string, number>();
      for (const node of movers.sort((a, b) => a.address.localeCompare(b.address))) {
        const anchor = nextAnchors.get(node.address), anchorKey = key(anchor);
        let slot = cursors.get(anchorKey) || 0, point: GraphPoint;
        while (true) {
          const offset = spiral(slot++);
          point = { px: anchor.px + offset.px, py: anchor.py + offset.py };
          const at = key(point);
          if (!occupied.has(at) && (at === anchorKey || !anchors.has(at))) { break; }
        }
        positions.set(node.address, { ...point, anchorX: anchor.px, anchorY: anchor.py, physical: anchor.physical });
        occupied.add(key(point)); cursors.set(anchorKey, slot);
      }
      this.cache.positions = positions;
      return positions;
    }
    const sorted = [...nodes].sort((a, b) => a.address.localeCompare(b.address));
    const anchors = new Map(sorted.map((node) => [node.address, anchorFor(node)]));
    const reserved = new Set([...anchors.values()].map(key));
    const occupied = new Set<string>(), placed = new Map<string, CachedPoint>();
    // Retain every stationary marker, including its stack offset, regardless of input order.
    for (const node of sorted) {
      const previous = this.cache.positions.get(node.address), anchor = anchors.get(node.address);
      if (previous?.physical === anchor.physical && !occupied.has(key(previous)) && !blocked.has(key(previous))) {
        placed.set(node.address, previous); occupied.add(key(previous));
      }
    }
    const cursors = new Map<string, number>();
    for (const node of sorted) {
      if (placed.has(node.address)) { continue; }
      const anchor = anchors.get(node.address), anchorKey = key(anchor);
      let slot = cursors.get(anchorKey) || 0, point: GraphPoint;
      while (true) {
        const offset = spiral(slot++);
        point = { px: anchor.px + offset.px, py: anchor.py + offset.py };
        if (!occupied.has(key(point)) && !blocked.has(key(point)) && (key(point) === anchorKey || !reserved.has(key(point)))) { break; }
      }
      const cached = { ...point, anchorX: anchor.px, anchorY: anchor.py, physical: anchor.physical };
      placed.set(node.address, cached); occupied.add(key(point)); cursors.set(anchorKey, slot);
    }
    this.cache.positions = placed;
    this.cache.occupied = occupied;
    this.cache.anchors.clear();
    for (const anchor of anchors.values()) { countAnchor(this.cache.anchors, key(anchor), 1); }
    this.cache.unblocked = !blocked.size;
    return placed;
  }
}

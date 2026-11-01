import { GRAPH_TILE } from './graphLayout';
import { GraphPoint } from './mapLayout';
import { NetEdge } from './types';

type Bounds = { left: number; top: number; right: number; bottom: number };
type IndexedEdge = Bounds & { edge: NetEdge };
const BUCKET_SIZE = GRAPH_TILE * 8;
const MAX_EDGE_BUCKETS = 64;
const intersects = (edge: Bounds, box: Bounds) => edge.right >= box.left && edge.left <= box.right
  && edge.bottom >= box.top && edge.top <= box.bottom;
const bucketKey = (x: number, y: number) => `${x},${y}`;

/** Index whole links, since both endpoints of a visible crossing may be off screen. */
export class GraphEdgeIndex {
  private buckets = new Map<string, IndexedEdge[]>();
  private spanning: IndexedEdge[] = [];
  private entries: IndexedEdge[] = [];

  update(nodes: Map<string, GraphPoint>, edges: NetEdge[]) {
    this.buckets.clear(); this.spanning = []; this.entries = [];
    for (const edge of edges) {
      const from = nodes.get(edge.from), to = nodes.get(edge.to);
      if (!from || !to) { continue; }
      const ax = from.anchorX ?? from.px, ay = from.anchorY ?? from.py;
      const bx = to.anchorX ?? to.px, by = to.anchorY ?? to.py;
      const entry: IndexedEdge = { edge, left: Math.min(ax, bx), top: Math.min(ay, by), right: Math.max(ax, bx), bottom: Math.max(ay, by) };
      this.entries.push(entry);
      const left = Math.floor(entry.left / BUCKET_SIZE), right = Math.floor(entry.right / BUCKET_SIZE);
      const top = Math.floor(entry.top / BUCKET_SIZE), bottom = Math.floor(entry.bottom / BUCKET_SIZE);
      // Bound index memory for station-spanning diagonals; never omit those links.
      if ((right - left + 1) * (bottom - top + 1) > MAX_EDGE_BUCKETS) { this.spanning.push(entry); continue; }
      for (let x = left; x <= right; x++) {
        for (let y = top; y <= bottom; y++) {
          const key = bucketKey(x, y), bucket = this.buckets.get(key) || [];
          bucket.push(entry); this.buckets.set(key, bucket);
        }
      }
    }
  }

  visible(left: number, top: number, right: number, bottom: number): NetEdge[] {
    const box = { left, top, right, bottom };
    const minX = Math.floor(left / BUCKET_SIZE), maxX = Math.floor(right / BUCKET_SIZE);
    const minY = Math.floor(top / BUCKET_SIZE), maxY = Math.floor(bottom / BUCKET_SIZE);
    if ((maxX - minX + 1) * (maxY - minY + 1) > this.buckets.size) {
      return this.entries.filter((entry) => intersects(entry, box)).map((entry) => entry.edge);
    }
    const found = new Map<string, NetEdge>();
    const collect = (entries: IndexedEdge[]) => {
      for (const entry of entries) {
        if (intersects(entry, box)) { found.set(entry.edge.id, entry.edge); }
      }
    };
    collect(this.spanning);
    for (let x = minX; x <= maxX; x++) {
      for (let y = minY; y <= maxY; y++) { collect(this.buckets.get(bucketKey(x, y)) || []); }
    }
    return [...found.values()];
  }
}

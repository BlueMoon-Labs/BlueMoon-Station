import { GraphLayout, GraphLayoutCache } from './graphLayout';
import { NetEdge } from './types';

export type { GraphLayoutCache } from './graphLayout';
export { createGraphLayoutCache, graphAdjacency } from './graphLayout';

/** Server-owned geographic location; uplink remains connectivity rather than geometry. */
export type LayoutNode = { address: string; type: string; x?: number; y?: number; z?: number; uplink?: string | null };
export type GraphPoint = { px: number; py: number; anchorX?: number; anchorY?: number };
export const graphBounds = (points: Iterable<GraphPoint>, padding = 100) => {
  let minX = Infinity;
  let minY = Infinity;
  let maxX = -Infinity;
  let maxY = -Infinity;
  for (const point of points) {
    minX = Math.min(minX, point.px); minY = Math.min(minY, point.py);
    maxX = Math.max(maxX, point.px); maxY = Math.max(maxY, point.py);
  }
  if (!Number.isFinite(minX)) { minX = minY = maxX = maxY = 0; }
  return { minX: minX - padding, minY: minY - padding, width: maxX - minX + padding * 2, height: maxY - minY + padding * 2 };
};
export const graphNeighborhood = (adjacency: Map<string, Set<string>>, start: string, depth: number) => {
  const found = new Set<string>();
  if (!adjacency.has(start)) { return found; }
  found.add(start);
  let frontier = [start];
  for (let step = 0; step < depth && frontier.length; step++) {
    const next: string[] = [];
    for (const address of frontier) {
      for (const neighbor of adjacency.get(address) ?? []) {
        if (!found.has(neighbor)) { found.add(neighbor); next.push(neighbor); }
      }
    }
    frontier = next;
  }
  return found;
};

export const graphPath = (adjacency: Map<string, Set<string>>, from: string, to: string): string[] => {
  if (!adjacency.has(from) || !adjacency.has(to)) { return []; }
  const parents = new Map<string, string | null>([[from, null]]);
  const queue = [from];
  for (let index = 0; index < queue.length; index++) {
    const address = queue[index];
    if (address === to) {
      const path: string[] = [];
      for (let cursor: string | null = to; cursor !== null; cursor = parents.get(cursor)) { path.push(cursor); }
      return path.reverse();
    }
    for (const neighbor of adjacency.get(address) ?? []) {
      if (!parents.has(neighbor)) { parents.set(neighbor, address); queue.push(neighbor); }
    }
  }
  return [];
};

export const layoutGraph = (nodes: LayoutNode[], edges: NetEdge[], cache: GraphLayoutCache) =>
  new GraphLayout(cache).update(nodes, edges);

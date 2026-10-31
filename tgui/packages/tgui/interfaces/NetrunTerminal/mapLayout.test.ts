import { GRAPH_GAP, GRAPH_GLYPH_RADIUS, GRAPH_TILE, GraphLayout } from './graphLayout';
import { createGraphLayoutCache, graphAdjacency, graphBounds, graphNeighborhood, graphPath, layoutGraph } from './mapLayout';
import { NetEdge } from './types';

const nodes = [
  { address: 'APC-A', type: 'apc', x: 10, y: 20, z: 1, uplink: null },
  { address: 'APC-B', type: 'apc', x: 30, y: 15, z: 1, uplink: null },
  { address: 'RELAY', type: 'relay', x: 31, y: 15, z: 1, uplink: 'APC-B' },
  { address: 'CLIENT', type: 'terminal', x: 12, y: 25, z: 1, uplink: 'APC-A' },
];
const edges: NetEdge[] = [
  { id: 'client', from: 'CLIENT', to: 'APC-A', kind: 'endpoint' },
  { id: 'chain', from: 'APC-A', to: 'APC-B', kind: 'apc' },
  { id: 'relay', from: 'RELAY', to: 'APC-B', kind: 'endpoint' },
];

describe('geographic network map placement', () => {
  test('station x/y control geometry with north up, independently of topology or input order', () => {
    const layout = layoutGraph(nodes, edges, createGraphLayoutCache());
    expect(layout.get('APC-A').px).toBe(10 * GRAPH_TILE);
    expect(layout.get('APC-A').py).toBe(-20 * GRAPH_TILE);
    expect(layout.get('CLIENT').px).toBe(12 * GRAPH_TILE);
    expect(layout.get('CLIENT').py).toBe(-25 * GRAPH_TILE);
    expect(layoutGraph([...nodes].reverse(), [...edges].reverse(), createGraphLayoutCache())).toEqual(layout);
    expect(layoutGraph(nodes.map((node) => ({ ...node, uplink: null })), [], createGraphLayoutCache())).toEqual(layout);
  });

  test('movement relocates its physical anchor while stationary peers retain their point objects', () => {
    const cache = createGraphLayoutCache();
    const before = layoutGraph(nodes, edges, cache);
    const moved = nodes.map((node) => node.address === 'CLIENT' ? { ...node, x: 40, y: 50 } : node);
    const after = layoutGraph(moved, edges, cache);
    expect(after.get('CLIENT').px).toBe(40 * GRAPH_TILE);
    expect(after.get('CLIENT').py).toBe(-50 * GRAPH_TILE);
    for (const address of ['APC-A', 'APC-B', 'RELAY']) { expect(after.get(address)).toBe(before.get(address)); }
  });

  test('stacked markers use deterministic nearby offsets and retain their actual world anchor', () => {
    const stack = Array.from({ length: 8 }, (_, i) => ({ ...nodes[0], address: `STACK-${i}`, type: 'implant' }));
    const neighbor = { ...nodes[0], address: 'NEIGHBOR', x: 11 };
    const cache = createGraphLayoutCache(), points = layoutGraph([...stack, neighbor], [], cache);
    expect(new Set([...points.values()].map((point) => `${point.px},${point.py}`)).size).toBe(9);
    expect(points.get('NEIGHBOR').px).toBe(11 * GRAPH_TILE);
    for (const entry of stack) {
      const point = points.get(entry.address);
      expect(point.anchorX).toBe(10 * GRAPH_TILE);
      expect(point.anchorY).toBe(-20 * GRAPH_TILE);
      expect(Math.abs(point.px - point.anchorX)).toBeLessThanOrEqual(GRAPH_GAP * 2);
      expect(Math.abs(point.py - point.anchorY)).toBeLessThanOrEqual(GRAPH_GAP * 2);
    }
    const reversed = layoutGraph([neighbor, ...stack].reverse(), [], createGraphLayoutCache());
    expect(reversed).toEqual(points);
    const expanded = layoutGraph([...stack, neighbor, { ...stack[0], address: 'A-NEW' }], [], cache);
    for (const [address, point] of points) { expect(expanded.get(address)).toBe(point); }
    expect(GRAPH_GLYPH_RADIUS * 2).toBeLessThanOrEqual(GRAPH_GAP);
  });

  test('6000 physical nodes stay distinct without aggregation and deletion drops stale addresses', () => {
    const large = Array.from({ length: 6000 }, (_, i) => ({ ...nodes[0], address: `N${i}`, x: i % 80, y: Math.floor(i / 80) }));
    const cache = createGraphLayoutCache(), points = layoutGraph(large, [], cache);
    expect(points.size).toBe(6000);
    expect(new Set([...points.values()].map((point) => `${point.px},${point.py}`)).size).toBe(6000);
    const trimmed = layoutGraph(large.slice(0, 1), [], cache);
    expect(trimmed.size).toBe(1); expect(cache.positions.size).toBe(1);
    expect(trimmed.get('N0')).toBe(points.get('N0'));
  });

  test('simultaneous moving stacks reserve their destinations and release old slots', () => {
    const cache = createGraphLayoutCache();
    const stack = Array.from({ length: 5 }, (_, i) => ({ ...nodes[0], address: `IMPLANT-${i}` }));
    const peer = { ...nodes[0], address: 'PEER', x: 11 };
    const before = layoutGraph([...stack, peer], [], cache);
    const moving = stack.map(node => ({ ...node, x: 11 }));
    const next = layoutGraph([{ ...peer, x: 10 }, ...moving].reverse(), [], cache);
    expect(next.get('PEER').px).toBe(10 * GRAPH_TILE);
    expect(next.get('IMPLANT-0').px).toBe(11 * GRAPH_TILE);
    expect(new Set([...next.values()].map(point => `${point.px},${point.py}`)).size).toBe(6);
    expect(before.get('PEER').px).toBe(11 * GRAPH_TILE);
    // After a split, the remaining stack keeps its offset and a new device can
    // claim the released physical tile without inheriting stale occupancy.
    const split = moving.map(node => node.address === 'IMPLANT-0' ? { ...node, x: 12 } : node);
    const last = layoutGraph([{ ...peer, x: 10 }, ...split], [], cache);
    expect(last.get('IMPLANT-1')).toBe(next.get('IMPLANT-1'));
    expect(last.get('IMPLANT-0').px).toBe(12 * GRAPH_TILE);
    const added = layoutGraph([{ ...peer, x: 10 }, ...split, { ...peer, address: 'NEW', x: 11 }], [], cache);
    expect(added.get('NEW').px).toBe(11 * GRAPH_TILE);
    expect(new Set([...added.values()].map(point => `${point.px},${point.py}`)).size).toBe(7);
  });

  test('large movement updates do not re-sort stationary devices', () => {
    const large = Array.from({ length: 6000 }, (_, i) => ({ ...nodes[0], address: `N${i}`, x: i % 80, y: Math.floor(i / 80) }));
    const cache = createGraphLayoutCache(), before = layoutGraph(large, [], cache);
    const compare = jest.spyOn(String.prototype, 'localeCompare');
    try {
      for (let step = 0; step < 20; step++) {
        const next = large.map((node, index) => index < 3 ? { ...node, x: 100 + step, y: 100 } : node);
        const points = layoutGraph(next, [], cache);
        expect(points.size).toBe(6000);
        expect(points.get('N5000')).toBe(before.get('N5000'));
        expect(points.get('N0').anchorX).toBe((100 + step) * GRAPH_TILE);
        expect(new Set(['N0', 'N1', 'N2'].map(id => `${points.get(id).px},${points.get(id).py}`)).size).toBe(3);
      }
      expect(compare.mock.calls.length).toBeLessThan(100);
    } finally { compare.mockRestore(); }
  });

  test('blocked layouts and clearing invalidate their occupancy index', () => {
    const layout = new GraphLayout();
    const entry = { ...nodes[0], x: 0, y: 0 };
    const blockedPoint = layout.update([entry], [], new Set(['0,0'])).get(entry.address);
    expect(`${blockedPoint.px},${blockedPoint.py}`).not.toBe('0,0');
    layout.update([{ ...entry, x: 1 }], []);
    layout.clear();
    const points = layout.update([entry], []);
    expect(points.size).toBe(1);
    expect(points.get(entry.address).px).toBe(0);
    expect(points.get(entry.address).py).toBe(0);
  });

  test('physical bounds include negative coordinates and published topology remains authoritative', () => {
    const points = [{ px: -1800, py: -900 }, { px: 16000, py: 4200 }];
    const bounds = graphBounds(points);
    expect(bounds.minX).toBeLessThan(-1800); expect(bounds.minY).toBeLessThan(-900);
    expect(bounds.minX + bounds.width).toBeGreaterThan(16000);
    const adjacency = graphAdjacency(nodes, edges);
    expect(graphNeighborhood(adjacency, 'CLIENT', 2)).toEqual(new Set(['CLIENT', 'APC-A', 'APC-B']));
    expect(graphPath(adjacency, 'CLIENT', 'RELAY')).toEqual(['CLIENT', 'APC-A', 'APC-B', 'RELAY']);
    expect(graphPath(graphAdjacency(nodes, edges.slice(0, 1)), 'CLIENT', 'RELAY')).toEqual([]);
  });
});

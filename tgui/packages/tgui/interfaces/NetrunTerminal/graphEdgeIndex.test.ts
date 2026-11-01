import { GraphEdgeIndex } from './graphEdgeIndex';
import { GraphPoint } from './mapLayout';
import { NetEdge } from './types';

test('visible links include a viewport crossing with both endpoints off screen', () => {
  const index = new GraphEdgeIndex();
  const edge: NetEdge = { id: 'crossing', from: 'A', to: 'B', kind: 'apc' };
  index.update(new Map([['A', { px: -10000, py: 0 }], ['B', { px: 10000, py: 0 }]]), [edge]);
  expect(index.visible(-100, -100, 100, 100)).toEqual([edge]);
  expect(index.visible(-100, 200, 100, 300)).toEqual([]);
});

test('index queries match exhaustive link bounds at overview and detailed zoom', () => {
  const index = new GraphEdgeIndex();
  const nodes = new Map<string, GraphPoint>();
  const edges: NetEdge[] = [];
  let seed = 12345;
  const random = () => { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 4294967296; };
  for (let i = 0; i < 300; i++) {
    const from = `A${i}`, to = `B${i}`, x = (random() - .5) * 200000, y = (random() - .5) * 200000;
    nodes.set(from, { px: x + 20, py: y + 20, anchorX: x, anchorY: y });
    nodes.set(to, { px: x + random() * 20000, py: y + random() * 20000 });
    edges.push({ id: String(i), from, to, kind: 'endpoint' });
  }
  index.update(nodes, edges);
  for (const size of [100, 1000, 10000, 200000]) {
    const expected = edges.filter((edge) => {
      const a = nodes.get(edge.from), b = nodes.get(edge.to);
      return Math.max(a.anchorX ?? a.px, b.px) >= -size && Math.min(a.anchorX ?? a.px, b.px) <= size
        && Math.max(a.anchorY ?? a.py, b.py) >= -size && Math.min(a.anchorY ?? a.py, b.py) <= size;
    }).map((edge) => edge.id).sort();
    expect(index.visible(-size, -size, size, size).map((edge) => edge.id).sort()).toEqual(expected);
  }
});

test('links spanning many buckets are retained once, and removed endpoints clear their links', () => {
  const index = new GraphEdgeIndex();
  const edge: NetEdge = { id: 'long', from: 'A', to: 'B', kind: 'apc' };
  const nodes = new Map([['A', { px: -1000000, py: -1000000 }], ['B', { px: 1000000, py: 1000000 }]]);
  index.update(nodes, [edge]);
  expect(index.visible(-20, -20, 20, 20)).toEqual([edge]);
  nodes.delete('B');
  index.update(nodes, [edge]);
  expect(index.visible(-20, -20, 20, 20)).toEqual([]);
});

import { GRAPH_TILE } from './graphLayout';
import { MapProjection } from './mapLayers';
import { NetEdge, NetNode } from './types';

const node: NetNode = { address: 'APC', name: 'APC', type: 'apc', x: 1, y: 1, online: true,
  access: 1, security: 1, entities: 0, ice: 0, active: false, uplink: null };
const mobile: NetNode = { ...node, address: 'DECK', type: 'deck', dynamic: true, uplink: node.address };
const edge: NetEdge = { id: 'link', from: node.address, to: mobile.address, kind: 'endpoint' };

test('all devices and connections share one projection and retain live fields', () => {
  const projection = new MapProjection();
  const first = projection.update([node, mobile], [edge]);
  expect(first.nodes.map((entry) => entry.address)).toEqual(['APC', 'DECK']);
  expect(first.edges).toEqual([edge]);
  expect(new Set(first.nodes.map((entry) => `${entry.px},${entry.py}`)).size).toBe(2);
  const changed = projection.update([{ ...node, entities: 2, ice: 1, active: true, can_hop: true }, mobile], [edge]);
  expect(changed.nodes[0]).toEqual(expect.objectContaining({ entities: 2, ice: 1, active: true, can_hop: true }));
  expect(changed.nodes[0].px).toBe(first.nodes[0].px);
  expect(changed.nodes[0].py).toBe(first.nodes[0].py);
  expect(changed.nodes[1]).toBe(first.nodes[1]);
});

test('movement updates one placement while unrelated devices retain their slots and identities', () => {
  const projection = new MapProjection();
  const first = projection.update([node, mobile], [edge]);
  const moved = projection.update([node, { ...mobile, x: 20 }], [edge]);
  expect(moved.nodes[0]).toBe(first.nodes[0]);
  expect(moved.nodes[1].px).toBe(20 * GRAPH_TILE);
  expect(moved.nodes[1].anchorX).toBe(20 * GRAPH_TILE);
  expect(moved.nodes[1].py).toBe(-GRAPH_TILE);
});

test('an ordinary device can move or change its mobility hint without leaving the graph', () => {
  const projection = new MapProjection();
  const first = projection.update([node, mobile], [edge]);
  const changed = projection.update([{ ...node, x: 30, dynamic: true }, mobile], [edge]);
  expect(changed.nodes).toHaveLength(2);
  expect(changed.nodes[0].px).toBe(30 * GRAPH_TILE);
  expect(changed.nodes[1]).toBe(first.nodes[1]);
  expect(changed.edges).toEqual([edge]);
});

test('removing a device removes it immediately and preserves the remaining node', () => {
  const projection = new MapProjection();
  const first = projection.update([node, mobile], [edge]);
  const removed = projection.update([mobile], []);
  expect(removed.nodes).toEqual([first.nodes[1]]);
  expect(removed.nodes[0]).toBe(first.nodes[1]);
  expect(removed.edges).toEqual([]);
});

test('repeated state and connection-only changes preserve node placements', () => {
  const projection = new MapProjection(), nodes = [node, mobile], edges = [edge];
  const first = projection.update(nodes, edges);
  expect(projection.update(nodes, edges)).toBe(first);
  const disconnected = projection.update(nodes, [{ ...edge, online: false }]);
  expect(disconnected.nodes).toBe(first.nodes);
  expect(disconnected.edges[0].online).toBe(false);
});

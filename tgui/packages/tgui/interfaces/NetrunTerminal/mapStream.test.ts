import { NetrunMapStream } from './mapStream';
import { NetMap, NetMapDelta, NetNode } from './types';

const node: NetNode = { address: 'APC', name: 'APC', type: 'apc', x: 1, y: 1, online: true,
  access: 1, security: 1, entities: 0, ice: 0, active: false, uplink: null };
const baseline = (overrides: Partial<NetMap> = {}): NetMap => ({ epoch: 'ui:one', full: true,
  revision: 1, structure_revision: 1, state_revision: 10, static_revision: 1,
  nodes: [node], edges: [], gateways: [], focus: node.address, ...overrides });
const delta = (overrides: Partial<NetMapDelta> = {}): NetMapDelta => ({ epoch: 'ui:one', full: false,
  base_revision: 10, state_revision: 11, ...overrides });

test('one changed endpoint preserves all other entries and unchanged edge arrays', () => {
  const stream = new NetrunMapStream();
  const nodes = Array.from({ length: 6000 }, (_, index) => ({ ...node, address: `N${index}` }));
  const first = stream.apply(baseline({ nodes }));
  const changed = stream.apply(delta({ nodes: [{ ...nodes[100], entities: 2 }] }));
  expect(changed.nodes).toHaveLength(6000);
  expect(changed.nodes[100].entities).toBe(2);
  expect(changed.nodes[0]).toBe(first.nodes[0]);
  expect(changed.nodes[5999]).toBe(first.nodes[5999]);
  expect(changed.edges).toBe(first.edges);
  expect(first.nodes[100].entities).toBe(0);
});

test('idle packets do not enumerate, copy or serialize the retained 6000-node baseline', () => {
  const stream = new NetrunMapStream();
  let reads = 0;
  const nodes = new Proxy(Array.from({ length: 6000 }, (_, index) => ({ ...node, address: `N${index}` })), {
    get: (target, key, receiver) => { reads++; return Reflect.get(target, key, receiver); },
  });
  const first = stream.apply(baseline({ nodes }));
  const initialReads = reads;
  for (let i = 0; i < 20; i++) {
    expect(stream.apply(delta({ state_revision: 10, nodes: [], edges: [], gateways: [] }))).toBe(first);
  }
  expect(reads).toBe(initialReads);
});

test('metadata updates at the same graph revision retain graph arrays', () => {
  const stream = new NetrunMapStream();
  const first = stream.apply(baseline());
  const route = { route: ['APC'], hops: 0, latency: 0, revision: 12, reachable: true };
  const next = stream.apply(delta({ state_revision: 10, focus: 'OTHER', route }));
  expect(next.focus).toBe('OTHER');
  expect(next.route).toEqual(route);
  expect(next.nodes).toBe(first.nodes);
  expect(next.edges).toBe(first.edges);
  expect(stream.apply(delta({ state_revision: 10, focus: 'OTHER', route: { ...route, route: ['APC'] } }))).toBe(next);
});

test('deletion removes the endpoint and any remaining incident links', () => {
  const stream = new NetrunMapStream();
  stream.apply(baseline({ nodes: [node, { ...node, address: 'PEER' }],
    edges: [{ id: 'link', from: 'APC', to: 'PEER', kind: 'endpoint' }] }));
  const deleted = stream.apply(delta({ removed_nodes: ['PEER'] }));
  expect(deleted.nodes.map((entry) => entry.address)).toEqual(['APC']);
  expect(deleted.edges).toEqual([]);
});

test('a missing baseline requests one resync and a same-epoch gap hides the previous baseline', () => {
  const stream = new NetrunMapStream();
  expect(stream.apply(delta())).toBeNull();
  expect(stream.resyncToken).toBe(1);
  expect(stream.apply(delta({ state_revision: 12 }))).toBeNull();
  expect(stream.resyncToken).toBe(1);
  stream.apply(baseline({ state_revision: 12 }));
  expect(stream.apply(delta({ base_revision: 13, state_revision: 14 }))).toBeNull();
  expect(stream.resyncToken).toBe(2);
  const restored = stream.apply(baseline({ nodes: [{ ...node, address: 'ONLY-PERMITTED' }], state_revision: 14 }));
  expect(restored.nodes.map((entry) => entry.address)).toEqual(['ONLY-PERMITTED']);
});

test('a lost delta hides the old map and rejects a baseline older than the missed update', () => {
  const stream = new NetrunMapStream();
  const initial = stream.apply(baseline());
  expect(stream.apply(delta({ base_revision: 11, state_revision: 12 }))).toBeNull();
  expect(stream.needsResync).toBe(true);
  expect(stream.resyncToken).toBe(1);
  expect(stream.apply(delta({ base_revision: 10, state_revision: 13, nodes: [{ ...node, name: 'Unconfirmed' }] }))).toBeNull();
  expect(initial.nodes[0].name).toBe('APC');
  expect(stream.apply(baseline({ state_revision: 12, nodes: [node] }))).toBeNull();
  const restored = stream.apply(baseline({ state_revision: 13, nodes: [{ ...node, name: 'Confirmed' }] }));
  expect(restored.nodes[0].name).toBe('Confirmed');
  expect(stream.needsResync).toBe(false);
});

test('a delayed full receipt can overlap a newer client without restarting recovery', () => {
  const stream = new NetrunMapStream();
  stream.apply(baseline({ nodes: [node, { ...node, address: 'REVOKED' }] }));
  stream.apply(delta({ nodes: [{ ...node, entities: 1 }], removed_nodes: ['REVOKED'] }));
  const next = stream.apply(delta({ base_revision: 10, state_revision: 12,
    nodes: [{ ...node, entities: 2 }], removed_nodes: ['REVOKED'] }));
  expect(next.nodes).toEqual([{ ...node, entities: 2 }]);
  expect(stream.needsResync).toBe(false);
  expect(stream.resyncToken).toBe(0);
});

test('new authorization epoch drops all previously disclosed nodes immediately', () => {
  const stream = new NetrunMapStream();
  stream.apply(baseline());
  expect(stream.apply(delta({ epoch: 'ui:revoked', base_revision: 10, state_revision: 12 }))).toBeNull();
  expect(stream.needsResync).toBe(true);
  expect(stream.apply(baseline({ epoch: 'ui:revoked', state_revision: 12, nodes: [] })).nodes).toEqual([]);
});

test('authorization epochs replace the baseline and independent windows keep separate cursors', () => {
  const first = new NetrunMapStream(), second = new NetrunMapStream();
  first.apply(baseline({ apc_zones: [{ address: 'APC', z: 1, runs: [{ x: 1, y: 1, width: 3 }] }] }));
  second.apply(baseline({ epoch: 'ui:two' }));
  const changed = first.apply(baseline({ epoch: 'ui:one:authorized', state_revision: 1, nodes: [], apc_zones: [] }));
  expect(changed.nodes).toEqual([]);
  expect(changed.apc_zones).toEqual([]);
  expect(second.apply(delta({ epoch: 'ui:two', nodes: [{ ...node, entities: 1 }] })).nodes[0].entities).toBe(1);
  expect(first.apply(delta({ epoch: 'ui:one', state_revision: 20 }))).toBe(changed);
  expect(first.apply(baseline({ epoch: 'ui:one', state_revision: 21 }))).toBe(changed);
  expect(second.resyncToken).toBe(0);
});

test('a full authorization change retains only unchanged entries still disclosed by the new baseline', () => {
  const stream = new NetrunMapStream();
  const original = Array.from({ length: 1000 }, (_, i) => ({ ...node, address: `N${i}` }));
  const edges = [{ id: 'visible', from: 'N0', to: 'N1', kind: 'endpoint' as const }];
  const first = stream.apply(baseline({ nodes: original, edges }));
  const nextNodes = original.slice(0, 999).map((entry) => ({ ...entry }));
  nextNodes[1] = { ...nextNodes[1], access: 3 };
  const next = stream.apply(baseline({ epoch: 'ui:changed', state_revision: 1,
    nodes: nextNodes, edges: edges.map((edge) => ({ ...edge })) }));
  expect(next.nodes[0]).toBe(first.nodes[0]);
  expect(next.nodes[1]).not.toBe(first.nodes[1]);
  expect(next.nodes[1].access).toBe(3);
  expect(next.nodes.some((entry) => entry.address === 'N999')).toBe(false);
  expect(next.edges).toBe(first.edges);
  expect(first.nodes[1].access).toBe(1);
});

test('monotonic wire epochs reject late snapshots after many network changes with bounded history', () => {
  const stream = new NetrunMapStream();
  const epoch = (generation: number) => `view-ref:${generation}:1`;
  stream.apply(baseline({ epoch: epoch(1) }));
  for (let generation = 2; generation <= 500; generation++) {
    stream.apply(baseline({ epoch: epoch(generation), nodes: [{ ...node, address: `N${generation}` }] }));
  }
  const newest = stream.apply(baseline({ epoch: epoch(500), nodes: [{ ...node, address: 'N500' }] }));
  expect(stream.apply(baseline({ epoch: epoch(1), state_revision: 999, nodes: [node] }))).toBe(newest);
  expect(newest.nodes[0].address).toBe('N500');
});

test('a delayed baseline from an intermediate epoch cannot cancel a newer recovery', () => {
  const stream = new NetrunMapStream();
  stream.apply(baseline({ epoch: 'view:1:1' }));
  expect(stream.apply(delta({ epoch: 'view:2:1', state_revision: 11 }))).toBeNull();
  expect(stream.apply(delta({ epoch: 'view:3:1', state_revision: 12 }))).toBeNull();
  expect(stream.apply(baseline({ epoch: 'view:2:1', state_revision: 12 }))).toBeNull();
  const restored = stream.apply(baseline({ epoch: 'view:3:1', state_revision: 12, nodes: [] }));
  expect(restored.nodes).toEqual([]);
  expect(stream.needsResync).toBe(false);
});

test('out-of-order graph packets do not resurrect deleted endpoints or older metadata', () => {
  const stream = new NetrunMapStream();
  stream.apply(baseline());
  const removed = stream.apply(delta({ removed_nodes: ['APC'], focus: null }));
  expect(stream.apply(delta({ state_revision: 10, nodes: [node], focus: 'APC' }))).toBe(removed);
});

test('BYOND numeric boolean flags select the same baseline and delta protocol', () => {
  const stream = new NetrunMapStream();
  stream.apply(baseline({ full: 1 }));
  const next = stream.apply(delta({ full: 0, nodes: [{ ...node, entities: 2 }] }));
  expect(next.nodes).toHaveLength(1);
  expect(next.nodes[0].entities).toBe(2);
  expect(stream.resyncToken).toBe(0);
});

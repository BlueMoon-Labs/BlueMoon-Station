import { GraphOverlay } from './graphPresentation';
import { GraphScene, PlacedNode } from './graphScene';
import { glyphRadius } from './nodeGlyphs';
import { PixiActors } from './pixiActors';
import { MockContainer, MockGraphics, mockPixi, resetPixiMock } from './testSupport/pixiLibraryMock';

const node = (address: string, px = 0, py = 0): PlacedNode => ({ address, name: address, type: 'camera',
  x: px, y: py, px, py, security: 1, access: 1, online: true, active: false, entities: 0, uplink: null });
const overlay = (extra: Partial<GraphOverlay> = {}): GraphOverlay => ({ selected: null, entityHost: null, jacked: null,
  gateways: new Map(), selectedRoute: [], waypointRoute: [], pingRoute: [], events: [], ...extra });
beforeEach(resetPixiMock);

test('keyed movement reuses geometry, interpolates hit targets, and settles without an idle tick', () => {
  const scene = new GraphScene(); scene.update([{ ...node('A'), dynamic: true }, { ...node('B', 200), dynamic: true, ice: 2 }], []);
  const layer = new PixiActors(mockPixi), state = overlay(), edges = [], adjacency = scene.adjacency;
  layer.update(scene, state, edges, adjacency, 0); layer.animate(200);
  const a = MockContainer.instances.find((entry) => entry.label === 'device:A');
  const b = MockContainer.instances.find((entry) => entry.label === 'device:B');
  const originalWrites = MockGraphics.graphics.map((entry) => entry.clears);
  const next = new GraphScene(); next.update([{ ...node('A', 96), dynamic: true }, scene.nodes[1]], []);
  layer.update(next, state, edges, adjacency, 200);
  expect(MockContainer.instances.filter((entry) => entry.label === 'device:A')).toHaveLength(1);
  expect(MockGraphics.graphics.map((entry) => entry.clears)).toEqual(originalWrites);
  expect(layer.animate(260)).toBe(true);
  expect(a.position.x).toBeGreaterThan(0); expect(a.position.x).toBeLessThan(96);
  expect(layer.hit({ px: a.position.x, py: 0 }, 1)?.address).toBe('A');
  expect(layer.animate(500)).toBe(false); expect(a.position.x).toBe(96); expect(b.position.x).toBe(200);
  layer.destroy(); expect(a.destroyed && b.destroyed).toBe(true);
});

test('live map actors show role glyphs and faction colours, and repaint only the changed occupant summary', () => {
  const original = { ...node('A'), bots: 1, processes: [{ kind: 'bot' as const, bot_kind: 'hacker', faction: 'redshift', count: 1 }] };
  const scene = new GraphScene(); scene.update([original, { ...node('B', 200), bots: 1,
    processes: [{ kind: 'bot', bot_kind: 'recycler', faction: 'owner:3', faction_color: '#123456', count: 1 }] }], []);
  const layer = new PixiActors(mockPixi), state = overlay(), edges = [];
  layer.update(scene, state, edges, scene.adjacency, 0);
  const a = MockContainer.instances.find((entry) => entry.label === 'device:A').children[1] as MockGraphics;
  const b = MockContainer.instances.find((entry) => entry.label === 'device:B').children[1] as MockGraphics;
  expect(a.calls.filter((call) => call.op === 'fill').map((call) => call.args[0])).toContainEqual({ color: 0xf18f65 });
  expect(b.calls.filter((call) => call.op === 'fill').map((call) => call.args[0])).toContainEqual({ color: 0x123456 });
  const cipherGeometry = a.calls.filter((call) => call.op === 'lineTo').map((call) => call.args);
  const beforeB = b.clears;
  const next = new GraphScene(); next.update([{ ...original, processes: [{ kind: 'bot', bot_kind: 'breacher',
    faction: 'collective', count: 1 }] }, scene.nodes[1]], scene.edges, scene);
  layer.update(next, state, edges, next.adjacency, 1);
  expect(a.calls.filter((call) => call.op === 'fill').map((call) => call.args[0])).toContainEqual({ color: 0xb7a0ff });
  expect(a.calls.filter((call) => call.op === 'lineTo').map((call) => call.args)).not.toEqual(cipherGeometry);
  expect(b.clears).toBe(beforeB);
  expect(layer.animate(1000)).toBe(false);
});

test('map process markers keep unknown profiles visible, bound group geometry, and retain total overflow', () => {
  const scene = new GraphScene(); scene.update([{ ...node('A'), bots: 9, processes: Array.from({ length: 9 }, (_, i) => ({
    kind: 'bot' as const, bot_kind: `future-${i}`, faction: 'owner:9', faction_color: 'var(--bad)', count: 1,
  })) }], []);
  const layer = new PixiActors(mockPixi); layer.update(scene, overlay(), [], scene.adjacency, 0);
  const actor = MockContainer.instances.find((entry) => entry.label === 'device:A');
  const marks = actor.children[1] as MockGraphics;
  expect(marks.calls.filter((call) => call.op === 'fill')).toHaveLength(6);
  expect(marks.calls.filter((call) => call.op === 'fill').every((call) => (call.args[0] as { color: number }).color === 0x77d9ad)).toBe(true);
  expect(actor.children.slice(2).map((label) => (label as unknown as { text: string }).text)).toEqual(['+3']);
  layer.setViewport({ left: -200, right: 200, top: -200, bottom: 200 }, .2);
  expect(actor.children.slice(2).every((label) => !label.visible)).toBe(true); // Shapes, not tiny text, identify roles at overview zoom.
});

test('all dynamic links and routes longer than 256 hops survive, including a crossing link', () => {
  const scene = new GraphScene();
  const nodes = Array.from({ length: 301 }, (_, i) => node(`N${i}`, i * 10));
  const edges = nodes.slice(1).map((entry, i) => ({ id: `e${i}`, from: nodes[i].address, to: entry.address, kind: 'apc' as const }));
  scene.update(nodes, edges);
  const dynamic = Array.from({ length: 6001 }, (_, i) => ({ id: `d${i}`, from: 'N0', to: 'N300', kind: 'endpoint' as const }));
  const layer = new PixiActors(mockPixi);
  layer.update(scene, overlay({ selectedRoute: nodes.map((entry) => entry.address) }), dynamic, scene.adjacency, 0);
  expect(MockContainer.instances.find((entry) => entry.label === 'moving-cables').children).toHaveLength(6001);
  layer.setViewport({ left: 1400, right: 1600, top: -10, bottom: 10 }, 1);
  expect(MockGraphics.graphics.find((entry) => entry.label === 'edge:d6000').visible).toBe(true);
  // Each hop has a continuous underlay plus its bright dashed stroke.
  expect(MockGraphics.graphics.some((entry) => entry.calls.filter((call) => call.op === 'lineTo').length >= 600)).toBe(true);
});

test('traffic follows real adjacency rather than drawing a fictional straight shortcut', () => {
  const scene = new GraphScene();
  scene.update([node('A'), node('B', 0, 100), node('C', 100, 100)], [
    { id: 'AB', from: 'A', to: 'B', kind: 'apc' }, { id: 'BC', from: 'B', to: 'C', kind: 'apc' },
  ]);
  const layer = new PixiActors(mockPixi);
  layer.update(scene, overlay({ selectedRoute: ['A', 'C'], events: [{ kind: 'intrusion', from: 'A', to: 'C', age: 0 }] }), [], scene.adjacency, 0);
  expect(layer.animate(250)).toBe(true);
  const effects = MockGraphics.graphics.find((entry) => entry.label === 'traffic-and-ping');
  expect(effects.calls.filter((call) => call.op === 'circle').some((call) => call.args[0] === 0 && call.args[1] === 50)).toBe(true);
  expect(layer.animate(4001)).toBe(false);
  const disconnected = new GraphScene(); disconnected.update(scene.nodes, [scene.edges[0], { ...scene.edges[1], online: false }]);
  layer.update(disconnected, overlay({ events: [{ kind: 'intrusion', from: 'A', to: 'C', age: 0 }] }), [], disconnected.adjacency, 5000);
  layer.animate(5250);
  expect(effects.calls.filter((call) => call.op === 'circle')).toHaveLength(1); // Arrival marker, no packet through the broken link.
});

test('reduced motion snaps devices and stops packet, fade and ping animation immediately', () => {
  const scene = new GraphScene(); scene.update([{ ...node('A'), dynamic: true }, node('B', 100)], [{ id: 'AB', from: 'A', to: 'B', kind: 'apc' }]);
  const layer = new PixiActors(mockPixi); layer.setReducedMotion(true);
  const state = overlay({ pingRoute: ['A', 'B'], events: [{ kind: 'trace', from: 'A', to: 'B', age: 0 }] });
  layer.update(scene, state, [], scene.adjacency, 0);
  expect(layer.animate(0)).toBe(false);
  const next = new GraphScene(); next.update([{ ...node('A', 96), dynamic: true }, node('B', 100)], scene.edges);
  layer.update(next, state, [], next.adjacency, 10); expect(layer.animate(10)).toBe(false);
  expect(layer.hit({ px: 96, py: 0 }, 1)?.address).toBe('A');
});

test('zoomed-out Pixi actors keep device bodies small and enlarge ICE/entity rings only', () => {
  const scene = new GraphScene(); scene.update([
    { ...node('CAM'), dynamic: true },
    { ...node('ICE', 100), dynamic: true, ice: 2, entities: 1 },
  ], []);
  const layer = new PixiActors(mockPixi);
  layer.update(scene, overlay(), [], scene.adjacency, 0);
  layer.setViewport({ left: -100, right: 300, top: -100, bottom: 100 }, .2);
  const camera = MockContainer.instances.find((entry) => entry.label === 'device:CAM').children[0] as MockGraphics;
  const reach = Math.max(...camera.calls.filter((call) => call.op === 'moveTo' || call.op === 'lineTo')
    .map((call) => Math.hypot(Number(call.args[0]), Number(call.args[1]))));
  expect(reach).toBeLessThanOrEqual(glyphRadius('camera') * 1.5); // The device body is never inflated.
  const radii = MockGraphics.graphics.flatMap((graphic) => graphic.calls
    .filter((call) => call.op === 'circle').map((call) => call.args[2]));
  expect(radii.some((radius) => Number(radius) >= 46)).toBe(true);
});

test('a sent packet flies its hop route for its real transit time, then reports its outcome', () => {
  const scene = new GraphScene();
  scene.update([node('A'), node('B', 0, 100), node('C', 100, 100)], [
    { id: 'AB', from: 'A', to: 'B', kind: 'apc' }, { id: 'BC', from: 'B', to: 'C', kind: 'apc' },
  ]);
  const layer = new PixiActors(mockPixi);
  const sent = { kind: 'packet' as const, id: 'p1', packet: 'command', phase: 'send' as const, from: 'A', to: 'C', age: 0, duration: 2, route: ['A', 'B', 'C'] };
  layer.update(scene, overlay({ events: [sent] }), [], scene.adjacency, 0);
  expect(layer.animate(1000)).toBe(true);
  const effects = MockGraphics.graphics.find((entry) => entry.label === 'traffic-and-ping');
  // Halfway through a two-second flight the packet sits at the B corner of the A-B-C route.
  expect(effects.calls.filter((call) => call.op === 'circle').some((call) => call.args[0] === 0 && call.args[1] === 100)).toBe(true);
  // A repeated push of the same packet keeps its clock instead of restarting the flight.
  layer.update(scene, overlay({ events: [{ ...sent, age: 1.5 }] }), [], scene.adjacency, 1500);
  layer.animate(1500);
  expect(effects.calls.filter((call) => call.op === 'circle').some((call) => call.args[0] === 50 && call.args[1] === 100)).toBe(true);
  expect(layer.animate(2500)).toBe(true); // Arrival ring after the transit time.
  expect(layer.animate(4000)).toBe(false);
  layer.update(scene, overlay({ events: [{ ...sent, id: 'p2', phase: 'fail', age: 0 }] }), [], scene.adjacency, 5000);
  expect(layer.animate(5100)).toBe(true);
  expect(effects.calls.some((call) => call.op === 'lineTo')).toBe(true); // A failed delivery is crossed out at the target.
  expect(layer.animate(6300)).toBe(false);
});

test('a fast packet first observed with its receipt traverses its actual path once within its original expiry', () => {
  const scene = new GraphScene();
  scene.update([node('A'), node('B', 0, 100), node('C', 100, 100)], [
    { id: 'AB', from: 'A', to: 'B', kind: 'apc' }, { id: 'BC', from: 'B', to: 'C', kind: 'apc' },
  ]);
  const sent = { kind: 'packet' as const, id: 'fast', packet: 'command', from: 'A', to: 'C', own: true,
    route: ['A', 'B', 'C'], phase: 'send' as const, duration: .01, age: .2, remaining_ms: 0, lifetime_ms: 1000 };
  const layer = new PixiActors(mockPixi);
  layer.update(scene, overlay({ events: [sent, { ...sent, phase: 'done', age: .19 }] }), [], scene.adjacency, 0);
  layer.animate(325);
  const effects = MockGraphics.graphics.find((entry) => entry.label === 'traffic-and-ping');
  expect(effects.calls.filter((call) => call.op === 'lineTo').map((call) => call.args)).toEqual([[0, 100], [100, 100]]);
  expect(effects.calls.filter((call) => call.op === 'circle').at(-1).args.slice(0, 2)).toEqual([0, 100]);
  layer.update(scene, overlay({ events: [{ ...sent, phase: 'done', age: .69, lifetime_ms: 500 }] }), [], scene.adjacency, 500);
  layer.animate(650);
  expect(effects.calls.filter((call) => call.op === 'circle')).toHaveLength(1); // One outcome, no restarted comet.
  expect(effects.calls.filter((call) => call.op === 'circle')[0].args.slice(0, 2)).toEqual([100, 100]);
  expect(layer.animate(1100)).toBe(false);
});

test('a receipt continues an already drawn dispatch and never replays it from the source', () => {
  const scene = new GraphScene(); scene.update([node('A'), node('B', 200)], [{ id: 'AB', from: 'A', to: 'B', kind: 'apc' }]);
  const layer = new PixiActors(mockPixi);
  const sent = { kind: 'packet' as const, id: 'seen', from: 'A', to: 'B', route: ['A', 'B'], phase: 'send' as const, duration: 2, age: 0 };
  layer.update(scene, overlay({ events: [sent] }), [], scene.adjacency, 0); layer.animate(1000);
  layer.update(scene, overlay({ events: [{ ...sent, phase: 'done' }] }), [], scene.adjacency, 1000); layer.animate(1000);
  const effects = MockGraphics.graphics.find((entry) => entry.label === 'traffic-and-ping');
  expect(effects.calls.filter((call) => call.op === 'circle').at(-1).args.slice(0, 2)).toEqual([100, 0]);
  layer.animate(1325);
  expect(effects.calls.filter((call) => call.op === 'circle')).toHaveLength(1);
  expect(effects.calls.filter((call) => call.op === 'circle')[0].args.slice(0, 2)).toEqual([200, 0]);
});

test('completed paths retain private gaps and missing route metadata never invents a BFS path', () => {
  const scene = new GraphScene(); scene.update([node('A'), node('B', 100), node('C', 200), node('D', 300)], [
    { id: 'AB', from: 'A', to: 'B', kind: 'apc' }, { id: 'BC', from: 'B', to: 'C', kind: 'apc' }, { id: 'CD', from: 'C', to: 'D', kind: 'apc' },
  ]);
  const layer = new PixiActors(mockPixi);
  layer.update(scene, overlay({ events: [{ kind: 'packet', id: 'gap', from: 'A', to: 'D', phase: 'done', age: 0,
    route: ['A', 'B', '', 'C', 'D'] }] }), [], scene.adjacency, 0); layer.animate(325);
  const effects = MockGraphics.graphics.find((entry) => entry.label === 'traffic-and-ping');
  expect(effects.calls.filter((call) => call.op === 'lineTo').map((call) => call.args)).toEqual([[100, 0], [300, 0]]);
  expect(effects.calls.filter((call) => call.op === 'circle')).toHaveLength(0);
  layer.update(scene, overlay({ events: [{ kind: 'packet', id: 'legacy', from: 'A', to: 'D', phase: 'done', age: 0 }] }), [], scene.adjacency, 2000);
  layer.animate(2100);
  expect(effects.calls.some((call) => call.op === 'lineTo')).toBe(false);
});

test('explicit redacted packet routes never fall back to a fabricated visible BFS route', () => {
  const scene = new GraphScene();
  scene.update([node('A'), node('B', 0, 100), node('C', 100, 100)], [
    { id: 'AB', from: 'A', to: 'B', kind: 'apc' }, { id: 'BC', from: 'B', to: 'C', kind: 'apc' },
  ]);
  const layer = new PixiActors(mockPixi);
  layer.update(scene, overlay({ events: [{ kind: 'packet', id: 'private', from: 'A', to: 'C', own: true,
    route: ['A', '', 'C'], phase: 'send', duration: 2, age: 0 }] }), [], scene.adjacency, 0);
  layer.animate(500);
  const effects = MockGraphics.graphics.find((entry) => entry.label === 'traffic-and-ping');
  expect(effects.calls.some((call) => call.op === 'lineTo')).toBe(false);
  const revoked = new GraphScene(); revoked.update([], []);
  layer.update(revoked, overlay(), [], revoked.adjacency, 600);
  expect(layer.animate(600)).toBe(false);
  expect(effects.calls).toEqual([]);
});

test('a ping clears its route geometry at expiry without clearing stored or waypoint routes', () => {
  const scene = new GraphScene(); scene.update([node('A'), node('B', 100)], [{ id: 'AB', from: 'A', to: 'B', kind: 'apc' }]);
  const layer = new PixiActors(mockPixi), edges = [];
  const state = overlay({ pingRoute: ['A', 'B'], pingId: 1, pingExpiresAt: 6000,
    selectedRoute: ['A', 'B'], waypointRoute: ['A', 'B'] });
  layer.update(scene, state, edges, scene.adjacency, 0);
  const ping = MockGraphics.graphics.find((entry) => entry.label === 'ping-route');
  expect(ping.calls.some((call) => call.op === 'lineTo')).toBe(true);
  expect(layer.animate(1800)).toBe(false); // A static tail needs a timer, no idle RAF loop.
  expect(layer.nextWake).toBe(6000);
  expect(layer.animate(6000)).toBe(false);
  expect(ping.calls).toEqual([]);
  expect(layer.nextWake).toBeNull();
  for (const label of ['selected-route', 'waypoint-route']) {
    expect(MockGraphics.graphics.find((entry) => entry.label === label).calls.some((call) => call.op === 'lineTo')).toBe(true);
  }
  layer.update(scene, { ...state, hovered: 'B' }, edges, scene.adjacency, 7000);
  expect(ping.calls).toEqual([]); // Other changes must not resurrect an expired event.
});

test('a repeated ping over the same route starts a new finite event and server clear removes it immediately', () => {
  const scene = new GraphScene(); scene.update([node('A'), node('B', 100)], [{ id: 'AB', from: 'A', to: 'B', kind: 'apc' }]);
  const layer = new PixiActors(mockPixi), edges = [], route = ['A', 'B'];
  const state = overlay({ pingRoute: route, pingId: 1, pingExpiresAt: 1800 });
  layer.update(scene, state, edges, scene.adjacency, 0);
  layer.animate(1800);
  const ping = MockGraphics.graphics.find((entry) => entry.label === 'ping-route');
  expect(ping.calls).toEqual([]);
  layer.update(scene, { ...state, pingId: 2, pingExpiresAt: 4000 }, edges, scene.adjacency, 2000);
  expect(ping.calls.some((call) => call.op === 'lineTo')).toBe(true);
  expect(layer.animate(2100)).toBe(true);
  layer.update(scene, { ...state, pingId: undefined, pingExpiresAt: undefined, pingRoute: [] }, edges, scene.adjacency, 2200);
  expect(ping.calls).toEqual([]);
  expect(layer.animate(4000)).toBe(false);
});

test('reduced motion keeps a finite static ping and expires its graphics without packet animation', () => {
  const scene = new GraphScene(); scene.update([node('A'), node('B', 100)], [{ id: 'AB', from: 'A', to: 'B', kind: 'apc' }]);
  const layer = new PixiActors(mockPixi); layer.setReducedMotion(true);
  layer.update(scene, overlay({ pingRoute: ['A', 'B'], pingId: 1, pingExpiresAt: 6000 }), [], scene.adjacency, 0);
  expect(layer.animate(0)).toBe(false);
  const ping = MockGraphics.graphics.find((entry) => entry.label === 'ping-route');
  expect(ping.calls.some((call) => call.op === 'lineTo')).toBe(true);
  expect(layer.nextWake).toBe(6000);
  expect(layer.animate(6000)).toBe(false);
  expect(ping.calls).toEqual([]);
});

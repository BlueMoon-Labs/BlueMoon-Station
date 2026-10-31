import { intersects, layoutLabels } from './graphLabels';
import { GRAPH_GLYPH_RADIUS, GRAPH_TILE } from './graphLayout';
import { GraphScene, PlacedNode } from './graphScene';
import { GraphViewport } from './graphViewport';

const node = (address: string, px = 0, py = 0): PlacedNode => ({
  address, name: `Узел ${address}`, type: 'camera', x: 0, y: 0, security: 1,
  online: true, access: 1, entities: 0, active: false, uplink: null, px, py,
});

test('APC fit uses actual area runs including cells without nodes', () => {
  const scene = new GraphScene(); scene.update([node('APC')], []);
  const points = scene.fitPoints([{ address: 'APC', z: 1, runs: [{ x: 20, y: 30, width: 4 }, { x: 20, y: 31, width: 1 }] }]);
  expect(points).toContainEqual({ px: 19.5 * GRAPH_TILE, py: -30.5 * GRAPH_TILE });
  expect(points).toContainEqual({ px: 23.5 * GRAPH_TILE, py: -29.5 * GRAPH_TILE });
  const camera = new GraphViewport(); camera.fit(points, 350, 250);
  for (const point of points) {
    const screen = camera.project(point);
    expect(screen.px).toBeGreaterThanOrEqual(0); expect(screen.px).toBeLessThanOrEqual(350);
    expect(screen.py).toBeGreaterThanOrEqual(0); expect(screen.py).toBeLessThanOrEqual(250);
  }
});

test('manual camera survives data changes and wheel zoom keeps its cursor anchor', () => {
  const camera = new GraphViewport(); camera.fit([node('a'), node('b', 100000, -20000)], 720, 480);
  const fitZoom = camera.zoom;
  const point = camera.unproject(250, 190);
  camera.zoomAt(250, 190, -100, fitZoom);
  expect(camera.project(point).px).toBeCloseTo(250);
  expect(camera.project(point).py).toBeCloseTo(190);
  expect(camera.fitting).toBe(false);
  camera.pan(30, 50);
  expect(camera.x).toBe(30); expect(camera.y).toBe(50);
  camera.fit([node('a')], 600, 300);
  expect(camera.fitting).toBe(true);
  expect(camera.project(node('a'))).toEqual({ px: 300, py: 150 });
});

test('hit boxes may overlap at overview scale, but nearest selection is deterministic', () => {
  const scene = new GraphScene(); scene.update([node('B', 96), node('A')], []);
  expect(scene.hit({ px: 48, py: 0 }, .08).address).toBe('A');
  expect(scene.hit({ px: 90, py: 0 }, .08).address).toBe('B');
  scene.update([node('B', 96)], []);
  expect(scene.byAddress.has('A')).toBe(false);
  expect(scene.hit({ px: -1000, py: 0 }, .08)).toBeNull();
});

test('status changes retain spatial indexes while hit tests expose current permissions', () => {
  const nodes = [node('A'), node('B', 96)];
  const edges = [{ id: 'AB', from: 'A', to: 'B', kind: 'endpoint' as const }];
  const first = new GraphScene(); first.update(nodes, edges);
  const second = new GraphScene(); second.update([{ ...nodes[0], entities: 2 }, nodes[1]], edges, first);
  expect(second.sceneryVersion).toBe(first.sceneryVersion);
  expect(second.adjacency).toBe(first.adjacency);
  expect(second.hit({ px: 0, py: 0 }, 1).entities).toBe(2);
  expect(first.hit({ px: 0, py: 0 }, 1).entities).toBe(0);
  const revoked = new GraphScene(); revoked.update([{ ...nodes[0], access: 0 }, nodes[1]], edges, second);
  expect(revoked.sceneryVersion).not.toBe(second.sceneryVersion);
  expect(revoked.hit({ px: 0, py: 0 }, 1).access).toBe(0);
  const removed = new GraphScene(); removed.update([nodes[1]], [], revoked);
  expect(removed.hit({ px: 0, py: 0 }, 1)).toBeNull();
});

test('moving dynamic devices do not invalidate stationary scenery', () => {
  const nodes = [node('A'), { ...node('B', 96), dynamic: true }], edges = [];
  const first = new GraphScene(); first.update(nodes, edges);
  const second = new GraphScene(); second.update([nodes[0], { ...nodes[1], px: 192 }], edges, first);
  expect(second.sceneryVersion).toBe(first.sceneryVersion);
  expect(second.hit({ px: 192, py: 0 }, 1).address).toBe('B');
});

test('actual label rectangles never overlap other labels or marker bounds, even for selected nodes', () => {
  const nodes = Array.from({ length: 100 }, (_, i) => ({ ...node(`n-${i}`, (i % 10) * GRAPH_TILE, Math.floor(i / 10) * GRAPH_TILE), name: 'Очень длинное название устройства станции' }));
  const camera = new GraphViewport(); camera.zoom = .7; camera.x = 40; camera.y = 40;
  const labels = layoutLabels(nodes, camera, 720, 720, (text) => text.length * 7, (entry) => entry.address === 'n-0' ? 5 : 0);
  expect(labels.length).toBeGreaterThan(0);
  for (let i = 0; i < labels.length; i++) {
    for (const other of labels.slice(i + 1)) { expect(intersects(labels[i].rect, other.rect)).toBe(false); }
    for (const marker of nodes) {
      const point = camera.project(marker), radius = GRAPH_GLYPH_RADIUS * camera.zoom;
      expect(intersects(labels[i].rect, { left: point.px - radius, right: point.px + radius, top: point.py - radius, bottom: point.py + radius })).toBe(false);
    }
  }
  camera.zoom = .05;
  expect(layoutLabels(nodes, camera, 720, 720, (text) => text.length * 7, () => 5)).toEqual([]);
});

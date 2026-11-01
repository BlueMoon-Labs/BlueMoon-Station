import { GraphOverlay } from './graphPresentation';
import { GraphScene, PlacedNode } from './graphScene';
import { GraphViewport } from './graphViewport';
import { PixiLabels } from './pixiLabels';
import { MockContainer, mockPixi, MockText, resetPixiMock } from './testSupport/pixiLibraryMock';

beforeEach(resetPixiMock);
test('viewport occupancy limits captions naturally rather than truncating the map to 48 labels', () => {
  const scene = new GraphScene();
  const nodes: PlacedNode[] = Array.from({ length: 100 }, (_, i) => ({
    address: `N${i}`, name: `Node ${i}`, type: 'camera', x: 0, y: 0, px: 80 + i % 10 * 160, py: 80 + Math.floor(i / 10) * 160,
    online: true, access: 1, active: false, entities: 0, security: 1, uplink: null,
  }));
  scene.update(nodes, []);
  const state: GraphOverlay = { selected: 'N0', jacked: null, entityHost: null, gateways: new Map(), selectedRoute: [], waypointRoute: [], pingRoute: [], events: [] };
  const view = new GraphViewport(); view.x = 0; view.y = 0; view.zoom = 1;
  const labels = new PixiLabels(mockPixi); labels.update(scene, state, view, 1700, 1700, (node) => node);
  const layer = labels.layer as unknown as MockContainer;
  const captions = layer.children.filter((entry) => entry instanceof MockText);
  expect(captions.length).toBeGreaterThan(48);
  const first = captions[0];
  labels.update(scene, state, view, 1700, 1700, (node) => node);
  expect(layer.children.filter((entry) => entry instanceof MockText)[0]).toBe(first);
  view.zoom = .7; labels.update(scene, state, view, 1700, 1700, (node) => node);
  // Below close-up zoom only important nodes (here the selected one) keep captions.
  expect(layer.children.filter((entry) => entry instanceof MockText).map((entry) => (entry as MockText).text)).toEqual(['Node 0']);
  view.zoom = .1; labels.update(scene, state, view, 1700, 1700, (node) => node);
  expect(layer.children).toHaveLength(0); expect(first.destroyed).toBe(true);
  labels.destroy(); expect(MockContainer.instances.every((entry) => entry.destroyed)).toBe(true);
});

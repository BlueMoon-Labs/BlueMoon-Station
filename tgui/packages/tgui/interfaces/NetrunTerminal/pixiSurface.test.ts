import { GraphOverlay } from './graphPresentation';
import { GraphScene, PlacedNode } from './graphScene';
import { PixiScenery } from './pixiScenery';
import { framebufferResolution, mountNetrunPixi } from './pixiSurface';
import { MockApplication, MockGraphics, resetPixiMock } from './testSupport/pixiLibraryMock';

jest.mock('pixi.js', () => jest.requireActual('./testSupport/pixiLibraryMock').mockPixi);

const node = (address: string, px = 0): PlacedNode => ({ address, name: address, type: 'camera', x: px, y: 0, px, py: 0,
  online: true, access: 1, active: false, entities: 0, security: 1, uplink: null });
const overlay = (): GraphOverlay => ({ selected: null, jacked: null, entityHost: null, gateways: new Map(),
  selectedRoute: [], waypointRoute: [], pingRoute: [], events: [] });
let frames: Map<number, FrameRequestCallback>, sequence: number, clock: number;
let lose: jest.Mock, context: WebGL2RenderingContext, getContext: jest.SpyInstance;
const flush = () => {
  for (let i = 0; frames.size && i < 1000; i++) {
    const pending = [...frames.values()]; frames.clear(); clock += 100;
    for (const frame of pending) { frame(clock); }
  }
  expect(frames.size).toBe(0);
};
beforeEach(() => {
  resetPixiMock(); frames = new Map(); sequence = 0; clock = 0;
  jest.spyOn(performance, 'now').mockImplementation(() => clock);
  Object.defineProperty(window, 'WebGL2RenderingContext', { value: function WebGL2() {}, configurable: true });
  Object.defineProperty(document, 'hidden', { value: false, configurable: true });
  jest.spyOn(window, 'requestAnimationFrame').mockImplementation((callback) => { const id = ++sequence; frames.set(id, callback); return id; });
  jest.spyOn(window, 'cancelAnimationFrame').mockImplementation((id) => { frames.delete(id); });
  lose = jest.fn(); context = { getExtension: () => ({ loseContext: lose }) } as unknown as WebGL2RenderingContext;
  getContext = jest.spyOn(HTMLCanvasElement.prototype, 'getContext').mockImplementation((kind: string) => {
    if (kind !== 'webgl2') { throw new Error(`Unexpected renderer: ${kind}`); }
    return context as never;
  });
});
afterEach(() => { jest.restoreAllMocks(); document.body.innerHTML = ''; });

test('framebuffer resolution adapts large displays without imposing topology limits', () => {
  expect(framebufferResolution(3000, 2000, 2)).toBeLessThan(1);
  expect(framebufferResolution(1280, 800, 1)).toBe(1);
});

test('theme changes repaint the same Pixi surface and defer hidden work without a new GPU context', async () => {
  const shell = document.createElement('div'), host = document.createElement('div');
  shell.dataset.netTheme = 'amber'; shell.appendChild(host); document.body.appendChild(shell);
  const surface = await mountNetrunPixi(host, 800, 600); flush();
  const app = MockApplication.instances[0];
  expect(app.renderer.background.color).toBe(0x1a120c);
  const before = app.renderer.render.mock.calls.length;
  surface.setSuspended(true); shell.dataset.netTheme = 'phosphor'; await Promise.resolve();
  expect(frames.size).toBe(0); expect(app.renderer.render).toHaveBeenCalledTimes(before);
  expect(app.renderer.background.color).toBe(0x09130d);
  surface.setSuspended(false); flush();
  expect(MockApplication.instances).toHaveLength(1); expect(host.children).toHaveLength(1);
  expect(host.querySelector('canvas').dataset.netTheme).toBe('phosphor');
  surface.destroy(); shell.dataset.netTheme = 'noir'; await Promise.resolve();
  expect(frames.size).toBe(0); expect(app.destroys).toBe(1);
});

test('aborting pending async init releases its context and never appends an orphan surface', async () => {
  let ready: () => void;
  MockApplication.pending = new Promise<void>((resolve) => { ready = resolve; });
  const host = document.createElement('div'), abort = new AbortController(); document.body.appendChild(host);
  const mounting = mountNetrunPixi(host, 800, 600, undefined, { signal: abort.signal });
  for (let i = 0; i < 5 && !MockApplication.instances.length; i++) { await Promise.resolve(); }
  expect(MockApplication.instances).toHaveLength(1);
  abort.abort(); ready(); expect(await mounting).toBeNull();
  expect(host.children).toHaveLength(0); expect(MockApplication.instances[0].destroys).toBe(1); expect(lose).toHaveBeenCalledTimes(1);
  expect(frames.size).toBe(0);
});

test('partial initialization failure cleans up renderer and context', async () => {
  const report = jest.spyOn(console, 'error').mockImplementation(() => {});
  MockApplication.rejectInit = true;
  const host = document.createElement('div');
  expect(await mountNetrunPixi(host, 800, 600)).toBeNull();
  expect(MockApplication.instances[0].destroys).toBe(1); expect(lose).toHaveBeenCalledTimes(1); expect(host.children).toHaveLength(0);
  expect(report).toHaveBeenCalledWith('NetRun Pixi initialization failed', expect.any(Error));
});

test('hidden workspaces keep the same context, defer updates, and resume without an idle render loop', async () => {
  const host = document.createElement('div'); document.body.appendChild(host);
  const surface = await mountNetrunPixi(host, 800, 600, undefined, { reducedMotion: true });
  const scene = new GraphScene(); scene.update([node('A')], []); const state = overlay();
  surface.updateScene(scene, state); surface.updateActors(scene, state); flush();
  const app = MockApplication.instances[0], before = app.renderer.render.mock.calls.length;
  surface.setSuspended(true); surface.updateCamera({ x: 30, y: 40, zoom: 2 });
  expect(frames.size).toBe(0); expect(app.renderer.render).toHaveBeenCalledTimes(before); expect(host.children).toHaveLength(1);
  surface.setSuspended(false); flush(); expect(MockApplication.instances).toHaveLength(1);
  expect(app.renderer.render.mock.calls.length).toBeGreaterThan(before);
  surface.destroy(); surface.destroy(); expect(app.destroys).toBe(1); expect(frames.size).toBe(0); expect(host.children).toHaveLength(0);
  expect(getContext.mock.calls.every(([kind]) => kind === 'webgl2')).toBe(true);
});

test('moving one dynamic node does not restart stationary scenery preparation', async () => {
  const host = document.createElement('div'); document.body.appendChild(host);
  const queue = jest.spyOn(PixiScenery.prototype, 'queue');
  const surface = await mountNetrunPixi(host, 800, 600, undefined, { reducedMotion: true });
  const stationary = node('A'), moving = { ...node('B', 100), dynamic: true }, edges = [];
  const first = new GraphScene(); first.update([stationary, moving], edges);
  const state = overlay(); surface.updateScene(first, state); surface.updateActors(first, state); flush();
  expect(queue).toHaveBeenCalledTimes(1);
  const next = new GraphScene(); next.update([stationary, { ...moving, px: 200 }], edges, first);
  surface.updateScene(next, state); surface.updateActors(next, state); flush();
  expect(queue).toHaveBeenCalledTimes(1);
  expect(surface.hitTest({ px: 200, py: 0 }, 1).address).toBe('B');
  const revoked = new GraphScene(); revoked.update([{ ...stationary, access: 0 }, next.nodes[1]], edges, next);
  surface.updateScene(revoked, state); surface.updateActors(revoked, state); flush();
  expect(queue).toHaveBeenCalledTimes(2);
  surface.destroy();
});

test('a revoked live node cannot be hit between a scene update and the next Pixi frame', async () => {
  const host = document.createElement('div'); document.body.appendChild(host);
  const surface = await mountNetrunPixi(host, 800, 600, undefined, { reducedMotion: true });
  const visible = node('A'), hidden = { ...node('B', 100), dynamic: true }, edges = [];
  const first = new GraphScene(); first.update([visible, hidden], edges);
  const state = overlay(); surface.updateScene(first, state); surface.updateActors(first, state); flush();
  expect(surface.hitTest({ px: 100, py: 0 }, 1).address).toBe('B');
  const next = new GraphScene(); next.update([visible], edges, first);
  surface.updateScene(next, state); surface.updateActors(next, state);
  expect(surface.hitTest({ px: 100, py: 0 }, 1)).toBeNull();
  flush(); surface.destroy();
});

test('context loss pauses frames, restores retained objects and removes all listeners on destroy', async () => {
  const host = document.createElement('div'), status = jest.fn(), failed = jest.fn(); document.body.appendChild(host);
  const surface = await mountNetrunPixi(host, 800, 600, failed, { onStatus: status }); flush();
  const canvas = host.querySelector('canvas'), lost = new Event('webglcontextlost', { cancelable: true });
  canvas.dispatchEvent(lost); expect(lost.defaultPrevented).toBe(true); expect(status).toHaveBeenLastCalledWith('lost');
  surface.updateCamera({ x: 50, y: 40, zoom: 1 }); expect(frames.size).toBe(0);
  canvas.dispatchEvent(new Event('webglcontextrestored')); expect(status).toHaveBeenLastCalledWith('ready'); flush();
  expect(failed).not.toHaveBeenCalled(); surface.destroy();
  const calls = status.mock.calls.length; canvas.dispatchEvent(new Event('webglcontextrestored'));
  expect(status).toHaveBeenCalledTimes(calls); expect(frames.size).toBe(0);
});

test('Pixi renders on every requested animation frame without artificial FPS throttling', async () => {
  const host = document.createElement('div'); document.body.appendChild(host);
  const surface = await mountNetrunPixi(host, 800, 600);
  const scene = new GraphScene();
  scene.update([{ ...node('A'), dynamic: true }], []);
  surface.updateScene(scene, overlay());
  surface.updateActors(scene, overlay());
  const app = MockApplication.instances[0];
  const framesRendered = [];
  for (const timestamp of [8, 16, 24, 32]) {
    const frame = [...frames.values()][0];
    expect(frame).toBeDefined();
    frames.clear(); clock = timestamp; frame(timestamp);
    framesRendered.push(app.renderer.render.mock.calls.length);
  }
  expect(framesRendered[3]).toBeGreaterThan(framesRendered[0]);
  surface.setInteracting(true);
  surface.updateCamera({ x: 42, y: 53, zoom: 1.15 });
  expect(frames.size).toBeGreaterThan(0);
  surface.setInteracting(false);
  flush(); surface.destroy();
});

test('finite live effects settle; reduced motion and document hiding cancel animation frames', async () => {
  const host = document.createElement('div'); document.body.appendChild(host);
  const surface = await mountNetrunPixi(host, 800, 600);
  const scene = new GraphScene(); scene.update([{ ...node('A'), dynamic: true }, node('B', 100)], [{ id: 'AB', from: 'A', to: 'B', kind: 'apc' }]);
  const state = { ...overlay(), pingRoute: ['A', 'B'], events: [{ kind: 'trace' as const, from: 'A', to: 'B', age: 0 }] };
  surface.updateScene(scene, state); surface.updateActors(scene, state);
  const initial = [...frames.values()]; frames.clear(); clock = 100; initial.forEach((callback) => callback(clock));
  expect(frames.size).toBeGreaterThan(0);
  Object.defineProperty(document, 'hidden', { value: true, configurable: true }); document.dispatchEvent(new Event('visibilitychange'));
  expect(frames.size).toBe(0);
  Object.defineProperty(document, 'hidden', { value: false, configurable: true }); document.dispatchEvent(new Event('visibilitychange'));
  flush(); surface.destroy();
});

test('a static ping schedules one expiry frame and a repeated path with a new id renders again', async () => {
  jest.useFakeTimers({ doNotFake: ['performance', 'requestAnimationFrame', 'cancelAnimationFrame'] });
  const host = document.createElement('div'); document.body.appendChild(host);
  const surface = await mountNetrunPixi(host, 800, 600, undefined, { reducedMotion: true });
  try {
    const scene = new GraphScene(); scene.update([node('A'), node('B', 100)], [{ id: 'AB', from: 'A', to: 'B', kind: 'apc' }]);
    const state = { ...overlay(), pingRoute: ['A', 'B'], pingId: 1, pingExpiresAt: 6000 };
    surface.updateScene(scene, state); surface.updateActors(scene, state); flush();
    const ping = MockGraphics.graphics.find((entry) => entry.label === 'ping-route');
    expect(ping.calls.some((call) => call.op === 'lineTo')).toBe(true);
    expect(frames.size).toBe(0);
    expect(jest.getTimerCount()).toBe(1);
    clock = 6000; jest.advanceTimersByTime(6000); flush();
    expect(ping.calls).toEqual([]);
    expect(jest.getTimerCount()).toBe(0);
    surface.updateActors(scene, { ...state, pingId: 2, pingExpiresAt: 12000 }); flush();
    expect(ping.calls.some((call) => call.op === 'lineTo')).toBe(true);
    expect(jest.getTimerCount()).toBe(1);
    surface.setSuspended(true);
    expect(jest.getTimerCount()).toBe(0);
    clock = 13000; surface.setSuspended(false); flush();
    expect(ping.calls).toEqual([]);
    expect(jest.getTimerCount()).toBe(0);
  } finally { surface.destroy(); jest.useRealTimers(); }
});

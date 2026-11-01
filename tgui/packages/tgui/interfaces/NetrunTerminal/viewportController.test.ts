import { GraphScene, PlacedNode } from './graphScene';
import { makePixiSurfaceMock } from './testSupport/pixiSurfaceMock';
import { NetworkViewportController, ViewportSnapshot } from './viewportController';

const node: PlacedNode = { address: 'APC', name: 'APC', type: 'apc', x: 0, y: 0, px: 0, py: 0,
  security: 1, online: true, access: 2, active: false, entities: 0, uplink: null };
const snapshot = (): ViewportSnapshot => {
  const base = new GraphScene(); base.update([node], []);
  return { scene: base, overlay: { gateways: new Map(), selected: 'APC', jacked: null,
    entityHost: null, selectedRoute: [], waypointRoute: [], pingRoute: [], events: [] },
  suspended: false };
};
const callbacks = () => ({ onStatus: jest.fn(), onHUD: jest.fn(), onHover: jest.fn(), onSelect: jest.fn() });

test('a large graph opens at a readable connection scale and overview still fits every device', async () => {
  const data = snapshot();
  const remote = { ...node, address: 'REMOTE', px: 20000, py: 10000 };
  data.scene.update([node, remote], []);
  const host = hostElement();
  const factory = jest.fn(async (element: HTMLElement) => makePixiSurfaceMock(element));
  const controller = new NetworkViewportController(data, callbacks(), factory);
  try {
    controller.attach(host); await factory.mock.results[0].value; await Promise.resolve();
    expect(controller.camera.zoom).toBe(.7);
    const connection = controller.camera.project(node);
    expect(connection.px).toBeCloseTo(360);
    expect(connection.py).toBeCloseTo(240);
    controller.fit();
    expect(controller.camera.zoom).toBeLessThan(.55);
    for (const entry of [node, remote]) {
      const point = controller.camera.project(entry);
      expect(point.px).toBeGreaterThanOrEqual(0); expect(point.px).toBeLessThanOrEqual(720);
      expect(point.py).toBeGreaterThanOrEqual(0); expect(point.py).toBeLessThanOrEqual(480);
    }
  } finally { controller.detach(); host.remove(); }
});

const hostElement = (scale = 1, left = 0, top = 0) => {
  const host = document.createElement('div');
  host.tabIndex = 0;
  Object.defineProperties(host, { clientWidth: { configurable: true, value: 720 }, clientHeight: { configurable: true, value: 480 } });
  host.getBoundingClientRect = () => ({ left, top, width: 720 * scale, height: 480 * scale,
    right: left + 720 * scale, bottom: top + 480 * scale, x: left, y: top, toJSON: () => ({}) });
  document.body.appendChild(host);
  return host;
};
const pointer = (target: EventTarget, type: string, x: number, y: number, pointerId = 1,
  buttons = type === 'pointerdown' || type === 'pointermove' ? 1 : 0) => {
  const event = new MouseEvent(type, { clientX: x, clientY: y, button: 0, buttons, bubbles: true, cancelable: true });
  Object.defineProperty(event, 'pointerId', { value: pointerId });
  target.dispatchEvent(event);
  return event;
};

test('hiding a ready workspace preserves its context and camera but pauses all GPU work', async () => {
  const host = hostElement(), data = snapshot(), handlers = callbacks();
  const factory = jest.fn(async (element: HTMLElement) => makePixiSurfaceMock(element));
  const controller = new NetworkViewportController(data, handlers, factory);
  try {
    controller.attach(host);
    const surface = await factory.mock.results[0].value;
    await Promise.resolve();
    controller.center('APC');
    pointer(host, 'pointerdown', 360, 240); pointer(host, 'pointermove', 430, 260); pointer(host, 'pointerup', 430, 260);
    const camera = { x: controller.camera.x, y: controller.camera.y, zoom: controller.camera.zoom };
    const uploads = surface.updateActors.mock.calls.length;
    controller.update({ ...data, suspended: true });
    expect(surface.setSuspended).toHaveBeenLastCalledWith(true);
    expect(surface.destroy).not.toHaveBeenCalled();
    pointer(host, 'pointermove', 600, 300);
    controller.update({ ...data, suspended: true, overlay: { ...data.overlay, selected: null } });
    expect(surface.updateActors).toHaveBeenCalledTimes(uploads);
    controller.update(data);
    expect(factory).toHaveBeenCalledTimes(1);
    expect(surface.setSuspended).toHaveBeenLastCalledWith(false);
    expect({ x: controller.camera.x, y: controller.camera.y, zoom: controller.camera.zoom }).toEqual(camera);
  } finally { controller.detach(); host.remove(); }
});

test('an initialization finishing after hiding is cancelled and cannot attach a stale surface', async () => {
  const host = hostElement(), data = snapshot(), handlers = callbacks();
  let resolve;
  const factory = jest.fn((_element, _width, _height, _unavailable, _options) => new Promise<any>((finish) => { resolve = finish; }));
  const controller = new NetworkViewportController(data, handlers, factory);
  controller.attach(host);
  const signal = factory.mock.calls[0][4].signal;
  controller.update({ ...data, suspended: true });
  expect(signal.aborted).toBe(true);
  const stale = makePixiSurfaceMock(host);
  resolve(stale);
  await Promise.resolve();
  expect(stale.destroy).toHaveBeenCalledTimes(1);
  expect(host.querySelector('canvas')).toBeNull();
  expect(handlers.onStatus).toHaveBeenLastCalledWith({ phase: 'paused' });
  controller.detach(); host.remove();
});

test('pan and zoom update the GPU camera without reuploading the graph or reconciling the HUD on every pan pixel', async () => {
  const host = hostElement(), data = snapshot(), handlers = callbacks();
  const factory = jest.fn(async (element: HTMLElement) => makePixiSurfaceMock(element));
  const controller = new NetworkViewportController(data, handlers, factory);
  try {
    controller.attach(host);
    const surface = await factory.mock.results[0].value;
    await Promise.resolve();
    const uploads = surface.updateScene.mock.calls.length, actors = surface.updateActors.mock.calls.length;
    handlers.onHUD.mockClear();
    pointer(host, 'pointerdown', 360, 240);
    for (let step = 1; step <= 8; step++) { pointer(host, 'pointermove', 360 + step * 10, 240); }
    pointer(host, 'pointerup', 440, 240);
    expect(surface.updateScene).toHaveBeenCalledTimes(uploads);
    expect(surface.updateActors).toHaveBeenCalledTimes(actors);
    expect(handlers.onHUD).not.toHaveBeenCalled();
    pointer(host, 'pointerdown', 440, 240); pointer(host, 'pointerup', 440, 240);
    expect(handlers.onSelect).toHaveBeenCalledWith('APC');
    const actorsAfterSelection = surface.updateActors.mock.calls.length;
    const fitPoints = jest.spyOn(data.scene, 'fitPoints');
    for (let count = 0; count < 6; count++) {
      host.dispatchEvent(new WheelEvent('wheel', { clientX: 440, clientY: 240, deltaY: 15, cancelable: true }));
    }
    expect(fitPoints).toHaveBeenCalledTimes(1);
    expect(surface.updateScene).toHaveBeenCalledTimes(uploads);
    expect(surface.updateActors).toHaveBeenCalledTimes(actorsAfterSelection);
    expect(handlers.onHUD).toHaveBeenCalled();
  } finally { controller.detach(); host.remove(); }
});

test.each([.75, 1, 1.25])('selection, hover and wheel follow the rendered pointer at CSS scale %s', async (scale) => {
  const left = 37, top = 53, host = hostElement(scale, left, top), data = snapshot(), handlers = callbacks();
  const factory = jest.fn(async (element: HTMLElement) => makePixiSurfaceMock(element));
  const controller = new NetworkViewportController(data, handlers, factory);
  try {
    controller.attach(host); const surface = await factory.mock.results[0].value; await Promise.resolve();
    const nodePosition = controller.camera.project(node);
    const clientX = left + nodePosition.px * scale, clientY = top + nodePosition.py * scale;
    expect(controller.hit(clientX, clientY)?.address).toBe('APC');
    pointer(host, 'pointermove', clientX, clientY, 1, 0);
    expect(handlers.onHover).toHaveBeenLastCalledWith({ address: 'APC', x: nodePosition.px, y: nodePosition.py });
    pointer(host, 'pointerdown', clientX, clientY); pointer(host, 'pointerup', clientX, clientY);
    expect(handlers.onSelect).toHaveBeenCalledWith('APC');
    const anchor = controller.camera.unproject(240, 160), beforeZoom = controller.camera.zoom;
    host.dispatchEvent(new WheelEvent('wheel', { clientX: left + 240 * scale, clientY: top + 160 * scale,
      deltaY: 120, cancelable: true }));
    expect(controller.camera.zoom).toBeLessThan(beforeZoom);
    const projected = controller.camera.project(anchor);
    expect(projected.px).toBeCloseTo(240);
    expect(projected.py).toBeCloseTo(160);
    expect(surface.resize).toHaveBeenLastCalledWith(720, 480);
  } finally { controller.detach(); host.remove(); }
});

test.each([.75, 1, 1.25])('pan and release momentum keep the same visible displacement at CSS scale %s', async (scale) => {
  const left = 37, top = 53, host = hostElement(scale, left, top), data = snapshot();
  const factory = jest.fn(async (element: HTMLElement) => makePixiSurfaceMock(element));
  const controller = new NetworkViewportController(data, callbacks(), factory);
  const frames: FrameRequestCallback[] = [];
  const animation = jest.spyOn(window, 'requestAnimationFrame').mockImplementation((callback) => { frames.push(callback); return frames.length; });
  const cancel = jest.spyOn(window, 'cancelAnimationFrame').mockImplementation(() => {});
  let now = 0;
  const clock = jest.spyOn(performance, 'now').mockImplementation(() => now);
  try {
    controller.attach(host); await factory.mock.results[0].value; await Promise.resolve();
    const initial = { x: controller.camera.x, y: controller.camera.y };
    const clientX = left + 360 * scale, clientY = top + 240 * scale;
    pointer(host, 'pointerdown', clientX, clientY);
    now = 16; pointer(document, 'pointermove', clientX + 60, clientY + 30);
    expect((controller.camera.x - initial.x) * scale).toBeCloseTo(60);
    expect((controller.camera.y - initial.y) * scale).toBeCloseTo(30);
    pointer(document, 'pointerup', clientX + 60, clientY + 30);
    const released = { x: controller.camera.x, y: controller.camera.y };
    expect(frames).toHaveLength(1);
    now = 32; frames.shift()(now);
    const momentum = .45 * 60 / 16 * (1 - Math.exp(-16 / 125)) * 125;
    expect((controller.camera.x - released.x) * scale).toBeCloseTo(momentum);
    expect((controller.camera.y - released.y) * scale).toBeCloseTo(momentum / 2);
  } finally { controller.detach(); host.remove(); animation.mockRestore(); cancel.mockRestore(); clock.mockRestore(); }
});

test('a CSS scale or camera change during a held press applies only new pointer movement', async () => {
  const host = hostElement(), data = snapshot();
  const factory = jest.fn(async (element: HTMLElement) => makePixiSurfaceMock(element));
  const controller = new NetworkViewportController(data, callbacks(), factory);
  try {
    controller.attach(host); await factory.mock.results[0].value; await Promise.resolve();
    const initial = { x: controller.camera.x, y: controller.camera.y };
    pointer(host, 'pointerdown', 360, 240);
    pointer(host, 'pointermove', 400, 260);
    const bounds = host.getBoundingClientRect();
    host.getBoundingClientRect = () => ({ ...bounds, left: 50, top: 20, width: 540, height: 360, right: 590, bottom: 380 });
    window.dispatchEvent(new Event('resize'));
    pointer(document, 'pointermove', 460, 290);
    expect(controller.camera.x).toBeCloseTo(initial.x + 40 + 80);
    expect(controller.camera.y).toBeCloseTo(initial.y + 20 + 40);
    controller.center('APC');
    const centered = { x: controller.camera.x, y: controller.camera.y };
    pointer(document, 'pointermove', 475, 305);
    expect(controller.camera.x).toBeCloseTo(centered.x + 20);
    expect(controller.camera.y).toBeCloseTo(centered.y + 20);
  } finally { controller.detach(); host.remove(); }
});

test('selection and graph projection changes preserve manual camera zoom, pan and GPU context', async () => {
  const host = hostElement(), data = snapshot(), handlers = callbacks();
  const factory = jest.fn(async (element: HTMLElement) => makePixiSurfaceMock(element));
  const controller = new NetworkViewportController(data, handlers, factory);
  try {
    controller.attach(host);
    const surface = await factory.mock.results[0].value;
    await Promise.resolve();
    const before = { x: controller.camera.x, y: controller.camera.y, zoom: controller.camera.zoom };
    host.dispatchEvent(new WheelEvent('wheel',
      { clientX: 360, clientY: 240, deltaY: 240, cancelable: true }));
    pointer(host, 'pointerdown', 360, 240);
    pointer(host, 'pointermove', 410, 275);
    // Do not finish the gesture with momentum: selection updates can arrive during the pan.
    controller.update({ ...data, overlay: { ...data.overlay, selected: null } });
    expect(controller.camera.zoom).not.toBe(before.zoom);
    const manuallyPlaced = { x: controller.camera.x, y: controller.camera.y, zoom: controller.camera.zoom };
    const nextBase = new GraphScene(); nextBase.update([{ ...node, px: 700, py: 350 }], []);
    controller.update({ ...data, scene: nextBase,
      overlay: { ...data.overlay, selected: 'APC', apcZones: [] } });
    expect({ x: controller.camera.x, y: controller.camera.y, zoom: controller.camera.zoom }).toEqual(manuallyPlaced);
    expect(factory).toHaveBeenCalledTimes(1);
    expect(surface.destroy).not.toHaveBeenCalled();
    controller.update({ ...data, suspended: true });
    controller.update(data);
    expect({ x: controller.camera.x, y: controller.camera.y, zoom: controller.camera.zoom }).toEqual(manuallyPlaced);
  } finally { controller.detach(); host.remove(); }
});

test('drag uses a retained Pixi scene and enables gesture mode without rebuilding scenery', async () => {
  const host = hostElement(), data = snapshot(), handlers = callbacks();
  const factory = jest.fn(async (element: HTMLElement) => makePixiSurfaceMock(element));
  const controller = new NetworkViewportController(data, handlers, factory);
  try {
    controller.attach(host);
    const surface = await factory.mock.results[0].value;
    await Promise.resolve();
    const uploads = surface.updateScene.mock.calls.length;
    pointer(host, 'pointerdown', 360, 240);
    pointer(host, 'pointermove', 395, 240);
    pointer(host, 'pointermove', 440, 240);
    expect(surface.setInteracting).toHaveBeenCalledWith(true);
    expect(surface.updateCamera).toHaveBeenCalled();
    expect(surface.updateScene).toHaveBeenCalledTimes(uploads);
    pointer(host, 'pointerup', 440, 240);
    expect(factory).toHaveBeenCalledTimes(1);
  } finally { controller.detach(); host.remove(); }
});

test('map gestures suppress native text selection and HTML dragging', async () => {
  const host = hostElement(), data = snapshot();
  const factory = jest.fn(async (element: HTMLElement) => makePixiSurfaceMock(element));
  const controller = new NetworkViewportController(data, callbacks(), factory);
  try {
    controller.attach(host); await factory.mock.results[0].value; await Promise.resolve();
    expect(pointer(host, 'pointerdown', 360, 240).defaultPrevented).toBe(true);
    expect(document.activeElement).toBe(host);
    const drag = new Event('dragstart', { bubbles: true, cancelable: true });
    host.dispatchEvent(drag);
    expect(drag.defaultPrevented).toBe(true);
  } finally { controller.detach(); host.remove(); }
});

test.each(['lost', 'unavailable'])('drag survives %s pointer capture and reactive updates until release outside the map', async (capture) => {
  const host = hostElement(), data = snapshot(), handlers = callbacks();
  host.setPointerCapture = jest.fn(() => { if (capture === 'unavailable') { throw new Error('Capture unavailable'); } });
  host.releasePointerCapture = jest.fn();
  const factory = jest.fn(async (element: HTMLElement) => makePixiSurfaceMock(element));
  const controller = new NetworkViewportController(data, handlers, factory);
  const outside = document.createElement('button'); document.body.appendChild(outside);
  outside.addEventListener('pointermove', (event) => event.stopPropagation());
  try {
    controller.attach(host); const surface = await factory.mock.results[0].value; await Promise.resolve();
    const initial = { x: controller.camera.x, y: controller.camera.y };
    const uploads = surface.updateScene.mock.calls.length;
    pointer(host, 'pointerdown', 360, 240);
    pointer(host, 'pointermove', 400, 250);
    pointer(host, 'lostpointercapture', 400, 250);
    pointer(document, 'pointercancel', 400, 250, 2);
    controller.update({ ...data, overlay: { ...data.overlay, selected: null } });
    pointer(outside, 'pointermove', 800, 290);
    expect(controller.camera).toMatchObject({ x: initial.x + 440, y: initial.y + 50 });
    expect(host.hasAttribute('data-net-panning')).toBe(true);
    expect(surface.updateScene).toHaveBeenCalledTimes(uploads);
    pointer(outside, 'pointerup', 800, 290);
    expect(host.hasAttribute('data-net-panning')).toBe(false);
    expect(host.releasePointerCapture).toHaveBeenCalledWith(1);
    expect(handlers.onSelect).not.toHaveBeenCalled();
    const afterRelease = { x: controller.camera.x, y: controller.camera.y };
    pointer(host, 'pointerdown', 400, 240);
    pointer(document, 'pointermove', 420, 270);
    expect(controller.camera).toMatchObject({ x: afterRelease.x + 20, y: afterRelease.y + 30 });
  } finally { controller.detach(); host.remove(); outside.remove(); }
});

test('a missed release, cancellation, blur and detach end the gesture without selecting or keeping global listeners', async () => {
  const host = hostElement(), data = snapshot(), handlers = callbacks();
  const factory = jest.fn(async (element: HTMLElement) => makePixiSurfaceMock(element));
  const controller = new NetworkViewportController(data, handlers, factory);
  try {
    controller.attach(host); const surface = await factory.mock.results[0].value; await Promise.resolve();
    for (const stop of ['release', 'cancel', 'blur', 'detach']) {
      pointer(host, 'pointerdown', 360, 240);
      pointer(document, 'pointermove', 400, 260);
      const placed = { x: controller.camera.x, y: controller.camera.y };
      if (stop === 'release') { pointer(document, 'pointermove', 450, 280, 1, 0); }
      if (stop === 'cancel') { pointer(document, 'pointercancel', 400, 260); }
      if (stop === 'blur') { window.dispatchEvent(new Event('blur')); }
      if (stop === 'detach') { controller.detach(); }
      pointer(document, 'pointermove', 500, 300);
      pointer(document, 'pointerup', 500, 300);
      expect(controller.camera).toMatchObject(placed);
      expect(host.hasAttribute('data-net-panning')).toBe(false);
      expect(surface.setInteracting).toHaveBeenLastCalledWith(false);
    }
    expect(handlers.onSelect).not.toHaveBeenCalled();
  } finally { controller.detach(); host.remove(); }
});

test('a failed GPU start waits for an explicit retry and creates no 2D fallback', async () => {
  const host = hostElement(), data = snapshot(), handlers = callbacks();
  const factory = jest.fn(async (_element: HTMLElement): Promise<any> => null);
  const controller = new NetworkViewportController(data, handlers, factory);
  try {
    controller.attach(host); await Promise.resolve();
    expect(handlers.onStatus).toHaveBeenLastCalledWith(expect.objectContaining({ phase: 'error' }));
    controller.update({ ...data, overlay: { ...data.overlay, events: [] } });
    expect(factory).toHaveBeenCalledTimes(1);
    expect(host.querySelector('canvas, svg')).toBeNull();
    factory.mockImplementationOnce(async (element) => makePixiSurfaceMock(element));
    controller.retry(); await Promise.resolve();
    expect(handlers.onStatus).toHaveBeenLastCalledWith({ phase: 'ready' });
    expect(host.querySelectorAll('[data-net-pixi]')).toHaveLength(1);
  } finally { controller.detach(); host.remove(); }
});

test('empty filters pause the same surface and final detach removes listeners and resources', async () => {
  const host = hostElement(), data = snapshot(), handlers = callbacks();
  const factory = jest.fn(async (element: HTMLElement) => makePixiSurfaceMock(element));
  const controller = new NetworkViewportController(data, handlers, factory);
  controller.attach(host);
  const surface = await factory.mock.results[0].value;
  await Promise.resolve();
  const empty = new GraphScene(); empty.update([], []);
  controller.update({ ...data, scene: empty });
  expect(handlers.onStatus).toHaveBeenLastCalledWith({ phase: 'empty' });
  expect(surface.setSuspended).toHaveBeenLastCalledWith(true);
  controller.update(data);
  expect(factory).toHaveBeenCalledTimes(1);
  controller.detach();
  expect(surface.destroy).toHaveBeenCalledTimes(1);
  expect(host.querySelector('canvas')).toBeNull();
  handlers.onSelect.mockClear();
  pointer(host, 'pointerdown', 360, 240); pointer(host, 'pointerup', 360, 240);
  expect(handlers.onSelect).not.toHaveBeenCalled();
  host.remove();
});

test('a local selection highlights immediately while machine permissions remain server-confirmed', async () => {
  const host = hostElement(), data = snapshot();
  const peer = { ...node, address: 'PEER', name: 'Сервер', px: 96 };
  data.scene.update([node, peer], []);
  const handlers = { ...callbacks(), onSelectionFeedback: jest.fn() };
  const factory = jest.fn(async (element: HTMLElement) => makePixiSurfaceMock(element));
  const controller = new NetworkViewportController(data, handlers, factory);
  try {
    controller.attach(host); const surface = await factory.mock.results[0].value; await Promise.resolve();
    controller.previewSelection('PEER');
    expect(surface.updateActors).toHaveBeenLastCalledWith(data.scene,
      expect.objectContaining({ selected: 'PEER', selectionPending: true }));
    expect(data.overlay.selected).toBe('APC');
    expect(handlers.onSelectionFeedback).toHaveBeenLastCalledWith(expect.objectContaining({ phase: 'pending', address: 'PEER' }));
    controller.update({ ...data, overlay: { ...data.overlay, selected: 'PEER' } });
    expect(surface.updateActors).toHaveBeenLastCalledWith(data.scene,
      expect.objectContaining({ selected: 'PEER', selectionPending: false }));
    expect(handlers.onSelectionFeedback).toHaveBeenLastCalledWith(expect.objectContaining({ phase: 'confirmed', address: 'PEER' }));
  } finally { controller.detach(); host.remove(); }
});

test('a superseded selection cannot expire the new one and an unconfirmed choice returns to server state', async () => {
  jest.useFakeTimers();
  const host = hostElement(), data = snapshot();
  const handlers = { ...callbacks(), onSelectionFeedback: jest.fn() };
  const factory = jest.fn(async (element: HTMLElement) => makePixiSurfaceMock(element));
  const controller = new NetworkViewportController(data, handlers, factory);
  try {
    controller.attach(host); const surface = await factory.mock.results[0].value; await Promise.resolve();
    controller.previewSelection('FIRST'); jest.advanceTimersByTime(3500);
    controller.previewSelection('SECOND'); jest.advanceTimersByTime(1000);
    expect(handlers.onSelectionFeedback).toHaveBeenLastCalledWith(expect.objectContaining({ phase: 'pending', address: 'SECOND' }));
    jest.advanceTimersByTime(3000);
    expect(handlers.onSelectionFeedback).toHaveBeenLastCalledWith(expect.objectContaining({ phase: 'timeout', address: 'SECOND' }));
    expect(surface.updateActors).toHaveBeenLastCalledWith(data.scene,
      expect.objectContaining({ selected: 'APC', selectionPending: false }));
    controller.previewSelection('THIRD'); controller.rejectSelection('Узел больше недоступен.');
    expect(handlers.onSelectionFeedback).toHaveBeenLastCalledWith(expect.objectContaining({ phase: 'rejected', message: 'Узел больше недоступен.' }));
    controller.detach();
    expect(jest.getTimerCount()).toBe(0);
  } finally { controller.detach(); host.remove(); jest.useRealTimers(); }
});

test('pointer hit testing follows the rendered mobile position and an engine miss stays a miss', async () => {
  const host = hostElement(), data = snapshot(), handlers = callbacks();
  const factory = jest.fn(async (element: HTMLElement) => makePixiSurfaceMock(element));
  const controller = new NetworkViewportController(data, handlers, factory);
  try {
    controller.attach(host); const surface = await factory.mock.results[0].value; await Promise.resolve();
    surface.hitTest = jest.fn(() => ({ ...node, address: 'INTERPOLATED-MOBILE', dynamic: true }));
    pointer(host, 'pointerdown', 360, 240); pointer(host, 'pointerup', 360, 240);
    expect(handlers.onSelect).toHaveBeenLastCalledWith('INTERPOLATED-MOBILE');
    surface.hitTest.mockReturnValueOnce(null);
    expect(controller.hit(360, 240)).toBeNull();
  } finally { controller.detach(); host.remove(); }
});

test('context recovery keeps the loading state through incoming data and resumes the same surface', async () => {
  const host = hostElement(), data = snapshot(), handlers = callbacks();
  const factory = jest.fn(async (element, _width, _height, _unavailable, _options) => makePixiSurfaceMock(element));
  const controller = new NetworkViewportController(data, handlers, factory);
  try {
    controller.attach(host); const surface = await factory.mock.results[0].value; await Promise.resolve();
    factory.mock.calls[0][4].onStatus('lost');
    controller.update({ ...data, overlay: { ...data.overlay, selected: null } });
    expect(handlers.onStatus).toHaveBeenLastCalledWith(expect.objectContaining({ phase: 'loading' }));
    pointer(host, 'pointerdown', 360, 240); pointer(host, 'pointerup', 360, 240);
    expect(handlers.onSelect).not.toHaveBeenCalled();
    factory.mock.calls[0][4].onStatus('ready');
    expect(handlers.onStatus).toHaveBeenLastCalledWith({ phase: 'ready' });
    expect(factory).toHaveBeenCalledTimes(1);
    expect(surface.destroy).not.toHaveBeenCalled();
  } finally { controller.detach(); host.remove(); }
});

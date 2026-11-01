import { act, fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../../backend';
import { debugReducer } from '../../debug';
import { CombatPanel } from './CombatPanel';
import { NetrunContent } from './Content';
import { FilePanel } from './FilePanel';
import { GRAPH_TILE } from './graphLayout';
import { GraphScene } from './graphScene';
import { GraphViewport } from './graphViewport';
import * as mapGeometry from './mapLayout';
import { MatrixPanel } from './Matrix';
import { StationMap } from './NetworkMap';
import { NodePanel } from './NodePanel';
import { ConsoleLog } from './Panels';
import { mountNetrunPixi } from './pixiSurface';
import type { MockPixiSurface } from './testSupport/pixiSurfaceMock';
import { NetMap, NetMapDelta, NetrunData } from './types';
import { WindowPanel } from './WindowPanel';

jest.mock('./pixiSurface', () => ({
  mountNetrunPixi: jest.fn(async (host: HTMLElement) =>
    jest.requireActual('./testSupport/pixiSurfaceMock').makePixiSurfaceMock(host)),
}));

beforeEach(() => jest.mocked(mountNetrunPixi).mockImplementation(async (host) =>
  jest.requireActual('./testSupport/pixiSurfaceMock').makePixiSurfaceMock(host)));
afterEach(async () => {
  await act(async () => {});
  jest.restoreAllMocks();
});

const surfaceReady = async (): Promise<MockPixiSurface> => {
  await act(async () => {});
  const result = jest.mocked(mountNetrunPixi).mock.results.slice(-1)[0];
  if (!result) { throw new Error('The visible map did not initialize its Pixi surface'); }
  return await result.value as MockPixiSurface;
};

const command = {
  id: 'apc_breaker', name: 'Главный рубильник', desc: 'Переключить питание.',
  icon: 'power-off', danger: false, access: 2, allowed: true,
  illegal: false, trace: 0,
};

const node = {
  address: 'AAAA:0001', name: 'APC инженерии', type: 'apc', x: 10, y: 10,
  security: 2, online: true, access: 2, entities: 0, active: false,
  uplink: null, network: 'engineering', legit: 2, commands: [command], status: ['Заряд 75%'],
};

const machine = {
  address: node.address, title: node.name, type: node.type,
  online: true, access: 2, fields: node.status, commands: [command],
  extra: [], feed: null, watching: false, can_breach: true,
};

const setup = (overrides: Partial<NetrunData> = {}) => {
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({
    config: { interface: 'NetrunTerminal' },
    data: {
      origin: 'terminal', wireless: false, uplink: true, trace: 0,
      locked: 0, can_breach: true, log: [], jack: null, host_actions: [],
      networks: [], view: null, selected: node,
      storage: { files: [], used: 0, capacity: 10 }, shard: null,
      breach: null, entity: null, combat: null, chat: { handle: 'runner', messages: [] },
      web: null, windows: [], window: null,
      map: { gateways: [], focus: node.address, revision: 1,
        nodes: [node, { ...node, address: 'BBBB:0002', x: 20 }],
        edges: [{ id: 'apc-link', from: node.address, to: 'BBBB:0002', kind: 'apc' }] },
      selected_network: null, ping_route: null,
      cli: { verbs: [{ id: 'sel', args: '<адрес>', desc: 'Выбрать узел.' }] },
      ...overrides,
    },
  }));
  return Object.assign(topic, { store });
};

const sent = (topic, action: string) => topic.mock.calls
  .filter((call) => call[0]?.type === `act/${action}`)
  .map((call) => { const { _netrun_action: _receipt, ...payload } = JSON.parse(call[0].payload); return payload; });

describe('Netrun terminal panels', () => {
  test('quiet delta polls retain a 6000-node scene without layout or reindexing', async () => {
    const index = jest.spyOn(GraphScene.prototype, 'update');
    const layout = jest.spyOn(mapGeometry, 'layoutGraph');
    try {
      const nodes = Array.from({ length: 6000 }, (_, i) => ({ ...node, address: `N${i}`, x: 10 + i % 80 * 2, y: 10 + Math.floor(i / 80) * 2 }));
      const initial: NetMap = { epoch: 'terminal-ui', full: true, gateways: [], focus: nodes[0].address,
        revision: 1, structure_revision: 1, static_revision: 1, state_revision: 1, nodes, edges: [] };
      const topic = setup({ map: initial });
      const panel = render(<StationMap />);
    await act(async () => {});
      const surface = await surfaceReady();
      const retained = surface.updateScene.mock.calls.slice(-1)[0][0];
      const counts = [index, layout].map((spy) => spy.mock.calls.length);
      for (let i = 0; i < 5; i++) {
        const idle: NetMapDelta = { epoch: 'terminal-ui', full: false, base_revision: 1, state_revision: 1, nodes: [], edges: [], focus: nodes[0].address };
        act(() => topic.store.dispatch(backendUpdate({ data: { map: idle, events: [], search: [] } })));
        panel.rerender(<StationMap />);
    await act(async () => {});
      }
      expect(panel.getByText('6000/6000 · текущий этаж')).toBeTruthy();
      expect([index, layout].map((spy) => spy.mock.calls.length)).toEqual(counts);
      expect(surface.updateScene.mock.calls.slice(-1)[0][0]).toBe(retained);
      expect(sent(topic, 'map_resync')).toEqual([]);
      expect(panel.container.querySelectorAll('canvas[data-net-pixi]')).toHaveLength(1);
      expect(panel.container.querySelector('[data-net-canvas]')).toBeNull();
    } finally {
      index.mockRestore(); layout.mockRestore();
    }
  });

  test('a refreshed UI requests one baseline then applies sparse updates and removals', async () => {
    const missing: NetMapDelta = { epoch: 'new-ui', full: false, base_revision: 4, state_revision: 5, nodes: [], edges: [] };
    const topic = setup({ map: missing });
    const panel = render(<StationMap />);
    await act(async () => {});
    expect(sent(topic, 'map_resync')).toEqual([{}]);
    act(() => topic.store.dispatch(backendUpdate({ data: { map: { ...missing, state_revision: 6 } } })));
    panel.rerender(<StationMap />);
    await act(async () => {});
    expect(sent(topic, 'map_resync')).toEqual([{}]);
    const full: NetMap = { epoch: 'new-ui', full: true, gateways: [], focus: node.address, revision: 1,
      structure_revision: 1, static_revision: 1, state_revision: 6, nodes: [node], edges: [] };
    act(() => topic.store.dispatch(backendUpdate({ data: { map: full } })));
    panel.rerender(<StationMap />);
    await act(async () => {});
    expect(panel.getByText('1/1 · текущий этаж')).toBeTruthy();
    const peer = { ...node, address: 'PEER', x: 20 };
    const update: NetMapDelta = { epoch: 'new-ui', full: false, base_revision: 6, state_revision: 7,
      structure_revision: 2, static_revision: 2, nodes: [peer], edges: [{ id: 'new-link', from: node.address, to: peer.address, kind: 'apc' }] };
    act(() => topic.store.dispatch(backendUpdate({ data: { map: update } })));
    panel.rerender(<StationMap />);
    await act(async () => {});
    expect(panel.getByText('2/2 · текущий этаж')).toBeTruthy();
    act(() => topic.store.dispatch(backendUpdate({ data: { map: { ...update, base_revision: 7, state_revision: 8,
      structure_revision: 3, static_revision: 3, nodes: [], edges: [], removed_nodes: [node.address], removed_edges: ['new-link'] } } })));
    panel.rerender(<StationMap />);
    await act(async () => {});
    expect(panel.getByText('1/1 · текущий этаж')).toBeTruthy();
    expect(sent(topic, 'map_resync')).toEqual([{}]);
  });

  test('movement and live state reach one Pixi scene while unrelated node placements stay retained', async () => {
    const layout = jest.spyOn(mapGeometry, 'layoutGraph');
    try {
      const mobile = { ...node, address: 'MOBILE', type: 'deck', dynamic: true, x: 11, uplink: node.address };
      const peer = { ...node, address: 'PEER', x: 30 };
      const initial: NetMap = { gateways: [], focus: node.address, revision: 1,
        structure_revision: 1, static_revision: 1, state_revision: 1,
        nodes: [node, peer, mobile], edges: [
          { id: 'backbone', from: node.address, to: peer.address, kind: 'apc' },
          { id: 'mobile', from: node.address, to: mobile.address, kind: 'endpoint' },
        ] };
      const topic = setup({ selected: mobile, map: initial });
      const panel = render(<StationMap />);
    await act(async () => {});
      const surface = await surfaceReady();
      const retained = surface.updateScene.mock.calls.slice(-1)[0][0];
      const first = surface.updateActors.mock.calls.slice(-1)[0][0].byAddress.get(mobile.address);
      expect(layout).toHaveBeenCalledTimes(1);
      act(() => topic.store.dispatch(backendUpdate({ data: { selected: peer,
        events: [{ kind: 'trace', from: mobile.address, to: peer.address, age: 0 }],
        map: { ...initial, structure_revision: 2, state_revision: 2,
          nodes: [{ ...node, entities: 2, ice: 1, active: true }, peer, { ...mobile, x: 25, uplink: peer.address }],
          edges: [initial.edges[0], { ...initial.edges[1], from: peer.address }],
          route: { reachable: true, route: [mobile.address, peer.address], hops: 1, latency: 200, revision: 2 } } } })));
      panel.rerender(<StationMap />);
    await act(async () => {});
      expect(surface.updateScene.mock.calls.slice(-1)[0][0]).not.toBe(retained);
      const liveScene = surface.updateActors.mock.calls.slice(-1)[0][0];
      expect(liveScene).toBe(surface.updateScene.mock.calls.slice(-1)[0][0]);
      expect(liveScene.byAddress.get(peer.address)).toBe(retained.byAddress.get(peer.address));
      expect(liveScene.byAddress.get(mobile.address).px).not.toBe(first.px);
      expect(liveScene.byAddress.get(node.address)).toEqual(expect.objectContaining({ entities: 2, ice: 1, active: true }));
      expect(layout).toHaveBeenCalledTimes(2);
      act(() => topic.store.dispatch(backendUpdate({ data: { map: { ...initial, structure_revision: 3, state_revision: 3,
        static_revision: 2, nodes: [peer, mobile], edges: [] } } })));
      panel.rerender(<StationMap />);
    await act(async () => {});
      const replaced = surface.updateScene.mock.calls.slice(-1)[0][0];
      expect(replaced).not.toBe(retained);
      expect(replaced.byAddress.has(node.address)).toBe(false);
    } finally { layout.mockRestore(); }
  });

  test('sector/floor controls and relay destinations send explicit geographic actions', async () => {
    const relay = { ...node, type: 'relay', z: 1, sector: 'station' };
    const topic = setup({ selected: relay, map: { gateways: [], nodes: [relay], edges: [], focus: relay.address, revision: 1,
      source_sector: 'station', source_z: 1, active_sector: 'station', active_z: 1,
      sectors: [{ id: 'station', name: 'Станция', levels: [1, 2] }, { id: 'mining', name: 'Шахта', levels: [5] }],
      relay_destinations: [
        { from: relay.address, to: 'MINING', name: 'Реле шахты', sector: 'mining', z: 5, online: true, can_hop: true },
        { from: relay.address, to: 'OFFLINE', name: 'Неисправное реле', sector: 'mining', z: 5, online: false, can_hop: false, unavailable_reason: 'Реле отключено' },
      ] } });
    const { getByLabelText } = render(<StationMap />);
    await act(async () => {});
    fireEvent.click(getByLabelText('Сектор: Шахта'));
    fireEvent.click(getByLabelText('Этаж Z2'));
    fireEvent.click(getByLabelText('Показать реле Реле шахты'));
    fireEvent.click(getByLabelText('Перейти к реле Реле шахты'));
    fireEvent.click(getByLabelText('Перейти к реле Неисправное реле'));
    expect(sent(topic, 'map_sector')).toEqual([{ id: 'mining' }, { id: 'station', z: 2 }]);
    expect(sent(topic, 'select')).toEqual([{ address: 'MINING' }]);
    expect(sent(topic, 'relay_hop')).toEqual([{ address: 'MINING' }]);
  });

  test('my node clears incompatible filters and centers only after its new floor arrives', async () => {
    const center = jest.spyOn(GraphViewport.prototype, 'center');
    const remote = { ...node, address: 'REMOTE', type: 'camera', z: 5 };
    const host = { ...node, address: 'HOST', type: 'camera', x: 50, y: 60, z: 1 };
    const initial = { gateways: [], nodes: [remote], edges: [], focus: remote.address, revision: 1,
      active_sector: 'mining', active_z: 5 };
    const topic = setup({ selected: remote, map: initial,
      entity: { name: 'Process', integrity: 100, max_integrity: 100, host: host.address, host_name: host.name, diving: false } });
    const panel = render(<StationMap />);
    await act(async () => {});
    fireEvent.click(panel.getByLabelText('Фильтр: Камеры'));
    fireEvent.click(panel.getByText('Рядом'));
    fireEvent.input(panel.getByPlaceholderText('Имя или адрес устройства…'), { target: { value: 'Скрыть всё' } });
    fireEvent.click(panel.getByText('Мой узел'));
    expect(sent(topic, 'focus_host')).toHaveLength(1);
    expect(center).not.toHaveBeenCalled();
    expect((panel.getByPlaceholderText('Имя или адрес устройства…') as HTMLInputElement).value).toBe('');
    act(() => topic.store.dispatch(backendUpdate({ data: { map: { ...initial }, log: [{ text: 'Old floor response', kind: 'label' }] } })));
    expect(center).not.toHaveBeenCalled();
    const fresh = { ...initial, revision: 2, active_sector: 'station', active_z: 1,
      nodes: [host, { ...host, address: 'PEER', x: 80 }], focus: host.address };
    act(() => topic.store.dispatch(backendUpdate({ data: { selected: host, map: fresh } })));
    panel.rerender(<StationMap />);
    await act(async () => {});
    expect(panel.getByText('2/2 · текущий этаж')).toBeTruthy();
    expect(center).toHaveBeenCalledTimes(1);
    expect(center.mock.calls[0][0]).toEqual(expect.objectContaining({ px: 50 * GRAPH_TILE, py: -60 * GRAPH_TILE }));
    act(() => topic.store.dispatch(backendUpdate({ data: { map: { ...fresh } } })));
    expect(center).toHaveBeenCalledTimes(1);
    center.mockRestore();
  });

  test('show relay selects the destination and centers after the delayed sector response', async () => {
    const center = jest.spyOn(GraphViewport.prototype, 'center');
    const origin = { ...node, type: 'relay', z: 1 };
    const target = { ...origin, address: 'TARGET', x: 70, y: 80, z: 5 };
    const initial = { gateways: [], nodes: [origin], edges: [], focus: origin.address, revision: 1,
      active_sector: 'station', active_z: 1, relay_destinations: [{ from: origin.address, to: target.address,
        name: 'Реле назначения', sector: 'mining', z: 5, online: true, can_hop: false }] };
    const topic = setup({ selected: origin, map: initial });
    const panel = render(<StationMap />);
    await act(async () => {});
    fireEvent.click(panel.getByLabelText('Фильтр: Реле NTnet'));
    fireEvent.input(panel.getByPlaceholderText('Имя или адрес устройства…'), { target: { value: 'Без совпадений' } });
    fireEvent.click(panel.getByLabelText('Показать реле Реле назначения'));
    expect(sent(topic, 'select')).toEqual([{ address: target.address }]);
    expect(sent(topic, 'map_sector')).toEqual([]);
    expect(center).not.toHaveBeenCalled();
    act(() => topic.store.dispatch(backendUpdate({ data: { map: { ...initial, revision: 2 } } })));
    expect(center).not.toHaveBeenCalled();
    act(() => topic.store.dispatch(backendUpdate({ data: { selected: target, map: { ...initial, revision: 3,
      active_sector: 'mining', active_z: 5, nodes: [target], focus: target.address, relay_destinations: [] } } })));
    panel.rerender(<StationMap />);
    await act(async () => {});
    expect(panel.getByText('1/1 · текущий этаж')).toBeTruthy();
    expect(center).toHaveBeenCalledTimes(1);
    expect(center.mock.calls[0][0]).toEqual(expect.objectContaining({ px: 70 * GRAPH_TILE, py: -80 * GRAPH_TILE }));
    center.mockRestore();
  });

  test('legacy physical movement changes geometry even when global topology revision stays fixed', async () => {
    const layout = jest.spyOn(mapGeometry, 'layoutGraph');
    const map = { gateways: [], focus: node.address, revision: 1, nodes: [node], edges: [] };
    const topic = setup({ map });
    const panel = render(<StationMap />);
    await act(async () => {});
    expect(layout).toHaveBeenCalledTimes(1);
    act(() => topic.store.dispatch(backendUpdate({ data: { map: { ...map, nodes: [{ ...node, x: 50, y: 80 }] } } })));
    panel.rerender(<StationMap />);
    await act(async () => {});
    expect(layout).toHaveBeenCalledTimes(2);
    expect(layout.mock.results[1].value.get(node.address).anchorX).toBe(50 * GRAPH_TILE);
    layout.mockRestore();
  });

  test('dragging updates the Pixi camera before releasing the pointer without rebuilding geometry', async () => {
    const originalPointer = window.PointerEvent;
    Object.defineProperty(window, 'PointerEvent', { value: MouseEvent, configurable: true });
    try {
      const many = Array.from({ length: 420 }, (_, index) => ({
        ...node, address: `CAM:${index}`, type: 'camera', x: 10 + index, y: 10 + index,
      }));
      setup({ map: { gateways: [], focus: node.address, revision: 1, nodes: [node, ...many], edges: [] } });
      const panel = render(<StationMap />);
    await act(async () => {});
      const surface = await surfaceReady();
      const geometry = surface.updateScene.mock.calls.slice(-1)[0][0];
      const initial = { ...surface.updateCamera.mock.calls.slice(-1)[0][0] };
      const viewport = panel.getByLabelText('Карта сети');
      fireEvent.pointerDown(viewport, { clientX: 100, clientY: 100, button: 0 });
      fireEvent.pointerMove(viewport, { clientX: 220, clientY: 170, buttons: 1 });
      expect(surface.updateCamera.mock.calls.slice(-1)[0][0]).toEqual(expect.objectContaining({ x: initial.x + 120, y: initial.y + 70 }));
      fireEvent.pointerMove(viewport, { clientX: 260, clientY: 180, buttons: 1 });
      expect(surface.updateCamera.mock.calls.slice(-1)[0][0]).toEqual(expect.objectContaining({ x: initial.x + 160, y: initial.y + 80 }));
      expect(surface.updateScene.mock.calls.slice(-1)[0][0]).toBe(geometry);
      fireEvent.pointerUp(viewport, { clientX: 260, clientY: 180 });
      panel.unmount();
      expect(surface.destroy).toHaveBeenCalledTimes(1);
    } finally {
      Object.defineProperty(window, 'PointerEvent', { configurable: true, value: originalPointer });
    }
  });

  test('manual pan is preserved when a later structural update arrives', async () => {
    const originalPointer = window.PointerEvent;
    Object.defineProperty(window, 'PointerEvent', { value: MouseEvent, configurable: true });
    const fit = jest.spyOn(GraphViewport.prototype, 'fit');
    const topic = setup();
    const { getByText, getByLabelText, rerender } = render(<StationMap />);
    await act(async () => {});
    const viewport = getByLabelText('Карта сети');
    await surfaceReady();
    fireEvent.pointerDown(viewport, { clientX: 100, clientY: 100, button: 0 });
    fireEvent.pointerMove(viewport, { clientX: 150, clientY: 150, buttons: 1 });
    fireEvent.pointerUp(viewport, { clientX: 150, clientY: 150 });
    const before = fit.mock.calls.length;
    const map = topic.store.getState().backend.data.map;
    act(() => topic.store.dispatch(backendUpdate({ data: { map: { ...map, revision: 2,
      nodes: [...map.nodes, { ...node, address: 'NEW', type: 'camera', uplink: node.address }],
      edges: [...map.edges, { id: 'new', from: node.address, to: 'NEW', kind: 'endpoint' }] } } })));
    rerender(<StationMap />);
    await act(async () => {});
    expect(fit).toHaveBeenCalledTimes(before);
    fit.mockRestore();
    Object.defineProperty(window, 'PointerEvent', { value: originalPointer, configurable: true });
  });

  test('projected state revisions repaint without layout and structural revisions replace nodes and links', async () => {
    const layout = jest.spyOn(mapGeometry, 'layoutGraph');
    const initial = { gateways: [], focus: node.address, revision: 1, structure_revision: 4, state_revision: 10,
      nodes: [node], edges: [] };
    const topic = setup({ map: initial });
    const { getByText, rerender } = render(<StationMap />);
    await act(async () => {});
    expect(layout).toHaveBeenCalledTimes(1);
    act(() => topic.store.dispatch(backendUpdate({ data: { map: { ...initial, state_revision: 11, nodes: [{ ...node, online: false }] } } })));
    rerender(<StationMap />);
    await act(async () => {});
    expect(layout).toHaveBeenCalledTimes(1);
    const added = { ...node, address: 'NEW', type: 'camera', uplink: node.address };
    act(() => topic.store.dispatch(backendUpdate({ data: { map: { ...initial, structure_revision: 5, state_revision: 12,
      nodes: [node, added], edges: [{ id: 'new-link', from: node.address, to: 'NEW', kind: 'endpoint' }] } } })));
    rerender(<StationMap />);
    await act(async () => {});
    expect(getByText('2/2 · текущий этаж')).toBeTruthy();
    expect(layout).toHaveBeenCalledTimes(2);

    act(() => topic.store.dispatch(backendUpdate({ data: { map: { ...initial, structure_revision: 6, state_revision: 13 } } })));
    rerender(<StationMap />);
    await act(async () => {});
    expect(getByText('1/1 · текущий этаж')).toBeTruthy();
    expect(layout).toHaveBeenCalledTimes(3);
    layout.mockRestore();
  });

  test('BYOND numeric false values never appear beside guest access or breach controls', async () => {
    const numericFalse = 0 as unknown as boolean;
    setup({
      selected: null, can_breach: numericFalse,
      selected_network: {
        id: 'med', code: 'NET-MED', name: 'ЛВС: Медблок',
        color: '#55cbe9', security: 2, access: 0,
        has_key: numericFalse, can_breach: numericFalse, log: [],
      },
    });
    const panel = render(<NodePanel />);
    expect(panel.getByText('НЕТ')).toBeTruthy();
    expect(panel.queryByText('0')).toBeNull();
    expect(panel.queryByText('Подобрать доступ к сети')).toBeNull();
    panel.unmount();
  });

  test('locked node with BYOND numeric false LAN flags has no ghost zero labels', async () => {
    const numericFalse = 0 as unknown as boolean;
    setup({
      can_breach: numericFalse,
      selected: { ...node, access: 0, legit: 0,
        lan: { id: 'med', code: 'NET-MED', name: 'ЛВС: Медблок',
          color: '#55cbe9', security: 2, access: 0, has_key: numericFalse,
          can_breach: numericFalse } },
    });
    const panel = render(<NodePanel />);
    expect(panel.queryByText('0')).toBeNull();
    expect(panel.queryByText('Подобрать доступ к ЛВС')).toBeNull();
    expect(panel.queryByText('Подобрать доступ')).toBeNull();
  });

  test('automatic breach explicitly sends its mode and shows waiting progress instead of cells', async () => {
    const topic = setup({ can_autobreach: true, selected: { ...node, access: 1 } });
    const panel = render(<NodePanel />);
    fireEvent.click(panel.getByText('Автовзлом'));
    expect(sent(topic, 'breach')).toContainEqual({ kind: 'node', id: node.address, automatic: true });
    panel.unmount();
    const { getByText } = render(<MatrixPanel state={{ minigame: 'automatic', target: 'test node', security: 3,
      size: 0, cells: [], daemons: [], time_left: 18, progress: 0.4 }} />);
    expect(getByText(/Подбор доступа: 40%/)).toBeTruthy();
    fireEvent.click(getByText('Прервать взлом'));
    expect(sent(topic, 'breach_abort')).toHaveLength(1);
  });

  test('incoming ICE warning remains visible over an active breach puzzle', async () => {
    setup({ combat: { node: node.address, node_name: node.name, self: null, targets: [], programs: [],
      incoming: [{ source: 'ICE-SENTRY', name: 'strike.exe', role: 'attack', power: 18, remaining: 2.5 }] },
    breach: { minigame: 'automatic', target: node.name, security: 2, size: 0, cells: [], daemons: [], time_left: 18, progress: 0.3 } });
    const { getByRole, getByText } = render(<NetrunContent />);
    await act(async () => {});
    expect(getByRole('alert').textContent).toContain('ICE-SENTRY готовит strike.exe');
    expect(getByRole('alert').textContent).toContain('2.5 с');
    expect(getByText('Открыть бой')).toBeTruthy();
  });

  test('recoverable daemon loot is shown even without a living combat target', async () => {
    const topic = setup({ combat: { node: node.address, node_name: node.name,
      self: { integrity: 100, max_integrity: 100, stunned: false }, targets: [], programs: [],
      loot: [{ uid: 'salvage-1', name: 'autobreach.exe', kind: 'daemon', size: 3, preview: null }] } });
    const { getByText } = render(<CombatPanel />);
    expect(getByText(/autobreach.exe/)).toBeTruthy();
    fireEvent.click(getByText('Забрать'));
    expect(sent(topic, 'recover_salvage')).toEqual([{ uid: 'salvage-1' }]);
  });

  test('stored route generations update status and overlay without recomputing graph geometry', async () => {
    const layout = jest.spyOn(mapGeometry, 'layoutGraph');
    const topic = setup();
    const map = topic.store.getState().backend.data.map;
    const route = { route: [node.address, 'BBBB:0002'], hops: 1, latency: 300, revision: 7, reachable: true };
    act(() => topic.store.dispatch(backendUpdate({ data: { map: { ...map, route } } })));
    const { container, getByText, getByTitle, rerender } = render(<StationMap />);
    await act(async () => {});
    expect(getByText('Путь: 1 пер. · 300 мс')).toBeTruthy();
    await surfaceReady();
    expect(container.querySelector('canvas[data-net-pixi]')).not.toBeNull();
    expect(layout).toHaveBeenCalledTimes(1);
    act(() => topic.store.dispatch(backendUpdate({ data: { map: { ...map, route: { ...route, revision: 8, latency: 400 } } } })));
    rerender(<StationMap />);
    await act(async () => {});
    expect(getByText('Путь: 1 пер. · 400 мс')).toBeTruthy();
    expect(getByTitle('Сохранённый маршрут #8')).toBeTruthy();
    expect(layout).toHaveBeenCalledTimes(1);
    act(() => topic.store.dispatch(backendUpdate({ data: { map: { ...map, route: { ...route, revision: 9, reachable: false } } } })));
    rerender(<StationMap />);
    await act(async () => {});
    expect(getByText('Путь: нет связи')).toBeTruthy();
    await surfaceReady();
    expect(container.querySelectorAll('canvas[data-net-pixi]')).toHaveLength(1);
    expect(container.querySelector('[data-net-canvas]')).toBeNull();
    layout.mockRestore();
  });

  test('a stored path never draws a shortcut across missing intermediate vertices', async () => {
    const topic = setup();
    const map = topic.store.getState().backend.data.map;
    act(() => topic.store.dispatch(backendUpdate({ data: { map: { ...map, route: {
      route: [node.address, 'NOT-IN-SLICE', 'BBBB:0002'], hops: 2, latency: 500, revision: 1, reachable: true,
    } } } })));
    const { container, getByText } = render(<StationMap />);
    await act(async () => {});
    expect(getByText('Путь: 2 пер. · 500 мс')).toBeTruthy();
    await surfaceReady();
    expect(container.querySelectorAll('canvas[data-net-pixi]')).toHaveLength(1);
    expect(container.querySelector('[data-net-canvas]')).toBeNull();
  });

  test('log polling reuses layout and a suspended map does not inspect replacement payloads', async () => {
    const layout = jest.spyOn(mapGeometry, 'layoutGraph');
    const topic = setup();
    const { rerender } = render(<StationMap />);
    await act(async () => {});
    expect(layout).toHaveBeenCalledTimes(1);
    const currentMap = topic.store.getState().backend.data.map;
    act(() => topic.store.dispatch(backendUpdate({ data: {
      map: { ...currentMap, nodes: currentMap.nodes.map((entry) => ({ ...entry })) },
      trace: 15, log: [{ text: 'New log entry', kind: 'label' }],
    } })));
    rerender(<StationMap />);
    await act(async () => {});
    expect(layout).toHaveBeenCalledTimes(1);
    rerender(<StationMap suspended />);
    await act(async () => {});
    const replacement = Object.defineProperty({ ...currentMap }, 'nodes', {
      get: () => { throw new Error('A suspended map must not read the graph'); },
    });
    act(() => topic.store.dispatch(backendUpdate({ data: { map: replacement } })));
    rerender(<StationMap suspended />);
    await act(async () => {});
    expect(layout).toHaveBeenCalledTimes(1);
    layout.mockRestore();
  });

  test('workspace and map consume available height and remote file controls stay in aligned scrolling rows', async () => {
    setup({ workspace_view: 'map', selected: { ...node, access: 3, files: [
      { uid: 'text', name: 'Очень длинное имя файла с заметкой для передачи.txt', kind: 'text', size: 1, preview: null },
      { uid: 'photo', name: 'Фото.png', kind: 'photo', size: 2, preview: null },
    ] } });
    const { container, getByText } = render(<NetrunContent />);
    await act(async () => {});
    fireEvent.click(getByText('Показать информацию об узле'));
    const workspace = container.querySelector<HTMLElement>('[data-net-layout="workspace"]');
    const map = container.querySelector<HTMLElement>('[data-net-layout="map"]');
    expect(workspace.style.flex).toContain('1 1');
    expect(map.style.height).toBe('100%');
    expect(container.querySelector<HTMLElement>('[aria-label="Карта сети"]').classList.contains('netrun-viewport')).toBe(true);
    const files = container.querySelector<HTMLElement>('[data-net-files="remote"]');
    expect(files.style.overflowY).toBe('auto');
    const rows = [...files.querySelectorAll<HTMLElement>('[data-net-file-row]')];
    expect(rows.length).toBe(2);
    for (const row of rows) {
      // Filename and buttons share a row; controls remain right-aligned.
      const actions = row.querySelector<HTMLElement>('[data-net-file-actions]');
      expect(row.style.display).toBe('flex');
      expect(row.style.alignItems).toBe('center');
      expect(actions.style.display).toBe('flex');
      expect(actions.style.flexWrap).toBe('nowrap');
      expect(actions.style.justifyContent).toBe('flex-end');
      expect(actions.style.flex).toContain('0 0');
    }
  });

  test('map filters and local search exclude vertices without rebuilding topology', async () => {
    const camera = { ...node, address: 'CAM:0001', name: 'Камера лаборатории', type: 'camera', x: 20 };
    const topic = setup({ map: { gateways: [], focus: node.address, revision: 1,
      nodes: [node, camera], edges: [{ id: 'camera-link', from: camera.address, to: node.address, kind: 'endpoint' }] } });
    const { getByLabelText, getByPlaceholderText, getByText } = render(<StationMap />);
    await act(async () => {});
    expect(getByText('2/2 · текущий этаж')).toBeTruthy();
    fireEvent.click(getByLabelText('Фильтр: Камеры'));
    expect(getByText('1/2 · текущий этаж')).toBeTruthy();
    fireEvent.keyDown(getByLabelText('Карта сети'), { key: 'd' });
    expect(sent(topic, 'select')).toEqual([]);
    fireEvent.click(getByLabelText('Фильтр: Камеры'));
    expect(getByText('2/2 · текущий этаж')).toBeTruthy();
    const input = getByPlaceholderText('Имя или адрес устройства…');
    fireEvent.input(input, { target: { value: 'лаборатории' } });
    expect(getByText('1/2 · текущий этаж')).toBeTruthy();
    fireEvent.input(input, { target: { value: 'несуществующий узел' } });
    expect(getByText('0/2 · текущий этаж')).toBeTruthy();
    fireEvent.input(input, { target: { value: '' } });
    expect(getByText('2/2 · текущий этаж')).toBeTruthy();
  });

  test('large network uses one Pixi surface with no legacy map renderer or DOM per vertex', async () => {
    const large = Array.from({ length: 1100 }, (_, i) => ({ ...node, address: `CLIENT-${i}`, type: 'camera', uplink: node.address }));
    const edges = large.map((n) => ({ id: n.address, from: n.address, to: node.address, kind: 'endpoint' as const }));
    setup({ map: { gateways: [], focus: node.address, revision: 1, nodes: [node, ...large], edges } });
    const { container, getByText } = render(<StationMap />);
    await act(async () => {});
    expect(getByText('1101/1101 · текущий этаж')).toBeTruthy();
    await surfaceReady();
    expect(container.querySelectorAll('canvas[data-net-pixi]')).toHaveLength(1);
    expect(container.querySelector('[data-net-canvas]')).toBeNull();
    expect(container.querySelectorAll('[data-net-node]')).toHaveLength(0);
    expect(container.querySelectorAll('[data-net-edge]')).toHaveLength(0);
  });

  test('node commands have natural height and dispatch the selected command', async () => {
    const topic = setup();
    const { container, getByText } = render(<NodePanel />);
    expect(container.querySelector('.Section--fill')).toBeNull();
    expect(getByText('Заряд 75%')).toBeTruthy();
    fireEvent.click(getByText(command.name));
    expect(sent(topic, 'command')).toEqual([{ id: command.id }]);
  });

  test('BYOND numeric false flags do not print stray zeros in machine tabs', async () => {
    setup();
    const { queryByText, getByText } = render(<WindowPanel window={{
      ...machine,
      can_breach: 0 as unknown as boolean,
      feed: 0 as unknown as string[],
      remote: 0 as never,
      network: { id: 'eng', name: 'Engineering', code: 'NET-ENG', access: 1, can_breach: true },
    }} />);
    expect(queryByText('0')).toBeNull();
    expect(getByText('Подобрать доступ к NET-ENG')).toBeTruthy();
  });

  test('sequence puzzle supports keyboard activation without changing action protocol', async () => {
    const topic = setup();
    const { getByRole } = render(<MatrixPanel state={{
      minigame: 'sequence', target: 'TEST', security: 1, size: 1,
      time_left: 20, cells: [{ code: '7A', active: true, order: 1 }], daemons: [],
      progress: 0, total: 1,
    }} />);
    fireEvent.keyDown(getByRole('button', { name: 'Выбрать код 7A, шаг 1' }), { key: 'Enter' });
    expect(sent(topic, 'breach_pick')).toEqual([{ index: 1 }]);
  });

  test('map network chooser closes after selecting a gateway', async () => {
    const gateway = { id: 'engineering', code: 'NET-ENG', name: 'Engineering',
      color: '#55cbe9', security: 2, access: 2, has_key: false, can_breach: false };
    const topic = setup({ map: {
      gateways: [gateway], focus: node.address, revision: 1, nodes: [node], edges: [],
    } });
    const panel = render(<StationMap />);
    await act(async () => {});
    const menu = panel.container.querySelector<HTMLDetailsElement>('details.netrun-map-gateways');
    expect(menu).not.toBeNull();
    menu!.open = true;
    fireEvent.click(panel.getByText('NET-ENG'));
    expect(menu!.open).toBe(false);
    expect(sent(topic, 'select_network')).toEqual([{ id: 'engineering' }]);
  });

  test('machine tab shows commands, breach and native actions without parameters', async () => {
    const topic = setup();
    const { container, getByText } = render(<WindowPanel window={{
      ...machine,
      remote: { interface: 'PortableTurret', data: { enabled: true }, actions: [
        { id: 'power', name: 'Питание турели', access: 3, allowed: true },
      ] },
    }} />);
    expect(container.querySelector('.Section--fill')).toBeNull();
    fireEvent.click(getByText(command.name));
    expect(sent(topic, 'window_act')).toEqual([{ address: node.address, waction: command.id }]);
    fireEvent.click(getByText('Подобрать доступ к узлу'));
    expect(sent(topic, 'breach')).toEqual([{ kind: 'node', id: node.address }]);
    fireEvent.click(getByText('Питание турели'));
    expect(sent(topic, 'remote_act')).toEqual([{ address: node.address, request: 'power', arguments: {} }]);
  });

  test('matrix remains visible when a machine tab starts a breach', async () => {
    setup({
      window: machine,
      windows: [{ address: node.address, title: node.name, type: node.type, online: true }],
      breach: {
        target: 'BREACH APC', security: 2, size: 1,
        cells: [{ code: '1C', active: true }], buffer: [], buffer_size: 4,
        daemons: [], time_left: 20, pick_row: true,
      },
    });
    const { container, getByText } = render(<NetrunContent />);
    await act(async () => {});
    expect(getByText('BREACH APC')).toBeTruthy();
    expect(container.querySelector<HTMLElement>('[data-net-page="breach"]').style.display).toBe('flex');
    expect(container.querySelector<HTMLElement>('[data-net-page="pinned"]').style.display).toBe('none');
  });

  test('Tab completes addresses from the unified map', async () => {
    setup();
    const { getByPlaceholderText } = render(<ConsoleLog />);
    const input = getByPlaceholderText('Введите команду…') as HTMLInputElement;
    fireEvent.change(input, { target: { value: 'sel BBB' } });
    fireEvent.keyDown(input, { key: 'Tab' });
    expect(input.value).toBe('sel BBBB:0002 ');
    fireEvent.change(input, { target: { value: 'sel AAAA:000' } });
    fireEvent.keyDown(input, { key: 'Tab' });
    expect(input.value).toBe('sel AAAA:0001 ');
  });

  test('history keeps fifty commands and restores the unfinished draft', async () => {
    setup();
    const { getByPlaceholderText } = render(<ConsoleLog />);
    const input = getByPlaceholderText('Введите команду…') as HTMLInputElement;
    for (let i = 0; i < 51; i++) {
      fireEvent.change(input, { target: { value: `cmd${i}` } });
      fireEvent.keyDown(input, { key: 'Enter' });
    }
    fireEvent.change(input, { target: { value: 'draft' } });
    for (let i = 0; i < 55; i++) {
      fireEvent.keyDown(input, { key: 'ArrowUp' });
    }
    expect(input.value).toBe('cmd1');
    for (let i = 0; i < 50; i++) {
      fireEvent.keyDown(input, { key: 'ArrowDown' });
    }
    expect(input.value).toBe('draft');
  });

  test('map keyboard navigation requires map focus and entity hops start at its host', async () => {
    const topic = setup({
      selected: { ...node, address: 'Z-SELECTED' },
      entity: { name: 'Process', integrity: 100, max_integrity: 100, host: 'A-HOST', host_name: 'Host', diving: false },
      map: { gateways: [], focus: 'A-HOST', revision: 1, nodes: [
        { ...node, address: 'Z-SELECTED' }, { ...node, address: 'A-HOST' },
        { ...node, address: 'B-LOCKED', access: 1 }, { ...node, address: 'C-OFFLINE', online: false },
        { ...node, address: 'D-TARGET' }, { ...node, address: 'E-NONNEIGHBOR' },
      ], edges: [
        { id: 'locked', from: 'A-HOST', to: 'B-LOCKED', kind: 'apc' },
        { id: 'offline', from: 'A-HOST', to: 'C-OFFLINE', kind: 'apc' },
        { id: 'target', from: 'A-HOST', to: 'D-TARGET', kind: 'apc' },
        { id: 'indirect', from: 'B-LOCKED', to: 'E-NONNEIGHBOR', kind: 'apc' },
      ] },
    });
    const { getByLabelText, getByPlaceholderText } = render(<StationMap />);
    await act(async () => {});
    fireEvent.keyDown(getByPlaceholderText('Имя или адрес устройства…'), { key: 'd', shiftKey: true });
    expect(sent(topic, 'hop')).toEqual([]);
    const canvas = getByLabelText('Карта сети');
    fireEvent.keyDown(canvas, { key: 'd', shiftKey: true });
    expect(sent(topic, 'hop')).toEqual([{ address: 'D-TARGET' }]);
  });

  test('locating a search result clears obstructing filters and centers its confirmed location', async () => {
    const target = { ...node, address: 'SEARCH-HIT', name: 'Камера теста', type: 'camera', x: 20 };
    const topic = setup({ map: { nodes: [node, target], edges: [], gateways: [], focus: node.address, revision: 1 },
      search: [{ address: target.address, name: target.name, type: target.type, network: 'test', online: true, visible: true }] });
    const centered = jest.spyOn(GraphViewport.prototype, 'center');
    try {
      const panel = render(<StationMap />);
    await act(async () => {});
      centered.mockClear(); // Initial framing centers the connection on a large graph.
      fireEvent.click(panel.getByLabelText('Фильтр: Камеры'));
      fireEvent.input(panel.getByPlaceholderText('Имя или адрес устройства…'), { target: { value: 'Нет совпадений' } });
      expect(panel.getByText('Все узлы скрыты фильтрами.')).toBeTruthy();
      fireEvent.click(panel.getByLabelText(`Выбрать узел ${target.name} на карте`));
      expect(panel.getByText('2/2 · текущий этаж')).toBeTruthy();
      expect((panel.getByPlaceholderText('Имя или адрес устройства…') as HTMLInputElement).value).toBe('');
      expect(sent(topic, 'select')).toEqual([{ address: target.address }]);
      expect(centered).not.toHaveBeenCalled();
      act(() => topic.store.dispatch(backendUpdate({ data: { selected: target } })));
      panel.rerender(<StationMap />);
    await act(async () => {});
      expect(centered).toHaveBeenCalledTimes(1);
      expect(centered.mock.calls[0][0]).toMatchObject({ address: target.address });
    } finally { centered.mockRestore(); }
  });

  test('map shortcuts leave modified keyboard commands and text editing alone', async () => {
    const topic = setup();
    const panel = render(<StationMap />);
    await act(async () => {});
    const viewport = panel.getByLabelText('Карта сети');
    for (const modifiers of [{ ctrlKey: true }, { altKey: true }, { metaKey: true }]) {
      fireEvent.keyDown(viewport, { key: 'd', ...modifiers });
    }
    const textarea = document.createElement('textarea');
    viewport.appendChild(textarea);
    fireEvent.keyDown(textarea, { key: 'd' });
    textarea.remove();
    fireEvent.keyDown(panel.getByPlaceholderText('Имя или адрес устройства…'), { key: 'd' });
    expect(sent(topic, 'select')).toEqual([]);
    fireEvent.keyDown(viewport, { key: 'd' });
    expect(sent(topic, 'select')).toEqual([{ address: 'BBBB:0002' }]);
  });

  test('a LAN key permits a guest to hop without enabling machine commands', async () => {
    const host = { ...node, address: 'A-HOST' };
    const keyed = { ...node, address: 'KEY-CLIENT', type: 'camera', uplink: host.address,
      access: 1, legit: 1, can_hop: true, commands: [{ ...command, allowed: false }] };
    const topic = setup({ selected: keyed,
      entity: { name: 'Process', integrity: 100, max_integrity: 100, host: host.address, host_name: 'Host', diving: false },
      map: { nodes: [host, keyed], edges: [{ id: 'keyed-neighbor', from: host.address, to: keyed.address, kind: 'endpoint' }],
        gateways: [], focus: host.address, revision: 1 },
    });
    const { getByLabelText, getByText } = render(<><StationMap /><NodePanel /></>);
    await act(async () => {});
    expect(getByText(command.name).closest('.Button').classList.contains('Button--disabled')).toBe(true);
    const hop = getByText('Перейти в узел');
    expect(hop.closest('.Button').classList.contains('Button--disabled')).toBe(false);
    fireEvent.click(hop);
    fireEvent.keyDown(getByLabelText('Карта сети'), { key: 's', shiftKey: true });
    // The transport intentionally deduplicates identical actions within 50 ms.
    expect(sent(topic, 'hop')).toEqual([{ address: keyed.address }]);
    fireEvent.click(getByText(command.name));
    expect(sent(topic, 'command')).toEqual([]);
  });

  test('a rejected file creation and later polling preserve the entire draft', async () => {
    const topic = setup({ file: null, storage: { files: [], used: 6, capacity: 6 } });
    const { container, getByText, rerender } = render(<FilePanel />);
    fireEvent.click(getByText('Новый текстовый файл'));
    const draft = 'Новый документ, который пока не помещается в память.';
    fireEvent.change(container.querySelector('textarea'), { target: { value: draft } });
    fireEvent.click(getByText('Создать'));
    expect(sent(topic, 'file_new')).toEqual([{ name: 'note.txt', content: draft, to_shard: false }]);
    act(() => {
      topic.store.dispatch(backendUpdate({ data: { file: null } }));
    });
    rerender(<FilePanel />);
    expect(container.querySelector('textarea')?.value).toBe(draft);
    expect(getByText('Создать')).toBeTruthy();
  });
});

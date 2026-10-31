import { act, fireEvent, render, within } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendSuspendSuccess, backendUpdate } from '../../backend';
import { debugReducer } from '../../debug';
import { NetrunContent } from './Content';
import { mountNetrunPixi } from './pixiSurface';
import type { MockPixiSurface } from './testSupport/pixiSurfaceMock';
import { MatrixState, NetOperation, NetrunData, WorkspaceView } from './types';

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

const node = {
  address: 'TEST:0001', name: 'Сервер теста', type: 'server', x: 0, y: 0,
  security: 2, online: true, access: 2, legit: 2, entities: 0, active: false,
  uplink: null, network: 'test', commands: [], status: [],
};
const machine = {
  address: node.address, title: node.name, type: node.type, online: true,
  access: 2, fields: ['Состояние закреплённого сервера'], commands: [], extra: [],
  feed: null, watching: false, can_breach: true,
};
const breach: MatrixState = {
  minigame: 'automatic', target: 'BREACH TEST', security: 2, size: 0,
  cells: [], daemons: [], time_left: 18, progress: 0.3,
};

const setup = (overrides: Partial<NetrunData> = {}) => {
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'NetrunTerminal' }, data: {
    origin: 'terminal', workspace_view: 'terminal', wireless: false, uplink: true,
    trace: 0, locked: 0, can_breach: true, log: [], jack: null, host_actions: [],
    networks: [], view: null, selected: node, selected_network: null,
    storage: { files: [], used: 0, capacity: 10 }, shard: null, file: null,
    breach: null, entity: null, combat: null, chat: { handle: 'runner', messages: [] },
    web: null, windows: [], window: null, ping_route: null,
    map: { nodes: [node], edges: [], gateways: [], focus: node.address, revision: 1 },
    cli: { verbs: [{ id: 'help', args: '', desc: 'Справка' }] },
    ...overrides,
  } }));
  const panel = render(<NetrunContent />);
  const update = (data: Partial<NetrunData>) => {
    act(() => store.dispatch(backendUpdate({ data })));
    panel.rerender(<NetrunContent />);
  };
  const page = (id: WorkspaceView) => panel.container.querySelector<HTMLElement>(`[data-net-page="${id}"]`);
  return { topic, store, panel, update, page };
};

const actions = (topic, action: string) => topic.mock.calls
  .filter((call) => call[0]?.type === `act/${action}`)
  .map((call) => { const { _netrun_action: _receipt, ...payload } = JSON.parse(call[0].payload); return payload; });

describe('Netrun workspace pages', () => {
  let actionTime = Date.now();
  beforeEach(() => {
    actionTime += 1000;
    jest.spyOn(Date, 'now').mockReturnValue(actionTime);
  });
  afterEach(() => jest.restoreAllMocks());

  test('a pooled window clears its subscribers and drafts before a fresh session arrives', () => {
    const { panel, store, page } = setup({ workspace_view: 'files' });
    const baseline = store.getState().backend.data;
    fireEvent.click(within(page('files')).getByText('Новый текстовый файл'));
    fireEvent.change(page('files').querySelector('textarea'), { target: { value: 'Черновик старого сеанса' } });
    act(() => store.dispatch(backendSuspendSuccess()));
    expect(panel.container.querySelector('[data-net-layout="workspace"]')).toBeNull();
    act(() => store.dispatch(backendUpdate({ data: baseline })));
    expect(panel.getByRole('tabpanel', { name: 'Файлы' })).toBeTruthy();
    expect(page('files').querySelector('textarea')).toBeNull();
  });

  test('opens the terminal alone and gives every tool a dedicated workspace', () => {
    const { panel, page, topic } = setup();
    expect(panel.getByRole('tabpanel', { name: 'Терминал' })).toBeTruthy();
    expect(page('map').style.display).toBe('none');
    expect(page('files').style.display).toBe('none');
    expect(panel.container.querySelector('[data-net-layout="bottom"]')).toBeNull();
    expect(panel.container.querySelector('[data-net-pixi]')).toBeNull();
    fireEvent.click(panel.getByText('Файлы'));
    expect(panel.getByRole('tabpanel', { name: 'Файлы' })).toBeTruthy();
    expect(page('terminal').style.display).toBe('none');
    expect(actions(topic, 'workspace_view')).toEqual([{ page: 'files' }]);
    expect(actions(topic, 'view_network')).toHaveLength(0);
  });

  test('the threat shortcut opens security and its map action addresses only an evidence ID', () => {
    const { panel, topic, page } = setup({ workspace_view: 'map', security: { defended: null, entries: [{
      id: 'trace-42', kind: 'intrusion', age: 3, ttl: 42, attributed: true, name: 'Раннер', source_address: 'TEST:0001',
      active: true, status: 'Источник установлен.', trace_allowed: true, map_allowed: true, pursue_allowed: false,
      pursue_reason: 'Нужна сетевая сущность.',
    }] } });
    fireEvent.click(panel.getByText('Угрозы (1)'));
    expect(panel.getByRole('tabpanel', { name: 'Терминал' })).toBeTruthy();
    const security = within(page('terminal')).getByRole('region', { name: 'Безопасность сети' });
    expect(security.parentElement.style.display).toBe('flex');
    fireEvent.click(within(security).getByText('Узел на карте'));
    expect(actions(topic, 'security_map')).toEqual([{ id: 'trace-42' }]);
  });

  test('a delivered file proposal is discoverable from the Files tab and waits for acceptance', () => {
    const { panel, page, topic } = setup({ file_exchange: { incoming: [{ id: 'proposal', sender: 'Резидент', name: 'agent.bot', kind: 'bot',
      size: 8, ttl: 120, can_accept: true }], max_offers: 8 } });
    expect(panel.getByText('Файлы (1)')).toBeTruthy();
    fireEvent.click(panel.getByRole('tab', { name: 'Файлы' }));
    const inbox = within(page('files')).getByRole('region', { name: 'Входящие предложения файлов' });
    expect(within(inbox).getByText('agent.bot')).toBeTruthy();
    expect(actions(topic, 'entity_file_accept')).toEqual([]);
  });

  test('Agents is its own page and a file shortcut preserves the selected template UID', () => {
    const template = { uid: 'bot-template', name: 'sentinel.bot', kind: 'bot', size: 8, preview: 'Страж', agent_profile: 'sentinel' };
    const { panel, page, topic, update } = setup({ workspace_view: 'files', agent_count: 2,
      storage: { files: [template], used: 8, capacity: 128 }, file: { ...template, source: 'local', content: null, image: null },
    });
    expect(panel.getByRole('tab', { name: 'Агенты' }).textContent).toContain('(2)');
    expect(page('files').querySelector('[data-net-agents]')).toBeNull();
    fireEvent.click(within(page('files')).getByText('К агентам: настройка и запуск'));
    expect(actions(topic, 'workspace_view')).toEqual([{ page: 'agents' }]);
    expect(actions(topic, 'file_select')).toEqual([]);
    update({ workspace_view: 'agents' });
    expect(panel.getByRole('tabpanel', { name: 'Агенты' })).toBeTruthy();
    expect(page('agents').querySelector('[data-net-bot-launch="bot-template"]')).not.toBeNull();
    fireEvent.click(within(page('agents')).getByText('Запустить агента'));
    expect(actions(topic, 'bot_launch')).toEqual([{ uid: 'bot-template' }]);
  });

  test('reopening after a missed breach completion restores the terminal and corrects server mode once', () => {
    const { panel, update, topic } = setup({ workspace_view: 'breach', breach: null });
    expect(panel.getByRole('tabpanel', { name: 'Терминал' })).toBeTruthy();
    expect(panel.queryByText('Взлом')).toBeNull();
    expect(actions(topic, 'workspace_view')).toEqual([{ page: 'terminal' }]);
    // Allow another transport delivery so its duplicate guard cannot mask extra corrections.
    jest.spyOn(Date, 'now').mockReturnValue(actionTime + 1000);
    update({ workspace_view: 'breach', breach: null, log: [{ text: 'Очередное обновление', kind: 'label' }] });
    expect(panel.getByRole('tabpanel', { name: 'Терминал' })).toBeTruthy();
    expect(actions(topic, 'workspace_view')).toEqual([{ page: 'terminal' }]);
    update({ workspace_view: 'terminal' });
    expect(actions(topic, 'workspace_view')).toEqual([{ page: 'terminal' }]);
  });

  test('navigation preserves the command line, file draft, map filters and viewport instance', async () => {
    const { panel, page, update } = setup();
    const cli = panel.getByLabelText('Командная строка') as HTMLInputElement;
    fireEvent.change(cli, { target: { value: 'ping unfinished' } });
    fireEvent.click(panel.getByText('Файлы'));
    fireEvent.click(within(page('files')).getByText('Новый текстовый файл'));
    const editor = page('files').querySelector('textarea');
    fireEvent.change(editor, { target: { value: 'Несохранённый документ' } });
    fireEvent.click(panel.getByText('Карта'));
    const search = panel.getByPlaceholderText('Имя или адрес устройства…') as HTMLInputElement;
    fireEvent.input(search, { target: { value: 'Сервер' } });
    const viewport = page('map').querySelector('[data-net-viewport]');
    expect(viewport).not.toBeNull();
    fireEvent.click(panel.getByText('Терминал'));
    update({ workspace_view: 'terminal', map: null, selected: null });
    expect(cli.value).toBe('ping unfinished');
    expect(page('map').querySelector('[data-net-viewport]')).toBe(viewport);
    fireEvent.click(panel.getByText('Файлы'));
    expect(page('files').querySelector('textarea')).toBe(editor);
    expect(editor.value).toBe('Несохранённый документ');
    fireEvent.click(panel.getByText('Карта'));
    expect(panel.getByPlaceholderText('Имя или адрес устройства…')).toBe(search);
    expect(search.value).toBe('Сервер');
    await act(async () => {});
  });

  test('opening a map node switches to pinned nodes and closing it keeps that page open', async () => {
    const { panel, page, update, topic } = setup({ workspace_view: 'map' });
    const viewport = page('map').querySelector('[data-net-viewport]');
    expect(viewport).not.toBeNull();
    fireEvent.click(panel.getByText('Показать информацию об узле'));
    fireEvent.click(within(page('map')).getByText('Закрепить'));
    expect(actions(topic, 'window_open')).toEqual([{ address: node.address }]);
    update({ workspace_view: 'pinned', map: null, selected: null, window: machine,
      windows: [{ address: node.address, title: node.name, type: node.type, online: true }] });
    expect(panel.getByRole('tabpanel', { name: 'Закреплённые узлы' })).toBeTruthy();
    expect(within(page('pinned')).getByText('Состояние закреплённого сервера')).toBeTruthy();
    expect(page('map').querySelector('[data-net-viewport]')).toBe(viewport);
    fireEvent.click(panel.getByTitle(`Закрыть закреплённый узел ${node.name}`));
    expect(actions(topic, 'window_close')).toEqual([{ address: node.address }]);
    update({ workspace_view: 'pinned', window: null, windows: [] });
    expect(panel.getByRole('tabpanel', { name: 'Закреплённые узлы' })).toBeTruthy();
    expect(within(page('pinned')).getByText(/Закреплённых узлов нет/)).toBeTruthy();
    fireEvent.click(panel.getByText('Карта'));
    expect(page('map').querySelector('[data-net-viewport]')).toBe(viewport);
    await act(async () => {});
  });

  test('workspace navigation retains the initialized Pixi surface and pauses hidden rendering', async () => {
    const { panel, update } = setup({ workspace_view: 'map' });
    await act(async () => {});
    const result = jest.mocked(mountNetrunPixi).mock.results.slice(-1)[0];
    expect(result).toBeTruthy();
    const surface = await result.value as MockPixiSurface;
    const element = surface.element;
    expect(panel.container.querySelector('[data-net-pixi]')).toBe(element);
    fireEvent.click(panel.getByRole('tab', { name: 'Файлы' }));
    update({ workspace_view: 'files', map: null, selected: null });
    expect(surface.setSuspended).toHaveBeenLastCalledWith(true);
    expect(surface.destroy).not.toHaveBeenCalled();
    fireEvent.click(panel.getByRole('tab', { name: 'Карта' }));
    expect(surface.setSuspended).toHaveBeenLastCalledWith(false);
    expect(jest.mocked(mountNetrunPixi)).toHaveBeenCalledTimes(1);
    expect(panel.container.querySelector('[data-net-pixi]')).toBe(element);
  });

  test('operation history opens from the map and locates its target without losing the console draft or camera', async () => {
    const peer = { ...node, address: 'TEST:0002', name: 'Реле диагностики', x: 2, y: 2 };
    const map: NetrunData['map'] = { nodes: [node, peer], edges: [{ id: 'peer', from: node.address, to: peer.address, kind: 'endpoint' }],
      gateways: [], focus: node.address, revision: 1 };
    const first: NetOperation = { id: 'command-1', operation_id: 'operation-1', phase: 'queued', kind: 'command',
      label: 'Диагностика реле', from: node.address, to: peer.address, started_at: 10, updated_at: 10, route: [node.address, peer.address] };
    const second: NetOperation = { ...first, id: 'command-2', operation_id: 'operation-2', label: 'Чтение журнала' };
    const { panel, page, update, topic } = setup({ map, operations: [first, second] });
    const cli = panel.getByLabelText('Командная строка') as HTMLInputElement;
    fireEvent.change(cli, { target: { value: 'run "Демон диагностики.exe"' } });
    fireEvent.click(panel.getByRole('tab', { name: 'Карта' }));
    update({ workspace_view: 'map' });
    await act(async () => {});
    const surface = await jest.mocked(mountNetrunPixi).mock.results.slice(-1)[0].value as MockPixiSurface;
    fireEvent.input(panel.getByPlaceholderText('Имя или адрес устройства…'), { target: { value: 'Сервер' } });
    const canvas = surface.element, viewport = page('map').querySelector('[data-net-viewport]');
    const initialCamera = { ...surface.updateCamera.mock.calls.slice(-1)[0][0] };
    const pointer = (target: EventTarget, type: string, clientX: number, clientY: number) => {
      const event = new MouseEvent(type, { bubbles: true, clientX, clientY, button: 0, buttons: type === 'pointercancel' ? 0 : 1 });
      Object.defineProperty(event, 'pointerId', { value: 1 });
      act(() => target.dispatchEvent(event));
    };
    pointer(viewport, 'pointerdown', 100, 100);
    pointer(document, 'pointermove', 160, 140);
    pointer(document, 'pointercancel', 160, 140);
    const camera = { ...surface.updateCamera.mock.calls.slice(-1)[0][0] };
    expect(camera.x).toBe(initialCamera.x + 60);
    expect(camera.y).toBe(initialCamera.y + 40);
    const geometryUploads = surface.updateScene.mock.calls.length;
    const status = panel.container.querySelector<HTMLElement>('[data-net-layout="status"]');
    fireEvent.click(within(status).getByText('Операции (2)'));
    expect(panel.getByRole('tabpanel', { name: 'Терминал' })).toBeTruthy();
    const journal = panel.getByRole('region', { name: 'Журнал сетевых операций' });
    expect(within(journal).getByText(first.label)).toBeTruthy();
    update({ workspace_view: 'terminal', map: null, selected: null,
      operations: [{ ...first, phase: 'completed', updated_at: 12 }, { ...second, phase: 'running' }] });
    expect(within(journal).getByText('Обработано')).toBeTruthy();
    expect(within(journal).getByText('Обрабатывается')).toBeTruthy();
    expect(cli.value).toBe('run "Демон диагностики.exe"');
    expect(surface.setSuspended).toHaveBeenLastCalledWith(true);
    expect(surface.updateScene).toHaveBeenCalledTimes(geometryUploads);
    expect(surface.updateCamera.mock.calls.slice(-1)[0][0]).toEqual(camera);
    const entry = journal.querySelector('[data-net-operation="command-1"]') as HTMLElement;
    fireEvent.click(within(entry).getByText('Показать узел'));
    expect(actions(topic, 'select')).toEqual([{ address: peer.address }]);
    expect(panel.getByRole('tabpanel', { name: 'Карта' })).toBeTruthy();
    expect((panel.getByPlaceholderText('Имя или адрес устройства…') as HTMLInputElement).value).toBe('');
    expect(surface.updateCamera.mock.calls.slice(-1)[0][0]).toEqual(camera);
    update({ workspace_view: 'map', map, selected: peer });
    expect(within(page('map').querySelector<HTMLElement>('[data-net-layout="sidebar"]')).getByText(peer.name)).toBeTruthy();
    expect(page('map').querySelector('[data-net-viewport]')).toBe(viewport);
    expect(panel.container.querySelector('[data-net-pixi]')).toBe(canvas);
    const centeredCamera = surface.updateCamera.mock.calls.slice(-1)[0][0];
    const target = surface.updateScene.mock.calls.slice(-1)[0][0].byAddress.get(peer.address);
    expect(centeredCamera.x + target.px * centeredCamera.zoom).toBeCloseTo(360);
    expect(centeredCamera.y + target.py * centeredCamera.zoom).toBeCloseTo(240);
    expect({ ...centeredCamera }).not.toEqual(camera);
    expect(surface.destroy).not.toHaveBeenCalled();
    fireEvent.click(panel.getByRole('tab', { name: 'Терминал' }));
    fireEvent.click(within(page('terminal')).getByText('Консоль'));
    expect(panel.getByLabelText('Командная строка')).toBe(cli);
    expect(cli.value).toBe('run "Демон диагностики.exe"');
    expect(document.activeElement).toBe(cli);
  });

  test('an active breach has its own page while files and map retain their state', () => {
    const { panel, page, update, topic } = setup({ workspace_view: 'files' });
    fireEvent.click(within(page('files')).getByText('Новый текстовый файл'));
    const editor = page('files').querySelector('textarea');
    fireEvent.change(editor, { target: { value: 'Сохранить после взлома' } });
    update({ workspace_view: 'breach', breach, map: null, selected: null });
    expect(panel.getByRole('tabpanel', { name: 'Взлом' })).toBeTruthy();
    expect(within(page('breach')).getByText(/BREACH TEST/)).toBeTruthy();
    fireEvent.click(panel.getByText('Файлы'));
    expect(editor.value).toBe('Сохранить после взлома');
    expect(page('breach').style.display).toBe('none');
    fireEvent.click(panel.getByText('Взлом'));
    expect(panel.getByRole('tabpanel', { name: 'Взлом' })).toBeTruthy();
    update({ workspace_view: 'breach', breach: null });
    expect(panel.getByRole('tabpanel', { name: 'Файлы' })).toBeTruthy();
    expect(actions(topic, 'workspace_view').slice(-1)[0]).toEqual({ page: 'files' });
    expect(editor.value).toBe('Сохранить после взлома');
  });

  test('incoming ICE casts use the reserved status row without moving tools or stealing focus', () => {
    const { panel, page, update, topic } = setup({ workspace_view: 'files' });
    fireEvent.click(within(page('files')).getByText('Новый текстовый файл'));
    const editor = page('files').querySelector('textarea');
    fireEvent.change(editor, { target: { value: 'Не терять фокус' } });
    const workspace = panel.container.querySelector('[data-net-layout="workspace"]');
    const status = panel.container.querySelector<HTMLElement>('[data-net-layout="status"]');
    const statusHeight = status.style.height;
    const combatTab = panel.getByRole('tab', { name: 'Бой' });
    editor.focus();
    update({ combat: { node: null, node_name: null, self: null, targets: [], programs: [],
      incoming: [{ source: 'ICE-SENTRY', source_ref: 'ice-1', name: 'trace.exe', role: 'trace', power: 6, remaining: 3 }] } });
    expect(panel.getByRole('tabpanel', { name: 'Файлы' })).toBeTruthy();
    expect(panel.getByRole('alert').textContent).toContain('ICE-SENTRY готовит trace.exe');
    expect(panel.container.querySelector('[data-net-layout="status"]')).toBe(status);
    expect(status.style.height).toBe(statusHeight);
    expect(document.activeElement).toBe(editor);
    expect(panel.container.querySelector('[data-net-layout="workspace"]')).toBe(workspace);
    expect(panel.getByRole('tab', { name: 'Бой' })).toBe(combatTab);
    expect(within(combatTab).getByLabelText('Входящих атак: 1')).toBeTruthy();
    expect(editor.value).toBe('Не терять фокус');
    fireEvent.click(panel.getByText('Бой'));
    expect(panel.getByRole('tabpanel', { name: 'Бой' })).toBeTruthy();
    expect(panel.getByRole('alert').textContent).toContain('ICE-SENTRY готовит trace.exe');
    expect(within(page('combat')).queryByText(/ICE-SENTRY готовит trace.exe/)).toBeNull();
    expect(actions(topic, 'workspace_view').slice(-1)[0]).toEqual({ page: 'combat' });
    expect(editor.value).toBe('Не терять фокус');
  });

  test('the active automatic route can be cancelled from any workspace', () => {
    const { panel, topic, update } = setup({ workspace_view: 'files',
      entity: { name: 'Runner', integrity: 100, max_integrity: 100, host: node.address,
        host_name: node.name, diving: true, travel: { target: 'TARGET', remaining: 3 } } });
    expect(panel.getByText('Автопроход к TARGET · осталось переходов: 3')).toBeTruthy();
    fireEvent.click(panel.getByLabelText('Остановить автопроход'));
    expect(actions(topic, 'travel_cancel')).toEqual([{}]);
    update({ entity: { name: 'Runner', integrity: 100, max_integrity: 100, host: node.address,
      host_name: node.name, diving: true, travel: null } });
    expect(panel.queryByLabelText('Остановить автопроход')).toBeNull();
  });

  test('workspace tabs support keyboard activation', () => {
    const { panel, topic } = setup();
    fireEvent.keyDown(panel.getByRole('tab', { name: 'Файлы' }), { key: 'Enter' });
    expect(panel.getByRole('tabpanel', { name: 'Файлы' })).toBeTruthy();
    expect(panel.getByRole('tab', { name: 'Файлы' }).getAttribute('aria-selected')).toBe('true');
    expect(actions(topic, 'workspace_view')).toEqual([{ page: 'files' }]);
  });

  test('terminal chat is a subtab and WEB switches without closing pinned nodes', () => {
    const { panel, page, topic } = setup({
      window: machine, windows: [{ address: node.address, title: node.name, type: node.type, online: true }],
      web: { available: true, sites: [], site: null, page: null },
    });
    fireEvent.click(within(page('terminal')).getByText('#noosphere'));
    expect(within(page('terminal')).getByPlaceholderText('runner в #noosphere')).toBeTruthy();
    fireEvent.click(panel.getByText('WEB'));
    expect(panel.getByRole('tabpanel', { name: 'WEB' })).toBeTruthy();
    expect(actions(topic, 'workspace_view')).toEqual([{ page: 'web' }]);
    expect(actions(topic, 'window_close')).toHaveLength(0);
    fireEvent.click(panel.getByText('Терминал'));
    expect(within(page('terminal')).getByPlaceholderText('runner в #noosphere')).toBeTruthy();
  });
});


test('a tab switch retains the last confirmed route and node panel until map data returns', async () => {
  const selected = { ...node, can_hop: true };
  const renderedMap = { nodes: [selected], edges: [], gateways: [], focus: selected.address,
    revision: 1, route: { route: [selected.address], hops: 0, latency: 0, revision: 1, reachable: true } };
  const entity = { host: 'OTHER', integrity: 80, max_integrity: 100 } as NetrunData['entity'];
  const { panel, page, update } = setup({ workspace_view: 'map', map: renderedMap, selected, entity });
  fireEvent.click(panel.getByText('Показать информацию об узле'));
  expect(within(page('map')).getByText(/Путь: 0 пер/)).toBeTruthy();
  expect(within(page('map')).getByText('Перейти в узел')).toBeTruthy();
  fireEvent.click(panel.getByText('Терминал'));
  update({ workspace_view: 'terminal', map: null, selected: null, entity: null });
  fireEvent.click(panel.getByText('Карта'));
  expect(within(page('map')).getByText(/Путь: 0 пер/)).toBeTruthy();
  const cachedHop = within(page('map')).getByText('Перейти в узел').closest('.Button');
  expect(cachedHop.classList.contains('Button--disabled')).toBe(true);
  update({ workspace_view: 'map', map: { ...renderedMap, route: { ...renderedMap.route, hops: 1, latency: 50 } }, selected, entity });
  expect(within(page('map')).getByText(/Путь: 1 пер/)).toBeTruthy();
  expect(within(page('map')).getByText('Перейти в узел').closest('.Button').classList.contains('Button--disabled')).toBe(false);
  await act(async () => {});
});

test('keyboard navigation moves focus and selection together without changing workspace instances', () => {
  const { panel, page } = setup();
  const filesPage = page('files');
  const terminal = panel.getByRole('tab', { name: 'Терминал' });
  terminal.focus();
  fireEvent.keyDown(terminal, { key: 'ArrowDown' });
  const map = panel.getByRole('tab', { name: 'Карта' });
  expect(document.activeElement).toBe(map);
  expect(map.getAttribute('aria-selected')).toBe('true');
  expect(terminal.tabIndex).toBe(-1);
  fireEvent.keyDown(map, { key: 'ArrowRight' });
  expect(document.activeElement).toBe(panel.getByRole('tab', { name: 'Файлы' }));
  expect(page('files')).toBe(filesPage);
  fireEvent.keyDown(document.activeElement, { key: 'Home' });
  expect(document.activeElement).toBe(terminal);
  expect(panel.getByRole('tabpanel', { name: 'Терминал' })).toBeTruthy();
});

test('a pinned window reappears immediately from the cache then respects authoritative closure', () => {
  const { panel, page, update } = setup({
    workspace_view: 'pinned', window: machine,
    windows: [{ address: node.address, title: node.name, type: node.type, online: true }],
  });
  fireEvent.click(panel.getByText('Терминал'));
  update({ workspace_view: 'terminal', window: null });
  fireEvent.click(panel.getByText('Закреплённые узлы (1)'));
  expect(within(page('pinned')).getByText('Состояние закреплённого сервера')).toBeTruthy();
  update({ workspace_view: 'pinned', window: null, windows: [] });
  expect(within(page('pinned')).queryByText('Состояние закреплённого сервера')).toBeNull();
});

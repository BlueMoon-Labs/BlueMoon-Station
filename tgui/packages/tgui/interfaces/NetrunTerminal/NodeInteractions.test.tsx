import { act, fireEvent, render, within } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../../backend';
import { debugReducer } from '../../debug';
import { NetrunContent } from './Content';
import { NodePanel } from './NodePanel';
import { EntityContact, NetrunData, SelectedNode } from './types';

const contact: EntityContact = {
  ref: 'process-1', name: 'Резидент', kind: 'entity', integrity: 80,
  max_integrity: 100, state: 'Ожидает', self: false, can_signal: true, can_message: true,
};
const node: SelectedNode = {
  address: 'LAN:0001', name: 'Терминал', type: 'terminal', x: 1, y: 1,
  security: 2, online: true, access: 2, legit: 2, entities: 1,
  active: false, uplink: null, network: 'LAN', commands: [], status: [],
  interactions: [{ id: 'dive', name: 'Погрузиться в узел', icon: 'plug', enabled: true }],
  contacts: [contact],
};

const setup = (overrides: Partial<NetrunData> = {}) => {
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'NetrunTerminal' }, data: {
    workspace_view: 'map', origin: 'implant', wireless: true, uplink: true,
    trace: 0, locked: 0, can_breach: false, log: [], jack: null, host_actions: [],
    networks: [], selected: node, selected_network: null,
    map: { gateways: [], nodes: [node], edges: [], revision: 1, focus: node.address },
    storage: { files: [], used: 0, capacity: 6 }, shard: null,
    breach: null, entity: null, combat: null, chat: { handle: 'runner', messages: [] },
    web: null, windows: [], window: null, ...overrides,
  } }));
  return { store, topic };
};

const sent = (topic, action: string) => topic.mock.calls
  .filter((call) => call[0]?.type === `act/${action}`)
  .map((call) => {
    const { _netrun_action: _receipt, ...payload } = JSON.parse(call[0].payload);
    return payload;
  });

describe('Node and process interactions', () => {
  // sendAct keeps its 50 ms duplicate guard across store/window replacements.
  // Separate human interactions explicitly, including clicks that must be denied,
  // so the transport cannot conceal an incorrectly enabled stale control.
  let actionTime = Date.now();
  const nextInteraction = () => {
    actionTime += 1000;
    jest.mocked(Date.now).mockReturnValue(actionTime);
  };
  beforeEach(() => {
    jest.spyOn(Date, 'now');
    nextInteraction();
  });
  afterEach(() => jest.restoreAllMocks());

  test('an authorized non-neighbor uses the shared movement action instead of a disabled direct hop', () => {
    const { topic } = setup({
      origin: 'entity',
      entity: { host: 'SOURCE', integrity: 100, max_integrity: 100 } as NetrunData['entity'],
      selected: { ...node, can_hop: false, movement: { action: 'travel', allowed: true, reason: null } },
    });
    const panel = render(<NodePanel />);
    const button = panel.getByText('Перейти в узел').closest('.Button')!;
    expect(button.classList.contains('Button--disabled')).toBe(false);
    expect(panel.queryByText('Пройти к узлу')).toBeNull();
    fireEvent.click(button);
    expect(sent(topic, 'move')).toEqual([{ address: node.address }]);
    expect(sent(topic, 'hop')).toEqual([]);
  });

  test('movement admission updates after gaining and losing access without reopening the panel', () => {
    const { store, topic } = setup({
      origin: 'entity',
      entity: { host: 'SOURCE', integrity: 100, max_integrity: 100 } as NetrunData['entity'],
      selected: { ...node, access: 0, can_hop: false,
        movement: { action: 'travel', allowed: false, reason: 'Нужен доступ пользователя или право прохода по ЛВС.' } },
    });
    const panel = render(<NodePanel />);
    fireEvent.click(panel.getByText('Перейти в узел'));
    expect(sent(topic, 'move')).toEqual([]);
    act(() => store.dispatch(backendUpdate({ data: { selected: {
      ...node, can_hop: false, movement: { action: 'travel', allowed: true, reason: null },
    } } })));
    fireEvent.click(panel.getByText('Перейти в узел'));
    expect(sent(topic, 'move')).toEqual([{ address: node.address }]);
    act(() => store.dispatch(backendUpdate({ data: { selected: {
      ...node, can_hop: true, movement: { action: 'hop', allowed: false, reason: 'Врата крепости закрыты.' },
    } } })));
    nextInteraction();
    fireEvent.click(panel.getByText('Перейти в узел'));
    expect(sent(topic, 'move')).toHaveLength(1);
  });

  test('a neighboring node also lets the server choose the current movement mode', () => {
    const { store, topic } = setup({
      origin: 'entity',
      entity: { host: 'SOURCE', integrity: 100, max_integrity: 100 } as NetrunData['entity'],
      selected: { ...node, can_hop: true, movement: { action: 'hop', allowed: true, reason: null } },
    });
    const panel = render(<NodePanel />);
    fireEvent.click(panel.getByText('Перейти в узел'));
    expect(sent(topic, 'move')).toEqual([{ address: node.address }]);
    act(() => store.dispatch(backendUpdate({ data: { workspace_view: 'terminal', map: null, selected: null } })));
    nextInteraction();
    fireEvent.click(panel.getByText('Перейти в узел'));
    expect(sent(topic, 'move')).toHaveLength(1);
  });

  test('the selected entry exposes dive and reacts to revoked availability', () => {
    const { store, topic } = setup();
    const panel = render(<NodePanel />);
    fireEvent.click(panel.getByText('Погрузиться в узел'));
    expect(sent(topic, 'node_interact')).toEqual([{ id: 'dive' }]);
    act(() => store.dispatch(backendUpdate({ data: { selected: {
      ...node, interactions: [{ ...node.interactions![0], enabled: false, reason: 'Узел больше не отвечает.' }],
    } } })));
    expect(panel.getByText('Узел больше не отвечает.')).toBeTruthy();
    fireEvent.click(panel.getByText('Погрузиться в узел'));
    expect(sent(topic, 'node_interact')).toHaveLength(1);
  });

  test('a suspended map keeps details visible while disabling entry and contact actions', () => {
    const { store, topic } = setup();
    const panel = render(<NodePanel />);
    act(() => store.dispatch(backendUpdate({ data: { workspace_view: 'terminal', selected: null, map: null } })));
    fireEvent.click(panel.getByText('Погрузиться в узел'));
    fireEvent.click(panel.getByText('Послать сигнал'));
    expect(sent(topic, 'node_interact')).toHaveLength(0);
    expect(sent(topic, 'entity_signal')).toHaveLength(0);
    expect((panel.getByLabelText('Сообщение для Резидент') as HTMLInputElement).disabled).toBe(true);
  });

  test('process cards address signals and messages to a concrete recipient', () => {
    const { topic } = setup();
    const panel = render(<NodePanel />);
    fireEvent.click(panel.getByText('Послать сигнал'));
    const input = panel.getByLabelText('Сообщение для Резидент') as HTMLInputElement;
    fireEvent.change(input, { target: { value: '  Проверка связи  ' } });
    fireEvent.submit(input.closest('form')!);
    expect(sent(topic, 'entity_signal')).toEqual([{ ref: contact.ref }]);
    expect(sent(topic, 'entity_message')).toEqual([{ ref: contact.ref, text: 'Проверка связи' }]);
    expect(input.value).toBe('');
  });

  test('draft messages do not leak across node selection and ICE has no message controls', () => {
    const { store } = setup();
    const panel = render(<NodePanel />);
    fireEvent.change(panel.getByLabelText('Сообщение для Резидент'), { target: { value: 'Первому узлу' } });
    act(() => store.dispatch(backendUpdate({ data: { selected: { ...node, address: 'LAN:0002' } } })));
    expect((panel.getByLabelText('Сообщение для Резидент') as HTMLInputElement).value).toBe('');
    act(() => store.dispatch(backendUpdate({ data: { selected: { ...node, contacts: [{
      ...contact, kind: 'ice', can_signal: false, can_message: false, state: 'Патрулирует',
    }] } } })));
    expect(panel.getByText(/ICE · Патрулирует/)).toBeTruthy();
    expect(panel.queryByText('Послать сигнал')).toBeNull();
    expect(panel.queryByLabelText('Сообщение для Резидент')).toBeNull();
  });

  test('entry selection stays accessible across workspaces and is not duplicated in files', () => {
    const { topic } = setup({ workspace_view: 'files', map: null, origin: 'ai', host_actions: [
      { id: 'choose_entry', name: 'Выбрать узел подключения', icon: 'plug' },
    ] });
    const panel = render(<NetrunContent />);
    const header = within(panel.container.querySelector('header')!);
    expect(header.getByText('ИИ')).toBeTruthy();
    const connections = within(panel.getByRole('group', { name: 'Действия подключения' }));
    fireEvent.click(connections.getByText('Выбрать узел подключения'));
    expect(sent(topic, 'choose_entry')).toEqual([{}]);
    expect(panel.getAllByText('Выбрать узел подключения')).toHaveLength(1);
  });

  test('ICE reconnaissance explains the kind and current risk before entering', () => {
    const { store } = setup({ selected: { ...node, contacts: [{
      ...contact, kind: 'ice', name: 'ICE-HUNTER', ice_kind: 'hunter',
      state: 'патрулирует', can_signal: false, can_message: false,
      threat: 'Опасный вход: ICE атакует ваш процесс.',
    }] } });
    const panel = render(<NodePanel />);
    expect(panel.getByText(/ICE · охотник · патрулирует/)).toBeTruthy();
    expect(panel.getByText('Опасный вход: ICE атакует ваш процесс.')).toBeTruthy();
    act(() => store.dispatch(backendUpdate({ data: { selected: { ...node, contacts: [{
      ...contact, kind: 'ice', name: 'ICE-SENTRY', ice_kind: 'sentry',
      state: 'охраняет узел', can_signal: false, can_message: false,
      threat: 'Доступ ПОЛЬЗОВАТЕЛЯ позволяет пройти.',
    }] } } })));
    expect(panel.getByText(/ICE · сторож · охраняет узел/)).toBeTruthy();
    expect(panel.getByText('Доступ ПОЛЬЗОВАТЕЛЯ позволяет пройти.')).toBeTruthy();
    expect(panel.queryByText('Опасный вход: ICE атакует ваш процесс.')).toBeNull();
    act(() => store.dispatch(backendUpdate({ data: { selected: { ...node, contacts: [{
      ...contact, kind: 'ice', name: 'BLACK ICE', ice_kind: 'black',
      state: 'охраняет узел', can_signal: false, can_message: false,
    }] } } })));
    expect(panel.getByText(/BLACK ICE · нелегальный · охраняет узел/)).toBeTruthy();
    expect(panel.getByRole('img', { name: 'BLACK ICE · нелегальный' }).querySelector('.fa-skull-crossbones')).toBeTruthy();
    expect(panel.getByText(/нейрообратная связь может повредить телу/)).toBeTruthy();
  });
});

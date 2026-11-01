import { act, fireEvent, render, waitFor } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../../backend';
import { debugReducer } from '../../debug';
import { MapFocusRequest, StationMap } from './NetworkMap';
import { mountNetrunPixi } from './pixiSurface';
import { makePixiSurfaceMock } from './testSupport/pixiSurfaceMock';
import { NetrunFeedbackProvider } from './useNetrunBackend';

jest.mock('./pixiSurface', () => ({ mountNetrunPixi: jest.fn() }));
const mount = jest.mocked(mountNetrunPixi);
const source = { address: 'SOURCE', name: 'APC', type: 'apc', x: 0, y: 0, online: true,
  security: 1, access: 2, legit: 2, entities: 0, active: false, uplink: null, commands: [], status: [] };
const peer = { ...source, address: 'PEER', name: 'Сервер', type: 'server', x: 20, access: 0, legit: 0 };
const View = (props: { suspended?: boolean; focusRequest?: MapFocusRequest; onInspect?: () => void } = {}) => <NetrunFeedbackProvider><StationMap suspended={props.suspended} focusRequest={props.focusRequest} onInspect={props.onInspect} /></NetrunFeedbackProvider>;

const setup = (onInspect?: () => void) => {
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'NetrunTerminal' }, data: {
    workspace_view: 'map', origin: 'terminal', uplink: true, wireless: false, locked: 0, trace: 0,
    networks: [], storage: { files: [], used: 0, capacity: 10 }, host_actions: [], windows: [],
    selected: source, selected_network: null, entity: null, jack: null, ping_route: null,
    map: { nodes: [source, peer], edges: [], gateways: [], focus: source.address, revision: 1 },
  } }));
  const panel = render(<View onInspect={onInspect} />);
  const update = (data: object) => {
    act(() => store.dispatch(backendUpdate({ data })));
    panel.rerender(<View onInspect={onInspect} />);
  };
  const selection = () => topic.mock.calls.filter((call) => call[0]?.type === 'act/select')
    .map((call) => JSON.parse(call[0].payload));
  return { panel, store, update, selection };
};
beforeEach(() => { mount.mockImplementation(async (host) => makePixiSurfaceMock(host)); });

test('device cables are visible by default and can be hidden explicitly', async () => {
  const { panel } = setup();
  await waitFor(() => expect(panel.getByLabelText('Карта сети').getAttribute('data-net-runtime')).toBe('ready'));
  const surface = await mount.mock.results[0].value;
  expect(surface.updateActors).toHaveBeenLastCalledWith(expect.anything(), expect.objectContaining({ showEndpointLinks: true }));
  fireEvent.click(panel.getByText('Фильтры'));
  fireEvent.click(panel.getByText('Кабели устройств'));
  expect(surface.updateActors).toHaveBeenLastCalledWith(expect.anything(), expect.objectContaining({ showEndpointLinks: false }));
});

test('keyboard selection gives immediate GPU feedback and only the matching server receipt can reject it', async () => {
  const { panel, store, selection, update } = setup();
  await waitFor(() => expect(panel.getByLabelText('Карта сети').getAttribute('data-net-runtime')).toBe('ready'));
  fireEvent.keyDown(panel.getByLabelText('Карта сети'), { key: 'd' });
  expect(panel.getByText('Выбираем: Сервер…')).toBeTruthy();
  expect(store.getState().backend.data.selected.address).toBe('SOURCE');
  const [request] = selection();
  expect(request.address).toBe('PEER');
  expect(request._netrun_action).toBeTruthy();
  update({ input_ack: 'another-operation' });
  expect(panel.getByText('Выбираем: Сервер…')).toBeTruthy();
  update({ input_ack: request._netrun_action });
  await waitFor(() => expect(panel.getByText('Узел не выбран. Проверьте доступ и связь.')).toBeTruthy());
  const surface = await mount.mock.results[0].value;
  expect(surface.updateActors).toHaveBeenLastCalledWith(expect.anything(),
    expect.objectContaining({ selected: 'SOURCE', selectionPending: false }));
});

test('a confirmed keyboard choice keeps its selection and never claims a rejection', async () => {
  const { panel, selection, update } = setup();
  await waitFor(() => expect(panel.getByLabelText('Карта сети').getAttribute('data-net-runtime')).toBe('ready'));
  fireEvent.keyDown(panel.getByLabelText('Карта сети'), { key: 'd' });
  const [request] = selection();
  update({ input_ack: request._netrun_action, selected: peer });
  await waitFor(() => expect(panel.getByText('Выбран: Сервер')).toBeTruthy());
  expect(panel.queryByText('Узел не выбран. Проверьте доступ и связь.')).toBeNull();
});

test('node information opens after an explicit selection is confirmed without moving the camera', async () => {
  const onInspect = jest.fn();
  const { panel, update, selection } = setup(onInspect);
  await waitFor(() => expect(panel.getByLabelText('Карта сети').getAttribute('data-net-runtime')).toBe('ready'));
  fireEvent.keyDown(panel.getByLabelText('Карта сети'), { key: 'd' });
  expect(onInspect).not.toHaveBeenCalled();
  const [request] = selection();
  update({ input_ack: request._netrun_action, selected: peer });
  await waitFor(() => expect(onInspect).toHaveBeenCalledTimes(1));
  update({ selected: peer, trace: 20 });
  expect(onInspect).toHaveBeenCalledTimes(1);
});

test('a dropped delta hides the map, requests resync, and acknowledges the recovered snapshot', async () => {
  const { panel, update } = setup();
  await waitFor(() => expect(panel.getByLabelText('Карта сети').getAttribute('data-net-runtime')).toBe('ready'));
  const full = { nodes: [source, peer], edges: [], gateways: [], focus: source.address,
    revision: 1, structure_revision: 1, static_revision: 1, state_revision: 10,
    epoch: 'session:one', full: 1 };
  update({ map: full });
  await waitFor(() => expect((global as any).Byond.topic.mock.calls
    .some((call) => call[0]?.type === 'act/map_sync_ack')).toBe(true));

  update({ map: { epoch: 'session:one', full: 0, base_revision: 11, state_revision: 12,
    nodes: [], edges: [], focus: peer.address } });
  expect(panel.getByText(/Синхронизация карты после пропущенного обновления/)).toBeTruthy();
  expect(panel.queryByLabelText('Карта сети')).toBeNull();
  await waitFor(() => expect((global as any).Byond.topic.mock.calls
    .some((call) => call[0]?.type === 'act/map_resync')).toBe(true));

  // The missing update may revoke access: an older full snapshot cannot
  // restore the previously displayed nodes.
  update({ map: full });
  expect(panel.queryByLabelText('Карта сети')).toBeNull();
  update({ map: { ...full, state_revision: 12, focus: peer.address } });
  expect(panel.getByLabelText('Карта сети')).toBeTruthy();
  await waitFor(() => expect((global as any).Byond.topic.mock.calls.filter(
    (call) => call[0]?.type === 'act/map_sync_ack').length).toBeGreaterThanOrEqual(2));
});

test('a consumed focus request is not replayed after graph recovery and a new request can locate the same node again', async () => {
  const { panel, store, selection } = setup();
  await waitFor(() => expect(panel.getByLabelText('Карта сети').getAttribute('data-net-runtime')).toBe('ready'));
  const focusRequest = { address: peer.address, sequence: 1 };
  panel.rerender(<View focusRequest={focusRequest} />);
  expect(selection().map((entry) => entry.address)).toEqual(['PEER']);
  const full = { nodes: [source, peer], edges: [], gateways: [], focus: source.address,
    revision: 1, structure_revision: 1, static_revision: 1, state_revision: 10,
    epoch: 'session:one', full: 1 };
  act(() => store.dispatch(backendUpdate({ data: { map: full, selected: peer } })));
  fireEvent.keyDown(panel.getByLabelText('Карта сети'), { key: 'a' });
  expect(selection().map((entry) => entry.address)).toEqual(['PEER', 'SOURCE']);
  act(() => store.dispatch(backendUpdate({ data: { selected: source, map: {
    epoch: 'session:two', full: 0, base_revision: 10, state_revision: 11, nodes: [], edges: [],
  } } })));
  expect(panel.queryByLabelText('Карта сети')).toBeNull();
  act(() => store.dispatch(backendUpdate({ data: { map: { ...full, epoch: 'session:two', state_revision: 12 } } })));
  await waitFor(() => expect(panel.getByLabelText('Карта сети').getAttribute('data-net-runtime')).toBe('ready'));
  expect(selection().map((entry) => entry.address)).toEqual(['PEER', 'SOURCE']);
  panel.rerender(<View focusRequest={{ address: peer.address, sequence: 2 }} />);
  expect(selection().map((entry) => entry.address)).toEqual(['PEER', 'SOURCE', 'PEER']);
});

test('ping metadata reaches Pixi without extending the same event or suppressing a repeat on the same path', async () => {
  let now = 1000;
  const time = jest.spyOn(performance, 'now').mockImplementation(() => now);
  try {
    const { panel, update } = setup();
    await waitFor(() => expect(panel.getByLabelText('Карта сети').getAttribute('data-net-runtime')).toBe('ready'));
    const surface = await mount.mock.results[0].value;
    const hops = [{ kind: 'node', ref: source.address }, { kind: 'node', ref: peer.address }];
    update({ ping_route: hops, ping: { id: 1, remaining_ms: 6000 } });
    expect(surface.updateActors).toHaveBeenLastCalledWith(expect.anything(),
      expect.objectContaining({ pingRoute: [source.address, peer.address], pingId: 1, pingExpiresAt: 7000 }));
    now = 3000;
    update({ ping_route: hops, ping: { id: 1, remaining_ms: 6000 } });
    expect(surface.updateActors).toHaveBeenLastCalledWith(expect.anything(),
      expect.objectContaining({ pingId: 1, pingExpiresAt: 7000 }));
    now = 4000;
    update({ ping_route: hops, ping: { id: 2, remaining_ms: 6000 } });
    expect(surface.updateActors).toHaveBeenLastCalledWith(expect.anything(),
      expect.objectContaining({ pingId: 2, pingExpiresAt: 10000 }));
    update({ ping_route: null, ping: null });
    expect(surface.updateActors).toHaveBeenLastCalledWith(expect.anything(),
      expect.objectContaining({ pingRoute: [], pingId: undefined, pingExpiresAt: undefined }));
  } finally { time.mockRestore(); }
});

test('a ping received while hidden keeps its original deadline when the map resumes', async () => {
  let now = 1000;
  const time = jest.spyOn(performance, 'now').mockImplementation(() => now);
  try {
    const { panel, store } = setup();
    await waitFor(() => expect(panel.getByLabelText('Карта сети').getAttribute('data-net-runtime')).toBe('ready'));
    const surface = await mount.mock.results[0].value, map = store.getState().backend.data.map;
    panel.rerender(<View suspended />);
    act(() => store.dispatch(backendUpdate({ data: { map: null, ping: { id: 1, remaining_ms: 6000 },
      ping_route: [{ kind: 'node', ref: source.address }, { kind: 'node', ref: peer.address }] } })));
    now = 9000;
    act(() => store.dispatch(backendUpdate({ data: { map } })));
    panel.rerender(<View />);
    expect(surface.updateActors).toHaveBeenLastCalledWith(expect.anything(),
      expect.objectContaining({ pingId: 1, pingExpiresAt: 7000 }));
  } finally { time.mockRestore(); }
});

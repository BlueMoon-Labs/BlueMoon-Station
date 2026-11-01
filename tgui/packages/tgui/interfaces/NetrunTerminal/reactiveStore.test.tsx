import { act, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';
import { memo } from 'react';

import { backendReducer, backendUpdate } from '../../backend';
import { netrunStoreFor } from './reactiveStore';
import { NetrunFeedbackProvider, useNetrunBackend, useNetrunFeedback, useNetrunSelector } from './useNetrunBackend';

const setup = () => {
  (global as any).Byond = { topic: jest.fn(), winset: () => {} };
  const store = createStore(combineReducers({ backend: backendReducer }));
  setGlobalStore(store);
  const initial = { trace: 0, log: [], storage: { files: [], used: 0, capacity: 10 },
    selected: null, host_actions: [], input_ack: null };
  store.dispatch(backendUpdate({ data: initial }));
  return { store, initial, update: (data) => act(() => store.dispatch(backendUpdate({ data }))) };
};

test('server pushes update only subscribed panels, including cloned unchanged payloads', () => {
  const { update, initial } = setup();
  const renders = { storage: 0, log: 0, actions: 0 };
  const Storage = memo(() => {
    const { data } = useNetrunBackend(['storage']); renders.storage++;
    return <span>Файлы: {data.storage.used}</span>;
  });
  const Log = memo(() => {
    const { data } = useNetrunBackend(['log']); renders.log++;
    return <span>{data.log.map((line) => line.text).join(',')}</span>;
  });
  const Actions = memo(() => { useNetrunBackend([]); renders.actions++; return null; });
  const panel = render(<><Storage /><Log /><Actions /></>);
  const before = { ...renders };
  update({ ...initial, log: [{ text: 'Событие сервера', kind: 'label' }], storage: { ...initial.storage, files: [] } });
  expect(panel.getByText('Событие сервера')).toBeTruthy();
  expect(renders).toEqual({ ...before, log: before.log + 1 });
  update({ storage: { files: [], used: 2, capacity: 10 } });
  expect(panel.getByText('Файлы: 2')).toBeTruthy();
  expect(renders.storage).toBe(before.storage + 1);
  expect(renders.log).toBe(before.log + 1);
  expect(renders.actions).toBe(before.actions);
});

test('derived navigation ignores countdown ticks and reacts when the count changes', () => {
  const { update } = setup();
  let renders = 0;
  const Navigation = () => {
    const status = useNetrunSelector((data) => ({ attacks: data.combat?.incoming?.length ?? 0 }));
    renders++;
    return <span>Атаки: {status.attacks}</span>;
  };
  const panel = render(<Navigation />);
  update({ combat: { incoming: [{ remaining: 5 }] } });
  expect(panel.getByText('Атаки: 1')).toBeTruthy();
  const before = renders;
  update({ combat: { incoming: [{ remaining: 4 }] } });
  expect(renders).toBe(before);
  update({ combat: { incoming: [] } });
  expect(panel.getByText('Атаки: 0')).toBeTruthy();
});

test('switching selector fields subscribes to the new state and unmount removes listeners', () => {
  const { store, update } = setup();
  const unsubscriptions: jest.Mock[] = [];
  // Track actual detach calls without replacing the store notification semantics.
  const originalSubscribe = store.subscribe;
  jest.spyOn(store, 'subscribe').mockImplementation((listener) => {
    const detach = jest.fn(originalSubscribe(listener)); unsubscriptions.push(detach); return detach;
  });
  const Probe = ({ field }: { field: 'trace' | 'storage' }) => {
    const { data } = useNetrunBackend([field]);
    return <span>{field === 'trace' ? data.trace : data.storage.used}</span>;
  };
  const panel = render(<Probe field="trace" />);
  panel.rerender(<Probe field="storage" />);
  update({ storage: { files: [], used: 7, capacity: 10 } });
  expect(panel.getByText('7')).toBeTruthy();
  panel.unmount();
  expect(unsubscriptions.length).toBeGreaterThan(0);
  expect(unsubscriptions.every((detach) => detach.mock.calls.length === 1)).toBe(true);
  jest.restoreAllMocks();
});

test('transport packet identity is preserved and adapters are isolated per window', () => {
  const first = setup();
  const adapter = netrunStoreFor(first.store);
  const packet = { epoch: 'first-window', full: false, state_revision: 2, base_revision: 1, nodes: [], edges: [] };
  first.update({ map: packet });
  expect(adapter.read().map).toBe(packet);
  const retry = { ...packet };
  first.update({ map: retry });
  expect(adapter.read().map).toBe(retry);
  const second = setup();
  expect(netrunStoreFor(second.store)).not.toBe(adapter);
  expect(netrunStoreFor(second.store).read().map).toBeUndefined();
});

test('action-only subscribers label commands using the latest server state', () => {
  const { update } = setup();
  let send: () => void;
  const Probe = () => {
    const { act: sendAction } = useNetrunBackend([]);
    const feedback = useNetrunFeedback();
    send = () => sendAction('command', { id: 'door_open' });
    return <span>{feedback?.label}</span>;
  };
  const panel = render(<NetrunFeedbackProvider><Probe /></NetrunFeedbackProvider>);
  update({ selected: { commands: [{ id: 'door_open', name: 'Новая команда' }] } });
  act(() => send());
  expect(panel.getByText('Новая команда')).toBeTruthy();
  const topic = Byond.topic as jest.Mock;
  const request = topic.mock.calls.find(([message]) => message.type === 'act/command')[0];
  expect(JSON.parse(request.payload).id).toBe('door_open');
  expect(typeof JSON.parse(request.payload)._netrun_action).toBe('string');
  panel.unmount();
});

test('an identical map retransmission remains observable to its stream consumer', () => {
  const { update } = setup();
  let deliveries = 0;
  const Probe = () => { useNetrunBackend(['map']); deliveries++; return null; };
  render(<Probe />);
  const packet = { epoch: 'ui:one', full: true, state_revision: 1, nodes: [], edges: [], gateways: [] };
  update({ map: packet });
  const before = deliveries;
  update({ map: { ...packet } });
  expect(deliveries).toBe(before + 1);
});

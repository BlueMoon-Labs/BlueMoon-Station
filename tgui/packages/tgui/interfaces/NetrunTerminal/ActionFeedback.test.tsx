import { act, fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../../backend';
import { debugReducer } from '../../debug';
import { ACTION_FEEDBACK_TIMING } from './actionFeedback';
import { SessionStatus } from './SessionStatus';
import { NetrunData } from './types';
import { NetrunFeedbackProvider, useNetrunBackend } from './useNetrunBackend';

const Probe = () => {
  const { act } = useNetrunBackend();
  return (<>
    <button type="button" onClick={() => act('command', { id: 'door_open' })}>Выполнить команду</button>
    <SessionStatus onCombat={() => {}} onBreach={() => {}} />
          </>);
};

test('click feedback is immediate, correlated with server receipt and preserves the reserved status height', () => {
  jest.useFakeTimers();
  try {
    const topic = jest.fn();
    (global as any).Byond = { winset: () => {}, topic };
    const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
    setGlobalStore(store);
    const data = { locked: 0, breach: null, combat: null, entity: null, window: null, host_actions: [],
      selected: { access: 1, commands: [{ id: 'door_open', name: 'Открыть шлюз' }] } } as NetrunData;
    store.dispatch(backendUpdate({ config: { interface: 'NetrunTerminal' }, data }));
    const panel = render(<NetrunFeedbackProvider><Probe /></NetrunFeedbackProvider>);
    const row = panel.container.querySelector<HTMLElement>('[data-net-layout="status"]');
    const before = row.style.height;
    fireEvent.click(panel.getByText('Выполнить команду'));
    expect(panel.getByRole('status').textContent).toBe('Отправлен запрос: Открыть шлюз');
    const payload = JSON.parse(topic.mock.calls.find((call) => call[0]?.type === 'act/command')[0].payload);
    expect(payload.id).toBe('door_open');
    expect(typeof payload._netrun_action).toBe('string');
    act(() => store.dispatch(backendUpdate({ data: { input_ack: 'another-window' } })));
    panel.rerender(<NetrunFeedbackProvider><Probe /></NetrunFeedbackProvider>);
    expect(panel.getByRole('status').textContent).toContain('Отправлен запрос');
    act(() => store.dispatch(backendUpdate({ data: { input_ack: payload._netrun_action } })));
    panel.rerender(<NetrunFeedbackProvider><Probe /></NetrunFeedbackProvider>);
    expect(panel.getByRole('status').textContent).toBe('Сервер ответил: Открыть шлюз');
    expect(row.style.height).toBe(before);
    expect(store.getState().backend.data.selected.access).toBe(1);
    act(() => jest.advanceTimersByTime(ACTION_FEEDBACK_TIMING.receipt));
    expect(panel.getByRole('status').textContent).not.toContain('Сервер ответил');
    expect(topic.mock.calls.filter((call) => call[0]?.type === 'act/command')).toHaveLength(1);
    panel.unmount();
    expect(jest.getTimerCount()).toBe(0);
  } finally { jest.useRealTimers(); }
});

test('an unrelated operation cannot replace current feedback and a matching denial reports the actual result', () => {
  (global as any).Byond = { winset: () => {}, topic: jest.fn() };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'NetrunTerminal' }, data: {
    locked: 0, breach: null, combat: null, entity: null, window: null, host_actions: [],
    selected: { access: 1, commands: [{ id: 'door_open', name: 'Открыть шлюз' }] },
  } }));
  const panel = render(<NetrunFeedbackProvider><Probe /></NetrunFeedbackProvider>);
  fireEvent.click(panel.getByText('Выполнить команду'));
  const call = (global as any).Byond.topic.mock.calls.find((entry) => entry[0]?.type === 'act/command');
  const nonce = JSON.parse(call[0].payload)._netrun_action;
  const operation = { id: 'packet-1', operation_id: 'operation-1', kind: 'command',
    label: 'Другая команда', from: 'A', to: 'B', phase: 'rejected', reason: 'Нет связи',
    started_at: 1, updated_at: 2, route: ['A', 'B'], nonce: 'another-window' };
  act(() => store.dispatch(backendUpdate({ data: { operations: [operation], input_ack: nonce } })));
  expect(panel.getByRole('status').textContent).toBe('Сервер ответил: Открыть шлюз');
  act(() => store.dispatch(backendUpdate({ data: { operations: [operation,
    { ...operation, id: 'packet-2', label: 'Открыть шлюз', nonce, reason: 'Доступ отозван' }] } })));
  expect(panel.getByRole('status').textContent).toBe('Отклонено: Открыть шлюз · Доступ отозван');
  expect(store.getState().backend.data.selected.access).toBe(1);
  panel.unmount();
});

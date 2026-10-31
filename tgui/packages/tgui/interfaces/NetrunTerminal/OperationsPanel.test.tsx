import { act, fireEvent, render, within } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../../backend';
import { OperationsPanel } from './OperationsPanel';
import { SessionStatus } from './SessionStatus';
import { NetOperation } from './types';

const operation = (id: string, phase: NetOperation['phase']): NetOperation => ({
  id, operation_id: `operation-${id}`, kind: 'command', label: `Команда ${id}`,
  from: 'APC', to: 'DEVICE', phase, started_at: 10, updated_at: 12, route: ['APC', 'RELAY', 'DEVICE'],
});
const setup = (operations: NetOperation[]) => {
  (global as any).Byond = { winset: () => {}, topic: jest.fn() };
  const store = createStore(combineReducers({ backend: backendReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'NetrunTerminal' }, data: { operations, locked: 0 } }));
  const locate = jest.fn(), open = jest.fn();
  const panel = render(<>
    <OperationsPanel onLocate={locate} />
    <SessionStatus onCombat={() => {}} onBreach={() => {}} onOperations={open} />
                       </>);
  const update = (next: NetOperation[], extra = {}) => act(() => store.dispatch(backendUpdate({ data: { operations: next, ...extra } })));
  return { panel, update, locate, open };
};

test('independent delivery outcomes survive later actions and receipt never completes a queued operation', () => {
  const first = operation('1', 'queued'), second = operation('2', 'queued');
  const { panel, update } = setup([first, second]);
  update([first, second], { input_ack: 'receipt' });
  expect(panel.getAllByText('Ожидает доставки')).toHaveLength(2);
  update([{ ...first, phase: 'completed' }, second]);
  expect(panel.getByText('Обработано')).toBeTruthy();
  expect(panel.getAllByText('Ожидает доставки')).toHaveLength(1);
  expect(panel.getByText('Операции (1)')).toBeTruthy();
});

test('completed requests expose and search the actual device response as plain text', () => {
  const { panel } = setup([{ ...operation('response', 'completed'), result: '<packet>Температура: 293 K</packet>' }]);
  expect(panel.getByText('<packet>Температура: 293 K</packet>')).toBeTruthy();
  expect(panel.container.querySelector('packet')).toBeNull();
  fireEvent.change(panel.getByLabelText('Поиск операций'), { target: { value: '293 K' } });
  expect(panel.getByText('Команда response')).toBeTruthy();
});

test('the status row presents the server outcome and reason after delivery instead of inferring success from receipt', () => {
  const first = operation('1', 'queued');
  const { panel, update } = setup([first]);
  expect(panel.getByRole('status').textContent).toBe('Ожидает доставки: Команда 1');
  update([{ ...first, phase: 'rejected', reason: 'Доступ отозван' }]);
  expect(panel.getByRole('status').textContent).toBe('Отклонено: Команда 1 · Доступ отозван');
});

test('operation filters retain focus and reveal structured route and denial without replaying a command', () => {
  const rejected = { ...operation('3', 'rejected'), reason: 'Маршрут разорван', updated_at: 15 };
  const { panel, update, locate } = setup([operation('1', 'completed'), operation('2', 'queued'), rejected]);
  fireEvent.click(panel.getByText('Отказы'));
  expect(panel.queryByText('Команда 1')).toBeNull();
  const search = panel.getByLabelText('Поиск операций');
  search.focus();
  fireEvent.change(search, { target: { value: 'разорван' } });
  update([operation('1', 'completed'), { ...rejected, updated_at: 16 }]);
  expect(document.activeElement).toBe(search);
  expect((search as HTMLInputElement).value).toBe('разорван');
  const entry = panel.container.querySelector('[data-net-operation="3"]') as HTMLElement;
  expect(within(entry).getByText('APC → RELAY → DEVICE')).toBeTruthy();
  expect(within(entry).getByText('600 мс')).toBeTruthy();
  fireEvent.click(within(entry).getByText('Показать узел'));
  expect(locate).toHaveBeenCalledWith('DEVICE');
  expect((global as any).Byond.topic).not.toHaveBeenCalled();
});

test('the reserved status row opens history and reflects live operations without changing its height', () => {
  const { panel, update, open } = setup([operation('1', 'running')]);
  const row = panel.container.querySelector<HTMLElement>('[data-net-layout="status"]');
  const height = row.style.height;
  fireEvent.click(panel.getByText('Операции (1)'));
  expect(open).toHaveBeenCalledTimes(1);
  update([operation('1', 'completed')]);
  expect(panel.getByText('Операции')).toBeTruthy();
  expect(row.style.height).toBe(height);
});

test('service lookup and expanded delivery details survive other operation updates', () => {
  const current = { ...operation('1', 'queued'), service: 'science.sync' };
  const { panel, update } = setup([current]);
  const journal = panel.getByRole('region', { name: 'Журнал сетевых операций' });
  const search = within(journal).getByLabelText('Поиск операций');
  fireEvent.change(search, { target: { value: 'SCIENCE.SYNC' } });
  const entry = journal.querySelector<HTMLDetailsElement>('[data-net-operation="1"]');
  expect(entry).not.toBeNull();
  fireEvent.click(entry.querySelector('summary'));
  expect(entry.open).toBe(true);
  update([{ ...current, phase: 'completed' }, operation('2', 'queued')]);
  expect(journal.querySelector('[data-net-operation="1"]')).toBe(entry);
  expect(entry.open).toBe(true);
  expect(within(entry).getByText('Обработано')).toBeTruthy();
  expect(within(entry).getByText('science.sync')).toBeTruthy();
  expect(within(journal).getByText('Все').closest('.Button').getAttribute('aria-pressed')).toBe('true');
});

import { act, fireEvent, render, within } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../../backend';
import { SecurityPanel } from './SecurityPanel';
import { SecurityEvidence, SecurityState } from './types';

const evidence: SecurityEvidence = { id: 'evidence-1', kind: 'breach', age: 12, ttl: 0, attributed: false,
  active: true, status: 'Идёт подбор доступа.', trace_allowed: true, map_allowed: false, pursue_allowed: false,
  map_reason: 'Источник ещё не установлен.', pursue_reason: 'Контакт ещё не установлен.' };
const defended = { address: 'SEC:0042', name: 'Сервер охраны', can_countertrace: true };
const setup = (entries: SecurityEvidence[], allowed = true) => {
  const topic = jest.fn(); (global as any).Byond = { topic, winset: () => {} };
  const store = createStore(combineReducers({ backend: backendReducer })); setGlobalStore(store);
  store.dispatch(backendUpdate({ data: { security: { defended: { ...defended, can_countertrace: allowed, reason: allowed ? null : 'Нужен доступ ROOT.' }, entries } } }));
  const panel = render(<SecurityPanel />);
  const sent = (action: string) => topic.mock.calls.filter(([message]) => message.type === `act/${action}`).map(([message]) => JSON.parse(message.payload));
  const update = (security: SecurityState) => act(() => store.dispatch(backendUpdate({ data: { security } })));
  return { panel, sent, update };
};

test('unknown evidence can be traced at ttl zero while its private name and location remain hidden', () => {
  const { panel, sent } = setup([{ ...evidence, name: 'Скрытая личность', source_address: 'PRIVATE:1234', source_name: 'Скрытый узел' }]);
  expect(panel.getByText('Неизвестный источник')).toBeTruthy();
  expect(panel.getByText('Попытка взлома · 12 с назад')).toBeTruthy();
  expect(panel.queryByText(/Скрытая личность|PRIVATE:1234|Скрытый узел/)).toBeNull();
  expect(panel.getByText(evidence.map_reason)).toBeTruthy();
  fireEvent.click(panel.getByText('Контртрассировка'));
  fireEvent.click(panel.getByText('Узел на карте'));
  fireEvent.click(panel.getByText('Преследовать'));
  expect(sent('security_trace')).toEqual([{ id: 'evidence-1' }]);
  expect(sent('security_map')).toHaveLength(0);
  expect(sent('security_pursue')).toHaveLength(0);
});

test('countermeasures address only the server evidence ID and expired attribution immediately removes old details', () => {
  const known = { ...evidence, attributed: true, name: 'Раннер', source_address: 'ENG:0012', source_name: 'Интерком', ttl: 38,
    map_allowed: true, map_reason: null, pursue_allowed: true, pursue_reason: null };
  const { panel, sent, update } = setup([known]);
  const entry = panel.container.querySelector('[data-net-evidence="evidence-1"]');
  expect(panel.getByText(/контакт ещё 38 с/)).toBeTruthy();
  fireEvent.click(panel.getByText('Обновить контртрассировку'));
  expect(sent('security_probe')).toEqual([{}]);
  fireEvent.click(panel.getByText('Узел на карте')); fireEvent.click(panel.getByText('Преследовать'));
  expect(sent('security_map')).toEqual([{ id: 'evidence-1' }]);
  expect(sent('security_pursue')).toEqual([{ id: 'evidence-1' }]);
  update({ defended, entries: [{ ...evidence, age: 50, trace_allowed: false, trace_reason: 'След недоступен.' }] });
  expect(panel.container.querySelector('[data-net-evidence="evidence-1"]')).toBe(entry);
  expect(panel.queryByText(/Раннер|ENG:0012|Интерком/)).toBeNull();
  expect(panel.getByText('След недоступен.')).toBeTruthy();
});

test('an empty defense offers the ordinary countertrace request with its denial reason', () => {
  const { panel, sent, update } = setup([], false);
  expect(panel.getByText('Нужен доступ ROOT.')).toBeTruthy();
  fireEvent.click(panel.getByText('Проверить следы')); expect(sent('security_probe')).toHaveLength(0);
  update({ defended, entries: [] });
  fireEvent.click(panel.getByText('Проверить следы')); expect(sent('security_probe')).toEqual([{}]);
  update({ defended, entries: Array.from({ length: 20 }, (_, i) => ({ ...evidence, id: `record-${i}`, kind: 'custom' })) });
  expect(panel.container.querySelectorAll('[data-net-evidence]')).toHaveLength(16);
  expect(within(panel.container.querySelector('[data-net-evidence="record-0"]')).getByText(/Подозрительная активность/)).toBeTruthy();
});

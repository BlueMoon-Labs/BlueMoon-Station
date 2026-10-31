import { act, fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../../backend';
import { debugReducer } from '../../debug';
import { NetrunContent } from './Content';

test('neural implant prepares a local entrance without showing network controls', () => {
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'NetrunTerminal' }, data: {
    origin: 'implant', ui_theme: 'ion', networks: [], windows: [],
    storage: { files: [], used: 0, capacity: 6 }, shard: null, file: null,
    selected: null, log: [], host_actions: [{ id: 'choose_entry', name: 'Выбрать узел погружения', icon: 'plug' }],
  } }));
  const panel = render(<NetrunContent />);
  expect(panel.getByText(/Выберите узел в своей зоне/)).toBeTruthy();
  expect(panel.getByText('Узел погружения не выбран.')).toBeTruthy();
  expect(panel.getByText(/^Локальные файлы/)).toBeTruthy();
  expect(panel.queryByRole('tab', { name: 'Карта' })).toBeNull();
  expect(panel.queryByText('#noosphere')).toBeNull();
  fireEvent.click(panel.getByText('Выбрать узел погружения'));
  expect(topic.mock.calls.some((call) => call[0]?.type === 'act/choose_entry')).toBe(true);
  act(() => store.dispatch(backendUpdate({ data: { selected: {
    name: 'Терминал', address: 'LAN:0001', interactions: [
      { id: 'dive', name: 'Погрузиться в узел', icon: 'plug', enabled: true },
    ],
  } } })));
  expect(panel.getByText('Узел погружения: Терминал')).toBeTruthy();
  fireEvent.click(panel.getByText('Погрузиться в узел'));
  expect(topic.mock.calls.some((call) => call[0]?.type === 'act/node_interact'
    && JSON.parse(call[0].payload).id === 'dive')).toBe(true);
  act(() => store.dispatch(backendUpdate({ data: { selected: {
    name: 'Терминал', address: 'LAN:0001', interactions: [
      { id: 'dive', name: 'Погрузиться в узел', icon: 'plug', enabled: false, reason: 'Узел вне вашего отсека.' },
    ],
  } } })));
  expect(panel.getByText('Узел вне вашего отсека.')).toBeTruthy();
  fireEvent.click(panel.getByText('Погрузиться в узел'));
  expect(topic.mock.calls.filter((call) => call[0]?.type === 'act/node_interact')).toHaveLength(1);
});

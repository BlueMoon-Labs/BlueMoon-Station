import { act, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { NetrunMonitor, NetrunMonitorData } from './NetrunMonitor';

const fixture: NetrunMonitorData = {
  status: {
    mode: 'external',
    state: 'ready',
    ready: 1,
    health: 'ok',
    label: 'Библиотека работает',
    detail: 'Ожидающих операций нет.',
    last_error: null,
    telemetry_supported: 1,
    telemetry_age_s: 0,
    binding: 'monitor-fixture',
  },
  sections: [{
    title: 'Очереди DM',
    rows: [
      { label: 'Ожидает', value: 0, unit: 'шт.' },
      { label: 'Native worker активен', value: false },
      { label: 'CPU Host', value: null, unit: 'мс' },
    ],
  }],
  history: [],
};

const setup = (overrides: Partial<NetrunMonitorData> = {}) => {
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({
    config: { interface: 'NetrunMonitor' },
    data: { ...fixture, ...overrides },
  }));
  return { ...render(<NetrunMonitor />), store, topic };
};

test('отличает нулевую очередь и false от отсутствующего измерения', () => {
  const ui = setup();
  expect(ui.getByText('Библиотека работает')).toBeTruthy();
  expect(ui.getByText('Получена 0 с назад')).toBeTruthy();
  expect(ui.getByText('0 шт.')).toBeTruthy();
  expect(ui.getByText('— мс')).toBeTruthy();
  expect(ui.getByText('Native worker активен:').parentElement.textContent).toContain('нет');
  expect(ui.getAllByText('Для графика нужны два снимка.')).toHaveLength(2);
});

test('новый снимок показывает stale и свежесть отдельно от готовности Core', () => {
  const ui = setup();
  const updatedStatus = {
    ...fixture.status,
    health: 'stale' as const,
    label: 'Нет прогресса обработки',
    detail: 'Есть ожидающие операции.',
    telemetry_age_s: 17,
    last_error: 'fixture-error<script>',
  };
  act(() => ui.store.dispatch(backendUpdate({ data: {
    ...fixture,
    status: updatedStatus,
    sections: [{ title: 'Очереди DM', rows: [{ label: 'Ожидает', value: 23 }] }],
  } })));
  ui.rerender(<NetrunMonitor />);
  expect(ui.getByText('Нет прогресса обработки')).toBeTruthy();
  expect(ui.getByText('Получена 17 с назад')).toBeTruthy();
  expect(ui.getByText('Готова к работе:').parentElement.textContent).toContain('да');
  expect(ui.getByText('23')).toBeTruthy();
  expect(ui.getByText('fixture-error<script>')).toBeTruthy();
  expect(ui.container.querySelector('script')).toBeNull();
  expect(ui.topic.mock.calls.some(([message]) => message.type?.startsWith('act/'))).toBe(false);
});

test('отключённая библиотека не выдаёт отсутствие телеметрии за нулевое время', () => {
  const ui = setup({
    status: {
      ...fixture.status,
      state: 'closed',
      ready: 0,
      health: 'offline',
      label: 'Библиотека отключена',
      telemetry_supported: 0,
      telemetry_age_s: null,
      binding: null,
    },
    sections: [],
  });
  expect(ui.getByText('Телеметрия не согласована с Host')).toBeTruthy();
  expect(ui.queryByText('Получена 0 с назад')).toBeNull();
  expect(ui.getByText('Готова к работе:').parentElement.textContent).toContain('нет');
  expect(ui.getByText('—')).toBeTruthy();
});

test('нулевая история рисует конечные координаты без изменения серверного снимка', () => {
  const sample = {
    time: 100, tx_kib_s: 0, rx_kib_s: 0, input_frames: 0,
    pending: 0, ack_ms: null, host_ms: null,
  };
  const history = [{ ...sample }, { ...sample, time: 102 }];
  const original = JSON.stringify(history);
  const ui = setup({ history });
  const lines = ui.container.querySelectorAll('polyline');
  expect(lines).toHaveLength(4);
  for (const line of Array.from(lines)) {
    expect(line.getAttribute('points')).not.toMatch(/NaN|Infinity/);
  }
  expect(JSON.stringify(history)).toBe(original);
});

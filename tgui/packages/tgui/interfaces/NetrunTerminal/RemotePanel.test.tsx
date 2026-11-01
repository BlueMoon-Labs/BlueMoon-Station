import { fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../../backend';
import { debugReducer } from '../../debug';
import { RemotePanel } from './RemotePanel';
import { MachineWindow } from './types';

type Remote = NonNullable<MachineWindow['remote']>;
const pressure: Remote['actions'][number] = { id: 'pressure', name: 'Установить давление',
  access: 2, allowed: true, params: [{ id: 'pressure', name: 'Давление, кПа', type: 'number', min: 0, max: 100, value: 50 }] };

const setup = (actions: Remote['actions'] = [pressure], interfaceName = 'GasPump', data: Remote['data'] = { pressure: 50 }) => {
  const topic = jest.fn();
  (global as any).Byond = { topic, winset: () => {} };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'NetrunTerminal' }, data: {} }));
  const remote: Remote = { interface: interfaceName, data, actions };
  return { ...render(<RemotePanel address="PUMP" remote={remote} />), topic, remote };
};
const sent = (topic) => topic.mock.calls.filter((call) => call[0]?.type === 'act/remote_act')
  .map((call) => JSON.parse(call[0].payload));

test('numeric requests reject invalid and out-of-range values before delivery', () => {
  const panel = setup();
  const field = panel.getByLabelText('Давление, кПа');
  for (const value of ['', 'abc', 'Infinity', '1e999', '0x10', '-1', '101']) {
    fireEvent.change(field, { target: { value } });
    fireEvent.click(panel.getByText(pressure.name));
    expect(sent(panel.topic)).toEqual([]);
    expect(panel.getByRole('status')).toBeTruthy();
  }
  fireEvent.change(field, { target: { value: '0' } });
  fireEvent.click(panel.getByText(pressure.name));
  expect(sent(panel.topic)).toEqual([{ address: 'PUMP', request: 'pressure', arguments: { pressure: 0 } }]);
});

test('native research offers named affordable technologies and sends their real id', () => {
  const action: Remote['actions'][number] = { id: 'researchNode', name: 'Исследовать технологию', access: 2, allowed: true,
    params: [{ id: 'node_id', name: 'Код технологии', type: 'text' }] };
  const panel = setup([action], 'Techweb', { researchable: true, locked: false,
    points: { Generic: 6000 }, static_data: { id_cache: ['datatheory', 'comptech', 'future'],
      node_cache: { '1': { name: 'Теория данных' }, '2': { name: 'Компьютерные консоли' }, '3': { name: 'Будущая технология' } } },
    nodes: [{ id: 'datatheory', tier: 0, can_unlock: true }, { id: 'comptech', tier: 1, can_unlock: true, costs: { Generic: 2000 } },
      { id: 'future', tier: 2, can_unlock: true }] });
  const menu = panel.getByLabelText('Код технологии') as HTMLSelectElement;
  expect(menu.tagName).toBe('SELECT');
  expect(panel.getByRole('option', { name: /Компьютерные консоли/ })).toBeTruthy();
  expect(panel.queryByRole('option', { name: /Теория данных|Будущая технология/ })).toBeNull();
  fireEvent.change(menu, { target: { value: 'comptech' } });
  fireEvent.click(panel.getByText(action.name));
  expect(sent(panel.topic)).toEqual([{ address: 'PUMP', request: 'researchNode', arguments: { node_id: 'comptech' } }]);
  expect(action.params?.[0].options).toBeUndefined();
});

test('native vending selects stocked products by name without exposing hidden inventory', () => {
  const panel = setup([{ id: 'vend', name: 'Выдать товар', allowed: true, access: 2,
    params: [{ id: 'ref', name: 'Товар', type: 'text' }] }], 'Vending', {
    product_records: [{ ref: 'drink-ref', name: 'Газировка', price: 15 }, { ref: 'empty-ref', name: 'Пустая ячейка', price: 10 }],
    hidden_records: [{ ref: 'hidden-ref', name: 'Скрытый товар', price: 0 }], stock: { 'drink-ref': 3, 'empty-ref': 0, 'hidden-ref': 5 } });
  const menu = panel.getByLabelText('Товар') as HTMLSelectElement;
  expect(menu.tagName).toBe('SELECT');
  expect(panel.getByRole('option', { name: /Газировка.*15/ })).toBeTruthy();
  expect(panel.queryByRole('option', { name: /Пустая ячейка|Скрытый товар/ })).toBeNull();
  fireEvent.change(menu, { target: { value: 'drink-ref' } });
  fireEvent.click(panel.getByText('Выдать товар'));
  expect(sent(panel.topic)).toEqual([{ address: 'PUMP', request: 'vend', arguments: { ref: 'drink-ref' } }]);
});

test('native fabrication uses delivered blueprints and revokes vanished selections', () => {
  const action: Remote['actions'][number] = { id: 'build', name: 'Изготовить', allowed: true, access: 2, params: [
    { id: 'id', name: 'Чертёж', type: 'text' }, { id: 'amount', name: 'Количество', type: 'number', min: 1, max: 60 },
] };
  const panel = setup([action], 'Fabricator', { categories: [{ name: 'Детали', items: [{ id: 'micro_mani', name: 'Манипулятор' }] }],
    maxBuildButtonAmount: 5, busy: false });
  const menu = panel.getByLabelText('Чертёж') as HTMLSelectElement;
  expect(menu.tagName).toBe('SELECT');
  fireEvent.change(menu, { target: { value: 'micro_mani' } });
  fireEvent.change(panel.getByLabelText('Количество'), { target: { value: '6' } });
  fireEvent.click(panel.getByText('Изготовить'));
  expect(sent(panel.topic)).toHaveLength(0);
  fireEvent.change(panel.getByLabelText('Количество'), { target: { value: '2' } });
  fireEvent.click(panel.getByText('Изготовить'));
  expect(sent(panel.topic)[0].arguments).toEqual({ id: 'micro_mani', amount: 2 });
  panel.rerender(<RemotePanel address="PUMP" remote={{ ...panel.remote, data: { ...panel.remote.data, categories: [] } }} />);
  fireEvent.click(panel.getByText('Изготовить'));
  expect(sent(panel.topic)).toHaveLength(1);
});

test('native pump readings show physical units rather than a raw property tree', () => {
  const panel = setup([], 'AtmosPump', { on: true, rate: 50, max_rate: 200, line_pressure: 123.5 });
  expect(panel.getByText('50 л/с')).toBeTruthy();
  expect(panel.getByText('123.5 кПа')).toBeTruthy();
});

test('native turret reports the actual head exemption setting', () => {
  const panel = setup([], 'PortableTurret', { on: true, locked: false, ignore_heads: true });
  const label = panel.getByText('Исключение глав:');
  expect(label.parentElement?.textContent).toBe('Исключение глав:Включено');
});

test('native DM zero research-control flag disables research requests', () => {
  const panel = setup([{ id: 'researchNode', name: 'Исследовать технологию', access: 2, allowed: true,
    params: [{ id: 'node_id', name: 'Код технологии', type: 'text' }] }], 'Techweb', {
    researchable: 0, locked: 0, nodes: [{ id: 'comptech', tier: 1, can_unlock: 1 }],
  });
  fireEvent.change(panel.getByLabelText('Код технологии'), { target: { value: 'comptech' } });
  fireEvent.click(panel.getByText('Исследовать технологию'));
  expect(sent(panel.topic)).toEqual([]);
});

test('Russian decimal input sends a number and live polling retains the draft', () => {
  const panel = setup();
  const field = panel.getByLabelText('Давление, кПа') as HTMLInputElement;
  fireEvent.change(field, { target: { value: '42,5' } });
  panel.rerender(<RemotePanel address="PUMP" remote={{ ...panel.remote,
    actions: [{ ...pressure, params: [{ ...pressure.params[0], value: 20 }] }] }} />);
  expect(field.value).toBe('42,5');
  fireEvent.click(panel.getByText(pressure.name));
  expect(sent(panel.topic)).toEqual([{ address: 'PUMP', request: 'pressure', arguments: { pressure: 42.5 } }]);
});

test('provider rejection is visible and disables the actual parameter input', () => {
  const reason = 'Панель заблокирована.';
  const panel = setup([{ ...pressure, allowed: false, reason }]);
  expect(panel.getByRole('status').textContent).toBe(reason);
  expect((panel.getByLabelText('Давление, кПа') as HTMLInputElement).disabled).toBe(true);
  fireEvent.click(panel.getByText(pressure.name));
  expect(sent(panel.topic)).toEqual([]);
});

test('switching to another endpoint does not reuse its previous numeric draft', () => {
  const panel = setup();
  fireEvent.change(panel.getByLabelText('Давление, кПа'), { target: { value: '88' } });
  panel.rerender(<RemotePanel address="OTHER-PUMP" remote={panel.remote} />);
  expect((panel.getByLabelText('Давление, кПа') as HTMLInputElement).value).toBe('50');
});

test('module menus show names and reject a selection removed by a live suit update', () => {
  const moduleAction: Remote['actions'][number] = { id: 'select_module', name: 'Переключить модуль', access: 2, allowed: true,
    params: [{ id: 'module', name: 'Модуль', type: 'text', value: 'light-ref', options: [
      { value: 'light-ref', name: 'Фонарь' }, { value: 'visor-ref', name: 'Визор' },
    ] }] };
  const panel = setup([moduleAction]);
  const menu = panel.getByLabelText('Модуль') as HTMLSelectElement;
  expect(menu.tagName).toBe('SELECT'); expect(menu.value).toBe('light-ref');
  fireEvent.change(menu, { target: { value: 'visor-ref' } });
  fireEvent.click(panel.getByText('Переключить модуль'));
  expect(sent(panel.topic)).toEqual([{ address: 'PUMP', request: 'select_module', arguments: { module: 'visor-ref' } }]);
  panel.rerender(<RemotePanel address="PUMP" remote={{ ...panel.remote, actions: [{ ...moduleAction,
    params: [{ ...moduleAction.params[0], options: [{ value: 'light-ref', name: 'Фонарь' }] }],
  }] }} />);
  expect(menu.value).toBe('');
  fireEvent.click(panel.getByText('Переключить модуль'));
  expect(sent(panel.topic)).toHaveLength(1);
  expect(panel.getByRole('status').textContent).toContain('выберите доступный вариант');
});

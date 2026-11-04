import { fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { PowerExportNodeContent, PowerExportNodeData } from './PowerExportNode';

const base: PowerExportNodeData = {
  active: 1,
  connected: 1,
  panel_open: 0,
  on_station: 1,
  target_kw: 1000,
  max_kw: 2000,
  step_kw: 50,
  station_cap_kw: 3000,
  export_w: 400000,
  surplus_w: 420000,
  base_price_per_mj: 3,
  market_percent: 150,
  price_per_mj: 4.5,
  income_per_minute: 108,
  payout_minutes: 1,
  payout_bulk: 500,
};

const setup = (data: Partial<PowerExportNodeData> = {}) => {
  let now = Date.now();
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'PowerExportNode' }, data: { ...base, ...data } }));
  return { ...render(<PowerExportNodeContent />), topic };
};

const sent = (topic, action) =>
  topic.mock.calls
    .map(([message]) => message)
    .filter((message) => message.type === `act/${action}`)
    .map((message) => (message.payload ? JSON.parse(message.payload) : {}));

const text = (container: HTMLElement) => (container.textContent || '').replace(/\u00a0/g, ' ');

const buttonWithIcon = (container: HTMLElement, icon: string) =>
  container.querySelector(`.fa-${icon}`)?.closest('.Button') as HTMLElement;

test('кнопки шлют toggle и set_draw с мощностью в кВт', () => {
  const { getByText, container, topic } = setup();
  fireEvent.click(getByText('Включён'));
  fireEvent.click(buttonWithIcon(container, 'minus'));
  fireEvent.click(buttonWithIcon(container, 'plus'));
  fireEvent.click(getByText('По излишку'));
  fireEvent.click(getByText('Максимум'));
  expect(sent(topic, 'toggle')).toHaveLength(1);
  expect(sent(topic, 'set_draw')).toEqual([{ kw: 950 }, { kw: 1050 }, { kw: 400 }, { kw: 2000 }]);
});

test('цена с рыночным фактором, потолок станции и доход объяснены', () => {
  const { container } = setup();
  expect(text(container)).toContain('4.50 кр. за МДж (3.00 кр. × рынок энергии 150%)');
  expect(text(container)).toContain('не больше 3000 кВт со всех узлов');
  expect(text(container)).toContain('~108 кр. в минуту');
  expect(text(container)).toContain('не реже раза в 1 мин., а при сумме от 500 кр. - сразу.');
});

test('«Сеть не тянет», когда заданная мощность выше излишка', () => {
  const over = setup();
  expect(text(over.container)).toContain('Сеть не тянет');
  over.unmount();
  const fits = setup({ target_kw: 400 });
  expect(text(fits.container)).not.toContain('Сеть не тянет');
});

test('без кабеля и с открытой панелью - предупреждения', () => {
  const { container } = setup({ connected: 0, panel_open: 1, active: 0 });
  expect(text(container)).toContain('Под узлом нет кабеля');
  expect(text(container)).toContain('Панель открыта: продажа остановлена.');
  expect(text(container)).toContain('Выключен');
  expect(text(container)).not.toContain('вне станции');
});

test('вне станции узел предупреждает, что не продаёт', () => {
  const { container } = setup({ on_station: 0 });
  expect(text(container)).toContain('Узел стоит вне станции');
});

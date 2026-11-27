import { fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { CargoExpress } from './CargoExpress';

jest.mock('common/storage', () => ({ storage: { get: jest.fn(() => Promise.resolve(undefined)), set: jest.fn(() => Promise.resolve()) } }));

const base = {
  locked: 0,
  access_hint: 'ID квартирмейстера',
  points: 5000,
  budget_name: 'бюджет снабжения',
  self_paid: 0,
  usingBeacon: 0,
  hasBeacon: 0,
  beaconzone: '',
  beaconName: 'Нет',
  printMsg: 'Напечатать маяк за 500 кр.',
  canBuyBeacon: 1,
  beacon_only: 0,
  message: '',
  help_topics: [{ title: 'Экспресс-заказ', lines: ['Экспресс-заказ списывает цену пака у партнёра сразу.'] }],
  supplies: {},
};

const setup = (data = {}) => {
  let now = Date.now();
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'CargoExpress' }, data: { ...base, ...data } }));
  return { ...render(<CargoExpress />), topic };
};

const sent = (topic: jest.Mock, action: string) =>
  topic.mock.calls.map(([message]) => message).filter((message) => message.type === `act/${action}`);

/** Весь текст окна вместе с пояснениями, свёрнутыми под "?". */
const text = (container: HTMLElement) => {
  container.querySelectorAll('.NtTerm__helpToggle:not(.NtTerm__helpToggle--open)').forEach((toggle) => fireEvent.click(toggle));
  return (container.textContent || '').replace(/\u00a0/g, ' ');
};

describe('CargoExpress', () => {
  test('бюджет и плательщик берутся из данных', () => {
    const content = text(setup().container);
    expect(content).toContain('бюджет снабжения5 000 кр.');
    expect(content).toContain('бюджет снабжения, сразу при заказе');
    expect(content).toContain('Напечатать маяк за 500 кр.');
    expect(content).toContain('Экспресс-заказ списывает цену пака у партнёра сразу.');
    expect(content).not.toContain('credits');
  });

  test('печать маяка шлёт printBeacon', () => {
    const ui = setup();
    fireEvent.click(ui.getByText('Напечатать маяк за 500 кр.'));
    expect(sent(ui.topic, 'printBeacon')).toHaveLength(1);
  });

  test('частный заказ платит личный счёт карты', () => {
    expect(text(setup({ self_paid: 1 }).container)).toContain('личный счёт карты, сразу при заказе');
  });

  const outpost = {
    contracts: [
      {
        uid: 7,
        kind: 'outpost',
        department: 'TAR',
        department_name: 'бюджет Тарков Индастриз',
        title: 'Pie',
        desc: 'Ship a whole one.',
        reward: 1571,
        share: 25,
        urgent: 0,
        time_left: null,
        taken_by: null,
        taker_id: null,
        takeable: 0,
        special: 0,
        rotates_in: 600,
        started: 0,
        progress: '0/1',
      },
    ],
    offers: [
      {
        uid: 3,
        partner: 'Гильдия старателей',
        partner_id: 'prospectors',
        item: 'плазма',
        requirement: '"плазма"',
        quantity: 10,
        delivered: 4,
        unit_price: 100,
        unit_reward: 200,
        premium: 1000,
        reward: 2000,
        paid: 400,
        accepted: 1,
        contraband: 0,
        time_left: 300,
      },
    ],
    team_share: 25,
    refill_in: 900,
    budget_name: 'бюджет Тарков Индастриз',
  };

  test('консоль аванпоста показывает его заказы и спецзаказы партнёров', () => {
    const content = text(setup({ outpost, budget_name: 'бюджет Тарков Индастриз' }).container);
    expect(content).toContain('Заработок аванпоста');
    expect(content).toContain('Pie');
    expect(content).toContain('1 571 кр.');
    expect(content).toContain('Сдано: 0/1');
    expect(content).toContain('Сдавшим 25%');
    expect(content).toContain('Новые заказычерез 15:00');
    expect(content).toContain('Гильдия старателей');
    expect(content).toContain('Сдано 4 из 10');
    expect(content).toContain('Деньги идут в бюджет Тарков Индастриз, сдавшему лично 25%');
  });

  test('заработок аванпоста виден и на заблокированной консоли, а станционной не показывается', () => {
    const locked = text(setup({ outpost, locked: 1 }).container);
    expect(locked).toContain('Разблокировать консоль');
    expect(locked).toContain('Заработок аванпоста');
    expect(text(setup().container)).not.toContain('Заработок аванпоста');
  });

  test('пустая доска аванпоста говорит, когда будут заказы', () => {
    const content = text(setup({ outpost: { ...outpost, contracts: [], offers: [], refill_in: 0 } }).container);
    expect(content).toContain('Заказов сейчас нет.');
    expect(content).toContain('Спецзаказов сейчас нет.');
    expect(content).toContain('с ближайшим обновлением доски');
  });
});

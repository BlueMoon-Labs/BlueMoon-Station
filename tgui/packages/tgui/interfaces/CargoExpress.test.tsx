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
});

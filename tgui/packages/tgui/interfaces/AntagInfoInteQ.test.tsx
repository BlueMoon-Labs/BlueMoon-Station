import { fireEvent, render, screen } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { AntagInfoInteQ } from './AntagInfoInteQ';

const hoard = {
  count: 1,
  name: 'hoard',
  explanation: 'Украдите 12000 кр. с чужих личных счетов и держите к концу смены не меньше 12000 кр. у себя. Сейчас: украдено 0 из 12000 кр., у себя 0 кр.',
  hint: 'Кража - перевод или снятие наличных, которое вы сами сделали с чужого счёта.',
  ref: '[0x21000abc]',
  swappable: 1,
};

const escape = { count: 2, name: 'escape', explanation: 'Escape on the shuttle alive.' };

const fixture = {
  phrases: 'кот, пёс',
  responses: 'мышь, кость',
  theme: 'inteq',
  allies: 'Не доверяйте никому.',
  goal: 'Get in, get done, get out.',
  intro: 'You are from InteQ.',
  code: '',
  has_uplink: 0,
  uplink_intro: '',
  uplink_unlock_info: '',
  objectives: [hoard, escape],
  economy_note: 'Экономические задания - про деньги станции.',
};

const setup = (overrides: object = {}) => {
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'AntagInfoInteQ' }, data: { ...fixture, ...overrides } }));
  render(<AntagInfoInteQ />);
  return topic;
};

const sent = (topic: jest.Mock, action: string) =>
  topic.mock.calls.filter(([message]) => message.type === `act/${action}`).map(([message]) => JSON.parse(message.payload));

test('под экономическим заданием видна подсказка «Как выполнить» и строка о замене', () => {
  setup();
  expect(screen.getByText(/Как выполнить: Кража - перевод/)).toBeTruthy();
  expect(screen.getByText('Экономические задания - про деньги станции.')).toBeTruthy();
  expect(screen.getAllByText(/Как выполнить/)).toHaveLength(1);
});

test('«Заменить» спрашивает подтверждение и шлёт ссылку на задание', () => {
  const topic = setup();
  expect(screen.getAllByText('Заменить')).toHaveLength(1);
  fireEvent.click(screen.getByText('Заменить'));
  expect(sent(topic, 'swap_economy_objective')).toEqual([]);
  fireEvent.click(screen.getByText('Новое случайное, назад нельзя. Точно?'));
  expect(sent(topic, 'swap_economy_objective')).toEqual([{ ref: hoard.ref }]);
});

test('без доступной замены кнопки нет, без экономических заданий нет и строки', () => {
  setup({ objectives: [{ ...hoard, swappable: 0 }, escape], economy_note: null });
  expect(screen.queryByText('Заменить')).toBeNull();
  expect(screen.queryByText(/Экономические задания/)).toBeNull();
  expect(screen.getByText(/Как выполнить/)).toBeTruthy();
});

test('после вызова шаттла кнопка видна, но не работает и объясняет почему', () => {
  const reason = 'Эвакуационный шаттл уже вызван: заменить задание нельзя.';
  const topic = setup({ objectives: [{ ...hoard, swappable: 0, swap_locked: reason }, escape] });
  const button = screen.getByText('Заменить').closest('.Button');
  expect(button?.className).toMatch(/Button--disabled/);
  fireEvent.click(screen.getByText('Заменить'));
  expect(screen.queryByText('Новое случайное, назад нельзя. Точно?')).toBeNull();
  expect(sent(topic, 'swap_economy_objective')).toEqual([]);
});

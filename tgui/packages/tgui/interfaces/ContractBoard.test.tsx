import { fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { ContractBoardContent } from './ContractBoard';

const contract = (uid, extra = {}) => ({
  uid,
  department: 'CIV',
  department_name: 'Гражданские',
  title: `Контракт ${uid}`,
  desc: 'Описание',
  reward: 5000,
  urgent: 0,
  time_left: null,
  taken_by: null,
  taker_id: null,
  takeable: 1,
  special: 0,
  progress: '0/1',
  rotates_in: null,
  started: 0,
  ...extra,
});

const backend = {
  mode: 'pad',
  contracts_help: 'Контракты NT: поставка и деятельность.',
  pad: 1,
  pad_on_station: 1,
  sending: 0,
  status_report: 'Готов к отправке.',
  my_account: 111,
  my_name: 'Тест Тестов',
  performer_share: 30,
  stored_cash: 1000,
  contracts: [
    contract(1, { rotates_in: 61 }),
    contract(2, { taken_by: 'Тест Тестов', taker_id: 111, urgent: 1, time_left: 125 }),
    contract(3, { takeable: 0, special: 1 }),
  ],
};

const setup = (data = {}) => {
  let now = Date.now();
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'ContractBoard' }, data: { ...backend, ...data } }));
  return { ...render(<ContractBoardContent />), topic };
};

const sent = (topic, action) =>
  topic.mock.calls
    .map(([message]) => message)
    .filter((message) => message.type === `act/${action}`)
    .map((message) => (message.payload ? JSON.parse(message.payload) : {}));

test('пункт подработки: «Взять» шлёт take с uid, «Отправить» - send, «Проверить» - recalc', () => {
  const ui = setup();
  expect(ui.getByText('Ваш контракт')).toBeTruthy();
  expect(ui.getByText('Смена через 1:01')).toBeTruthy();
  fireEvent.click(ui.getByText('Взять'));
  fireEvent.click(ui.getByText('Отправить'));
  fireEvent.click(ui.getByText('Проверить'));
  expect(sent(ui.topic, 'take')).toEqual([{ uid: 1 }]);
  expect(sent(ui.topic, 'send')).toHaveLength(1);
  expect(sent(ui.topic, 'recalc')).toHaveLength(1);
  expect(ui.queryByText('Распечатать')).toBeNull();
});

test('идущую отправку можно отменить, пад вне станции виден', () => {
  const ui = setup({ sending: 1, pad_on_station: 0 });
  fireEvent.click(ui.getByText('Отменить'));
  expect(sent(ui.topic, 'stop')).toHaveLength(1);
  expect(ui.getByText('Вне станции')).toBeTruthy();
});

test('консоль контрактов: бюджет снабжения, печать списка, без пада', () => {
  const ui = setup({ mode: 'console' });
  expect(ui.queryByText('Пад подработки')).toBeNull();
  expect(ui.getByText('Контракт 3 (заказ ЦК)')).toBeTruthy();
  fireEvent.click(ui.getByText('Распечатать'));
  fireEvent.click(ui.getByText('Взять'));
  expect(sent(ui.topic, 'Print')).toHaveLength(1);
  expect(sent(ui.topic, 'take')).toEqual([{ uid: 1 }]);
});

test('справка о контрактах и пустая доска без счёта', () => {
  const ui = setup({ contracts: [], my_name: null });
  fireEvent.click(ui.getByText('Как работают контракты'));
  expect(ui.getByText('Контракты NT: поставка и деятельность.')).toBeTruthy();
  fireEvent.click(ui.getByText('Контракты'));
  expect(ui.getByText('Контрактов сейчас нет.')).toBeTruthy();
  expect(ui.getByText('Банковский счёт не найден: контракт не взять.')).toBeTruthy();
});

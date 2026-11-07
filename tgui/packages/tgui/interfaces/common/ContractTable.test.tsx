import { fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../../backend';
import { debugReducer } from '../../debug';
import { ContractTable } from './ContractTable';

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

const contracts = [
  contract(1, { rotates_in: 61 }),
  contract(2, { taken_by: 'Тест Тестов', taker_id: 111, urgent: 1, time_left: 125 }),
  contract(3, { takeable: 0, special: 1 }),
  contract(4, { taken_by: 'Другой', taker_id: 222 }),
  contract(5, { started: 1, rotates_in: 3600, takeable: 0 }),
];

const setup = (data = {}, readOnly = false) => {
  let now = Date.now();
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(
    backendUpdate({ config: { interface: 'ContractBoard' }, data: { contracts, my_account: 111, performer_share: 30, ...data } }),
  );
  return { ...render(<ContractTable readOnly={readOnly} />), topic };
};

const sent = (topic, action) =>
  topic.mock.calls
    .map(([message]) => message)
    .filter((message) => message.type === `act/${action}`)
    .map((message) => JSON.parse(message.payload));

test('доска показывает, кто взял контракт, срочность, срок и смену', () => {
  const ui = setup();
  expect(ui.getByText('Ваш контракт')).toBeTruthy();
  expect(ui.getByText('Взял: Другой')).toBeTruthy();
  expect(ui.getAllByText('Выполняет отдел')).toHaveLength(2);
  expect(ui.getByText('Срочный')).toBeTruthy();
  expect(ui.getByText('Осталось 2:05')).toBeTruthy();
  expect(ui.getByText('Смена через 1:01')).toBeTruthy();
  expect(ui.getByText('Снимется через 60:00, отгруженное не вернётся')).toBeTruthy();
  expect(ui.getByText('Контракт 3 (заказ ЦК)')).toBeTruthy();
  expect(ui.getByText('Взявший контракт получает 30% награды, остальное - отделу.')).toBeTruthy();
});

test('"Взять" шлёт take с uid', () => {
  const ui = setup();
  fireEvent.click(ui.getByText('Взять'));
  expect(sent(ui.topic, 'take')).toEqual([{ uid: 1 }]);
});

test('без счёта "Взять" неактивна', () => {
  const noAccount = setup({ my_account: null });
  fireEvent.click(noAccount.getByText('Взять'));
  expect(sent(noAccount.topic, 'take')).toEqual([]);
});

test('только просмотр: без кнопки, свободный контракт помечен', () => {
  const ui = setup({}, true);
  expect(ui.queryByText('Взять')).toBeNull();
  expect(ui.getByText('Свободен')).toBeTruthy();
  expect(ui.getByText('Взял: Другой')).toBeTruthy();
});

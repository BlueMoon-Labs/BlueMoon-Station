import { cleanup, fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { CashRegisterContent, CashRegisterData } from './CashRegister';

const ivan = {
  id: 111,
  name: 'Иван Петров',
  present: 1,
  mine: 0,
  order: [
    { id: 4, name: 'Пиво', price: 100, count: 2 },
    { id: 7, name: 'Сок', price: 30, count: 1 },
  ],
  total: 230,
  rev: 5,
  department: 'Сервис',
  share: 50,
  pay_problem: null,
};

const anna = { ...ivan, id: 222, name: 'Анна', order: [], total: 0, rev: 6, department: null, share: 100 };

const base: CashRegisterData = {
  skin: 'bar',
  skin_name: 'бар',
  price_max: 5000,
  menu_max: 20,
  name_max: 42,
  count_max: 20,
  cashiers_max: 2,
  tip_max: 5000,
  transfer_cooldown: 5,
  cashiers: [ivan],
  is_cashier: 0,
  can_join: 0,
  menu: [
    { id: 4, name: 'Пиво', price: 100 },
    { id: 7, name: 'Сок', price: 30 },
  ],
  total_sales: null,
  has_account: 1,
  balance: 1000,
  cooldown_left: 0,
  receipt: 0,
};

const setup = (data: Partial<CashRegisterData> = {}) => {
  let now = Date.now();
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'CashRegister' }, data: { ...base, ...data } }));
  return { ...render(<CashRegisterContent />), topic };
};

const sent = (topic, action) =>
  topic.mock.calls
    .map(([message]) => message)
    .filter((message) => message.type === `act/${action}`)
    .map((message) => (message.payload ? JSON.parse(message.payload) : {}));

const text = (container: HTMLElement) => (container.textContent || '').replace(/\u00a0/g, ' ');

const typeNumber = (input: HTMLInputElement, value: string) => {
  fireEvent.focus(input);
  fireEvent.input(input, { target: { value } });
  fireEvent.blur(input);
};

test('клиент видит счёт кассира, долю отдела, платит ровно этот счёт и оставляет чаевые', () => {
  const { container, getByText, topic } = setup();
  expect(text(container)).toContain('Пиво x2');
  expect(text(container)).toContain('200 кр.');
  expect(text(container)).toContain('Получатель Иван Петров: 50% кассиру, остальное отделу "Сервис"');
  expect(text(container)).toContain('Наличные приложите к кассе');
  fireEvent.click(getByText('Оплатить картой 230 кр.'));
  typeNumber(container.querySelector('input') as HTMLInputElement, '25');
  fireEvent.click(getByText('Оставить чаевые'));
  expect(sent(topic, 'pay')).toEqual([{ cashier: 111, rev: 5, total: 230 }]);
  expect(sent(topic, 'tip')).toEqual([{ cashier: 111, amount: 25 }]);
  expect(container.textContent).not.toContain('Добавить');
});

test('два кассира: у каждого свой счёт, чаевые - выбранному', () => {
  const { container, getByText, getAllByText, topic } = setup({ cashiers: [ivan, { ...anna, present: 0 }] });
  expect(text(container)).toContain('Счёт: Иван Петров');
  expect(text(container)).toContain('Счёт: Анна (отошёл)');
  expect(text(container)).toContain('Кассир ещё не набрал счёт.');
  expect(getAllByText(/^Оплатить картой/)).toHaveLength(1);
  fireEvent.click(getByText('Анна', { selector: '.NtTerm__chip' }));
  fireEvent.click(getByText('Оставить: Анна'));
  expect(sent(topic, 'tip')).toEqual([{ cashier: 222, amount: 10 }]);
});

test('клиенту объяснён отказ оплаты и идущий кулдаун', () => {
  const { container, getByText } = setup({
    cashiers: [{ ...ivan, pay_problem: 'Недостаточно средств: на счёте 10 кр.' }],
    cooldown_left: 4,
  });
  expect(text(container)).toContain('Недостаточно средств: на счёте 10 кр.');
  expect(text(container)).toContain('ещё 4 с.');
  expect(getByText('Оплатить картой 230 кр.').closest('.Button')?.className).toContain('Button--disabled');
  expect(getByText('Оставить чаевые').closest('.Button')?.className).toContain('Button--disabled');
});

test('чек последней оплаты печатается, пока он не распечатан', () => {
  const { getByText, topic } = setup({ receipt: 1 });
  fireEvent.click(getByText('Распечатать чек'));
  expect(sent(topic, 'receipt')).toHaveLength(1);
  cleanup();
  const { container } = setup({ receipt: 0 });
  expect(container.textContent).not.toContain('Распечатать чек');
});

test('кассир ушёл - чек последней оплаты всё равно печатается', () => {
  const { getByText, topic } = setup({ cashiers: [], receipt: 1 });
  fireEvent.click(getByText('Распечатать чек'));
  expect(sent(topic, 'receipt')).toHaveLength(1);
});

test('свободная касса предлагает встать за неё', () => {
  const { container, getByText, topic } = setup({ cashiers: [], can_join: 1 });
  expect(text(container)).toContain('Касса свободна');
  expect(container.textContent).not.toContain('Оплатить');
  fireEvent.click(getByText('Встать за кассу'));
  expect(sent(topic, 'join')).toHaveLength(1);
  cleanup();
  const busy = setup({ can_join: 0 });
  expect(busy.container.textContent).not.toContain('Встать за кассу');
});

test('кассир набирает свой счёт по меню и правит меню', () => {
  const { container, getByText, getAllByText, getByPlaceholderText, topic } = setup({
    is_cashier: 1,
    total_sales: 130,
    cashiers: [{ ...ivan, mine: 1 }, anna],
  });
  expect(text(container)).toContain('130 кр.');
  expect(text(container)).toContain('Второй кассир: Анна.');
  expect(text(container)).toContain('Итого230 кр.');
  fireEvent.click(getAllByText('В счёт')[1]);
  fireEvent.click(container.querySelectorAll('.Button .fa-minus')[0].closest('.Button') as HTMLElement);
  fireEvent.click(getByText('Очистить'));
  fireEvent.input(getByPlaceholderText('Новая позиция'), { target: { value: ' Чай ' } });
  typeNumber(container.querySelectorAll('input')[1] as HTMLInputElement, '15');
  fireEvent.click(getByText('Добавить'));
  fireEvent.click(container.querySelectorAll('.Button .fa-trash')[0].closest('.Button') as HTMLElement);
  fireEvent.click(getByText('Отойти от кассы'));
  expect(sent(topic, 'order')).toEqual([
    { id: 7, delta: 1 },
    { id: 4, delta: -1 },
  ]);
  expect(sent(topic, 'clear')).toHaveLength(1);
  expect(sent(topic, 'add_item')).toEqual([{ name: 'Чай', price: 15 }]);
  expect(sent(topic, 'remove_item')).toEqual([{ id: 4 }]);
  expect(sent(topic, 'logout')).toHaveLength(1);
  expect(container.textContent).not.toContain('Оплатить');
});

test('плюс в счёт гаснет на пределе штук', () => {
  const { getAllByText } = setup({
    is_cashier: 1,
    count_max: 2,
    cashiers: [{ ...ivan, mine: 1 }],
  });
  expect(getAllByText('В счёт')[0].closest('.Button')?.className).toContain('Button--disabled');
  expect(getAllByText('В счёт')[1].closest('.Button')?.className).not.toContain('Button--disabled');
});

import { fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { CashRegisterContent, CashRegisterData } from './CashRegister';

const base: CashRegisterData = {
  skin: 'bar',
  skin_name: 'бар',
  price_max: 5000,
  menu_max: 20,
  name_max: 42,
  tip_max: 5000,
  transfer_cooldown: 5,
  cashier: 'Иван Петров',
  cashier_present: 1,
  session: 3,
  is_cashier: 0,
  menu: [
    { id: 4, name: 'Пиво', price: 100 },
    { id: 7, name: 'Сок', price: 30 },
  ],
  selected: 7,
  total_sales: null,
  department: 'Сервис',
  cashier_share: 50,
  has_account: 1,
  balance: 1000,
  pay_problem: null,
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

test('клиент видит кассира, получателя и долю отдела, платит выбранное и оставляет чаевые', () => {
  const { container, getByText, topic } = setup();
  expect(text(container)).toContain('Иван Петров');
  expect(text(container)).toContain('50% кассиру, 50% в бюджет отдела «Сервис»');
  expect(text(container)).toContain('Сок - 30 кр., получатель: Иван Петров');
  expect(text(container)).toContain('делят один кулдаун: не чаще раза в 5 с');
  fireEvent.click(getByText('Оплатить 30 кр.'));
  const tip = container.querySelector('input') as HTMLInputElement;
  fireEvent.focus(tip);
  fireEvent.input(tip, { target: { value: '25' } });
  fireEvent.blur(tip);
  fireEvent.click(getByText('Оставить чаевые'));
  expect(sent(topic, 'pay')).toEqual([{ id: 7, price: 30, session: 3 }]);
  expect(sent(topic, 'tip')).toEqual([{ amount: 25, session: 3 }]);
  expect(container.textContent).not.toContain('Добавить');
});

test('клиенту объяснён отказ оплаты и идущий кулдаун', () => {
  const { container, getByText } = setup({ pay_problem: 'Недостаточно средств: на счёте 10 кр.', cooldown_left: 4 });
  expect(text(container)).toContain('Недостаточно средств: на счёте 10 кр.');
  expect(text(container)).toContain('Следующий платёж через 4 с.');
  expect(getByText('Оплатить 30 кр.').closest('.Button')?.className).toContain('Button--disabled');
  expect(getByText('Оставить чаевые').closest('.Button')?.className).toContain('Button--disabled');
});

test('чек последней оплаты печатается из окна, пока он не распечатан', () => {
  const { getByText, topic } = setup({ receipt: 1 });
  fireEvent.click(getByText('Распечатать чек последней оплаты'));
  expect(sent(topic, 'receipt')).toHaveLength(1);
  const { container } = setup({ receipt: 0 });
  expect(container.textContent).not.toContain('Распечатать чек');
});

test('кассир ушёл - чек последней оплаты всё равно можно распечатать', () => {
  const { getByText, topic } = setup({ cashier: null, selected: 0, receipt: 1 });
  fireEvent.click(getByText('Распечатать чек последней оплаты'));
  expect(sent(topic, 'receipt')).toHaveLength(1);
  const { container } = setup({ cashier: null, selected: 0, receipt: 0 });
  expect(container.textContent).not.toContain('Распечатать чек');
});

test('свободная касса предлагает встать за неё картой', () => {
  const { container } = setup({ cashier: null, selected: 0 });
  expect(text(container)).toContain('Касса свободна');
  expect(container.textContent).not.toContain('Оплатить 30');
});

test('кассир правит меню: добавить, к оплате, снять, убрать, отойти', () => {
  const { container, getByText, getAllByText, getByPlaceholderText, topic } = setup({ is_cashier: 1, total_sales: 130 });
  expect(text(container)).toContain('130 кр.');
  fireEvent.input(getByPlaceholderText('Название позиции'), { target: { value: ' Чай ' } });
  const price = container.querySelectorAll('input')[1] as HTMLInputElement;
  fireEvent.focus(price);
  fireEvent.input(price, { target: { value: '15' } });
  fireEvent.blur(price);
  fireEvent.click(getByText('Добавить'));
  fireEvent.click(getByText('К оплате'));
  fireEvent.click(getByText('Снять'));
  fireEvent.click(container.querySelectorAll('.Button .fa-trash')[0].closest('.Button') as HTMLElement);
  fireEvent.click(getByText('Отойти от кассы'));
  expect(sent(topic, 'add_item')).toEqual([{ name: 'Чай', price: 15 }]);
  expect(sent(topic, 'select')).toEqual([{ id: 4 }, { id: 0 }]);
  expect(sent(topic, 'remove_item')).toEqual([{ id: 4 }]);
  expect(sent(topic, 'logout')).toHaveLength(1);
  expect(getAllByText('Пиво')).toHaveLength(1);
  expect(container.textContent).not.toContain('Оплатить 30');
});

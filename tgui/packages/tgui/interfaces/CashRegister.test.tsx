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
  has_template: 0,
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
  just_paid: null,
};

const setup = (data: Partial<CashRegisterData> = {}) => {
  let now = Date.now();
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'CashRegister' }, data: { ...base, ...data } }));
  return { ...render(<CashRegisterContent />), topic, store };
};

const sent = (topic, action) =>
  topic.mock.calls
    .map(([message]) => message)
    .filter((message) => message.type === `act/${action}`)
    .map((message) => (message.payload ? JSON.parse(message.payload) : {}));

const text = (container: HTMLElement) => (container.textContent || '').replace(/\u00a0/g, ' ');

const currentStep = (container: HTMLElement) => text(container.querySelector('[aria-current="step"]') as HTMLElement);

const getLogout = (container: HTMLElement) =>
  Array.from(container.querySelectorAll('.Button')).find((button) => button.textContent === 'Отойти от кассы') as HTMLElement;

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
  expect(currentStep(container)).toContain('Оплатите: кнопкой «Оплатить картой», ID-картой или КПК по кассе или приложите к ней наличные');
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

test('клиенту по шагам: сначала заказ кассиру, только что оплатившему - отдельная строка', () => {
  const { container } = setup({ cashiers: [anna] });
  expect(currentStep(container)).toContain('Скажите кассиру, что хотите');
  expect(container.querySelectorAll('.fa-check')).toHaveLength(0);
  expect(container.querySelector('.NtTerm__paid')).toBeNull();
  cleanup();
  const paid = setup({ cashiers: [anna], receipt: 1, just_paid: 230 });
  expect(text(paid.container.querySelector('.NtTerm__paid') as HTMLElement)).toBe('Вы оплатили 230 кр. Чек и чаевые - ниже, по желанию.');
  expect(currentStep(paid.container)).toContain('Скажите кассиру, что хотите');
  expect(paid.container.querySelectorAll('.fa-check')).toHaveLength(0);
  cleanup();
  const ordered = setup({ receipt: 1, just_paid: 230 });
  expect(ordered.container.querySelector('.NtTerm__paid')).toBeNull();
  expect(currentStep(ordered.container)).toContain('Оплатите');
});

test('вернувшийся покупатель с давним нераспечатанным чеком начинает с заказа', () => {
  const { container } = setup({ cashiers: [anna], receipt: 1, just_paid: null });
  expect(currentStep(container)).toContain('Скажите кассиру, что хотите');
  expect(container.querySelectorAll('.fa-check')).toHaveLength(0);
  expect(container.querySelector('.NtTerm__paid')).toBeNull();
  expect(text(container)).toContain('Распечатать чек');
});

test('без личного счёта свободная касса просит ID-карту, а не встать за неё', () => {
  const { container } = setup({ cashiers: [], has_account: 0 });
  expect(text(container)).toContain('Продаёте? Нужна ID-карта с личным счётом.');
  expect(text(container)).not.toContain('Встаньте за кассу');
});

test('кассиру с пустым меню - типовое меню одной кнопкой, только если у корпуса оно есть', () => {
  const { getByText, topic } = setup({ is_cashier: 1, has_template: 1, menu: [], cashiers: [{ ...anna, mine: 1 }] });
  fireEvent.click(getByText('Типовое меню'));
  expect(sent(topic, 'template')).toHaveLength(1);
  cleanup();
  const filled = setup({ is_cashier: 1, has_template: 1, cashiers: [{ ...anna, mine: 1 }] });
  expect(filled.container.textContent).not.toContain('Типовое меню');
  cleanup();
  const universal = setup({ is_cashier: 1, has_template: 0, menu: [], cashiers: [{ ...anna, mine: 1 }] });
  expect(universal.container.textContent).not.toContain('Типовое меню');
  cleanup();
  const customer = setup({ has_template: 1, menu: [], cashiers: [anna] });
  expect(customer.container.textContent).not.toContain('Типовое меню');
});

test('кнопка ухода кассира предупреждает, что набранный счёт сбросится', () => {
  const { container } = setup({ is_cashier: 1, cashiers: [{ ...ivan, mine: 1 }] });
  fireEvent.mouseEnter(getLogout(container));
  expect(text(document.querySelector('.Tooltip') as HTMLElement)).toBe('Набранный счёт на 230 кр. сбросится');
});

test('встать вторым кассиром предлагают как дело персонала, не покупателя', () => {
  const { getByText, topic } = setup({ can_join: 1 });
  fireEvent.click(getByText('Встать вторым кассиром'));
  expect(sent(topic, 'join')).toHaveLength(1);
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
  expect(text(container)).toContain('Продаёте? Встаньте за кассу кнопкой ниже или проведите по ней своей ID-картой или КПК.');
  expect(text(container)).toContain('Покупаете? Дождитесь кассира или просто попросите, что хотите: касса необязательна.');
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

test('кассиру по шагам: меню, заказ в счёт, оплата покупателем', () => {
  const { container } = setup({ is_cashier: 1, total_sales: 0, menu: [], cashiers: [{ ...anna, mine: 1 }] });
  expect(currentStep(container)).toContain('Заведите позиции в меню');
  expect(text(container)).toContain('Касса необязательна');
  cleanup();
  const menuReady = setup({ is_cashier: 1, total_sales: 0, cashiers: [{ ...anna, mine: 1 }] });
  expect(currentStep(menuReady.container)).toContain('добавьте его в свой счёт кнопкой «В счёт»');
  cleanup();
  const ordered = setup({ is_cashier: 1, total_sales: 0, cashiers: [{ ...ivan, mine: 1 }] });
  expect(currentStep(ordered.container)).toContain('Покупатель платит сам: картой или КПК по кассе');
  expect(text(ordered.container)).toContain('С оплаты: 50% кассиру, остальное отделу "Сервис". Чаевые - вам целиком.');
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

test('кассир видит, что его счёт оплатили; очистка счёта без выручки - не оплата', () => {
  const mine = { ...ivan, mine: 1 };
  const { container, rerender, store } = setup({ is_cashier: 1, total_sales: 130, cashiers: [mine] });
  const update = (data: Partial<CashRegisterData>) => {
    store.dispatch(backendUpdate({ data }));
    rerender(<CashRegisterContent />);
  };
  expect(container.querySelector('.NtTerm__paid')).toBeNull();
  update({ total_sales: 360, cashiers: [{ ...mine, order: [], total: 0, rev: 9 }] });
  expect(text(container.querySelector('.NtTerm__paid') as HTMLElement)).toBe('Оплачено: 230 кр.');
  update({ cashiers: [{ ...mine, rev: 10 }] });
  expect(container.querySelector('.NtTerm__paid')).toBeNull();
  update({ cashiers: [{ ...mine, order: [], total: 0, rev: 11 }] });
  expect(container.querySelector('.NtTerm__paid')).toBeNull();
});

test('клиенту подсвечен изменившийся счёт кассира', () => {
  const { container, rerender, store } = setup();
  expect(container.querySelector('.NtTerm__pulse')).toBeNull();
  store.dispatch(backendUpdate({ data: { cashiers: [{ ...ivan, total: 330, rev: 6 }] } }));
  rerender(<CashRegisterContent />);
  expect(text(container.querySelector('.NtTerm__pulse--new') as HTMLElement)).toBe('330 кр.');
});

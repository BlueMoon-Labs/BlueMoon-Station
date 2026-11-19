import { fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { RoomServiceContent, RoomServiceData } from './RoomService';

const base: RoomServiceData = {
  menu: [
    { id: 'burger', name: 'Бургер', kind: 'food', price: 60 },
    { id: 'coffee', name: 'Кофе', kind: 'drink', price: 30 },
  ],
  decor: [
    { id: 'flowers', name: 'Цветы', desc: 'Два растения в горшках.', price: 400, max: 2 },
    { id: 'music', name: 'Музыка', desc: 'Экран Muz-TV на стене.', price: 3000, max: 1 },
  ],
  catering_mult: 2,
  wait_minutes: 15,
  claim_minutes: 5,
  tip_amounts: [10, 25, 50],
  count_max: 4,
  orders_max: 3,
  room: 42,
  open: 1,
  account_problem: null,
  has_account: 1,
  balance: 1000,
  staff: { food: 1, drink: 0 },
  catering: { food: 0, drink: 1 },
  special: null,
  orders: [],
  tips: [],
  decor_bought: [],
};

const setup = (data: Partial<RoomServiceData> = {}) => {
  let now = Date.now();
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'RoomService' }, data: { ...base, ...data } }));
  return { ...render(<RoomServiceContent />), topic };
};

const sent = (topic, action) =>
  topic.mock.calls
    .map(([message]) => message)
    .filter((message) => message.type === `act/${action}`)
    .map((message) => (message.payload ? JSON.parse(message.payload) : {}));

const text = (container: HTMLElement) => (container.textContent || '').replace(/\u00a0/g, ' ');

const button = (container: HTMLElement, label: RegExp) =>
  Array.from(container.querySelectorAll('.Button')).find((node) => label.test(text(node as HTMLElement))) as HTMLElement;

test('повар на смене: заказ с кухни уходит сервису, число штук идёт в заказ', () => {
  const { container, topic } = setup();
  expect(text(container)).toContain('Повар на смене: заказ уйдёт ему');
  expect(text(container)).toContain('вернутся, если заказ никто не возьмёт за 5 мин. или не доставят за 15 мин.');
  expect(button(container, /^От NT/)).toBeUndefined();
  fireEvent.click(container.querySelector('.fa-plus') as HTMLElement);
  expect(text(container)).toContain('Бургер x2');
  fireEvent.click(button(container, /^Заказать за 120 кр\.$/));
  expect(sent(topic, 'order')).toEqual([{ id: 'burger', count: 2, route: 'staff' }]);
});

test('бармена нет: бар продаёт кейтеринг NT дороже', () => {
  const { container, getByText, topic } = setup();
  fireEvent.click(getByText('Бар'));
  expect(text(container)).toContain('Бармена нет на смене: NT пришлёт готовое сразу, в 2 раза дороже.');
  expect(button(container, /^Заказать/)).toBeUndefined();
  fireEvent.click(button(container, /^От NT за 60 кр\.$/));
  expect(sent(topic, 'order')).toEqual([{ id: 'coffee', count: 1, route: 'catering' }]);
});

test('сервис не успел: на кухне есть и заказ повару, и кейтеринг', () => {
  const { container, topic } = setup({ catering: { food: 1, drink: 1 } });
  expect(text(container)).toContain('Сервис уже не успел с прошлым заказом');
  fireEvent.click(button(container, /^От NT за 120 кр\.$/));
  fireEvent.click(button(container, /^Заказать за 60 кр\.$/));
  expect(sent(topic, 'order')).toEqual([
    { id: 'burger', count: 1, route: 'catering' },
    { id: 'burger', count: 1, route: 'staff' },
  ]);
});

test('ждущий заказ отменяет только заказчик, при лимите заказ повару закрыт', () => {
  const orders = [
    { uid: 7, name: 'Бургер', kind: 'food' as const, count: 2, total: 120, minutes_left: 12, taken: 1, mine: 1 },
    { uid: 8, name: 'Кофе', kind: 'drink' as const, count: 1, total: 30, minutes_left: 3, taken: 0, mine: 0 },
    { uid: 9, name: 'Бургер', kind: 'food' as const, count: 1, total: 60, minutes_left: 14, taken: 0, mine: 0 },
  ];
  const { container, getAllByText, topic } = setup({ orders });
  expect(text(container)).toContain('№7: Бургер x2');
  expect(text(container)).toContain('Повар принял заказ, ещё 12 мин.');
  expect(text(container)).toContain('ждёт сервис, ещё 3 мин.');
  expect(getAllByText('Отменить')).toHaveLength(1);
  fireEvent.click(getAllByText('Отменить')[0]);
  expect(sent(topic, 'cancel')).toEqual([{ uid: 7 }]);
  expect(text(container)).toContain('Доставки уже ждут 3 заказа номера');
  expect(button(container, /^Заказать за/).className).toContain('Button--disabled');
});

test('декор: покупка набора, купленный до предела не продаётся', () => {
  const { container, getByText, topic } = setup({ decor_bought: { flowers: 1, music: 1 } });
  fireEvent.click(getByText('Номер'));
  expect(text(container)).toContain('Два растения в горшках.');
  expect(text(container)).toContain('1 из 2');
  fireEvent.click(button(container, /^Купить за 400 кр\.$/));
  expect(sent(topic, 'decor')).toEqual([{ id: 'flowers' }]);
  expect(button(container, /^Уже в номере$/).className).toContain('Button--disabled');
});

test('без личного счёта ничего не купить, вне номера терминал молчит', () => {
  const { container, unmount } = setup({ account_problem: 'Платить можно только с личного счёта.', has_account: 0 });
  expect(text(container)).toContain('Платить можно только с личного счёта.');
  expect(text(container)).toContain('нет счёта');
  expect(button(container, /^Заказать за/).className).toContain('Button--disabled');
  unmount();
  const closed = setup({ open: 0 });
  expect(text(closed.container)).toContain('Терминал работает только в номере отеля.');
  expect(button(closed.container, /^Заказать за/)).toBeUndefined();
});

test('замороженный счёт показан недоступным, а не отсутствующим', () => {
  const { container } = setup({ account_problem: 'Ваш счёт заморожен.', has_account: 1 });
  expect(text(container)).toContain('недоступен');
  expect(text(container)).not.toContain('нет счёта');
});

test('после доставки заказчик оставляет чаевые одной из сумм', () => {
  const tips = [{ uid: 12, name: 'Бургер x2', staff: 'Иван Повар' }];
  const { container, topic } = setup({ tips });
  expect(text(container)).toContain('№12: Бургер x2, доставка - Иван Повар');
  fireEvent.click(button(container, /^25 кр\.$/));
  expect(sent(topic, 'tip')).toEqual([{ uid: 12, amount: 25 }]);
  expect(button(container, /^10 кр\.$/)).toBeDefined();
  expect(button(container, /^50 кр\.$/)).toBeDefined();
});

test('блюдо дня от шефа - только заказом повару', () => {
  const special = { id: 'special', name: 'Блюдо дня от шефа: plain burger', kind: 'food' as const, price: 90 };
  const { container, topic } = setup({ special, catering: { food: 1, drink: 1 } });
  expect(text(container)).toContain('Блюдо дня от шефа: plain burger');
  fireEvent.click(button(container, /^Заказать за 90 кр\.$/));
  expect(sent(topic, 'order')).toEqual([{ id: 'special', count: 1, route: 'staff' }]);
  expect(button(container, /^От NT за 180 кр\.$/)).toBeUndefined();
  const noCook = setup({ special, staff: { food: 0, drink: 0 } });
  expect(text(noCook.container)).not.toContain('Блюдо дня от шефа');
});

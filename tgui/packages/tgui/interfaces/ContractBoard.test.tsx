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
  contracts_help_topics: [{ title: 'Как выполнить', lines: ['Контракты NT: поставка и деятельность.'] }],
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

test('пункт подработки: "Взять" шлёт take с uid, "Отправить" - send, "Проверить" - recalc', () => {
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

const auctionPad = {
  items: [
    { ref: '[0x1]', name: 'гитара', problem: null },
    { ref: '[0x2]', name: 'лазер', problem: 'Оружие, боеприпасы и снаряжение СБ на аукцион не принимаются.' },
    { ref: '[0x3]', name: 'шляпа', problem: null },
  ],
  minutes: [5, 10, 15],
  fee: 10,
  min_price: 25,
  max_price: 100000,
  mine: 0,
  per_account: 2,
  lots: 1,
  lots_max: 6,
};

test('аукцион экипажа: выбранная вещь, цена, срок и скрытое имя уходят в auction_list, запрещённое объяснено', () => {
  const ui = setup({ auction: auctionPad });
  expect(ui.queryByText('Аукцион экипажа')).toBeNull();
  fireEvent.click(ui.getByText('Аукцион'));
  expect(ui.getByText('Оружие, боеприпасы и снаряжение СБ на аукцион не принимаются.')).toBeTruthy();
  expect(ui.getByText('ваших 0 из 2, на аукционе 1 из 6', { exact: false })).toBeTruthy();
  expect(ui.getByText('Выставить: гитара')).toBeTruthy();
  fireEvent.click(ui.getByText('лазер'));
  expect(ui.getByText('Выставить: гитара')).toBeTruthy();
  fireEvent.click(ui.getByText('шляпа'));
  fireEvent.click(ui.getByText('10 мин.'));
  fireEvent.click(ui.getByText('Скрыть моё имя'));
  const price = ui.container.querySelector('input') as HTMLInputElement;
  fireEvent.focus(price);
  fireEvent.input(price, { target: { value: '250' } });
  fireEvent.blur(price);
  fireEvent.click(ui.getByText('Выставить: шляпа'));
  expect(sent(ui.topic, 'auction_list')).toEqual([{ ref: '[0x3]', price: 250, minutes: 10, anonymous: true, buyout: 0 }]);
});

test('аукцион экипажа: цена «купить сразу» уходит в auction_list, надпись на вещи видна, после снятия лота пауза', () => {
  const items = [{ ref: '[0x1]', name: 'гитара', problem: null, inscription: 'Гитара Вована' }];
  const ui = setup({ auction: { ...auctionPad, items } });
  fireEvent.click(ui.getByText('Аукцион'));
  expect(ui.getByText('Гитара Вована', { exact: false })).toBeTruthy();
  fireEvent.click(ui.getByText('Можно купить сразу за'));
  const inputs = ui.container.querySelectorAll('input');
  const buyout = inputs[inputs.length - 1] as HTMLInputElement;
  fireEvent.focus(buyout);
  fireEvent.input(buyout, { target: { value: '600' } });
  fireEvent.blur(buyout);
  fireEvent.click(ui.getByText('Выставить: гитара'));
  expect(sent(ui.topic, 'auction_list')).toEqual([{ ref: '[0x1]', price: 100, minutes: 5, anonymous: false, buyout: 600 }]);
  document.body.innerHTML = '';
  const waiting = setup({ auction: { ...auctionPad, relist_left: 95 } });
  fireEvent.click(waiting.getByText('Аукцион'));
  expect(waiting.getByText('Вы недавно сняли свой лот: новый можно выставить через 1:35.')).toBeTruthy();
  expect(waiting.getByText('Выставить: гитара').closest('.Button')?.className).toContain('Button--disabled');
  fireEvent.click(waiting.getByText('Выставить: гитара'));
  expect(sent(waiting.topic, 'auction_list')).toEqual([]);
});

test('аукцион экипажа: у предела лотов не выставить, пустой пад подсказывает', () => {
  const ui = setup({ auction: { ...auctionPad, mine: 2 } });
  fireEvent.click(ui.getByText('Аукцион'));
  expect(ui.getByText('Выставить: гитара').closest('.Button')?.className).toContain('Button--disabled');
  fireEvent.click(ui.getByText('Выставить: гитара'));
  expect(sent(ui.topic, 'auction_list')).toEqual([]);
  document.body.innerHTML = '';
  const empty = setup({ auction: { ...auctionPad, items: [] } });
  fireEvent.click(empty.getByText('Аукцион'));
  expect(empty.getByText('Положите на пад вещь, которую хотите продать экипажу.')).toBeTruthy();
  expect(empty.queryByText('Аукцион экипажа')).toBeTruthy();
  document.body.innerHTML = '';
  expect(setup({ mode: 'console', auction: auctionPad }).queryByText('Аукцион')).toBeNull();
});

test('справка о контрактах и пустая доска без счёта', () => {
  const ui = setup({ contracts: [], my_name: null });
  expect(ui.queryByText('Контракты NT: поставка и деятельность.')).toBeNull();
  const toggles = ui.container.querySelectorAll('.NtTerm__helpToggle');
  fireEvent.click(toggles[toggles.length - 1]);
  expect(ui.getByText('Контракты NT: поставка и деятельность.').tagName).toBe('LI');
  expect(ui.getByText('Как выполнить')).toBeTruthy();
  expect(ui.getByText('Контрактов сейчас нет.')).toBeTruthy();
  expect(ui.getByText('Банковский счёт не найден: контракт не взять.')).toBeTruthy();
});

const rank = { name: 'Подрядчик', rep: 30, done: 4, slots: 3, used: 1, bonus: 5, next_name: 'Мастер', next_rep: 50 };

test('вкладки: на доске сверху свободные чужие объявления, мои с репутацией, счётчики дел на вкладках', () => {
  const contracts = [
    ...backend.contracts,
    contract(4, { kind: 'crew', poster: 'Повар', poster_id: 222, department_name: 'Экипаж', title: 'Помыть кухню' }),
    contract(5, { kind: 'crew', poster: 'Тест Тестов', poster_id: 111, department_name: 'Экипаж', title: 'Моё объявление' }),
    contract(6, { kind: 'crew', poster: 'Повар', poster_id: 222, department_name: 'Экипаж', title: 'Уже взятое', taken_by: 'Другой', taker_id: 333 }),
  ];
  const ui = setup({ contracts, rank });
  const menu = ui.container.querySelector('.NtTerm__menu') as HTMLElement;
  expect(menu.textContent).toContain('Мои2');
  expect(menu.textContent).toContain('Экипаж1');
  expect(ui.getByText('Просит экипаж')).toBeTruthy();
  const titles = Array.from(ui.container.querySelectorAll('.NtTerm__contractTitle')).map((node) => node.textContent);
  expect(titles[1]).toContain('Помыть кухню');
  expect(ui.queryByText('Моё объявление')).toBeNull();
  expect(ui.queryByText('Уже взятое')).toBeNull();
  expect(ui.getByText('Все (3)')).toBeTruthy();
  fireEvent.click(ui.getByText('Свободные (1)'));
  expect(ui.queryByText('Ваш контракт')).toBeNull();
  fireEvent.click(ui.getAllByText('Взять')[0]);
  expect(sent(ui.topic, 'take')).toEqual([{ uid: 4 }]);
  fireEvent.click(ui.getByText('Мои'));
  expect(ui.container.querySelector('.NtTerm__rankName')?.textContent).toBe('Подрядчик');
  expect(ui.getByText('До ранга «Мастер»: ещё 20')).toBeTruthy();
  expect(ui.getByText('взято 1 из 3, выполнено 4')).toBeTruthy();
  expect(ui.getByText('Ваш контракт')).toBeTruthy();
  expect(ui.getByText('Ваше объявление')).toBeTruthy();
  expect(ui.queryByText('Взять')).toBeNull();
});

test('экипаж: объявления и форма своего уходят в crew_post', () => {
  const contracts = [contract(4, { kind: 'crew', poster: 'Повар', poster_id: 222, department_name: 'Экипаж', title: 'Помыть кухню' })];
  const crew_request = { min: 100, max: 5000, title_max: 60, desc_max: 300, minutes: 30, accept_minutes: 10 };
  const ui = setup({ contracts, rank, crew_request });
  fireEvent.click(ui.container.querySelector('.NtTerm__menu')?.querySelectorAll('.NtTerm__menuItem')[2] as HTMLElement);
  expect(ui.getByText('Объявления экипажа')).toBeTruthy();
  expect(ui.getByText('Помыть кухню')).toBeTruthy();
  fireEvent.click(ui.getByText('Взять'));
  expect(sent(ui.topic, 'take')).toEqual([{ uid: 4 }]);
  fireEvent.click(ui.getByText('Дать объявление'));
  fireEvent.input(ui.getByPlaceholderText('Что нужно сделать'), { target: { value: 'Починить окно' } });
  fireEvent.input(ui.getByPlaceholderText('Подробности: что, куда, к какому сроку'), { target: { value: 'В баре' } });
  fireEvent.click(ui.getByText('Разместить'));
  expect(sent(ui.topic, 'crew_post')).toEqual([{ title: 'Починить окно', desc: 'В баре', reward: 100 }]);
});

test('"Дать объявление" на доске открывает форму на вкладке экипажа', () => {
  const crew_request = { min: 100, max: 5000, title_max: 60, desc_max: 300, minutes: 30, accept_minutes: 10 };
  const ui = setup({ rank, crew_request });
  expect(ui.queryByText('Просит экипаж')).toBeNull();
  fireEvent.click(ui.getByText('Дать объявление'));
  expect(ui.getByText('Объявления экипажа')).toBeTruthy();
  fireEvent.input(ui.getByPlaceholderText('Что нужно сделать'), { target: { value: 'Принести кофе' } });
  fireEvent.input(ui.getByPlaceholderText('Подробности: что, куда, к какому сроку'), { target: { value: 'На мостик' } });
  fireEvent.click(ui.getByText('Разместить'));
  expect(sent(ui.topic, 'crew_post')).toEqual([{ title: 'Принести кофе', desc: 'На мостик', reward: 100 }]);
  document.body.innerHTML = '';
  expect(setup({ crew_request }).queryByText('Дать объявление')).toBeNull();
});

test('спецзаказы партнёров и фильтр доски по отделу', () => {
  const offer = {
    uid: 9,
    partner: 'Коллекционеры',
    partner_id: 'collectors',
    item: 'Редкая монета',
    requirement: 'монета',
    quantity: 2,
    delivered: 1,
    unit_price: 300,
    unit_reward: 400,
    premium: 0,
    reward: 800,
    paid: 0,
    accepted: 0,
    contraband: 0,
    time_left: 600,
  };
  const contracts = [contract(1), contract(6, { department: 'MED', department_name: 'Медицина', title: 'Лечить' })];
  const ui = setup({ contracts, partner_offers: [offer] });
  fireEvent.click(ui.getAllByText('Медицина').find((node) => node.className.includes('NtTerm__chip')) as HTMLElement);
  expect(ui.getByText('Лечить')).toBeTruthy();
  expect(ui.queryByText('Контракт 1')).toBeNull();
  fireEvent.click(ui.getByText('Спецзаказы'));
  expect(ui.getByText('Редкая монета')).toBeTruthy();
  expect(ui.getByText('1 из 2', { exact: false })).toBeTruthy();
});

test('без контрактов на вкладках пусто, но понятно', () => {
  const ui = setup({ contracts: [], rank });
  fireEvent.click(ui.getByText('Мои'));
  expect(ui.getByText('Вы ничего не взяли. Свободные контракты - на вкладке «Доска».')).toBeTruthy();
  fireEvent.click(ui.getByText('Спецзаказы'));
  expect(ui.getByText('Спецзаказов сейчас нет.')).toBeTruthy();
});

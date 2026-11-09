import { act, fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { CargoContent } from './Cargo';
import { CargoExpress } from './CargoExpress';
import { NtosCargo } from './NtosCargo';

jest.mock('common/storage', () => ({ storage: { get: jest.fn(() => Promise.resolve(undefined)), set: jest.fn(() => Promise.resolve()) } }));

const offer = (uid, extra = {}) => ({
  uid,
  partner: 'Гильдия старателей',
  partner_id: 'prospectors',
  item: 'слитки золота',
  requirement: '"слитки золота"',
  quantity: 10,
  delivered: 3,
  unit_price: 60,
  unit_reward: 120,
  premium: 600,
  reward: 1200,
  paid: 180,
  accepted: 0,
  contraband: 0,
  time_left: 125,
  ...extra,
});

const backend = {
  location: 'Станция',
  points: 5000,
  away: 1,
  docked: 1,
  loan: 0,
  loan_dispatched: 0,
  requestonly: 0,
  can_send: 1,
  can_approve_requests: 1,
  can_take_offers: 1,
  self_paid: 0,
  message: 'Сообщение',
  private_markup: 1.1,
  tier_step: 250,
  tier_max: 4,
  manifest_department: null,
  manifest_fee: 12,
  contracts_help: 'Справка о контрактах.',
  supplies: {
    Materials: {
      name: 'Canisters & Materials',
      packs: [
        { name: '50 Metal Sheets', id: '/datum/supply_pack/materials/metal50', goody: 0, commodity: 'Металлы' },
        { name: '50 Glass Sheets', id: '/datum/supply_pack/materials/glass50', goody: 0, commodity: 'Стройматериалы' },
      ],
    },
  },
  prices: {
    '/datum/supply_pack/materials/metal50': [3000, 'prospectors', 1],
    '/datum/supply_pack/materials/glass50': [1500, null, 0],
  },
  cart: [{ id: 11, object: 'Ящик', cost: 700, orderer: 'Тест', paid: 0, pack: '/datum/supply_pack/materials/metal50' }],
  requests: [{ id: 21, object: 'Заявка', cost: 400, orderer: 'Врач', reason: 'Нужно' }],
  department_requests: [{ id: 31, object: 'Инструменты', department: 'Инженерия', orderer: 'СЕ', reason: 'Ремонт', prepaid: 900 }],
  special_offers: [offer(7), offer(8, { accepted: 1, item: 'слитки серебра' })],
  market: {
    price_index: 1.05,
    commodities: [
      { id: 'metals', name: 'Металлы', factor: 1.1, sell: 2.4, hot: 2, demand: 80, history: [1, 1.1, 1.2], buyer: 'Гильдия старателей' },
      { id: 'culture', name: 'Культура', factor: 1, sell: 0, hot: 0, demand: 100, history: [1, 1], buyer: null },
    ],
  },
  partners: [
    { id: 'prospectors', name: 'Гильдия старателей', desc: 'Шахтёры', unlocked: 1, tier: 1, reputation: 300, discount: 3, markup: 0.95, wealth: 15000, next_unlock: null, buys: 'Металлы x1.05', sells: 'Canisters & Materials' },
    { id: 'nakamura', name: 'Накамура Инжиниринг', desc: 'Двигатели', unlocked: 0, tier: 0, reputation: 0, discount: 0, markup: 0.95, wealth: 15000, next_unlock: 'Откроется, когда репутация у партнёра "НТ Логистика" дойдёт до ступени 2.', buys: 'Энергия x1.3', sells: 'Engineering' },
  ],
  contracts: [
    { uid: 1, department: 'CIV', department_name: 'Гражданские', title: 'Контракт 1', desc: 'Описание', reward: 5000, urgent: 0, time_left: null, taken_by: null, taker_id: null, takeable: 1, special: 0, progress: '0/1', rotates_in: null, started: 0 },
  ],
  my_account: 111,
  performer_share: 30,
};

const setup = (data = {}, Component = CargoContent) => {
  let now = Date.now();
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'Cargo' }, data: { ...backend, ...data } }));
  return { ...render(<Component />), topic, store };
};

const sent = (topic, action) =>
  topic.mock.calls
    .map(([message]) => message)
    .filter((message) => message.type === `act/${action}`)
    .map((message) => (message.payload ? JSON.parse(message.payload) : {}));

const openTab = (ui, label: RegExp) => fireEvent.click(ui.getByText(label));

test('заказ пака шлёт прежнее действие add с id, пак без наличия заказать нельзя', () => {
  const ui = setup();
  expect(ui.getByText('Гильдия старателей')).toBeTruthy();
  expect(ui.getByText('нет в наличии')).toBeTruthy();
  fireEvent.click(ui.getByText('3 000 кр.'));
  fireEvent.click(ui.getByText('1 500 кр.'));
  expect(sent(ui.topic, 'add')).toEqual([{ id: '/datum/supply_pack/materials/metal50' }]);
});

test('частичное обновление с таблицей цен меняет цену, поставщика и наличие, каталог остаётся прежним', () => {
  const ui = setup();
  ui.store.dispatch(
    backendUpdate({
      data: {
        prices: {
          '/datum/supply_pack/materials/metal50': [3600, null, 0],
          '/datum/supply_pack/materials/glass50': [1700, 'nakamura', 1],
        },
      },
    }),
  );
  ui.rerender(<CargoContent />);
  expect(ui.getByText('50 Metal Sheets')).toBeTruthy();
  expect(ui.getAllByText('нет в наличии')).toHaveLength(1);
  expect(ui.getByText('Накамура Инжиниринг')).toBeTruthy();
  fireEvent.click(ui.getByText('3 600 кр.'));
  fireEvent.click(ui.getByText('1 700 кр.'));
  expect(sent(ui.topic, 'add')).toEqual([{ id: '/datum/supply_pack/materials/glass50' }]);
});

test('пак без строки в таблице цен недоступен: без цены "0 кр.", заказать нельзя', () => {
  const ui = setup({ prices: { '/datum/supply_pack/materials/metal50': [3000, 'prospectors', 1] } });
  expect(ui.queryByText('0 кр.')).toBeNull();
  expect(ui.getAllByText('нет в наличии')).toHaveLength(1);
  fireEvent.click(ui.getByText('-'));
  fireEvent.click(ui.getByText('3 000 кр.'));
  expect(sent(ui.topic, 'add')).toEqual([{ id: '/datum/supply_pack/materials/metal50' }]);
});

test('частный заказ показывает цену с наценкой и переключается toggleprivate', () => {
  const ui = setup({ self_paid: 1 });
  expect(ui.getByText('3 300 кр.')).toBeTruthy();
  fireEvent.click(ui.getByText('Купить лично'));
  expect(sent(ui.topic, 'toggleprivate')).toHaveLength(1);
});

test('личный каталог: без наценки частного заказа, в поиске пак один раз', () => {
  const corgi = { name: 'Corgi Crate', id: '/datum/supply_pack/critter/corgi', desc: 'Корги', cost: 5000, goody: 0, commodity: null, supplier: 'НТ Логистика', in_stock: 1, personal: 1 };
  const cow = { name: 'Cow Crate', id: '/datum/supply_pack/critter/cow', desc: 'Корова', cost: 3000, goody: 0, commodity: null, supplier: 'НТ Логистика', in_stock: 1 };
  const supplies = {
    Livestock: { name: 'Livestock', packs: [corgi, cow] },
    'Личный каталог': { name: 'Личный каталог', packs: [corgi] },
  };
  const ui = setup({ self_paid: 1, supplies, points: 12345 });
  expect(ui.getByText('3 300 кр.')).toBeTruthy();
  expect(ui.getByText('5 000 кр.')).toBeTruthy();
  fireEvent.click(ui.getByText('Личный каталог (1)'));
  expect(ui.getByText('Без наценки')).toBeTruthy();
  fireEvent.click(ui.getByText('5 000 кр.'));
  expect(sent(ui.topic, 'add')).toEqual([{ id: '/datum/supply_pack/critter/corgi' }]);
  fireEvent.input(ui.getByPlaceholderText('Поиск по названию, описанию и описи'), { target: { value: 'Corgi' } });
  expect(ui.getAllByText('Corgi Crate')).toHaveLength(1);
});

test('вкладка "Рынок" показывает горячий товар с пометкой ×2 и товар без покупателя', () => {
  const ui = setup();
  openTab(ui, /^Рынок$/);
  expect(ui.getByText('горячий ×2')).toBeTruthy();
  expect(ui.getByText('нет покупателя, груз вернётся')).toBeTruthy();
  expect(ui.getByText('Индекс цен: ×1.05')).toBeTruthy();
});

test('вкладка "Партнёры" показывает закрытого партнёра с условием открытия и ступень открытого', () => {
  const ui = setup();
  openTab(ui, /^Партнёры$/);
  expect(ui.getByText('Откроется, когда репутация у партнёра "НТ Логистика" дойдёт до ступени 2.')).toBeTruthy();
  expect(ui.getByText('Закрыт')).toBeTruthy();
  expect(ui.getByText('Ступень 1 из 4')).toBeTruthy();
  expect(ui.getByText('300, до ступени 2: 200')).toBeTruthy();
  expect(ui.queryByText(/Эмбарго/)).toBeNull();
});

test('у партнёра логотип по id из спрайтшита economy_logos', () => {
  const ui = setup();
  openTab(ui, /^Партнёры$/);
  expect(ui.container.querySelector('.economy_logos32x32.logo-prospectors')).not.toBeNull();
  expect(ui.container.querySelector('.economy_logos32x32.logo-nakamura')).not.toBeNull();
});

test('партнёр под эмбарго показывает оставшиеся минуты', () => {
  const ui = setup({
    partners: [{ ...backend.partners[0], embargo_minutes: 17 }, backend.partners[1]],
  });
  openTab(ui, /^Партнёры$/);
  expect(ui.getByText('Эмбарго: ещё 17 мин. партнёр не покупает и не продаёт.')).toBeTruthy();
});

test('спецзаказ: "Принять" шлёт accept_offer с uid, взятый печатает накладную', () => {
  const ui = setup();
  openTab(ui, /^Спецзаказы/);
  fireEvent.click(ui.getByText('Принять'));
  fireEvent.click(ui.getByText('Накладная'));
  expect(sent(ui.topic, 'accept_offer')).toEqual([{ uid: 7 }]);
  expect(sent(ui.topic, 'print_offer_manifest')).toEqual([{ uid: 8 }]);
  expect(ui.getAllByText('3 из 10')).toHaveLength(2);
});

test('спецзаказ партнёра под эмбарго: невзятый не принять, взятый можно выполнить', () => {
  const ui = setup({ special_offers: [offer(7, { embargoed: 1 }), offer(8, { accepted: 1, embargoed: 1, item: 'слитки серебра' })] });
  openTab(ui, /^Спецзаказы/);
  expect(ui.queryByText('Принять')).toBeNull();
  expect(ui.getByText('Партнёр под эмбарго: взять спецзаказ нельзя, пока эмбарго не снимут.')).toBeTruthy();
  expect(ui.getByText('Партнёр под эмбарго, но взятый спецзаказ можно выполнить.')).toBeTruthy();
  fireEvent.click(ui.getByText('Накладная'));
  expect(sent(ui.topic, 'print_offer_manifest')).toEqual([{ uid: 8 }]);
  expect(sent(ui.topic, 'accept_offer')).toEqual([]);
});

test('на КПК спецзаказы только для просмотра, шаттл не отправить', () => {
  const ui = setup({ can_take_offers: 0, can_send: 0, can_edit_cart: 1, is_app: 1 });
  expect(ui.getByText('Шаттл, его аренда и спецзаказы - только с консоли снабжения.')).toBeTruthy();
  openTab(ui, /^Спецзаказы/);
  expect(ui.queryByText('Принять')).toBeNull();
  expect(ui.queryByText('Накладная')).toBeNull();
  expect(ui.getByText(/только на консоли снабжения станции/)).toBeTruthy();
  openTab(ui, /^Корзина/);
  expect(ui.queryByText('Вызвать шаттл с заказом')).toBeNull();
  fireEvent.click(ui.getByText('Очистить'));
  expect(sent(ui.topic, 'clear')).toHaveLength(1);
});

test('аренда шаттла с консоли шлёт loan, на КПК ряда аренды нет', () => {
  const ui = setup({ loan: 1 });
  fireEvent.click(ui.getByText('Сдать шаттл ЦК'));
  expect(sent(ui.topic, 'loan')).toHaveLength(1);
  const app = setup({ loan: 1, is_app: 1, can_send: 0 });
  expect(app.queryByText('Аренда шаттла')).toBeNull();
});

test('заявка с консоли запросов шлёт add с причиной из окна', () => {
  const ui = setup({ requestonly: 1, can_send: 0, can_approve_requests: 0, reason_max: 200 });
  const input = ui.container.querySelector('input[placeholder^="Если оставить"]') as HTMLInputElement;
  fireEvent.input(input, { target: { value: 'Ремонт палаты' } });
  fireEvent.click(ui.getByText('3 000 кр.'));
  expect(sent(ui.topic, 'add')).toEqual([{ id: '/datum/supply_pack/materials/metal50', reason: 'Ремонт палаты' }]);
});

test('приложение NtosCargo открывает окно снабжения', () => {
  const ui = setup({ is_app: 1, can_send: 0, PC_device_theme: 'ntos', PC_programheaders: [] }, NtosCargo);
  expect(ui.getByText(/Бюджет снабжения/)).toBeTruthy();
  expect(ui.getByText('50 Metal Sheets')).toBeTruthy();
});

test('корзина, заявки и заказы отделов шлют прежние действия', () => {
  const ui = setup();
  openTab(ui, /^Корзина/);
  expect(ui.getAllByText('Вызвать шаттл с заказом')).toHaveLength(2);
  fireEvent.click(ui.getAllByText('Вызвать шаттл с заказом')[1]);
  fireEvent.click(ui.getByText('Очистить'));
  fireEvent.click(ui.container.querySelector('.fa-minus') as Element);
  openTab(ui, /^Заявки$/);
  fireEvent.click(ui.getByText('Одобрить'));
  fireEvent.click(ui.getByText('Отклонить'));
  fireEvent.click(ui.getByText('Отклонить все'));
  expect(sent(ui.topic, 'send')).toHaveLength(1);
  expect(sent(ui.topic, 'clear')).toHaveLength(1);
  expect(sent(ui.topic, 'remove')).toEqual([{ id: 11 }]);
  expect(sent(ui.topic, 'approve')).toEqual([{ id: 21 }]);
  expect(sent(ui.topic, 'deny')).toEqual([{ id: 21 }]);
  expect(sent(ui.topic, 'denyall')).toHaveLength(1);
});

test('консоль запросов не правит корзину и не решает заявки', () => {
  const ui = setup({ requestonly: 1, can_send: 0, can_approve_requests: 0 });
  expect(ui.queryByText(/^Корзина/)).toBeNull();
  openTab(ui, /^Заявки$/);
  expect(ui.queryByText('Одобрить')).toBeNull();
  expect(ui.queryByText('Отклонить все')).toBeNull();
});

test('накладная отдела и справка о рынке: строка без тем показывается целиком', () => {
  const ui = setup({ manifest_department: 'Сервис', market_help: 'Ящик пака - залог' });
  fireEvent.click(ui.getByText('Накладная: Сервис'));
  expect(sent(ui.topic, 'print_manifest')).toHaveLength(1);
  expect(ui.queryByText('Ящик пака - залог')).toBeNull();
  openTab(ui, /^Справка$/);
  expect(ui.getByText('Ящик пака - залог')).toBeTruthy();
});

test('справка разбита на темы с отдельными пунктами', () => {
  const ui = setup({
    help_topics: [
      { title: 'Заказ и доставка', icon: 'shopping-cart', lines: ['Ящик пака - залог.', 'Частный заказ дороже на 10%.'] },
      { title: 'Спецзаказы', icon: 'star', lines: ['Срок - 30 мин.'] },
    ],
  });
  openTab(ui, /^Справка$/);
  expect(ui.getByText('Заказ и доставка')).toBeTruthy();
  expect(ui.getByText('Частный заказ дороже на 10%.')).toBeTruthy();
  expect(ui.getByText('Срок - 30 мин.')).toBeTruthy();
});

test('шапка: шаттл в пути с таймером, у ЦК - вызов, на станции - отправка', () => {
  const transit = setup({ shuttle: { state: 'to_station', eta: 84 } });
  expect(transit.getByText(/летит на станцию/)).toBeTruthy();
  expect(transit.getByText('1:24')).toBeTruthy();
  expect(transit.queryByText(/шаттл с заказом/)).toBeNull();
  transit.unmount();
  const home = setup({ shuttle: { state: 'station', eta: 0 } });
  fireEvent.click(home.getByText('Отправить шаттл к ЦК'));
  expect(sent(home.topic, 'send')).toHaveLength(1);
  home.unmount();
  const empty = setup({ shuttle: { state: 'centcom', eta: 0 }, cart: [] });
  expect(empty.getByText('Вызвать шаттл')).toBeTruthy();
});

test('карточка пака: опись, количество и заказ нескольких штук одним add', () => {
  const ui = setup();
  fireEvent.click(ui.getByText('50 Metal Sheets'));
  expect(sent(ui.topic, 'pack_info')).toEqual([{ id: '/datum/supply_pack/materials/metal50' }]);
  expect(ui.getByText('Загружаю описание...')).toBeTruthy();
  ui.store.dispatch(backendUpdate({ data: { pack_info: { id: '/datum/supply_pack/materials/metal50', desc: 'Листы металла', contents: ['metal ×50'] } } }));
  ui.rerender(<CargoContent />);
  expect(ui.getByText('Листы металла')).toBeTruthy();
  expect(ui.getByText('metal ×50')).toBeTruthy();
  const plus = ui.container.querySelector('.NtTerm__detail .fa-plus') as Element;
  fireEvent.click(plus);
  fireEvent.click(plus);
  fireEvent.click(ui.getByText('В корзину за 9 000 кр.'));
  expect(sent(ui.topic, 'add')).toEqual([{ id: '/datum/supply_pack/materials/metal50', amount: 3 }]);
});

test('поиск: до ответа сервера по названию, затем по найденному сервером в описании и описи', () => {
  jest.useFakeTimers();
  const ui = setup();
  fireEvent.input(ui.getByPlaceholderText('Поиск по названию, описанию и описи'), { target: { value: 'Glass' } });
  expect(ui.getByText('50 Glass Sheets')).toBeTruthy();
  expect(ui.queryByText('50 Metal Sheets')).toBeNull();
  fireEvent.input(ui.getByPlaceholderText('Поиск по названию, описанию и описи'), { target: { value: 'листы' } });
  expect(sent(ui.topic, 'search')).toEqual([]);
  act(() => {
    jest.advanceTimersByTime(300);
  });
  expect(sent(ui.topic, 'search')).toEqual([{ text: 'листы' }]);
  ui.store.dispatch(backendUpdate({ data: { search: 'листы', search_hits: ['/datum/supply_pack/materials/metal50'], search_total: 1 } }));
  ui.rerender(<CargoContent />);
  expect(ui.getByText('50 Metal Sheets')).toBeTruthy();
  expect(ui.queryByText('50 Glass Sheets')).toBeNull();
  jest.useRealTimers();
});

test('избранное: звёздочка собирает пак во вкладку "Избранное"', () => {
  const ui = setup();
  fireEvent.click(ui.getByText('Избранное (0)'));
  expect(ui.getByText(/Отметьте звёздочкой/)).toBeTruthy();
  fireEvent.click(ui.getByText('Canisters & Materials (2)'));
  fireEvent.click(ui.container.querySelectorAll('td .fa-star')[0]);
  fireEvent.click(ui.getByText('Избранное (1)'));
  expect(ui.getByText('50 Metal Sheets')).toBeTruthy();
  expect(ui.queryByText('50 Glass Sheets')).toBeNull();
});

test('корзина складывает одинаковые паки, плюс добавляет ещё один, видно остаток бюджета', () => {
  const metal = '/datum/supply_pack/materials/metal50';
  const ui = setup({
    points: 1000,
    cart: [
      { id: 11, object: 'Металл', cost: 700, orderer: 'Тест', paid: 0, pack: metal },
      { id: 12, object: 'Металл', cost: 700, orderer: 'Тест', paid: 0, pack: metal },
      { id: 13, object: 'Металл', cost: 770, orderer: 'Иван', paid: 1, pack: metal },
      { id: 14, object: 'Инструменты (оплачено: Инженерия)', cost: 0, orderer: 'СЕ', paid: 0, pack: '/datum/supply_pack/tools', department: 'Инженерия' },
    ],
  });
  openTab(ui, /^Корзина/);
  expect(ui.getByText('Снабжение')).toBeTruthy();
  expect(ui.getByText('Лично: Иван')).toBeTruthy();
  expect(ui.getByText('Отдел: Инженерия')).toBeTruthy();
  expect(ui.getAllByText('1 400 кр.')).toHaveLength(2);
  expect(ui.getByText('-400 кр.')).toBeTruthy();
  expect(ui.getByText(/Бюджета не хватает на всё/)).toBeTruthy();
  fireEvent.click(ui.container.querySelector('.fa-plus') as Element);
  fireEvent.click(ui.container.querySelector('.fa-minus') as Element);
  expect(sent(ui.topic, 'add')).toEqual([{ id: metal }]);
  expect(sent(ui.topic, 'remove')).toEqual([{ id: 12 }]);
});

test('карточка пака: выбор партнёра меняет цену и уходит в add, показана репутация', () => {
  const ui = setup({
    reputation_per_credit: 0.1,
    prices: {
      '/datum/supply_pack/materials/metal50': [3000, 'prospectors', 1, [['nt_logistics', 3300], ['prospectors', 3000]]],
      '/datum/supply_pack/materials/glass50': [1500, null, 0],
    },
    partners: [...backend.partners, { ...backend.partners[0], id: 'nt_logistics', name: 'НТ Логистика' }],
  });
  fireEvent.click(ui.getByText('50 Metal Sheets'));
  expect(ui.getByText(/НТ Логистика - 3 300 кр\./)).toBeTruthy();
  expect(ui.getByText(/\+165 репутации/)).toBeTruthy();
  fireEvent.click(ui.getByText(/НТ Логистика - 3 300 кр\./));
  fireEvent.click(ui.getByText('В корзину за 3 300 кр.'));
  expect(sent(ui.topic, 'add')).toEqual([{ id: '/datum/supply_pack/materials/metal50', partner: 'nt_logistics' }]);
});

test('закрытый эксклюзив партнёра объясняет, на какой ступени откроется', () => {
  const supplies = {
    Medical: { name: 'Medical', packs: [{ name: 'Хирургический набор Вей-Мед', id: '/x', desc: 'Набор', goody: 0, exclusive: ['Вей-Мед', 2] }] },
  };
  const ui = setup({ supplies, prices: { '/x': [4500, null, 0] } });
  expect(ui.getByText('ступень 2 у Вей-Мед')).toBeTruthy();
  expect(ui.getByText('эксклюзив Вей-Мед')).toBeTruthy();
});

test('аукцион: лот, ставки соперников и ставка станции шлёт auction_bid', () => {
  const ui = setup({
    auction: {
      uid: 4,
      name: 'золотая скрипка',
      desc: 'Скрипка из золота.',
      value: 4000,
      bid: 1700,
      bidder: 'станция "Кило-7"',
      mine: 0,
      min_bid: 1785,
      increment: 85,
      left: 45,
      rivals: 2,
      history: [
        { who: 'станция "Кило-7"', amount: 1700 },
        { who: 'Иван Петров', amount: 1600 },
      ],
    },
    my_balance: 5000,
  });
  fireEvent.click(ui.getByText(/^Аукцион/));
  expect(ui.getByText('Лот: золотая скрипка')).toBeTruthy();
  expect(ui.getByText('осталось 0:45')).toBeTruthy();
  expect(ui.getByText('1 700 кр. - станция "Кило-7"')).toBeTruthy();
  fireEvent.click(ui.getByText('Поставить 1 785 кр.'));
  fireEvent.click(ui.getByText('+2 шага'));
  fireEvent.click(ui.getByText('Поставить 1 955 кр.'));
  expect(sent(ui.topic, 'auction_bid')).toEqual([
    { uid: 4, amount: 1785 },
    { uid: 4, amount: 1955 },
  ]);
});

test('аукцион без лота: когда следующий и итоги прошлых', () => {
  const ui = setup({
    auction: null,
    auction_next: 300,
    auction_results: [{ name: 'корона', winner: 'Иван Петров', price: 2600, ours: 1 }],
  });
  fireEvent.click(ui.getByText(/^Аукцион/));
  expect(ui.getByText(/примерно через 5:00/)).toBeTruthy();
  expect(ui.getByText('наша станция: Иван Петров, 2 600 кр.')).toBeTruthy();
});

test('скупка: пачка только целиком, цена со скидкой, покупка шлёт buy_bundle', () => {
  const ui = setup({
    bundles: [
      {
        uid: 9,
        partner: 'Вей-Мед',
        partner_id: 'vey_med',
        items: ['бинт', 'шина', 'пакет крови', 'скальпель'],
        full_value: 2000,
        price: 1400,
        discount: 30,
        left: 600,
      },
    ],
  });
  fireEvent.click(ui.getByText('Скупка'));
  expect(ui.getByText('4 предмета, только вместе')).toBeTruthy();
  expect(ui.getByText('бинт, шина, пакет крови, скальпель')).toBeTruthy();
  expect(ui.getByText('1 400 кр.')).toBeTruthy();
  expect(ui.getByText('ещё 10:00')).toBeTruthy();
  fireEvent.click(ui.getByText('Купить пачкой'));
  expect(sent(ui.topic, 'buy_bundle')).toEqual([{ uid: 9 }]);
});

test('счётчики дел видны в навигации', () => {
  const ui = setup();
  expect(ui.getByText('Заявки')).toBeTruthy();
  const nav = ui.container.querySelectorAll('.NtTerm__menuCount');
  expect(Array.from(nav).map((badge) => badge.textContent)).toEqual(['1', '1', '2']);
});

test('контракты в консоли снабжения только для просмотра', () => {
  const ui = setup();
  openTab(ui, /^Контракты$/);
  expect(ui.getByText('Контракт 1')).toBeTruthy();
  expect(ui.getByText('Свободен')).toBeTruthy();
  expect(ui.queryByText('Взять')).toBeNull();
});

test('экспресс-консоль показывает каталог из Cargo без наценки частного заказа и заказывает через add', () => {
  const ui = setup(
    {
      locked: 0,
      supplies: {
        Materials: {
          name: 'Canisters & Materials',
          packs: [{ name: '50 Metal Sheets', id: '/datum/supply_pack/materials/metal50', desc: 'Металл', cost: 3000 }],
        },
      },
      usingBeacon: 0,
      hasBeacon: 0,
      beaconzone: '',
      beaconName: 'Нет',
      printMsg: 'Печать',
      canBuyBeacon: 0,
      beacon_only: 0,
      self_paid: 1,
      private_markup: undefined,
    },
    CargoExpress,
  );
  expect(ui.queryByText('Очистить')).toBeNull();
  fireEvent.click(ui.getByText('Купить лично'));
  expect(sent(ui.topic, 'toggleprivate')).toHaveLength(1);
  fireEvent.click(ui.getByText('3 000 кр.'));
  expect(sent(ui.topic, 'add')).toEqual([{ id: '/datum/supply_pack/materials/metal50' }]);
});

test('аукцион: перебитая ставка видна сразу, своя новая ставка убирает сообщение', () => {
  const lot = {
    uid: 4,
    name: 'золотая скрипка',
    desc: 'Скрипка из золота.',
    value: 4000,
    bid: 1700,
    bidder: 'Иван Петров',
    mine: 1,
    min_bid: 1785,
    increment: 85,
    left: 45,
    rivals: 2,
    history: [{ who: 'Иван Петров', amount: 1700 }],
  };
  const ui = setup({ auction: lot });
  fireEvent.click(ui.getByText(/^Аукцион/));
  expect(ui.container.textContent).not.toContain('Вашу ставку перебили');
  expect(ui.container.querySelector('.NtTerm__pulse')).toBeNull();
  ui.store.dispatch(backendUpdate({ data: { auction: { ...lot, bid: 1800, bidder: 'станция "Кило-7"', mine: 0 } } }));
  ui.rerender(<CargoContent />);
  expect(ui.container.textContent?.replace(/\s/g, ' ')).toContain('Вашу ставку перебили: станция "Кило-7", 1 800 кр.; ваши деньги вернулись на счёт.');
  expect(ui.container.querySelector('.NtTerm__pulse--new')?.textContent?.replace(/\s/g, ' ')).toContain('1 800 кр.');
  ui.store.dispatch(backendUpdate({ data: { auction: { ...lot, bid: 1900, mine: 1 } } }));
  ui.rerender(<CargoContent />);
  expect(ui.container.textContent).not.toContain('Вашу ставку перебили');
});

test('новая заявка: счётчик вкладки вспыхивает, когда заявок стало больше, а не при открытии окна', () => {
  const ui = setup();
  const badge = () => Array.from(ui.container.querySelectorAll('.NtTerm__menuItem')).find((node) => node.textContent?.startsWith('Заявки'))?.querySelector('.NtTerm__menuCount');
  const count = Number(badge()?.textContent || 0);
  expect(badge()?.className).not.toContain('NtTerm__menuCount--new');
  const requests = ((ui.store.getState() as any).backend.data.requests || []) as any[];
  ui.store.dispatch(backendUpdate({ data: { requests: [...requests, { id: 99, object: 'Pizza Crate', cost: 100, orderer: 'Анна', reason: 'обед' }] } }));
  ui.rerender(<CargoContent />);
  expect(badge()?.textContent).toBe(String(count + 1));
  expect(badge()?.className).toContain('NtTerm__menuCount--new');
});

import { fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { CargoContent } from './Cargo';
import { CargoExpress } from './CargoExpress';
import { NtosCargo } from './NtosCargo';

const offer = (uid, extra = {}) => ({
  uid,
  partner: 'Гильдия старателей',
  partner_id: 'prospectors',
  item: 'слитки золота',
  requirement: '«слитки золота»',
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
        { name: '50 Metal Sheets', id: '/datum/supply_pack/materials/metal50', desc: 'Металл', goody: 0, commodity: 'Металлы' },
        { name: '50 Glass Sheets', id: '/datum/supply_pack/materials/glass50', desc: 'Стекло', goody: 0, commodity: 'Стройматериалы' },
      ],
    },
  },
  prices: {
    '/datum/supply_pack/materials/metal50': [3000, 'prospectors', 1],
    '/datum/supply_pack/materials/glass50': [1500, null, 0],
  },
  cart: [{ id: 11, object: 'Ящик', cost: 700, orderer: 'Тест', paid: 0 }],
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
    { id: 'nakamura', name: 'Накамура Инжиниринг', desc: 'Двигатели', unlocked: 0, tier: 0, reputation: 0, discount: 0, markup: 0.95, wealth: 15000, next_unlock: 'Откроется, когда репутация у партнёра «НТ Логистика» дойдёт до ступени 2.', buys: 'Энергия x1.3', sells: 'Engineering' },
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

test('пак без строки в таблице цен недоступен: без цены «0 кр.», заказать нельзя', () => {
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
  const ui = setup({ self_paid: 1, supplies });
  expect(ui.getByText('3 300 кр.')).toBeTruthy();
  expect(ui.getByText('5 000 кр.')).toBeTruthy();
  fireEvent.click(ui.getByText('Личный каталог (1)'));
  expect(ui.getByText('Без наценки')).toBeTruthy();
  fireEvent.click(ui.getByText('5 000 кр.'));
  expect(sent(ui.topic, 'add')).toEqual([{ id: '/datum/supply_pack/critter/corgi' }]);
  fireEvent.input(ui.getByPlaceholderText('Поиск...'), { target: { value: 'Corgi' } });
  expect(ui.getAllByText('Corgi Crate')).toHaveLength(1);
});

test('вкладка «Рынок» показывает горячий товар с пометкой ×2 и товар без покупателя', () => {
  const ui = setup();
  openTab(ui, /^Рынок$/);
  expect(ui.getByText('горячий ×2')).toBeTruthy();
  expect(ui.getByText('нет покупателя, груз вернётся')).toBeTruthy();
  expect(ui.getByText('Индекс цен: ×1.05')).toBeTruthy();
});

test('вкладка «Партнёры» показывает закрытого партнёра с условием открытия и ступень открытого', () => {
  const ui = setup();
  openTab(ui, /^Партнёры$/);
  expect(ui.getByText('Откроется, когда репутация у партнёра «НТ Логистика» дойдёт до ступени 2.')).toBeTruthy();
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

test('спецзаказ: «Принять» шлёт accept_offer с uid, взятый печатает накладную', () => {
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
  fireEvent.click(ui.getByText('Вызвать шаттл с заказом'));
  fireEvent.click(ui.getByText('Очистить'));
  fireEvent.click(ui.container.querySelector('.fa-minus') as Element);
  openTab(ui, /^Заявки \(/);
  fireEvent.click(ui.getByText('Одобрить'));
  fireEvent.click(ui.getByText('Отклонить'));
  fireEvent.click(ui.getByText('Отклонить все'));
  openTab(ui, /^Заказы отделов/);
  expect(ui.getByText('Инженерия')).toBeTruthy();
  fireEvent.click(ui.container.querySelector('.fa-undo') as Element);
  expect(sent(ui.topic, 'send')).toHaveLength(1);
  expect(sent(ui.topic, 'clear')).toHaveLength(1);
  expect(sent(ui.topic, 'remove')).toEqual([{ id: 11 }, { id: 31 }]);
  expect(sent(ui.topic, 'approve')).toEqual([{ id: 21 }]);
  expect(sent(ui.topic, 'deny')).toEqual([{ id: 21 }]);
  expect(sent(ui.topic, 'denyall')).toHaveLength(1);
});

test('консоль запросов не правит корзину и не решает заявки', () => {
  const ui = setup({ requestonly: 1, can_send: 0, can_approve_requests: 0 });
  expect(ui.queryByText(/^Корзина/)).toBeNull();
  openTab(ui, /^Заявки \(/);
  expect(ui.queryByText('Одобрить')).toBeNull();
  expect(ui.queryByText('Отклонить все')).toBeNull();
});

test('накладная отдела и справка о рынке', () => {
  const ui = setup({ manifest_department: 'Сервис', market_help: 'Ящик пака - залог' });
  fireEvent.click(ui.getByText('Накладная: Сервис'));
  expect(sent(ui.topic, 'print_manifest')).toHaveLength(1);
  fireEvent.click(ui.getByText('Как работают цены, партнёры и спецзаказы'));
  expect(ui.getByText('Ящик пака - залог')).toBeTruthy();
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

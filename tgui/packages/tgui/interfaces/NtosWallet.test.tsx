import { fireEvent, render, within } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { NtosWalletContent, WalletData } from './NtosWallet';

const base: WalletData = {
  message: '',
  metadollars_available: 1,
  metadollars: 7,
  transfer_max: 50000,
  transfer_cooldown: 5,
  memo_max: 64,
  name_max: 42,
  audit_rights: 'глава СБ и капитан (по доступу ID)',
  owed_cap: 6,
  wage_floor: 30,
  tax_nt_share: 50,
  wage_interval: 10,
  dormant_minutes: 10,
  performer_share: 30,
  contracts_help_topics: [{ title: 'Как выполнить', lines: ['Контракты NT: справка.'] }],
  crew: ['Иван Петров', 'Анна Смирнова'],
  has_account: 1,
  from_card: 1,
  holder: 'Иван Петров',
  number: 123456,
  balance: 1500,
  state: 'active',
  blocked: 0,
  anonymous: 0,
  personal: 1,
  frozen_by: null,
  freeze_reason: null,
  cooldown_left: 0,
  wage: {
    grade: 'средний',
    department: 'Медицина',
    base: 200,
    bonus: 10,
    amount: 220,
    tax_rate: 12,
    owed: 40,
  },
  history: [{ time: '12:00:00', label: 'Зарплата', amount: 220, counterparty: 'Медицина (№111)' }],
  contracts: [
    {
      uid: 7,
      department: 'MED',
      department_name: 'Медицина',
      title: 'Поток пациентов',
      desc: 'Выписать пятерых',
      reward: 1200,
      urgent: 0,
      time_left: null,
      taken_by: null,
      taker_id: null,
      takeable: 1,
      special: 0,
      rotates_in: 300,
      started: 0,
      progress: '0 / 5',
    },
  ],
  my_account: 123456,
  shares: [{ ticker: 'NTRN', name: 'Нанотрейзен', count: 3, value: 450 }],
  portfolio: 450,
};

const setup = (data: Partial<WalletData> = {}) => {
  let now = Date.now();
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'NtosWallet' }, data: { ...base, ...data } }));
  return { ...render(<NtosWalletContent />), topic };
};

const sent = (topic: jest.Mock, action: string) =>
  topic.mock.calls
    .map(([message]) => message)
    .filter((message) => message.type === `act/${action}`)
    .map((message) => JSON.parse(message.payload));

const text = (container: HTMLElement) => (container.textContent || '').replace(/\u00a0/g, ' ');

describe('NtosWallet', () => {
  test('счёт: баланс, расшифровка зарплаты, налог, долг и аудит', () => {
    const { container } = setup();
    const content = text(container);
    expect(content).toContain('Иван Петров, счёт №123456');
    expect(content).toContain('1 500 кр.');
    expect(content).toContain('Налог 12%');
    expect(content).toContain('50% налога забирает NT, остальное получает казна');
    expect(content).toContain('раз в 10 мин.');
    expect(content).toContain('Отдел должен');
    expect(content).toContain('до 6 базовых окладов');
    expect(content).toContain('меньше 30 кр., NT доплачивает');
    expect(content).toContain('Финансовый аудит (глава СБ и капитан (по доступу ID))');
    expect(content).toContain('серия частых переводов одному человеку');
    expect(content).toContain('Медицина (№111)');
  });

  test('без оклада или отдела - минимум NT, а не "не начисляется"', () => {
    const fired = text(setup({ wage: { ...base.wage!, grade: null, department: null, amount: 0, floor_only: 1 } }).container);
    expect(fired).toContain('Оклада нет: отдел не платит, NT платит минимум 30 кр. раз в 10 мин.');
    expect(fired).not.toContain('Не начисляется');
    document.body.innerHTML = '';
    const graded = text(setup({ wage: { ...base.wage!, department: null, floor_only: 1 } }).container);
    expect(graded).toContain('Грейд средний, но отдел не назначен');
    expect(graded).not.toContain('220 кр. раз в');
  });

  test('заморозка показывает, кто и почему', () => {
    const { container } = setup({
      state: 'frozen',
      frozen_by: 'Ник Ли, Detective',
      freeze_reason: 'дробление',
      freeze_source: 'финансовым аудитом (Ник Ли, Detective)',
    });
    expect(text(container)).toContain('Счёт заморожен финансовым аудитом (Ник Ли, Detective): дробление.');
    const admin = setup({
      state: 'frozen',
      frozen_by: 'Центральное командование NT',
      freeze_reason: 'проверка',
      freeze_source: 'Центральным командованием NT, разморозить может только ЦК',
    });
    expect(text(admin.container)).toContain('Счёт заморожен Центральным командованием NT, разморозить может только ЦК: проверка.');
    expect(text(admin.container)).not.toContain('финансовым аудитом');
    expect(text(container)).toContain('базовых окладов) и придёт с первой зарплатой после разморозки');
  });

  test('без счёта - просьба вставить карту, метадоллары доступны', () => {
    const { container, getByText } = setup({ has_account: 0 });
    expect(text(container)).toContain('вставьте в КПК ID-карту со счётом');
    fireEvent.click(getByText('Метадоллары'));
    expect(text(container)).toContain('7 M$');
  });

  test('перевод и чаевые шлют получателя, сумму и назначение', () => {
    const { container, getByText, getByPlaceholderText, topic } = setup({ cooldown_left: 3 });
    fireEvent.click(getByText('Перевод'));
    expect(text(container)).toContain('до 50 000 кр. за раз, не чаще раза в 5 с');
    expect(text(container)).toContain('Следующий платёж через 3 с.');
    fireEvent.input(getByPlaceholderText('Имя или номер счёта'), { target: { value: ' Анна Смирнова ' } });
    fireEvent.input(getByPlaceholderText('Необязательно, только для перевода'), { target: { value: 'за обед' } });
    const amount = container.querySelectorAll('input')[1];
    fireEvent.focus(amount);
    fireEvent.input(amount, { target: { value: '250' } });
    fireEvent.blur(amount);
    fireEvent.click(getByText('Перевести'));
    fireEvent.click(getByText('Чаевые'));
    expect(sent(topic, 'transfer')).toEqual([{ target: 'Анна Смирнова', amount: 250, memo: 'за обед' }]);
    expect(sent(topic, 'tip')).toEqual([{ target: 'Анна Смирнова', amount: 250 }]);
  });

  test('подработка: взять контракт шлёт take с uid', () => {
    const { container, getByText, topic } = setup();
    fireEvent.click(getByText('Подработка'));
    expect(text(container)).not.toContain('Контракты NT: справка.');
    fireEvent.click(getByText('Как это работает'));
    expect(text(container)).toContain('Контракты NT: справка.');
    expect(text(container)).not.toContain('Взявший контракт получает');
    expect(text(container)).toContain('1 200 кр.');
    fireEvent.click(getByText('Взять'));
    expect(sent(topic, 'take')).toEqual([{ uid: 7 }]);
  });

  const crewRequest = (uid: number, extra = {}) => ({
    ...base.contracts![0],
    uid,
    kind: 'crew' as const,
    department_name: 'Экипаж',
    title: `Объявление ${uid}`,
    poster: 'Заказчик',
    poster_id: 333,
    ...extra,
  });

  test('подработка: на вкладке видно, сколько чужих объявлений ждёт исполнителя', () => {
    const { getByText } = setup({
      contracts: [crewRequest(1), crewRequest(2), crewRequest(3, { taken_by: 'Другой', taker_id: 222 }), crewRequest(4, { poster_id: 123456 })],
    });
    expect(getByText('Подработка (2)')).toBeTruthy();
    document.body.innerHTML = '';
    expect(setup().getByText('Подработка')).toBeTruthy();
  });

  const personal = {
    personal_catalog: [
      {
        name: 'Питомцы',
        packs: [{ id: '/datum/supply_pack/critter/corgi', name: 'Corgi Crate', desc: 'Верный друг.', contents: ['корги'] }],
      },
      {
        name: 'Праздник и угощение',
        packs: [
          { id: '/datum/supply_pack/organic/party', name: 'Party Equipment', contents: ['пиво ×4', 'шейкер'] },
          { id: '/datum/supply_pack/organic/randomized/candy', name: 'Candy Crate', contents: ['леденец', 'пончик'], random: 10 },
        ],
      },
    ],
    personal_order_limit: 5,
    personal_prices: {
      '/datum/supply_pack/critter/corgi': [1200, 1] as [number, number],
      '/datum/supply_pack/organic/party': [900, 0] as [number, number],
      '/datum/supply_pack/organic/randomized/candy': [2600, 1] as [number, number],
    },
    personal_orders: [],
    personal_in_transit: [],
    shuttle: { state: 'centcom' as const, eta: 0 },
  };

  test('заказы: каталог по разделам с ценой, заказ оплачивается после подтверждения', () => {
    const { container, getByText, getAllByText, topic } = setup(personal);
    fireEvent.click(getByText('Заказы'));
    const content = text(container);
    expect(content).toContain('Цена партнёра без наценки частного заказа списывается сразу');
    expect(content).toContain('Ждать шаттла могут до 5 ваших заказов сразу');
    expect(content).toContain('Шаттл снабжения у ЦК: заказ погрузят, когда снабжение вызовет его на станцию.');
    expect(content).toContain('Corgi Crate');
    expect(content).toContain('1 200 кр.');
    fireEvent.click(getByText('Corgi Crate'));
    expect(text(container)).toContain('Верный друг.');
    expect(text(container)).toContain('Внутри: корги.');
    fireEvent.click(getByText('Candy Crate'));
    expect(text(container)).toContain('Случайные 10 шт. из набора: леденец, пончик.');
    const [corgi, party, candy] = getAllByText('Заказать');
    expect(party.closest('.Button')?.className).toContain('Button--disabled');
    expect(candy.closest('.Button')?.className).toContain('Button--disabled');
    fireEvent.click(corgi);
    expect(sent(topic, 'personal_order')).toEqual([]);
    fireEvent.click(getByText('Оплатить 1 200 кр.?'));
    expect(sent(topic, 'personal_order')).toEqual([{ id: '/datum/supply_pack/critter/corgi', price: 1200 }]);
    fireEvent.click(getAllByText('Праздник и угощение')[0]);
    expect(text(container)).not.toContain('Corgi Crate');
    expect(text(container)).toContain('Party Equipment');
  });

  test('заказы: свои заказы отменяются с подтверждением, у предела кнопки заказа гаснут', () => {
    const orders = [1, 2, 3, 4, 5].map((id) => ({ id, name: 'Corgi Crate', price: 1200 }));
    const { container, getByText, getAllByText, topic } = setup({
      ...personal,
      personal_orders: orders,
      personal_in_transit: ['№9 Jukebox'],
      shuttle: { state: 'to_station', eta: 150 },
    });
    fireEvent.click(getByText('Заказы'));
    const content = text(container);
    expect(content).toContain('№1 Corgi Crate');
    expect(content).toContain('Уже летит на станцию: №9 Jukebox.');
    expect(content).toContain('новый заказ полетит следующим рейсом. До посадки на станции: 3 мин.');
    for (const button of getAllByText('Заказать')) {
      expect(button.closest('.Button')?.className).toContain('Button--disabled');
    }
    fireEvent.click(getAllByText('Отменить')[0]);
    fireEvent.click(getByText('Отменить и вернуть деньги?'));
    expect(sent(topic, 'personal_cancel')).toEqual([{ id: 1 }]);
  });

  test.each([
    ['to_station', 'До посадки на станции: 3 мин.'],
    ['to_centcom', 'До ЦК: 3 мин.'],
    ['recharging', 'Будет готов через 3 мин.'],
  ] as const)('заказы: время шаттла в состоянии %s подписано по делу', (state, expected) => {
    const { container, getByText } = setup({ ...personal, shuttle: { state, eta: 150 } });
    fireEvent.click(getByText('Заказы'));
    const content = text(container);
    expect(content).toContain(expected);
    if (state !== 'to_station') {
      expect(content).not.toContain('До посадки');
    }
  });

  test('заказы: подарок уходит с получателем, ценой и выбором подписи, в своих заказах видно, кому он', () => {
    const { container, getByText, getAllByText, topic } = setup({
      ...personal,
      personal_orders: [{ id: 4, name: 'Corgi Crate', price: 1200, gift_to: 'Анна Смирнова' }],
    });
    fireEvent.click(getByText('Заказы'));
    expect(text(container)).toContain('№4 Corgi Crate - подарок для Анна Смирнова');
    const picker = container.querySelector('.Dropdown__control') as HTMLElement;
    expect(picker.textContent).toContain('Себе');
    fireEvent.click(picker);
    const menu = within(container.querySelector('.Dropdown__menu') as HTMLElement);
    expect(menu.queryByText('Иван Петров')).toBeNull();
    fireEvent.click(menu.getByText('Анна Смирнова'));
    expect(text(container)).toContain('Подарок для Анна Смирнова: платите вы');
    expect(text(container)).toContain('посылка от вас');
    fireEvent.click(getAllByText('Подарить')[0]);
    fireEvent.click(getByText('Подарить за 1 200 кр.?'));
    fireEvent.click(getByText('Подписать моим именем'));
    expect(text(container)).toContain('без вашего имени');
    fireEvent.click(getByText('Подарить за 1 200 кр.?'));
    expect(sent(topic, 'personal_order')).toEqual([
      { id: '/datum/supply_pack/critter/corgi', price: 1200, recipient: 'Анна Смирнова', hide_name: false },
      { id: '/datum/supply_pack/critter/corgi', price: 1200, recipient: 'Анна Смирнова', hide_name: true },
    ]);
  });

  test('заказы: получателя подарка можно указать номером счёта, которого нет в списке', () => {
    const { getByText, getAllByText, getByPlaceholderText, topic } = setup(personal);
    fireEvent.click(getByText('Заказы'));
    fireEvent.input(getByPlaceholderText('Себе, или имя либо номер счёта получателя'), { target: { value: '4521' } });
    fireEvent.click(getAllByText('Подарить')[0]);
    fireEvent.click(getByText('Подарить за 1 200 кр.?'));
    expect(sent(topic, 'personal_order')).toEqual([
      { id: '/datum/supply_pack/critter/corgi', price: 1200, recipient: '4521', hide_name: false },
    ]);
  });

  const lot = (uid: number, extra = {}) => ({
    uid,
    name: `Лот ${uid}`,
    desc: 'Описание лота.',
    value: 0,
    bid: 0,
    bidder: null,
    mine: 0,
    outbid: 0,
    min_bid: 100,
    increment: 25,
    left: 125,
    history: [],
    seller: 'аноним',
    my_lot: 0,
    ...extra,
  });

  const auction = {
    auction_fee: 10,
    auction_lots_per_account: 2,
    auction: { ...lot(1, { name: 'корона', value: 2500, rivals: 2, bid: 1200, bidder: 'станция "Кило-7"', min_bid: 1260 }), seller: undefined },
    crew_lots: [
      lot(2, { name: 'гитара', seller: 'Анна Смирнова', bid: 150, bidder: 'Иван Петров', mine: 1, min_bid: 175 }),
      lot(3, {
        name: 'шляпа',
        outbid: 1,
        bid: 300,
        bidder: 'Анна Смирнова',
        min_bid: 325,
        left: 40,
        history: [
          { who: 'Анна Смирнова', amount: 300 },
          { who: 'Иван Петров', amount: 250 },
        ],
      }),
      lot(4, { name: 'ваза', my_lot: 1, seller: 'Иван Петров' }),
      lot(5, { name: 'рояль', min_bid: 5000 }),
    ],
  };

  test('заказы: аукцион сектора и экипажа, ставка с подтверждением, перебитая ставка, снятие своего лота', () => {
    const { container, getByText, topic } = setup({ ...personal, ...auction });
    fireEvent.click(getByText('Заказы'));
    const content = text(container);
    expect(content).toContain('NT берёт 10% с продажи; лотов сразу - до 2 на человека');
    expect(content).toContain('аукцион сектора');
    expect(content).toContain('продаёт Анна Смирнова');
    expect(content).toContain('ставка 150 кр. - ваша');
    expect(content).toContain('ставка 300 кр. - Анна Смирнова; вашу ставку перебили');
    expect(content).toContain('ваш лот');
    expect(content).toContain('ставок нет, старт 100 кр.');
    expect(content).toContain('0:40');
    expect(getByText('Ставка 5 000 кр.').closest('.Button')?.className).toContain('Button--disabled');
    expect(getByText('Поднять до 175 кр.')).toBeTruthy();
    fireEvent.click(getByText('Ставка 1 260 кр.'));
    expect(sent(topic, 'auction_bid')).toEqual([]);
    fireEvent.click(getByText('Поставить 1 260 кр.?'));
    expect(sent(topic, 'auction_bid')).toEqual([{ uid: 1, amount: 1260 }]);
    fireEvent.click(getByText('Снять'));
    fireEvent.click(getByText('Снять лот?'));
    expect(sent(topic, 'auction_cancel')).toEqual([{ uid: 4 }]);
  });

  test('заказы: раскрытый лот показывает описание и ставки, ставка своей суммы', () => {
    const { container, getByText, topic } = setup({ ...personal, ...auction });
    fireEvent.click(getByText('Заказы'));
    expect(text(container)).not.toContain('Иван Петров 250 кр.');
    fireEvent.click(getByText('шляпа'));
    expect(text(container)).toContain('Описание лота.');
    expect(text(container)).toContain('Ставки: Анна Смирнова 300 кр., Иван Петров 250 кр.');
    fireEvent.click(getByText('корона'));
    expect(text(container)).toContain('Оценка лота 2 500 кр., торгуются ещё 2 станции сектора.');
    fireEvent.click(getByText('Поставить 325 кр.'));
    expect(sent(topic, 'auction_bid')).toEqual([{ uid: 3, amount: 325 }]);
  });

  test('заказы: лот экипажа покупают сразу с подтверждением, у цены выкупа ставка пропадает, надпись видна раскрытой', () => {
    const { container, getByText, getAllByText, queryByText, topic } = setup({
      ...personal,
      ...auction,
      auction: null,
      crew_lots: [
        lot(6, { name: 'гитара', buyout: 400, inscription: 'Гитара Вована' }),
        lot(7, { name: 'ваза', buyout: 400, bid: 390, bidder: 'Анна Смирнова', min_bid: 415 }),
        lot(8, { name: 'рояль', buyout: 5000 }),
      ],
    });
    fireEvent.click(getByText('Заказы'));
    expect(getAllByText('Ставка 100 кр.')).toHaveLength(2);
    expect(queryByText('Ставка 415 кр.')).toBeNull();
    expect(getByText('Купить за 5 000 кр.').closest('.Button')?.className).toContain('Button--disabled');
    expect(text(container)).not.toContain('Гитара Вована');
    fireEvent.click(getByText('гитара'));
    expect(text(container)).toContain('На вещи надпись: Гитара Вована');
    expect(text(container)).toContain('Купить сразу, без торгов: 400 кр.');
    fireEvent.click(getAllByText('Купить за 400 кр.')[0]);
    expect(sent(topic, 'auction_buyout')).toEqual([]);
    fireEvent.click(getByText('Купить сразу за 400 кр.?'));
    expect(sent(topic, 'auction_buyout')).toEqual([{ uid: 6 }]);
  });

  test('заказы: без лотов аукцион говорит, когда следующий лот сектора', () => {
    const { container, getByText } = setup({ ...personal, auction: null, crew_lots: [], auction_next: 300, auction_fee: 10 });
    fireEvent.click(getByText('Заказы'));
    expect(text(container)).toContain('Лотов сейчас нет. Следующий лот сектора - примерно через 5 мин.');
  });

  test('акции: портфель и позиции', () => {
    const { container, getByText } = setup();
    fireEvent.click(getByText('Акции'));
    expect(text(container)).toContain('NTRN');
    expect(text(container)).toContain('3 шт.');
    expect(text(container)).toContain('450 кр.');
  });

  test('метадоллары: снять и зачислить', () => {
    const { container, getByText, topic } = setup();
    fireEvent.click(getByText('Метадоллары'));
    expect(text(container)).toContain('Кредиты в M$ и обратно не обмениваются');
    const amount = container.querySelector('input') as HTMLInputElement;
    fireEvent.focus(amount);
    fireEvent.input(amount, { target: { value: '3' } });
    fireEvent.blur(amount);
    fireEvent.click(getByText('Снять'));
    fireEvent.click(getByText('Зачислить стопку из руки'));
    expect(sent(topic, 'md_withdraw')).toEqual([{ amount: 3 }]);
    expect(sent(topic, 'md_deposit')).toHaveLength(1);
  });

  test('лотерея: условия, выигрыш и покупка билетов', () => {
    const lottery = { price: 100, house_share: 30, per_account: 10, sold: 12, prize: 840, minutes_left: 7, mine: 6 };
    const { container, getByText, topic } = setup({ lottery });
    const content = text(container);
    expect(content).toContain('Лотерея сектора');
    expect(content).toContain('ваших 6 из 10');
    expect(content).toContain('840 кр.');
    expect(content).toContain('через 7 мин.');
    expect(content).toContain('70% всех продаж, 30% забирает NT');
    fireEvent.click(getByText('Купить билет'));
    expect(sent(topic, 'lottery_buy')).toEqual([{ count: 1 }]);
    expect(getByText('Купить 5').closest('.Button')?.className).toContain('Button--disabled');
  });

  test('без лотереи раздела нет', () => {
    const { container } = setup({ lottery: null });
    expect(text(container)).not.toContain('Лотерея сектора');
  });

  test('нет связи с M$ - вкладка говорит об этом', () => {
    const { container, getByText } = setup({ metadollars_available: 0 });
    fireEvent.click(getByText('Метадоллары'));
    expect(text(container)).toContain('Нет связи с вашим счётом метадолларов.');
  });
});

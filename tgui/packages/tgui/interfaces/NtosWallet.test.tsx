import { fireEvent, render } from '@testing-library/react';
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
    fireEvent.click(getByText('Оплатить?'));
    expect(sent(topic, 'personal_order')).toEqual([{ id: '/datum/supply_pack/critter/corgi' }]);
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
    expect(content).toContain('новый заказ полетит следующим рейсом. До посадки: 3 мин.');
    for (const button of getAllByText('Заказать')) {
      expect(button.closest('.Button')?.className).toContain('Button--disabled');
    }
    fireEvent.click(getAllByText('Отменить')[0]);
    fireEvent.click(getByText('Отменить и вернуть деньги?'));
    expect(sent(topic, 'personal_cancel')).toEqual([{ id: 1 }]);
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

import { fireEvent, render, within } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { NtosStockExchangeContent, StockExchangeData } from './NtosStockExchange';
import { StockTerminal } from './StockTerminal';

const base: StockExchangeData = {
  companies: [
    { ticker: 'VYMD', name: 'Вей-Мед', price: 120, change: 4.2, halted: 0, base_price: 120, max_buy: 37 },
    { ticker: 'CYBS', name: 'Киберсан', price: 4, change: -60, halted: 1, base_price: 90 },
    { ticker: 'NKMR', name: 'Накамура', price: 140, change: 0, halted: 0, base_price: 140, dividend_pool: 30, dividend_per_share: 30 },
    { ticker: 'SECT', name: 'Индекс сектора', price: 98.5, change: -1.5, halted: 0, base_price: 100, index: 1 },
  ],
  history: { VYMD: [100, 110, 120], CYBS: [], NKMR: [140, 140] },
  drivers: {
    VYMD: [
      { label: 'Случайные колебания за минуту', effect: null, note: 'около ±2.5%' },
      { label: 'Продажи станции через снабжение партнёру "Вей-Мед"', effect: 15, upto: 1, note: 'медикаменты; +5% за каждые 1000 кр. продаж' },
      { label: 'Сорванный станцией спецзаказ "Вей-Мед"', effect: -5 },
      {
        label: 'Работа станции: выписка пациентов, реанимация',
        effect: 20,
        upto: 1,
        note: '+1% за каждые 100 кр., что отдел получил за эту работу; в следующую смену не переходит',
      },
      { label: 'Вспышка болезни на станции', effect: 20 },
    ],
    CYBS: [],
    NKMR: [{ label: 'Расслоение суперматерии на станции', effect: 10 }],
  },
  moves: {
    VYMD: [
      { text: 'медики выписывают пациентов', effect: 3, time: '14:32' },
      { text: 'Расслоение суперматерии на станции', effect: -12.5, time: '14:05' },
    ],
  },
  work_cap: 20,
  common_drivers: [
    { label: 'Обвал рынка сектора', effect: -20 },
    { label: 'Бум в секторе', effect: 10 },
  ],
  event_min: -20,
  event_max: 25,
  station_event_cooldown: 10,
  has_account: 1,
  account_name: 'Иван Петров',
  holdings: { VYMD: 3, CYBS: 2 },
  cooldowns: { NKMR: 12 },
  balance: 5000,
  portfolio: 368,
  realized: -45,
  frozen: 0,
  can_treasury: 0,
  using_treasury: 0,
  message: '',
  fee: 2,
  spread: 1,
  cooldown: 30,
  position_cap: 10000,
  personal_cap: 10000,
  treasury_cap_mult: 5,
  halt_ratio: 5,
  halt_minutes: 10,
  relist_ratio: 20,
  news_channel: 'Сводка сектора',
  news_delay: 7,
  refute_minutes: 5,
  persist_decay: 20,
  orders: [],
  orders_max: 5,
  dividend_share: 5,
  payroll_minutes: 10,
};

const setup = (data: Partial<StockExchangeData> = {}, component = <NtosStockExchangeContent />) => {
  let now = Date.now();
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'NtosStockExchange' }, data: { ...base, ...data } }));
  return { ...render(component), topic, store };
};

const sent = (topic: jest.Mock, action: string) =>
  topic.mock.calls
    .map(([message]) => message)
    .filter((message) => message.type === `act/${action}`)
    .map((message) => JSON.parse(message.payload));

const openPage = (container: HTMLElement, label: string) => {
  const item = Array.from(container.querySelectorAll('.NtTerm__menuItem')).find((node) => (node.textContent || '').includes(label));
  fireEvent.click(item as Element);
};

/** Весь текст окна вместе с пояснениями, свёрнутыми под "?". */
const text = (container: HTMLElement) => {
  container.querySelectorAll('.NtTerm__helpToggle:not(.NtTerm__helpToggle--open)').forEach((toggle) => fireEvent.click(toggle));
  return (container.textContent || '').replace(/\u00a0/g, ' ');
};

const framed = (container: HTMLElement, title: string) =>
  Array.from(container.querySelectorAll('.NtTerm__frame')).find((node) =>
    (node.querySelector('.NtTerm__frameTitle')?.textContent || '') === title) as HTMLElement;

const commit = (input: Element, value: string) => {
  fireEvent.focus(input);
  fireEvent.input(input, { target: { value } });
  fireEvent.blur(input);
};

const pick = (frame: HTMLElement, index: number, option: string) => {
  fireEvent.click(frame.querySelectorAll('.Dropdown__control')[index]);
  fireEvent.click(within(frame.querySelector('.Dropdown__menu') as HTMLElement).getByText(option));
};

const selectTile = (container: HTMLElement, ticker: string) => {
  const tile = Array.from(container.querySelectorAll('.NtTerm__tile')).find((node) =>
    (node.querySelector('.NtTerm__tileHead')?.textContent || '').startsWith(ticker),
  );
  fireEvent.click(tile as Element);
};

describe('NtosStockExchange', () => {
  test('плитка у каждой компании, выбранная - с графиком из статической истории; без истории - надпись вместо графика', () => {
    const { container } = setup({ history: { VYMD: [100, 110, 120], NKMR: [140, 140] } });
    expect(container.querySelectorAll('.NtTerm__tile')).toHaveLength(4);
    expect(container.querySelector('.NtTerm__tile--selected')?.textContent).toContain('VYMD');
    expect(container.querySelectorAll('.NtTerm__chart svg')).toHaveLength(1);
    selectTile(container, 'CYBS');
    expect(text(container)).toContain('история появится через минуту');
  });

  test('у выбранной компании логотип по тикеру из спрайтшита economy_logos', () => {
    const { container } = setup();
    expect(container.querySelector('.economy_logos32x32.logo-vymd')).not.toBeNull();
    selectTile(container, 'CYBS');
    expect(container.querySelector('.economy_logos32x32.logo-cybs')).not.toBeNull();
  });

  test('купить, ×10, продать и продать всё шлют тикер и количество', () => {
    const { getAllByText, topic } = setup();
    fireEvent.click(getAllByText('Купить')[0]);
    fireEvent.click(getAllByText('×10')[0]);
    fireEvent.click(getAllByText('Продать')[0]);
    fireEvent.click(getAllByText('Продать всё')[0]);
    expect(sent(topic, 'buy')).toEqual([
      { ticker: 'VYMD', count: 1 },
      { ticker: 'VYMD', count: 10 },
    ]);
    expect(sent(topic, 'sell')).toEqual([
      { ticker: 'VYMD', count: 1 },
      { ticker: 'VYMD', count: 'max' },
    ]);
  });

  test('"Макс" показывает доступный объём и просит сервер посчитать его заново', () => {
    const { getByText, topic } = setup();
    fireEvent.click(getByText('Макс (37)'));
    expect(sent(topic, 'buy')).toEqual([{ ticker: 'VYMD', count: 'max' }]);
  });

  test('остановленные торги и кулдаун убирают кнопки', () => {
    const { container, queryByText } = setup();
    expect(container.querySelector('.NtTerm__tiles')?.textContent).toContain('стоп');
    selectTile(container, 'CYBS');
    expect(text(container)).toContain('Торги остановлены');
    expect(queryByText('Купить')).toBeNull();
    selectTile(container, 'NKMR');
    expect(text(container)).toContain('Следующая сделка через 12 с');
    expect(queryByText('Купить')).toBeNull();
  });

  test('счёт: баланс, стоимость акций, прибыль и позиция', () => {
    const { container } = setup();
    const content = text(container);
    expect(content).toContain('Личный счёт');
    expect(content).toContain('Иван Петров');
    expect(content).toContain('5 000 кр.');
    expect(content).toContain('368 кр.');
    expect(content).toContain('-45 кр.');
    expect(content).toContain('3 шт. на 360 кр.');
  });

  test('правила биржи берут числа из данных', () => {
    const { container } = setup();
    openPage(container, 'Правила');
    const content = text(container);
    expect(content).toContain('в канале "Сводка сектора" на ньюскастерах не сразу, а в течение примерно 7 мин. после скачка цены');
    expect(content).toContain('Через 5 мин. после выхода NT публикует опровержение, и цена возвращается');
    expect(content).toContain('спред 1%');
    expect(content).toContain('комиссия 2%');
    expect(content).toContain('не чаще раза в 30 с');
    expect(content).toContain('не больше чем на 10 000 кр.; акции считаются по цене не ниже базовой');
    expect(content).toContain('ниже 5% базовой, торги останавливаются на 10 мин.');
    expect(content).toContain('по 20% базовой');
    expect(content).toContain('стоимость позиции сохраняется');
    expect(content).toContain('сдвигаясь на 20% к базовой');
    expect(content).toContain('крупные сделки с акциями компании перед новостью о ней или до опровержения фальшивки');
    expect(content).not.toContain('2 000');
    expect(content).toContain('только капитан');
  });

  test('сноски: у компании видно, что и насколько двигает её цену', () => {
    const { container } = setup();
    openPage(container, 'От чего зависит цена');
    const content = text(container);
    expect(content).toContain('От чего зависит цена');
    expect(content).toContain('Новости компании: от −20% до +25%');
    expect(content).toContain('Обвал рынка сектора: −20%');
    expect(content).toContain('Бум в секторе: +10%');
    expect(content).toContain('не чаще раза в 10 мин.');
    expect(content).toContain('Случайные колебания за минуту: около ±2.5%');
    expect(content).toContain('Продажи станции через снабжение партнёру "Вей-Мед": до +15% (медикаменты; +5% за каждые 1000 кр. продаж)');
    expect(content).toContain('Сорванный станцией спецзаказ "Вей-Мед": −5%');
    expect(content).toContain('Вспышка болезни на станции: +20%');
    expect(content).toContain('Расслоение суперматерии на станции: +10%');
  });

  test('лента причин у выбранной компании: время, причина и сдвиг, новые сверху; без скачков и у индекса - пояснение', () => {
    const { container } = setup();
    const lines = Array.from(container.querySelectorAll('.NtTerm__line')).map((node) => (node.textContent || '').replace(/\u00a0/g, ' '));
    expect(lines[0]).toContain('14:32 медики выписывают пациентов');
    expect(lines[0]).toContain('+3%');
    expect(lines[1]).toContain('14:05 Расслоение суперматерии на станции');
    expect(lines[1]).toContain('−12.5%');
    expect(container.querySelector('.NtTerm__line--good')?.textContent).toContain('+3%');
    expect(container.querySelector('.NtTerm__line--bad')?.textContent).toContain('−12.5%');
    selectTile(container, 'NKMR');
    expect(text(container)).toContain('Скачков пока не было');
    selectTile(container, 'SECT');
    expect(text(container)).toContain('Индекс движется вместе с компаниями сектора');
  });

  test('ленты и потолка работы нет в данных - окно не ломается', () => {
    const { container } = setup({ moves: undefined as any, work_cap: undefined as any });
    expect(text(container)).toContain('Скачков пока не было');
  });

  test('работа отделов: сноска компании и потолок за смену в правилах', () => {
    const { container } = setup();
    openPage(container, 'От чего зависит цена');
    let content = text(container);
    expect(content).toContain('Работа станции: выписка пациентов, реанимация: до +20% (+1% за каждые 100 кр., что отдел получил за эту работу');
    expect(content).toContain('не больше чем на 20% за смену в каждую сторону');
    openPage(container, 'Правила');
    content = text(container);
    expect(content).toContain('Работа отделов поднимает связанные компании');
    expect(content).toContain('не больше чем на 20% за смену, и в следующую смену этот сдвиг не переходит');
  });

  test('портфель: позиция по текущей цене', () => {
    const { container } = setup();
    openPage(container, 'Портфель');
    expect(text(container)).toContain('VYMD Вей-Мед, 3 шт. по 120.00');
    expect(text(container)).toContain('360 кр.');
  });

  test('сноски без данных от сервера не ломают окно', () => {
    const { container } = setup({ drivers: undefined as any, common_drivers: undefined as any });
    expect(text(container)).toContain('Котировки');
  });

  test('кратность лимита казны согласуется с числом', () => {
    for (const [mult, word] of [[5, 'раз'], [3, 'раза'], [22, 'раза']] as const) {
      const { container, unmount } = setup({ treasury_cap_mult: mult });
      openPage(container, 'Правила');
      expect(text(container)).toContain(`лимит в ${mult} ${word} больше личного`);
      unmount();
    }
  });

  test('без права на казну переключателя нет', () => {
    const { queryByText } = setup();
    expect(queryByText('Торговать из казны')).toBeNull();
  });

  test('капитан переключает торговлю из казны', () => {
    const { container, getByText, topic } = setup({ can_treasury: 1, using_treasury: 1, account_name: 'Казна станции', position_cap: 50000 });
    expect(text(container)).toContain('Казна станции');
    fireEvent.click(getByText('Торговать из казны'));
    openPage(container, 'Правила');
    expect(text(container)).toContain('не больше чем на 50 000 кр.');
    expect(sent(topic, 'use_treasury')).toEqual([{ value: false }]);
  });

  test('сообщение, заморозка и отсутствие счёта', () => {
    const { container } = setup({ message: 'Слишком частые сделки по VYMD.', frozen: 1 });
    expect(text(container)).toContain('Слишком частые сделки по VYMD.');
    expect(text(container)).toContain('Счёт заморожен');
    const empty = setup({ has_account: 0 });
    expect(text(empty.container)).toContain('Нет банковского счёта');
  });

  test('без счёта и при заморозке кнопки сделок выключены', () => {
    for (const locked of [{ has_account: 0 }, { frozen: 1 }]) {
      const { getAllByText, topic, unmount } = setup(locked);
      fireEvent.click(getAllByText('Купить')[0]);
      fireEvent.click(getAllByText('Продать всё')[0]);
      expect(topic.mock.calls.filter(([message]) => String(message.type).startsWith('act/'))).toEqual([]);
      unmount();
    }
  });

  test('терминал показывает то же окно', () => {
    const { container, getAllByText, topic } = setup({}, <StockTerminal />);
    expect(text(container)).toContain('Котировки');
    fireEvent.click(getAllByText('Купить')[0]);
    expect(sent(topic, 'buy')).toEqual([{ ticker: 'VYMD', count: 1 }]);
  });

  test('индекс сектора торгуется в котировках без логотипа', () => {
    const { container, getAllByText, topic } = setup({ holdings: {}, cooldowns: {} });
    expect(container.querySelector('.logo-sect')).toBeNull();
    expect(container.querySelector('.NtTerm__tiles')?.textContent).toContain('98.50');
    selectTile(container, 'SECT');
    expect(text(container)).toContain('SECT Индекс сектора');
    fireEvent.click(getAllByText('Купить')[0]);
    expect(sent(topic, 'buy')).toEqual([{ ticker: 'SECT', count: 1 }]);
    expect(getAllByText('Купить')).toHaveLength(1);
  });

  test('дивиденды: фонд, выплата на акцию и ваша доля; без фондов - пустая строка', () => {
    const { container } = setup({ holdings: { NKMR: 4 } });
    openPage(container, 'Портфель');
    const content = text(container);
    expect(content).toContain('5% закупок станции у партнёра компании идёт в её фонд. Раз в 10 мин.');
    expect(content).toContain('NKMR: фонд 30 кр., около 30.00 кр. на акцию');
    expect(content).toContain('вам ≈ 120 кр.');
    expect(content).not.toContain('VYMD: фонд');
    const empty = setup({ companies: base.companies.map((company) => ({ ...company, dividend_pool: 0 })) });
    openPage(empty.container, 'Портфель');
    expect(text(empty.container)).toContain('Фонды пока пусты');
  });

  test('заявка: тикер, условие, цена и количество уходят в add_order', () => {
    const { container, topic } = setup();
    openPage(container, 'Портфель');
    const frame = framed(container, 'Заявки 0/5');
    pick(frame, 0, 'NKMR');
    pick(frame, 1, 'Продать, если цена ≥ (фиксация)');
    const inputs = frame.querySelectorAll('input');
    commit(inputs[0], '150,5');
    commit(inputs[1], '3');
    fireEvent.click(within(frame).getByText('Поставить'));
    expect(sent(topic, 'add_order')).toEqual([{ ticker: 'NKMR', side: 'sell_above', count: 3, price: 150.5 }]);
    expect(text(frame)).toContain('Заявок нет.');
  });

  test('стоящие заявки с понятными условиями, "Отменить" шлёт id; при пяти заявках новую не поставить', () => {
    const orders = [
      { id: 1, ticker: 'VYMD', side: 'buy_below', count: 5, price: 100 },
      { id: 2, ticker: 'VYMD', side: 'sell_below', count: 3, price: 90.5 },
      { id: 7, ticker: 'NKMR', side: 'sell_above', count: 2, price: 160 },
      { id: 8, ticker: 'SECT', side: 'buy_below', count: 1, price: 95 },
      { id: 9, ticker: 'SECT', side: 'buy_below', count: 1, price: 90 },
    ] as const;
    const { container, getAllByText, topic } = setup({ orders: [...orders] });
    openPage(container, 'Портфель');
    const content = text(container);
    expect(content).toContain('Заявки 5/5');
    expect(content).toContain('VYMD: купить 5 шт., если цена ≤ 100.00');
    expect(content).toContain('VYMD: продать 3 шт., если цена ≤ 90.50 (стоп)');
    expect(content).toContain('NKMR: продать 2 шт., если цена ≥ 160.00 (фиксация)');
    fireEvent.click(getAllByText('Отменить')[2]);
    expect(sent(topic, 'cancel_order')).toEqual([{ id: 7 }]);
    fireEvent.click(getAllByText('Поставить')[0]);
    expect(sent(topic, 'add_order')).toEqual([]);
  });

  test('без счёта и при заморозке заявки не ставятся и не снимаются', () => {
    for (const locked of [{ has_account: 0 }, { frozen: 1 }]) {
      const { container, getByText, topic, unmount } = setup({ ...locked, orders: [{ id: 1, ticker: 'VYMD', side: 'buy_below', count: 5, price: 100 }] });
      openPage(container, 'Портфель');
      fireEvent.click(getByText('Поставить'));
      fireEvent.click(getByText('Отменить'));
      expect(topic.mock.calls.filter(([message]) => String(message.type).startsWith('act/'))).toEqual([]);
      unmount();
    }
  });

  test('правила и сноски объясняют дивиденды, индекс и заявки', () => {
    const { container } = setup({
      drivers: {
        ...base.drivers,
        SECT: [{ label: 'Среднее по всем компаниям сектора', effect: null, note: '100 - когда все по базовой цене' }],
        NKMR: [{ label: 'Закупки станции у "Накамура"', effect: null, note: 'цену не двигают: 5% суммы идёт в дивиденды держателям' }],
      },
    });
    openPage(container, 'Правила');
    let content = text(container);
    expect(content).toContain('Дивиденды: 5% каждой закупки станции у партнёра компании идёт в её фонд');
    expect(content).toContain('Индекс сектора стоит 100 × среднюю долю базовой цены всех компаний');
    expect(content).toContain('не больше 5 на счёт');
    openPage(container, 'От чего зависит цена');
    content = text(container);
    expect(content).toContain('Среднее по всем компаниям сектора: 100 - когда все по базовой цене');
    expect(content).toContain('Закупки станции у "Накамура": цену не двигают: 5% суммы идёт в дивиденды держателям');
  });
});

test('сменившаяся цена подсвечивается по направлению, при открытии окна подсветки нет', () => {
  const { container, rerender, store } = setup();
  expect(container.querySelector('.NtTerm__pulse')).toBeNull();
  const companies = base.companies.map((company) => (company.ticker === 'VYMD' ? { ...company, price: company.price - 5 } : company));
  store.dispatch(backendUpdate({ data: { companies } }));
  rerender(<NtosStockExchangeContent />);
  const pulses = Array.from(container.querySelectorAll('.NtTerm__pulse'));
  expect(pulses.length).toBeGreaterThan(0);
  expect(pulses.every((node) => node.className.includes('NtTerm__pulse--down'))).toBe(true);
});

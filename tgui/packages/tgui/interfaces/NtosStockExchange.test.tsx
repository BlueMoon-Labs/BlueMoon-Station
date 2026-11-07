import { fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { NtosStockExchangeContent, StockExchangeData } from './NtosStockExchange';
import { StockTerminal } from './StockTerminal';

const base: StockExchangeData = {
  companies: [
    { ticker: 'VYMD', name: 'Вей-Мед', price: 120, change: 4.2, halted: 0, base_price: 120, max_buy: 37 },
    { ticker: 'CYBS', name: 'Киберсан', price: 4, change: -60, halted: 1, base_price: 90 },
    { ticker: 'NKMR', name: 'Накамура', price: 140, change: 0, halted: 0, base_price: 140 },
  ],
  history: { VYMD: [100, 110, 120], CYBS: [], NKMR: [140, 140] },
  drivers: {
    VYMD: [
      { label: 'Случайные колебания за минуту', effect: null, note: 'около ±2.5%' },
      { label: 'Продажи станции через снабжение партнёру «Вей-Мед»', effect: 15, upto: 1, note: 'медикаменты; +5% за каждые 1000 кр. продаж' },
      { label: 'Сорванный станцией спецзаказ «Вей-Мед»', effect: -5 },
      { label: 'Вспышка болезни на станции', effect: 20 },
    ],
    CYBS: [],
    NKMR: [{ label: 'Расслоение суперматерии на станции', effect: 10 }],
  },
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
};

const setup = (data: Partial<StockExchangeData> = {}, component = <NtosStockExchangeContent />) => {
  let now = Date.now();
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'NtosStockExchange' }, data: { ...base, ...data } }));
  return { ...render(component), topic };
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

const text = (container: HTMLElement) => (container.textContent || '').replace(/\u00a0/g, ' ');

describe('NtosStockExchange', () => {
  test('график за час берётся из статической истории по тикеру, компания без истории идёт без графика', () => {
    const { container } = setup({ history: { VYMD: [100, 110, 120], NKMR: [140, 140] } });
    expect(container.querySelectorAll('svg')).toHaveLength(2);
  });

  test('у каждой компании логотип по тикеру из спрайтшита economy_logos', () => {
    const { container } = setup();
    expect(container.querySelector('.economy_logos32x32.logo-vymd')).not.toBeNull();
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

  test('«Макс» показывает доступный объём и просит сервер посчитать его заново', () => {
    const { getByText, topic } = setup();
    fireEvent.click(getByText('Макс (37)'));
    expect(sent(topic, 'buy')).toEqual([{ ticker: 'VYMD', count: 'max' }]);
  });

  test('остановленные торги и кулдаун убирают кнопки', () => {
    const { container, getAllByText } = setup();
    const content = text(container);
    expect(content).toContain('Торги остановлены');
    expect(content).toContain('Следующая сделка через 12 с');
    expect(getAllByText('Купить')).toHaveLength(1);
  });

  test('счёт: баланс, стоимость акций, прибыль и позиция', () => {
    const { container } = setup();
    const content = text(container);
    expect(content).toContain('Личный счёт');
    expect(content).toContain('Иван Петров');
    expect(content).toContain('5 000 кр.');
    expect(content).toContain('368 кр.');
    expect(content).toContain('-45 кр.');
    expect(content).toContain('3 шт. · 360 кр.');
  });

  test('правила биржи берут числа из данных', () => {
    const { container } = setup();
    openPage(container, 'Правила');
    const content = text(container);
    expect(content).toContain('в канале «Сводка сектора» на ньюскастерах не сразу, а в течение примерно 7 мин. после скачка цены');
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
    expect(content).toContain('Продажи станции через снабжение партнёру «Вей-Мед»: до +15% (медикаменты; +5% за каждые 1000 кр. продаж)');
    expect(content).toContain('Сорванный станцией спецзаказ «Вей-Мед»: −5%');
    expect(content).toContain('Вспышка болезни на станции: +20%');
    expect(content).toContain('Расслоение суперматерии на станции: +10%');
  });

  test('портфель и бегущая строка: позиция по текущей цене, у остановленной компании - стоп', () => {
    const { container } = setup();
    expect(container.querySelector('.NtTerm__tape')?.textContent).toContain('стоп');
    openPage(container, 'Портфель');
    expect(text(container)).toContain('VYMD · Вей-Мед · 3 шт. по 120.00');
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
});

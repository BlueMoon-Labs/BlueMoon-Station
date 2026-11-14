import { fireEvent, render, within } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { EconomyAdmin, EconomyAdminData } from './EconomyAdmin';

const base: EconomyAdminData = {
  message: '',
  tax_rate: 10,
  state: 'normal',
  minted: 9000,
  burned: 4000,
  price_index: 1.05,
  ledger: {
    minted: 9000,
    burned: 4000,
    total: 52000,
    department_kept: 20000,
    department_burned: 13000,
    department_sink: 65,
    department_sink_min: 60,
    department_sink_max: 80,
    department_sink_no_return: 41,
    department_sink_no_command: 72,
    department_sink_bare: 50,
    tax_nt_burned: 1500,
    budget_returned: 9000,
    crew: { count: 40, median_balance: 2400, median_start: 450, median_growth: 5.3 },
    by_category: [
      {
        id: 'admin',
        name: 'Администрация',
        amount: 400,
        reasons: [{ id: 'admin', name: 'Корректировка NT', amount: 400 }],
      },
    ],
  },
  snapshots: [
    { minute: 5, minted: 1000, burned: 300, in_accounts: 50000, cash: 200 },
    { minute: 10, minted: 800, burned: 600, in_accounts: 50200, cash: 250 },
  ],
  departments: [{ id: 'SCI', name: 'Наука', number: 555, balance: 9000, owed: 0, staff: 2, threshold: 6000, return_due: 300, purchases: 3, purchases_per_hour: 1.5, purchase_amount: 7000, returned: 2500 }],
  accounts: [
    { number: 111, holder: 'Анна', budget: 0, department: 'MED', balance: 300, state: 0 },
    {
      number: 222,
      holder: 'Борис',
      budget: 0,
      department: 'SCI',
      balance: 90,
      state: 1,
      frozen_by: 'Детектив',
      freeze_reason: 'дробление',
    },
    { number: 555, holder: 'Наука', budget: 1, department: 'SCI', balance: 4000, state: 0 },
  ],
  flags: [
    {
      uid: 3,
      time: '12:30',
      text: 'Дробление переводов',
      amount: 900,
      account: 111,
      counterparty: 222,
      closed: 0,
      refunded: 0,
      closed_by: null,
    },
  ],
  commodities: [
    { id: 'metals', name: 'Металлы', factor: 1.1, sell: 0.9, hot: 0, demand: 80, history: [1, 1.1], buyer: 'НТ Логистика' },
  ],
  partners: [
    {
      id: 'nt',
      name: 'НТ Логистика',
      unlocked: 1,
      tier: 1,
      reputation: 120,
      discount: 3,
      markup: 1,
      wealth: 50000,
      next_unlock: null,
      buys: 'всё остальное x1',
      sells: 'все группы каталога',
    },
  ],
  companies: [
    {
      ticker: 'AGRO',
      name: 'Аграрный союз',
      price: 50,
      change: 4,
      halted: 0,
      history: [45, 50],
      base_price: 45,
      event_mult: 1.2,
      queued: 1,
    },
  ],
  config_errors: [],
  config_reloaded_at: null,
  tax_max: 30,
  adjust_max: 100000,
  comment_max: 200,
  freeze_reason_max: 64,
  headline_max: 120,
  effect_min: -90,
  effect_max: 100,
  event_mult_max: 3,
  price_max_ratio: 5,
  reset_phrase: 'сброс',
  persist_decay: 20,
  station_event_cooldown: 10,
  snapshot_minutes: 5,
};

const setup = (data: Partial<EconomyAdminData> = {}) => {
  let now = Date.now();
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'EconomyAdmin' }, data: { ...base, ...data } }));
  return { ...render(<EconomyAdmin />), topic };
};

const sent = (topic: jest.Mock, action: string) =>
  topic.mock.calls
    .map(([message]) => message)
    .filter((message) => message.type === `act/${action}`)
    .map((message) => JSON.parse(message.payload));

const text = (container: HTMLElement) => (container.textContent || '').replace(/\u00a0/g, ' ');

const commit = (input: Element, value: string) => {
  fireEvent.focus(input);
  fireEvent.input(input, { target: { value } });
  fireEvent.blur(input);
};

const typeComment = (getByPlaceholderText: (text: RegExp) => HTMLElement, value: string) =>
  fireEvent.input(getByPlaceholderText(/Комментарий для админ-лога/), { target: { value } });

const rowOf = (element: HTMLElement) => within(element.closest('tr') as HTMLElement);

const sectionOf = (title: HTMLElement) => within(title.closest('.Section') as HTMLElement);

describe('EconomyAdmin', () => {
  test('деньги: график снимков рисуется при двух снимках, категории и обновление', () => {
    const { container, getByText, topic } = setup();
    expect(container.querySelectorAll('.EconomyAdmin__chart polyline')).toHaveLength(2);
    const content = text(container);
    expect(content).toContain('52 000 кр.');
    expect(content).toContain('+5 000 кр.');
    expect(content).toContain('Корректировка NT: 400 кр.');
    expect(content).toContain('65% (цель 60-80%): сожжено 13 000 кр. из 20 000 кр.');
    expect(content).toContain('Личные деньги в эту долю не входят');
    fireEvent.click(getByText('Обновить'));
    expect(sent(topic, 'refresh')).toEqual([{}]);
  });

  test('деньги: с одним снимком графика нет, есть пояснение', () => {
    const { container } = setup({ snapshots: [base.snapshots[0]] });
    expect(container.querySelector('.EconomyAdmin__chart')).toBeNull();
    expect(text(container)).toContain('график появится после двух снимков');
  });

  test('счета: корректировка, заморозка и разморозка с комментарием', () => {
    const { container, getByPlaceholderText, getByText, topic } = setup();
    typeComment(getByPlaceholderText, 'тикет 42');
    fireEvent.click(getByText('Счета'));
    expect(text(container)).toContain('заморожен (Детектив: дробление)');
    fireEvent.click(rowOf(getByText('Анна')).getByText('Выбрать'));
    const form = sectionOf(getByText('Корректировка счёта'));
    const [, amount] = form.getAllByRole('textbox');
    commit(amount, '-250');
    fireEvent.click(form.getByText('Провести'));
    expect(sent(topic, 'adjust')).toEqual([{ number: 111, amount: -250, comment: 'тикет 42' }]);
    fireEvent.click(rowOf(getByText('Анна')).getByText('Заморозить'));
    expect(sent(topic, 'freeze')).toEqual([]);
    fireEvent.input(getByPlaceholderText(/Причина заморозки для владельца/), { target: { value: 'проверка' } });
    fireEvent.click(rowOf(getByText('Анна')).getByText('Заморозить'));
    expect(sent(topic, 'freeze')).toEqual([{ number: 111, reason: 'проверка', comment: 'тикет 42' }]);
    expect(text(container)).toContain('бюджеты TAR и DS - счета внестанционных ролей');
    fireEvent.click(rowOf(getByText('Борис')).getByText('Разморозить'));
    expect(sent(topic, 'unfreeze')).toEqual([{ number: 222, comment: 'тикет 42' }]);
    expect(rowOf(getByText('Наука', { selector: 'td' })).queryByText('Заморозить')).toBeNull();
  });

  test('калибровка: доли стоков отделов, возвраты, доля NT с налога и рост личных денег', () => {
    const { container } = setup();
    const content = text(container);
    expect(content).toContain('65%; без возврата излишка 41%, без казны 72%, без обоих 50%');
    expect(content).toContain('Возврат излишков NT:9 000 кр.');
    expect(content).toContain('Доля NT с налога:1 500 кр.');
    expect(content).toContain('медиана 2 400 кр. при подъёмных 450 кр., рост x5.3 (40 чел. на смене)');
  });

  test('отделы: порог бюджета и возврат NT за тик', () => {
    const { container, getByText } = setup();
    fireEvent.click(getByText('Отделы'));
    const row = rowOf(getByText('Наука', { selector: 'td' }));
    expect(row.getByText('6 000 кр.')).toBeTruthy();
    expect(row.getByText('300 кр.')).toBeTruthy();
    expect(text(row.getByText(/^3 \(1.5\)/).closest('td') as HTMLElement)).toContain('3 (1.5) на 7 000 кр.');
    expect(row.getByText('2 500 кр.')).toBeTruthy();
    expect(text(container)).toContain('у казны - стартовая казна и по наибольшему запросу на каждый отдел');
    expect(text(container)).toContain('цели накопления главы');
  });

  test('рынок: сдвиг, обвал, бум и сброс сектора только с фразой', () => {
    const { getByText, getByPlaceholderText, topic } = setup();
    typeComment(getByPlaceholderText, 'ивент');
    fireEvent.click(getByText('Рынок'));
    fireEvent.click(getByText('Сдвиг рынка'));
    fireEvent.click(getByText('Обвал'));
    fireEvent.click(getByText('Бум'));
    expect(sent(topic, 'market_event')).toEqual([
      { kind: 'shift', comment: 'ивент' },
      { kind: 'crash', comment: 'ивент' },
      { kind: 'boom', comment: 'ивент' },
    ]);
    const reset = sectionOf(getByText('Сброс сектора'));
    expect(text(reset.getByText(/В конце раунда файл запишется/))).toContain('с обычным затуханием 20%');
    const button = reset.getByText('Сбросить сектор');
    fireEvent.click(button);
    expect(sent(topic, 'reset_sector')).toEqual([]);
    fireEvent.input(reset.getByRole('textbox'), { target: { value: 'сброс' } });
    fireEvent.click(reset.getByText('Сбросить сектор'));
    expect(sent(topic, 'reset_sector')).toEqual([{ confirm: 'сброс', comment: 'ивент' }]);
  });

  test('биржа: событие компании с шоком и заголовком', () => {
    const { container, getByText, getByPlaceholderText, topic } = setup();
    typeComment(getByPlaceholderText, 'ивент');
    fireEvent.click(getByText('Биржа'));
    expect(text(container)).toContain('x1.2');
    const form = sectionOf(getByText('Событие компании'));
    const [effect] = form.getAllByRole('textbox');
    commit(effect, '25');
    fireEvent.input(getByPlaceholderText('Заголовок новости'), { target: { value: 'Урожай века' } });
    fireEvent.click(getByText('Поставить событие'));
    expect(sent(topic, 'market_event')).toEqual([
      { kind: 'company_event', ticker: 'AGRO', effect: 25, headline: 'Урожай века', comment: 'ивент' },
    ]);
  });

  test('конфиг: перечитка, налог и ошибки в NoticeBox', () => {
    const { container, getByText, topic } = setup({
      config_errors: ['settings.tax_max: вне 0..100'],
      config_reloaded_at: '12:40:00',
    });
    fireEvent.click(getByText('Конфиг'));
    const errors = container.querySelector('.NoticeBox--color--danger, .NoticeBox--type--danger') as HTMLElement;
    expect(errors).not.toBeNull();
    expect(text(errors)).toContain('settings.tax_max: вне 0..100');
    fireEvent.click(getByText('Перечитать economy.json'));
    expect(sent(topic, 'reload_config')).toEqual([{ comment: '' }]);
    expect(text(container)).toContain('settings.tax_max');
    const tax = sectionOf(getByText('Налог', { selector: '.Section__titleText' }));
    commit(tax.getByRole('textbox'), '15');
    fireEvent.click(tax.getByText('Установить налог'));
    expect(sent(topic, 'set_tax')).toEqual([{ rate: 15, comment: '' }]);
  });

  test('аудит: дела и сообщение последнего действия', () => {
    const { container, getByText } = setup({ message: 'Счёт Анна №111: +300 кр.' });
    expect(text(container)).toContain('Счёт Анна №111: +300 кр.');
    fireEvent.click(getByText('Аудит'));
    const content = text(container);
    expect(content).toContain('открыто 1 из 1');
    expect(content).toContain('№111 -> №222');
    expect(content).toContain('900 кр.');
  });
});

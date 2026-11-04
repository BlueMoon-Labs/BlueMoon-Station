import { fireEvent, render, within } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { AuditCase, FinancialAuditData, NtosFinancialAuditContent } from './NtosFinancialAudit';

const skim: AuditCase = {
  uid: 7,
  kind: 'unknown_device',
  text: 'Списание с неопознанного устройства',
  amount: 1000,
  time: '12:10',
  source: 111111,
  source_holder: 'Анна',
  recipient: 222222,
  recipient_holder: 'Борис',
  recipient_frozen: 1,
  recipient_balance: 1500,
  pooled: 0,
  mine: 0,
  recipients: [],
  closed: 0,
  closed_by: null,
  close_reason: null,
  refunded: 0,
};

const cashout: AuditCase = {
  ...skim,
  uid: 8,
  kind: 'anon_cashout',
  text: 'Наличные с анонимного счёта: Бар',
  amount: 300,
  source: 333333,
  source_holder: 'Анонимный счёт №5',
  recipient: null,
  recipient_holder: null,
  recipient_frozen: 0,
  recipient_balance: 0,
};

const closedCase: AuditCase = {
  ...skim,
  uid: 3,
  kind: 'structuring',
  closed: 1,
  closed_by: 'Иван Шерлок, Detective',
  close_reason: 'долг за карты',
};

const base: FinancialAuditData = {
  message: '',
  can_audit: 1,
  audit_rights: 'глава СБ и капитан',
  rules: {
    siphon_threshold: 1000,
    siphon_minutes: 30,
    structuring_count: 5,
    structuring_minutes: 5,
    insider_threshold: 2000,
    insider_minutes: 5,
    event_eta_min: 3,
    event_eta_max: 5,
    refute_minutes: 7,
    trace_minutes: 30,
    trace_depth: 3,
    fee_percent: 10,
    owed_cap: 6,
    reason_max: 64,
    search_max: 20,
  },
  my_account: 999999,
  cases: [closedCase, skim, cashout],
  query: '',
  results: [],
  selected: null,
  trace: null,
};

const boris = {
  number: 222222,
  holder: 'Борис',
  balance: 1500,
  kind: 'personal' as const,
  status: 'active' as const,
  frozen_by: null,
  freeze_reason: null,
  cases: [7],
  history: [{ time: '12:10', label: 'Перевод с неопознанного устройства', amount: 1000, counterparty: 'Анна (№111111)' }],
};

const setup = (data: Partial<FinancialAuditData> = {}) => {
  let now = Date.now();
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'NtosFinancialAudit' }, data: { ...base, ...data } }));
  return { ...render(<NtosFinancialAuditContent />), topic };
};

const sent = (topic: jest.Mock, action: string) =>
  topic.mock.calls
    .map(([message]) => message)
    .filter((message) => message.type === `act/${action}`)
    .map((message) => JSON.parse(message.payload));

const text = (container: HTMLElement) => (container.textContent || '').split(String.fromCharCode(160)).join(' ');

const commit = (input: Element, value: string) => {
  fireEvent.focus(input);
  fireEvent.input(input, { target: { value } });
  fireEvent.blur(input);
};

const rowOf = (element: HTMLElement) => within(element.closest('tr') as HTMLElement);

const pooled: AuditCase = {
  ...skim,
  uid: 9,
  kind: 'budget_siphon',
  text: 'Выплаты из бюджета на счета без владельца',
  amount: 1200,
  source: 444444,
  source_holder: 'Казна станции',
  recipient: null,
  recipient_holder: null,
  recipient_frozen: 0,
  recipient_balance: 0,
  pooled: 1,
  recipients: [
    { number: 501, holder: 'Пустой 1', amount: 400, left: 400, frozen: 1, balance: 400 },
    { number: 502, holder: 'Пустой 2', amount: 800, left: 300, frozen: 0, balance: 300 },
  ],
};

describe('NtosFinancialAudit', () => {
  test('без прав: только справка, без дел и кнопок', () => {
    const { container, queryByText } = setup({ can_audit: 0, selected: boris });
    const content = text(container);
    expect(content).toContain('открыты только тем, кто ведёт аудит: глава СБ и капитан.');
    expect(content).not.toContain('Борис');
    expect(queryByText('Заморозить')).toBeNull();
    expect(queryByText('Разобрать')).toBeNull();
  });

  test('дела: открытые и закрытые, кто и почему закрыл', () => {
    const { container, getByText } = setup();
    expect(getByText('Дела (2)')).toBeTruthy();
    fireEvent.click(getByText('Показать (1)'));
    const content = text(container);
    expect(content).toContain('Анна №111111 → Борис №222222');
    expect(content).toContain('Закрыто без возврата (Иван Шерлок, Detective): долг за карты');
  });

  test('возврат по делу: сумма, сбор СБ и номер дела', () => {
    const { container, getByText, getByPlaceholderText, topic } = setup();
    fireEvent.click(rowOf(getByText('Неопознанное устройство')).getByText('Разобрать'));
    const content = text(container);
    expect(content).toContain('Пострадавшему вернётся 900 кр., сбор отдела безопасности - 100 кр. (10% суммы)');
    expect(content).toContain('NT за дела не доплачивает');
    const refund = within(getByText('Возврат по делу').parentElement as HTMLElement);
    commit(refund.getByRole('textbox'), '500');
    expect(text(container)).toContain('Пострадавшему вернётся 450 кр., сбор отдела безопасности - 50 кр.');
    fireEvent.click(refund.getByText('Вернуть средства'));
    expect(sent(topic, 'refund')).toEqual([{ uid: 7, amount: 500 }]);
    fireEvent.input(getByPlaceholderText('Причина закрытия'), { target: { value: 'сам перевёл' } });
    fireEvent.click(getByText('Закрыть дело'));
    expect(sent(topic, 'close_case')).toEqual([{ uid: 7, reason: 'сам перевёл' }]);
    expect(text(container)).toContain('Владельцы обоих счетов дела получат сообщение на карту');
  });

  test('возврат закрыт, пока получатель не заморожен; у обналичивания возврата нет', () => {
    const { container, getByText, topic } = setup({ cases: [{ ...skim, recipient_frozen: 0 }, cashout] });
    fireEvent.click(rowOf(getByText('Неопознанное устройство')).getByText('Разобрать'));
    expect(text(container)).toContain('Сначала заморозьте счёт получателя');
    fireEvent.click(getByText('Вернуть средства'));
    expect(sent(topic, 'refund')).toEqual([]);
    fireEvent.click(rowOf(getByText('Наличные с анонимного счёта')).getByText('Разобрать'));
    expect(text(container)).toContain('вернуть деньги нельзя');
  });

  test('из дела к счёту получателя', () => {
    const { getAllByText, getByText, topic } = setup();
    fireEvent.click(rowOf(getByText('Неопознанное устройство')).getByText('Разобрать'));
    fireEvent.click(getAllByText('Счёт')[1]);
    expect(sent(topic, 'select')).toEqual([{ number: 222222 }]);
    expect(getByText('Поиск счёта')).toBeTruthy();
  });

  test('поиск, карточка счёта, заморозка и след', () => {
    const { container, getByPlaceholderText, getByText, topic } = setup({
      results: [{ number: 222222, holder: 'Борис', balance: 1500, kind: 'personal', status: 'active' }],
      selected: boris,
      trace: {
        number: 111111,
        holder: 'Анна',
        time: '12:15',
        tree: [
          {
            holder: 'Борис',
            number: 222222,
            amount: 1000,
            children: [{ holder: 'Анонимный счёт №5', number: 333333, amount: 700, children: [] }],
          },
        ],
      },
    });
    fireEvent.click(getByText('Счета'));
    fireEvent.input(getByPlaceholderText('Имя владельца или номер счёта'), { target: { value: 'бор' } });
    fireEvent.click(getByText('Найти'));
    expect(sent(topic, 'search')).toEqual([{ query: 'бор' }]);
    fireEvent.click(getByText('Открыть'));
    expect(sent(topic, 'select')).toEqual([{ number: 222222 }]);
    fireEvent.click(getByText('Проследить'));
    expect(sent(topic, 'trace')).toEqual([{ number: 222222 }]);
    fireEvent.input(getByPlaceholderText('Причина заморозки'), { target: { value: 'скиммер' } });
    fireEvent.click(getByText('Заморозить'));
    expect(sent(topic, 'freeze')).toEqual([{ number: 222222, reason: 'скиммер' }]);
    const content = text(container);
    expect(content).toContain('Перевод с неопознанного устройства');
    expect(content).toContain('до 6 выплат');
    const child = getByText(/Анонимный счёт №5 №333333/);
    const parent = getByText(/^Борис №222222/, { selector: 'div' });
    expect(parent.parentElement?.contains(child)).toBe(true);
    expect(text(child.parentElement as HTMLElement)).toContain('700 кр.');
    expect(text(parent)).toContain('1 000 кр.');
  });

  test('замороженный счёт: кто заморозил и разморозка; свой счёт не замораживается', () => {
    const frozen = { ...boris, status: 'frozen' as const, frozen_by: 'Иван Шерлок, Detective', freeze_reason: 'скиммер' };
    const view = setup({ selected: frozen });
    fireEvent.click(view.getByText('Счета'));
    expect(text(view.container)).toContain('заморожен аудитом (Иван Шерлок, Detective): скиммер');
    fireEvent.click(view.getByText('Разморозить'));
    expect(sent(view.topic, 'unfreeze')).toEqual([{ number: 222222 }]);
    view.unmount();
    const locked = setup({
      selected: { ...frozen, frozen_by: 'Центральное командование NT', freeze_locked: 'Счёт заморожен ЦК: разморозить может только ЦК.' },
    });
    fireEvent.click(locked.getByText('Счета'));
    expect(text(locked.container)).toContain('Счёт заморожен ЦК: разморозить может только ЦК.');
    expect(locked.queryByText('Разморозить')).toBeNull();
    locked.unmount();
    const own = setup({ selected: { ...boris, number: 999999 } });
    fireEvent.click(own.getByText('Счета'));
    expect(own.queryByText('Заморозить')).toBeNull();
    expect(text(own.container)).toContain('Это ваш счёт');
  });

  test('карточка счёта закрывается, поиск по Enter', () => {
    const { getByPlaceholderText, getByText, topic } = setup({ selected: boris });
    fireEvent.click(getByText('Счета'));
    fireEvent.click(getByText('Закрыть'));
    expect(sent(topic, 'select')).toEqual([{ number: 0 }]);
    const search = getByPlaceholderText('Имя владельца или номер счёта');
    fireEvent.input(search, { target: { value: 'иван' } });
    fireEvent.keyDown(search, { key: 'Enter', keyCode: 13 });
    expect(sent(topic, 'search')).toEqual([{ query: 'иван' }]);
  });

  test('дело со своим участием: без форм возврата и закрытия', () => {
    const { container, getByText, queryByText } = setup({ cases: [{ ...skim, mine: 1 }] });
    fireEvent.click(rowOf(getByText('Неопознанное устройство')).getByText('Разобрать'));
    expect(text(container)).toContain('В деле ваш счёт или ваши платежи: возврат и закрытие ведёт другой аудитор.');
    expect(queryByText('Вернуть средства')).toBeNull();
    expect(queryByText('Закрыть дело')).toBeNull();
  });

  test('объединённое дело со своим участием: без кнопок возврата', () => {
    const { container, getByText, queryByText } = setup({ cases: [{ ...pooled, mine: 1 }] });
    fireEvent.click(rowOf(getByText('Отток бюджета')).getByText('Разобрать'));
    expect(text(container)).toContain('ведёт другой аудитор');
    expect(queryByText('Возврат')).toBeNull();
    expect(queryByText('Закрыть дело')).toBeNull();
  });

  test('правила: точные пороги из данных', () => {
    const { container, getByText } = setup();
    fireEvent.click(getByText('Правила'));
    const content = text(container);
    expect(content).toContain('на 1 000 кр. и больше за 30 мин.');
    expect(content).toContain('5 и больше личных переводов одному получателю за 5 мин.');
    expect(content).toContain('сделки после того, как она встала в очередь: она выходит через 3-5 мин.');
    expect(content).toContain('сделки за 5 мин. до его выхода');
    expect(content).toContain('опровержения, которое выходит через 7 мин.');
    expect(content).toContain('если с последнего движения по нему прошло меньше 30 мин.');
    expect(content).toContain('10% суммы уходит сбором в бюджет отдела безопасности');
  });

  test('объединённое дело: получатели с остатками, возврат с выбранного', () => {
    const { container, getByText, topic } = setup({ cases: [pooled] });
    fireEvent.click(rowOf(getByText('Отток бюджета')).getByText('Разобрать'));
    const content = text(container);
    expect(content).toContain('счета без владельца: 2');
    expect(content).toContain('Вернуть можно с любого получателя из списка');
    expect(content).not.toContain('только с последнего');
    const secondRow = getByText('Пустой 2 №502', { exact: false }).closest('tr') as HTMLElement;
    expect(text(secondRow)).toContain('800 кр.300 кр.');
    const second = within(secondRow);
    fireEvent.click(rowOf(getByText('Пустой 1 №501', { exact: false })).getByText('Возврат'));
    const refund = within(getByText('Возврат со счёта №501').parentElement as HTMLElement);
    commit(refund.getByRole('textbox'), '250');
    fireEvent.click(refund.getByText('Вернуть средства'));
    expect(sent(topic, 'refund')).toEqual([{ uid: 9, amount: 250, recipient: 501 }]);
    fireEvent.click(second.getByText('Возврат'));
    expect(text(container)).toContain('Сначала заморозьте счёт получателя');
  });
});

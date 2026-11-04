import { fireEvent, render, within } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { NtosTreasuryContent, TreasuryConsole, TreasuryData } from './NtosTreasury';

const base: TreasuryData = {
  tax_max: 30,
  grades: [
    { id: 'easy', name: 'лёгкий', wage: 100 },
    { id: 'hard', name: 'тяжёлый', wage: 200 },
  ],
  holder_max: 42,
  economy_minutes: 5,
  wage_minutes: 10,
  wage_floor: 30,
  owed_cap: 6,
  treasury_grant: 200,
  tax_nt_share: 50,
  treasury_cap: 30000,
  treasury_return_due: 700,
  grace_minutes: 15,
  cap_share: 10,
  treasury_max: 5000,
  treasury_pending_max: 2,
  unowned_max: 30,
  stall_fee: 500,
  stall_minutes: 60,
  rich_per_capita: 3000,
  poor_per_capita: 500,
  audit_rights: 'глава СБ и капитан',
  message: '',
  can_manage: 1,
  treasury: 12000,
  tax_rate: 10,
  ledger: { minted: 9000, burned: 4000, state: 'rich', money_history: [100, 200, 300] },
  departments: [
    { id: 'MED', name: 'Медицина', balance: 4000, owed: 0, owed_wages: 0, staff_on_shift: 3, threshold: 9000, headroom: 5000, return_due: 0 },
    { id: 'SCI', name: 'Наука', balance: 1500, owed: 200, owed_wages: 60, staff_on_shift: 2, threshold: 1000, headroom: -500, return_due: 120 },
  ],
  requests: [
    {
      uid: 4,
      department_id: 'SCI',
      department_name: 'Наука',
      amount: 700,
      requester: 'Директор',
      reason: 'Ремонт',
      status: 'pending',
    },
  ],
  my_account: 111,
  can_audit: 1,
  accounts: [
    { number: 111, holder: 'Глава Персонала', grade: 'hard', department: 'SRV', balance: 500, status: 'active', crew: 1, anonymous: 0, flagged: 0 },
    { number: 222, holder: 'Анна', grade: 'easy', department: 'MED', balance: 90, status: 'active', crew: 1, anonymous: 0, flagged: 1 },
    { number: 333, holder: 'Анонимный счёт №101', grade: null, department: null, balance: 40, status: 'active', crew: 0, anonymous: 1, flagged: 0 },
  ],
  account: null,
  stalls: [{ name: 'stall', area: 'Бар', renter: 'Анна', until: '12:30', active: 1, goods: 4 }],
};

const anna = {
  number: 222,
  holder: 'Анна',
  balance: 90,
  grade: 'лёгкий',
  department: 'Медицина',
  wage: 100,
  bonus: 0,
  owed: 0,
  status: 'frozen' as const,
  frozen_by: 'Детектив',
  freeze_reason: 'дробление',
  case: 'Дело №3: Перевод с неопознанного устройства, 300 кр.',
  history: [{ time: '12:00:00', label: 'Зарплата', amount: 100, counterparty: 'Медицина' }],
};

const setup = (data: Partial<TreasuryData> = {}, console = false) => {
  let now = Date.now();
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'NtosTreasury' }, data: { ...base, ...data } }));
  return { ...render(console ? <TreasuryConsole /> : <NtosTreasuryContent />), topic };
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

const rowOf = (element: HTMLElement) => within(element.closest('tr') as HTMLElement);

const sectionOf = (title: HTMLElement) => within(title.closest('.Section') as HTMLElement);

const pickAfter = (label: HTMLElement, option: string) => {
  const holder = label.nextElementSibling as HTMLElement;
  fireEvent.click(holder.querySelector('.Dropdown__control') as Element);
  fireEvent.click(within(holder.querySelector('.Dropdown__menu') as HTMLElement).getByText(option));
};

describe('NtosTreasury', () => {
  test('казна: налог, пополнение отдела и перевод между отделами', () => {
    const { container, getByText, topic } = setup();
    const content = text(container);
    expect(content).toContain('12 000 кр.');
    expect(content).toContain('не выше 30%');
    expect(content).toContain('грант NT 200 кр. раз в 5 мин.');
    expect(content).toContain('торгует только капитан');
    expect(content).toContain('50% налога забирает NT, остальное получает казна');
    expect(content).toContain('Сверх 30 000 кр. казна раз в 5 мин. возвращает NT 10% излишка');
    expect(content).toContain('Перевод из казны в бюджет первые 15 мин. излишком не считается, перевод между отделами такой защиты не получает');
    expect(content).toContain('Переведённое между отделами от возврата NT не защищено');
    expect(content).toContain('Казна выше порога: через несколько минут NT заберёт 700 кр.');
    expect(content).toContain('5 000 кр.');
    expect(content).toContain('излишек, NT заберёт 120 кр.');
    const tax = rowOf(getByText('Установить'));
    commit(tax.getByRole('textbox'), '15');
    fireEvent.click(tax.getByText('Установить'));
    expect(sent(topic, 'set_tax')).toEqual([{ rate: 15 }]);
    const science = rowOf(getByText('Наука', { selector: 'td' }));
    commit(science.getByRole('textbox'), '300');
    fireEvent.click(science.getByText('Из казны'));
    expect(sent(topic, 'fund')).toEqual([{ department: 'SCI', amount: 300 }]);
    const move = sectionOf(getByText('Перевод между отделами'));
    commit(move.getByRole('textbox'), '250');
    fireEvent.click(move.getByText('Перевести'));
    expect(sent(topic, 'move_budget')).toEqual([{ from: 'MED', to: 'SCI', amount: 250 }]);
  });

  test('запросы: одобрить и отклонить', () => {
    const { getByText, topic } = setup();
    fireEvent.click(getByText('Запросы (1)'));
    fireEvent.click(getByText('Одобрить'));
    fireEvent.click(getByText('Отклонить'));
    expect(sent(topic, 'resolve_request')).toEqual([
      { uid: 4, approve: true },
      { uid: 4, approve: false },
    ]);
  });

  test('счета: открыть счёт, выбрать, сводка; аудит без порога', () => {
    const { container, getByPlaceholderText, getByText, topic } = setup();
    fireEvent.click(getByText('Счета экипажа'));
    const content = text(container);
    expect(content).toContain('Глава Персонала (вы)');
    expect(content).toContain('анонимный');
    expect(content).toContain('Анна дело аудита');
    expect(getByText('дело аудита').textContent).toBe('дело аудита');
    expect(getByText('анонимный').textContent).toBe('анонимный');
    expect(content).toContain('Крупные или частые выплаты из казны одному человеку');
    expect(content).toContain('Аудит ведут: глава СБ и капитан.');
    expect(content).toContain('казна держит не больше 30.');
    const holder = getByPlaceholderText('Имя владельца');
    fireEvent.input(holder, { target: { value: 'Иван' } });
    const opening = sectionOf(getByText('Новый счёт'));
    const funds = opening.getAllByRole('textbox').find((input) => input !== holder) as HTMLElement;
    commit(funds, '300');
    fireEvent.click(opening.getByText('Открыть счёт'));
    expect(sent(topic, 'open_account')).toEqual([{ holder: 'Иван', funds: 300 }]);
    fireEvent.click(rowOf(getByText('Анна')).getByText('Открыть'));
    expect(sent(topic, 'select_account')).toEqual([{ number: 222 }]);
    fireEvent.click(getByText('Сводный отчёт'));
    expect(sent(topic, 'print_summary')).toHaveLength(1);
  });

  test('открытый счёт: грейд, отдел, блокировка, выписка, история и заморозка', () => {
    const { container, getByText, topic } = setup({ account: anna });
    fireEvent.click(getByText('Счета экипажа'));
    const content = text(container);
    expect(content).toContain('заморожен аудитом (Детектив): дробление');
    expect(content).toContain('Дело №3');
    expect(content).toContain('Зарплата');
    expect(content).toContain('тяжёлый 200 кр.');
    pickAfter(getByText('Грейд:'), 'тяжёлый');
    expect(sent(topic, 'set_grade')).toEqual([{ number: 222, grade: 'hard' }]);
    pickAfter(getByText('Отдел:'), 'Наука');
    expect(sent(topic, 'set_department')).toEqual([{ number: 222, department: 'SCI' }]);
    fireEvent.click(getByText('Заблокировать'));
    expect(sent(topic, 'toggle_block')).toEqual([{ number: 222 }]);
    fireEvent.click(getByText('Выписка'));
    expect(sent(topic, 'print_account')).toEqual([{ number: 222 }]);
    fireEvent.click(getByText('Закрыть'));
    expect(sent(topic, 'select_account')).toEqual([{ number: 0 }]);
  });

  test('свой счёт не правится', () => {
    const own = { ...anna, number: 111, holder: 'Глава Персонала', status: 'active' as const, case: null };
    const { container, getByText, queryByText } = setup({ account: own });
    fireEvent.click(getByText('Счета экипажа'));
    expect(text(container)).toContain('Свой оклад, отдел и блокировку менять нельзя.');
    expect(queryByText('Заблокировать')).toBeNull();
  });

  test('счёт без отдела: оклад не платится, только минимум NT', () => {
    const { container, getByText } = setup({ account: { ...anna, department: null, floor_only: 1 } });
    fireEvent.click(getByText('Счета экипажа'));
    expect(text(container)).toContain('Отдел не назначен: оклад не платится, NT платит только минимум 30 кр.');
  });

  test('прилавки и журнал NT словами', () => {
    const { container, getByText } = setup();
    fireEvent.click(getByText('Прилавки'));
    expect(text(container)).toContain('Анна, до 12:30');
    expect(text(container)).toContain('500 кр. на 60 мин.');
    fireEvent.click(getByText('Журнал NT'));
    const content = text(container);
    expect(content).toContain('Станция богата');
    expect(content).toContain('9 000 кр.');
    expect(content).toContain('4 000 кр.');
    expect(content).toContain('+5 000 кр.');
    expect(content).toContain('от 3 000 кр. - богата');
  });

  test('без прав: только чтение, без счетов и кнопок', () => {
    const { container, getByText, queryByText } = setup(
      { can_manage: 0, accounts: undefined, stalls: undefined, my_account: undefined },
      true,
    );
    expect(text(container)).toContain('глава персонала (по должности и доступу ГП на ID-карте)');
    expect(queryByText('Счета экипажа')).toBeNull();
    expect(queryByText('Установить')).toBeNull();
    expect(queryByText('Из казны')).toBeNull();
    fireEvent.click(getByText('Запросы (1)'));
    expect(queryByText('Одобрить')).toBeNull();
    expect(text(container)).toContain('ждёт решения');
  });
});

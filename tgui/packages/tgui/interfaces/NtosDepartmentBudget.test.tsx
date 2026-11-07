import { fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { BudgetData, DepartmentConsole, NtosDepartmentBudgetContent } from './NtosDepartmentBudget';

const base: BudgetData = {
  departments: [
    { id: 'MED', name: 'Медицина' },
    { id: 'SCI', name: 'Наука' },
  ],
  catalog: [{ type: '/datum/supply_pack/medical/surgery', name: 'Surgical Kit', desc: 'Набор хирурга' }],
  work_prices: [{ name: 'Реанимация', price: 400, unit: 'за реанимацию' }],
  reason_max: 200,
  grant_base: 100,
  grant_payroll_share: 100,
  cap_paydays: 6,
  cap_share: 10,
  grace_minutes: 15,
  goal_minutes: 30,
  goal_cooldown_minutes: 30,
  economy_minutes: 5,
  wage_minutes: 10,
  owed_cap: 6,
  wage_floor: 30,
  dormant_minutes: 10,
  max_wage_bonus: 50,
  treasury_max: 5000,
  treasury_pending_max: 2,
  auto_approve_limit: 1000,
  auto_approve_cooldown: 10,
  auto_approve_wait: 10,
  pending_per_requester: 3,
  handling_fee: 12,
  work_share: 10,
  work_cap: 1500,
  performer_share: 30,
  contracts_help: 'Контракты NT: справка.',
  audit_rights: 'глава СБ и капитан',
  grant_price: 3,
  grant_cap: 10000,
  message: '',
  can_switch: 0,
  has_department: 1,
  my_account: 111,
  manifest_department: 'Медицина',
  can_manage: 1,
  is_staff: 1,
  department: { id: 'MED', name: 'Медицина', balance: 4000, owed: 0, staff_on_shift: 3, grant: 400, grant_has_base: 1, threshold: 9000, return_due: 0 },
  prices: { '/datum/supply_pack/medical/surgery': { price: 2500, available: 1 } },
  requests: [
    { uid: 5, pack: 'Surgical Kit', price: 2500, requester: 'Анна', reason: 'Нет скальпелей', status: 'pending' },
  ],
  treasury_requests: [],
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
  work_log: [{ time: '12:00:00', type: 'Реанимация', amount: 400, performer: 'Анна' }],
  register_share: 50,
  staff: [
    { number: 111, holder: 'Глав Врач', wage: 300, bonus: 0, owed: 0, frozen: 0, away: 0 },
    { number: 222, holder: 'Анна', wage: 150, bonus: 10, owed: 40, frozen: 0, away: 0 },
  ],
  owed_wages: 40,
  is_science: 0,
  grant_left: 0,
  grant_resets_in: 0,
};

const setup = (data: Partial<BudgetData> = {}, console = false) => {
  let now = Date.now();
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'NtosDepartmentBudget' }, data: { ...base, ...data } }));
  return { ...render(console ? <DepartmentConsole /> : <NtosDepartmentBudgetContent />), topic, store };
};

const sent = (topic: jest.Mock, action: string) =>
  topic.mock.calls
    .map(([message]) => message)
    .filter((message) => message.type === `act/${action}`)
    .map((message) => JSON.parse(message.payload));

/** Весь текст окна вместе с пояснениями, свёрнутыми под "?". */
const text = (container: HTMLElement) => {
  container.querySelectorAll('.NtTerm__helpToggle:not(.NtTerm__helpToggle--open)').forEach((toggle) => fireEvent.click(toggle));
  return (container.textContent || '').replace(/\u00a0/g, ' ');
};

const commit = (input: Element, value: string) => {
  fireEvent.focus(input);
  fireEvent.input(input, { target: { value } });
  fireEvent.blur(input);
};

describe('NtosDepartmentBudget', () => {
  test('обзор: баланс, грант, зарплаты и предупреждение аудита без порога', () => {
    const { container } = setup();
    const content = text(container);
    expect(content).toContain('4 000 кр.');
    expect(content).toContain('раз в 5 мин.: 100% окладов сотрудников на смене и 100 кр. на закупки из каталога.');
    expect(content).toContain('не больше 6 базовых окладов');
    expect(content).toContain('долг гасится частями');
    expect(content).toContain('меньше 30 кр., NT доплачивает');
    expect(content).toContain('Кто дольше 10 мин. мёртв или не на смене, зарплату не получает');
    expect(content).not.toContain('в игре');
    expect(content).toContain('Премия себе и крупные или частые выплаты одному человеку');
    expect(content).toContain('Аудит ведут: глава СБ и капитан.');
    expect(content).toContain('Глав Врач (вы)');
  });

  test('порог бюджета и предупреждение о возврате NT', () => {
    const { container } = setup();
    expect(text(container)).toContain('9 000 кр.: 6 окладов сотрудников на смене');
    expect(text(container)).toContain('Раз в 5 мин. 10% излишка сверх порога возвращается NT');
    expect(text(container)).not.toContain('Бюджет выше порога');
    const over = setup({
      department: { id: 'MED', name: 'Медицина', balance: 12000, owed: 0, staff_on_shift: 3, grant: 400, threshold: 9000, return_due: 300 },
    });
    expect(text(over.container)).toContain('Бюджет выше порога: через несколько минут NT заберёт 300 кр. Потратьте');
    expect(text(over.container)).toContain('Потратьте излишек на закупки или назначьте цель накопления');
  });

  test('после снятой цели видно перерыв, копить нельзя', () => {
    const { container, getByText } = setup({
      department: { id: 'MED', name: 'Медицина', balance: 4000, owed: 0, staff_on_shift: 3, grant: 400, threshold: 9000, return_due: 0, goal_cooldown: 12 },
    });
    expect(text(container)).toContain('Новую цель можно поставить через 12 мин.');
    fireEvent.click(getByText('Каталог'));
    expect(getByText('Копить').closest('.Button')?.className).toContain('Button--disabled');
  });

  test('без базовой части грант только от окладов', () => {
    const { container } = setup({
      department: { id: 'CIV', name: 'Гражданские', balance: 900, owed: 0, staff_on_shift: 4, grant: 100, grant_has_base: 0 },
    });
    expect(text(container)).toContain('100% окладов сотрудников на смене.');
    expect(text(container)).not.toContain('на закупки из каталога');
  });

  test('глава: премия, надбавка, запрос в казну и накладная', () => {
    const { container, getAllByText, getByText, getByPlaceholderText, topic } = setup();
    const inputs = container.querySelectorAll('input');
    commit(inputs[2], '25');
    commit(inputs[3], '300');
    fireEvent.click(getAllByText('Надбавка')[2]);
    fireEvent.click(getAllByText('Премия')[2]);
    expect(sent(topic, 'wage_bonus')).toEqual([{ number: 222, percent: 25 }]);
    expect(getAllByText('Надбавка')[1].closest('.Button')?.className).toContain('Button--disabled');
    fireEvent.click(getAllByText('Надбавка')[1]);
    expect(sent(topic, 'wage_bonus')).toHaveLength(1);
    expect(sent(topic, 'bonus')).toEqual([{ number: 222, amount: 300 }]);
    commit(inputs[4], '700');
    fireEvent.input(getByPlaceholderText('На что нужны деньги'), { target: { value: 'ремонт' } });
    fireEvent.click(getByText('Запросить'));
    expect(sent(topic, 'treasury_request')).toEqual([{ amount: 700, reason: 'ремонт' }]);
    fireEvent.click(getByText('Накладная: Медицина'));
    expect(sent(topic, 'print_manifest')).toHaveLength(1);
  });

  test('надбавка в поле обновляется, когда её поменял другой', () => {
    const { container, store, rerender } = setup();
    const staff = [base.staff![0], { ...base.staff![1], bonus: 30 }];
    store.dispatch(backendUpdate({ data: { ...base, staff } }));
    rerender(<NtosDepartmentBudgetContent />);
    expect((container.querySelectorAll('input')[2] as HTMLInputElement).value).toBe('30');
  });

  test('глава: одобрить и отклонить заявку, заказать пак', () => {
    const { getByText, topic } = setup();
    fireEvent.click(getByText('Заявки'));
    fireEvent.click(getByText('Одобрить'));
    fireEvent.click(getByText('Отклонить'));
    expect(sent(topic, 'approve')).toEqual([{ uid: 5 }]);
    expect(sent(topic, 'deny')).toEqual([{ uid: 5 }]);
    fireEvent.click(getByText('Каталог'));
    fireEvent.click(getByText('Заказать'));
    expect(sent(topic, 'order')).toEqual([{ pack: '/datum/supply_pack/medical/surgery' }]);
    fireEvent.click(getByText('Копить'));
    expect(sent(topic, 'set_goal')).toEqual([{ pack: '/datum/supply_pack/medical/surgery' }]);
  });

  test('цель накопления и защищённые поступления видны, цель снимается', () => {
    const goal = { id: '/datum/supply_pack/medical/surgery', name: 'Surgical Kit', amount: 1200, minutes_left: 25 };
    const { container, getByText, topic } = setup({
      department: { id: 'MED', name: 'Медицина', balance: 4000, owed: 0, staff_on_shift: 3, grant: 400, threshold: 9000, return_due: 0, shielded: 500, goal },
      catalog: [
        { type: '/datum/supply_pack/medical/surgery', name: 'Surgical Kit', desc: 'Набор хирурга' },
        { type: '/datum/supply_pack/medical/bloodpacks', name: 'Blood Pack Variety Crate', desc: 'Кровь' },
      ],
      prices: {
        '/datum/supply_pack/medical/surgery': { price: 1200, available: 1 },
        '/datum/supply_pack/medical/bloodpacks': { price: 900, available: 1 },
      },
    });
    expect(text(container)).toContain('Surgical Kit, 1 200 кр., ещё 25 мин.');
    expect(text(container)).toContain('500 кр. недавних поступлений пока не считаются излишком');
    expect(text(container)).toContain('Цель уже выбрана: чтобы выбрать другую, снимите эту в каталоге.');
    fireEvent.click(getByText('Каталог'));
    expect(getByText('Копить').closest('.Button')?.className).toContain('Button--disabled');
    fireEvent.click(getByText('Цель'));
    expect(sent(topic, 'clear_goal')).toHaveLength(1);
  });

  test('сотрудник: без одобрения и премий, заявка с причиной', () => {
    const { container, getByText, queryByText, getByPlaceholderText, topic } = setup({ can_manage: 0, staff: [] });
    expect(queryByText('Премия')).toBeNull();
    fireEvent.click(getByText('Заявки'));
    expect(queryByText('Одобрить')).toBeNull();
    expect(text(container)).toContain('ждёт решения');
    fireEvent.click(getByText('Каталог'));
    expect(queryByText('Заказать')).toBeNull();
    expect(text(container)).toContain('заявка до 1000 кр. одобряется сама');
    expect(text(container)).toContain('Если ответа нет 10 мин., такая заявка одобряется сама и при начальстве на смене.');
    fireEvent.input(getByPlaceholderText('Причина заявки'), { target: { value: 'бинты' } });
    fireEvent.click(getByText('Заявка'));
    expect(sent(topic, 'request')).toEqual([{ pack: '/datum/supply_pack/medical/surgery', reason: 'бинты' }]);
  });

  test('чужой отдел у консоли: ни заявок, ни заказов', () => {
    const { getByText, queryByText } = setup({ can_manage: 0, is_staff: 0, staff: [] }, true);
    fireEvent.click(getByText('Каталог'));
    expect(queryByText('Заявка')).toBeNull();
    expect(getByText('Заявки подают только сотрудники отдела.')).toBeTruthy();
  });

  test('контракты, работа и касса', () => {
    const { container, getByText, topic } = setup();
    fireEvent.click(getByText('Контракты'));
    expect(text(container)).toContain('Контракты NT: справка.');
    fireEvent.click(getByText('Взять'));
    expect(sent(topic, 'take')).toEqual([{ uid: 7 }]);
    fireEvent.click(getByText('Работа'));
    expect(text(container)).toContain('за реанимацию');
    expect(text(container)).toContain('ещё 10% сверху');
    fireEvent.click(getByText('Касса'));
    expect(text(container)).toContain('доля кассира идёт ему лично');
    commit(container.querySelector('input') as Element, '30');
    fireEvent.click(getByText('Сохранить'));
    expect(sent(topic, 'register_share')).toEqual([{ percent: 30 }]);
  });

  test('грант только у науки', () => {
    const plain = setup();
    expect(plain.queryByText('Грант')).toBeNull();
    plain.unmount();
    const { container, getByText, topic } = setup({ is_science: 1, grant_left: 400, grant_resets_in: 20 });
    fireEvent.click(getByText('Грант'));
    expect(text(container)).toContain('3 кр. за очко');
    expect(text(container)).toContain('лимит обновится через 20 мин.');
    commit(container.querySelector('input') as Element, '100');
    fireEvent.click(getByText('Купить'));
    expect(sent(topic, 'research_grant')).toEqual([{ points: 100 }]);
  });

  test('капитан выбирает отдел, без отдела - подсказка', () => {
    const { container, getByText, topic } = setup({ can_switch: 1, has_department: 0, department: undefined });
    expect(text(container)).toContain('Выберите отдел выше.');
    fireEvent.click(getByText('Наука'));
    expect(sent(topic, 'select_department')).toEqual([{ id: 'SCI' }]);
  });
});

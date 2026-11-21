import { fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { BudgetData, DepartmentConsole, NtosDepartmentBudgetContent, ordersItself, requestTooltip } from './NtosDepartmentBudget';

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
  goal_collect_minutes: 60,
  economy_minutes: 5,
  wage_minutes: 10,
  owed_cap: 6,
  wage_floor: 30,
  dormant_minutes: 10,
  max_wage_bonus: 50,
  bonus_cap_hour: 3000,
  bonus_self_cap_hour: 2500,
  express_markup: 50,
  express_cooldown: 10,
  treasury_max: 5000,
  treasury_pending_max: 2,
  auto_approve_limit: 1000,
  auto_approve_cooldown: 10,
  auto_approve_wait: 10,
  staple_cap: 6000,
  handoff_minutes: 20,
  pending_per_requester: 3,
  handling_fee: 12,
  work_share: 10,
  work_cap: 1500,
  performer_share: 30,
  contracts_help_topics: [{ title: 'Как выполнить', lines: ['Контракты NT: справка.'] }],
  audit_rights: 'глава СБ и капитан',
  audit_bonus_allowance: 3000,
  audit_siphon_minutes: 30,
  grant_price: 3,
  grant_cap: 10000,
  message: '',
  can_switch: 0,
  has_department: 1,
  my_account: 111,
  manifest_department: 'Медицина',
  can_manage: 1,
  is_staff: 1,
  department: { id: 'MED', name: 'Медицина', balance: 4000, owed: 0, staff_on_shift: 3, grant: 400, grant_max: 500, grant_level: 9600, grant_has_base: 1, threshold: 9000, return_due: 0 },
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
    { number: 111, holder: 'Глав Врач', wage: 300, bonus: 0, bonus_left: 2500, owed: 0, frozen: 0, away: 0 },
    { number: 222, holder: 'Анна', wage: 150, bonus: 10, bonus_left: 3000, owed: 40, frozen: 0, away: 0 },
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
    expect(content).toContain('Грант NT доливает бюджет раз в 5 мин. до 9 600 кр.: порог бюджета, долги и следующая зарплата сотрудникам и цель накопления.');
    expect(content).toContain('За цикл не больше 500 кр.: 100% окладов сотрудников на смене и 100 кр. на закупки из каталога.');
    expect(content).toContain('400 кр. на ближайшем цикле');
    expect(content).toContain('не больше 6 базовых окладов');
    expect(content).toContain('долг гасится частями');
    expect(content).toContain('меньше 30 кр., NT доплачивает');
    expect(content).toContain('Кто дольше 10 мин. мёртв или не на смене, зарплату не получает');
    expect(content).not.toContain('в игре');
    expect(content).toContain('Премия себе открывает дело финансового аудита, премии сотрудникам в пределах лимита - нет.');
    expect(content).not.toContain('3 000 кр. за 30 мин.');
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
    expect(text(over.container)).toContain('Потратьте излишек на закупки, одобрите ждущие заявки или назначьте цель накопления');
    over.unmount();
    const soon = setup({ department: { ...base.department!, balance: 12000, return_due: 300, return_in: 4 } });
    expect(text(soon.container)).toContain('Бюджет выше порога: через 4 мин. NT заберёт 300 кр.');
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

  test('премия не больше часового лимита сотрудника', () => {
    const staff = [
      { ...base.staff![0], bonus_left: 0 },
      { ...base.staff![1], bonus_left: 100 },
    ];
    const { container, getAllByText, topic } = setup({ staff });
    const inputs = container.querySelectorAll('input');
    commit(inputs[1], '50');
    expect(getAllByText('Премия')[1].closest('.Button')?.className).toContain('Button--disabled');
    commit(inputs[3], '300');
    fireEvent.click(getAllByText('Премия')[2]);
    expect(sent(topic, 'bonus')).toEqual([{ number: 222, amount: 100 }]);
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

  test('капсула: шлёт express с паком, пока отдел ждёт следующую - недоступна', () => {
    const ui = setup();
    fireEvent.click(ui.getByText('Каталог'));
    fireEvent.click(ui.getByText('Капсулой'));
    expect(sent(ui.topic, 'express')).toEqual([{ pack: '/datum/supply_pack/medical/surgery' }]);
    ui.unmount();
    const waiting = setup({ department: { ...base.department!, express_ready_in: 300 } });
    fireEvent.click(waiting.getByText('Каталог'));
    expect(waiting.getByText('Капсулой').closest('.Button')?.className).toContain('Button--disabled');
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
    expect(text(container)).toContain('Surgical Kit, 1 200 кр., набрано, заказать за 25 мин.');
    expect(text(container)).toContain('1 200 кр. из 1 200 кр.');
    expect(text(container)).toContain('500 кр. недавних поступлений пока не считаются излишком');
    expect(text(container)).toContain('Цель уже выбрана: чтобы выбрать другую, снимите эту в каталоге.');
    expect(text(container)).not.toContain('Красный код');
    fireEvent.click(getByText('Каталог'));
    expect(getByText('Копить').closest('.Button')?.className).toContain('Button--disabled');
    fireEvent.click(getByText('Цель'));
    expect(sent(topic, 'clear_goal')).toHaveLength(1);
  });

  test('цель без срока, пока бюджет копит, но со сроком на сбор; при красном коде излишек не забирают', () => {
    const goal = { id: '/datum/supply_pack/medical/surgery', name: 'Surgical Kit', amount: 12000, minutes_left: null, collect_minutes_left: 40 };
    const { container } = setup({
      department: { id: 'MED', name: 'Медицина', balance: 4000, owed: 0, staff_on_shift: 3, grant: 400, threshold: 9000, return_due: 0, goal, emergency: 1 },
    });
    expect(text(container)).toContain('Surgical Kit, 12 000 кр., копим: набрать за 40 мин., иначе цель снимется; срок на заказ пойдёт, когда бюджет наберёт цену');
    expect(text(container)).toContain('4 000 кр. из 12 000 кр.');
    expect(text(container)).toContain('(ставится в каталоге; набрать её цену нужно за 60 мин., иначе цель снимется; набрали - 30 мин. на заказ;');
    expect(text(container)).toContain('Красный код: пока его не снимут, NT не забирает излишек бюджета.');
  });

  const cargo: Partial<BudgetData> = {
    catalog: [{ type: '/datum/supply_pack/department/cargo_mining_kit', name: 'Mining Expedition Kit', desc: 'Бур' }],
    prices: { '/datum/supply_pack/department/cargo_mining_kit': { price: 1800, available: 1 } },
    department: { id: 'CAR', name: 'Снабжение', balance: 40000, owed: 0, staff_on_shift: 3, grant: 400, threshold: 30000, return_due: 0 },
    goal_max: 200000,
    goal_erts: [
      { id: 1, name: 'Доставщики Питцы', price: 25000, available: 1 },
      { id: 6, name: 'Отряд Быстрого Реагирования', price: 200000, available: 0 },
    ],
    goal_packs: [
      { type: '/datum/supply_pack/security/armory/pact_ninja_case', name: 'PACT Ninja Case', group: 'Armory', price: 31000, available: 1 },
      { type: '/datum/supply_pack/misc/paper', name: 'Bureaucracy Crate', group: 'Miscellaneous', price: 900, available: 1 },
    ],
  };

  test('снабжение копит на отряд ОБР и пак вне каталога, поиск по пакам', () => {
    const { container, getByText, getAllByText, getByPlaceholderText, queryByText, topic } = setup(cargo);
    fireEvent.click(getByText('Каталог'));
    expect(text(container)).toContain('или на любой пак, который оно заказывает за свой бюджет, до 200 000 кр.');
    expect(text(container)).toContain('уже вызван');
    const buttons = getAllByText('Копить');
    expect(buttons).toHaveLength(5);
    expect(buttons[2].closest('.Button')?.className).toContain('Button--disabled');
    fireEvent.click(buttons[1]);
    expect(sent(topic, 'set_goal')).toEqual([{ ert: 1 }]);
    expect(container.textContent!.indexOf('PACT Ninja Case')).toBeLessThan(container.textContent!.indexOf('Bureaucracy Crate'));
    fireEvent.input(getByPlaceholderText('Найти пак снабжения'), { target: { value: 'ninja' } });
    expect(queryByText('Bureaucracy Crate')).toBeNull();
    fireEvent.click(getAllByText('Копить')[3]);
    expect(sent(topic, 'set_goal')).toEqual([{ ert: 1 }, { pack: '/datum/supply_pack/security/armory/pact_ninja_case' }]);
  });

  test('цель снабжения на ОБР: срок на вызов, снимается из каталога; у других отделов раздела нет', () => {
    const goal = { id: 'ert:1', name: 'Доставщики Питцы', amount: 25000, is_ert: 1, minutes_left: 20 };
    const { container, getByText, topic, unmount } = setup({ ...cargo, department: { ...cargo.department!, goal } });
    expect(text(container)).toContain('Доставщики Питцы, 25 000 кр., набрано, отряд вызывает капитан с консоли связи, осталось 20 мин.');
    expect(text(container)).toContain('или на отряд ОБР, его вызывает капитан с консоли связи; набрать её цену');
    fireEvent.click(getByText('Каталог'));
    fireEvent.click(getByText('Цель'));
    expect(sent(topic, 'clear_goal')).toHaveLength(1);
    unmount();
    const medical = setup();
    fireEvent.click(medical.getByText('Каталог'));
    expect(medical.container.textContent).not.toContain('Копить на дорогое');
  });

  test('цель снабжения на пак вне каталога: отгрузить шаттлом или заказать с экспресс-консоли', () => {
    const goal = { id: '/datum/supply_pack/security/armory/pact_ninja_case', name: 'PACT Ninja Case', amount: 31000, off_catalog: 1, minutes_left: 10 };
    const { container } = setup({ ...cargo, department: { ...cargo.department!, goal } });
    expect(text(container)).toContain('PACT Ninja Case, 31 000 кр., набрано, отгрузите шаттлом снабжения или закажите с экспресс-консоли за 10 мин.');
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
    fireEvent.input(getByPlaceholderText('Причина заявки'), { target: { value: 'бинты' } });
    fireEvent.click(getByText('Заявка'));
    expect(sent(topic, 'request')).toEqual([{ pack: '/datum/supply_pack/medical/surgery', reason: 'бинты' }]);
  });

  test('сотрудник: недорогой пак при мгновенном одобрении заказывается сразу, после заказа - перерыв', () => {
    const cheap = { prices: { '/datum/supply_pack/medical/surgery': { price: 800, available: 1 } } };
    const ready = setup({ ...cheap, can_manage: 0, staff: [], instant_approval: 1, auto_ready_in: 0 });
    fireEvent.click(ready.getByText('Каталог'));
    expect(text(ready.container)).toContain('Заявка до 1 000 кр. одобряется сама сразу, не чаще раза в 10 мин. на сотрудника.');
    expect(text(ready.container)).not.toContain('Если на смене некому одобрить');
    expect(text(ready.container)).toContain('Если ответа нет 10 мин., недорогая заявка одобряется сама и при начальстве на смене.');
    fireEvent.click(ready.getByText('Заказать'));
    expect(sent(ready.topic, 'request')).toEqual([{ pack: '/datum/supply_pack/medical/surgery', reason: '' }]);
    ready.unmount();
    const waiting = setup({ ...cheap, can_manage: 0, staff: [], instant_approval: 1, auto_ready_in: 7 });
    fireEvent.click(waiting.getByText('Каталог'));
    expect(waiting.queryByText('Заказать')).toBeNull();
    expect(waiting.getByText('Заявка')).toBeTruthy();
    waiting.unmount();
    const security = setup({ ...cheap, can_manage: 0, staff: [], instant_approval: 0, auto_ready_in: 0 });
    fireEvent.click(security.getByText('Каталог'));
    expect(security.queryByText('Заказать')).toBeNull();
    expect(text(security.container)).toContain('Если на смене некому одобрить, заявка до 1000 кр. одобряется сама');
    expect(text(security.container)).not.toContain('Если ответа нет');
  });

  test('сотрудник: заказ без одобрения не трогает деньги на зарплату, подсказка объясняет, чего ждёт заявка', () => {
    const cheap = { prices: { '/datum/supply_pack/medical/surgery': { price: 800, available: 1 } } };
    const staffView = { ...cheap, can_manage: 0, staff: [], instant_approval: 1, auto_ready_in: 0 };
    const reserved = setup({ ...staffView, department: { ...base.department!, balance: 1500, reserve: 800 } });
    fireEvent.click(reserved.getByText('Каталог'));
    expect(reserved.queryByText('Заказать')).toBeNull();
    expect(text(reserved.container)).toContain('после заказа в бюджете останется на долги и следующую зарплату сотрудникам (сейчас 800 кр.)');
    reserved.unmount();
    const enough = setup({ ...staffView, department: { ...base.department!, balance: 1600, reserve: 800 } });
    fireEvent.click(enough.getByText('Каталог'));
    expect(enough.getByText('Заказать')).toBeTruthy();
    enough.unmount();
    const data = { ...base, ...staffView } as BudgetData;
    expect(requestTooltip({ ...data, department: { ...base.department!, balance: 500 } }, 800).replace(/\u00a0/g, ' ')).toBe('В бюджете сейчас 500 кр., пак стоит 800 кр.: заявка подождёт денег');
    expect(requestTooltip({ ...data, head_on_shift: 1 }, 800)).toBe('Заявка главе: ему придёт сообщение на карту');
    expect(requestTooltip({ ...data, head_on_shift: 0 }, 800)).not.toContain('главе');
    expect(ordersItself({ ...data, department: { ...base.department!, balance: 1500, reserve: 800 } }, { staple: 1 }, 800)).toBe(false);
  });

  test('на что тратить бюджет: советы и "нужно сейчас" с кнопкой', () => {
    const needs = [{ type: '/datum/supply_pack/medical/surgery', name: 'Surgical Kit', why: 'Раненых на станции: 3' }];
    const advice = ['Кровь, бинты и мази кончаются первыми.'];
    const head = setup({ needs, advice });
    expect(text(head.container)).toContain('На что тратить бюджет');
    expect(text(head.container)).toContain('Кровь, бинты и мази кончаются первыми.');
    expect(text(head.container)).toContain('Раненых на станции: 3');
    fireEvent.click(head.getByText('Заказать'));
    expect(sent(head.topic, 'order')).toEqual([{ pack: '/datum/supply_pack/medical/surgery' }]);
    head.unmount();
    const staff = setup({ needs, advice, can_manage: 0, staff: [], instant_approval: 1, auto_ready_in: 0 });
    fireEvent.click(staff.getByText('Заявка'));
    expect(sent(staff.topic, 'request')).toEqual([{ pack: '/datum/supply_pack/medical/surgery', reason: 'Раненых на станции: 3' }]);
    staff.unmount();
    const outsider = setup({ needs, advice, can_manage: 0, is_staff: 0, staff: [] });
    expect(text(outsider.container)).toContain('Раненых на станции: 3');
    expect(outsider.queryByText('Заявка')).toBeNull();
    outsider.unmount();
    const empty = setup({ needs: [], advice: [] });
    expect(text(empty.container)).not.toContain('На что тратить бюджет');
  });

  test('скупка для отдела: глава берёт пачку за бюджет, сотрудник видит, кто её берёт', () => {
    const bundles = [
      {
        uid: 4,
        partner: 'Вей-Мед',
        packs: ['Medical Supplies Crate', 'Blood Pack Variety Crate'],
        need: 'Blood Pack Variety Crate',
        need_why: 'Мало крови у 2 чел. по датчикам костюмов',
        full_value: 3000,
        price: 2200,
        discount: 27,
        left: 600,
        can_budget: 1,
      },
    ];
    const head = setup({ bundles });
    expect(text(head.container)).toContain('Скупка для отдела');
    expect(text(head.container)).toContain('Medical Supplies Crate, Blood Pack Variety Crate');
    expect(text(head.container)).toContain('Нужно сейчас: Blood Pack Variety Crate - Мало крови');
    fireEvent.click(head.getByText('Купить пачку'));
    expect(sent(head.topic, 'buy_bundle')).toEqual([{ uid: 4 }]);
    head.unmount();
    const first = setup({ bundles: [{ ...bundles[0], department_left: 240 }], bundle_first: 5 });
    expect(text(first.container)).toContain('для отдела ещё 4 мин.');
    expect(text(first.container)).toContain('первые 5 мин. пачку берут только за бюджет отдела');
    first.unmount();
    const staff = setup({ bundles: [{ ...bundles[0], can_budget: 0 }], can_manage: 0, staff: [] });
    expect(staff.queryByText('Купить пачку')).toBeNull();
    expect(text(staff.container)).toContain('Берёт глава, ГП или капитан');
    staff.unmount();
    const empty = setup({ bundles: [] });
    expect(text(empty.container)).not.toContain('Скупка для отдела');
  });

  test('грант не нужен, когда бюджет на уровне', () => {
    const { container } = setup({ department: { ...base.department!, grant: 0 } });
    expect(text(container)).toContain('не нужен: бюджет не ниже 9 600 кр.');
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

  test('заявка: сколько ждёт, кто решит и что дальше; глава копит на дорогую', () => {
    const requests = [
      { ...base.requests![0], price: 9000, pack_type: '/datum/supply_pack/medical/surgery', waited: 12, outlook: 'Решает ИИ; через 8 мин. без решения перейдёт и начальнику снабжения.', can_decide: 1 },
    ];
    const { container, getByText, topic } = setup({ requests, deciders: 'ИИ' });
    fireEvent.click(getByText('Заявки'));
    const content = text(container);
    expect(content).toContain('Решает сейчас');
    expect(content).toContain('Ждёт 12 мин. Решает ИИ; через 8 мин. без решения перейдёт и начальнику снабжения.');
    expect(content).toContain('Решают глава отдела, ГП и капитан');
    fireEvent.click(getByText('Копить'));
    expect(sent(topic, 'set_goal')).toEqual([{ pack: '/datum/supply_pack/medical/surgery' }]);
  });

  test('без решающих на смене окно так и говорит, а цель при нехватке не предлагает сотруднику', () => {
    const requests = [{ ...base.requests![0], price: 9000, pack_type: '/datum/supply_pack/medical/surgery', can_decide: 0 }];
    const { container, getByText, queryByText } = setup({ requests, deciders: null, can_manage: 0, staff: [] });
    fireEvent.click(getByText('Заявки'));
    expect(text(container)).toContain('никого нет на смене');
    expect(queryByText('Одобрить')).toBeNull();
    expect(queryByText('Копить')).toBeNull();
  });

  test('ИИ: выбирает отдел, решает заявки, но не заказывает и не подаёт', () => {
    const requests = [{ ...base.requests![0], can_decide: 1 }];
    const { container, getByText, queryByText, topic } = setup({
      requests,
      is_ai: 1,
      ai_decides: 1,
      can_switch: 1,
      can_manage: 0,
      is_staff: 0,
      staff: [],
      staple_left: null,
    });
    expect(text(container)).toContain('ИИ открывает бюджет любого отдела и решает заявки сотрудников, кроме заявок СБ.');
    expect(queryByText('Премия')).toBeNull();
    fireEvent.click(getByText('Заявки'));
    fireEvent.click(getByText('Одобрить'));
    fireEvent.click(getByText('Отклонить'));
    expect(sent(topic, 'approve')).toEqual([{ uid: 5 }]);
    expect(sent(topic, 'deny')).toEqual([{ uid: 5 }]);
    expect(queryByText('Копить')).toBeNull();
    fireEvent.click(getByText('Каталог'));
    expect(queryByText('Заказать')).toBeNull();
    expect(queryByText('Заявка')).toBeNull();
    expect(text(container)).toContain('ИИ решает их во вкладке "Заявки"');
  });

  test('сотрудник заказывает расходник сам, пока хватает часового лимита', () => {
    const catalog = [
      { type: '/datum/supply_pack/materials/glass50', name: '50 Glass Sheets', desc: 'Стекло', staple: 1 },
      { type: '/datum/supply_pack/medical/surgery', name: 'Surgical Kit', desc: 'Набор хирурга' },
    ];
    const prices = {
      '/datum/supply_pack/materials/glass50': { price: 2700, available: 1 },
      '/datum/supply_pack/medical/surgery': { price: 2500, available: 1 },
    };
    const ui = setup({ catalog, prices, can_manage: 0, staff: [], staple_left: 3300 });
    fireEvent.click(ui.getByText('Каталог'));
    expect(text(ui.container)).toContain('расходник');
    expect(text(ui.container)).toContain('до 6 000 кр. за час, осталось 3 300 кр.');
    expect(text(ui.container)).toContain('Заявку без решения 20 мин. может решить и начальник снабжения');
    fireEvent.click(ui.getByText('Заказать'));
    expect(sent(ui.topic, 'request')).toEqual([{ pack: '/datum/supply_pack/materials/glass50', reason: '' }]);
    expect(ui.getAllByText('Заявка')).toHaveLength(1);
    ui.unmount();
    const spent = setup({ catalog, prices, can_manage: 0, staff: [], staple_left: 1000 });
    fireEvent.click(spent.getByText('Каталог'));
    expect(spent.queryByText('Заказать')).toBeNull();
    expect(spent.getAllByText('Заявка')).toHaveLength(2);
  });

  test('начальник снабжения видит переданные заявки других отделов и решает их за их бюджет', () => {
    const handoff = [
      {
        uid: 4,
        pack: 'Industrial RCD',
        price: 8800,
        requester: 'Инженер',
        reason: '',
        status: 'pending' as const,
        waited: 25,
        outlook: 'Решает начальник снабжения.',
        can_decide: 1,
        department: 'Инженерия',
        department_id: 'ENG',
        balance: 20000,
        handed_off: 1,
      },
    ];
    const cargoDepartment = { id: 'CAR', name: 'Снабжение', balance: 40000, owed: 0, staff_on_shift: 3, grant: 400, threshold: 30000, return_due: 0 };
    const { container, getByText, topic, unmount } = setup({ department: cargoDepartment, requests: [], handoff_requests: handoff });
    fireEvent.click(getByText('Заявки'));
    expect(text(container)).toContain('Заявки отделов, переданные снабжению');
    expect(text(container)).toContain('Инженерия, в бюджете 20 000 кр.');
    fireEvent.click(getByText('Одобрить'));
    expect(sent(topic, 'approve')).toEqual([{ uid: 4, department: 'ENG' }]);
    unmount();
    const medical = setup();
    fireEvent.click(medical.getByText('Заявки'));
    expect(medical.container.textContent).not.toContain('переданные снабжению');
  });

  test('капитан выбирает отдел, без отдела - подсказка', () => {
    const { container, getByText, topic } = setup({ can_switch: 1, has_department: 0, department: undefined });
    expect(text(container)).toContain('Выберите отдел выше.');
    fireEvent.click(getByText('Наука'));
    expect(sent(topic, 'select_department')).toEqual([{ id: 'SCI' }]);
  });
});

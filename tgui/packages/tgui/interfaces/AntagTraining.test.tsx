import { fireEvent, render, within } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { AntagTraining, AntagTrainingData, Exercise } from './AntagTraining';

const fixture: AntagTrainingData = {
  preparing: 0,
  supply_ready: 1,
  practice_ready: 1,
  last_feedback: null,
  last_kit: null,
  kits: [{ id: 'medicine', name: 'Первая помощь' }],
  paths: [
    { id: 'blade', name: 'Клинок', desc: 'Парирование и ответ' },
    { id: 'ash', name: 'Пепел', desc: 'Огонь и перемещение' },
  ],
  selected_path: null,
  path_stage: 0,
  recipes: [],
  resource: null,
  practice: null,
  exercises: [],
  duel: null,
  duel_ready: 1,
  last_duel_result: null,
  program: 'Еретик — все пути',
  program_id: '/datum/antag_training_program/heretic',
  auto_recover: 1,
  health: 100,
  max_health: 100,
  busy: 0,
  return_to_body: 0,
  target_limit: 12,
  supply_count: 0,
  supply_limit: 100,
  structure_count: 0,
  structure_limit: 16,
  build_error: null,
  cleaning_personal: 0,
  reset_vote: null,
  members: [{ id: 'member', name: 'Участник', program: 'Еретик', health: 100, max_health: 100, dead: 0, connected: 1, zone: 'Безопасный центр', defeats: 0, self: 1 }],
  zones: [
    { id: 'hub', name: 'Безопасный центр', desc: 'Подготовка', current: 1, members: 1, targets: 0 },
    { id: 'pve', name: 'Арена противников', desc: 'Бой с ИИ', current: 0, members: 0, targets: 0 },
  ],
  sectors: [{ id: 'dark', name: 'Тёмный сектор', desc: 'Комнаты без света', state: 'unloaded', members: 0, current: 0 }],
  sector_idle_minutes: 5,
  equipment: [{ id: 'laser', name: 'Лазерный карабин', category: 'Стрельба' }],
  structures: [{ id: 'operating_table', name: 'Операционный стол', category: 'Медицина и химия', desc: 'Для операций и осмотра пациента.' }],
  injuries: [{ id: 'burn', name: 'Ожоги: +40' }],
  conditions: [{ id: 'knockdown', name: 'Сбить с ног на 10 с' }],
  creatures: [{ id: 'human', name: 'Человек без брони' }, { id: 'carp', name: 'Карп' }],
  targets: [],
  programs: [{ id: '/datum/antag_training_program/heretic', name: 'Еретик — все пути', category: 'Культы и магия', desc: 'Пути и вознесение' }],
  options: ['Добавить очки знаний'],
  heretic: 1,
  target_action: 'Цель охоты',
};

let now = Date.now();

const setup = (overrides: Partial<AntagTrainingData> = {}) => {
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'AntagTraining' }, data: { ...fixture, ...overrides } }));
  return { ...render(<AntagTraining />), topic };
};

test('любой участник может запросить сброс сектора после подтверждения', () => {
  const ui = setup();
  fireEvent.click(ui.getByText('Зоны'));
  fireEvent.click(ui.getByText('Сброс'));
  expect(ui.topic.mock.calls.some(([message]) => message.type === 'act/reset_zone')).toBe(false);
  fireEvent.click(ui.getByText('Запросить сброс?'));
  const call = ui.topic.mock.calls.find(([message]) => message.type === 'act/reset_zone');
  expect(JSON.parse(call[0].payload)).toEqual({ zone: 'pve' });
});

test('незагруженный сектор показан под картой ядра и загружается по кнопке', () => {
  const ui = setup();
  fireEvent.click(ui.getByText('Зоны'));
  const card = ui.getByText('Тёмный сектор').closest('.AntagTraining__sector') as HTMLElement;
  expect(within(card).getByText('Не загружен')).toBeTruthy();
  expect(within(card).queryByText('Сброс')).toBeNull();
  expect(ui.getByText('Сектор грузится при первом входе и выгружается через 5 минут без участников.')).toBeTruthy();
  fireEvent.click(within(card).getByText('Загрузить и перейти'));
  const call = ui.topic.mock.calls.find(([message]) => message.type === 'act/sector_enter');
  expect(JSON.parse(call[0].payload)).toEqual({ id: 'dark' });
});

test('готовый сектор переходит и сбрасывается голосованием', () => {
  const ui = setup({ sectors: [{ ...fixture.sectors[0], state: 'ready', members: 2, current: 1 }] });
  fireEvent.click(ui.getByText('Зоны'));
  const card = ui.getByText('Тёмный сектор').closest('.AntagTraining__sector') as HTMLElement;
  expect(within(card).getByText('Готов')).toBeTruthy();
  expect(within(card).getByText('Вы здесь')).toBeTruthy();
  fireEvent.click(within(card).getByText('Сброс'));
  fireEvent.click(within(card).getByText('Запросить сброс?'));
  fireEvent.click(within(card).getByText('Перейти'));
  expect(ui.topic.mock.calls.filter(([message]) => message.type.startsWith('act/')).map(([message]) => [message.type, JSON.parse(message.payload)])).toEqual([
    ['act/reset_zone', { zone: 'dark' }], ['act/sector_enter', { id: 'dark' }],
  ]);
});

test.each([
  ['loading', 'Загружается…'],
  ['unloading', 'Выгружается…'],
] as const)('сектор в работе (%s) показывает состояние без сброса', (state, label) => {
  const ui = setup({ sectors: [{ ...fixture.sectors[0], state }] });
  fireEvent.click(ui.getByText('Зоны'));
  const card = ui.getByText('Тёмный сектор').closest('.AntagTraining__sector') as HTMLElement;
  expect(within(card).getByText(label)).toBeTruthy();
  expect(within(card).queryByText('Сброс')).toBeNull();
});

test.each([
  ['dark', 'moon'],
  ['engineering', 'bolt'],
  ['atmos', 'wind'],
  ['eva', 'user-astronaut'],
  ['robotics', 'robot'],
  ['station', 'building'],
])('дополнительный сектор %s показан своей иконкой', (id, icon) => {
  const ui = setup({ sectors: [{ ...fixture.sectors[0], id, name: `Сектор ${id}` }] });
  fireEvent.click(ui.getByText('Зоны'));
  const card = ui.getByText(`Сектор ${id}`).closest('.AntagTraining__sector') as HTMLElement;
  expect(card.querySelector(`.AntagTraining__sectorHeading .fa-${icon}`)).toBeTruthy();
  expect(card.querySelector('.fa-layer-group')).toBeNull();
});

test.each([
  ['Инженерия', 'bolt'],
  ['Атмос', 'wind'],
  ['Космос', 'user-astronaut'],
  ['Робототехника', 'robot'],
])('категория снаряжения «%s» показана своей иконкой на фильтре и в карточке', (category, icon) => {
  const ui = setup({ equipment: [{ id: 'item', name: 'Предмет', category, desc: 'Описание' }] });
  fireEvent.click(ui.getByText('Снаряжение'));
  expect(ui.getByText(category).closest('.Button')?.querySelector(`.fa-${icon}`)).toBeTruthy();
  const card = ui.getByText('Предмет').closest('.AntagTraining__equipment') as HTMLElement;
  expect(card.querySelector(`.AntagTraining__catalogIcon.fa-${icon}`)).toBeTruthy();
  fireEvent.click(within(card).getByText('Выдать'));
  const call = ui.topic.mock.calls.find(([message]) => message.type === 'act/equipment');
  expect(JSON.parse(call[0].payload)).toEqual({ id: 'item' });
});

test('комплект сектора выдаётся той же командой и объясняет загрузку сектора', () => {
  const ui = setup({ kits: [...fixture.kits, { id: 'eva', name: 'Выход в космос' }] });
  expect(ui.getByText(/незагруженный дополнительный сектор он сначала загрузит/)).toBeTruthy();
  fireEvent.click(ui.getByText('Выход в космос'));
  const call = ui.topic.mock.calls.find(([message]) => message.type === 'act/kit');
  expect(JSON.parse(call[0].payload)).toEqual({ id: 'eva' });
});

test('создание цели отправляет выбранный тип, сектор и режим ИИ', () => {
  const ui = setup({ zones: [...fixture.zones, { id: 'laboratory', name: 'Лаборатория', desc: 'Ритуалы', current: 0, members: 0, targets: 0 }] });
  fireEvent.click(ui.getByText('Цели'));
  fireEvent.click(ui.container.querySelector('.Dropdown__control'));
  fireEvent.click(ui.getByText('Карп'));
  fireEvent.click(ui.container.querySelectorAll('.Dropdown__control')[1]);
  fireEvent.click(ui.getByText('Лаборатория'));
  fireEvent.click(ui.getByText('Активный ИИ'));
  fireEvent.click(ui.getByText('Создать'));
  const call = ui.topic.mock.calls.find(([message]) => message.type === 'act/spawn');
  expect(JSON.parse(call[0].payload)).toEqual({ id: 'carp', zone: 'laboratory', active: true });
});

test.each([
  ['4', 'Основы: ступень 4'],
  ['9', 'Полный путь: ступень 9'],
])('подготовка отправляет выбранный путь и ступень %s', (stage, label) => {
  const ui = setup();
  fireEvent.click(ui.getByText('Моя роль'));
  fireEvent.click(ui.container.querySelectorAll('.Dropdown__control')[0]);
  fireEvent.click(ui.getByText('Пепел'));
  fireEvent.click(ui.container.querySelectorAll('.Dropdown__control')[1]);
  fireEvent.click(ui.getByText(label));
  fireEvent.click(ui.getByText('Изучить до ступени'));
  const call = ui.topic.mock.calls.find(([message]) => message.type === 'act/prepare_path');
  expect(JSON.parse(call[0].payload)).toEqual({ id: 'ash', stage });
});

test('«Моя роль» ведёт программу в её сектор, к упражнениям, сценариям и площадкам', () => {
  const route = {
    sectors: [{ id: 'dark', name: 'Тёмный сектор' }],
    exercises_done: 1,
    exercises_total: 2,
    scenarios: [{ id: 'xeno', name: 'Ксеноморфы', venue: 'Тёмный сектор' }],
    presets: [{ id: 'maint', name: 'Техи' }],
  };
  const ui = setup({ route });
  fireEvent.click(ui.getByText('Моя роль'));
  expect(ui.getByText(/Упражнения программы: 1 из 2/)).toBeTruthy();
  expect(ui.getByText('Ксеноморфы · Тёмный сектор')).toBeTruthy();
  expect(ui.getByText(/Пресеты площадок: Техи/)).toBeTruthy();
  fireEvent.click(ui.getByText('Тёмный сектор'));
  const call = ui.topic.mock.calls.find(([message]) => message.type === 'act/sector_enter');
  expect(JSON.parse(call[0].payload)).toEqual({ id: 'dark' });
  fireEvent.click(ui.getByText('К сценариям'));
  expect(ui.queryByText('Где тренировать')).toBeNull();
  ui.unmount();
  const empty = setup({ route: { sectors: [], scenarios: [], presets: [], exercises_done: 0, exercises_total: 0 } });
  fireEvent.click(empty.getByText('Моя роль'));
  expect(empty.getByText(/Своего сектора, сценариев и пресетов площадок у программы нет/)).toBeTruthy();
});

test('«Моя роль» показывает цели роли с отметками и что делать дальше', () => {
  const role_objectives = [
    { text: 'Учебная ликвидация: убейте Манекена.', done: 1 },
    { text: 'Учебная кража: заберите секретные документы.', done: 0 },
  ];
  const ui = setup({ role_objectives, role_next: 'Учебная кража: заберите секретные документы.' });
  fireEvent.click(ui.getByText('Моя роль'));
  expect(ui.getByText('Цели роли')).toBeTruthy();
  const done = ui.getByText('Учебная ликвидация: убейте Манекена.');
  expect(within(done).getByText(/выполнено/)).toBeTruthy();
  expect(done.querySelector('.fa-square-check')).toBeTruthy();
  const pending = ui.getAllByText(/Учебная кража: заберите секретные документы\./)[0];
  expect(within(pending).queryByText(/выполнено/)).toBeNull();
  expect(pending.querySelector('.fa-square')).toBeTruthy();
  expect(ui.getByText(/Что дальше: Учебная кража/)).toBeTruthy();
  ui.unmount();
  const drill = setup({ role_objectives: [], role_next: 'Упражнение «Реанимация», шаг 2 из 3: Запустите сердце дефибриллятором.' });
  fireEvent.click(drill.getByText('Моя роль'));
  expect(drill.getByText(/Что дальше: Упражнение «Реанимация», шаг 2 из 3/)).toBeTruthy();
  drill.unmount();
  const none = setup({ role_objectives: [], role_next: null });
  fireEvent.click(none.getByText('Моя роль'));
  expect(none.queryByText('Цели роли')).toBeNull();
});

test('сброс роли требует подтверждения и передаёт идентификатор программы', () => {
  const ui = setup();
  fireEvent.click(ui.getByText('Моя роль'));
  fireEvent.click(ui.getAllByText('Еретик — все пути').at(-1));
  expect(ui.topic.mock.calls.some(([message]) => message.type === 'act/restart')).toBe(false);
  fireEvent.click(ui.getByText(/Сбросить своего персонажа\?/));
  const call = ui.topic.mock.calls.find(([message]) => message.type === 'act/restart');
  expect(JSON.parse(call[0].payload)).toEqual({ program: fixture.program_id });
});

test('новый персонаж: программы сгруппированы по разделам в порядке каталога', () => {
  const ui = setup({ programs: [...fixture.programs, { id: '/datum/antag_training_program/hk47', name: 'HK-47 — дроид-ассасин', category: 'Чужаки' }, { id: '/datum/antag_training_program/free', name: 'Снаряжение и бой', category: 'Общее' }] });
  fireEvent.click(ui.getByText('Моя роль'));
  const text = ui.container.textContent || '';
  const order = ['Общее', 'Снаряжение и бой', 'Чужаки', 'HK-47 — дроид-ассасин', 'Культы и магия', 'Еретик — все пути'].map((label) => text.lastIndexOf(label));
  expect(order.every((position) => position >= 0)).toBe(true);
  expect([...order].sort((first, second) => first - second)).toEqual(order);
});

test('старт предлагает комплект и упражнение с отдельными командами', () => {
  const ui = setup();
  fireEvent.click(ui.getByText('Первая помощь'));
  fireEvent.click(ui.getByText('Вылечить пациента'));
  expect(ui.topic.mock.calls.map(([message]) => [message.type, JSON.parse(message.payload)])).toEqual([
    ['act/kit', { id: 'medicine' }], ['act/practice', { id: 'medicine' }],
  ]);
});

test('готовый предмет и компоненты используют конкретный изученный рецепт', () => {
  const ui = setup({ recipes: [{ id: 'recipe', name: 'Принцип поединка', ingredients: 'Нож, металл', hint: '', components: 1, result: 1 }] });
  fireEvent.click(ui.getByText('Путь и рецепты еретика'));
  fireEvent.click(ui.getByText('Готовый предмет'));
  fireEvent.click(ui.getByText('Компоненты'));
  expect(ui.topic.mock.calls.filter(([message]) => message.type === 'act/recipe').map(([message]) => JSON.parse(message.payload))).toEqual([
    { id: 'recipe', components: false }, { id: 'recipe', components: true },
  ]);
});

test('повтор сохраняет вид упражнения, нулевое время до крита отображается', () => {
  const ui = setup({ practice: { id: 'combat', target: 'Цель 1', complete: 1, hint: 'Готово', damage: 100, healing: 10, last_damage: 20, critical_seconds: 0 } });
  expect(ui.getByText('0.0 с')).toBeTruthy();
  fireEvent.click(ui.getByText('Повторить упражнение'));
  expect(JSON.parse(ui.topic.mock.calls.find(([message]) => message.type === 'act/practice')[0].payload)).toEqual({ id: 'combat' });
});

test('чужая дуэль не даёт кнопки принятия или отмены', () => {
  const ui = setup({ duel: { phase: 'invite', first: 'Первый', second: 'Второй', lethal: 0, remaining: 25, involved: 0, can_accept: 0 } });
  expect(ui.queryByText('Принять вызов')).toBeNull();
  expect(ui.queryByText('Отменить дуэль')).toBeNull();
});

test('вызов принимается с любой вкладки', () => {
  const ui = setup({ duel: { phase: 'invite', first: 'Первый', second: 'Второй', lethal: 0, remaining: 25, involved: 1, can_accept: 1 } });
  fireEvent.click(ui.getByText('Снаряжение'));
  fireEvent.click(ui.getByText('Принять вызов'));
  expect(ui.topic.mock.calls.some(([message]) => message.type === 'act/duel_accept')).toBe(true);
});

test('подготовка блокирует повторную выдачу, сохраняя восстановление и выход', () => {
  const ui = setup({ preparing: 1, supply_ready: 0, practice_ready: 0 });
  fireEvent.click(ui.getByText('Первая помощь'));
  fireEvent.click(ui.getByText('Вылечить пациента'));
  expect(ui.topic.mock.calls).toHaveLength(0);
  fireEvent.click(ui.getByText('Восстановиться'));
  expect(ui.topic.mock.calls.some(([message]) => message.type === 'act/heal')).toBe(true);
});

test('показывает всех участников без искусственного предела', () => {
  const members = Array.from({ length: 8 }, (_, index) => ({ ...fixture.members[0], id: `member${index}`, name: `Игрок ${index + 1}`, self: index === 0 }));
  const ui = setup({ members });
  expect(ui.getByText('Участников: 8')).toBeTruthy();
  fireEvent.click(ui.getByText('Участники'));
  expect(ui.getByText('Игрок 8')).toBeTruthy();
});

test('при восстановлении сектора выдача заблокирована, выход остаётся доступен', () => {
  const ui = setup({ busy: 1 });
  fireEvent.click(ui.getByText('Снаряжение'));
  fireEvent.click(ui.getByText('Выдать'));
  expect(ui.topic.mock.calls.some(([message]) => message.type === 'act/equipment')).toBe(false);
  fireEvent.click(ui.getByText('Выйти'));
  fireEvent.click(ui.getByText('Выбрать, куда выйти?'));
  expect(ui.topic.mock.calls.some(([message]) => message.type === 'act/exit')).toBe(true);
});

test.each([
  [0, 'Выбрать, куда выйти?'],
  [1, 'Вернуться в тело в кафе?'],
])('подтверждение выхода называет, куда он ведёт (тело в кафе: %s)', (returnToBody, question) => {
  const ui = setup({ return_to_body: returnToBody });
  expect(ui.getByText('Вход через меню гостролей или капсулу в Гост-Кафе')).toBeTruthy();
  fireEvent.click(ui.getByText('Выйти'));
  expect(ui.topic.mock.calls.some(([message]) => message.type === 'act/exit')).toBe(false);
  fireEvent.click(ui.getByText(question));
  expect(ui.topic.mock.calls.filter(([message]) => message.type === 'act/exit')).toHaveLength(1);
});

test('у человеческой цели нельзя включить ИИ', () => {
  const ui = setup();
  fireEvent.click(ui.getByText('Цели'));
  fireEvent.click(ui.getByText('Активный ИИ'));
  fireEvent.click(ui.getByText('Создать'));
  const call = ui.topic.mock.calls.find(([message]) => message.type === 'act/spawn');
  expect(JSON.parse(call[0].payload).active).toBe(false);
});

test('поиск фильтрует выдачу сразу при вводе', () => {
  const ui = setup();
  fireEvent.click(ui.getByText('Снаряжение'));
  fireEvent.input(ui.getByPlaceholderText('Найти оружие, инструмент или материал…'), { target: { value: 'нож' } });
  expect(ui.queryByText('Лазерный карабин')).toBeNull();
  expect(ui.getByText(/Ничего не найдено/)).toBeTruthy();
});

test('голосование видно на другой вкладке и отправляет согласие или отмену', () => {
  const ui = setup({ reset_vote: { zone: 'Тир', approved: 1, total: 6, remaining: 40, voted: 0 } });
  fireEvent.click(ui.getByText('Моя роль'));
  expect(ui.getByText('Сброс: Тир')).toBeTruthy();
  fireEvent.click(ui.getByText('Согласиться'));
  fireEvent.click(ui.getByText('Отменить сброс'));
  expect(ui.topic.mock.calls.some(([message]) => message.type === 'act/reset_approve')).toBe(true);
  expect(ui.topic.mock.calls.some(([message]) => message.type === 'act/reset_cancel')).toBe(true);
});

test('личная очистка подтверждается отдельно от смены персонажа', () => {
  const ui = setup();
  fireEvent.click(ui.getByText('Моя роль'));
  fireEvent.click(ui.getByText('Очистить своё'));
  expect(ui.topic.mock.calls.some(([message]) => message.type === 'act/clean_personal')).toBe(false);
  fireEvent.click(ui.getByText('Удалить свои объекты?'));
  expect(ui.topic.mock.calls.some(([message]) => message.type === 'act/clean_personal')).toBe(true);
});

test('мастерская ищет по описанию и отправляет только идентификатор объекта', () => {
  const ui = setup();
  fireEvent.click(ui.getByText('Мастерская'));
  fireEvent.input(ui.getByPlaceholderText(/Найти объект или занятие/), { target: { value: 'осмотра' } });
  expect(ui.getByText('Операционный стол')).toBeTruthy();
  fireEvent.click(ui.getByText('Установить'));
  const call = ui.topic.mock.calls.find(([message]) => message.type === 'act/build');
  expect(JSON.parse(call[0].payload)).toEqual({ id: 'operating_table' });
});

const standOn = { enabled: 1, full: 0, query: null, results: [], more: 0, members: [] };

test.each([
  ['Снаряжение', 'Выдать', 'equipment', 'Выдано 150 · без лимита'],
  ['Мастерская', 'Установить', 'build', 'Установлено 20 · без лимита'],
  ['Цели', 'Создать', 'spawn', '0 · без лимита'],
])('в режиме стенда вкладка «%s» показывает снятый лимит и не блокирует кнопку', (tab, button, action, counter) => {
  const ui = setup({ stand: standOn, supply_count: 150, structure_count: 20, target_limit: 0 });
  fireEvent.click(ui.getByText(tab));
  expect(ui.getByText(counter)).toBeTruthy();
  fireEvent.click(ui.getByText(button));
  expect(ui.topic.mock.calls.some(([message]) => message.type === `act/${action}`)).toBe(true);
});

test.each([
  [150, 'Выдано 150 / 200', true],
  [200, 'Выдано 200 / 200', false],
])('стенд кодера удваивает лимит снаряжения: %s выдано', (count, counter, enabled) => {
  const ui = setup({ stand: { ...standOn, limit_scale: 2 }, supply_count: count });
  fireEvent.click(ui.getByText('Снаряжение'));
  expect(ui.getByText(counter)).toBeTruthy();
  fireEvent.click(ui.getByText('Выдать'));
  expect(ui.topic.mock.calls.some(([message]) => message.type === 'act/equipment')).toBe(enabled);
});

test('цели не создаются в чужом занятом секторе: его нет в списке', () => {
  const booking = { id: 'dark', squad: 'Бета', color: '#4fb3d9', mine: 0, leader: 0, waitlist: [], on_waitlist: 0, remaining: 90, idle_remaining: 300 };
  const zones = [...fixture.zones, { id: 'dark', name: 'Тёмный сектор', desc: 'Комнаты без света', current: 0, members: 0, targets: 0 }, { id: 'eva', name: 'Открытый космос', desc: 'EVA', current: 0, members: 0, targets: 0 }];
  const ui = setup({ zones, bookings: { dark: booking } });
  fireEvent.click(ui.getByText('Цели'));
  fireEvent.click(ui.container.querySelectorAll('.Dropdown__control')[1]);
  expect(ui.queryByText('Открытый космос')).toBeTruthy();
  expect(ui.queryByText('Тёмный сектор')).toBeNull();
});

test.each([
  ['Снаряжение', 'Выдать', 'equipment', 'Выдано 100 / 100'],
  ['Мастерская', 'Установить', 'build', 'Установлено 16 / 16'],
  ['Цели', 'Создать', 'spawn', '0 / 0'],
])('без стенда вкладка «%s» показывает обычный лимит и блокирует кнопку на пределе', (tab, button, action, counter) => {
  const ui = setup({ stand: { ...standOn, enabled: 0 }, supply_count: 100, structure_count: 16, target_limit: 0 });
  fireEvent.click(ui.getByText(tab));
  expect(ui.getByText(counter)).toBeTruthy();
  fireEvent.click(ui.getByText(button));
  expect(ui.topic.mock.calls.some(([message]) => message.type === `act/${action}`)).toBe(false);
});

test.each([
  { build_error: 'Клетка перед вами занята.' },
  { structure_count: 16 },
  { supply_count: 100 },
  { busy: 1 },
])('мастерская блокирует установку при недоступном месте или лимите: %j', (overrides) => {
  const ui = setup(overrides);
  fireEvent.click(ui.getByText('Мастерская'));
  if (overrides.build_error) {
    expect(ui.getByText(overrides.build_error)).toBeTruthy();
  }
  fireEvent.click(ui.getByText('Установить'));
  expect(ui.topic.mock.calls.some(([message]) => message.type === 'act/build')).toBe(false);
});

const patient = { id: 'patient', name: 'Учебная цель', health: 100, max_health: 100, dead: 0, human: 1, living: 1, brute: 0, burn: 0, toxin: 0, oxygen: 0, stamina: 30, zone: 'Лаборатория', owner: 'Участник', can_manage: 1 };

test('подготовка пациента передаёт вид повреждения и конкретную цель', () => {
  const ui = setup({ targets: [patient] });
  fireEvent.click(ui.getByText('Цели'));
  expect(ui.getByText('Урон выносливости: 30')).toBeTruthy();
  fireEvent.click(ui.getByText('Ожоги: +40'));
  const call = ui.topic.mock.calls.find(([message]) => message.type === 'act/target_injure');
  expect(JSON.parse(call[0].payload)).toEqual({ id: 'patient', injury: 'burn' });
});

test.each([{ dead: 1 }, { can_manage: 0 }])('повреждения недоступны мёртвой или чужой цели: %j', (overrides) => {
  const ui = setup({ targets: [{ ...patient, ...overrides }] });
  fireEvent.click(ui.getByText('Цели'));
  fireEvent.click(ui.getByText('Ожоги: +40'));
  expect(ui.topic.mock.calls.some(([message]) => message.type === 'act/target_injure')).toBe(false);
});

test('состояние цели видно в карточке, кнопка передаёт состояние и цель', () => {
  const ui = setup({ targets: [{ ...patient, states: ['в наручниках'] }] });
  fireEvent.click(ui.getByText('Цели'));
  expect(ui.getByText('Состояние: в наручниках')).toBeTruthy();
  fireEvent.click(ui.getByText('Сбить с ног на 10 с'));
  const call = ui.topic.mock.calls.find(([message]) => message.type === 'act/target_condition');
  expect(JSON.parse(call[0].payload)).toEqual({ id: 'patient', condition: 'knockdown' });
});

test('программа без еретика показывает свои кнопки без рецептов, подношения и цели охоты', () => {
  const ui = setup({ program: 'Кровная клятва', program_id: '/datum/antag_training_program/blood_brother', options: ['Поднять связь'], heretic: 0, target_action: null, targets: [patient] });
  expect(ui.getByText('Первое подношение').closest('.Button')?.className).toContain('Button--disabled');
  fireEvent.click(ui.getByText('Цели'));
  expect(ui.queryByText('Цель охоты')).toBeNull();
  fireEvent.click(ui.getByText('Моя роль'));
  expect(ui.queryByText('Подготовить путь')).toBeNull();
  fireEvent.click(ui.getByText('Поднять связь'));
  const call = ui.topic.mock.calls.find(([message]) => message.type === 'act/program_option');
  expect(JSON.parse(call[0].payload)).toEqual({ option: 'Поднять связь' });
});

test('роль без еретика скрывает путь, кнопка роли и кнопка цели подписаны программой', () => {
  const ui = setup({ heretic: 0, target_action: 'Цель контракта', program: 'HK-47 — дроид-ассасин', options: ['ЭМИ по себе'], option_hints: { 'ЭМИ по себе': 'Импульс как от ионной винтовки.' }, targets: [patient] });
  fireEvent.click(ui.getByText('Моя роль'));
  expect(ui.queryByText('Изучить до ступени')).toBeNull();
  fireEvent.click(ui.getByText('ЭМИ по себе'));
  const call = ui.topic.mock.calls.find(([message]) => message.type === 'act/program_option');
  expect(JSON.parse(call[0].payload)).toEqual({ option: 'ЭМИ по себе' });
  fireEvent.click(ui.getByText('Цели'));
  expect(ui.queryByText('Цель охоты')).toBeNull();
  fireEvent.click(ui.getByText('Цель контракта'));
  const marked = ui.topic.mock.calls.find(([message]) => message.type === 'act/target_hunt');
  expect(JSON.parse(marked[0].payload)).toEqual({ id: 'patient' });
});

test('цель-предмет показывает прочность без урона и лечения, карточка шлёт только удаление', () => {
  const egg = { id: 'egg', name: 'egg', health: 40, max_health: 100, dead: 0, human: 0, living: 0, zone: 'Ближний бой', owner: 'Участник', can_manage: 1 };
  const ui = setup({ heretic: 0, target_action: 'Цель контракта', targets: [egg] });
  fireEvent.click(ui.getByText('Цели'));
  const card = ui.container.querySelector('.AntagTraining__target') as HTMLElement;
  expect(within(card).getByText('Прочность 40 / 100')).toBeTruthy();
  expect(card.textContent).not.toMatch(/NaN|Физический|выносливости|Исцелить|Цель контракта/);
  ui.topic.mockClear();
  card.querySelectorAll('.Button').forEach((button) => fireEvent.click(button));
  const sent = ui.topic.mock.calls.map(([message]) => message.type).filter((type) => type.startsWith('act/'));
  expect(sent).toEqual(['act/target_delete']);
});

test('без кнопки цели у программы карточка цели её не показывает', () => {
  const ui = setup({ heretic: 0, target_action: null, options: [], targets: [patient] });
  fireEvent.click(ui.getByText('Цели'));
  expect(ui.queryByText('Цель охоты')).toBeNull();
});

const exercise: Exercise = {
  id: 'pen',
  name: 'Ручка на стол',
  desc: 'Взять ручку и положить её на стол.',
  difficulty: 1,
  zone: 'Ближний бой',
  practice: 0,
  score_rule: 'Оценка: 100 баллов, минус 15 за каждую подсказку.',
  steps: [
    { name: 'Возьмите ручку', done: 1, current: 0, hint: 'Нажмите на ручку пустой рукой.' },
    { name: 'Положите ручку на стол', done: 0, current: 1, hint: null },
  ],
  best: null,
  run: { elapsed: 12.5, hints: 1, ended: 0, success: 0, score: null, result: null },
};

const exerciseCard = (ui: ReturnType<typeof setup>) => {
  fireEvent.click(ui.getByText('Упражнения'));
  return ui.container.querySelector('.AntagTraining__exercise') as HTMLElement;
};
const actions = (ui: ReturnType<typeof setup>) => ui.topic.mock.calls.filter(([message]) => message.type.startsWith('act/')).map(([message]) => [message.type, JSON.parse(message.payload)]);

test('идущее упражнение показывает шаги, открытую подсказку и время, кнопки отправляют свои команды', () => {
  const ui = setup({ exercises: [exercise] });
  const card = exerciseCard(ui);
  expect(within(card).getByText('Подсказка: Нажмите на ручку пустой рукой.')).toBeTruthy();
  expect(within(card).getByText('Время: 12.5 с · подсказок: 1')).toBeTruthy();
  expect(within(card).getByText('Оценка: 100 баллов, минус 15 за каждую подсказку.')).toBeTruthy();
  fireEvent.click(within(card).getByText('Подсказка'));
  fireEvent.click(within(card).getByText('Прекратить'));
  fireEvent.click(within(card).getByText('Начать заново'));
  expect(actions(ui)).toEqual([['act/exercise_hint', {}], ['act/exercise_stop', {}], ['act/exercise_start', { id: 'pen' }]]);
});

test('неначатое упражнение показывает лучший результат и стартует по id без кнопки подсказки', () => {
  const ui = setup({ exercises: [{ ...exercise, id: 'pen_fresh', run: null, best: { time: 12, hints: 1, score: 85 }, steps: exercise.steps.map((step) => ({ ...step, done: 0, current: 0, hint: null })) }] });
  const card = exerciseCard(ui);
  expect(within(card).getByText('Лучший результат: 85 баллов за 12.0 с, подсказок: 1')).toBeTruthy();
  expect(within(card).queryByText('Подсказка')).toBeNull();
  expect(within(card).queryByText('Прекратить')).toBeNull();
  fireEvent.click(within(card).getByText('Начать'));
  expect(actions(ui)).toEqual([['act/exercise_start', { id: 'pen_fresh' }]]);
});

test('итог прогона виден, «Убрать итог» снимает упражнение', () => {
  const ui = setup({ exercises: [{ ...exercise, run: { elapsed: 20, hints: 0, ended: 1, success: 1, score: 100, result: 'Выполнено за 20 с, подсказок: 0, оценка 100.' } }] });
  const card = exerciseCard(ui);
  expect(within(card).getByText('Выполнено за 20 с, подсказок: 0, оценка 100.')).toBeTruthy();
  expect(within(card).queryByText('Подсказка')).toBeNull();
  fireEvent.click(within(card).getByText('Убрать итог'));
  expect(actions(ui)).toEqual([['act/exercise_stop', {}]]);
});

test('практика роли в списке упражнений запускается и снимается прежними командами', () => {
  const lesson: Exercise = { id: 'dance', name: 'Урок Пляски', desc: 'Пошаговый урок.', difficulty: 2, zone: 'Тир', practice: 1, score_rule: null, steps: [{ name: 'Три удара в долю', done: 0, current: 1, hint: null }], best: null, run: { ended: 0, success: 0, result: 'Бейте мишень в долю.' } };
  const ui = setup({ exercises: [lesson] });
  const card = exerciseCard(ui);
  expect(within(card).getByText('Бейте мишень в долю.')).toBeTruthy();
  expect(within(card).queryByText('Подсказка')).toBeNull();
  fireEvent.click(within(card).getByText('Начать заново'));
  fireEvent.click(within(card).getByText('Прекратить'));
  expect(actions(ui)).toEqual([['act/practice', { id: 'dance' }], ['act/practice_stop', {}]]);
});

test('без упражнений в зоне вкладка ведёт туда, где они есть, своими командами перехода', () => {
  const ui = setup({
    zones: [...fixture.zones, { id: 'melee', name: 'Ближний бой', desc: 'Манекены', current: 0, members: 0, targets: 0, exercises_done: 1, exercises_total: 2 }],
    sectors: [{ ...fixture.sectors[0], exercises_done: 0, exercises_total: 2 }],
  });
  expect(ui.getByText('В этой зоне нет упражнений для вашей роли. Во вкладке «Упражнения» видно, где они есть.')).toBeTruthy();
  fireEvent.click(ui.getByText('Открыть упражнения'));
  expect(ui.getByText('Здесь нет упражнений для вашей роли')).toBeTruthy();
  expect(ui.queryByText(/Безопасный центр ·/)).toBeNull();
  fireEvent.click(ui.getByText('Ближний бой · 1/2'));
  fireEvent.click(ui.getByText('Тёмный сектор · 0/2'));
  expect(actions(ui)).toEqual([['act/move', { zone: 'melee' }], ['act/sector_enter', { id: 'dark' }]]);
});

test('без упражнений с оценкой вкладка ведёт и в зону, где есть только практика', () => {
  const ui = setup({
    zones: [...fixture.zones, { id: 'range', name: 'Тир', desc: 'Мишени', current: 0, members: 0, targets: 0, exercises_done: 0, exercises_total: 0, practice: 1 }],
    sectors: [{ ...fixture.sectors[0], exercises_done: 0, exercises_total: 0 }],
  });
  fireEvent.click(ui.getByText('Открыть упражнения'));
  expect(ui.getByText('Перейдите туда, где они есть:')).toBeTruthy();
  expect(ui.queryByText(/Тёмный сектор ·/)).toBeNull();
  fireEvent.click(ui.getByText('Тир · практика'));
  expect(actions(ui)).toEqual([['act/move', { zone: 'range' }]]);
});

test('список упражнений: идущее выбрано сразу, клик открывает другое, статус и лучший результат видны в строке', () => {
  const fresh: Exercise = { ...exercise, id: 'cuffs', name: 'Обезвредь и закуй', run: null, best: { time: 30, hints: 0, score: 90 }, steps: [{ name: 'Сбейте цель с ног', done: 0, current: 0, hint: null }] };
  const ui = setup({ exercises: [fresh, exercise] });
  const card = exerciseCard(ui);
  expect(within(card).getByText('Ручка на стол')).toBeTruthy();
  const rows = [...ui.container.querySelectorAll('.AntagTraining__row')] as HTMLElement[];
  expect(rows.map((row) => row.textContent)).toEqual(['Обезвредь и закуйлучший 90', 'Ручка на столидёт']);
  expect(rows[1].classList.contains('AntagTraining__row--selected')).toBe(true);
  fireEvent.click(within(rows[0]).getByText('Обезвредь и закуй'));
  const opened = ui.container.querySelector('.AntagTraining__exercise') as HTMLElement;
  expect(within(opened).getByText('Лучший результат: 90 баллов за 30.0 с, подсказок: 0')).toBeTruthy();
  fireEvent.click(within(opened).getByText('Начать'));
  expect(actions(ui)).toEqual([['act/exercise_start', { id: 'cuffs' }]]);
});

test('пульт, открытый стендом, начинает с вкладки упражнений', () => {
  const ui = setup({ start_tab: 'exercises', exercises: [exercise] });
  expect(ui.container.querySelector('.AntagTraining__exercise')).toBeTruthy();
  expect(ui.queryByText('Что хотите потренировать?')).toBeNull();
});

test('карточки зон и секторов показывают прогресс упражнений, зона без упражнений - без полосы', () => {
  const ui = setup({
    zones: [
      { ...fixture.zones[0], exercises_done: 0, exercises_total: 0 },
      { ...fixture.zones[1], exercises_done: 2, exercises_total: 2 },
    ],
    sectors: [{ ...fixture.sectors[0], exercises_done: 1, exercises_total: 3 }],
  });
  fireEvent.click(ui.getByText('Зоны'));
  const hub = ui.getByText('Безопасный центр').closest('.AntagTraining__sector') as HTMLElement;
  expect(hub.querySelector('.AntagTraining__zoneProgress')).toBeNull();
  const arena = ui.getByText('Арена противников').closest('.AntagTraining__sector') as HTMLElement;
  expect(within(arena).getByText('Упражнения: 2 из 2')).toBeTruthy();
  const dark = ui.getByText('Тёмный сектор').closest('.AntagTraining__sector') as HTMLElement;
  expect(within(dark).getByText('Упражнения: 1 из 3')).toBeTruthy();
  expect(parseFloat((dark.querySelector('.AntagTraining__meterFill') as HTMLElement).style.width)).toBeCloseTo(33.3, 1);
});

test('новый персонаж: кнопка программы показывает её иконку', () => {
  const ui = setup({ programs: [{ ...fixture.programs[0], icon: 'book-skull', color: 'green' }] });
  fireEvent.click(ui.getByText('Моя роль'));
  const button = ui.getAllByText('Еретик — все пути').at(-1).closest('.Button') as HTMLElement;
  expect(button.querySelector('.fa-book-skull')).toBeTruthy();
});

test('тело без здоровья не показывает полосу здоровья ни в шапке, ни в списке участников', () => {
  const ui = setup({ health: null, max_health: null, members: [{ ...fixture.members[0], health: null, max_health: null }] });
  expect(ui.getByText('У этого тела нет здоровья: восстановление создаёт его заново.')).toBeTruthy();
  expect(ui.queryByText(/Здоровье/)).toBeNull();
  fireEvent.click(ui.getByText('Участники'));
  expect(ui.queryByText(/Здоровье/)).toBeNull();
  expect(ui.getByText('Восстановиться')).toBeTruthy();
});

test('должность в «Моей роли»: смена через set_role, предупреждение для программы без должности', () => {
  const roles = [
    { id: 'default', name: 'Учебное тело', department: 'Полигон', order: 0 },
    { id: 'crew:Medical Doctor', name: 'Medical Doctor', department: 'Медицина', order: 41 },
  ];
  const ui = setup({ roles, role: 'default', role_applies: 0 });
  fireEvent.click(ui.getByText('Моя роль'));
  expect(ui.getByText('Должность: Учебное тело')).toBeTruthy();
  expect(ui.container.textContent).toContain('Эта программа не использует должность');
  fireEvent.click(ui.getByText('Medical Doctor'));
  const calls = ui.topic.mock.calls.filter(([message]) => message.type === 'act/set_role').map(([message]) => JSON.parse(message.payload));
  expect(calls).toEqual([{ role: 'crew:Medical Doctor' }]);
});

test('сектор чужой брони: вход и сброс закрыты, бронь и очередь видны в карточке', () => {
  const booking = { id: 'dark', squad: 'Бета', color: '#4fb3d9', mine: 0, leader: 0, waitlist: [], on_waitlist: 0, remaining: 90, idle_remaining: 300 };
  const ui = setup({ sectors: [{ ...fixture.sectors[0], state: 'ready' }], bookings: { dark: booking } });
  fireEvent.click(ui.getByText('Зоны'));
  const card = ui.getByText('Тёмный сектор').closest('.AntagTraining__sector') as HTMLElement;
  expect(within(card).getByText(/Занят группой «Бета» · ещё 1:30/)).toBeTruthy();
  expect(within(card).getByText('Перейти').closest('.Button')?.className).toContain('Button--disabled');
  expect(within(card).getByText('Сброс').closest('.Button')?.className).toContain('Button--disabled');
  fireEvent.click(within(card).getByText('Встать в очередь'));
  expect(ui.topic.mock.calls.filter(([message]) => message.type.startsWith('act/')).map(([message]) => [message.type, JSON.parse(message.payload)])).toEqual([['act/waitlist_join', { id: 'dark' }]]);
});

test('голосование чужой группы: без кнопок согласия и отмены', () => {
  const ui = setup({ reset_vote: { zone: 'Тёмный сектор', approved: 1, total: 2, remaining: 40, voted: 0, can_vote: 0, can_cancel: 0 } });
  expect(ui.getByText('Сектор занят группой: голосуют только её участники.')).toBeTruthy();
  expect(ui.queryByText('Согласиться')).toBeNull();
  expect(ui.queryByText('Отменить сброс')).toBeNull();
});

test('вкладка участников показывает группы', () => {
  const ui = setup({ squads: [{ id: 'beta', name: 'Бета', color: '#4fb3d9', open: 0, leader: 'Ве', members: [{ id: 've', name: 'Ве', leader: 1 }], sector: null, sector_id: null, mine: 0, invited: [] }] });
  fireEvent.click(ui.getByText('Участники'));
  expect(ui.getByText('Новая группа')).toBeTruthy();
  expect(ui.getByText('По приглашению')).toBeTruthy();
});

test('стенд виден только с правами, вкладка появляется после включения', () => {
  expect(setup().queryByText('Режим стенда')).toBeNull();
  const stand = { enabled: 0, full: 1, query: null, results: [], more: 0, members: [] };
  const off = setup({ stand });
  expect(off.getByText('Режим стенда')).toBeTruthy();
  expect(off.queryByText('Стенд')).toBeNull();
  const on = setup({ stand: { ...stand, enabled: 1 } });
  fireEvent.click(on.getByText('Стенд'));
  expect(on.getByText('Создать по пути')).toBeTruthy();
});

test('кнопка «В хаб» ведёт в вестибюль, «В центр» остаётся', () => {
  const ui = setup({ hub: 1 });
  fireEvent.click(ui.getByText('В хаб'));
  fireEvent.click(ui.getByText('В центр'));
  const types = ui.topic.mock.calls.map(([message]) => message.type);
  expect(types).toContain('act/hub');
  expect(types).toContain('act/move');
});

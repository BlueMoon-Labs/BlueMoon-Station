import { fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { AntagTraining, AntagTrainingData } from './AntagTraining';

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
  duel: null,
  duel_ready: 1,
  last_duel_result: null,
  program: 'Еретик — все пути',
  program_id: '/datum/antag_training_program/heretic',
  auto_recover: 1,
  health: 100,
  max_health: 100,
  busy: 0,
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
  equipment: [{ id: 'laser', name: 'Лазерный карабин', category: 'Стрельба' }],
  structures: [{ id: 'operating_table', name: 'Операционный стол', category: 'Медицина и химия', desc: 'Для операций и осмотра пациента.' }],
  injuries: [{ id: 'burn', name: 'Ожоги: +40' }],
  creatures: [{ id: 'human', name: 'Человек без брони' }, { id: 'carp', name: 'Карп' }],
  targets: [],
  programs: [{ id: '/datum/antag_training_program/heretic', name: 'Еретик — все пути' }],
  options: ['Добавить очки знаний'],
};

const setup = (overrides: Partial<AntagTrainingData> = {}) => {
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

test('сброс роли требует подтверждения и передаёт идентификатор программы', () => {
  const ui = setup();
  fireEvent.click(ui.getByText('Моя роль'));
  fireEvent.click(ui.getAllByText('Еретик — все пути').at(-1));
  expect(ui.topic.mock.calls.some(([message]) => message.type === 'act/restart')).toBe(false);
  fireEvent.click(ui.getByText(/Сбросить своего персонажа\?/));
  const call = ui.topic.mock.calls.find(([message]) => message.type === 'act/restart');
  expect(JSON.parse(call[0].payload)).toEqual({ program: fixture.program_id });
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
  fireEvent.click(ui.getByText('Выйти в призрака?'));
  expect(ui.topic.mock.calls.some(([message]) => message.type === 'act/exit')).toBe(true);
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

const patient = { id: 'patient', name: 'Учебная цель', health: 100, max_health: 100, dead: 0, human: 1, brute: 0, burn: 0, toxin: 0, oxygen: 0, zone: 'Лаборатория', owner: 'Участник', can_manage: 1 };

test('подготовка пациента передаёт вид повреждения и конкретную цель', () => {
  const ui = setup({ targets: [patient] });
  fireEvent.click(ui.getByText('Цели'));
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

import { fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { AntagTraining, AntagTrainingData } from './AntagTraining';

const fixture: AntagTrainingData = {
  program: 'Еретик — все пути',
  program_id: '/datum/antag_training_program/heretic',
  auto_recover: 1,
  health: 100,
  max_health: 100,
  busy: 0,
  target_limit: 12,
  supply_count: 0,
  supply_limit: 100,
  cleaning_personal: 0,
  reset_vote: null,
  members: [{ id: 'member', name: 'Участник', program: 'Еретик', health: 100, max_health: 100, dead: 0, connected: 1, zone: 'Безопасный центр', defeats: 0, self: 1 }],
  zones: [
    { id: 'hub', name: 'Безопасный центр', desc: 'Подготовка', current: 1, members: 1, targets: 0 },
    { id: 'pve', name: 'Арена противников', desc: 'Бой с ИИ', current: 0, members: 0, targets: 0 },
  ],
  equipment: [{ id: 'laser', name: 'Лазерный карабин', category: 'Стрельба' }],
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
  fireEvent.click(ui.getByText('Сброс'));
  expect(ui.topic.mock.calls.some(([message]) => message.type === 'act/reset_zone')).toBe(false);
  fireEvent.click(ui.getByText('Запросить сброс?'));
  const call = ui.topic.mock.calls.find(([message]) => message.type === 'act/reset_zone');
  expect(JSON.parse(call[0].payload)).toEqual({ zone: 'pve' });
});

test('создание цели отправляет выбранный тип, сектор и режим ИИ', () => {
  const ui = setup();
  fireEvent.click(ui.getByText('Цели'));
  fireEvent.click(ui.container.querySelector('.Dropdown__control'));
  fireEvent.click(ui.getByText('Карп'));
  fireEvent.click(ui.getByText('Активный ИИ'));
  fireEvent.click(ui.getByText('Создать'));
  const call = ui.topic.mock.calls.find(([message]) => message.type === 'act/spawn');
  expect(JSON.parse(call[0].payload)).toEqual({ id: 'carp', zone: 'pve', active: true });
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

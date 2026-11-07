import { fireEvent, render, within } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { AntagTrainingCatalog, AntagTrainingCatalogData } from './AntagTrainingCatalog';

const heretic = {
  id: '/datum/antag_training_program/heretic',
  name: 'Еретик — все пути',
  category: 'Культы и магия',
  desc: 'Пути Мансуса, рецепты обрядов и вознесение.',
  sector: 'Тёмный сектор',
  icon: 'book-skull',
  color: 'green',
  learn: ['Выбор пути', 'Рецепты обрядов', 'Вознесение'],
  difficulty: 3,
  order: 5,
  exercises_done: 0,
  exercises_total: 0,
};

const free = {
  id: '/datum/antag_training_program/free',
  name: 'Снаряжение и бой',
  category: 'Общее',
  desc: 'Оружие, броня, медицина, химия, строительство и бой с противниками.',
  sector: null,
  icon: 'dumbbell',
  color: 'teal',
  learn: ['Оружие', 'Броня', 'Лечение'],
  difficulty: 1,
  order: 1,
  exercises_done: 1,
  exercises_total: 3,
};

const hk47 = { id: '/datum/antag_training_program/hk47', name: 'HK-47 — дроид-ассасин', category: 'Чужаки', desc: 'Дроид-ассасин.', icon: 'robot', color: 'orange', learn: ['Контракты', 'Модули', 'ЭМИ'], difficulty: 3, order: 0, exercises_done: 0, exercises_total: 0 };

const mechanics = {
  id: 'mechanics',
  program: free.id,
  name: 'Механики станции',
  category: 'Общее',
  desc: 'Питание, атмос, выход в космос и робототехника.',
  sector: 'Инженерный сектор, Атмос',
  icon: 'screwdriver-wrench',
  color: 'yellow',
  learn: ['Генератор, кабель и щиток', 'Смесь газов, пробой и пожар', 'Скафандр, джетпак и шлюз'],
  difficulty: 2,
  order: 2,
  exercises_done: 0,
  exercises_total: 4,
};

const fixture: AntagTrainingCatalogData = {
  programs: [heretic, hk47, free],
  mechanics,
  can_load_character: 1,
};

let now = Date.now();

const setup = (overrides: Partial<AntagTrainingCatalogData> = {}) => {
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'AntagTrainingCatalog' }, data: { ...fixture, ...overrides } }));
  return { ...render(<AntagTrainingCatalog />), topic };
};

const startCalls = (topic: jest.Mock) => topic.mock.calls.filter(([message]) => message.type === 'act/start').map(([message]) => JSON.parse(message.payload));
const rowOf = (ui: ReturnType<typeof setup>, name: string, index = 0) => ui.getAllByText(name)[index].closest('.AntagTraining__row') as HTMLElement;

test('разделы идут в порядке каталога, клик по программе выделяет её и показывает описание и сектор', () => {
  const ui = setup();
  const text = ui.container.textContent || '';
  expect(text.indexOf('Общее')).toBeLessThan(text.indexOf('Культы и магия'));
  expect(text.lastIndexOf('Общее')).toBeLessThan(text.lastIndexOf('Культы и магия'));
  expect(ui.queryByText(heretic.desc)).toBeNull();
  fireEvent.click(rowOf(ui, hk47.name));
  expect(ui.getByText(hk47.desc)).toBeTruthy();
  fireEvent.click(rowOf(ui, heretic.name, 1));
  expect(ui.getByText(heretic.desc)).toBeTruthy();
  expect(ui.getByText(/Сектор: Тёмный сектор/)).toBeTruthy();
  expect([...ui.container.querySelectorAll('.AntagTraining__row--selected')].map((row) => row.querySelector('.AntagTraining__rowName')?.textContent)).toEqual([heretic.name, heretic.name]);
});

test('учебная кукла и «Войти» отправляют программу и выбор куклы', () => {
  const ui = setup();
  fireEvent.click(rowOf(ui, heretic.name));
  fireEvent.click(ui.getByText('Учебная кукла'));
  fireEvent.click(ui.getByText('Войти'));
  expect(startCalls(ui.topic)).toEqual([{ program: heretic.id, use_character: false, role: 'default' }]);
});

test('своя кукла выбрана по умолчанию, если её можно загрузить', () => {
  const ui = setup();
  fireEvent.click(rowOf(ui, 'Снаряжение и бой'));
  fireEvent.click(ui.getByText('Войти'));
  expect(startCalls(ui.topic)).toEqual([{ program: '/datum/antag_training_program/free', use_character: true, role: 'default' }]);
});

test('без слота персонажа своя кукла недоступна', () => {
  const ui = setup({ can_load_character: 0 });
  fireEvent.click(rowOf(ui, heretic.name));
  fireEvent.click(ui.getByText('Своя кукла'));
  fireEvent.click(ui.getByText('Войти'));
  expect(startCalls(ui.topic)).toEqual([{ program: heretic.id, use_character: false, role: 'default' }]);
});

test('без выбранной программы вход недоступен', () => {
  const ui = setup();
  fireEvent.click(ui.getByText('Войти'));
  expect(startCalls(ui.topic)).toEqual([]);
});

test('«С чего начать» идёт по месту программ и включает механики, остальные программы туда не попадают', () => {
  const ui = setup();
  const start = ui.getByText('С чего начать').closest('.AntagTraining__start') as HTMLElement;
  const rows = [...start.querySelectorAll('.AntagTraining__row')];
  expect(rows.map((row) => row.querySelector('.AntagTraining__rowName')?.textContent)).toEqual([free.name, mechanics.name, heretic.name]);
  expect(rows.map((row) => row.querySelector('.AntagTraining__step')?.textContent)).toEqual(['1', '2', '3']);
  expect(within(start).queryByText(hk47.name)).toBeNull();
  expect(rows[0].querySelector('.fa-dumbbell')).toBeTruthy();
  expect(within(rows[0] as HTMLElement).getByText('1/3')).toBeTruthy();
  expect(rows[2].querySelectorAll('.AntagTraining__levelMark--on').length).toBe(3);
});

test('шаг механик показывает свои пункты и прогресс, «Войти» запускает программу «Снаряжение и бой»', () => {
  const ui = setup();
  fireEvent.click(rowOf(ui, mechanics.name));
  for (const item of mechanics.learn) {
    expect(ui.getByText(item)).toBeTruthy();
  }
  expect(ui.getByText('Упражнения за раунд: 0 из 4')).toBeTruthy();
  expect(ui.getByText(/Сектор: Инженерный сектор, Атмос/)).toBeTruthy();
  expect(ui.getByText('Общее · сложность средняя')).toBeTruthy();
  fireEvent.click(ui.getByText('Учебная кукла'));
  fireEvent.click(ui.getByText('Войти'));
  expect(startCalls(ui.topic)).toEqual([{ program: free.id, use_character: false, role: 'default' }]);
});

test('карточка программы: иконка своего цвета, сложность, «Что вы освоите» и прогресс; без упражнений прогресса нет', () => {
  const ui = setup();
  fireEvent.click(rowOf(ui, free.name));
  const head = ui.container.querySelector('.AntagTraining__detailHead') as HTMLElement;
  expect(head.querySelector('.fa-dumbbell.color-teal')).toBeTruthy();
  expect(ui.getByText('Что вы освоите')).toBeTruthy();
  expect(ui.getByText('Лечение')).toBeTruthy();
  expect(ui.getByText('Упражнения за раунд: 1 из 3')).toBeTruthy();
  fireEvent.click(rowOf(ui, hk47.name));
  expect(ui.getByText('Чужаки · сложность сложная')).toBeTruthy();
  expect(ui.queryByText(/Упражнения за раунд/)).toBeNull();
});

const roles = [
  { id: 'default', name: 'Учебное тело', department: 'Полигон', order: 0 },
  { id: 'crew:Medical Doctor', name: 'Medical Doctor', department: 'Медицина', order: 41 },
];

test('выбранная должность уходит в start', () => {
  const ui = setup({ roles });
  fireEvent.click(rowOf(ui, heretic.name));
  fireEvent.click(ui.getByText('Учебное тело'));
  fireEvent.click(ui.getByText('Medical Doctor'));
  fireEvent.click(ui.getByText('Войти'));
  expect(startCalls(ui.topic)[0].role).toBe('crew:Medical Doctor');
});

test('в каталоге киборг не выбирается для программы только для людей', () => {
  const ui = setup({ roles: [...roles, { id: 'silicon:cyborg', name: 'Киборг', department: 'Синтетики', order: 2, kind: 2 }], programs: [{ ...heretic, allowed_roles: 1 }] });
  fireEvent.click(rowOf(ui, heretic.name));
  fireEvent.click(ui.getByText('Учебное тело'));
  fireEvent.click(ui.getByText('Киборг'));
  expect(ui.container.textContent).not.toContain('Эта программа работает только с человеком');
});

const openSquad = {
  id: 'squad_1',
  name: 'Альфа',
  color: '#e05d5d',
  open: 1,
  leader: 'Ли Ван',
  members: ['Ли Ван'],
  sector: 'Тёмный сектор',
  scenario: {
    name: 'Своя сборка',
    phase: 'setup' as const,
    venue: 'Тёмный сектор',
    slots: [{ id: 'slot_1', label: 'Сыщик', side_name: 'Сторона А', role_name: 'Детектив', program_name: 'Снаряжение и бой', count: 1, required: 0, occupants: [], free: 1, joinable: 1 }],
  },
};

const joinCalls = (topic: jest.Mock) => topic.mock.calls.filter(([message]) => message.type === 'act/join_squad').map(([message]) => JSON.parse(message.payload));

test('открытые группы: вход в свободный слот и в группу без слота с выбранной куклой и должностью', () => {
  const ui = setup({ roles, squads: [openSquad] });
  fireEvent.click(ui.getByText('Группы (1)'));
  expect(ui.getByText('Открытые группы')).toBeTruthy();
  expect(ui.queryByText('С чего начать')).toBeNull();
  expect(ui.queryByText('Войти')).toBeNull();
  fireEvent.click(ui.getByText('Учебная кукла'));
  fireEvent.click(ui.getByText('Занять слот'));
  fireEvent.click(ui.getByText('Учебное тело'));
  fireEvent.click(ui.getByText('Medical Doctor'));
  fireEvent.click(ui.getByText('Войти в группу'));
  expect(joinCalls(ui.topic)).toEqual([
    { squad: 'squad_1', slot: 'slot_1', use_character: false, role: 'default' },
    { squad: 'squad_1', use_character: false, role: 'crew:Medical Doctor' },
  ]);
  fireEvent.click(ui.getByText('Программы'));
  expect(ui.getByText('С чего начать')).toBeTruthy();
});

test('без открытых групп каталог подсказывает собрать свою', () => {
  const ui = setup();
  fireEvent.click(ui.getByText('Группы'));
  expect(ui.getByText(/Открытых групп сейчас нет/)).toBeTruthy();
});

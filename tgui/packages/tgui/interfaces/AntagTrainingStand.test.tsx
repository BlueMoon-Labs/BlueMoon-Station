import { fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { StandData, StandToggle, TrainingStand } from './AntagTrainingStand';

const stand: StandData = {
  enabled: 1,
  full: 0,
  query: 'crowbar',
  results: [{ path: '/obj/item/crowbar', name: 'crowbar' }],
  more: 0,
  members: [
    { id: 'self', name: 'Кодер', role: 'default', program_id: '/datum/antag_training_program/free', self: 1 },
    { id: 'other', name: 'Ученик', role: 'default', program_id: '/datum/antag_training_program/free', self: 0 },
  ],
};

const backend = {
  roles: [
    { id: 'default', name: 'Учебное тело', department: 'Полигон', order: 0 },
    { id: 'crew:Station Engineer', name: 'Station Engineer', department: 'Инженерия', order: 1 },
  ],
  programs: [
    { id: '/datum/antag_training_program/free', name: 'Снаряжение и бой' },
    { id: '/datum/antag_training_program/antag/traitor', name: 'Предатель' },
  ],
  zones: [{ id: 'hub', name: 'Безопасный центр' }, { id: 'pve', name: 'Арена противников' }],
  sectors: [{ id: 'dark', name: 'Тёмный сектор' }],
  busy: 0,
};

let now = Date.now();

const setup = (overrides: Partial<StandData> | null = {}, element = <TrainingStand />) => {
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'AntagTraining' }, data: { ...backend, stand: overrides === null ? null : { ...stand, ...overrides } } }));
  return { ...render(element), topic };
};

const sent = (topic: jest.Mock, action: string) => topic.mock.calls.map(([message]) => message).filter((message) => message.type === `act/${action}`).map((message) => ({ ...message, payload: JSON.parse(message.payload) }));

test('переключатель скрыт без прав и шлёт stand_toggle с правами', () => {
  expect(setup(null, <StandToggle />).queryByText('Режим стенда')).toBeNull();
  const ui = setup({ enabled: 0 }, <StandToggle />);
  fireEvent.click(ui.getByText('Режим стенда'));
  expect(sent(ui.topic, 'stand_toggle')).toHaveLength(1);
});

test('поиск и создание по пути', () => {
  const ui = setup();
  fireEvent.input(ui.getByPlaceholderText('Часть пути, например gun/energy'), { target: { value: 'gun/energy' } });
  fireEvent.click(ui.getByText('Найти'));
  expect(sent(ui.topic, 'stand_search')[0].payload).toEqual({ query: 'gun/energy' });
  fireEvent.click(ui.getByText('Создать'));
  expect(sent(ui.topic, 'stand_spawn')[0].payload).toEqual({ path: '/obj/item/crowbar' });
});

test('короткий запрос не отправляется, стоп-лист назван только не-админу', () => {
  const ui = setup({ query: 'ab', results: [] });
  fireEvent.input(ui.getByPlaceholderText('Часть пути, например gun/energy'), { target: { value: 'ab' } });
  expect(ui.getByText('Найти').closest('.Button')?.className).toContain('Button--disabled');
  expect(ui.getByText(/Введите хотя бы 3 символа/)).toBeTruthy();
  expect(ui.getByText(/Их создают только администраторы/)).toBeTruthy();
  ui.unmount();
  expect(setup({ full: 1 }).queryByText(/Их создают только администраторы/)).toBeNull();
});

test('сброс зоны без голосования после подтверждения, центр не сбрасывается', () => {
  const ui = setup();
  expect(ui.queryByText('Безопасный центр')).toBeNull();
  fireEvent.click(ui.getByText('Тёмный сектор'));
  expect(sent(ui.topic, 'stand_reset')).toHaveLength(0);
  fireEvent.click(ui.getByText('Сбросить сейчас?'));
  expect(sent(ui.topic, 'stand_reset')[0].payload).toEqual({ zone: 'dark' });
});

test('выключенный стенд показывает подсказку вместо инструментов', () => {
  const ui = setup({ enabled: 0 });
  expect(ui.getByText(/Режим стенда выключен/)).toBeTruthy();
  expect(ui.queryByText('Создать по пути')).toBeNull();
});

test('должность и программа другого участника меняются из стенда', () => {
  const ui = setup();
  fireEvent.click(ui.getAllByText('Учебное тело')[1]);
  fireEvent.click(ui.getByText('Station Engineer'));
  expect(sent(ui.topic, 'stand_role')[0].payload).toEqual({ id: 'other', role: 'crew:Station Engineer' });
  fireEvent.click(ui.getAllByText('Снаряжение и бой')[1]);
  fireEvent.click(ui.getByText('Предатель'));
  expect(sent(ui.topic, 'stand_program')[0].payload).toEqual({ id: 'other', program: '/datum/antag_training_program/antag/traitor' });
});

test('бронь группы снимается, группа распускается после подтверждения', () => {
  const ui = setup({ squads: [{ id: 'alpha', name: 'Альфа', members: 2, sector_id: 'dark', sector: 'Тёмный сектор' }, { id: 'beta', name: 'Бета', members: 1, sector_id: null, sector: null }] });
  expect(ui.getAllByText('Снять бронь')).toHaveLength(1);
  fireEvent.click(ui.getByText('Снять бронь'));
  fireEvent.click(ui.getByText('Снять бронь группы?'));
  expect(sent(ui.topic, 'stand_release')[0].payload).toEqual({ kind: 'booking', id: 'dark' });
  fireEvent.click(ui.getAllByText('Распустить')[1]);
  fireEvent.click(ui.getByText('Распустить группу?'));
  expect(sent(ui.topic, 'stand_release')[1].payload).toEqual({ kind: 'squad', id: 'beta' });
});

test('сценарий группы закрывается после подтверждения, кнопка только у группы со сценарием', () => {
  const ui = setup({ squads: [{ id: 'alpha', name: 'Альфа', members: 2, sector_id: 'station', sector: 'Станционный макет', scenario: 'Культ' }, { id: 'beta', name: 'Бета', members: 1, sector_id: null, sector: null }] });
  expect(ui.getByText(/сценарий «Культ»/)).toBeTruthy();
  expect(ui.getAllByText('Завершить сценарий')).toHaveLength(1);
  fireEvent.click(ui.getByText('Завершить сценарий'));
  fireEvent.click(ui.getByText('Закрыть сценарий группы?'));
  expect(sent(ui.topic, 'stand_release')[0].payload).toEqual({ kind: 'scenario', id: 'alpha' });
});

test('занятая площадка освобождается после подтверждения', () => {
  const ui = setup({ pads: [{ id: 'pad_3', name: 'Площадка 3', owner: 'группа «Альфа»', preset: 'Бриг' }] });
  expect(ui.getByText(/Владелец: группа «Альфа» · пресет «Бриг»/)).toBeTruthy();
  fireEvent.click(ui.getByText('Освободить'));
  expect(sent(ui.topic, 'stand_release')).toHaveLength(0);
  fireEvent.click(ui.getByText('Освободить площадку?'));
  expect(sent(ui.topic, 'stand_release')[0].payload).toEqual({ kind: 'pad', id: 'pad_3' });
});

test('стенд кодера называет лимиты удвоенными, стенд админа - снятыми', () => {
  expect(setup({ full: 0, limit_scale: 2 }).getByText(/Лимиты целей, вещей и построек для вас удвоены/)).toBeTruthy();
  expect(setup({ full: 1, limit_scale: 0 }).getByText(/Лимиты целей, вещей и построек для вас сняты/)).toBeTruthy();
});

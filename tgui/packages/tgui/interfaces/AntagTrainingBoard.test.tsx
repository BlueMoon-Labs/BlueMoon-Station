import { fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { AntagTrainingBoard, BoardSquad, SquadBoardList } from './AntagTrainingBoard';

const squad = (overrides: Partial<BoardSquad> = {}): BoardSquad => ({
  id: 'squad_1',
  name: 'Альфа',
  color: '#e05d5d',
  open: 1,
  leader: 'Ли Ван',
  members: ['Ли Ван'],
  sector: 'Тёмный сектор',
  scenario: {
    name: 'Своя сборка',
    phase: 'setup',
    venue: 'Тёмный сектор',
    slots: [
      { id: 'slot_1', label: 'Сыщик', side_name: 'Сторона А', role_name: 'Детектив', program_name: 'Снаряжение и бой', count: 1, required: 0, occupants: [], free: 1, joinable: 1 },
      { id: 'slot_2', label: 'Охрана', side_name: 'Сторона Б', role_name: 'Офицер СБ', program_name: 'Снаряжение и бой', count: 1, required: 1, occupants: ['Ли Ван'], free: 0, joinable: 0 },
    ],
  },
  ...overrides,
});

let now = Date.now();

const setup = (data: Record<string, unknown>, element = <AntagTrainingBoard />) => {
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'AntagTrainingBoard' }, data }));
  return { ...render(element), topic };
};

const sent = (topic: jest.Mock, action: string) => topic.mock.calls.map(([message]) => message).filter((message) => message.type === `act/${action}`).map((message) => JSON.parse(message.payload));

test('призрак видит группы и слоты доски без кнопок', () => {
  const ui = setup({ participant: 0, board: [squad()] });
  expect(ui.getByText(/только для просмотра/)).toBeTruthy();
  expect(ui.getByText('Альфа')).toBeTruthy();
  expect(ui.getByText(/Сценарий «Своя сборка» · разбор слотов/)).toBeTruthy();
  expect(ui.getByText('Сыщик')).toBeTruthy();
  expect(ui.queryByText('Занять слот')).toBeNull();
  expect(ui.queryByText('Войти в группу')).toBeNull();
});

test('участник получает на доске вкладки групп и сценария', () => {
  const ui = setup({ participant: 1, squads: [], members: [{ id: 'm1', name: 'Ли Ван', self: 1, connected: 1 }], scenario_templates: [], sectors: [] });
  expect(ui.getByText('Новая группа')).toBeTruthy();
  fireEvent.click(ui.getByText('Собрать группу'));
  expect(sent(ui.topic, 'squad_create')).toEqual([{ name: '', open: true }]);
  fireEvent.click(ui.getByText('Сценарий'));
  expect(ui.getByText(/Сценарии играет группа/)).toBeTruthy();
});

test('список с обработчиком предлагает только свободные слоты открытых групп', () => {
  const onJoin = jest.fn();
  const ui = setup({}, <SquadBoardList squads={[squad(), squad({ id: 'squad_2', name: 'Бета', open: 0, scenario: null })]} onJoin={onJoin} empty="пусто" />);
  expect(ui.getAllByText('Занять слот')).toHaveLength(1);
  fireEvent.click(ui.getByText('Занять слот'));
  expect(onJoin).toHaveBeenLastCalledWith('squad_1', 'slot_1');
  expect(ui.getAllByText('Войти в группу')).toHaveLength(1);
  fireEvent.click(ui.getByText('Войти в группу'));
  expect(onJoin).toHaveBeenLastCalledWith('squad_1');
  expect(ui.getByText('По приглашению')).toBeTruthy();
  expect(ui.getByText(/Сценарий не выбран/)).toBeTruthy();
  ui.unmount();
  expect(setup({}, <SquadBoardList squads={[]} empty="Открытых групп нет." />).getByText('Открытых групп нет.')).toBeTruthy();
});

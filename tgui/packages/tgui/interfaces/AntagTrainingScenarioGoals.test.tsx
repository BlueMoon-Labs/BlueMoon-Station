import { fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { ScenarioEntry, TrainingScenario } from './AntagTrainingScenario';

const sides = [{ id: 'a', name: 'Сторона А' }, { id: 'b', name: 'Сторона Б' }];
const sideOptions = sides.map((side) => ({ value: side.id, name: side.name }));
const library = [
  { id: 'survive', name: 'Продержаться', params: [{ key: 'minutes', label: 'Минут', options: [{ value: '1', name: '1 мин' }, { value: '5', name: '5 мин' }] }] },
  { id: 'side_down', name: 'Вывести из строя противника', params: [{ key: 'target', label: 'Противник', options: sideOptions }] },
  { id: 'detain', name: 'Задержать и доставить', params: [{ key: 'target', label: 'Противник', options: sideOptions }, { key: 'zone', label: 'Куда доставить', options: [{ value: 'side:depths', name: 'Дальние комнаты' }] }] },
];
const custom: ScenarioEntry = {
  id: 'custom',
  name: 'Своя сборка',
  desc: 'Пустой лист.',
  phase: 'setup',
  sector: 'Тёмный сектор',
  sector_id: 'dark',
  booked: 1,
  leader: 1,
  free_play: 0,
  min_players: 1,
  max_players: 12,
  time_limit: 0,
  elapsed: 0,
  remaining: null,
  sides,
  slots: [],
  members: [{ id: 'me', name: 'Ая', slot: null }],
  my_slot: null,
  objectives: [],
  objectives_editable: 1,
  objective_specs: [{ name: 'Продержаться 1 мин', side: 'a', side_name: 'Сторона А' }],
  objective_library: library,
  start_problem: null,
  summary: null,
  runs: 0,
};

let now = Date.now();

const setup = (scenario: ScenarioEntry) => {
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'AntagTraining' }, data: { scenario_templates: [], scenario, squad: 'alpha', squad_leader: 1, roles: [], programs: [] } }));
  const sent = (type: string) => topic.mock.calls.map(([message]) => message).filter((message) => message.type === `act/${type}`).map((message) => JSON.parse(message.payload));
  return { ...render(<TrainingScenario />), sent };
};

test('лидер видит цели листа, убирает цель по номеру и добавляет новую с параметрами', () => {
  const ui = setup(custom);
  expect(ui.getByText('Цели сторон')).toBeTruthy();
  expect(ui.getByText(/Продержаться 1 мин/)).toBeTruthy();
  fireEvent.click(ui.getByText('Добавить цель'));
  expect(ui.sent('scenario_objective_add')).toEqual([{ kind: 'survive', side: 'a', minutes: '1' }]);
  fireEvent.click(ui.getByText('Продержаться'));
  fireEvent.click(ui.getByText('Задержать и доставить'));
  expect(ui.getByText('Куда доставить')).toBeTruthy();
  fireEvent.click(ui.getByText('Добавить цель'));
  expect(ui.sent('scenario_objective_add')[1]).toEqual({ kind: 'detain', side: 'a', target: 'b', zone: 'side:depths' });
  fireEvent.click(ui.getByText(/Продержаться 1 мин/).closest('.Stack')!.querySelector('.Button')!);
  expect(ui.sent('scenario_objective_remove')).toEqual([{ index: 1 }]);
});

test('участник видит цели без правки; без библиотеки лидер ждёт загрузки места', () => {
  const member = setup({ ...custom, leader: 0 });
  expect(member.getByText(/Продержаться 1 мин/)).toBeTruthy();
  expect(member.queryByText('Добавить цель')).toBeNull();
  member.unmount();
  const loading = setup({ ...custom, objective_specs: [], objective_library: [] });
  expect(loading.getByText(/Целей нет/)).toBeTruthy();
  expect(loading.getByText(/Место ещё загружается/)).toBeTruthy();
});

test('шаблон без правки целей не показывает раздел целей', () => {
  const ui = setup({ ...custom, id: 'traitor_security', objectives_editable: 0 });
  expect(ui.queryByText('Цели сторон')).toBeNull();
});

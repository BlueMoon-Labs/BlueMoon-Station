import { fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';
import { ReactElement } from 'react';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { ScenarioBanner, ScenarioEntry, TrainingScenario } from './AntagTrainingScenario';

const templates = [
  { id: 'traitor_security', name: 'Предатель против СБ', desc: 'Документы и бриг.', sector: 'station', min_players: 2, max_players: 5, minutes: 15, sides: ['Предатель', 'СБ'] },
  { id: 'custom', name: 'Своя сборка', desc: 'Пустой лист.', sector: null, min_players: 1, max_players: 12, minutes: 0, sides: ['Сторона А', 'Сторона Б'] },
];
const roles = [
  { id: 'default', name: 'Учебное тело', department: 'Полигон', order: 0, kind: 1 },
  { id: 'crew:Security Officer', name: 'Security Officer', department: 'Служба безопасности', order: 1, kind: 1 },
  { id: 'silicon:cyborg', name: 'Киборг', department: 'Синтетики', order: 2, kind: 2 },
];
const programs = [
  { id: '/datum/antag_training_program/free', name: 'Снаряжение и бой', allowed_roles: 3 },
  { id: '/datum/antag_training_program/antag/traitor', name: 'Предатель', allowed_roles: 1 },
];
const traitorSlot = { id: 'slot1', side: 'traitor', label: 'Предатель', role: 'default', role_name: 'Учебное тело', program: '/datum/antag_training_program/antag/traitor', program_name: 'Предатель', count: 1, required: 1, occupants: [] };
const officerSlot = { id: 'slot2', side: 'security', label: 'Офицер СБ', role: 'crew:Security Officer', role_name: 'Security Officer', program: null, program_name: 'Снаряжение и бой', count: 3, required: 1, occupants: [{ id: 'bo', name: 'Бо', self: 0, out: 0 }] };
const scenario: ScenarioEntry = {
  id: 'traitor_security',
  name: 'Предатель против СБ',
  desc: 'Документы и бриг.',
  phase: 'setup',
  sector: 'Станционный макет',
  sector_id: 'station',
  booked: 1,
  leader: 1,
  free_play: 0,
  min_players: 2,
  max_players: 5,
  time_limit: 900,
  elapsed: 0,
  remaining: null,
  sides: [{ id: 'traitor', name: 'Предатель' }, { id: 'security', name: 'СБ' }],
  slots: [traitorSlot, officerSlot],
  members: [{ id: 'me', name: 'Ая', slot: null }, { id: 'bo', name: 'Бо', slot: 'slot2' }],
  my_slot: null,
  objectives: [],
  start_problem: null,
  summary: null,
  runs: 0,
};
const objectives = [
  { name: 'Вынести документы', side: 'traitor', side_name: 'Предатель', done: 0, progress: null },
  { name: 'Заковать предателя', side: 'security', side_name: 'СБ', done: 1, progress: null },
];
const base = { scenario_templates: templates, scenario: null, squad: 'alpha', squad_leader: 1, sectors: [{ id: 'dark', name: 'Тёмный сектор' }, { id: 'station', name: 'Станционный макет' }], roles, programs };

let now = Date.now();

const setup = (data: Record<string, unknown>, element: ReactElement = <TrainingScenario />) => {
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'AntagTraining' }, data: { ...base, ...data } }));
  const sent = (type: string) => topic.mock.calls.map(([message]) => message).filter((message) => message.type === `act/${type}`).map((message) => JSON.parse(message.payload));
  return { ...render(element), topic, sent };
};

test('без группы: каталог виден, выбрать нельзя', () => {
  const ui = setup({ squad: null, squad_leader: 0 });
  expect(ui.getByText(/Сценарии играет группа/)).toBeTruthy();
  expect(ui.getByText('Предатель против СБ')).toBeTruthy();
  expect(ui.queryByText('Выбрать')).toBeNull();
});

test('лидер выбирает шаблон и пустой лист в секторе', () => {
  const ui = setup({});
  fireEvent.click(ui.getByText('Выбрать'));
  expect(ui.sent('scenario_pick')).toEqual([{ id: 'traitor_security' }]);
  fireEvent.click(ui.getByText('Пустой лист'));
  expect(ui.sent('scenario_pick')[1]).toEqual({ id: 'custom', sector: 'dark' });
  expect(ui.getByText(/Сектор: Станционный макет · игроков 2–5 · 15 мин/)).toBeTruthy();
});

test('быстрый сценарий площадки выбирается без сектора, место - площадка хаба', () => {
  const brigDefense = { id: 'brig_defense', name: 'Оборона брига', desc: 'Бриг на площадке.', sector: null, pad_preset: 'brig', pad_preset_name: 'Бриг', min_players: 2, max_players: 8, minutes: 10, sides: ['СБ', 'Налётчики'] };
  const ui = setup({ scenario_templates: [brigDefense], pads: [{ id: 'pad_2', name: 'Площадка 2', owner: null, mine: 0 }] });
  expect(ui.getByText(/Площадка хаба, пресет «Бриг» · игроков 2–8 · 10 мин · СБ против Налётчики/)).toBeTruthy();
  fireEvent.click(ui.getByText('Выбрать'));
  expect(ui.sent('scenario_pick')).toEqual([{ id: 'brig_defense' }]);
  ui.unmount();
  const header = setup({ scenario: { ...scenario, sector: 'Площадка 2', sector_id: 'pad_2', venue_kind: 'pad', booked: 0 } });
  expect(header.getByText(/Площадка «Площадка 2»: не занята/)).toBeTruthy();
  fireEvent.click(header.getByText('Занять площадку'));
  expect(header.sent('scenario_book')).toHaveLength(1);
});

test('участник занимает слот и выходит из него', () => {
  const ui = setup({ squad_leader: 0, scenario: { ...scenario, leader: 0, start_problem: 'Обязательный слот «Предатель» пуст.' } });
  expect(ui.queryByText('Старт')).toBeNull();
  expect(ui.getByText('Обязательный слот «Предатель» пуст.')).toBeTruthy();
  fireEvent.click(ui.getAllByText('Занять')[0]);
  expect(ui.sent('scenario_take')).toEqual([{ slot: 'slot1' }]);
  ui.unmount();
  const mine = setup({ squad_leader: 0, scenario: { ...scenario, leader: 0, my_slot: 'slot2' } });
  fireEvent.click(mine.getByText('Выйти из слота'));
  expect(mine.sent('scenario_leave')).toHaveLength(1);
});

test('лидер правит слоты, убирает участника и стартует', () => {
  const ui = setup({ scenario });
  fireEvent.click(Array.from(ui.container.querySelectorAll('.Button')).find((button) => button.querySelector('.fa-plus') && !button.textContent)!);
  expect(ui.sent('scenario_slot_edit')[0]).toEqual({ slot: 'slot1', field: 'count', value: 2 });
  fireEvent.click(ui.getAllByText('Обязательный')[1]);
  expect(ui.sent('scenario_slot_edit')[1]).toEqual({ slot: 'slot2', field: 'required', value: false });
  fireEvent.click(ui.getAllByText('Убрать слот')[0]);
  fireEvent.click(ui.getByText('Убрать?'));
  expect(ui.sent('scenario_slot_remove')).toEqual([{ slot: 'slot1' }]);
  fireEvent.click(ui.getByText('Добавить слот'));
  expect(ui.sent('scenario_slot_add')).toEqual([{ side: 'traitor', role: 'default', program: '/datum/antag_training_program/free' }]);
  const unassign = ui.getByText('Бо').parentElement!.querySelector('.Button')!;
  fireEvent.click(unassign);
  expect(ui.sent('scenario_assign')).toEqual([{ slot: '', member: 'bo' }]);
  fireEvent.click(ui.getByText('Старт'));
  expect(ui.sent('scenario_start')).toHaveLength(1);
});

test('старт закрыт, пока есть причина, сектор занимается кнопкой', () => {
  const ui = setup({ scenario: { ...scenario, booked: 0, start_problem: 'Сначала займите сектор «Станционный макет» для группы.' } });
  expect(ui.getByText('Старт').closest('.Button')?.className).toContain('Button--disabled');
  fireEvent.click(ui.getByText('Занять сектор'));
  expect(ui.sent('scenario_book')).toHaveLength(1);
  fireEvent.click(ui.getByText('Снять сценарий'));
  fireEvent.click(ui.getByText('Снять сценарий?'));
  expect(ui.sent('scenario_cancel')).toHaveLength(1);
});

test('идущая партия: таймер, цели, выбывшие и ручной итог', () => {
  const running = { ...scenario, phase: 'running' as const, elapsed: 75, remaining: 825, objectives, slots: [{ ...traitorSlot, occupants: [{ id: 'me', name: 'Ая', self: 1, out: 1 }] }, officerSlot] };
  const ui = setup({ scenario: running });
  expect(ui.getByText('Партия идёт · осталось 13:45')).toBeTruthy();
  expect(ui.getByText('Вынести документы')).toBeTruthy();
  expect(ui.getByText(/Ая · Предатель · выбыл/)).toBeTruthy();
  expect(ui.getByText(/участнику из пульта открыты только снаряжение и выход/)).toBeTruthy();
  expect(ui.queryByText('Старт')).toBeNull();
  fireEvent.click(ui.getByText('Подвести итог'));
  fireEvent.click(ui.getByText('Остановить партию без победителя?'));
  expect(ui.sent('scenario_end')).toHaveLength(1);
  ui.unmount();
  const banner = setup({ scenario: running }, <ScenarioBanner />);
  expect(banner.getByText(/осталось 13:45 · целей выполнено 1 из 2/)).toBeTruthy();
});

test('итог: победитель, выбывшие, повтор, смена сторон и завершение', () => {
  const summary = { winner: 'security', winner_name: 'СБ', reason: 'Все цели стороны «СБ» выполнены.', time: 192, objectives, eliminated: ['Ая'] };
  const ui = setup({ scenario: { ...scenario, phase: 'summary', summary, runs: 1 } });
  expect(ui.getByText('Победа: СБ')).toBeTruthy();
  expect(ui.getByText(/Время партии: 3:12/)).toBeTruthy();
  expect(ui.getByText('Выбыли: Ая.')).toBeTruthy();
  fireEvent.click(ui.getByText('Повтор'));
  expect(ui.sent('scenario_replay')).toHaveLength(1);
  fireEvent.click(ui.getByText('Сменить стороны'));
  expect(ui.sent('scenario_swap')).toHaveLength(1);
  fireEvent.click(ui.getByText('Завершить'));
  fireEvent.click(ui.getByText('Всех в вестибюль хаба с прежними ролями?'));
  expect(ui.sent('scenario_finish')).toHaveLength(1);
});

test('не лидер видит итог без кнопок', () => {
  const summary = { winner: null, winner_name: null, reason: 'Время вышло.', time: 900, objectives: [], eliminated: [] };
  const ui = setup({ squad_leader: 0, scenario: { ...scenario, leader: 0, phase: 'summary', summary } });
  expect(ui.getByText('Итог: без победителя')).toBeTruthy();
  expect(ui.queryByText('Повтор')).toBeNull();
  expect(ui.getByText(/выбирает лидер группы/)).toBeTruthy();
});

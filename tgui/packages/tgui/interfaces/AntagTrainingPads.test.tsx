import { fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { AntagTrainingPads, PadEntry, PadsData, TrainingPads } from './AntagTrainingPads';

const pad = (overrides: Partial<PadEntry> = {}): PadEntry => ({
  id: 'pad_1',
  name: 'Площадка 1',
  preset: 'bare',
  preset_name: 'Пустая площадка',
  owner: null,
  squad: 0,
  mine: 0,
  open: 1,
  can_enter: 1,
  loading: 0,
  ready: 1,
  inside: 0,
  scenario: null,
  idle_remaining: null,
  vote: null,
  ...overrides,
});

const backend: PadsData = {
  pads_ready: 1,
  pad_idle_minutes: 20,
  pad_mine: null,
  pad_presets: [
    { id: 'brig', name: 'Бриг', desc: 'Камеры и оружейная.', programs: ['Беглец', 'Охотник за беглецами'], scenarios: ['Оборона брига'] },
    { id: 'bar', name: 'Бар', desc: 'Стойка и кухня.' },
  ],
  pads: [pad()],
};

let now = Date.now();

const setup = (data: Record<string, unknown>, element = <TrainingPads />) => {
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'AntagTraining' }, data: { ...backend, ...data } }));
  return { ...render(element), topic };
};

const sent = (topic: jest.Mock, action: string) => topic.mock.calls.map(([message]) => message).filter((message) => message.type === `act/${action}`).map((message) => JSON.parse(message.payload));

test('свободную площадку можно занять, если своей ещё нет', () => {
  const ui = setup({});
  expect(ui.getByText('свободна')).toBeTruthy();
  fireEvent.click(ui.getByText('Занять'));
  expect(sent(ui.topic, 'pad_claim')).toEqual([{ id: 'pad_1' }]);
  ui.unmount();
  const busy = setup({ pad_mine: 'pad_2' });
  fireEvent.click(busy.getByText('Занять'));
  expect(sent(busy.topic, 'pad_claim')).toHaveLength(0);
});

test('владелец выбирает пресет, закрывает вход, перезагружает и освобождает', () => {
  const ui = setup({ pad_mine: 'pad_1', pads: [pad({ owner: 'Учебный', mine: 1, idle_remaining: 600 })] });
  expect(ui.getByText(/освободится через 10:00/)).toBeTruthy();
  fireEvent.click(ui.getByText('Загрузить'));
  expect(sent(ui.topic, 'pad_preset')).toEqual([{ id: 'pad_1', preset: 'brig' }]);
  fireEvent.click(ui.getByText('Пускать всех'));
  expect(sent(ui.topic, 'pad_open')).toEqual([{ id: 'pad_1' }]);
  fireEvent.click(ui.getByText('Перезагрузить'));
  expect(sent(ui.topic, 'pad_reload')).toEqual([{ id: 'pad_1' }]);
  fireEvent.click(ui.getByText('Освободить'));
  fireEvent.click(ui.getByText('Освободить площадку?'));
  expect(sent(ui.topic, 'pad_release')).toEqual([{ id: 'pad_1' }]);
});

test('выбранный пресет называет программы и сценарии, под которые он сделан', () => {
  const ui = setup({ pad_mine: 'pad_1', pads: [pad({ owner: 'Учебный', mine: 1 })] });
  expect(ui.getByText('Подходит программам: Беглец, Охотник за беглецами.')).toBeTruthy();
  expect(ui.getByText('Сценарии на этом пресете: Оборона брига.')).toBeTruthy();
  ui.unmount();
  const guest = setup({ pads: [pad({ owner: 'Учебный' })] });
  expect(guest.queryByText(/Подходит программам/)).toBeNull();
});

test('чужая закрытая площадка: без кнопок владельца, с пометкой о закрытом входе', () => {
  const ui = setup({ pads: [pad({ owner: 'группа «Альфа»', squad: 1, open: 0, can_enter: 0, idle_remaining: 60 })] });
  expect(ui.getByText('только для владельцев')).toBeTruthy();
  expect(ui.getByText(/Вход закрыт/)).toBeTruthy();
  expect(ui.queryByText('Занять')).toBeNull();
  expect(ui.queryByText('Загрузить')).toBeNull();
  expect(ui.queryByText('Освободить')).toBeNull();
});

test('площадка идущего сценария: вход только участникам партии', () => {
  const ui = setup({ pads: [pad({ owner: 'группа «Альфа»', squad: 1, open: 1, can_enter: 0, scenario: 'Королевская битва' })] });
  expect(ui.getByText('сценарий «Королевская битва»')).toBeTruthy();
  expect(ui.getByText(/внутрь пускают только его участников, выбывшие смотрят с трибуны/)).toBeTruthy();
  expect(ui.queryByText(/Вход закрыт/)).toBeNull();
});

test('голосование за перезагрузку: согласие шлёт pad_vote', () => {
  const vote = { preset_name: 'Бар', reload: 0, approved: 1, total: 2, remaining: 30, voted: 0, can_vote: 1 };
  const ui = setup({ pads: [pad({ owner: 'Учебный', inside: 2, vote })] });
  expect(ui.getByText('Пресет «Бар»')).toBeTruthy();
  fireEvent.click(ui.getByText('Согласиться'));
  expect(sent(ui.topic, 'pad_vote')).toEqual([{ id: 'pad_1' }]);
});

test('площадки ещё не загружены', () => {
  const ui = setup({ pads_ready: 0 });
  expect(ui.getByText(/загружаются вместе с мини-станцией/)).toBeTruthy();
  expect(ui.queryByText('Занять')).toBeNull();
});

test('пульт у входа показывает только свою площадку', () => {
  const ui = setup({ focus: 'pad_2', pads: [pad(), pad({ id: 'pad_2', name: 'Площадка 2', preset_name: 'Бриг' })] }, <AntagTrainingPads />);
  expect(ui.getByText('Площадка 2')).toBeTruthy();
  expect(ui.queryByText('Площадка 1')).toBeNull();
});

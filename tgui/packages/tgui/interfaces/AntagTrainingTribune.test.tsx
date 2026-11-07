import { fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { AntagTrainingTribune, neighbourCameras, TribuneData } from './AntagTrainingTribune';

const backend: TribuneData = {
  mapRef: 'camera_console_map',
  venues: [
    { id: 'dark', name: 'Тёмный сектор', kind: 'sector', holder: 'группа «Альфа»', scenario: 'Своя сборка' },
    { id: 'pad_2', name: 'Площадка 2', kind: 'pad', holder: 'Ли Ван', scenario: null },
  ],
  venue: null,
  cameras: [],
  activeCamera: null,
};

let now = Date.now();

const setup = (data: Partial<TribuneData>) => {
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'AntagTrainingTribune' }, data: { ...backend, ...data } }));
  return { ...render(<AntagTrainingTribune />), topic };
};

const sent = (topic: jest.Mock, action: string) => topic.mock.calls.map(([message]) => message).filter((message) => message.type === `act/${action}`).map((message) => JSON.parse(message.payload));

test('трибуна предлагает занятые места и просит выбрать', () => {
  const ui = setup({});
  expect(ui.getByText('Тёмный сектор · «Своя сборка»')).toBeTruthy();
  expect(ui.getByText('Выберите сектор или площадку слева.')).toBeTruthy();
  expect(ui.queryByText('Камеры')).toBeNull();
  fireEvent.click(ui.getByText('Площадка 2'));
  expect(sent(ui.topic, 'select_venue')).toEqual([{ id: 'pad_2' }]);
});

test('пустая трибуна объясняет, когда появится картинка', () => {
  const ui = setup({ venues: [] });
  expect(ui.getByText(/ни один сектор не забронирован/)).toBeTruthy();
});

test('камеры места переключаются списком и стрелками', () => {
  const ui = setup({ venue: 'dark', cameras: [{ name: 'Тёмный сектор: обзор 2' }, { name: 'Тёмный сектор: обзор 1' }], activeCamera: { name: 'Тёмный сектор: обзор 1', status: 1 } });
  expect(ui.getByText(/группа «Альфа» · Тёмный сектор: обзор 1/)).toBeTruthy();
  fireEvent.click(ui.getByText('Тёмный сектор: обзор 2'));
  fireEvent.click(ui.container.querySelector('.fa-chevron-right')?.closest('.Button') as HTMLElement);
  fireEvent.click(ui.container.querySelector('.fa-chevron-left')?.closest('.Button') as HTMLElement);
  expect(sent(ui.topic, 'switch_camera')).toEqual([{ name: 'Тёмный сектор: обзор 2' }, { name: 'Тёмный сектор: обзор 2' }]);
});

test('соседние камеры для стрелок', () => {
  const cameras = [{ name: 'a' }, { name: 'b' }, { name: 'c' }];
  expect(neighbourCameras(cameras, 'b')).toEqual(['a', 'c']);
  expect(neighbourCameras(cameras, 'a')).toEqual([undefined, 'b']);
  expect(neighbourCameras(cameras, null)).toEqual([undefined, undefined]);
});

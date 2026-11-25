import { fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../../backend';
import { debugReducer } from '../../debug';
import { PlayerSaveInspector, PlayerSaveInspectorData } from '.';

const root = JSON.stringify({
  format: 'bluemoon-player-save',
  version: 1,
  tree: { custom_moan_sounds: { value: { type: 'list', items: ['sound/a.ogg'], associations: [null] }, children: {} } },
});

const base: PlayerSaveInspectorData = {
  ckey: 'borisovych',
  files: [
    { path: 'preferences.sav.json', kind: 'root', slot: null, recovery: 0, size: 569478 },
    { path: 'preferences.sav.json.d/bb.sav.json', kind: 'slot', slot: 31, character: 'Anahit', recovery: 0, size: 2048 },
    { path: 'preferences.sav.json.d/cc.sav.json', kind: 'slot', slot: 6, character: 'Норика', recovery: 0, size: 1024 },
  ],
  default_slot: 31,
  selected: null,
  preview: null,
  preview_error: null,
  preview_truncated: 0,
  message: null,
};

const setup = (data: Partial<PlayerSaveInspectorData> = {}) => {
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'PlayerSaveInspector' }, data: { ...base, ...data } }));
  return { ...render(<PlayerSaveInspector />), topic };
};

const sent = (topic: jest.Mock, action: string) =>
  topic.mock.calls
    .map(([message]) => message)
    .filter((message) => message.type === `act/${action}`)
    .map((message) => JSON.parse(message.payload));

it('показывает активный слот первым с именем и выгружает слот целиком', () => {
  const { getByText, getAllByText, topic } = setup();
  expect(getByText('Слот 31 · Anahit')).toBeTruthy();
  expect(getByText('(активный)')).toBeTruthy();
  const order = getAllByText(/^Слот \d+ ·/).map((node) => node.textContent);
  expect(order[0]).toContain('Слот 31');
  fireEvent.click(getAllByText('Слот целиком')[0]);
  expect(sent(topic, 'download_bundle')).toEqual([{ slot: 31 }]);
  fireEvent.click(getByText('Скачать всё'));
  expect(sent(topic, 'download_bundle')[1]).toEqual({});
});

it('открывает файл и показывает читаемый вид с поиском строк', () => {
  const { getByText, getByPlaceholderText, container, topic } = setup({ selected: 'preferences.sav.json', preview: root });
  fireEvent.click(getByText('корень (preferences.sav.json)'));
  expect(sent(topic, 'view')).toEqual([{ path: 'preferences.sav.json' }]);
  const preview = container.querySelector('.PlayerSaveInspector__preview')!;
  expect(preview.textContent).toContain('"custom_moan_sounds": [');
  expect(preview.textContent).not.toContain('"items"');
  fireEvent.click(getByText('JSON'));
  expect(container.querySelector('.PlayerSaveInspector__preview')!.textContent).toContain('"items"');
  fireEvent.input(getByPlaceholderText('Найти строки...'), { target: { value: 'sound/a' } });
  expect(getByText(/Совпадений: 1/)).toBeTruthy();
});

it('без ckey просит ввести его, ошибки и сообщения видны', () => {
  const { getByText } = setup({ ckey: null, files: [], message: 'У nobody не найдено файлов сохранений.' });
  expect(getByText('Введите ckey игрока.')).toBeTruthy();
  expect(getByText('У nobody не найдено файлов сохранений.')).toBeTruthy();
});

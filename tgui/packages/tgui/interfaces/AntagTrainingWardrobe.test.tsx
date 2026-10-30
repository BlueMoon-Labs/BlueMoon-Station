import { fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { AntagTrainingWardrobe, AntagTrainingWardrobeData } from './AntagTrainingWardrobe';

const fixture: AntagTrainingWardrobeData = {
  department: 'Инженерия',
  program: 'Снаряжение и бой',
  selected: 'default',
  busy: 0,
  roles: [
    { id: 'default', name: 'Учебное тело', department: 'Полигон', order: 0 },
    { id: 'crew:Station Engineer', name: 'Station Engineer', department: 'Инженерия', order: 51 },
  ],
  blocked: [],
};

const setup = (overrides: Partial<AntagTrainingWardrobeData> = {}) => {
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'AntagTrainingWardrobe' }, data: { ...fixture, ...overrides } }));
  return { ...render(<AntagTrainingWardrobe />), topic };
};

test('шкаф отдела выдаёт выбранную должность', () => {
  const ui = setup();
  fireEvent.click(ui.getByText('Station Engineer'));
  const call = ui.topic.mock.calls.find(([message]) => message.type === 'act/set_role');
  expect(JSON.parse(call[0].payload)).toEqual({ role: 'crew:Station Engineer' });
});

test('несовместимые с программой роли названы и не предлагаются', () => {
  const ui = setup({ department: 'Синтетики', roles: [fixture.roles[0]], blocked: ['ИИ', 'Киборг'] });
  expect(ui.getByText(/Ваша программа не работает с ролями: ИИ, Киборг/)).toBeTruthy();
  expect(ui.queryByText('ИИ')).toBeNull();
});

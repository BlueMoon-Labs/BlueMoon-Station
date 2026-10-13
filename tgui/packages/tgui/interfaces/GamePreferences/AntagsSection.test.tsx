import { fireEvent, render, screen } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../../backend';
import { AntagsSection } from './AntagsSection';

test('стиль заданий показывает описание выбранного и отправляет новый стиль', () => {
  const topic = jest.fn();
  (global as any).Byond = { topic };
  const store = createStore(combineReducers({ backend: backendReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({
    config: { interface: 'GamePreferences' },
    data: {
      antag_roles: [{ name: 'traitor', status: 0 }],
      no_antag: false,
      midround_antag: true,
      preferred_chaos_level: 2,
      antag_objective_style: 'quiet',
      antag_objective_styles: [
        { value: 'quiet', name: 'Без убийств', description: 'описание тихого' },
        { value: 'normal', name: 'Как выпадет', description: 'описание обычного' },
        { value: 'violent', name: 'Больше убийств', description: 'описание кровавого' },
      ],
    },
  }));
  render(<AntagsSection />);
  expect(screen.getByText('Стиль заданий')).toBeTruthy();
  expect(screen.getByText('описание тихого')).toBeTruthy();
  expect(screen.getByText('Без убийств')).toBeTruthy();
  fireEvent.click(screen.getByText('Без убийств'));
  fireEvent.click(screen.getByText('Больше убийств'));
  const acts = topic.mock.calls.map(([message]) => message).filter((message) => message.type === 'act/set_antag_objective_style');
  expect(acts.length).toBe(1);
  expect(JSON.parse(acts[0].payload)).toEqual({ value: 'violent' });
});

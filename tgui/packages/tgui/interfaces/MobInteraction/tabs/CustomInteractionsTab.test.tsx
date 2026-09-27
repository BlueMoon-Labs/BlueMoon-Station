import { act, fireEvent, render, screen } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../../../backend';
import { debugReducer } from '../../../debug';
import { CustomInteractionsTab } from './CustomInteractionsTab';

test('switches sound catalogs without resending the options', () => {
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(
    combineReducers({ backend: backendReducer, debug: debugReducer }),
  );
  setGlobalStore(store);
  const data = {
    feminine_moan_sounds: false,
    own_custom_interactions: [],
    custom_interaction_sounds: [],
    custom_moan_sounds: [],
    use_custom_moan_sounds: true,
  };
  store.dispatch(backendUpdate({
    config: { interface: 'MobInteraction', title: 'Взаимодействия' },
    static_data: {
      moan_sound_catalogs: {
        male: [{ key: 'male.ogg', label: 'Мужской звук', group: 'Голос' }],
        female: [{ key: 'female.ogg', label: 'Женский звук', group: 'Голос' }],
      },
    },
    data,
  }));
  const { rerender } = render(<CustomInteractionsTab />);
  expect(screen.queryByText('Мужской звук')).not.toBeNull();
  expect(screen.queryByText('Женский звук')).toBeNull();
  act(() => {
    store.dispatch(backendUpdate({
      data: { ...data, feminine_moan_sounds: true },
    }));
  });
  rerender(<CustomInteractionsTab />);
  expect(screen.queryByText('Мужской звук')).toBeNull();
  fireEvent.click(screen.getByText('Женский звук'));
  expect(JSON.stringify(topic.mock.calls)).toContain('female.ogg');
});

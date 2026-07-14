/**
 * Playlist exports are JSON objects, while favorites and individual playlists
 * are JSON arrays. A playlist object imported as favorites used to reach this
 * interface and crash on array operations such as includes() and spread.
 */
import { render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { Jukebox } from './Jukebox';

const setupStore = (data = {}) => {
  (global as any).Byond = { winset: () => {}, topic: () => {} };
  const store = createStore(
    combineReducers({ backend: backendReducer, debug: debugReducer }),
  );
  setGlobalStore(store);
  store.dispatch(
    backendUpdate({
      config: { interface: 'Jukebox', title: 'Jukebox' },
      data: {
        active: false,
        track_selected: null,
        track_length: null,
        volume: 50,
        is_emagged: false,
        cost_for_play: 1,
        has_access: true,
        repeat: false,
        songs: ['Valid Track'],
        queued_tracks: [],
        favorite_tracks: {
          'Imported playlist': ['Valid Track'],
        },
        playlists: {
          Broken: 'not an array',
          Valid: ['Valid Track'],
        },
        ...data,
      },
    }),
  );
};

describe('Jukebox imported preferences', () => {
  test('renders malformed imported collection shapes without crashing', () => {
    setupStore();
    const { container } = render(<Jukebox />);
    expect(container.innerHTML).toContain('Valid Track');
  });
});

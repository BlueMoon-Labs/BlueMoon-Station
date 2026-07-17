/**
 * Regression test for TelecommsInteraction after the React 19 migration: a
 * filtered-frequency label used a string `style` prop (`style={`color:...`}`),
 * which React 19 throws on. Rendering a valid filtered frequency must not crash.
 */
import { render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { RADIO_CHANNELS } from '../constants';
import { debugReducer } from '../debug';
import { TelecommsInteraction } from './TelecommsInteraction';

const validChannel = RADIO_CHANNELS[0];

const setupStore = (data = {}) => {
  // Window.componentDidMount calls Byond.winset; stub the BYOND bridge.
  (global as any).Byond = { winset: () => {}, topic: () => {} };
  const store = createStore(
    combineReducers({ backend: backendReducer, debug: debugReducer }),
  );
  setGlobalStore(store);
  store.dispatch(
    backendUpdate({
      config: { interface: 'TelecommsInteraction' },
      data: {
        notice: '',
        multitool: false,
        multitool_buf: null,
        links: [],
        freq_listening: [validChannel.freq],
        machine: {
          power: true,
          id: 'NT-1',
          network: 'tcommsat',
          prefab: false,
          hidden: false,
          isrelay: false,
          isbus: false,
        },
        ...data,
      },
    }),
  );
  return store;
};

describe('TelecommsInteraction', () => {
  test('renders a filtered frequency label without crashing on string styles', () => {
    setupStore();
    const { container } = render(<TelecommsInteraction />);
    // The channel label (previously style={`color:...`}) must render.
    expect(container.innerHTML).toContain(validChannel.name);
    const colored = container.querySelector('span[style*="color"]');
    expect(colored).toBeTruthy();
  });

  test('renders without React DOM warnings (LabeledList <tbody>)', () => {
    const spy = jest.spyOn(console, 'error').mockImplementation(() => {});
    setupStore();
    render(<TelecommsInteraction />);
    // No "<table> cannot contain a nested <tr>" / string-style warnings.
    expect(spy).not.toHaveBeenCalled();
    spy.mockRestore();
  });
});

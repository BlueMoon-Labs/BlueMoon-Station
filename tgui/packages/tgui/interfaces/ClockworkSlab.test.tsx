/**
 * Regression test for the Clockwork Slab after the React 19 migration.
 *
 * Inferno accepted string `style` props; React 19 throws
 * ("The `style` prop expects a mapping from style properties to values,
 * not a string."). The recollection tutorial rendered a quickbind slot as
 * `<span style={`color:...`}>`, and the DM backend always sends the quickbind
 * slots with the tutorial open by default, so the window crashed on open.
 */
import { render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { CSTutorial } from './ClockworkSlab';

const setupStore = (data = {}) => {
  const store = createStore(combineReducers({ backend: backendReducer }));
  setGlobalStore(store);
  store.dispatch(
    backendUpdate({
      config: { interface: 'ClockworkSlab' },
      data: {
        recollection_categories: [],
        rec_section: { title: 'Default', info: 'Hello servant!' },
        HONOR_RATVAR: false,
        // Mirrors clockwork_slab.dm ui_data(): a populated slot plus blank
        // ({}) slots, which is what the crashing string-style span rendered.
        rec_binds: [
          { name: 'Spatial Gateway', color: '#b18b25' },
          {},
          {},
        ],
        ...data,
      },
    }),
  );
  return store;
};

describe('ClockworkSlab recollection tutorial', () => {
  test('renders quickbind slots without crashing on string styles', () => {
    setupStore();
    const { container } = render(<CSTutorial />);
    // Bound slot name and the blank-slot placeholder both render.
    expect(container.innerHTML).toContain('Spatial Gateway');
    expect(container.innerHTML).toContain('Нет');
    // The slot color must be applied as a real CSS style, not a raw string.
    const colored = container.querySelector('span[style*="color"]');
    expect(colored).toBeTruthy();
  });
});

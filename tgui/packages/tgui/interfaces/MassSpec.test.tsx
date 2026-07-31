/**
 * Regression test for MassSpec after the React 19 migration: the SVG peak
 * polygons used a string `style` prop (`style={`fill:...`}`), which React 19
 * throws on. Rendering the graph (beaker1Contents present) must not crash.
 */
import { render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { MassSpec } from './MassSpec';

const setupStore = (data = {}) => {
  // Window.componentDidMount calls Byond.winset; stub the BYOND bridge.
  (global as any).Byond = { winset: () => {}, topic: () => {} };
  const store = createStore(
    combineReducers({ backend: backendReducer, debug: debugReducer }),
  );
  setGlobalStore(store);
  store.dispatch(
    backendUpdate({
      config: { interface: 'MassSpec' },
      data: {
        processing: false,
        lowerRange: 0,
        upperRange: 100,
        graphUpperRange: 100,
        graphLowerRange: 0,
        graphIncrement: 20,
        deltaRange: 100,
        eta: 0,
        peakHeight: 50,
        beaker1: true,
        beaker2: true,
        beaker1CurrentVolume: 50,
        beaker2CurrentVolume: 0,
        beaker1MaxVolume: 50,
        beaker2MaxVolume: 50,
        beaker1Contents: [
          { name: 'water', mass: 18, volume: 50, color: '#3344ff' },
        ],
        beaker2Contents: [],
        ...data,
      },
    }),
  );
  return store;
};

describe('MassSpec', () => {
  test('renders the peak graph without crashing on string styles', () => {
    setupStore();
    const { container } = render(<MassSpec />);
    // The reagent peak polygon (previously style={`fill:...`}) must render.
    const polygons = container.querySelectorAll('polygon');
    expect(polygons.length).toBeGreaterThan(0);
  });

  test('renders without React DOM warnings (camelCased SVG attrs)', () => {
    const spy = jest.spyOn(console, 'error').mockImplementation(() => {});
    setupStore();
    render(<MassSpec />);
    // No "Invalid DOM property `stroke-width`" / string-style warnings.
    expect(spy).not.toHaveBeenCalled();
    spy.mockRestore();
  });
});

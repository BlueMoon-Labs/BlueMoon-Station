/**
 * ProgressBar в этой кодовой базе печатает children (ProgressBar.js:20,24,42).
 * Электролизёр передавал текст в несуществующий проп content: тот сваливался
 * в ...rest, через computeBoxProps попадал на div мусорным HTML-атрибутом
 * content="42%", а сама подпись рисовалась запасным путём ProgressBar
 * (toFixed(value * 100)), а не тем, что прислал бэкенд.
 */
import { render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { Electrolyzer } from './Electrolyzer';

const setupStore = (data = {}) => {
  // Window.componentDidMount calls Byond.winset; stub the BYOND bridge.
  (global as any).Byond = { winset: () => {}, topic: () => {} };
  const store = createStore(
    combineReducers({ backend: backendReducer, debug: debugReducer }),
  );
  setGlobalStore(store);
  store.dispatch(
    backendUpdate({
      config: { interface: 'Electrolyzer' },
      data: {
        on: false,
        open: true,
        hasPowercell: true,
        powerLevel: 42,
        ...data,
      },
    }),
  );
  return store;
};

describe('Electrolyzer cell charge', () => {
  test('процент заряда отрисован', () => {
    setupStore({ powerLevel: 42 });
    const { container } = render(<Electrolyzer />);
    expect(container.textContent).toContain('42%');
  });

  test('подпись лежит в разметке шкалы, а не в мусорном атрибуте', () => {
    setupStore({ powerLevel: 42 });
    const { container } = render(<Electrolyzer />);
    const bar = container.querySelector('.ProgressBar');
    expect(bar).not.toBeNull();
    // content не является пропом ProgressBar: он утекает на div атрибутом.
    expect(bar.getAttribute('content')).toBeNull();
    expect(bar.querySelector('.ProgressBar__content').textContent).toBe('42%');
  });

  test('без ячейки показывает прочерк вместо шкалы', () => {
    setupStore({ hasPowercell: false });
    const { container } = render(<Electrolyzer />);
    expect(container.querySelector('.ProgressBar')).toBeNull();
  });
});

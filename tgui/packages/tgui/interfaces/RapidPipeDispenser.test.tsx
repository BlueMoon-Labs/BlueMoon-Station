/**
 * Окно держало собственную таблицу PAINT_COLORS, разошедшуюся с игрой
 * (grey, dark, cyan). Бэкенд шлёт настоящую палитру в data.paint_colors
 * (RPD.dm:316), и с тех пор как цвет решает стыковку труб, сватч обязан
 * показывать именно её.
 */
import { render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { RapidPipeDispenser } from './RapidPipeDispenser';

const setupStore = (data = {}) => {
  // Window.componentDidMount calls Byond.winset; stub the BYOND bridge.
  (global as any).Byond = { winset: () => {}, topic: () => {} };
  const store = createStore(
    combineReducers({ backend: backendReducer, debug: debugReducer }),
  );
  setGlobalStore(store);
  store.dispatch(
    backendUpdate({
      config: { interface: 'RapidPipeDispenser' },
      data: {
        category: 0,
        piping_layer: 3,
        ducting_layer: 1,
        mode: 1 | 2 | 4,
        locked: false,
        selected_color: 'grey',
        paint_colors: {
          grey: '#ffffff',
          green: '#1edd00',
          dark: '#454545',
        },
        preview_rows: [],
        categories: [
          {
            cat_name: 'Pipes',
            recipes: [{ pipe_name: 'Pipe', pipe_index: 1, selected: true }],
          },
        ],
        ...data,
      },
    }),
  );
  return store;
};

describe('RapidPipeDispenser paint palette', () => {
  test('сватчи берут цвета из data.paint_colors', () => {
    setupStore();
    const { container } = render(<RapidPipeDispenser />);
    const swatches = container.querySelectorAll('.ColorBox');
    expect(swatches.length).toBe(3);
    const rendered = Array.from(swatches).map(
      node => (node as HTMLElement).style.backgroundColor,
    );
    // #ffffff, не жёстко зашитый #bbbbbb.
    expect(rendered).toContain('rgb(255, 255, 255)');
    // #454545, не жёстко зашитый #808080.
    expect(rendered).toContain('rgb(69, 69, 69)');
  });

  test('пустая палитра не роняет окно', () => {
    setupStore({ paint_colors: {} });
    const { container } = render(<RapidPipeDispenser />);
    expect(container.querySelectorAll('.ColorBox').length).toBe(0);
  });
});

import { render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { HairStylePicker } from './HairStylePicker';

const labels = {
  tab_hair: 'Причёска',
  tab_facial: 'Борода',
  tab_grad: 'Градиент',
  title: 'Выбор прически',
  apply: 'Применить',
  color: 'Цвет',
  color_requires_spray: 'Нужен краситель',
  search: 'Поиск...',
  favorites: 'Избранное',
  preview: 'Превью',
  portrait: 'Портрет',
  full: 'Всё тело',
  page: 'Страница',
  selected: 'Выбрано:',
  empty: 'Ничего не найдено',
};

const setup = (data: Record<string, unknown>) => {
  (global as any).Byond = { winset: () => {}, topic: jest.fn() };
  const store = createStore(
    combineReducers({ backend: backendReducer, debug: debugReducer }),
  );
  setGlobalStore(store);
  store.dispatch(
    backendUpdate({
      config: { interface: 'HairStylePicker' },
      data: {
        allowed_tabs: ['hair'],
        tab: 'hair',
        dir: 2,
        search: '',
        favorites: [],
        favorites_only: false,
        page: 1,
        pages: 1,
        total: 2,
        names: ['Bob', 'Afro'],
        selected: 'Bob',
        cell_w: 40,
        cell_h: 20,
        cols: 4,
        preview_portraits: {},
        preview_full: null,
        labels,
        ...data,
      },
    }),
  );
  return render(<HairStylePicker />);
};

test('готовые миниатюры видны сразу, недостающие ждут с индикатором', () => {
  const ui = setup({ cells: ['AAAA', null], cells_loading: 1 });
  const images = ui.container.querySelectorAll('img');
  expect(images).toHaveLength(1);
  expect(images[0].getAttribute('src')).toBe('data:image/png;base64,AAAA');
  expect(ui.getByTitle('Afro')).toBeTruthy();
  expect(ui.container.querySelector('.fa-spinner')).toBeTruthy();
});

test('собранная страница без индикатора ожидания', () => {
  const ui = setup({ cells: ['AAAA', 'BBBB'], cells_loading: 0 });
  expect(ui.container.querySelectorAll('img')).toHaveLength(2);
  expect(ui.container.querySelector('.fa-spinner')).toBeNull();
});

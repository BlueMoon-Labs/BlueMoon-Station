import { render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { InsiderPagerContent, InsiderPagerData } from './InsiderPager';

const base: InsiderPagerData = {
  knows: 1,
  events: [
    { ticker: 'AGRO', headline: 'Контракт сорван', effect: -20, positive: 0, eta: 185 },
    { ticker: 'NKMR', headline: 'Новая линейка', effect: 15, positive: 1, eta: 9 },
  ],
  eta_min: 180,
  eta_max: 300,
};

const setup = (data: Partial<InsiderPagerData> = {}) => {
  (global as any).Byond = { winset: () => {}, topic: jest.fn() };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'InsiderPager' }, data: { ...base, ...data } }));
  return render(<InsiderPagerContent />);
};

const text = (container: HTMLElement) => (container.textContent || '').replace(/\u00a0/g, ' ');

test('события очереди с обратным отсчётом мм:сс и сдвигом цены, без кнопок', () => {
  const { container } = setup();
  expect(text(container)).toContain('Контракт сорван');
  expect(text(container)).toContain('через 03:05');
  expect(text(container)).toContain('через 00:09');
  expect(text(container)).toContain('▼ -20%');
  expect(text(container)).toContain('▲ +15%');
  expect(text(container)).toContain('через 03:00-05:00 после постановки');
  expect(container.querySelectorAll('.Button')).toHaveLength(0);
});

test('пустая очередь', () => {
  const { container } = setup({ events: [] });
  expect(text(container)).toContain('Пейджер молчит');
});

test('постороннему - пустой экран без событий и подсказок', () => {
  const { container } = setup({ knows: 0, events: [], eta_min: undefined, eta_max: undefined });
  expect(text(container)).toContain('Новых сообщений нет.');
  expect(container.textContent).not.toContain('AGRO');
  expect(container.textContent).not.toContain('инсайд');
});

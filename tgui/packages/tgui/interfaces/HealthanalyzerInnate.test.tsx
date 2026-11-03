import { fireEvent, render, screen } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { Healthanalyzer } from './Healthanalyzer';

const feature = {
  id: 'naga_tail',
  name: 'Опорный хвост',
  tooltip: 'У пациента отсутствуют ноги. Операции на хвосте необходимо начинать в области паха.',
};

const sample = {
  scanTime: '12:00:00', health: 100, dead: 0, unknown: 0, robotic: 0,
  temperatureC: 37, temperatureF: 98.6, species: 'Human', sections: [],
  damageLevels: { oxy: 0, tox: 0, burn: 0, brute: 0 }, innateFeatures: [feature],
};

const setup = (scan: Record<string, unknown> = sample) => {
  (global as any).Byond = { winset: () => {}, topic: jest.fn() };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'Healthanalyzer' }, data: { scan, advanced: 1, printing: 0, scanNumber: 1 } }));
  const ui = render(<Healthanalyzer />);
  const update = (changes: Record<string, unknown>) => {
    store.dispatch(backendUpdate({ data: { scan: { ...scan, ...changes } } }));
    ui.rerender(<Healthanalyzer />);
  };
  return { ...ui, update };
};

test('наведение показывает медицинские данные выбранной особенности', () => {
  const second = { id: 'second', name: 'Вторая особенность', tooltip: 'Другая медицинская рекомендация.' };
  setup({ ...sample, innateFeatures: [feature, second] });
  expect(screen.queryByRole('tooltip')).toBeNull();
  fireEvent.mouseEnter(screen.getByText(feature.name));
  expect(screen.getByRole('tooltip').textContent).toBe(feature.tooltip);
  fireEvent.mouseLeave(screen.getByText(feature.name));
  expect(screen.queryByRole('tooltip')).toBeNull();
  fireEvent.mouseEnter(screen.getByText(second.name));
  expect(screen.getAllByRole('tooltip').length).toBe(1);
  expect(screen.getByRole('tooltip').textContent).toBe(second.tooltip);
});

test('Escape закрывает медицинскую подсказку до обработки закрытия окна', () => {
  setup();
  fireEvent.mouseEnter(screen.getByText(feature.name));
  const outerHandler = jest.fn();
  window.addEventListener('keydown', outerHandler);
  try {
    fireEvent.keyDown(document, { key: 'Escape' });
    expect(screen.queryByRole('tooltip')).toBeNull();
    expect(outerHandler).not.toHaveBeenCalled();
  } finally {
    window.removeEventListener('keydown', outerHandler);
  }
});

test('обновление скана удаляет открытую подсказку исчезнувшей особенности', () => {
  const { update } = setup();
  fireEvent.mouseEnter(screen.getByText(feature.name));
  update({ innateFeatures: [] });
  expect(screen.queryByRole('tooltip')).toBeNull();
  expect(screen.queryByText(feature.name)).toBeNull();
  expect(screen.queryByText('Врожденное:')).toBeNull();
});

test.each([[], undefined])('строка врождённых особенностей скрыта при пустом списке %j', (innateFeatures) => {
  setup({ ...sample, innateFeatures });
  expect(screen.queryByText('Врожденное:')).toBeNull();
});

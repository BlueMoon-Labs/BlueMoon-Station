import { fireEvent, render, screen, within } from '@testing-library/react';
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

test('врождённые особенности находятся внизу первого блока', () => {
  const { container } = setup();
  const first = container.querySelector('.Section')!;
  expect(within(first as HTMLElement).getByText('Опорный хвост')).toBeTruthy();
  const content = first.querySelector('.Section__content')!;
  expect(content.lastElementChild!.textContent).toContain('Врожденное: Опорный хвост');
  expect(screen.getByText('Врожденное:').classList.contains('color-label')).toBe(true);
});

test('медицинская подсказка приходит из данных особенности и находится рядом с якорем', () => {
  setup();
  expect(screen.queryByRole('tooltip')).toBeNull();
  const label = screen.getByText(feature.name);
  fireEvent.mouseEnter(label);
  const tip = screen.getByRole('tooltip');
  expect(tip.textContent).toBe(feature.tooltip);
  expect(tip.closest('.Healthanalyzer__innateFeature')).toBe(label.closest('.Healthanalyzer__innateFeature'));
  expect(label.getAttribute('title')).toBeNull();
  fireEvent.mouseLeave(label.closest('.Healthanalyzer__innateFeature')!);
  expect(screen.queryByRole('tooltip')).toBeNull();
});

test('пустой список явно показывает отсутствие особенностей', () => {
  setup({ ...sample, innateFeatures: [] });
  expect(screen.getByText('Врожденное:').parentElement!.textContent).toBe('Врожденное: Нет');
  expect(screen.queryByRole('tooltip')).toBeNull();
});

test('старый или химический отчёт без поля не показывает ложное отсутствие особенностей', () => {
  setup({ ...sample, chemicalOnly: 1, innateFeatures: undefined });
  expect(screen.queryByText(/Врожденное:/)).toBeNull();
});

test('несколько особенностей получают независимые подсказки', () => {
  setup({ ...sample, innateFeatures: [feature, { id: 'second', name: 'Вторая особенность', tooltip: 'Другая медицинская рекомендация.' }] });
  fireEvent.mouseEnter(screen.getByText(feature.name));
  expect(screen.getByRole('tooltip').textContent).toBe(feature.tooltip);
  fireEvent.mouseLeave(screen.getByText(feature.name).closest('.Healthanalyzer__innateFeature')!);
  fireEvent.mouseEnter(screen.getByText('Вторая особенность'));
  expect(screen.getAllByRole('tooltip').length).toBe(1);
  expect(screen.getByRole('tooltip').textContent).toBe('Другая медицинская рекомендация.');
});

test('особенность без медицинского текста не создаёт пустую подсказку', () => {
  setup({ ...sample, innateFeatures: [{ id: 'plain', name: 'Без подсказки' }] });
  fireEvent.mouseEnter(screen.getByText('Без подсказки'));
  expect(screen.queryByRole('tooltip')).toBeNull();
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
  expect(screen.getByText('Врожденное:').parentElement!.textContent).toBe('Врожденное: Нет');
});

test('текст подсказки не интерпретируется как HTML', () => {
  const text = '<img src=x onerror=alert(1)> Операции в паху.';
  const { container } = setup({ ...sample, innateFeatures: [{ ...feature, tooltip: text }] });
  fireEvent.mouseEnter(screen.getByText(feature.name));
  expect(screen.getByRole('tooltip').textContent).toBe(text);
  expect(container.querySelector('img')).toBeNull();
});

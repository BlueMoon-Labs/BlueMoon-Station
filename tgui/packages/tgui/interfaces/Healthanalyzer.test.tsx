import { fireEvent, render, screen } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { Healthanalyzer } from './Healthanalyzer';

const scan = { scanTime: '12:00:00', health: 100, dead: 0, unknown: 0, robotic: 0, sections: [] };

const setupStore = (data = {}) => {
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'Healthanalyzer' }, data: { advanced: 0, printing: 0, scanNumber: 1, scan, ...data } }));
  return topic;
};

describe('Healthanalyzer', () => {
  test('кнопка выписки шлёт действие econ_discharge', () => {
    const topic = setupStore({ canDischarge: 1 });
    render(<Healthanalyzer />);
    fireEvent.click(screen.getByText('Выписать пациента'));
    expect(topic.mock.calls.map(([message]) => message.type)).toContain('act/econ_discharge');
  });

  test('без готовности к выписке кнопки нет', () => {
    setupStore({ canDischarge: 0 });
    render(<Healthanalyzer />);
    expect(screen.queryByText('Выписать пациента')).toBeNull();
  });
});

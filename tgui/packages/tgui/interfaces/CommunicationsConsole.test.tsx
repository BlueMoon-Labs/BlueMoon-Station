import { fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { CommunicationsConsole } from './CommunicationsConsole';

const setup = (shuttles) => {
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(
    backendUpdate({
      config: { interface: 'CommunicationsConsole' },
      data: { authenticated: 1, hasConnection: 1, page: 'buying_shuttle', budget: 1000, shuttles },
    }),
  );
  return { ...render(<CommunicationsConsole />), topic };
};

const text = (container: HTMLElement) => (container.textContent || '').replace(/\u00a0/g, ' ');

describe('CommunicationsConsole: покупка шаттла', () => {
  test('шаттл с отрицательной ценой показывает доплату NT, а не минус', () => {
    const { container, getByText, topic } = setup([
      { name: 'Метеор', description: 'Дешёвый шаттл', creditCost: -5000, ref: 'meteor' },
      { name: 'Люкс', description: 'Дорогой шаттл', creditCost: 3000, ref: 'lux' },
    ]);
    const content = text(container);
    expect(content).not.toMatch(/-5\D?000/);
    const payout = getByText(/Доплата NT: 5\D?000 кредитов/);
    expect(payout.closest('.Button')?.className).not.toContain('Button--disabled');
    fireEvent.click(payout);
    const sent = topic.mock.calls.map(([message]) => message).filter((message) => message.type === 'act/purchaseShuttle');
    expect(sent.map((message) => JSON.parse(message.payload))).toEqual([{ shuttle: 'meteor' }]);
    expect(getByText(/3\D?000 кредитов/).closest('.Button')?.className).toContain('Button--disabled');
  });
});

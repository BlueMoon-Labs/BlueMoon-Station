/**
 * Менторхелп открывает общую панель обращений: она обязана стартовать на
 * вкладке менторов, иначе вопрос по механикам уходит админам.
 */
import { render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { PlayerTicketPanel } from './PlayerTicketPanel';

const setupStore = (data = {}) => {
  (global as any).Byond = { winset: () => {}, topic: () => {} };
  const store = createStore(
    combineReducers({ backend: backendReducer, debug: debugReducer }),
  );
  setGlobalStore(store);
  store.dispatch(
    backendUpdate({
      config: { interface: 'PlayerTicketPanel' },
      data: { has_ticket: false, has_mentor_ticket: false, ...data },
    }),
  );
  return store;
};

describe('PlayerTicketPanel', () => {
  test('из менторхелпа открывается вкладка менторов', () => {
    setupStore({ initial_tab: 'mentor' });
    const { container } = render(<PlayerTicketPanel />);
    expect(container.textContent).toContain('Опишите ваш вопрос подробно');
    expect(container.textContent).not.toContain('Укажите имена причастных');
  });

  test('из админхелпа открывается вкладка администрации', () => {
    setupStore({ initial_tab: 'admin' });
    const { container } = render(<PlayerTicketPanel />);
    expect(container.textContent).toContain('Укажите имена причастных');
  });

  test('без начальной вкладки открывается администрация', () => {
    setupStore();
    const { container } = render(<PlayerTicketPanel />);
    expect(container.textContent).toContain('Укажите имена причастных');
  });
});

import { render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { CreditsTransferNote } from './NtosMessenger';

const setup = (data: Record<string, unknown>) => {
  (global as any).Byond = { winset: () => {}, topic: jest.fn() };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'NtosMessenger' }, data }));
  return render(<CreditsTransferNote />);
};

describe('CreditsTransferNote', () => {
  it('показывает лимит и кулдаун перевода из данных сервера', () => {
    const { container } = setup({ credits_transfer_max: 50000, credits_transfer_cooldown: 5 });
    const text = container.textContent || '';
    expect(text).toContain('до 50000 кр. за раз');
    expect(text).toContain('не чаще раза в 5 с');
    expect(text).toContain('Только с личного счёта на личный');
  });
});

import { fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { CourtFee } from './BrigAssistantConsole';

let now = Date.now();

const backend = {
  has_id: 1,
  scanning: 0,
  id_name: 'Подсудимый',
  id_balance: 500,
  can_court_fee: 1,
  court_fee_max: 3000,
  fines: [],
  wanted: [],
  remove: [],
};

const setup = (data: Record<string, unknown>) => {
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  const update = (patch: Record<string, unknown>) => store.dispatch(backendUpdate({ config: { interface: 'BrigAssistantConsole' }, data: { ...backend, ...data, ...patch } }));
  update({});
  return { ...render(<CourtFee />), topic, update };
};

const sent = (topic: jest.Mock, action: string) => topic.mock.calls.map(([message]) => message).filter((message) => message.type === `act/${action}`).map((message) => JSON.parse(message.payload));

test('магистрат назначает пошлину владельцу вставленной карты', () => {
  const ui = setup({});
  fireEvent.click(ui.getByText('Назначить'));
  expect(sent(ui.topic, 'court_fee')).toEqual([{ amount: 100, reason: '' }]);
});

test('сумма не выше потолка пошлины', () => {
  const ui = setup({ court_fee_max: 50 });
  fireEvent.click(ui.getByText('Назначить'));
  expect(sent(ui.topic, 'court_fee')).toEqual([{ amount: 50, reason: '' }]);
});

test('сумма и основание сбрасываются при смене карты', () => {
  const ui = setup({});
  const amountInput = ui.container.querySelectorAll('input')[0];
  fireEvent.focus(amountInput);
  fireEvent.input(amountInput, { target: { value: '700' } });
  fireEvent.blur(amountInput);
  fireEvent.click(ui.getByText('Назначить'));
  expect(sent(ui.topic, 'court_fee')).toEqual([{ amount: 700, reason: '' }]);
  ui.update({ id_name: 'Другой' });
  ui.rerender(<CourtFee />);
  fireEvent.click(ui.getByText('Назначить'));
  expect(sent(ui.topic, 'court_fee')).toEqual([{ amount: 700, reason: '' }, { amount: 100, reason: '' }]);
});

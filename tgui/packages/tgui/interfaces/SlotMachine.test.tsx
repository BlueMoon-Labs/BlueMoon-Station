import { fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { SlotMachine } from './SlotMachine';

const reel = { symbols: ['seven', 'cherry', 'star'], stopped: 1 };

const base = {
  money: 120,
  prize_bank: 900,
  house_edge: 10,
  jackpot_share: 5,
  bank_share: 85,
  deposit_max: 1000,
  prize_big: 440,
  prize_small: 146,
  jackpot_sevens: 4,
  plays: 80,
  jackpots: 1,
  balance: 50,
  working: 0,
  bet_amount: 5,
  result_message: '',
  result_type: '',
  bonus_multiplier: 1,
  bonus_active: 0,
  win_streak: 0,
  session_winnings: 0,
  auto_spin: 0,
  auto_spin_remaining: 0,
  free_spins_remaining: 0,
  loss_streak: 0,
  reels: [reel, reel, reel, reel, reel],
  spin_history: [],
  gamble_available: 0,
  gamble_amount: 0,
  near_miss: 0,
  near_miss_message: '',
  show_confetti: 0,
  active_lines: 1,
  winning_line: 0,
};

const setup = (data = {}) => {
  let now = Date.now();
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'SlotMachine' }, data: { ...base, ...data } }));
  const ui = render(<SlotMachine />);
  fireEvent.click(ui.getByText('▶ Нажмите, чтобы играть ◀'));
  return { ...ui, topic };
};

const sent = (topic: jest.Mock, action: string) =>
  topic.mock.calls
    .map(([message]) => message)
    .filter((message) => message.type === `act/${action}`)
    .map((message) => (message.payload ? JSON.parse(message.payload) : {}));

const text = (container: HTMLElement) => (container.textContent || '').replace(/\u00a0/g, ' ');

describe('SlotMachine', () => {
  test('доли ставки, банк и таблица выигрышей из данных автомата', () => {
    const { container } = setup();
    const content = text(container);
    expect(content).toContain('Банк выигрышей: 900 кр.');
    expect(content).toContain('10% забирает NT, 5% идёт в джекпот, 85% - в банк');
    expect(content).toContain('Выигрыш не больше банка');
    expect(content).toContain('4× 💰/🃏 в центре');
    expect(content).toContain('440 кр.');
    expect(content).toContain('146 кр.');
  });

  test('внесение с карты шлёт card_deposit с суммой, вращение - spin', () => {
    const { getByText, topic } = setup();
    fireEvent.click(getByText('100'));
    fireEvent.click(getByText('КРУТИТЬ 5 кр.'));
    expect(sent(topic, 'card_deposit')).toEqual([{ amount: 100 }]);
    expect(sent(topic, 'spin')).toHaveLength(1);
  });

  test('пока барабаны крутятся, внести с карты и сменить ставку нельзя', () => {
    const { getByText, getAllByText } = setup({ working: 1 });
    expect(getByText('500').closest('.Button')?.className).toContain('Button--disabled');
    expect(getAllByText(/^25 кр\./)[0].closest('.Button')?.className).toContain('Button--disabled');
  });

  test('смена ставки шлёт set_bet с суммой из списка', () => {
    const { getAllByText, topic } = setup();
    fireEvent.click(getAllByText(/^25 кр\./)[0]);
    expect(sent(topic, 'set_bet')).toEqual([{ amount: 25 }]);
  });
});

import { act, fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../../backend';
import { debugReducer } from '../../debug';
import { SessionStatus } from './SessionStatus';
import { CombatState, CombatTurn } from './types';

const setup = (turn: CombatTurn) => {
  (global as any).Byond = { winset: () => {}, topic: jest.fn() };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  const combat: CombatState = { node: 'A', node_name: 'Сервер', self: null, programs: [], targets: [], incoming: [], turn };
  store.dispatch(backendUpdate({ config: { interface: 'NetrunTerminal' }, data: {
    combat, entity: null, locked: 0, breach: null, operations: [], security: null,
  } }));
  const onCombat = jest.fn();
  const panel = render(<SessionStatus onCombat={onCombat} onBreach={jest.fn()} />);
  return { panel, onCombat, update: (value: CombatState | null) => act(() => store.dispatch(backendUpdate({ data: { combat: value } }))) };
};

const turn: CombatTurn = {
  id: 'battle:1', round: 1, actor_ref: 'self', actor_name: 'Alice', your_turn: true,
  ap: 2, max_ap: 3, remaining: 10, can_pass: true, participating: true,
};

test('a quiet own turn remains discoverable outside the combat page without firing a game action', () => {
  const { panel, onCombat } = setup(turn);
  fireEvent.click(panel.getByRole('button', { name: /Ваш ход · 2\/3 ОД/ }));
  expect(onCombat).toHaveBeenCalledTimes(1);
  expect((global as any).Byond.topic).not.toHaveBeenCalled();
});

test('the same reserved status slot shows waiting and clears after battle termination', () => {
  const { panel, update } = setup(turn);
  const slot = panel.container.querySelector('[data-net-layout="status"]');
  update({ node: 'A', node_name: 'Сервер', self: null, programs: [], targets: [], turn: {
    ...turn, id: 'battle:2', actor_name: 'ICE', your_turn: false, ap: 0,
  } });
  expect(panel.getByRole('button', { name: /Ожидание хода · ICE/ })).toBeTruthy();
  expect(panel.container.querySelector('[data-net-layout="status"]')).toBe(slot);
  update(null);
  expect(panel.queryByRole('button', { name: /Открыть бой/ })).toBeNull();
  expect(panel.getByRole('status').textContent).toContain('Выберите узел');
});

test('a spectator sees the ongoing encounter without being described as a waiting participant', () => {
  const { panel, onCombat } = setup({ ...turn, your_turn: false, participating: false, can_join: true });
  fireEvent.click(panel.getByRole('button', { name: /Бой в узле · ход Alice/ }));
  expect(onCombat).toHaveBeenCalledTimes(1);
  expect(panel.queryByText(/Ожидание хода/)).toBeNull();
});


test('an unthreatened spectator can join directly from another workspace using the stable encounter identity', () => {
  const { panel, update } = setup({ ...turn, id: 'battle:3', join_id: 'battle',
    remaining: 0, your_turn: false, participating: false, can_join: true });
  fireEvent.click(panel.getByText('Вступить в бой'));
  const topic = (global as any).Byond.topic;
  const joins = () => topic.mock.calls.filter((call) => call[0]?.type === 'act/combat_join');
  expect(joins()).toHaveLength(1);
  expect(JSON.parse(joins()[0][0].payload)).toEqual({ turn_id: 'battle' });
  update({ node: 'A', node_name: 'Сервер', self: null, programs: [], targets: [], incoming: [], turn: {
    ...turn, join_id: 'battle', participating: false, your_turn: false, can_join: false,
  } });
  fireEvent.click(panel.getByText('Вступить в бой'));
  expect(joins()).toHaveLength(1);
  update({ node: 'A', node_name: 'Сервер', self: null, programs: [], targets: [], incoming: [], turn });
  expect(panel.queryByText('Вступить в бой')).toBeNull();
});

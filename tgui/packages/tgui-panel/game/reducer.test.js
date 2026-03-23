import { connectionLost, connectionRestored } from './actions';
import { gameReducer } from './reducer';

describe('gameReducer', () => {
  const initialState = {
    roundId: null,
    roundTime: null,
    roundRestartedAt: null,
    connectionLostAt: null,
  };

  test('initial state has all timestamps null', () => {
    const state = gameReducer(undefined, { type: '@@INIT' });

    expect(state.roundRestartedAt).toBeNull();
    expect(state.connectionLostAt).toBeNull();
  });

  test('roundrestart sets roundRestartedAt from meta.now', () => {
    const state = gameReducer(initialState, {
      type: 'roundrestart',
      meta: { now: 1700000000 },
    });

    expect(state.roundRestartedAt).toBe(1700000000);
  });

  test('connectionLost sets connectionLostAt from meta.now', () => {
    const action = connectionLost();
    action.meta = { now: 1234567 };

    const state = gameReducer(initialState, action);

    expect(state.connectionLostAt).toBe(1234567);
  });

  test('connectionRestored clears connectionLostAt', () => {
    const lostState = { ...initialState, connectionLostAt: 1234567 };

    const state = gameReducer(lostState, connectionRestored());

    expect(state.connectionLostAt).toBeNull();
  });

  test('full cycle: connect -> lose -> restore', () => {
    let state = initialState;

    // Lose connection
    const lostAction = connectionLost();
    lostAction.meta = { now: 100 };
    state = gameReducer(state, lostAction);
    expect(state.connectionLostAt).toBe(100);

    // Restore connection
    state = gameReducer(state, connectionRestored());
    expect(state.connectionLostAt).toBeNull();
  });

  test('multiple restarts update timestamp each time', () => {
    let state = initialState;

    state = gameReducer(state, {
      type: 'roundrestart',
      meta: { now: 100 },
    });
    expect(state.roundRestartedAt).toBe(100);

    state = gameReducer(state, {
      type: 'roundrestart',
      meta: { now: 200 },
    });
    expect(state.roundRestartedAt).toBe(200);
  });

  test('roundrestart does not affect connectionLostAt', () => {
    const lostState = { ...initialState, connectionLostAt: 999 };

    const state = gameReducer(lostState, {
      type: 'roundrestart',
      meta: { now: 100 },
    });

    expect(state.connectionLostAt).toBe(999);
    expect(state.roundRestartedAt).toBe(100);
  });

  test('returns state unchanged for unknown action', () => {
    const state = { ...initialState, roundRestartedAt: 42 };
    expect(gameReducer(state, { type: 'UNKNOWN' })).toBe(state);
  });
});

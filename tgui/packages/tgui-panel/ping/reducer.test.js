import { scale } from 'common/math';

import { pingFail, pingSuccess } from './actions';
import {
  PING_ROUNDTRIP_BEST,
  PING_ROUNDTRIP_WORST,
} from './constants';
import { pingReducer } from './reducer';

// Helper to create a pingSuccess action with a given roundtrip
const makePingSuccess = (roundtrip) => {
  const sentAt = 1000000;
  const now = sentAt + roundtrip * 2; // roundtrip = (now - sentAt) * 0.5
  jest.spyOn(Date, 'now').mockReturnValue(now);
  return pingSuccess({ id: 1, sentAt });
};

describe('pingReducer', () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('pingSuccess', () => {
    test('stores roundtrip and resets failCount', () => {
      const action = makePingSuccess(100);
      const state = pingReducer({}, action);

      expect(state.roundtrip).toBe(100);
      expect(state.failCount).toBe(0);
    });

    test('first ping uses roundtrip as initial average', () => {
      // No previous roundtripAvg -> prevRoundtrip = roundtrip
      const action = makePingSuccess(120);
      const state = pingReducer({}, action);

      // EMA: 120 * 0.4 + 120 * 0.6 = 120
      expect(state.roundtripAvg).toBe(120);
    });

    test('EMA weights: 0.4 previous + 0.6 current', () => {
      const prev = { roundtripAvg: 100 };
      const action = makePingSuccess(200);
      const state = pingReducer(prev, action);

      // EMA: round(100 * 0.4 + 200 * 0.6) = round(40 + 120) = 160
      expect(state.roundtripAvg).toBe(160);
    });

    test('EMA convergence over multiple pings', () => {
      let state = {};

      // Send several pings at 80ms — avg should converge toward 80
      for (let i = 0; i < 10; i++) {
        const action = makePingSuccess(80);
        state = pingReducer(state, action);
      }

      expect(state.roundtripAvg).toBe(80);
    });

    test('perfect ping (≤ BEST) gives networkQuality ~1.0', () => {
      const action = makePingSuccess(PING_ROUNDTRIP_BEST);
      const state = pingReducer({}, action);

      // scale(50, 50, 200) = 0 -> quality = 1 - 0 = 1
      expect(state.networkQuality).toBeCloseTo(1.0);
    });

    test('very fast ping (< BEST) clamps networkQuality to 1.0', () => {
      const action = makePingSuccess(10); // well below BEST (50)
      const state = pingReducer({}, action);

      // scale(10, 50, 200) = -0.267 -> unclamped: 1.267
      // Must be clamped to 1.0
      expect(state.networkQuality).toBe(1);
    });

    test('terrible ping (≥ WORST) gives networkQuality ~0.0', () => {
      const action = makePingSuccess(PING_ROUNDTRIP_WORST);
      const state = pingReducer({}, action);

      // scale(200, 50, 200) = 1 -> quality = 1 - 1 = 0
      expect(state.networkQuality).toBeCloseTo(0.0);
    });

    test('mid-range ping gives proportional quality', () => {
      const mid = (PING_ROUNDTRIP_BEST + PING_ROUNDTRIP_WORST) / 2; // 125
      const action = makePingSuccess(mid);
      const state = pingReducer({}, action);

      const expected = 1 - scale(mid, PING_ROUNDTRIP_BEST, PING_ROUNDTRIP_WORST);
      expect(state.networkQuality).toBeCloseTo(expected);
    });

    test('resets failCount from non-zero', () => {
      const prev = { failCount: 5, networkQuality: 0.2 };
      const action = makePingSuccess(100);
      const state = pingReducer(prev, action);

      expect(state.failCount).toBe(0);
    });
  });

  describe('pingFail', () => {
    test('increments failCount', () => {
      const state = pingReducer({}, pingFail());
      expect(state.failCount).toBe(1);
    });

    test('degrades networkQuality by failCount / MAX_FAILS', () => {
      const prev = { networkQuality: 1.0, failCount: 0 };
      const state = pingReducer(prev, pingFail());

      // quality = clamp01(1.0 - 0/3) = 1.0 (first fail doesn't degrade)
      expect(state.networkQuality).toBe(1.0);
      expect(state.failCount).toBe(1);
    });

    test('progressive degradation with multiple failures', () => {
      let state = { networkQuality: 1.0, failCount: 0 };

      state = pingReducer(state, pingFail()); // fail=0->1, quality=1.0-0/3=1.0
      expect(state.networkQuality).toBeCloseTo(1.0);

      state = pingReducer(state, pingFail()); // fail=1->2, quality=1.0-1/3=0.667
      expect(state.networkQuality).toBeCloseTo(0.667, 2);

      state = pingReducer(state, pingFail()); // fail=2->3, quality=0.667-2/3=0.0
      expect(state.networkQuality).toBeCloseTo(0.0, 1);
    });

    test('networkQuality clamps to 0 and does not go negative', () => {
      let state = { networkQuality: 0.1, failCount: 2 };
      state = pingReducer(state, pingFail());

      // quality = clamp01(0.1 - 2/3) = clamp01(-0.567) = 0
      expect(state.networkQuality).toBe(0);
    });

    test('clears roundtrip data after exceeding MAX_FAILS', () => {
      let state = { networkQuality: 1.0, failCount: 0, roundtrip: 100, roundtripAvg: 100 };

      // Fail 5 times — check uses previous failCount, so need failCount=4
      // before dispatch (i.e. 5th dispatch) for `4 > 3` to be true
      for (let i = 0; i < 5; i++) {
        state = pingReducer(state, pingFail());
      }

      expect(state.failCount).toBe(5);
      expect(state.roundtrip).toBeUndefined();
      expect(state.roundtripAvg).toBeUndefined();
    });

    test('does not clear roundtrip at exactly MAX_FAILS', () => {
      let state = { networkQuality: 1.0, failCount: 0, roundtrip: 100, roundtripAvg: 100 };

      // Fail exactly 3 times (= MAX_FAILS)
      for (let i = 0; i < 3; i++) {
        state = pingReducer(state, pingFail());
      }

      // failCount is now 3, but check is `failCount > MAX_FAILS` (not >=)
      expect(state.failCount).toBe(3);
      expect(state.roundtrip).toBe(100);
    });
  });

  test('returns state unchanged for unknown action', () => {
    const state = { networkQuality: 0.5 };
    expect(pingReducer(state, { type: 'UNKNOWN' })).toBe(state);
  });
});

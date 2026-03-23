import { pingFail, pingReply, pingSuccess } from './actions';

describe('pingSuccess', () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

  test('calculates roundtrip as half of round-trip time', () => {
    const now = 1000500;
    jest.spyOn(Date, 'now').mockReturnValue(now);

    const action = pingSuccess({ id: 7, sentAt: 1000000 });

    // roundtrip = (1000500 - 1000000) * 0.5 = 250
    expect(action.payload.roundtrip).toBe(250);
  });

  test('preserves ping id as lastId', () => {
    jest.spyOn(Date, 'now').mockReturnValue(2000);

    const action = pingSuccess({ id: 42, sentAt: 1000 });

    expect(action.payload.lastId).toBe(42);
  });

  test('includes current time in meta.now', () => {
    const now = 9999;
    jest.spyOn(Date, 'now').mockReturnValue(now);

    const action = pingSuccess({ id: 1, sentAt: 9000 });

    expect(action.meta.now).toBe(now);
  });

  test('zero latency when sentAt equals now', () => {
    jest.spyOn(Date, 'now').mockReturnValue(5000);

    const action = pingSuccess({ id: 1, sentAt: 5000 });

    expect(action.payload.roundtrip).toBe(0);
  });

  test('has correct action type', () => {
    jest.spyOn(Date, 'now').mockReturnValue(1000);
    const action = pingSuccess({ id: 1, sentAt: 500 });
    expect(action.type).toBe('ping/success');
  });
});

describe('pingFail', () => {
  test('has correct action type', () => {
    expect(pingFail().type).toBe('ping/fail');
  });
});

describe('pingReply', () => {
  test('has correct action type', () => {
    expect(pingReply().type).toBe('ping/reply');
  });
});

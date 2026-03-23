import { connectionsMatch } from './telemetry.utils';

describe('connectionsMatch', () => {
  const baseConn = {
    ckey: 'player1',
    address: '192.168.1.1',
    computer_id: 'abc123',
  };

  test('returns true when all fields match', () => {
    const a = { ...baseConn };
    const b = { ...baseConn };
    expect(connectionsMatch(a, b)).toBe(true);
  });

  test('returns false when ckey differs', () => {
    const a = { ...baseConn };
    const b = { ...baseConn, ckey: 'player2' };
    expect(connectionsMatch(a, b)).toBe(false);
  });

  test('returns false when address differs', () => {
    const a = { ...baseConn };
    const b = { ...baseConn, address: '10.0.0.1' };
    expect(connectionsMatch(a, b)).toBe(false);
  });

  test('returns false when computer_id differs', () => {
    const a = { ...baseConn };
    const b = { ...baseConn, computer_id: 'xyz789' };
    expect(connectionsMatch(a, b)).toBe(false);
  });

  test('returns false when only one field matches', () => {
    const a = { ...baseConn };
    const b = {
      ckey: 'player1',
      address: '10.0.0.1',
      computer_id: 'xyz789',
    };
    expect(connectionsMatch(a, b)).toBe(false);
  });

  test('exact same object reference returns true', () => {
    expect(connectionsMatch(baseConn, baseConn)).toBe(true);
  });
});

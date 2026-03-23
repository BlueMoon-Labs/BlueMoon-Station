import { emotesReducer } from './reducer';

describe('emotesReducer', () => {
  test('initial state has visible=false and empty list', () => {
    const state = emotesReducer(undefined, { type: '@@INIT' });

    expect(state.visible).toBe(false);
    expect(state.list).toEqual({});
  });

  test('emotes/toggle toggles visible', () => {
    const state = emotesReducer(
      { visible: false, list: {} },
      { type: 'emotes/toggle' },
    );
    expect(state.visible).toBe(true);
  });

  test('double toggle returns to false', () => {
    let state = { visible: false, list: {} };
    state = emotesReducer(state, { type: 'emotes/toggle' });
    state = emotesReducer(state, { type: 'emotes/toggle' });
    expect(state.visible).toBe(false);
  });

  test('emotes/setList replaces list with payload', () => {
    const emoteList = { wave: { name: 'wave' }, smile: { name: 'smile' } };
    const state = emotesReducer(
      { visible: false, list: {} },
      { type: 'emotes/setList', payload: emoteList },
    );

    expect(state.list).toEqual(emoteList);
  });

  test('setList does not affect visible', () => {
    const state = emotesReducer(
      { visible: true, list: {} },
      { type: 'emotes/setList', payload: { test: 1 } },
    );
    expect(state.visible).toBe(true);
  });

  test('returns state unchanged for unknown action', () => {
    const state = { visible: true, list: { a: 1 } };
    expect(emotesReducer(state, { type: 'UNKNOWN' })).toBe(state);
  });
});

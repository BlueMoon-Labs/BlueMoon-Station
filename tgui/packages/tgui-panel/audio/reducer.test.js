import { audioReducer } from './reducer';

describe('audioReducer', () => {
  const initialState = {
    visible: false,
    playing: false,
    track: null,
  };

  test('initial state', () => {
    const state = audioReducer(undefined, { type: '@@INIT' });

    expect(state.visible).toBe(false);
    expect(state.playing).toBe(false);
    expect(state.track).toBeNull();
  });

  test('audio/playing sets visible and playing to true', () => {
    const state = audioReducer(initialState, { type: 'audio/playing' });

    expect(state.visible).toBe(true);
    expect(state.playing).toBe(true);
  });

  test('audio/stopped sets visible and playing to false', () => {
    const playingState = { ...initialState, visible: true, playing: true };
    const state = audioReducer(playingState, { type: 'audio/stopped' });

    expect(state.visible).toBe(false);
    expect(state.playing).toBe(false);
  });

  test('audio/playMusic stores payload as meta', () => {
    const meta = { title: 'Song', artist: 'Artist', url: 'http://x.mp3' };
    const state = audioReducer(initialState, {
      type: 'audio/playMusic',
      payload: meta,
    });

    expect(state.meta).toEqual(meta);
  });

  test('audio/stopMusic clears visible, playing, and meta', () => {
    const activeState = {
      visible: true,
      playing: true,
      meta: { title: 'Song' },
    };
    const state = audioReducer(activeState, { type: 'audio/stopMusic' });

    expect(state.visible).toBe(false);
    expect(state.playing).toBe(false);
    expect(state.meta).toBeNull();
  });

  test('audio/toggle toggles visible', () => {
    const state = audioReducer(initialState, { type: 'audio/toggle' });
    expect(state.visible).toBe(true);
  });

  test('double toggle returns to original', () => {
    let state = audioReducer(initialState, { type: 'audio/toggle' });
    expect(state.visible).toBe(true);

    state = audioReducer(state, { type: 'audio/toggle' });
    expect(state.visible).toBe(false);
  });

  test('toggle does not affect playing state', () => {
    const playingState = { ...initialState, playing: true, visible: true };
    const state = audioReducer(playingState, { type: 'audio/toggle' });

    expect(state.visible).toBe(false);
    expect(state.playing).toBe(true);
  });

  test('stopMusic after playMusic clears meta', () => {
    let state = audioReducer(initialState, {
      type: 'audio/playMusic',
      payload: { title: 'Test' },
    });
    expect(state.meta).toEqual({ title: 'Test' });

    state = audioReducer(state, { type: 'audio/stopMusic' });
    expect(state.meta).toBeNull();
  });

  test('returns state unchanged for unknown action', () => {
    const state = { visible: true, playing: true };
    expect(audioReducer(state, { type: 'UNKNOWN' })).toBe(state);
  });
});

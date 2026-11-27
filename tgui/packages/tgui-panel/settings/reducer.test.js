import { loadSettings } from './actions';
import { settingsReducer } from './reducer';

describe('settingsReducer', () => {
  test('loadSettings does not mutate payload objects', () => {
    const payload = {
      version: 1,
      theme: 'dark',
      view: {
        visible: true,
      },
    };

    const nextState = settingsReducer(undefined, loadSettings(payload));

    expect(nextState.theme).toBe('dark');
    expect(payload.view).toEqual({
      visible: true,
    });
  });

  test('v1 settings load correctly with v2 defaults', () => {
    const payload = {
      version: 1,
      theme: 'dark',
      fontSize: 14,
    };

    const nextState = settingsReducer(undefined, loadSettings(payload));

    // Existing v1 fields are preserved
    expect(nextState.theme).toBe('dark');
    expect(nextState.fontSize).toBe(14);
    // New v2 fields use defaults
    expect(nextState.chatStyle).toBe('classic');
    expect(nextState.chatAnimation).toBe('none');
    expect(nextState.chatBgColor).toBe('');
    expect(nextState.chatTextColor).toBe('');
    expect(nextState.chatAccentColor).toBe('');
    expect(nextState.smoothScroll).toBe(false);
    expect(nextState.hoverEffect).toBe(false);
  });

  test('v2 settings load correctly with v3 defaults', () => {
    const payload = {
      version: 2,
      chatStyle: 'bubbles',
      chatAnimation: 'fadein',
      chatBgColor: '#111111',
      smoothScroll: true,
    };

    const nextState = settingsReducer(undefined, loadSettings(payload));

    // Existing v2 fields are preserved
    expect(nextState.chatStyle).toBe('bubbles');
    expect(nextState.chatAnimation).toBe('fadein');
    expect(nextState.chatBgColor).toBe('#111111');
    expect(nextState.smoothScroll).toBe(true);
    // New v3 fields use defaults
    expect(nextState.chatAnimSpeed).toBe('normal');
    expect(nextState.textGlow).toBe('none');
    expect(nextState.textGlowColor).toBe('');
    expect(nextState.messageSpacing).toBe(2);
    expect(nextState.fontWeight).toBe(400);
    expect(nextState.letterSpacing).toBe(0);
    expect(nextState.borderRadius).toBe(8);
  });

  test('v3 settings load correctly with v4 defaults', () => {
    const payload = {
      version: 3,
      chatStyle: 'neon',
      textGlow: 'subtle',
      borderRadius: 4,
      messageSpacing: 5,
    };

    const nextState = settingsReducer(undefined, loadSettings(payload));

    // Existing v3 fields are preserved
    expect(nextState.chatStyle).toBe('neon');
    expect(nextState.textGlow).toBe('subtle');
    expect(nextState.borderRadius).toBe(4);
    expect(nextState.messageSpacing).toBe(5);
    // New v4 fields use defaults
    expect(nextState.enableTimestamps).toBe(false);
    expect(nextState.timestampFormat).toBe('hm');
    expect(nextState.enableTimeDividers).toBe(false);
    expect(nextState.timeDividerInterval).toBe(300000);
  });

  test('v4 settings load correctly with v5 defaults', () => {
    const payload = {
      version: 4,
      chatStyle: 'bubbles',
      enableTimestamps: true,
      timestampFormat: 'hms',
    };

    const nextState = settingsReducer(undefined, loadSettings(payload));

    // Existing v4 fields are preserved
    expect(nextState.chatStyle).toBe('bubbles');
    expect(nextState.enableTimestamps).toBe(true);
    expect(nextState.timestampFormat).toBe('hms');
    // New v5 fields use defaults
    expect(nextState.chatBgAnimation).toBe('none');
    expect(nextState.chatBgAnimOpacity).toBe(0.5);
  });

  test('v5 settings load correctly with v6 defaults', () => {
    const payload = {
      version: 5,
      chatStyle: 'bubbles',
      highlightText: 'hello',
    };

    const nextState = settingsReducer(undefined, loadSettings(payload));

    expect(nextState.chatStyle).toBe('bubbles');
    expect(nextState.highlightSettings).toEqual([
      expect.objectContaining({ highlightText: 'hello', sound: false }),
    ]);
  });

  test('loads v6 payload with v7 defaults', () => {
    const state = settingsReducer(undefined, loadSettings({
      version: 6,
      chatStyle: 'retro',
    }));
    expect(state.version).toBe(8);
    expect(state.chatStyle).toBe('retro');
    expect(state.typeOverrides).toEqual({});
    expect(state.gameEffectsEnabled).toBe(true);
    expect(state.gameEffects).toEqual({});
    expect(state.settleOldAnimations).toBe(true);
  });

  test('v7 single highlight becomes the first group of v8', () => {
    const state = settingsReducer(undefined, loadSettings({
      version: 7,
      highlightText: 'Ваня, капитан',
      highlightColor: '#123456',
      highlightSoundEnabled: true,
      matchWord: true,
      matchCase: true,
    }));
    expect(state.version).toBe(8);
    expect(state.highlightSettings).toEqual([expect.objectContaining({
      enabled: true,
      highlightText: 'Ваня, капитан',
      highlightColor: '#123456',
      sound: true,
      matchWord: true,
      matchCase: true,
      speechOnly: false,
    })]);
    for (const key of ['highlightText', 'highlightColor',
      'highlightSoundEnabled', 'matchWord', 'matchCase']) {
      expect(state).not.toHaveProperty(key);
    }
  });

  test('partial load without highlight keeps current groups', () => {
    const state = settingsReducer(undefined, loadSettings({
      version: 8,
      highlightSettings: [{ id: 'a', highlightText: 'Ваня' }],
    }));
    // Так приходит panel/theme и поздняя частичная загрузка
    const next = settingsReducer(state, loadSettings({
      version: 1,
      theme: 'light',
    }));
    expect(next.theme).toBe('light');
    expect(next.highlightSettings).toBe(state.highlightSettings);
  });

  test('v8 groups load as saved, the same content keeps the reference', () => {
    const highlightSettings = [
      { id: 'a', enabled: true, highlightText: 'Ваня',
        highlightColor: '#ff0000', matchWord: true, matchStart: false,
        matchEnd: false, matchCase: false,
        speechOnly: true, sound: true },
      { id: 'b', enabled: false, highlightText: 'медбей',
        highlightColor: '#00ff00', matchWord: false, matchStart: false,
        matchEnd: false, matchCase: false,
        speechOnly: false, sound: false },
    ];
    const state = settingsReducer(undefined, loadSettings({
      version: 8,
      highlightSettings,
    }));
    expect(state.highlightSettings).toEqual(highlightSettings);
    const again = settingsReducer(state, loadSettings({
      version: 8,
      highlightSettings: JSON.parse(JSON.stringify(highlightSettings)),
    }));
    expect(again.highlightSettings).toBe(state.highlightSettings);
  });
});

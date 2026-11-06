import { setGlobalStore } from 'common/redux';
import { act } from 'react';
import { createRoot } from 'react-dom/client';

import { APPEARANCE_KEYS } from './appearanceCode';
import { settingsReducer } from './reducer';
import { SettingsChannels } from './SettingsChannels';
import { SettingsEffects } from './SettingsEffects';
import { SettingsAppearance, SettingsTextStyles } from './SettingsPanel';
import { SettingsRadioJobs } from './SettingsRadioJobs';

const DEFAULTS = settingsReducer(undefined, { type: 'init' });

// Не оформление: тема, звук и подсветка, время, вкладки, служебное.
const NOT_APPEARANCE = ['version', 'theme', 'adminMusicVolume',
  'highlightText', 'highlightColor', 'highlightSoundEnabled', 'matchWord',
  'matchCase', 'enableTimestamps', 'timestampFormat', 'enableTimeDividers',
  'timeDividerInterval', 'newMessagesMarker', 'visibleMessageLimit', 'view'];

// Кнопка сброса каждой вкладки и ключи оформления этой вкладки.
const RESETS = [
  {
    Tab: SettingsAppearance,
    button: 'Сбросить оформление',
    keys: ['chatStyle', 'chatAnimation', 'chatAnimSpeed', 'chatBgAnimation',
      'chatBgAnimOpacity', 'chatBgColor', 'chatTextColor', 'chatAccentColor',
      'smoothScroll', 'hoverEffect', 'textGlow', 'textGlowColor',
      'messageSpacing', 'fontWeight', 'letterSpacing', 'borderRadius'],
  },
  {
    Tab: SettingsTextStyles,
    button: 'Сбросить стили текста',
    keys: ['styleOverrides', 'spanAnimations'],
  },
  {
    Tab: SettingsChannels,
    button: 'Сбросить каналы',
    keys: ['typeOverrides'],
  },
  {
    Tab: SettingsEffects,
    button: 'Сбросить эффекты',
    keys: ['gameEffects', 'gameEffectsEnabled', 'settleOldAnimations'],
  },
  {
    Tab: SettingsRadioJobs,
    button: 'Сбросить должности',
    keys: ['showRadioJobs', 'radioJobColorMode', 'radioJobHeadMark',
      'radioJobColorNames', 'radioJobIcons', 'radioJobColors'],
  },
];

// Шрифт и высота строки во вкладке "Основные" без кнопки сброса.
const WITHOUT_RESET = ['fontSize', 'fontFamily', 'lineHeight'];

// Значения не по умолчанию для каждого ключа оформления.
const CHANGED = {
  fontSize: 20, fontFamily: 'Arial', lineHeight: 2,
  chatStyle: 'pda', chatAnimation: 'scanner', chatAnimSpeed: 'slow',
  chatBgAnimation: 'snow', chatBgAnimOpacity: 0.8, chatBgColor: '#101010',
  chatTextColor: '#eeeeee', chatAccentColor: '#00ff00', smoothScroll: true,
  hoverEffect: true, textGlow: 'soft', textGlowColor: '#ff0000',
  messageSpacing: 5, fontWeight: 700, letterSpacing: 1, borderRadius: 2,
  styleOverrides: { emote: { color: '#112233' } }, spanAnimations: false,
  typeOverrides: { radio: { border: '#111111' } }, gameEffectsEnabled: false,
  gameEffects: { tremble: false }, settleOldAnimations: false,
  showRadioJobs: false, radioJobColorMode: 'none', radioJobHeadMark: 'bold',
  radioJobColorNames: true, radioJobIcons: false,
  radioJobColors: { med: '#00ff00' },
};

const mounted = [];

beforeAll(() => {
  globalThis.IS_REACT_ACT_ENVIRONMENT = true;
});

afterEach(() => {
  for (const { root, container } of mounted.splice(0)) {
    act(() => root.unmount());
    container.remove();
  }
});

test('every setting is either appearance or named as not', () => {
  const keys = Object.keys(DEFAULTS).sort();
  expect(NOT_APPEARANCE.filter(key => APPEARANCE_KEYS.includes(key)))
    .toEqual([]);
  expect([...APPEARANCE_KEYS, ...NOT_APPEARANCE].sort()).toEqual(keys);
});

test('every appearance key has a reset button or is named as not', () => {
  const covered = [...RESETS.flatMap(reset => reset.keys), ...WITHOUT_RESET];
  expect([...covered].sort()).toEqual([...APPEARANCE_KEYS].sort());
  expect(Object.keys(CHANGED).sort()).toEqual([...APPEARANCE_KEYS].sort());
});

test.each(RESETS)('$button restores its tab', ({ Tab, button, keys }) => {
  const dispatched = [];
  setGlobalStore({
    getState: () => ({ settings: { ...DEFAULTS, ...CHANGED } }),
    dispatch: action => dispatched.push(action),
  });
  const container = document.createElement('div');
  document.body.appendChild(container);
  const root = createRoot(container);
  act(() => root.render(<Tab />));
  mounted.push({ root, container });
  const node = [...container.querySelectorAll('.Button')]
    .find(candidate => candidate.textContent.trim() === button);
  expect(node).toBeTruthy();
  act(() => node.dispatchEvent(new MouseEvent('click', { bubbles: true })));
  const payload = dispatched.at(-1).payload;
  const expected = Object.fromEntries(keys.map(key => [key, DEFAULTS[key]]));
  expect(payload).toEqual(expected);
});

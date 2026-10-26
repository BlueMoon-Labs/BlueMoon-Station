import { setGlobalStore } from 'common/redux';
import { act } from 'react';
import { createRoot } from 'react-dom/client';

import { APPEARANCE_KEYS, decodeAppearance, encodeAppearance } from './appearanceCode';
import { AppearanceCode } from './SettingsPanel';

const sample = {
  chatStyle: 'seccon',
  chatAnimation: 'teletype',
  chatBgAnimation: 'snow',
  chatAccentColor: '#b3261e',
  typeOverrides: { adminpm: { border: '#c0392b', flash: true } },
  highlightText: 'секрет',
};

const roundTrip = settings => decodeAppearance(encodeAppearance(settings));

test('round trip keeps appearance and drops non-appearance keys', () => {
  const result = decodeAppearance(encodeAppearance(sample));
  expect(result.ok).toBe(true);
  expect(result.settings.chatStyle).toBe('seccon');
  expect(result.settings.typeOverrides.adminpm.flash).toBe(true);
  expect(result.settings.highlightText).toBeUndefined();
});

test('cyrillic survives', () => {
  const code = encodeAppearance({ chatStyle: 'pda', fontFamily: 'Тест' });
  const result = decodeAppearance(code);
  expect(result.ok).toBe(true);
  expect(result.settings.fontFamily).toBe('Тест');
});

test('garbage is rejected', () => {
  expect(decodeAppearance('мусор').ok).toBe(false);
  expect(decodeAppearance('BMCHAT1:!!!').ok).toBe(false);
  expect(decodeAppearance('').ok).toBe(false);
  expect(decodeAppearance('BMCHAT1:' + btoa('[1,2]')).ok).toBe(false);
  expect(decodeAppearance('BMCHAT1:' + btoa('\xff\xfe')).ok).toBe(false);
  expect(decodeAppearance(undefined).ok).toBe(false);
});

test('errors are russian text for the player', () => {
  const result = decodeAppearance('мусор');
  expect(result.error).toMatch(/[а-я]/);
});

test('code survives line breaks and spaces from a messenger', () => {
  const code = encodeAppearance(sample);
  const broken = '  ' + code.slice(0, 12) + '\n' + code.slice(12, 30)
    + ' ' + code.slice(30) + '\n';
  const result = decodeAppearance(broken);
  expect(result.ok).toBe(true);
  expect(result.settings).toEqual(roundTrip(sample).settings);
});

test('unknown preset ids fall back to defaults', () => {
  const code = encodeAppearance({
    chatStyle: 'nope', chatAnimation: 'nope', chatBgAnimation: 'nope',
  });
  const result = decodeAppearance(code);
  expect(result.settings.chatStyle).toBe('classic');
  expect(result.settings.chatAnimation).toBe('none');
  expect(result.settings.chatBgAnimation).toBe('none');
});

test('non-object override maps are dropped', () => {
  const code = encodeAppearance({ typeOverrides: 'x', styleOverrides: [1] });
  const result = decodeAppearance(code);
  expect(result.settings.typeOverrides).toBeUndefined();
  expect(result.settings.styleOverrides).toBeUndefined();
});

test('marker of new messages and other settings stay out of the code', () => {
  expect(APPEARANCE_KEYS).toContain('settleOldAnimations');
  expect(APPEARANCE_KEYS).not.toContain('newMessagesMarker');
  const result = roundTrip({
    ...sample,
    newMessagesMarker: true,
    highlightColor: '#ff0000',
    highlightSoundEnabled: true,
    adminMusicVolume: 1,
    theme: 'light',
    view: { visible: true, activeTab: 'general' },
  });
  for (const key of ['newMessagesMarker', 'highlightColor',
    'highlightSoundEnabled', 'adminMusicVolume', 'theme', 'view']) {
    expect(result.settings[key]).toBeUndefined();
  }
});

// Пределы контролов вкладок Основные и Оформление.
const UI_LIMITS = {
  fontSize: [8, 32],
  lineHeight: [0.8, 5],
  chatBgAnimOpacity: [0.05, 1],
  messageSpacing: [0, 10],
  fontWeight: [100, 900],
  letterSpacing: [-0.5, 3],
  borderRadius: [0, 16],
};

test('numbers at the edges of the controls are kept', () => {
  for (const edge of [0, 1]) {
    const values = {};
    for (const [key, limits] of Object.entries(UI_LIMITS)) {
      values[key] = limits[edge];
    }
    expect(roundTrip(values).settings).toEqual(values);
  }
  expect(roundTrip({ lineHeight: 3.5 }).settings).toEqual({ lineHeight: 3.5 });
});

test('numbers out of the controls limits or of a wrong type are dropped', () => {
  for (const [key, [min, max]] of Object.entries(UI_LIMITS)) {
    const step = (max - min) / 100;
    for (const value of [min - step, max + step, String(min), NaN, null]) {
      expect(roundTrip({ [key]: value }).settings).toEqual({});
    }
  }
  expect(roundTrip({ lineHeight: 5.5 }).settings).toEqual({});
});

test('colors must be #rrggbb or empty', () => {
  const result = roundTrip({
    chatBgColor: '',
    chatTextColor: '#A1b2C3',
    chatAccentColor: 'red',
    textGlowColor: '#fff',
  });
  expect(result.settings).toEqual({ chatBgColor: '', chatTextColor: '#A1b2C3' });
  expect(roundTrip({ chatAccentColor: '#123456; } body { x: y' })
    .settings.chatAccentColor).toBeUndefined();
});

test('booleans must be booleans', () => {
  const result = roundTrip({
    hoverEffect: 'yes',
    spanAnimations: false,
    settleOldAnimations: true,
  });
  expect(result.settings).toEqual({
    spanAnimations: false,
    settleOldAnimations: true,
  });
});

test('speed and glow must be known ids, font a short string', () => {
  expect(roundTrip({ chatAnimSpeed: 'slow', textGlow: 'strong' }).settings)
    .toEqual({ chatAnimSpeed: 'slow', textGlow: 'strong' });
  expect(roundTrip({ chatAnimSpeed: 'warp', textGlow: 5 }).settings)
    .toEqual({});
  expect(roundTrip({ fontFamily: 7 }).settings).toEqual({});
  expect(roundTrip({ fontFamily: 'x'.repeat(200) }).settings).toEqual({});
});

test('channel overrides keep only known channels and valid fields', () => {
  const result = roundTrip({
    typeOverrides: {
      adminpm: { border: '#c0392b', tint: true, anim: 'teletype', flash: true },
      radio: { border: 'blue', tint: 'yes', anim: 'nope', flash: false },
      combat: { anim: 'none' },
      bogus: { border: '#000000' },
      ooc: 'x',
    },
  });
  expect(result.settings.typeOverrides).toEqual({
    adminpm: { border: '#c0392b', tint: true, anim: 'teletype', flash: true },
    radio: { flash: false },
    combat: { anim: 'none' },
  });
});

test('tint without a stripe stays out of the code', () => {
  const stray = { radio: { tint: true, anim: 'fadein' }, ooc: { tint: true } };
  const code = encodeAppearance({ typeOverrides: stray });
  expect(JSON.stringify(decodeAppearance(code))).not.toContain('tint');
  expect(atob(code.slice(code.indexOf(':') + 1))).not.toContain('tint');
  expect(decodeAppearance(code).settings.typeOverrides)
    .toEqual({ radio: { anim: 'fadein' } });
});

test('smooth scroll travels with the appearance', () => {
  expect(roundTrip({ smoothScroll: true }).settings)
    .toEqual({ smoothScroll: true });
  expect(roundTrip({ smoothScroll: 'yes' }).settings).toEqual({});
});

test('text style overrides keep only known styles and valid fields', () => {
  const result = roundTrip({
    styleOverrides: {
      emote: { color: '#112233', font: 'bold', size: 150, anim: 'pulse' },
      whisper: { color: 'x', font: 'comic', size: 500, anim: 'spin',
        disabled: true },
      unknown: { color: '#112233' },
    },
  });
  expect(result.settings.styleOverrides).toEqual({
    emote: { color: '#112233', font: 'bold', size: 150, anim: 'pulse' },
    whisper: { disabled: true },
  });
});

const rawCode = json => 'BMCHAT1:' + btoa(json);

test('hostile keys do not reach prototypes or the result', () => {
  // Поля внутри похожи на настоящие, чтобы копия без фильтра их пропустила.
  const evil = '{"__proto__":{"polluted":true,"flash":true,"disabled":true},'
    + '"constructor":{"flash":true,"disabled":true,"prototype":'
    + '{"polluted":true}},"hasOwnProperty":true}';
  const maps = ['styleOverrides', 'typeOverrides'];
  const json = '{"__proto__":{"polluted":1,"fontSize":12},'
    + '"constructor":{"prototype":{"polluted":1}},"hasOwnProperty":false,'
    + '"styleOverrides":' + evil
    + ',"typeOverrides":' + evil.slice(0, -1) + ',"radio":'
    + evil.slice(0, -1) + ',"flash":true}}}';
  const result = decodeAppearance(rawCode(json));
  expect(result.ok).toBe(true);
  expect(({}).polluted).toBeUndefined();
  expect(Object.prototype.polluted).toBeUndefined();
  expect(Object.keys(result.settings).sort())
    .toEqual(['styleOverrides', 'typeOverrides']);
  expect(result.settings.fontSize).toBeUndefined();
  expect(result.settings.typeOverrides).toEqual({ radio: { flash: true } });
  for (const key of maps) {
    const map = result.settings[key];
    expect(Object.getPrototypeOf(map)).toBe(Object.prototype);
    expect(Object.prototype.hasOwnProperty.call(map, '__proto__')).toBe(false);
    expect(Object.prototype.hasOwnProperty.call(map, 'constructor'))
      .toBe(false);
    for (const entry of Object.values(map)) {
      if (entry && typeof entry === 'object') {
        expect(Object.getPrototypeOf(entry)).toBe(Object.prototype);
        expect(Object.keys(entry)).not.toContain('__proto__');
      }
    }
  }
});

test('a code longer than the limit is rejected', () => {
  const filler = 'x'.repeat(20000);
  const long = encodeAppearance({ chatStyle: 'pda', fontFamily: filler });
  expect(long.length).toBeGreaterThan(20000);
  expect(decodeAppearance(long)).toEqual({ ok: false, error: 'Код повреждён.' });
  const padded = rawCode('{"chatStyle":"pda"' + ' '.repeat(20000) + '}');
  expect(padded.length).toBeGreaterThan(20000);
  expect(decodeAppearance(padded).ok).toBe(false);
});

describe('AppearanceCode block', () => {
  const mounted = [];

  const renderWith = settings => {
    const dispatched = [];
    setGlobalStore({
      getState: () => ({ settings }),
      dispatch: action => dispatched.push(action),
    });
    const container = document.createElement('div');
    document.body.appendChild(container);
    const root = createRoot(container);
    act(() => root.render(<AppearanceCode />));
    mounted.push({ root, container });
    return { container, dispatched };
  };

  const buttonOf = (container, text) => [...container
    .querySelectorAll('.Button')].find(node => node.textContent.includes(text));

  const click = node => act(() => node.dispatchEvent(
    new MouseEvent('click', { bubbles: true })));

  const typeInto = (textarea, value) => act(() => {
    textarea.value = value;
    textarea.dispatchEvent(new Event('input', { bubbles: true }));
  });

  beforeAll(() => {
    globalThis.IS_REACT_ACT_ENVIRONMENT = true;
  });

  afterEach(() => {
    for (const { root, container } of mounted.splice(0)) {
      act(() => root.unmount());
      container.remove();
    }
  });

  test('shows a read-only code of the current appearance', () => {
    const { container } = renderWith(sample);
    expect(container.querySelector('textarea[readonly]')).toBeNull();
    click(buttonOf(container, 'Показать код'));
    const field = container.querySelector('textarea[readonly]');
    expect(field).toBeTruthy();
    expect(field.value).toBe(encodeAppearance(sample));
  });

  test('applying a pasted code dispatches the decoded appearance', () => {
    const { container, dispatched } = renderWith({ chatStyle: 'classic' });
    const input = container.querySelector('textarea:not([readonly])');
    typeInto(input, encodeAppearance(sample));
    click(buttonOf(container, 'Применить код'));
    expect(dispatched).toHaveLength(1);
    expect(dispatched[0].payload).toEqual(roundTrip(sample).settings);
  });

  test('a bad code shows an error and changes nothing', () => {
    const { container, dispatched } = renderWith({ chatStyle: 'classic' });
    const input = container.querySelector('textarea:not([readonly])');
    typeInto(input, 'мусор');
    click(buttonOf(container, 'Применить код'));
    expect(dispatched).toHaveLength(0);
    expect(container.textContent).toContain('Это не код оформления чата.');
  });
});

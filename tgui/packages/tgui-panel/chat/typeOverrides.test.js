import fs from 'fs';
import path from 'path';

import { CHANNEL_TYPES, CHAT_ANIM_SPEEDS, CHAT_ANIMATIONS, TYPE_ANIM_KEYFRAMES } from '../settings/constants';
import { MESSAGE_TYPES } from './constants';
import { buildTypeOverrideCss, hexToRgba, TYPE_ANIM_DURATION_SCALE, TYPE_ANIM_MAX_MS, TYPE_ANIM_TIMING, typeAnimationValue } from './typeOverrides';

describe('hexToRgba', () => {
  test('converts 6-digit hex', () => {
    expect(hexToRgba('#ff0000', 0.1)).toBe('rgba(255, 0, 0, 0.1)');
  });
  test('rejects garbage', () => {
    expect(hexToRgba('red', 0.1)).toBeNull();
    expect(hexToRgba('#ff00', 0.1)).toBeNull();
    expect(hexToRgba(undefined, 0.1)).toBeNull();
  });
});

describe('buildTypeOverrideCss', () => {
  test('empty overrides give empty css', () => {
    expect(buildTypeOverrideCss({})).toBe('');
  });
  test('missing map and empty entries give empty css', () => {
    expect(buildTypeOverrideCss(undefined)).toBe('');
    expect(buildTypeOverrideCss(null)).toBe('');
    expect(buildTypeOverrideCss({ radio: {}, ooc: null })).toBe('');
  });
  test('border and tint', () => {
    const css = buildTypeOverrideCss({ radio: { border: '#336699', tint: true } });
    expect(css).toContain('.Chat .ChatMessage.ChatMessage--type-radio');
    expect(css).toContain('border-left: 3px solid #336699');
    expect(css).toContain('background-color: rgba(51, 102, 153, 0.08)');
  });
  test('stripe tells the style it took the left edge', () => {
    const css = buildTypeOverrideCss({ radio: { border: '#336699' } });
    expect(css).toContain('--type-stripe: 1;');
    expect(css).toContain('padding-left: var(--type-stripe-pad, 6px);');
    const scss = fs.readFileSync(
      path.join(__dirname, '../styles/components/ChatPresets.scss'), 'utf8');
    const rule = scss.match(/\.Chat--style-engineering > \.ChatMessage:not\(\.ChatMessage--highlighted\) \{([^}]*)\}/);
    expect(rule[1]).toContain('var(--type-stripe, 0)');
    expect(rule[1]).toContain('--type-stripe-pad:');
  });
  test('tint without border is ignored', () => {
    expect(buildTypeOverrideCss({ radio: { tint: true } })).toBe('');
  });
  test('animation none and named', () => {
    expect(buildTypeOverrideCss({ ooc: { anim: 'none' } }))
      .toContain('animation: none');
    expect(buildTypeOverrideCss({ ooc: { anim: 'teletype' } }))
      .toContain('animation: chatTeletype'
        + ' min(var(--chat-anim-speed, 320ms) * 1.5, 600ms) linear;');
    expect(buildTypeOverrideCss({ ooc: { anim: 'fadein' } }))
      .toContain('animation: chatFadeIn var(--chat-anim-speed, 320ms)'
        + ' cubic-bezier(0.2, 0.65, 0.3, 1);');
  });
  test('no speed makes an entrance longer than the cap', () => {
    // Длительность так, как её посчитает браузер: min(скорость * k, предел).
    const effective = (anim, speedMs) => {
      const value = typeAnimationValue(anim)
        .replace('var(--chat-anim-speed, 320ms)', speedMs + 'ms');
      const scaled = value.match(/min\(([\d.]+)ms \* ([\d.]+), ([\d.]+)ms\)/);
      if (scaled) {
        return Math.min(+scaled[1] * +scaled[2], +scaled[3]);
      }
      return +value.match(/ ([\d.]+)ms /)[1];
    };
    for (const anim of Object.keys(TYPE_ANIM_KEYFRAMES)) {
      for (const speed of CHAT_ANIM_SPEEDS) {
        const ms = effective(anim, parseInt(speed.value, 10));
        expect([anim, speed.id, ms <= TYPE_ANIM_MAX_MS])
          .toEqual([anim, speed.id, true]);
        expect(ms).toBeGreaterThanOrEqual(parseInt(speed.value, 10));
      }
    }
    expect(Object.keys(TYPE_ANIM_DURATION_SCALE).sort())
      .toEqual(['lamp', 'teletype']);
  });
  test('every entrance animation has a smooth curve', () => {
    for (const anim of Object.keys(TYPE_ANIM_KEYFRAMES)) {
      expect(TYPE_ANIM_TIMING[anim]).toMatch(/^(linear|cubic-bezier\()/);
      expect(typeAnimationValue(anim)).not.toContain('steps(');
    }
  });
  test('type animation matches the chat-wide class', () => {
    const scss = ['ChatCustomization.scss', 'ChatPresets.scss']
      .map(file => fs.readFileSync(
        path.join(__dirname, '../styles/components', file), 'utf8'))
      .join('\n');
    for (const anim of Object.keys(TYPE_ANIM_KEYFRAMES)) {
      const rule = scss.match(new RegExp('\\.ChatMessage--anim-' + anim
        + ' \\{\\s*animation: ([^;]+);'));
      expect(rule).not.toBeNull();
      expect(rule[1]).toBe(typeAnimationValue(anim));
      expect(buildTypeOverrideCss({ ooc: { anim } }))
        .toContain('animation: ' + rule[1] + ';');
    }
  });
  test('scanner bar follows the type animation', () => {
    const scanner = buildTypeOverrideCss({ ooc: { anim: 'scanner' } });
    expect(scanner).toContain('.ChatMessage--type-ooc:not(.ChatMessage--highlighted)'
      + ':not(.Chat:not(.Chat--noSettle) .ChatMessage--settled)::after'
      + ' { content: \'\'; animation: chatScannerBar');
    // Свежесть полосы и в классах, и здесь - условие затухания.
    const scss = fs.readFileSync(
      path.join(__dirname, '../styles/components/ChatPresets.scss'), 'utf8');
    expect(scss).toContain('.Chat:not(.Chat--noSettle) .ChatMessage--settled::after');
    expect(scss).toContain('.ChatMessage--anim-scanner:not(.ChatMessage--highlighted)'
      + ':not(.Chat:not(.Chat--noSettle) .ChatMessage--settled) {');
    const other = buildTypeOverrideCss({ ooc: { anim: 'none' } });
    expect(other).toContain('.ChatMessage--type-ooc:not(.ChatMessage--highlighted)'
      + ':not(.Chat:not(.Chat--noSettle) .ChatMessage--settled)::after'
      + ' { content: none; animation: none; }');
    expect(other).not.toContain('chatScannerBar');
  });
  test('unknown animation is ignored', () => {
    expect(buildTypeOverrideCss({ ooc: { anim: 'spin;}' } })).toBe('');
    expect(buildTypeOverrideCss({ ooc: { anim: 'constructor' } })).toBe('');
  });
  test('flash adds pseudo element rule', () => {
    const css = buildTypeOverrideCss({ adminpm: { border: '#c0392b', flash: true } });
    expect(css).toContain('.ChatMessage--type-adminpm::before');
    expect(css).not.toContain('::after');
    expect(css).toContain('chatTypeFlash');
    expect(css).toContain('rgba(192, 57, 43, 0.35)');
  });
  test('flash without border uses default color', () => {
    const css = buildTypeOverrideCss({ adminpm: { flash: true } });
    expect(css).toContain('rgba(255, 221, 68, 0.35)');
  });
  test('unknown type is ignored', () => {
    expect(buildTypeOverrideCss({ '} body {': { border: '#ffffff' } })).toBe('');
  });
  test('invalid color is ignored', () => {
    expect(buildTypeOverrideCss({ radio: { border: 'red;}' } })).toBe('');
  });
  test('non-string color is ignored', () => {
    expect(buildTypeOverrideCss({ radio: { border: ['#336699'], tint: true } }))
      .toBe('');
  });
  test('channel stripe yields to highlight stripe', () => {
    const css = buildTypeOverrideCss({
      radio: { border: '#336699', anim: 'fadein', flash: true },
    });
    const notHl = '.Chat .ChatMessage.ChatMessage--type-radio'
      + ':not(.ChatMessage--highlighted)';
    expect(css).toContain(notHl + ' { border-left: 3px solid #336699;');
    expect(css).toContain('.Chat .ChatMessage.ChatMessage--type-radio'
      + ' { animation: chatFadeIn');
    expect(css).toContain('.Chat .ChatMessage.ChatMessage--type-radio::before');
  });
  test('settled and reduced motion stop the flash layer', () => {
    const scss = fs.readFileSync(
      path.join(__dirname, '../styles/components/ChatPresets.scss'), 'utf8');
    expect(scss).toContain('.ChatMessage--settled::before');
    expect(scss).toContain('.Chat .ChatMessage::before');
  });
});

describe('CHANNEL_TYPES', () => {
  test('every type is assigned by the renderer', () => {
    const known = MESSAGE_TYPES.map(t => t.type);
    for (const { type } of CHANNEL_TYPES) {
      expect(known).toContain(type);
    }
  });
});

describe('TYPE_ANIM_KEYFRAMES', () => {
  test('covers every chat animation except none', () => {
    const ids = CHAT_ANIMATIONS.map(a => a.id).filter(id => id !== 'none');
    expect(Object.keys(TYPE_ANIM_KEYFRAMES).sort()).toEqual(ids.sort());
  });
  test('every keyframe exists in the stylesheets', () => {
    const dir = path.join(__dirname, '../styles/components');
    const scss = ['ChatCustomization.scss', 'ChatPresets.scss']
      .map(file => fs.readFileSync(path.join(dir, file), 'utf8'))
      .join('\n');
    const names = [...Object.values(TYPE_ANIM_KEYFRAMES), 'chatTypeFlash'];
    for (const name of names) {
      expect(scss).toMatch(new RegExp('@keyframes ' + name + ' \\{'));
    }
  });
});

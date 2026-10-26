import fs from 'fs';
import path from 'path';

import { CHAT_ANIM_SPEEDS, CHAT_ANIMATIONS, CHAT_BG_ANIMATIONS, CHAT_STYLES, MESSAGE_STYLE_ANIMATIONS, TYPE_ANIM_KEYFRAMES } from './constants';

const stylesDir = path.resolve(__dirname, '../styles/components');
const css = ['ChatCustomization.scss', 'ChatBgAnimations.scss', 'ChatPresets.scss']
  .map(file => fs.readFileSync(path.join(stylesDir, file), 'utf8'))
  .join('\n');

// Тело @keyframes name без внешних скобок (вложенные блоки внутри).
const keyframes = (text, name) => {
  const head = '@keyframes ' + name + ' {';
  const start = text.indexOf(head);
  expect(start).toBeGreaterThan(-1);
  let depth = 1;
  let i = start + head.length;
  while (depth > 0 && i < text.length) {
    depth += text[i] === '{' ? 1 : text[i] === '}' ? -1 : 0;
    i++;
  }
  return text.slice(start + head.length, i - 1);
};

const keyframeNames = (text, pattern) => [...text.matchAll(
  new RegExp('@keyframes (' + pattern + ') \\{', 'g'))].map(m => m[1]);

// { имя: [свойства] } для всех @keyframes с именем по шаблону.
const keyframeProps = (text, pattern) => Object.fromEntries(
  keyframeNames(text, pattern).map(name => [name, [...new Set(
    [...keyframes(text, name).matchAll(/([a-z-]+)\s*:/g)].map(m => m[1]))]]));

// Значения border-left / border-left-color целиком, до точки с запятой.
const stripeDeclarations = text =>
  [...text.matchAll(/border-left(?:-color)?\s*:\s*([^;{}]+);/g)]
    .map(match => match[1]);

const LINE_WIDTH_OR_STYLE = /^(\d*\.?\d+(px|em|rem)|thin|medium|thick|none|hidden|dotted|dashed|solid|double|groove|ridge|inset|outset)$/;

// Цвет рамки задан напрямую, а не через var(--chat-accent, ...).
const hardStripeColor = value => {
  const tokens = value.trim().split(/\s+/);
  while (tokens.length > 1 && LINE_WIDTH_OR_STYLE.test(tokens[0])) {
    tokens.shift();
  }
  return /^(#|rgba?\(|hsla?\()/.test(tokens.join(' '));
};

describe('chat presets', () => {
  test.each(CHAT_STYLES.filter(s => s.id !== 'classic'))(
    'style $id has css', ({ id }) => {
      expect(css).toContain('.Chat--style-' + id);
    });
  test.each(CHAT_ANIMATIONS.filter(a => a.id !== 'none'))(
    'animation $id has css', ({ id }) => {
      expect(css).toContain('.ChatMessage--anim-' + id);
    });
  test.each(CHAT_BG_ANIMATIONS.filter(a => a.id !== 'none'))(
    'background $id has css', ({ id }) => {
      expect(css).toContain('.Chat--bgAnim-' + id);
    });
  describe('backgrounds', () => {
    const bg = fs.readFileSync(
      path.join(stylesDir, 'ChatBgAnimations.scss'), 'utf8');
    // Кадры фонов: обычные @keyframes, циклы repeat-keyframes и сдвиги
    // drift-keyframes, у которых в теле один transform.
    const frames = keyframeProps(bg, 'bg[A-Za-z]+');
    for (const m of bg.matchAll(
      /@include repeat-keyframes\((bg[A-Za-z]+), \d+, \(([\s\S]*?)\n\)\);/g)) {
      frames[m[1]] = [...new Set(
        [...m[2].matchAll(/[(,] ?([a-z-]+): /g)].map(p => p[1]))];
    }
    for (const m of bg.matchAll(/@include drift-keyframes\((bg[A-Za-z]+),/g)) {
      frames[m[1]] = ['transform'];
    }
    const mixin = name => bg.slice(bg.indexOf('@mixin ' + name),
      bg.indexOf('\n}\n', bg.indexOf('@mixin ' + name)));

    test('animate only transform and opacity', () => {
      expect(Object.keys(frames).length).toBeGreaterThan(30);
      for (const [name, props] of Object.entries(frames)) {
        expect([name, props.filter(p => p !== 'transform'
          && p !== 'opacity')]).toEqual([name, []]);
      }
      expect([...mixin('drift-keyframes').matchAll(/\n\s*([a-z-]+):/g)]
        .map(m => m[1])).toEqual(['transform', 'transform',
        'animation-timing-function', 'transform']);
      expect(bg).not.toContain('@property');
      expect(bg).not.toMatch(/background-position|mask-position/);
    });

    // Слой с плиткой: сдвиг drift-keyframes равен его ($dx, $dy) и кратен
    // каждой плитке в блоке слоя, иначе на границе цикла узор прыгает.
    test('drifts move by whole tiles', () => {
      const drifts = {};
      for (const m of bg.matchAll(
        /@include drift-keyframes\((bg[A-Za-z]+), (-?[\d.]+)px, (-?[\d.]+)px/g)) {
        drifts[m[1]] = [+m[2], +m[3]];
      }
      const blocks = bg.split(/#\{\$L[123]\}/).slice(1);
      let checked = 0;
      for (const block of blocks) {
        const anim = block.match(/animation: (bg[A-Za-z]+) /);
        if (!anim || !drifts[anim[1]] || anim[1].startsWith('bgWaves')) {
          continue;
        }
        const [dx, dy] = drifts[anim[1]];
        const own = block.match(/@include (?:tile-layer|flakes)\(([\d.]+)px, ([\d.]+)px, (-?[\d.]+)px, (-?[\d.]+)px/);
        if (own) {
          expect([anim[1], +own[3], +own[4]]).toEqual([anim[1], dx, dy]);
        }
        const sizes = [...block.matchAll(/background-size: ([\d.]+)px ([\d.]+)px/g)]
          .map(m => [+m[1], +m[2]]);
        if (own) {
          sizes.push([+own[1], +own[2]]);
        }
        expect(sizes.length).toBeGreaterThan(0);
        for (const [w, h] of sizes) {
          expect([anim[1], w, h, Math.abs(dx % w), Math.abs(dy % h)])
            .toEqual([anim[1], w, h, 0, 0]);
        }
        checked++;
      }
      expect(checked).toBeGreaterThan(20);
    });
    test('loops end where they start', () => {
      const alternate = new Set([...bg.matchAll(
        /animation: (bg[A-Za-z]+) [^;]*alternate/g)].map(m => m[1]));
      // Концы расходятся, но скачок не виден: оба конца прозрачны, поворот
      // на целые обороты или полоса за краем окна.
      const hidden = ['bgRadFlashA', 'bgRadFlashB', 'bgMeteor', 'bgCrtRoll',
        'bgBeaconSpin'];
      for (const name of keyframeNames(bg, 'bg[A-Za-z]+')) {
        if (alternate.has(name) || hidden.includes(name)) {
          continue;
        }
        const frames = [...keyframes(bg, name).matchAll(/\n {2}([\d.%,\s]+|from|to) \{([^}]*)\}/g)];
        const first = frames[0][2].trim();
        const last = frames[frames.length - 1][2].trim();
        const shared = frames.some(f => /(^|\D)0%/.test(f[1])
          && /100%/.test(f[1]));
        expect([name, shared || first === last]).toEqual([name, true]);
      }
      for (const m of bg.matchAll(
        /@include repeat-keyframes\((bg[A-Za-z]+), \d+, \(([\s\S]*?)\n\)\);/g)) {
        const first = m[2].match(/\n {2}0%: (\(.*\)),/);
        const last = m[2].match(/\n {2}(?:100|99\.9)%: (\(.*\)),/);
        const opacity = s => (s.match(/opacity: ([\d.]+)/) || [])[1];
        if (last[0].includes('99.9%')) {
          // Конец раньше 100%: прыжок к началу только на прозрачном слое.
          expect([m[1], opacity(first[1]), opacity(last[1])])
            .toEqual([m[1], '0', '0']);
          continue;
        }
        expect([m[1], last[1]]).toEqual([m[1], first[1]]);
      }
    });
    test('flake sway stays inside the layer margin', () => {
      const pad = +mixin('flakes').match(/tile-layer\([^)]*, ([\d.]+)px\)/)[1];
      for (const name of ['bgSwayX', 'bgSwayXSmall', 'bgFlutter', 'bgSteam',
        'bgEmberFlicker']) {
        const def = bg.match(new RegExp('@include repeat-keyframes\\(' + name
          + ', \\d+, \\(([\\s\\S]*?)\\n\\)\\);'))[1];
        const shifts = [...def.matchAll(/translate3d\((-?[\d.]+)(?:px)?, (-?[\d.]+)(?:px)?,/g)]
          .flatMap(m => [Math.abs(+m[1]), Math.abs(+m[2])]);
        expect([name, Math.max(...shifts) < pad]).toEqual([name, true]);
      }
    });
    test.each(CHAT_BG_ANIMATIONS.filter(a => a.id !== 'none'))(
      'background $id draws on the viewport layers', ({ id }) => {
        const start = bg.indexOf('.Chat.Chat--bgAnim-' + id + ' {');
        expect(start).toBeGreaterThan(-1);
        const end = bg.indexOf('\n}\n', start);
        expect(bg.slice(start, end)).toMatch(/#\{\$L[123]\}/);
      });
    test('every animation used by a layer is defined', () => {
      const used = [...bg.matchAll(/animation: (bg[A-Za-z]+) /g)]
        .map(m => m[1]);
      expect(used.length).toBeGreaterThan(40);
      for (const name of used) {
        expect(Object.keys(frames)).toContain(name);
      }
    });
  });
  test('entrance keyframes stay on the compositor', () => {
    const frames = keyframeProps(css, 'chat[A-Za-z]+');
    const names = [...Object.values(TYPE_ANIM_KEYFRAMES), 'chatScannerBar'];
    for (const name of names) {
      const allowed = ['opacity', 'transform', 'filter'];
      // Печать и створки шлюза режут блок, это движение по краю.
      if (name === 'chatTeletype' || name === 'chatAirlock') {
        allowed.push('clip-path');
      }
      expect([name, frames[name].filter(p => !allowed.includes(p))])
        .toEqual([name, []]);
      // Фильтры, сдвигающие пиксели, композитор не ведёт.
      expect([name, keyframes(css, name)])
        .not.toEqual([name, expect.stringMatching(/blur\(|drop-shadow\(/)]);
    }
  });
  test('entrance animations do not step', () => {
    const rules = [...css.matchAll(/\.ChatMessage--anim-[a-z]+[^{]*\{([^}]*)\}/g)];
    expect(rules.length).toBeGreaterThanOrEqual(CHAT_ANIMATIONS.length - 1);
    for (const rule of rules) {
      expect(rule[1]).not.toContain('steps(');
    }
  });
  test('background keyframes follow the chat window, not the panel', () => {
    const bg = fs.readFileSync(
      path.join(stylesDir, 'ChatBgAnimations.scss'), 'utf8');
    const frames = keyframeNames(bg, 'bg[A-Za-z]+')
      .map(name => keyframes(bg, name)).join('');
    expect(frames).not.toMatch(/\dvh/);
  });
  // Перерисовка text-shadow идёт шагами не реже 15 в секунду на отрезок
  // кейфреймов; смена цвета плавная. Нарочно рваные глитчи не в счёт.
  test('stepped text effects stay near smooth', () => {
    const glitches = ['ai_glitch', 'bcast_flicker', 'glitch-jit', 'cs-flicker'];
    const uses = [];
    for (const file of ['chat-dark.scss', 'chat-light.scss']) {
      const goon = fs.readFileSync(
        path.join(stylesDir, '../goon', file), 'utf8');
      for (const m of goon.matchAll(/animation: ([\w-]+) (\d+)ms steps\((\d+)\)/g)) {
        const kf = keyframes(goon, m[1]);
        const offsets = kf.match(/(\d+%|from|to)/g).length;
        uses.push([m[1], +m[2], +m[3], offsets - 1]);
      }
      for (const name of ['hypnocolor', 'velvet', 'phobia']) {
        expect(goon).toMatch(new RegExp('animation: ' + name + ' \\d+ms infinite;'));
      }
    }
    for (const { css } of MESSAGE_STYLE_ANIMATIONS) {
      const m = css && css.match(/^([\w-]+) (\d+)ms steps\((\d+)\)/);
      if (m) {
        uses.push([m[1], +m[2], +m[3], 1]);
      }
    }
    expect(uses.length).toBeGreaterThan(8);
    for (const [name, ms, steps, segments] of uses) {
      if (glitches.includes(name)) {
        continue;
      }
      const perSecond = steps * segments * 1000 / ms;
      expect([name, perSecond >= 15]).toEqual([name, true]);
    }
  });
  test('speeds read at a glance and stay ordered', () => {
    const ms = CHAT_ANIM_SPEEDS.map(s => parseInt(s.value, 10));
    expect(ms).toEqual([...ms].sort((a, b) => a - b));
    expect(Math.min(...ms)).toBeGreaterThanOrEqual(150);
    expect(Math.max(...ms)).toBeLessThanOrEqual(600);
  });
  test('stripe color detector', () => {
    expect(hardStripeColor('2px solid #ffffff')).toBe(true);
    expect(hardStripeColor('3px double\n    #c4a55a')).toBe(true);
    expect(hardStripeColor('2px dashed rgba(1, 2, 3, 0.5)')).toBe(true);
    expect(hardStripeColor('rgba(1, 2, 3, 0.5)')).toBe(true);
    expect(hardStripeColor('3px double var(--chat-accent, #c4a55a)'))
      .toBe(false);
    expect(hardStripeColor('2px solid\n    color-mix(in srgb,'
      + ' var(--chat-accent, #4fb8b2) 75%, transparent)')).toBe(false);
    expect(hardStripeColor('5px solid transparent')).toBe(false);
  });
  test('style stripes use accent variable', () => {
    const custom = ['ChatCustomization.scss', 'ChatPresets.scss']
      .map(file => fs.readFileSync(path.join(stylesDir, file), 'utf8'))
      .join('\n');
    const offenders = stripeDeclarations(custom).filter(hardStripeColor);
    expect(offenders).toEqual([]);
  });
  test.each(['seccon', 'syndicate', 'bridge', 'medbay', 'engineering',
    'cargo', 'centcom', 'blackbox'])('highlighted line keeps text in place in %s', id => {
    const presets = fs.readFileSync(
      path.join(stylesDir, 'ChatPresets.scss'), 'utf8');
    const rule = presets.match(new RegExp('\\.Chat--style-' + id
      + ' > \\.ChatMessage--highlighted \\{([^}]*)\\}'));
    expect(rule).not.toBeNull();
    expect(rule[1]).toMatch(/padding-left: calc\(\d+px - 1em \/ 6\);/);
  });
  test('base highlight uses accent variable', () => {
    const base = fs.readFileSync(path.join(stylesDir, 'Chat.scss'), 'utf8');
    const start = base.indexOf('\n.ChatMessage--highlighted {');
    expect(start).toBeGreaterThan(-1);
    const block = base.slice(start, base.indexOf('\n}', start));
    expect(block).toContain('var(--chat-accent');
    const hardColors = block
      .split('\n')
      .filter(line => /(#[0-9a-f]{3}|rgba?\()/i.test(line))
      .filter(line => !line.includes('var(--'));
    expect(hardColors).toEqual([]);
  });
  test('highlight stands out from accented stripes', () => {
    const custom = fs.readFileSync(
      path.join(stylesDir, 'ChatCustomization.scss'), 'utf8');
    const rule = selector => {
      const start = custom.indexOf('\n' + selector + ' {');
      expect(start).toBeGreaterThan(-1);
      return custom.slice(start, custom.indexOf('\n}', start));
    };
    expect(rule('.Chat--style-terminal > .ChatMessage--highlighted'))
      .toContain('var(--chat-accent');
    const vaporBase = rule('.Chat--style-vaporwave > .ChatMessage');
    const vaporHl = rule('.Chat--style-vaporwave > .ChatMessage--highlighted');
    expect(vaporBase).toContain('color-mix(');
    expect(vaporHl).not.toContain('color-mix(');
  });
});

describe('history settling', () => {
  const presets = () => fs.readFileSync(
    path.join(stylesDir, 'ChatPresets.scss'), 'utf8');
  test('settling can be switched off on the root', () => {
    expect(presets()).toContain(
      '.Chat:not(.Chat--noSettle) .ChatMessage--settled');
    expect(presets()).not.toMatch(/^\.ChatMessage--settled/m);
  });
  // Мигает ореол ::after, сам значок неподвижен; reduced-motion гасит оба.
  test('reduced motion stops the unread badge', () => {
    const base = fs.readFileSync(path.join(stylesDir, 'Chat.scss'), 'utf8');
    const badge = base.slice(base.indexOf('\n.Chat__unreadBadge {'));
    const rule = badge.slice(0, badge.indexOf('\n}'));
    const halo = rule.indexOf('&::after {');
    expect(halo).toBeGreaterThan(-1);
    expect(rule.slice(halo)).toContain('infinite');
    expect(rule.slice(0, halo)).not.toContain('animation:');
    const own = base.slice(base.indexOf('@media (prefers-reduced-motion'));
    expect(own).toMatch(/\.Chat__unreadBadge::after \{\s*animation: none !important;/);
    // Сам значок не анимирован, гасить на нём нечего.
    expect(presets()).not.toContain('.Chat__unreadBadge');
  });
});

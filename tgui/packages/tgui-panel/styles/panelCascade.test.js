import { buildTypeOverrideCss } from '../chat/typeOverrides';
import { CHAT_STYLES, TYPE_ANIM_KEYFRAMES } from '../settings/constants';
import { compilePanelCss, contrast, over, parseColor, parseRules, resolveVars, winningDeclaration } from './cssCascade';

// Собранный бандл и стиль вкладки "Каналы" после него, как в панели.
let bundle;
const rulesWith = (typeOverrides, extra = '') => parseRules(bundle + '\n'
  + buildTypeOverrideCss(typeOverrides || {}) + extra);

beforeAll(() => {
  bundle = compilePanelCss();
});

afterEach(() => {
  document.body.innerHTML = '';
});

// Правила чат-листа, как их пишет generate_css() в batched_spritesheet.dm.
const SPRITESHEET_CSS = '\n.chat16x16{display:inline-block;width:16px;'
  + 'height:16px;background-repeat:no-repeat;}'
  + '\n.chat16x16.job-syndicate{background-position:-16px 0;}';

// Подложка панели вокруг чата: base.scss тёмной темы и светлой.
const PANEL_BG = { dark: '#202020', light: '#eeeeee' };

const mount = (theme, rootClasses, messageClasses) => {
  const wrap = document.createElement('div');
  wrap.className = theme === 'light' ? 'theme-light' : '';
  wrap.innerHTML = '<div class="Chat ' + rootClasses + '">'
    + '<div class="ChatMessage ' + messageClasses + '">text'
    + '<span class="Chat__badge"></span></div></div>';
  document.body.appendChild(wrap);
  const root = wrap.firstChild;
  return { root, message: root.firstChild, badge: root.querySelector('.Chat__badge') };
};

const resolved = (rules, node, property, pseudo) => {
  const decl = winningDeclaration(rules, node, property, pseudo);
  return decl ? resolveVars(rules, node, decl.value) : null;
};

describe('scanner bar', () => {
  const SCANNER = 'ChatMessage--anim-scanner ChatMessage--type-radio';
  const barRuns = (rules, message) => {
    const content = resolved(rules, message, 'content', '::after');
    const animation = resolved(rules, message, 'animation-name', '::after');
    return !!content && content !== 'none'
      && !!animation && animation.startsWith('chatScannerBar');
  };
  test('chat-wide scanner runs the bar', () => {
    const { message } = mount('dark', '', SCANNER);
    expect(barRuns(rulesWith({}), message)).toBe(true);
  });
  test.each(['none', 'fadein', 'teletype'])(
    'channel animation %s stops the chat-wide bar', anim => {
      const { message } = mount('dark', '', SCANNER);
      expect(barRuns(rulesWith({ radio: { anim } }), message)).toBe(false);
    });
  test('channel scanner runs the bar under another chat animation', () => {
    const { message } = mount('dark', '',
      'ChatMessage--anim-fadein ChatMessage--type-radio');
    expect(barRuns(rulesWith({}), message)).toBe(false);
    expect(barRuns(rulesWith({ radio: { anim: 'scanner' } }), message))
      .toBe(true);
  });
  test('settled and highlighted messages keep still', () => {
    const settled = mount('dark', '', SCANNER + ' ChatMessage--settled');
    expect(barRuns(rulesWith({}), settled.message)).toBe(false);
    const awake = mount('dark', 'Chat--noSettle',
      SCANNER + ' ChatMessage--settled');
    expect(barRuns(rulesWith({}), awake.message)).toBe(true);
    const highlighted = mount('dark', '',
      SCANNER + ' ChatMessage--highlighted');
    expect(barRuns(rulesWith({}), highlighted.message)).toBe(false);
  });
});

describe.each(['dark', 'light'])('%s theme', theme => {
  const ACCENT = '#00ff00';
  const accented = '\n.Chat { --chat-accent: ' + ACCENT + '; }';

  // Цвет текста стиля читается на его фоне (или на подложке панели).
  test.each(CHAT_STYLES.map(style => style.id))('style %s text is readable',
    id => {
      const rules = rulesWith({});
      const { root } = mount(theme, 'Chat--style-' + id, '');
      const panel = parseColor(PANEL_BG[theme]);
      const bgValue = resolved(rules, root, 'background-color');
      const bg = bgValue ? over(parseColor(bgValue), panel) : panel;
      const text = resolved(rules, root, 'color');
      expect([id, text]).toEqual([id, expect.any(String)]);
      const ratio = contrast(over(parseColor(text), bg), bg);
      expect([id, text, bgValue, ratio >= 4.5])
        .toEqual([id, text, bgValue, true]);
    });

  // Полоса канала перекрывает полосу стиля, подсветка - их обе. У неона
  // полоса и есть цвет акцента, подсветка там видна по заливке.
  test.each(CHAT_STYLES.map(style => style.id))('style %s: stripes and highlight',
    id => {
      const rules = rulesWith({ radio: { border: '#123456' } }, accented);
      const plain = mount(theme, 'Chat--style-' + id,
        'ChatMessage--type-radio');
      expect([id, resolved(rules, plain.message, 'border-left-color')])
        .toEqual([id, expect.stringContaining('#123456')]);
      const lit = mount(theme, 'Chat--style-' + id,
        'ChatMessage--type-radio ChatMessage--highlighted');
      const stripe = winningDeclaration(rules, lit.message,
        'border-left-color');
      expect([id, stripe.selector]).toEqual([id,
        expect.not.stringContaining('ChatMessage--type-')]);
      if (id === 'neon') {
        return;
      }
      const property = id === 'vaporwave' ? 'border-image' : 'border-left-color';
      const winner = winningDeclaration(rules, lit.message, property);
      expect([id, winner.selector]).toEqual([id,
        expect.stringMatching(/ChatMessage--highlighted(?!\))/)]);
      expect([id, resolveVars(rules, lit.message, winner.value)])
        .toEqual([id, expect.stringContaining(ACCENT)]);
    });

  test.each(['darkpro', 'cyberpunk', 'sakura', 'space'])(
    'style %s stripe follows the accent', id => {
      const rules = rulesWith({}, accented);
      const { message } = mount(theme, 'Chat--style-' + id, '');
      expect([id, resolved(rules, message, 'border-left-color')])
        .toEqual([id, expect.stringContaining(ACCENT)]);
      const second = message.cloneNode(true);
      message.parentNode.appendChild(second);
      expect([id, resolved(rules, second, 'border-left-color')])
        .toEqual([id, expect.stringContaining(ACCENT)]);
    });

  test('vaporwave stripe and cyberpunk badge follow the accent', () => {
    const rules = rulesWith({}, accented);
    const vapor = mount(theme, 'Chat--style-vaporwave', '');
    expect(resolved(rules, vapor.message, 'border-image'))
      .toContain(ACCENT);
    const cyber = mount(theme, 'Chat--style-cyberpunk', '');
    expect(resolved(rules, cyber.badge, 'background-color')).toBe(ACCENT);
  });
});

describe.each(['dark', 'light'])('radio job tags, %s theme', theme => {
  const tag = mode => {
    const rules = rulesWith({});
    const { message } = mount(theme, mode, '');
    message.innerHTML = '<span class="radiojob radiojob-synd radiojob-f-synd'
      + ' radiojob-legacy-synd">[Syndicate Operative]</span>';
    return resolved(rules, message.firstChild, 'color');
  };
  test('"as before" mode keeps the old faction color', () => {
    expect(tag('Chat--rjLegacy')).toBe('#8f4a4b');
    expect(tag('')).not.toBe('#8f4a4b');
  });
  // Разметка say.dm: значок, класс старого вывода первым, у имени свой класс.
  const line = rootClasses => {
    const rules = rulesWith({}, SPRITESHEET_CSS);
    const { message } = mount(theme, rootClasses, '');
    message.innerHTML = '<span class="radiojob-icon chat16x16 job-syndicate">'
      + '</span><span class="radiojob-legacy-synd radiojob radiojob-synd'
      + ' radiojob-f-synd">[Syndicate Operative]</span> <span class='
      + '"radiojob-name radiojob-synd radiojob-f-synd'
      + ' radiojob-name-legacy-synd">Ivan</span>';
    const [icon, tagNode, name] = message.children;
    return {
      icon: winningDeclaration(rules, icon, 'display').value,
      tag: resolved(rules, tagNode, 'color'),
      name: resolved(rules, name, 'color'),
    };
  };
  test('names follow the tag in "as before" mode', () => {
    const legacy = line('Chat--rjLegacy Chat--rjNames');
    expect(legacy.name).toBe('#8f4a4b');
    expect(legacy.name).toBe(legacy.tag);
    const department = line('Chat--rjNames');
    expect(department.name).toBe(department.tag);
    expect(department.name).not.toBe('#8f4a4b');
  });
  test('job icon shows unless turned off', () => {
    expect(line('').icon).toBe('inline-block');
    expect(line('Chat--hideRadioJobs').icon).toBe('inline-block');
    expect(line('Chat--rjNoIcon').icon).toBe('none');
  });
});

// Встряска крика и качка головокружения не отменяют анимацию появления.
describe('block effects keep the entrance', () => {
  const animation = (rootClasses, messageClasses, typeOverrides) => {
    const rules = rulesWith(typeOverrides);
    const { message } = mount('dark', rootClasses, messageClasses);
    return resolved(rules, message, 'animation');
  };
  test.each(Object.keys(TYPE_ANIM_KEYFRAMES))('chat-wide %s', anim => {
    for (const fx of ['shake', 'sway']) {
      const value = animation('', 'ChatMessage--anim-' + anim
        + ' ChatMessage--fx-' + fx);
      expect([anim, fx, value]).toEqual([anim, fx,
        expect.stringMatching(new RegExp('^' + TYPE_ANIM_KEYFRAMES[anim]
          + ' .*, fx-' + fx + ' '))]);
    }
  });
  test('channel animation and no animation', () => {
    expect(animation('', 'ChatMessage--anim-fadein ChatMessage--type-radio'
      + ' ChatMessage--fx-shake', { radio: { anim: 'teletype' } }))
      .toMatch(/^chatTeletype .*, fx-shake /);
    expect(animation('', 'ChatMessage--anim-fadein ChatMessage--type-radio'
      + ' ChatMessage--fx-shake', { radio: { anim: 'none' } }))
      .toMatch(/^none, fx-shake /);
    expect(animation('', 'ChatMessage--fx-shake')).toMatch(/^none, fx-shake /);
  });
  test('switched off effect leaves the entrance alone', () => {
    const value = animation('Chat--fxOff-yell',
      'ChatMessage--anim-fadein ChatMessage--fx-shake');
    expect(value).toMatch(/^chatFadeIn /);
    expect(value).not.toContain('fx-shake');
  });
});

// Светлые частицы и линии на светлой теме темнеют и глушатся.
test.each(['snow', 'hyperspace', 'crtnoise', 'dust', 'radiation', 'meteors',
  'beacon', 'vents'])('background %s has a light theme variant', id => {
  const rules = rulesWith({});
  const layerOpacity = theme => {
    const wrap = document.createElement('div');
    wrap.className = theme === 'light' ? 'theme-light' : '';
    wrap.innerHTML = '<div class="Chat Chat--bgAnim-' + id + '">'
      + '<div class="ChatBg"></div></div>';
    document.body.appendChild(wrap);
    return winningDeclaration(rules, wrap.querySelector('.ChatBg'), 'opacity');
  };
  expect(layerOpacity('light').selector).toContain('.theme-light');
  expect(layerOpacity('dark').selector).not.toContain('.theme-light');
});

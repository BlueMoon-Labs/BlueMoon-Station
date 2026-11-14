/**
 * Каскад для тестов стилей панели: собранный CSS, его правила,
 * специфичность селекторов по Selectors 4 и победитель для узла.
 * Строковые проверки SCSS не видят проигрыш по специфичности.
 */
import path from 'path';
import * as sass from 'sass';
import { pathToFileURL } from 'url';

const PACKAGES = path.resolve(__dirname, '../..');

// Порядок как в бандле: index.js подключает main.scss, затем светлую тему.
const ENTRIES = ['main.scss', 'themes/light.scss'];

// URL из глобала окружения: sass сверяет instanceof с ним, а не с url.URL.
const tildeImporter = {
  findFileUrl: url => (url.startsWith('~')
    ? new URL(pathToFileURL(path.join(PACKAGES, url.slice(1))).href) : null),
};

export const compilePanelCss = () => ENTRIES
  .map(file => sass.compile(path.join(__dirname, file), {
    importers: [tildeImporter],
    logger: sass.Logger.silent,
    style: 'expanded',
  }).css)
  .join('\n');

// Делит по разделителю верхнего уровня, не заходя в скобки и строки.
export const splitTop = (text, separator) => {
  const parts = [];
  let depth = 0;
  let quote = null;
  let start = 0;
  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    if (ch === '\\') {
      i++;
    }
    else if (quote) {
      if (ch === quote) {
        quote = null;
      }
    }
    else if (ch === '"' || ch === '\'') {
      quote = ch;
    }
    else if (ch === '(' || ch === '[') {
      depth++;
    }
    else if (ch === ')' || ch === ']') {
      depth--;
    }
    else if (ch === separator && depth === 0) {
      parts.push(text.slice(start, i).trim());
      start = i + 1;
    }
  }
  parts.push(text.slice(start).trim());
  return parts.filter(part => part !== '');
};

const closing = (text, open) => {
  const pairs = { '(': ')', '[': ']', '{': '}' };
  const end = pairs[text[open]];
  let depth = 0;
  for (let i = open; i < text.length; i++) {
    if (text[i] === '\\') {
      i++;
    }
    else if (text[i] === text[open]) {
      depth++;
    }
    else if (text[i] === end && --depth === 0) {
      return i;
    }
  }
  return text.length;
};

const skipIdent = (text, i) => {
  while (i < text.length) {
    if (text[i] === '\\') {
      i += 2;
    }
    else if (/[\w-]/.test(text[i]) || text.charCodeAt(i) > 127) {
      i++;
    }
    else {
      break;
    }
  }
  return i;
};

const LEGACY_PSEUDO_ELEMENTS = ['before', 'after', 'first-line',
  'first-letter'];

const add = (x, y) => [x[0] + y[0], x[1] + y[1], x[2] + y[2]];

export const compareSpecificity = (x, y) => x[0] - y[0] || x[1] - y[1]
  || x[2] - y[2];

const maxOf = list => splitTop(list, ',').map(specificity)
  .reduce((best, next) => (compareSpecificity(next, best) > 0
    ? next : best), [0, 0, 0]);

/** Специфичность одного сложного селектора: [id, класс, тип]. */
export const specificity = selector => {
  let total = [0, 0, 0];
  let i = 0;
  while (i < selector.length) {
    const ch = selector[i];
    if (ch === '#') {
      total = add(total, [1, 0, 0]);
      i = skipIdent(selector, i + 1);
    }
    else if (ch === '.') {
      total = add(total, [0, 1, 0]);
      i = skipIdent(selector, i + 1);
    }
    else if (ch === '[') {
      total = add(total, [0, 1, 0]);
      i = closing(selector, i) + 1;
    }
    else if (ch === ':') {
      const element = selector[i + 1] === ':';
      const start = i + (element ? 2 : 1);
      i = skipIdent(selector, start);
      const name = selector.slice(start, i).toLowerCase();
      let args = null;
      if (selector[i] === '(') {
        const end = closing(selector, i);
        args = selector.slice(i + 1, end);
        i = end + 1;
      }
      if (element || LEGACY_PSEUDO_ELEMENTS.includes(name)) {
        total = add(total, [0, 0, 1]);
      }
      else if (name === 'where') {
        continue;
      }
      else if (['not', 'is', 'has'].includes(name)) {
        total = add(total, maxOf(args));
      }
      else if (args && /^nth-(last-)?child$/.test(name)
        && / of /.test(args)) {
        total = add(total, add([0, 1, 0],
          maxOf(args.slice(args.indexOf(' of ') + 4))));
      }
      else {
        total = add(total, [0, 1, 0]);
      }
    }
    else if (/[a-zA-Z_-]/.test(ch) || selector.charCodeAt(i) > 127) {
      total = add(total, [0, 0, 1]);
      i = skipIdent(selector, i);
    }
    else {
      i++;
    }
  }
  return total;
};

// ::after, :after и т.п. в конце селектора.
const PSEUDO_ELEMENT = /::?(before|after|first-line|first-letter|placeholder|selection|marker|-webkit-[\w-]+)$/;

const parseDeclarations = body => splitTop(body, ';')
  .filter(part => part.includes(':') && !part.includes('{'))
  .map(part => {
    const colon = part.indexOf(':');
    const raw = part.slice(colon + 1).trim();
    const important = /!\s*important$/.test(raw);
    return {
      property: part.slice(0, colon).trim(),
      value: raw.replace(/\s*!\s*important$/, ''),
      important,
    };
  });

/** Правила стилей в порядке файла; @keyframes и прочие @-блоки пропущены. */
export const parseRules = css => {
  const text = css.replace(/\/\*[\s\S]*?\*\//g, '');
  const rules = [];
  const walk = (chunk, media) => {
    let i = 0;
    while (i < chunk.length) {
      const open = chunk.indexOf('{', i);
      if (open < 0) {
        return;
      }
      const prelude = chunk.slice(i, open).replace(/^[\s;}]+/, '').trim();
      const end = closing(chunk, open);
      const body = chunk.slice(open + 1, end);
      if (prelude.startsWith('@media')) {
        walk(body, prelude);
      }
      else if (!prelude.startsWith('@')) {
        rules.push({
          selectors: splitTop(prelude, ','),
          declarations: parseDeclarations(body),
          media,
          order: rules.length,
        });
      }
      i = end + 1;
    }
  };
  walk(text, null);
  return rules;
};

// jsdom не знает :nth-child(An+B of S). Замена на :is(S):nth-child(An+B)
// считает всех соседей, а не только S: в тестовой разметке это одно и то же.
const NTH_OF = /:nth-(last-)?child\(([^()]*?) of ([^()]*)\)/g;

const matches = (node, selector) => node.matches(selector
  .replace(NTH_OF, (all, last, nth, of) => ':is(' + of + '):nth-'
    + (last || '') + 'child(' + nth + ')'));

// Сокращения, которые тоже задают свойство.
const SHORTHANDS = {
  'border-left-color': ['border', 'border-left', 'border-color'],
  'background-color': ['background'],
  'animation-name': ['animation'],
};

/**
 * Объявление свойства, которое победит на узле (или его ::after и т.п.).
 * Правила из @media не берутся: проверяем обычный режим. Возвращает
 * { value, selector, specificity } или null.
 */
export const winningDeclaration = (rules, node, property, pseudo = '') => {
  const names = [property, ...(SHORTHANDS[property] || [])];
  let best = null;
  for (const rule of rules) {
    if (rule.media) {
      continue;
    }
    const decl = rule.declarations
      .filter(d => names.includes(d.property)).at(-1);
    if (!decl) {
      continue;
    }
    let matched = null;
    for (const selector of rule.selectors) {
      const own = selector.match(PSEUDO_ELEMENT);
      const ownPseudo = own ? '::' + own[1] : '';
      if (ownPseudo !== pseudo) {
        continue;
      }
      const base = own ? selector.slice(0, own.index) || '*' : selector;
      if (!matches(node, base)) {
        continue;
      }
      const spec = specificity(selector);
      if (!matched || compareSpecificity(spec, matched.specificity) > 0) {
        matched = { selector, specificity: spec };
      }
    }
    if (!matched) {
      continue;
    }
    const candidate = { ...matched, value: decl.value,
      important: decl.important, order: rule.order };
    // Правила идут в порядке файла: при равенстве побеждает позднее.
    const wins = !best || (candidate.important !== best.important
      ? candidate.important
      : compareSpecificity(candidate.specificity, best.specificity) >= 0);
    if (wins) {
      best = candidate;
    }
  }
  return best;
};

// Значение свойства-переменной на узле с наследованием от предков.
const customProperty = (rules, node, name, seen) => {
  for (let el = node; el; el = el.parentElement) {
    const decl = winningDeclaration(rules, el, name);
    if (decl) {
      return resolveVars(rules, el, decl.value, seen);
    }
  }
  return null;
};

/**
 * Подставляет var() так, как это сделает браузер на узле. null - значение
 * недействительно (переменной нет и запасного значения тоже).
 */
export const resolveVars = (rules, node, value, seen = []) => {
  let out = '';
  let i = 0;
  while (i < value.length) {
    const at = value.indexOf('var(', i);
    if (at < 0) {
      return out + value.slice(i);
    }
    out += value.slice(i, at);
    const end = closing(value, at + 3);
    const inner = value.slice(at + 4, end);
    const comma = inner.indexOf(',');
    const name = (comma < 0 ? inner : inner.slice(0, comma)).trim();
    const fallback = comma < 0 ? null : inner.slice(comma + 1).trim();
    let resolved = seen.includes(name) ? null
      : customProperty(rules, node, name, [...seen, name]);
    if (resolved === null && fallback !== null) {
      resolved = resolveVars(rules, node, fallback, seen);
    }
    if (resolved === null) {
      return null;
    }
    out += resolved;
    i = end + 1;
  }
  return out;
};

/** [r, g, b, a] из #hex, rgb(), rgba() или transparent; иначе null. */
export const parseColor = text => {
  const value = text.trim().toLowerCase();
  if (value === 'transparent') {
    return [0, 0, 0, 0];
  }
  const hex = value.match(/^#([0-9a-f]{3}|[0-9a-f]{6})$/);
  if (hex) {
    const digits = hex[1].length === 3
      ? hex[1].split('').map(d => d + d) : hex[1].match(/../g);
    return [...digits.map(d => parseInt(d, 16)), 1];
  }
  const rgb = value.match(/^rgba?\(([^)]*)\)$/);
  if (rgb) {
    const parts = rgb[1].split(/[\s,/]+/).filter(Boolean).map(Number);
    return [parts[0], parts[1], parts[2], parts.length > 3 ? parts[3] : 1];
  }
  return null;
};

// Цвет поверх непрозрачной подложки.
export const over = (top, base) => [0, 1, 2]
  .map(k => top[k] * top[3] + base[k] * (1 - top[3])).concat(1);

const luminance = color => {
  const [r, g, b] = color.slice(0, 3).map(c => {
    const s = c / 255;
    return s <= 0.03928 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
  });
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
};

/** Контраст WCAG двух непрозрачных цветов. */
export const contrast = (x, y) => {
  const [hi, lo] = [luminance(x), luminance(y)].sort((a, b) => b - a);
  return (hi + 0.05) / (lo + 0.05);
};

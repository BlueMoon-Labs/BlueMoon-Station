import { dropStrayTint } from './channelsModel';
import { CHANNEL_TYPES, CHAT_ANIM_SPEEDS, CHAT_ANIMATIONS, CHAT_BG_ANIMATIONS, CHAT_STYLES, MESSAGE_STYLE_ANIMATIONS, MESSAGE_STYLE_FONTS, MESSAGE_STYLES, TEXT_GLOW_OPTIONS, TYPE_ANIM_KEYFRAMES } from './constants';

const PREFIX = 'BMCHAT1:';
const MAX_CODE_LENGTH = 20000;
const MAX_FONT_LENGTH = 64;
const HEX_COLOR = /^#[0-9a-fA-F]{6}$/;

const NOT_A_CODE = 'Это не код оформления чата.';
const BROKEN_CODE = 'Код повреждён.';

const isColor = value => value === ''
  || (typeof value === 'string' && HEX_COLOR.test(value));

const isBool = value => typeof value === 'boolean';

const own = (map, key) => (Object.prototype.hasOwnProperty.call(map, key)
  ? map[key] : undefined);

const inRange = (min, max) => value => typeof value === 'number'
  && Number.isFinite(value) && value >= min && value <= max;

const oneOf = list => value => list.some(item => item.id === value);

const isFont = value => typeof value === 'string'
  && value.length <= MAX_FONT_LENGTH;

const pickFields = (entry, checks) => {
  if (!entry || typeof entry !== 'object' || Array.isArray(entry)) {
    return null;
  }
  const picked = {};
  for (const [field, check] of Object.entries(checks)) {
    const value = own(entry, field);
    if (value !== undefined && check(value)) {
      picked[field] = value;
    }
  }
  return picked;
};

const pickEntries = (map, ids, checks) => {
  const picked = {};
  for (const id of ids) {
    const entry = pickFields(own(map, id), checks);
    if (entry && Object.keys(entry).length > 0) {
      picked[id] = entry;
    }
  }
  return picked;
};

const STYLE_FIELDS = {
  color: isColor,
  disabled: isBool,
  font: oneOf(MESSAGE_STYLE_FONTS),
  size: inRange(50, 200),
  anim: oneOf(MESSAGE_STYLE_ANIMATIONS),
};

const TYPE_FIELDS = {
  border: isColor,
  tint: isBool,
  anim: value => value === '' || value === 'none'
    || Object.prototype.hasOwnProperty.call(TYPE_ANIM_KEYFRAMES, value),
  flash: isBool,
};

// Неизвестный id стиля, анимации или фона (пресет из другой версии)
// заменяется умолчанием, а не оставляет игроку его прежний.
const PRESETS = {
  chatStyle: [CHAT_STYLES, 'classic'],
  chatAnimation: [CHAT_ANIMATIONS, 'none'],
  chatBgAnimation: [CHAT_BG_ANIMATIONS, 'none'],
};

// Пределы как у контролов вкладок Основные и Оформление.
const VALUE_CHECKS = {
  fontSize: inRange(8, 32),
  fontFamily: isFont,
  lineHeight: inRange(0.8, 5),
  chatAnimSpeed: oneOf(CHAT_ANIM_SPEEDS),
  chatBgColor: isColor,
  chatTextColor: isColor,
  chatAccentColor: isColor,
  smoothScroll: isBool,
  hoverEffect: isBool,
  chatBgAnimOpacity: inRange(0.05, 1),
  textGlow: oneOf(TEXT_GLOW_OPTIONS),
  textGlowColor: isColor,
  messageSpacing: inRange(0, 10),
  fontWeight: inRange(100, 900),
  letterSpacing: inRange(-0.5, 3),
  borderRadius: inRange(0, 16),
  spanAnimations: isBool,
  settleOldAnimations: isBool,
};

const MAP_PICKERS = {
  styleOverrides: map => pickEntries(
    map, MESSAGE_STYLES.map(style => style.id), STYLE_FIELDS),
  typeOverrides: map => dropStrayTint(pickEntries(
    map, CHANNEL_TYPES.map(channel => channel.type), TYPE_FIELDS)),
};

// Только оформление: подсветка, звук, вкладки и метка новых сообщений
// в код не идут.
export const APPEARANCE_KEYS = [
  'fontSize', 'fontFamily', 'lineHeight',
  'chatStyle', 'chatAnimation', 'chatAnimSpeed',
  'chatBgColor', 'chatTextColor', 'chatAccentColor',
  'smoothScroll', 'hoverEffect', 'chatBgAnimation', 'chatBgAnimOpacity',
  'textGlow', 'textGlowColor', 'messageSpacing', 'fontWeight',
  'letterSpacing', 'borderRadius', 'styleOverrides', 'spanAnimations',
  'typeOverrides', 'settleOldAnimations',
];

const toBase64 = text => btoa(encodeURIComponent(text).replace(
  /%([0-9A-F]{2})/g, (match, hex) => String.fromCharCode(parseInt(hex, 16))));

const fromBase64 = code => decodeURIComponent(Array.from(atob(code),
  ch => '%' + ch.charCodeAt(0).toString(16).padStart(2, '0')).join(''));

export const encodeAppearance = settings => {
  const picked = {};
  for (const key of APPEARANCE_KEYS) {
    if (settings?.[key] !== undefined) {
      picked[key] = key === 'typeOverrides'
        ? dropStrayTint(settings[key]) : settings[key];
    }
  }
  return PREFIX + toBase64(JSON.stringify(picked));
};

const sanitize = data => {
  const settings = {};
  for (const key of APPEARANCE_KEYS) {
    const value = own(data, key);
    if (value === undefined) {
      continue;
    }
    if (PRESETS[key]) {
      const [list, fallback] = PRESETS[key];
      settings[key] = oneOf(list)(value) ? value : fallback;
    }
    else if (MAP_PICKERS[key]) {
      if (value && typeof value === 'object' && !Array.isArray(value)) {
        settings[key] = MAP_PICKERS[key](value);
      }
    }
    else if (VALUE_CHECKS[key](value)) {
      settings[key] = value;
    }
  }
  return settings;
};

export const decodeAppearance = code => {
  const text = typeof code === 'string' ? code.replace(/\s+/g, '') : '';
  if (!text.startsWith(PREFIX)) {
    return { ok: false, error: NOT_A_CODE };
  }
  if (text.length > MAX_CODE_LENGTH) {
    return { ok: false, error: BROKEN_CODE };
  }
  let data;
  try {
    data = JSON.parse(fromBase64(text.slice(PREFIX.length)));
  }
  catch {
    return { ok: false, error: BROKEN_CODE };
  }
  if (!data || typeof data !== 'object' || Array.isArray(data)) {
    return { ok: false, error: BROKEN_CODE };
  }
  return { ok: true, settings: sanitize(data) };
};

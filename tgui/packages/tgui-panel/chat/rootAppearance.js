import { CHAT_ANIM_SPEEDS, GAME_EFFECTS, MESSAGE_STYLES } from '../settings/constants';
import { RADIO_JOB_COLOR_MODES, RADIO_JOB_HEAD_MARKS, RADIO_JOB_IDS } from '../settings/radioJobs';

/**
 * Значения, которые ставятся на корень .Chat: и чату, и предпросмотру
 * в настройках. null - свойство снять.
 */

export const getChatCustomProps = settings => {
  const speedDef = CHAT_ANIM_SPEEDS.find(
    s => s.id === settings.chatAnimSpeed);
  let glowValue = null;
  const glowColor = settings.textGlowColor
    || settings.chatAccentColor || '#ffdd44';
  if (settings.textGlow === 'subtle') {
    glowValue = '0 0 4px ' + glowColor;
  }
  else if (settings.textGlow === 'strong') {
    glowValue = '0 0 10px ' + glowColor
      + ', 0 0 20px ' + glowColor;
  }
  return {
    '--chat-anim-speed': speedDef?.value || '320ms',
    '--chat-glow': glowValue,
    '--chat-msg-spacing': settings.messageSpacing + 'px',
    '--chat-font-weight': String(settings.fontWeight),
    '--chat-letter-spacing': settings.letterSpacing + 'px',
    '--chat-border-radius': settings.borderRadius + 'px',
  };
};

export const getChatColorProps = (bgColor, textColor, accentColor) => ({
  '--chat-bg': bgColor || null,
  '--chat-text': textColor || null,
  '--chat-accent': accentColor || null,
});

/**
 * Стили текста на корне: цвет через --cs-<id>-color, "обычный текст"
 * через Chat--plain-<id>, общий выключатель анимаций Chat--fxAnimOff.
 * Свойства перечислены для всех стилей, чтобы снять устаревшие.
 */
export const getStyleOverrideRoot = (overrides = {}, spanAnimations = true) => {
  const classes = [];
  const props = {};
  if (!spanAnimations) {
    classes.push('Chat--fxAnimOff');
  }
  for (const style of MESSAGE_STYLES) {
    const override = overrides?.[style.id];
    props['--cs-' + style.id + '-color'] = override?.color || null;
    if (override?.disabled) {
      classes.push('Chat--plain-' + style.id);
    }
  }
  return { classes, props };
};

export const isStyleOverrideClass = cls => cls.startsWith('Chat--plain-')
  || cls === 'Chat--fxAnimOff';

/**
 * Выключатели игровых эффектов: Chat--gameFxOff гасит все,
 * Chat--fxOff-<id> - один эффект из GAME_EFFECTS.
 */
export const getGameFxRootClasses = (effects = {}, enabled = true) => {
  if (enabled === false) {
    return ['Chat--gameFxOff'];
  }
  return GAME_EFFECTS
    .filter(effect => effects?.[effect.id] === false)
    .map(effect => 'Chat--fxOff-' + effect.id);
};

// Затухание анимаций истории выключено.
export const SETTLE_OFF_CLASS = 'Chat--noSettle';

export const getSettleRootClasses = enabled => (
  enabled === false ? [SETTLE_OFF_CLASS] : []);

export const isGameFxRootClass = cls => cls === 'Chat--gameFxOff'
  || cls.startsWith('Chat--fxOff-');

const RADIO_JOB_MODE_CLASS = {
  legacy: 'Chat--rjLegacy',
  none: 'Chat--rjNoColor',
};

const HEX_COLOR = /^#[0-9a-fA-F]{6}$/;

/**
 * Теги должностей в рации: режим цвета, метка глав, имя в цвет отдела,
 * значок профессии и свои цвета --rj-<id>. Свойства перечислены для всех id, чтобы снять
 * сброшенные.
 */
export const getRadioJobRoot = (settings = {}) => {
  const classes = [];
  const mode = RADIO_JOB_COLOR_MODES.some(
    entry => entry.id === settings.radioJobColorMode)
    ? settings.radioJobColorMode : 'department';
  if (RADIO_JOB_MODE_CLASS[mode]) {
    classes.push(RADIO_JOB_MODE_CLASS[mode]);
  }
  const headMark = RADIO_JOB_HEAD_MARKS.some(
    entry => entry.id === settings.radioJobHeadMark)
    ? settings.radioJobHeadMark : 'icon';
  if (headMark !== 'none') {
    classes.push('Chat--rjHead-' + headMark);
  }
  if (settings.radioJobColorNames) {
    classes.push('Chat--rjNames');
  }
  if (settings.radioJobIcons === false) {
    classes.push('Chat--rjNoIcon');
  }
  const props = {};
  for (const id of RADIO_JOB_IDS) {
    const color = settings.radioJobColors?.[id];
    props['--rj-' + id] = HEX_COLOR.test(color || '') ? color : null;
  }
  return { classes, props };
};

export const isRadioJobRootClass = cls => cls.startsWith('Chat--rj');

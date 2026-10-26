import { CHAT_ANIM_SPEEDS, MESSAGE_STYLES } from '../settings/constants';

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

// Затухание анимаций истории выключено.
export const SETTLE_OFF_CLASS = 'Chat--noSettle';

export const getSettleRootClasses = enabled => (
  enabled === false ? [SETTLE_OFF_CLASS] : []);

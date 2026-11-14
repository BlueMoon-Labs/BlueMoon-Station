import { CHANNEL_TYPES, TYPE_ANIM_KEYFRAMES } from '../settings/constants';

const HEX_COLOR = /^#[0-9a-fA-F]{6}$/;

// Кривая каждой анимации появления; классы ChatMessage--anim-<id> в
// ChatCustomization.scss и ChatPresets.scss пишут ту же строку
// animation, это сверяет typeOverrides.test.js.
export const TYPE_ANIM_TIMING = {
  fadein: 'cubic-bezier(0.2, 0.65, 0.3, 1)',
  slidein: 'cubic-bezier(0.16, 1, 0.3, 1)',
  bounce: 'cubic-bezier(0.3, 0.7, 0.4, 1)',
  drop: 'cubic-bezier(0.25, 0.8, 0.4, 1)',
  zoomin: 'cubic-bezier(0.22, 0.61, 0.36, 1)',
  pop: 'cubic-bezier(0.3, 0.7, 0.4, 1)',
  glowin: 'cubic-bezier(0.2, 0.6, 0.3, 1)',
  teletype: 'linear',
  faxfeed: 'cubic-bezier(0.25, 0.75, 0.35, 1)',
  interference: 'linear',
  crtscan: 'cubic-bezier(0.2, 0.7, 0.3, 1)',
  airlock: 'cubic-bezier(0.7, 0, 0.3, 1)',
  develop: 'cubic-bezier(0.3, 0.6, 0.4, 1)',
  scanner: 'cubic-bezier(0.4, 0, 0.6, 1)',
  lamp: 'linear',
};

// Печать и мигание лампы читаются дольше остальных, но не дольше
// TYPE_ANIM_MAX_MS даже на скорости "Медленно".
export const TYPE_ANIM_DURATION_SCALE = {
  teletype: 1.5,
  lamp: 1.6,
};

export const TYPE_ANIM_MAX_MS = 600;

const ANIM_SPEED = 'var(--chat-anim-speed, 320ms)';

const animDuration = anim => (TYPE_ANIM_DURATION_SCALE[anim]
  ? 'min(' + ANIM_SPEED + ' * ' + TYPE_ANIM_DURATION_SCALE[anim] + ', '
    + TYPE_ANIM_MAX_MS + 'ms)'
  : ANIM_SPEED);

/** Значение animation для анимации появления или null. */
export const typeAnimationValue = anim => {
  if (!Object.prototype.hasOwnProperty.call(TYPE_ANIM_KEYFRAMES, anim)) {
    return null;
  }
  return TYPE_ANIM_KEYFRAMES[anim] + ' ' + animDuration(anim) + ' '
    + TYPE_ANIM_TIMING[anim];
};

export const hexToRgba = (hex, alpha) => {
  if (typeof hex !== 'string' || !HEX_COLOR.test(hex)) {
    return null;
  }
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return 'rgba(' + r + ', ' + g + ', ' + b + ', ' + alpha + ')';
};

/**
 * CSS для вкладки "Каналы". Полоска (0,4,0) из-за :not(), анимация
 * (0,3,0): обе выше классов анимации появления (0,1,0).
 */
export const buildTypeOverrideCss = overrides => {
  let css = '';
  for (const { type } of CHANNEL_TYPES) {
    const entry = overrides?.[type];
    if (!entry) {
      continue;
    }
    const selector = '.Chat .ChatMessage.ChatMessage--type-' + type;
    const border = typeof entry.border === 'string'
      && HEX_COLOR.test(entry.border) ? entry.border : null;
    if (border) {
      // --type-stripe: стиль со своей полосой слева прячет её под этой.
      const stripe = ['border-left: 3px solid ' + border + ';',
        '--type-stripe: 1;',
        'padding-left: var(--type-stripe-pad, 6px);'];
      if (entry.tint) {
        stripe.push('background-color: ' + hexToRgba(border, 0.08) + ';');
      }
      css += selector + ':not(.ChatMessage--highlighted) { '
        + stripe.join(' ') + ' }\n';
    }
    const decls = [];
    const animValue = entry.anim === 'none'
      ? 'none' : typeAnimationValue(entry.anim);
    if (animValue) {
      // --enter-anim встряска и качка ставят рядом со своей анимацией.
      decls.push('animation: ' + animValue + ';',
        '--enter-anim: ' + animValue + ';');
      // Полоса сканера живёт на ::after: включаем свою или гасим общую.
      // Селектор свежести тот же, что у общего правила, плюс класс типа:
      // подавление этим сильнее его по специфичности.
      const fresh = selector + ':not(.ChatMessage--highlighted)'
        + ':not(.Chat:not(.Chat--noSettle) .ChatMessage--settled)';
      if (entry.anim === 'scanner') {
        css += fresh + ' { position: relative; }\n'
          + fresh + '::after { content: \'\'; animation: chatScannerBar '
          + animDuration('scanner') + ' ' + TYPE_ANIM_TIMING.scanner + '; }\n';
      }
      else {
        css += fresh + '::after { content: none; animation: none; }\n';
      }
    }
    if (entry.flash) {
      decls.push('position: relative;');
    }
    if (decls.length > 0) {
      css += selector + ' { ' + decls.join(' ') + ' }\n';
    }
    if (entry.flash) {
      const flashColor = (border && hexToRgba(border, 0.35))
        || 'rgba(255, 221, 68, 0.35)';
      css += selector + '::before { content: \'\'; position: absolute;'
        + ' inset: 0; pointer-events: none; background-color: '
        + flashColor + '; opacity: 0;'
        + ' animation: chatTypeFlash 900ms ease-out 1; }\n';
    }
  }
  return css;
};

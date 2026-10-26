/**
 * Блочные эффекты сообщения: transform допустим только на блоке
 * .ChatMessage, на инлайн-спане он ломает перенос строк.
 */
export const BLOCK_FX = [
  { selector: '.yell', fx: 'shake' },
  { selector: '.hear_dizzy', fx: 'sway' },
];

export const getBlockFxClasses = node => {
  const result = [];
  for (const { selector, fx } of BLOCK_FX) {
    if (node.querySelector(selector)) {
      result.push('ChatMessage--fx-' + fx);
    }
  }
  return result;
};

// Сколько последних видимых сообщений держат свои анимации.
export const SETTLE_KEEP = 40;

/**
 * Гасит анимации у сообщений старше SETTLE_KEEP последних.
 * Без fullPass идёт с конца окна назад до первого уже погашенного.
 * Полный проход (смена вкладки) ещё и будит окно свежих.
 */
export const settleOldMessages = (messages, fullPass) => {
  if (fullPass) {
    for (let i = Math.max(0, messages.length - SETTLE_KEEP);
      i < messages.length; i++) {
      const node = messages[i].node;
      if (node && node !== 'pruned') {
        node.classList.remove('ChatMessage--settled');
      }
    }
  }
  for (let i = messages.length - SETTLE_KEEP - 1; i >= 0; i--) {
    const node = messages[i].node;
    if (!node || node === 'pruned') {
      continue;
    }
    if (node.classList.contains('ChatMessage--settled')) {
      if (!fullPass) {
        return;
      }
      continue;
    }
    node.classList.add('ChatMessage--settled');
  }
};

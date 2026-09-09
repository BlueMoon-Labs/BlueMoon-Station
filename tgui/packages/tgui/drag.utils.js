/**
 * @file
 * Pure utility functions extracted from drag.js for testability.
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

/**
 * Checks if the current window size matches the target size
 * within an epsilon tolerance that scales with pixel ratio.
 *
 * @param {[number, number]} targetSize Target [width, height] in physical pixels
 * @param {[number, number]} currentSize Current [width, height] in physical pixels
 * @param {number} pixelRatio Device pixel ratio
 * @returns {boolean}
 */
export const isWindowSizeApplied = (targetSize, currentSize, pixelRatio) => {
  const epsilon = Math.max(2, Math.ceil(pixelRatio * 2));
  return Math.abs(currentSize[0] - targetSize[0]) <= epsilon
    && Math.abs(currentSize[1] - targetSize[1]) <= epsilon;
};

/**
 * Normalizes whatever `Byond.winget(id, 'size')` hands back into [width, height].
 *
 * BYOND returns coordinate properties as an object ({x, y}), the same shape `pos` arrives in.
 * The original code ran the value through String() and split on /[x,]/, which turns an object
 * into "[object Object]" — no 'x', no comma, so the length check never passed and the winget
 * channel was dead code. That channel is the only one that can work at all while the window is
 * still hidden, which is exactly when the reveal gate needs it.
 *
 * Returns null when the value cannot be read as a pair of finite numbers.
 *
 * @param {unknown} size Raw winget response
 * @returns {[number, number] | null}
 */
export const parseWingetSize = size => {
  if (!size) {
    return null;
  }
  let pair;
  if (typeof size === 'object') {
    pair = Array.isArray(size)
      ? [Number(size[0]), Number(size[1])]
      : [Number(size.x), Number(size.y)];
  }
  else {
    pair = String(size).split(/[x,]/).map(Number);
  }
  if (pair.length !== 2 || !Number.isFinite(pair[0]) || !Number.isFinite(pair[1])) {
    return null;
  }
  return pair;
};

/**
 * Moves an item to the top of the recents array, and keeps its length
 * limited to the number in `limit` argument.
 *
 * Uses a strict equality check for comparisons.
 *
 * Returns new recents and an item which was trimmed.
 */
export const touchRecents = (recents, touchedItem, limit = 50) => {
  const nextRecents = [touchedItem];
  let trimmedItem;
  for (let i = 0; i < recents.length; i++) {
    const item = recents[i];
    if (item === touchedItem) {
      continue;
    }
    if (nextRecents.length < limit) {
      nextRecents.push(item);
    }
    else {
      trimmedItem = item;
    }
  }
  return [nextRecents, trimmedItem];
};

/**
 * Constraints window position to safe screen area.
 *
 * @param {[number, number]} pos Window position
 * @param {[number, number]} size Window size
 * @param {[number, number]} screenPos Screen position (top-left of available area)
 * @param {[number, number]} screenSize Screen dimensions
 * @returns {[boolean, [number, number]]} [relocated, newPosition]
 */
export const constraintPosition = (pos, size, screenPos, screenSize) => {
  const nextPos = [pos[0], pos[1]];
  let relocated = false;
  for (let i = 0; i < 2; i++) {
    const leftBoundary = screenPos[i];
    const rightBoundary = screenPos[i] + screenSize[i];
    if (pos[i] < leftBoundary) {
      nextPos[i] = leftBoundary;
      relocated = true;
    }
    else if (pos[i] + size[i] > rightBoundary) {
      nextPos[i] = rightBoundary - size[i];
      relocated = true;
    }
  }
  return [relocated, nextPos];
};

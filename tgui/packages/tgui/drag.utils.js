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

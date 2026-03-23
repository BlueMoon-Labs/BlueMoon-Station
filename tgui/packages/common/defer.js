/**
 * Schedules callback execution on the next microtask.
 *
 * @param {Function} callback
 * @param {...any} args
 */
export const defer = (callback, ...args) => {
  queueMicrotask(() => callback(...args));
};

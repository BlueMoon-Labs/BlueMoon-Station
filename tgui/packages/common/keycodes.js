/**
 * Keyboard key constants based on the KeyboardEvent.key API.
 *
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

export const KEY_BACKSPACE = 'Backspace';
export const KEY_TAB = 'Tab';
export const KEY_ENTER = 'Enter';
export const KEY_SHIFT = 'Shift';
export const KEY_CTRL = 'Control';
export const KEY_ALT = 'Alt';
export const KEY_PAUSE = 'Pause';
export const KEY_CAPSLOCK = 'CapsLock';
export const KEY_ESCAPE = 'Escape';
export const KEY_SPACE = ' ';
export const KEY_PAGEUP = 'PageUp';
export const KEY_PAGEDOWN = 'PageDown';
export const KEY_END = 'End';
export const KEY_HOME = 'Home';
export const KEY_LEFT = 'ArrowLeft';
export const KEY_UP = 'ArrowUp';
export const KEY_RIGHT = 'ArrowRight';
export const KEY_DOWN = 'ArrowDown';
export const KEY_INSERT = 'Insert';
export const KEY_DELETE = 'Delete';
export const KEY_F1 = 'F1';
export const KEY_F2 = 'F2';
export const KEY_F3 = 'F3';
export const KEY_F4 = 'F4';
export const KEY_F5 = 'F5';
export const KEY_F6 = 'F6';
export const KEY_F7 = 'F7';
export const KEY_F8 = 'F8';
export const KEY_F9 = 'F9';
export const KEY_F10 = 'F10';
export const KEY_F11 = 'F11';
export const KEY_F12 = 'F12';

/**
 * Returns true if the given key is a single alphabetic character (a-z, A-Z).
 *
 * @param {string} key - The KeyboardEvent.key value
 * @returns {boolean}
 */
export const isAlphaKey = (key) => key.length === 1 && /[a-zA-Z]/.test(key);

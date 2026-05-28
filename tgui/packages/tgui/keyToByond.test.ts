import { keyToByond } from './keyToByond';

const byond = (key: string, code: string) => keyToByond({ key, code });

describe('keyToByond', () => {
  test.each([
    ['w on QWERTY', 'w', 'KeyW', 'W'],
    ['W uppercase', 'W', 'KeyW', 'W'],
    ['Cyrillic layout physical W', 'ц', 'KeyW', 'W'],
    ['German QWERTZ physical Y', 'z', 'KeyY', 'Y'],
    ['A movement key', 'a', 'KeyA', 'A'],
    ['S movement key', 's', 'KeyS', 'S'],
    ['D movement key', 'd', 'KeyD', 'D'],
    ['Digit1 physical key', '!', 'Digit1', '1'],
    ['Digit0 physical key', ')', 'Digit0', '0'],
    ['Numpad1', '1', 'Numpad1', 'Numpad1'],
    ['Numpad9', '9', 'Numpad9', 'Numpad9'],
    ['ArrowLeft', 'ArrowLeft', 'ArrowLeft', 'West'],
    ['ArrowUp', 'ArrowUp', 'ArrowUp', 'North'],
    ['ArrowRight', 'ArrowRight', 'ArrowRight', 'East'],
    ['ArrowDown', 'ArrowDown', 'ArrowDown', 'South'],
    ['PageUp', 'PageUp', 'PageUp', 'Northeast'],
    ['PageDown', 'PageDown', 'PageDown', 'Southeast'],
    ['End', 'End', 'End', 'Southwest'],
    ['Home', 'Home', 'Home', 'Northwest'],
    ['Shift', 'Shift', 'ShiftLeft', 'Shift'],
    ['Control', 'Control', 'ControlLeft', 'Ctrl'],
    ['Alt', 'Alt', 'AltLeft', 'Alt'],
    ['Insert', 'Insert', 'Insert', 'Insert'],
    ['Delete', 'Delete', 'Delete', 'Delete'],
    ['F1', 'F1', 'F1', 'F1'],
    ['F12', 'F12', 'F12', 'F12'],
    ['Comma physical key', '<', 'Comma', ','],
    ['Minus physical key', '_', 'Minus', '-'],
    ['Period physical key', '>', 'Period', '.'],
  ])('%s maps to %s', (_name, key, code, expected) => {
    expect(byond(key, code)).toBe(expected);
  });

  test.each([
    ['Backspace', 'Backspace'],
    ['CapsLock', 'CapsLock'],
    ['IntlBackslash', 'IntlBackslash'],
    ['Slash', 'Slash'],
    ['Space', 'Space'],
  ])('%s is intentionally not mapped', (key, code) => {
    expect(byond(key, code)).toBeUndefined();
  });
});

import {
  isAlphaKey,
  KEY_ALT,
  KEY_BACKSPACE,
  KEY_CTRL,
  KEY_DOWN,
  KEY_ENTER,
  KEY_ESCAPE,
  KEY_F1,
  KEY_F12,
  KEY_LEFT,
  KEY_RIGHT,
  KEY_SHIFT,
  KEY_SPACE,
  KEY_TAB,
  KEY_UP,
} from './keycodes';

describe('isAlphaKey', () => {
  test('строчные латинские буквы a-z -> true', () => {
    expect(isAlphaKey('a')).toBe(true);
    expect(isAlphaKey('m')).toBe(true);
    expect(isAlphaKey('z')).toBe(true);
  });

  test('заглавные латинские буквы A-Z -> true', () => {
    expect(isAlphaKey('A')).toBe(true);
    expect(isAlphaKey('M')).toBe(true);
    expect(isAlphaKey('Z')).toBe(true);
  });

  test('цифры -> false', () => {
    expect(isAlphaKey('0')).toBe(false);
    expect(isAlphaKey('5')).toBe(false);
    expect(isAlphaKey('9')).toBe(false);
  });

  test('специальные клавиши (длинные строки) -> false', () => {
    expect(isAlphaKey('Enter')).toBe(false);
    expect(isAlphaKey('Shift')).toBe(false);
    expect(isAlphaKey('Backspace')).toBe(false);
    expect(isAlphaKey('ArrowLeft')).toBe(false);
  });

  test('пробел -> false', () => {
    expect(isAlphaKey(' ')).toBe(false);
  });

  test('пустая строка -> false', () => {
    expect(isAlphaKey('')).toBe(false);
  });

  test('спецсимволы -> false', () => {
    expect(isAlphaKey('!')).toBe(false);
    expect(isAlphaKey('@')).toBe(false);
    expect(isAlphaKey('+')).toBe(false);
    expect(isAlphaKey('-')).toBe(false);
    expect(isAlphaKey('/')).toBe(false);
  });

  test('кириллица -> false (только латиница в regex [a-zA-Z])', () => {
    expect(isAlphaKey('я')).toBe(false);
    expect(isAlphaKey('А')).toBe(false);
    expect(isAlphaKey('ё')).toBe(false);
  });

  test('Unicode символ длиной > 1 (emoji) -> false', () => {
    // Emoji — surrogate pair, length = 2
    expect(isAlphaKey('😀')).toBe(false);
  });
});

describe('экспортированные константы клавиш', () => {
  test('KEY_SPACE — пробел', () => {
    expect(KEY_SPACE).toBe(' ');
  });

  test('KEY_ENTER — "Enter"', () => {
    expect(KEY_ENTER).toBe('Enter');
  });

  test('KEY_ESCAPE — "Escape"', () => {
    expect(KEY_ESCAPE).toBe('Escape');
  });

  test('KEY_TAB — "Tab"', () => {
    expect(KEY_TAB).toBe('Tab');
  });

  test('модификаторы имеют стандартные KeyboardEvent.key значения', () => {
    expect(KEY_SHIFT).toBe('Shift');
    expect(KEY_CTRL).toBe('Control');
    expect(KEY_ALT).toBe('Alt');
  });

  test('стрелки используют Arrow-префикс', () => {
    expect(KEY_LEFT).toBe('ArrowLeft');
    expect(KEY_UP).toBe('ArrowUp');
    expect(KEY_RIGHT).toBe('ArrowRight');
    expect(KEY_DOWN).toBe('ArrowDown');
  });

  test('F-клавиши', () => {
    expect(KEY_F1).toBe('F1');
    expect(KEY_F12).toBe('F12');
  });

  test('KEY_BACKSPACE — "Backspace"', () => {
    expect(KEY_BACKSPACE).toBe('Backspace');
  });
});

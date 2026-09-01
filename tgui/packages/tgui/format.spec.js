import {
  formatDb,
  formatMoney,
  formatPower,
  formatSiBaseTenUnit,
  formatSiUnit,
  formatTime,
} from './format';

describe('formatSiUnit', () => {
  test('единицы (< 1000)', () => {
    const result = formatSiUnit(42);
    // scaledPrecision = 2 + 0*3 - 1 = 1 -> toFixed(42, 1) = "42.0"
    expect(result).toBe('42.0');
  });

  test('кило (1000)', () => {
    expect(formatSiUnit(1000)).toBe('1.00 k');
  });

  test('мега (1e6)', () => {
    expect(formatSiUnit(1000000)).toBe('1.00 M');
  });

  test('гига (1e9)', () => {
    expect(formatSiUnit(1e9)).toBe('1.00 G');
  });

  test('дробные значения', () => {
    expect(formatSiUnit(1500)).toBe('1.50 k');
    expect(formatSiUnit(2500000)).toBe('2.50 M');
  });

  test('с unit суффиксом', () => {
    expect(formatSiUnit(1000, 0, 'W')).toContain('W');
    expect(formatSiUnit(1000, 0, 'W')).toBe('1.00 kW');
  });

  test('не-число возвращается как есть', () => {
    expect(formatSiUnit('hello')).toBe('hello');
  });

  test('Infinity возвращается как есть', () => {
    expect(formatSiUnit(Infinity)).toBe(Infinity);
  });

  test('NaN возвращается как есть', () => {
    expect(formatSiUnit(NaN)).toBe(NaN);
  });

  test('милли-значения', () => {
    const result = formatSiUnit(0.005);
    expect(result).toContain('m');
  });
});

describe('formatPower', () => {
  test('добавляет суффикс W', () => {
    expect(formatPower(1000)).toBe('1.00 kW');
  });

  test('мегаватты', () => {
    expect(formatPower(1e6)).toBe('1.00 MW');
  });
});

describe('formatMoney', () => {
  test('целое число без разделителей', () => {
    expect(formatMoney(100)).toBe('100');
  });

  test('тысячи — thin space разделитель по умолчанию', () => {
    const result = formatMoney(1000);
    expect(result).toBe('1\u2009000');
  });

  test('миллионы', () => {
    const result = formatMoney(1000000);
    expect(result).toBe('1\u2009000\u2009000');
  });

  test('с запятыми (addCommas=true)', () => {
    expect(formatMoney(1000000, 0, true)).toBe('1,000,000');
  });

  test('маленькие числа — без разделителей', () => {
    expect(formatMoney(999)).toBe('999');
  });

  test('Infinity -> Infinity', () => {
    expect(formatMoney(Infinity)).toBe(Infinity);
  });

  test('отрицательное число', () => {
    const result = formatMoney(-1000);
    // Отрицательный знак + разделитель
    expect(result).toContain('-');
    expect(result).toContain('1');
  });

  // BUG: precision > 0 — round() результат перезаписывается toFixed(original value)
  // Строка 81: fixed = round(value, precision) — округляет
  // Строка 83: fixed = toFixed(value, precision) — перезаписывает из ОРИГИНАЛЬНОГО value
  test('precision > 0 с десятичными', () => {
    const result = formatMoney(1234.5, 2);
    // С thin space разделителем: "1 234.50"
    expect(result).toBe('1\u2009234.50');
  });

  // BUG: precision > 0 — toFixed(value) вместо toFixed(rounded)
  // round(1.005, 2) = 1.01 (robust rounding), но toFixed(1.005, 2) = "1.00" (IEEE 754 glitch)
  test('precision > 0 использует rounded значение, а не оригинал', () => {
    const rounded = formatMoney(1.005, 2);
    expect(rounded).toBe('1.01');
  });
});

describe('formatDb', () => {
  test('1 -> +0.00 dB (unity gain)', () => {
    expect(formatDb(1)).toBe('+0.00 dB');
  });

  test('10 -> +20.00 dB', () => {
    expect(formatDb(10)).toBe('+20.00 dB');
  });

  test('100 -> +40.00 dB', () => {
    expect(formatDb(100)).toBe('+40.00 dB');
  });

  test('0.1 -> отрицательные dB', () => {
    const result = formatDb(0.1);
    expect(result).toMatch(/^–\d+\.\d+ dB$/);
  });

  test('0 -> -Inf dB', () => {
    expect(formatDb(0)).toBe('–Inf dB');
  });

  test('значение > 1 -> положительный знак', () => {
    expect(formatDb(2)).toMatch(/^\+/);
  });

  test('значение < 1 -> отрицательный знак (–)', () => {
    expect(formatDb(0.5)).toMatch(/^–/);
  });
});

describe('formatTime', () => {
  test('default формат — HH:MM:SS с padding', () => {
    // 130 десятисекунд = 13 секунд
    expect(formatTime(130)).toBe('00:00:13');
  });

  test('минуты и секунды', () => {
    // 10 * 60 * 2 + 10 * 30 = 1200 + 300 = 1500 десятисекунд = 2m 30s
    expect(formatTime(1500)).toBe('00:02:30');
  });

  test('часы, минуты и секунды', () => {
    // 1 час + 30 минут + 45 секунд = 10*3600 + 10*1800 + 10*45 = 54450
    expect(formatTime(54450)).toBe('01:30:45');
  });

  test('short формат — без нулевых компонентов', () => {
    // 300 десятисекунд = 30 секунд
    expect(formatTime(300, 'short')).toBe('30s');
  });

  test('short формат — минуты и секунды', () => {
    // 10*60 + 10*5 = 650 десятисекунд = 1m 5s
    expect(formatTime(650, 'short')).toBe('1m5s');
  });

  test('short формат — только минуты (0 секунд)', () => {
    // 10 * 60 * 5 = 3000 десятисекунд = 5m 0s
    expect(formatTime(3000, 'short')).toBe('5m');
  });

  // BUG: formatTime(0, "short") возвращает "" вместо "0s"
  test('short формат — 0 должен отобразить "0s"', () => {
    expect(formatTime(0, 'short')).toBe('0s');
  });

  test('default формат — 0 отображает 00:00:00', () => {
    expect(formatTime(0)).toBe('00:00:00');
  });
});

describe('formatSiBaseTenUnit', () => {
  // BUG: SI_BASE_TEN_INDEX = SI_BASE_TEN_UNIT.indexOf(' ') возвращает -1,
  // потому что в массиве первый элемент — пустая строка '' а не пробел ' '.
  // Из-за этого minBase1000 = -(-1) = 1, и значения < 1000 масштабируются
  // как кило: value / 1000, а затем toFixed с precision 0 -> "0".

  // BUG: SI_BASE_TEN_INDEX = SI_BASE_TEN_UNIT.indexOf(' ') = -1
  // (в массиве '' а не ' '), сдвигает ВСЕ SI-тиры на один вниз.
  // Сейчас: 42->"0", 1000->"1" (без SI), 1e6->"· 10³" (вместо · 10⁶)

  test('BUG: значение 42 — должно содержать "42"', () => {
    expect(formatSiBaseTenUnit(42)).toContain('42');
  });

  test('BUG: значение 999 — должно содержать "999"', () => {
    expect(formatSiBaseTenUnit(999)).toContain('999');
  });

  test('BUG: значение 1 — должно содержать "1"', () => {
    const result = formatSiBaseTenUnit(1);
    expect(result).toMatch(/^1/);
  });

  test('BUG: кило (1000) — должно содержать "· 10³"', () => {
    expect(formatSiBaseTenUnit(1000)).toContain('10³');
  });

  test('BUG: мега (1e6) — должно содержать "· 10⁶"', () => {
    expect(formatSiBaseTenUnit(1e6)).toContain('10⁶');
  });

  test('BUG: гига (1e9) — должно содержать "· 10⁹"', () => {
    expect(formatSiBaseTenUnit(1e9)).toContain('10⁹');
  });

  test('BUG: дробные кило (1500) — должно быть "1.50 · 10³"', () => {
    const result = formatSiBaseTenUnit(1500);
    expect(result).toContain('1.50');
    expect(result).toContain('10³');
  });

  test('BUG: с unit суффиксом (1000W) — должно содержать "· 10³" и "W"', () => {
    const result = formatSiBaseTenUnit(1000, 0, 'W');
    expect(result).toContain('W');
    expect(result).toContain('10³');
  });

  test('не-число возвращается как есть', () => {
    expect(formatSiBaseTenUnit('hello')).toBe('hello');
  });

  test('Infinity возвращается как есть', () => {
    expect(formatSiBaseTenUnit(Infinity)).toBe(Infinity);
  });

  test('NaN возвращается как есть', () => {
    expect(formatSiBaseTenUnit(NaN)).toBe(NaN);
  });

  test('с явным minBase1000=0 — обходит баг для базовых значений', () => {
    // При minBase1000=0 значения < 1000 показываются без масштабирования
    const result = formatSiBaseTenUnit(42, 0);
    expect(result).toContain('42');
  });
});

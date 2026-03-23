import {
  clamp,
  clamp01,
  inRange,
  keyOfMatchingRange,
  numberOfDecimalDigits,
  round,
  scale,
  toFixed,
} from './math';

describe('clamp', () => {
  test('возвращает значение внутри диапазона без изменений', () => {
    expect(clamp(5, 0, 10)).toBe(5);
  });

  test('ограничивает значение снизу', () => {
    expect(clamp(-5, 0, 10)).toBe(0);
  });

  test('ограничивает значение сверху', () => {
    expect(clamp(15, 0, 10)).toBe(10);
  });

  test('граничные значения — min и max возвращаются как есть', () => {
    expect(clamp(0, 0, 10)).toBe(0);
    expect(clamp(10, 0, 10)).toBe(10);
  });

  test('min === max — всегда возвращает это значение', () => {
    expect(clamp(5, 3, 3)).toBe(3);
    expect(clamp(1, 3, 3)).toBe(3);
  });

  test('отрицательный диапазон', () => {
    expect(clamp(-5, -10, -1)).toBe(-5);
    expect(clamp(0, -10, -1)).toBe(-1);
    expect(clamp(-20, -10, -1)).toBe(-10);
  });
});

describe('clamp01', () => {
  test('значение внутри [0,1] без изменений', () => {
    expect(clamp01(0.5)).toBe(0.5);
  });

  test('отрицательное -> 0', () => {
    expect(clamp01(-1)).toBe(0);
  });

  test('больше 1 -> 1', () => {
    expect(clamp01(2)).toBe(1);
  });

  test('граничные значения', () => {
    expect(clamp01(0)).toBe(0);
    expect(clamp01(1)).toBe(1);
  });
});

describe('scale', () => {
  test('нормализует значение в диапазоне [min, max] к [0, 1]', () => {
    expect(scale(5, 0, 10)).toBe(0.5);
    expect(scale(0, 0, 10)).toBe(0);
    expect(scale(10, 0, 10)).toBe(1);
  });

  test('значение за пределами диапазона — экстраполяция', () => {
    expect(scale(20, 0, 10)).toBe(2);
    expect(scale(-10, 0, 10)).toBe(-1);
  });

  test('min === max -> деление на ноль -> Infinity/NaN', () => {
    expect(scale(5, 5, 5)).toBe(NaN);
  });

  test('отрицательный диапазон', () => {
    expect(scale(-5, -10, 0)).toBe(0.5);
  });
});

describe('round', () => {
  test('округление до целого', () => {
    expect(round(3.7, 0)).toBe(4);
    expect(round(3.2, 0)).toBe(3);
  });

  test('округление с precision', () => {
    expect(round(3.456, 2)).toBe(3.46);
    expect(round(3.454, 2)).toBe(3.45);
  });

  test('.5 округляется от нуля (away from zero)', () => {
    expect(round(2.5, 0)).toBe(3);
    expect(round(-2.5, 0)).toBe(-3);
  });

  test('отрицательные числа', () => {
    expect(round(-3.7, 0)).toBe(-4);
    expect(round(-3.2, 0)).toBe(-3);
  });

  test('0 возвращается как 0 (short-circuit через !value)', () => {
    expect(round(0, 2)).toBe(0);
  });

  test('NaN возвращается как NaN', () => {
    expect(round(NaN, 2)).toBeNaN();
  });

  test('undefined возвращается как undefined', () => {
    expect(round(undefined, 2)).toBeUndefined();
  });

  test('отрицательный precision — округление до десятков/сотен', () => {
    expect(round(1234, -2)).toBe(1200);
  });

  test('большие числа', () => {
    expect(round(999999.5, 0)).toBe(1000000);
  });
});

describe('toFixed', () => {
  test('фиксирует количество десятичных знаков', () => {
    expect(toFixed(3.14159, 2)).toBe('3.14');
  });

  test('0 знаков после запятой', () => {
    expect(toFixed(3.7, 0)).toBe('4');
  });

  test('отрицательный fractionDigits -> 0', () => {
    expect(toFixed(3.14, -1)).toBe('3');
  });

  test('дополняет нулями', () => {
    expect(toFixed(3, 3)).toBe('3.000');
  });
});

describe('inRange', () => {
  test('значение внутри диапазона', () => {
    expect(inRange(5, [0, 10])).toBe(true);
  });

  test('значение на границах', () => {
    expect(inRange(0, [0, 10])).toBe(true);
    expect(inRange(10, [0, 10])).toBe(true);
  });

  test('значение вне диапазона', () => {
    expect(inRange(-1, [0, 10])).toBe(false);
    expect(inRange(11, [0, 10])).toBe(false);
  });

  test('falsy range -> falsy результат', () => {
    expect(inRange(5, null)).toBeFalsy();
    expect(inRange(5, undefined)).toBeFalsy();
  });
});

describe('keyOfMatchingRange', () => {
  const ranges = {
    low: [0, 33],
    mid: [34, 66],
    high: [67, 100],
  };

  test('возвращает ключ совпавшего диапазона', () => {
    expect(keyOfMatchingRange(10, ranges)).toBe('low');
    expect(keyOfMatchingRange(50, ranges)).toBe('mid');
    expect(keyOfMatchingRange(80, ranges)).toBe('high');
  });

  test('нет совпадения -> undefined', () => {
    expect(keyOfMatchingRange(200, ranges)).toBeUndefined();
    expect(keyOfMatchingRange(-1, ranges)).toBeUndefined();
  });

  test('на границе — возвращает первый совпавший', () => {
    expect(keyOfMatchingRange(33, ranges)).toBe('low');
    expect(keyOfMatchingRange(34, ranges)).toBe('mid');
  });
});

describe('numberOfDecimalDigits', () => {
  test('целое число -> 0', () => {
    expect(numberOfDecimalDigits(42)).toBe(0);
  });

  test('десятичная дробь', () => {
    expect(numberOfDecimalDigits(3.14)).toBe(2);
    expect(numberOfDecimalDigits(1.5)).toBe(1);
    expect(numberOfDecimalDigits(0.123456)).toBe(6);
  });

  test('0 -> 0', () => {
    expect(numberOfDecimalDigits(0)).toBe(0);
  });

  // BUG: научная нотация вызывает crash
  // 1e-7.toString() = "1e-7", split('.')[1] = undefined -> .length -> TypeError
  test('научная нотация (1e-7) — не должна падать', () => {
    expect(() => numberOfDecimalDigits(1e-7)).not.toThrow();
  });
});

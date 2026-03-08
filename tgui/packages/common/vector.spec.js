import {
  vecAdd,
  vecDivide,
  vecInverse,
  vecLength,
  vecMultiply,
  vecNormalize,
  vecScale,
  vecSubtract,
} from './vector';

describe('vecAdd', () => {
  test('сложение двух 2D векторов', () => {
    expect(vecAdd([1, 2], [3, 4])).toEqual([4, 6]);
  });

  test('сложение трёх векторов', () => {
    expect(vecAdd([1, 1], [2, 2], [3, 3])).toEqual([6, 6]);
  });

  test('сложение с нулевым вектором — без изменений', () => {
    expect(vecAdd([5, 3], [0, 0])).toEqual([5, 3]);
  });

  test('сложение с отрицательным вектором — обнуление', () => {
    expect(vecAdd([1, 2], [-1, -2])).toEqual([0, 0]);
  });

  test('3D векторы', () => {
    expect(vecAdd([1, 2, 3], [4, 5, 6])).toEqual([5, 7, 9]);
  });

  test('один вектор — возвращает как есть', () => {
    expect(vecAdd([7, 8])).toEqual([7, 8]);
  });

  test('дробные компоненты', () => {
    expect(vecAdd([0.1, 0.2], [0.3, 0.4])).toEqual([
      0.1 + 0.3,
      0.2 + 0.4,
    ]);
  });
});

describe('vecSubtract', () => {
  test('вычитание двух 2D векторов', () => {
    expect(vecSubtract([5, 7], [2, 3])).toEqual([3, 4]);
  });

  test('вычитание из себя — нулевой вектор', () => {
    expect(vecSubtract([4, 5], [4, 5])).toEqual([0, 0]);
  });

  test('вычитание нескольких векторов последовательно', () => {
    // [10, 10] - [3, 3] - [2, 2] = [5, 5]
    expect(vecSubtract([10, 10], [3, 3], [2, 2])).toEqual([5, 5]);
  });

  test('результат с отрицательными компонентами', () => {
    expect(vecSubtract([1, 1], [5, 5])).toEqual([-4, -4]);
  });

  test('3D векторы', () => {
    expect(vecSubtract([10, 20, 30], [1, 2, 3])).toEqual([9, 18, 27]);
  });
});

describe('vecMultiply', () => {
  test('поэлементное умножение двух векторов', () => {
    expect(vecMultiply([2, 3], [4, 5])).toEqual([8, 15]);
  });

  test('умножение на нулевой вектор — обнуление', () => {
    expect(vecMultiply([5, 3], [0, 0])).toEqual([0, 0]);
  });

  test('умножение трёх векторов', () => {
    expect(vecMultiply([1, 2], [3, 4], [5, 6])).toEqual([15, 48]);
  });

  test('отрицательные компоненты', () => {
    expect(vecMultiply([2, -3], [-4, 5])).toEqual([-8, -15]);
  });

  test('умножение на единичный вектор — без изменений', () => {
    expect(vecMultiply([7, 8], [1, 1])).toEqual([7, 8]);
  });
});

describe('vecDivide', () => {
  test('поэлементное деление', () => {
    expect(vecDivide([10, 20], [2, 5])).toEqual([5, 4]);
  });

  test('деление на нулевой вектор — Infinity', () => {
    const result = vecDivide([1, 2], [0, 0]);
    expect(result[0]).toBe(Infinity);
    expect(result[1]).toBe(Infinity);
  });

  test('0 / 0 = NaN', () => {
    const result = vecDivide([0, 0], [0, 0]);
    expect(result[0]).toBeNaN();
    expect(result[1]).toBeNaN();
  });

  test('отрицательные компоненты', () => {
    expect(vecDivide([-10, 20], [2, -5])).toEqual([-5, -4]);
  });

  test('деление на единичный вектор — без изменений', () => {
    expect(vecDivide([7, 8], [1, 1])).toEqual([7, 8]);
  });

  test('дробный результат', () => {
    expect(vecDivide([1, 1], [3, 3])).toEqual([1 / 3, 1 / 3]);
  });
});

describe('vecScale', () => {
  test('масштабирование вектора скаляром', () => {
    expect(vecScale([1, 2], 3)).toEqual([3, 6]);
  });

  test('масштабирование на 0 — нулевой вектор', () => {
    expect(vecScale([5, 3], 0)).toEqual([0, 0]);
  });

  test('масштабирование на -1 — инверсия', () => {
    expect(vecScale([5, 3], -1)).toEqual([-5, -3]);
  });

  test('масштабирование на дробь', () => {
    expect(vecScale([10, 20], 0.5)).toEqual([5, 10]);
  });

  test('масштабирование на 1 — без изменений', () => {
    expect(vecScale([7, 8], 1)).toEqual([7, 8]);
  });

  test('3D вектор', () => {
    expect(vecScale([1, 2, 3], 10)).toEqual([10, 20, 30]);
  });
});

describe('vecInverse', () => {
  test('инверсия вектора', () => {
    expect(vecInverse([1, 2])).toEqual([-1, -2]);
  });

  test('инверсия нулевого вектора', () => {
    // -0 === 0 в JS, toEqual обрабатывает корректно
    expect(vecInverse([0, 0])).toEqual([-0, -0]);
  });

  test('двойная инверсия — исходный вектор', () => {
    const v = [3, -5, 7];
    expect(vecInverse(vecInverse(v))).toEqual(v);
  });

  test('3D вектор со смешанными знаками', () => {
    expect(vecInverse([1, -2, 3])).toEqual([-1, 2, -3]);
  });
});

describe('vecLength', () => {
  test('единичный вектор по оси X', () => {
    expect(vecLength([1, 0])).toBe(1);
  });

  test('единичный вектор по оси Y', () => {
    expect(vecLength([0, 1])).toBe(1);
  });

  test('теорема Пифагора: 3-4-5', () => {
    expect(vecLength([3, 4])).toBe(5);
  });

  test('нулевой вектор — длина 0', () => {
    expect(vecLength([0, 0])).toBe(0);
  });

  test('3D вектор: [1, 2, 2] -> 3', () => {
    expect(vecLength([1, 2, 2])).toBe(3);
  });

  test('отрицательные компоненты — та же длина', () => {
    expect(vecLength([-3, -4])).toBe(5);
  });

  test('единичный 3D вектор: [1, 0, 0]', () => {
    expect(vecLength([1, 0, 0])).toBe(1);
  });

  test('длина всегда неотрицательна', () => {
    expect(vecLength([-10, -20, -30])).toBeGreaterThanOrEqual(0);
  });
});

describe('vecNormalize', () => {
  // BUG: vecNormalize вызывает vecDivide(vec, vecLength(vec)),
  // но vecLength возвращает скаляр (число), а vecDivide ожидает векторы.
  // zip(vector, number) обращается к number[0], number[1] и т.д. -> undefined,
  // поэтому DIV(x, undefined) = NaN для каждого компонента.
  // Правильная реализация: vecScale(vec, 1 / vecLength(vec))

  test('BUG: нормализация [3, 4] — должна дать [0.6, 0.8]', () => {
    const result = vecNormalize([3, 4]);
    expect(result[0]).toBeCloseTo(0.6);
    expect(result[1]).toBeCloseTo(0.8);
  });

  test('BUG: нормализация единичного вектора [1, 0] — должна вернуть [1, 0]', () => {
    const result = vecNormalize([1, 0]);
    expect(result[0]).toBeCloseTo(1);
    expect(result[1]).toBeCloseTo(0);
  });

  test('BUG: нормализация 3D вектора [1, 2, 2] — длина результата = 1', () => {
    const result = vecNormalize([1, 2, 2]);
    // Длина [1,2,2] = 3, нормализованный = [1/3, 2/3, 2/3]
    expect(result[0]).toBeCloseTo(1 / 3);
    expect(result[1]).toBeCloseTo(2 / 3);
    expect(result[2]).toBeCloseTo(2 / 3);
  });
});

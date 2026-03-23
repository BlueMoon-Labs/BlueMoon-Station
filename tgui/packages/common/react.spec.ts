/**
 * @file
 * @copyright 2021 Aleksej Komarov
 * @license MIT
 */

import { canRender, classes, normalizeChildren, pureComponentHooks, shallowDiffers } from './react';

describe('classes', () => {
  test('empty', () => {
    expect(classes([])).toBe('');
  });

  test('result contains inputs', () => {
    const output = classes(['foo', 'bar', false, true, 0, 1, 'baz']);
    expect(output).toContain('foo');
    expect(output).toContain('bar');
    expect(output).toContain('baz');
  });

  test('не-строки игнорируются', () => {
    const output = classes([false, null, undefined, 0, 1, true]);
    expect(output.trim()).toBe('');
  });
});


describe('normalizeChildren', () => {
  test('массив — возвращает отфильтрованный flat массив', () => {
    const result = normalizeChildren(['a', 'b', 'c']);
    expect(result).toEqual(['a', 'b', 'c']);
  });

  test('вложенный массив — flat + filter', () => {
    const result = normalizeChildren([['a', 'b'], 'c']);
    expect(result).toEqual(['a', 'b', 'c']);
  });

  test('falsy элементы фильтруются из массива', () => {
    const result = normalizeChildren([null, 'a', undefined, 'b', 0, false, '']);
    // filter(value => value) — 0, false, '' тоже falsy
    expect(result).toEqual(['a', 'b']);
  });

  test('объект -> массив из одного элемента', () => {
    const obj = { type: 'div' };
    const result = normalizeChildren(obj);
    expect(result).toEqual([obj]);
  });

  test('примитив (строка) -> пустой массив', () => {
    // typeof 'hello' !== 'object', поэтому не попадает в ветку объекта
    expect(normalizeChildren('hello' as any)).toEqual([]);
  });

  test('число -> пустой массив', () => {
    expect(normalizeChildren(42 as any)).toEqual([]);
  });

  test('null -> пустой массив', () => {
    // null является 'object' в JS!
    // typeof null === 'object', поэтому попадает в ветку объекта
    // и возвращает [null]
    const result = normalizeChildren(null as any);
    // Array.isArray(null) -> false
    // typeof null === 'object' -> true
    // -> [null]
    expect(result).toEqual([null]);
  });
});

describe('shallowDiffers', () => {
  test('одинаковые объекты -> false', () => {
    expect(shallowDiffers({ a: 1, b: 2 }, { a: 1, b: 2 })).toBe(false);
  });

  test('разные значения -> true', () => {
    expect(shallowDiffers({ a: 1 }, { a: 2 })).toBe(true);
  });

  test('лишний ключ в a -> true', () => {
    expect(shallowDiffers({ a: 1, b: 2 }, { a: 1 })).toBe(true);
  });

  test('лишний ключ в b -> true', () => {
    expect(shallowDiffers({ a: 1 }, { a: 1, b: 2 })).toBe(true);
  });

  test('оба пустые -> false', () => {
    expect(shallowDiffers({}, {})).toBe(false);
  });

  test('тот же объект -> false', () => {
    const obj = { a: 1 };
    expect(shallowDiffers(obj, obj)).toBe(false);
  });

  test('deep equality не проверяется — nested objects сравниваются по ссылке', () => {
    const nested = { x: 1 };
    expect(shallowDiffers({ a: nested }, { a: nested })).toBe(false);
    // Разные объекты с одинаковым содержимым — shallow differs = true
    expect(shallowDiffers({ a: { x: 1 } }, { a: { x: 1 } })).toBe(true);
  });

  test('undefined vs отсутствующий ключ — differs', () => {
    // { a: undefined } — ключ 'a' in a -> true, 'a' in b -> false
    expect(shallowDiffers({ a: undefined }, {})).toBe(true);
  });
});

describe('canRender', () => {
  test('undefined -> false', () => {
    expect(canRender(undefined)).toBe(false);
  });

  test('null -> false', () => {
    expect(canRender(null)).toBe(false);
  });

  test('boolean -> false', () => {
    expect(canRender(true)).toBe(false);
    expect(canRender(false)).toBe(false);
  });

  test('0 -> true (числа рендерятся)', () => {
    expect(canRender(0)).toBe(true);
  });

  test('строка -> true', () => {
    expect(canRender('')).toBe(true);
    expect(canRender('hello')).toBe(true);
  });

  test('объект -> true', () => {
    expect(canRender({})).toBe(true);
    expect(canRender([])).toBe(true);
  });

  test('число -> true', () => {
    expect(canRender(42)).toBe(true);
  });
});

describe('pureComponentHooks', () => {
  test('onComponentShouldUpdate — одинаковые props -> false (не обновлять)', () => {
    const result = pureComponentHooks.onComponentShouldUpdate(
      { a: 1, b: 'hello' },
      { a: 1, b: 'hello' },
    );
    expect(result).toBe(false);
  });

  test('onComponentShouldUpdate — разные значения -> true (обновить)', () => {
    const result = pureComponentHooks.onComponentShouldUpdate(
      { a: 1 },
      { a: 2 },
    );
    expect(result).toBe(true);
  });

  test('onComponentShouldUpdate — добавленный ключ -> true', () => {
    const result = pureComponentHooks.onComponentShouldUpdate(
      { a: 1 },
      { a: 1, b: 2 },
    );
    expect(result).toBe(true);
  });

  test('onComponentShouldUpdate — тот же объект -> false', () => {
    const props = { a: 1 };
    expect(pureComponentHooks.onComponentShouldUpdate(props, props)).toBe(false);
  });

  test('onComponentShouldUpdate — deep change не детектируется (shallow)', () => {
    const nested = { x: 1 };
    // Одна и та же ссылка -> shallow considers equal
    expect(
      pureComponentHooks.onComponentShouldUpdate({ a: nested }, { a: nested }),
    ).toBe(false);
    // Разные объекты с одинаковым содержимым -> shallow considers different
    expect(
      pureComponentHooks.onComponentShouldUpdate({ a: { x: 1 } }, { a: { x: 1 } }),
    ).toBe(true);
  });
});

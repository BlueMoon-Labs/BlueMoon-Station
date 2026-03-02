import {
  filter,
  filterMap,
  map,
  paginate,
  range,
  reduce,
  sort,
  sortBy,
  toArray,
  toKeyedArray,
  uniq,
  uniqBy,
  zip,
  zipWith,
} from './collections';

// Type assertions, these will lint if the types are wrong.
const _zip1: [string, number] = zip(['a'], [1])[0];

describe('range', () => {
  test('range(0, 5)', () => {
    expect(range(0, 5)).toEqual([0, 1, 2, 3, 4]);
  });

  test('range(3, 7)', () => {
    expect(range(3, 7)).toEqual([3, 4, 5, 6]);
  });

  test('range(0, 0) -> пустой массив', () => {
    expect(range(0, 0)).toEqual([]);
  });

  test('range(5, 5) -> пустой массив', () => {
    expect(range(5, 5)).toEqual([]);
  });
});

describe('zip', () => {
  test('zip(["a", "b", "c"], [1, 2, 3, 4])', () => {
    expect(zip(['a', 'b', 'c'], [1, 2, 3, 4])).toEqual([
      ['a', 1],
      ['b', 2],
      ['c', 3],
    ]);
  });

  test('три массива', () => {
    expect(zip([1, 2], ['a', 'b'], [true, false])).toEqual([
      [1, 'a', true],
      [2, 'b', false],
    ]);
  });
});

describe('toArray', () => {
  test('массив возвращается как есть (тот же объект)', () => {
    const arr = [1, 2, 3];
    expect(toArray(arr)).toBe(arr);
  });

  test('объект -> массив значений', () => {
    expect(toArray({ a: 1, b: 2, c: 3 })).toEqual([1, 2, 3]);
  });

  test('null -> пустой массив', () => {
    expect(toArray(null)).toEqual([]);
  });

  test('undefined -> пустой массив', () => {
    expect(toArray(undefined)).toEqual([]);
  });

  test('число -> пустой массив', () => {
    expect(toArray(42)).toEqual([]);
  });

  test('строка -> пустой массив', () => {
    expect(toArray('hello')).toEqual([]);
  });

  test('не включает свойства прототипа', () => {
    const parent = { inherited: 'yes' };
    const child = Object.create(parent);
    child.own = 'value';
    expect(toArray(child)).toEqual(['value']);
  });
});

describe('toKeyedArray', () => {
  test('добавляет ключ "key" по умолчанию', () => {
    const obj = {
      foo: { value: 1 },
      bar: { value: 2 },
    };
    const result = toKeyedArray(obj);
    expect(result).toEqual([
      { key: 'foo', value: 1 },
      { key: 'bar', value: 2 },
    ]);
  });

  test('кастомное имя ключа', () => {
    const obj = { item1: { name: 'A' } };
    const result = toKeyedArray(obj, 'id');
    expect(result).toEqual([{ id: 'item1', name: 'A' }]);
  });
});

describe('filter', () => {
  test('фильтрует массив', () => {
    expect(filter(x => x > 2)([1, 2, 3, 4, 5])).toEqual([3, 4, 5]);
  });

  test('null -> null (passthrough)', () => {
    expect(filter(x => x)(null)).toBe(null);
  });

  test('undefined -> undefined (passthrough)', () => {
    expect(filter(x => x)(undefined)).toBe(undefined);
  });

  test('объект -> throw', () => {
    expect(() => filter(x => x)({ a: 1 })).toThrow();
  });

  test('пустой массив -> пустой массив', () => {
    expect(filter(x => x)([])).toEqual([]);
  });

  test('iteratee получает index и collection', () => {
    const indices: number[] = [];
    filter((_, i) => {
      indices.push(i);
      return true;
    })(['a', 'b', 'c']);
    expect(indices).toEqual([0, 1, 2]);
  });
});

describe('map', () => {
  test('маппит массив', () => {
    expect(map(x => x * 2)([1, 2, 3])).toEqual([2, 4, 6]);
  });

  test('маппит объект -> массив', () => {
    expect(map((v, k) => `${k}=${v}`)({ a: 1, b: 2 })).toEqual([
      'a=1',
      'b=2',
    ]);
  });

  test('null -> null (passthrough)', () => {
    expect(map(x => x)(null)).toBe(null);
  });

  test('undefined -> undefined (passthrough)', () => {
    expect(map(x => x)(undefined)).toBe(undefined);
  });

  test('число -> throw', () => {
    expect(() => map(x => x)(42 as any)).toThrow();
  });
});

describe('filterMap', () => {
  test('маппит и фильтрует undefined', () => {
    const result = filterMap([1, 2, 3, 4, 5], x =>
      x > 3 ? x * 10 : undefined,
    );
    expect(result).toEqual([40, 50]);
  });

  test('null и false НЕ фильтруются (только undefined)', () => {
    const result = filterMap([1, 2, 3], x => {
      if (x === 1) return null;
      if (x === 2) return false;
      return x;
    });
    expect(result).toEqual([null, false, 3]);
  });

  test('0 не фильтруется', () => {
    const result = filterMap([1, 2], () => 0);
    expect(result).toEqual([0, 0]);
  });

  test('пустой массив -> пустой массив', () => {
    expect(filterMap([], x => x)).toEqual([]);
  });
});

describe('sortBy', () => {
  test('сортировка по одному критерию', () => {
    const items = [{ name: 'C' }, { name: 'A' }, { name: 'B' }];
    const sorted = sortBy(x => x.name)(items);
    expect(sorted.map(x => x.name)).toEqual(['A', 'B', 'C']);
  });

  test('сортировка по числовому критерию', () => {
    const items = [3, 1, 4, 1, 5];
    const sorted = sortBy(x => x)(items);
    expect(sorted).toEqual([1, 1, 3, 4, 5]);
  });

  test('несколько критериев', () => {
    const items = [
      { group: 'B', order: 2 },
      { group: 'A', order: 3 },
      { group: 'A', order: 1 },
      { group: 'B', order: 1 },
    ];
    const sorted = sortBy(
      x => x.group,
      x => x.order,
    )(items);
    expect(sorted).toEqual([
      { group: 'A', order: 1 },
      { group: 'A', order: 3 },
      { group: 'B', order: 1 },
      { group: 'B', order: 2 },
    ]);
  });

  test('не-массив возвращается как есть', () => {
    expect(sortBy(x => x)('hello' as any)).toBe('hello');
    expect(sortBy(x => x)(null as any)).toBe(null);
  });

  test('sort() без критериев — сохраняет исходный порядок (нет сортировки)', () => {
    // sortBy() без iteratees: COMPARATOR сравнивает пустые criteria -> всегда 0
    // Array.sort стабильная -> исходный порядок сохраняется
    expect(sort([3, 1, 2])).toEqual([3, 1, 2]);
  });

  test('не мутирует исходный массив', () => {
    const original = [3, 1, 2];
    const copy = [...original];
    sortBy(x => x)(original);
    expect(original).toEqual(copy);
  });
});

describe('reduce', () => {
  test('с начальным значением', () => {
    expect(reduce((acc, x) => acc + x, 0)([1, 2, 3, 4])).toBe(10);
  });

  test('без начального значения — берёт array[0]', () => {
    expect(reduce((acc, x) => acc + x, undefined)([1, 2, 3, 4])).toBe(10);
  });

  test('строковая конкатенация', () => {
    expect(reduce((acc, x) => acc + x, '')(['a', 'b', 'c'])).toBe('abc');
  });

  test('один элемент без init -> возвращает элемент', () => {
    expect(reduce((acc, x) => acc + x, undefined)([42])).toBe(42);
  });
});

describe('uniqBy', () => {
  test('удаляет дубликаты (простые значения)', () => {
    expect(uniq([1, 2, 2, 3, 1, 3])).toEqual([1, 2, 3]);
  });

  test('сохраняет первое вхождение', () => {
    const items = [
      { id: 1, name: 'first' },
      { id: 2, name: 'second' },
      { id: 1, name: 'duplicate' },
    ];
    const result = uniqBy((x: { id: number; name: string }) => x.id)(items);
    expect(result).toEqual([
      { id: 1, name: 'first' },
      { id: 2, name: 'second' },
    ]);
  });

  test('NaN дедупликация — NaN считается равным NaN', () => {
    // NaN === NaN -> false в JS, но uniqBy должен дедуплицировать
    expect(uniq([NaN, NaN, NaN])).toEqual([NaN]);
  });

  test('-0 нормализуется к 0', () => {
    const result = uniq([-0, 0]);
    expect(result).toEqual([0]);
    // -0 нормализуется, значит Object.is(result[0], 0) должно быть true
    expect(Object.is(result[0], 0)).toBe(true);
  });

  test('строки', () => {
    expect(uniq(['a', 'b', 'a', 'c', 'b'])).toEqual(['a', 'b', 'c']);
  });

  test('пустой массив', () => {
    expect(uniq([])).toEqual([]);
  });
});

describe('zipWith', () => {
  test('комбинирует элементы через функцию', () => {
    const result = zipWith((a, b) => a + b)([1, 2, 3], [10, 20, 30]);
    expect(result).toEqual([11, 22, 33]);
  });
});

describe('paginate', () => {
  test('ровно делится на страницы', () => {
    expect(paginate([1, 2, 3, 4, 5, 6], 3)).toEqual([
      [1, 2, 3],
      [4, 5, 6],
    ]);
  });

  test('одна страница', () => {
    expect(paginate([1, 2, 3], 3)).toEqual([[1, 2, 3]]);
  });

  test('пустой массив -> пустой результат', () => {
    expect(paginate([], 3)).toEqual([]);
  });

  test('maxPerPage больше коллекции', () => {
    const result = paginate([1, 2], 5);
    expect(result).toEqual([[1, 2]]);
  });

  // BUG: paginate теряет неполную последнюю страницу
  test('неполная последняя страница должна включаться', () => {
    // paginate([1,2,3,4,5], 3) должен вернуть [[1,2,3], [4,5]]
    // но реально возвращает [[1,2,3]] — потеря данных
    expect(paginate([1, 2, 3, 4, 5], 3)).toEqual([
      [1, 2, 3],
      [4, 5],
    ]);
  });
});

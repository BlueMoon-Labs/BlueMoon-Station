import {
  IMPL_LOCAL_STORAGE,
  IMPL_MEMORY,
  LocalStorageBackend,
  MemoryBackend,
  storage,
} from './storage';

describe('MemoryBackend', () => {
  let backend;

  beforeEach(() => {
    backend = new MemoryBackend();
  });

  test('impl = IMPL_MEMORY', () => {
    expect(backend.impl).toBe(IMPL_MEMORY);
  });

  test('get несуществующего ключа — undefined', () => {
    expect(backend.get('nonexistent')).toBeUndefined();
  });

  test('set и get — сохраняет и возвращает значение', () => {
    backend.set('key', 'value');
    expect(backend.get('key')).toBe('value');
  });

  test('set перезаписывает значение', () => {
    backend.set('key', 'first');
    backend.set('key', 'second');
    expect(backend.get('key')).toBe('second');
  });

  test('хранит объекты по ссылке', () => {
    const obj = { a: 1, b: 2 };
    backend.set('obj', obj);
    expect(backend.get('obj')).toBe(obj);
  });

  test('хранит массивы', () => {
    const arr = [1, 2, 3];
    backend.set('arr', arr);
    expect(backend.get('arr')).toBe(arr);
  });

  test('хранит null', () => {
    backend.set('key', null);
    expect(backend.get('key')).toBeNull();
  });

  test('хранит число 0 (falsy значение)', () => {
    backend.set('key', 0);
    expect(backend.get('key')).toBe(0);
  });

  test('хранит пустую строку (falsy значение)', () => {
    backend.set('key', '');
    expect(backend.get('key')).toBe('');
  });

  test('хранит boolean false', () => {
    backend.set('key', false);
    expect(backend.get('key')).toBe(false);
  });

  test('remove — get возвращает undefined после удаления', () => {
    backend.set('key', 'value');
    backend.remove('key');
    expect(backend.get('key')).toBeUndefined();
  });

  // BUG: remove(key) устанавливает store[key] = undefined вместо delete store[key].
  // Ключ остаётся в Object.keys, что может привести к утечке памяти
  // и некорректному поведению при итерации по ключам.
  test('BUG: remove(key) — ключ НЕ должен оставаться в Object.keys', () => {
    backend.set('a', 1);
    backend.set('b', 2);
    backend.remove('a');
    expect(Object.keys(backend.store)).not.toContain('a');
    expect(Object.keys(backend.store)).toEqual(['b']);
  });

  test('clear — очищает все ключи', () => {
    backend.set('a', 1);
    backend.set('b', 2);
    backend.clear();
    expect(backend.get('a')).toBeUndefined();
    expect(backend.get('b')).toBeUndefined();
    expect(Object.keys(backend.store)).toEqual([]);
  });

  test('несколько независимых ключей', () => {
    backend.set('x', 10);
    backend.set('y', 20);
    backend.set('z', 30);
    expect(backend.get('x')).toBe(10);
    expect(backend.get('y')).toBe(20);
    expect(backend.get('z')).toBe(30);
  });
});

describe('LocalStorageBackend', () => {
  let backend;

  beforeEach(() => {
    backend = new LocalStorageBackend();
    localStorage.clear();
  });

  test('impl = IMPL_LOCAL_STORAGE', () => {
    expect(backend.impl).toBe(IMPL_LOCAL_STORAGE);
  });

  test('get несуществующего ключа — undefined', () => {
    expect(backend.get('nonexistent')).toBeUndefined();
  });

  test('set/get строки — JSON round-trip', () => {
    backend.set('key', 'hello');
    expect(backend.get('key')).toBe('hello');
  });

  test('set/get числа', () => {
    backend.set('key', 42);
    expect(backend.get('key')).toBe(42);
  });

  test('set/get дробного числа', () => {
    backend.set('key', 3.14);
    expect(backend.get('key')).toBeCloseTo(3.14);
  });

  test('set/get объекта', () => {
    const obj = { a: 1, b: 'test', c: [1, 2] };
    backend.set('key', obj);
    expect(backend.get('key')).toEqual(obj);
  });

  test('set/get массива', () => {
    backend.set('key', [1, 2, 3]);
    expect(backend.get('key')).toEqual([1, 2, 3]);
  });

  test('set/get boolean', () => {
    backend.set('t', true);
    backend.set('f', false);
    expect(backend.get('t')).toBe(true);
    expect(backend.get('f')).toBe(false);
  });

  test('set/get null — JSON.stringify(null) = "null" -> JSON.parse("null") = null', () => {
    backend.set('key', null);
    expect(backend.get('key')).toBeNull();
  });

  // BUG: set(undefined) -> localStorage.setItem(key, "undefined") (undefined -> строка)
  // При get: JSON.parse("undefined") бросает SyntaxError
  // Правильное поведение: set(undefined) должно работать как remove, или
  // get должно вернуть undefined без ошибки.
  test('BUG: set(undefined) -> get НЕ должен бросать ошибку', () => {
    backend.set('key', undefined);
    expect(() => backend.get('key')).not.toThrow();
  });

  test('перезапись значения', () => {
    backend.set('key', 'first');
    backend.set('key', 'second');
    expect(backend.get('key')).toBe('second');
  });

  test('remove удаляет ключ', () => {
    backend.set('key', 'value');
    backend.remove('key');
    expect(backend.get('key')).toBeUndefined();
  });

  test('clear очищает все ключи', () => {
    backend.set('a', 1);
    backend.set('b', 2);
    backend.clear();
    expect(backend.get('a')).toBeUndefined();
    expect(backend.get('b')).toBeUndefined();
  });

  test('данные сохраняются в localStorage как JSON строки', () => {
    backend.set('key', { x: 1 });
    const raw = localStorage.getItem('key');
    expect(raw).toBe('{"x":1}');
  });
});

describe('StorageProxy (storage singleton)', () => {
  test('get/set/remove — асинхронные операции через Promise', async () => {
    await storage.set('test-key', 'test-value');
    const value = await storage.get('test-key');
    expect(value).toBe('test-value');
    await storage.remove('test-key');
    const removed = await storage.get('test-key');
    expect(removed).toBeUndefined();
  });

  test('clear — очищает все данные', async () => {
    await storage.set('a', 1);
    await storage.set('b', 2);
    await storage.clear();
    expect(await storage.get('a')).toBeUndefined();
    expect(await storage.get('b')).toBeUndefined();
  });

  test('хранит сложные объекты', async () => {
    const data = { nested: { array: [1, 2, 3] }, flag: true };
    await storage.set('complex', data);
    expect(await storage.get('complex')).toEqual(data);
  });
});

import {
  HubStorageBackend,
  IMPL_HUB_STORAGE,
  IMPL_LOCAL_STORAGE,
  IMPL_MEMORY,
  IMPL_SERVER_STORAGE,
  LocalStorageBackend,
  MemoryBackend,
  ServerStorageBackend,
  storage,
  StorageProxy,
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

describe('HubStorageBackend', () => {
  let backend;
  let hubStore;

  beforeEach(() => {
    localStorage.clear();
    hubStore = new Map();
    window.hubStorage = {
      getItem: jest.fn(async key => hubStore.get(key)),
      key: jest.fn(async index => [...hubStore.keys()][index]),
      removeItem: jest.fn(async key => hubStore.delete(key)),
      setItem: jest.fn(async (key, value) => hubStore.set(key, value)),
    };
    Object.defineProperty(window.hubStorage, 'length', {
      configurable: true,
      get: () => hubStore.size,
    });
    backend = new HubStorageBackend();
  });

  afterEach(() => {
    delete window.hubStorage;
  });

  test('uses a BlueMoon namespace and round-trips JSON values', async () => {
    await backend.set('panel-settings', { theme: 'dark' });

    expect(window.hubStorage.setItem).toHaveBeenCalledWith(
      'bluemoon-panel-settings',
      '{"theme":"dark"}',
    );
    await expect(backend.get('panel-settings')).resolves.toEqual({ theme: 'dark' });
    expect(backend.impl).toBe(IMPL_HUB_STORAGE);
  });

  test('set(undefined) removes the persistent value', async () => {
    await backend.set('chat-state', { visible: true });
    await backend.set('chat-state', undefined);

    expect(window.hubStorage.removeItem)
      .toHaveBeenCalledWith('bluemoon-chat-state');
    await expect(backend.get('chat-state')).resolves.toBeUndefined();
  });

  test('clear only removes values owned by the BlueMoon namespace', async () => {
    hubStore.set('other-project-setting', 'keep me');
    await backend.set('panel-settings', { theme: 'dark' });
    await backend.set('chat-state', { visible: true });

    await backend.clear();

    expect(hubStore.get('other-project-setting')).toBe('keep me');
    await expect(backend.get('panel-settings')).resolves.toBeUndefined();
    await expect(backend.get('chat-state')).resolves.toBeUndefined();
  });

  test('StorageProxy prefers a working BYOND backend', async () => {
    const proxy = new StorageProxy();
    await proxy.set('key', 'value');

    expect(window.hubStorage.getItem)
      .toHaveBeenCalledWith('bluemoon-__backend-probe__');
    await expect(proxy.get('key')).resolves.toBe('value');
  });

  test('StorageProxy lazily migrates settings from pre-516 storage', async () => {
    localStorage.setItem('panel-settings', '{"theme":"light"}');
    const proxy = new StorageProxy();

    await expect(proxy.get('panel-settings')).resolves.toEqual({ theme: 'light' });
    expect(window.hubStorage.setItem).toHaveBeenCalledWith(
      'bluemoon-panel-settings',
      '{"theme":"light"}',
    );
  });

  test('StorageProxy does not resurrect a removed legacy value', async () => {
    localStorage.setItem('panel-settings', '{"theme":"light"}');
    const proxy = new StorageProxy();
    await proxy.get('panel-settings');
    await proxy.set('panel-settings', { theme: 'dark' });

    await proxy.remove('panel-settings');

    await expect(proxy.get('panel-settings')).resolves.toBeUndefined();
    expect(localStorage.getItem('panel-settings')).toBeNull();
  });

  test('StorageProxy set(undefined) also removes the legacy value', async () => {
    localStorage.setItem('panel-settings', '{"theme":"light"}');
    const proxy = new StorageProxy();
    await proxy.get('panel-settings');

    await proxy.set('panel-settings', undefined);

    await expect(proxy.get('panel-settings')).resolves.toBeUndefined();
    expect(localStorage.getItem('panel-settings')).toBeNull();
  });

  test('StorageProxy clears hub and legacy values without touching foreign keys', async () => {
    localStorage.setItem('panel-settings', '{"theme":"light"}');
    hubStore.set('other-project-setting', 'keep me');
    const proxy = new StorageProxy();
    await proxy.get('panel-settings');
    await proxy.set('chat-state', { visible: true });

    await proxy.clear();

    await expect(proxy.get('panel-settings')).resolves.toBeUndefined();
    await expect(proxy.get('chat-state')).resolves.toBeUndefined();
    expect(localStorage.getItem('panel-settings')).toBeNull();
    expect(hubStore.get('other-project-setting')).toBe('keep me');
  });

  test('StorageProxy keeps migrated values current for fallback', async () => {
    localStorage.setItem('panel-settings', '{"theme":"light"}');
    const proxy = new StorageProxy();
    await proxy.get('panel-settings');
    await proxy.set('panel-settings', { theme: 'dark' });
    window.hubStorage.getItem.mockRejectedValueOnce(new Error('WebView2 reset'));

    await expect(proxy.get('panel-settings')).resolves.toEqual({ theme: 'dark' });
  });

  test('StorageProxy returns the legacy value when its migration write fails', async () => {
    localStorage.setItem('panel-settings', '{"theme":"light"}');
    window.hubStorage.setItem.mockRejectedValueOnce(new Error('WebView2 reset'));
    const proxy = new StorageProxy();

    await expect(proxy.get('panel-settings')).resolves.toEqual({ theme: 'light' });
    await expect(proxy.backendPromise).resolves.toBeInstanceOf(LocalStorageBackend);
  });

  test('StorageProxy falls back when hubStorage rejects after selection', async () => {
    const proxy = new StorageProxy();
    await proxy.backendPromise;
    window.hubStorage.setItem.mockRejectedValueOnce(new Error('WebView2 reset'));

    await expect(proxy.set('fallback-key', 'fallback-value')).resolves.toBeUndefined();
    await expect(proxy.get('fallback-key')).resolves.toBe('fallback-value');
  });
});

describe('ServerStorageBackend', () => {
  let serverStore;
  let hubStore;

  // Как у BYOND 516: только getItem/setItem/removeItem, без key и length.
  const createByondStorage = store => ({
    getItem: jest.fn(key => (store.has(key) ? store.get(key) : null)),
    setItem: jest.fn((key, value) => store.set(key, value)),
    removeItem: jest.fn(key => store.delete(key)),
  });

  beforeEach(() => {
    localStorage.clear();
    serverStore = new Map();
    hubStore = new Map();
    window.serverStorage = createByondStorage(serverStore);
    window.hubStorage = createByondStorage(hubStore);
  });

  afterEach(() => {
    delete window.serverStorage;
    delete window.hubStorage;
  });

  test('StorageProxy picks serverStorage first, even without key and length', async () => {
    const proxy = new StorageProxy();
    const backend = await proxy.backendPromise;

    expect(backend).toBeInstanceOf(ServerStorageBackend);
    expect(backend.impl).toBe(IMPL_SERVER_STORAGE);
    await proxy.set('chat-state', { visible: true });
    expect(serverStore.get('bluemoon-chat-state')).toBe('{"visible":true}');
    expect(hubStore.size).toBe(0);
  });

  test('hubStorage without key and length is still used when there is no serverStorage', async () => {
    delete window.serverStorage;
    const proxy = new StorageProxy();

    await expect(proxy.backendPromise).resolves.toBeInstanceOf(HubStorageBackend);
  });

  test('a missing key is moved over from hubStorage once', async () => {
    hubStore.set('bluemoon-panel-settings', '{"theme":"dark"}');
    localStorage.setItem('panel-settings', '{"theme":"light"}');
    const proxy = new StorageProxy();

    await expect(proxy.get('panel-settings')).resolves.toEqual({ theme: 'dark' });
    expect(serverStore.get('bluemoon-panel-settings')).toBe('{"theme":"dark"}');
  });

  test('falls back to pre-516 storage when hubStorage has nothing', async () => {
    localStorage.setItem('panel-settings', '{"theme":"light"}');
    const proxy = new StorageProxy();

    await expect(proxy.get('panel-settings')).resolves.toEqual({ theme: 'light' });
    expect(serverStore.get('bluemoon-panel-settings')).toBe('{"theme":"light"}');
  });

  test('hubStorage is only read: moving and removing leave it as it was', async () => {
    hubStore.set('bluemoon-chat-messages', '[1,2]');
    const proxy = new StorageProxy();
    await expect(proxy.get('chat-messages')).resolves.toEqual([1, 2]);

    await proxy.remove('chat-messages');
    await proxy.clear();

    expect(hubStore.get('bluemoon-chat-messages')).toBe('[1,2]');
    expect(window.hubStorage.setItem).not.toHaveBeenCalled();
    expect(window.hubStorage.removeItem).not.toHaveBeenCalled();
  });

  test('clear without key and length removes own known keys, keeps foreign ones and reports it', async () => {
    serverStore.set('statbrowser_theme', '{}');
    serverStore.set('bluemoon-panel-settings', '{"theme":"dark"}');
    const backend = new ServerStorageBackend();
    await backend.get('panel-settings');
    await backend.set('chat-state', { visible: true });

    await expect(backend.clear()).resolves.toBe(false);
    expect(serverStore.get('statbrowser_theme')).toBe('{}');
    expect(serverStore.has('bluemoon-panel-settings')).toBe(false);
    expect(serverStore.has('bluemoon-chat-state')).toBe(false);
  });

  test('StorageProxy.clear passes the incomplete clear on to the caller', async () => {
    const proxy = new StorageProxy();
    await proxy.set('chat-state', { visible: true });

    await expect(proxy.clear()).resolves.toBe(false);
    expect(serverStore.has('bluemoon-chat-state')).toBe(false);
  });
});

describe('ServerStorageBackend.setReplacing', () => {
  // Копия ByondStorage из byondwin.dll: setItem и removeItem отправляют клиенту
  // всё хранилище, sync просит у клиента его копию, клиент отвечает fill.
  function ByondStorage(client, answerSync = true) {
    let storage = {};
    let synced = true;
    let waiting = [];
    const update = () => {
      client.file = JSON.stringify(storage);
      client.updates++;
    };
    const ready = () => {
      synced = true;
      const list = waiting;
      waiting = [];
      for (const resolve of list) {
        resolve(this);
      }
    };
    this.getItem = item => (Object.hasOwn(storage, item) ? storage[item] : null);
    this.setItem = (item, value) => {
      storage[item] = value;
      update();
    };
    this.removeItem = item => {
      if (Object.hasOwn(storage, item)) {
        delete storage[item];
        update();
      }
    };
    this.sync = () => new Promise(resolve => {
      waiting.push(resolve);
      if (synced) {
        synced = false;
        if (answerSync) {
          setTimeout(() => window.serverStorage.fill(client.file), 0);
        }
      }
    });
    this.fill = function (data) {
      storage = data ? JSON.parse(data) : {};
      ready();
    };
    this.fill(client.file);
  }

  afterEach(() => {
    jest.useRealTimers();
    delete window.serverStorage;
  });

  test('writes the key and drops old keys in one write, keeping foreign keys', async () => {
    const client = {
      file: JSON.stringify({
        'statbrowser_theme': '{}',
        'bluemoon-chat-log-0': '[1]',
        'bluemoon-chat-log-index': '{}',
      }),
      updates: 0,
    };
    window.serverStorage = new ByondStorage(client);
    const store = window.serverStorage;
    // Другое окно успело записать свой ключ: эта копия о нём не знает.
    client.file = JSON.stringify({ ...JSON.parse(client.file), 'bluemoon-geometries': '{"a":1}' });
    const fill = store.fill;
    const backend = new ServerStorageBackend();

    await expect(backend.setReplacing('chat-history-z', { version: 3 },
      ['chat-log-0', 'chat-log-index'])).resolves.toBe(true);
    expect(client.updates).toBe(1);
    expect(store.fill).toBe(fill);
    expect(JSON.parse(client.file)).toEqual({
      'statbrowser_theme': '{}',
      'bluemoon-geometries': '{"a":1}',
      'bluemoon-chat-history-z': '{"version":3}',
    });
  });

  test('between the answer to sync and the write nothing else gets in', async () => {
    const client = { file: JSON.stringify({ 'bluemoon-chat-log-0': '[1]' }), updates: 0 };
    window.serverStorage = new ByondStorage(client);
    const proxy = new StorageProxy();
    await proxy.backendPromise;
    const writing = proxy.setReplacing('chat-history-z', 1, ['chat-log-0']);
    const other = proxy.set('panel-settings', 2);
    await Promise.all([writing, other]);
    expect(JSON.parse(client.file)).toEqual({
      'bluemoon-chat-history-z': '1',
      'bluemoon-panel-settings': '2',
    });
  });

  test('without an answer to sync only the key is written', async () => {
    jest.useFakeTimers();
    const client = { file: JSON.stringify({ 'bluemoon-chat-log-0': '[1]' }), updates: 0 };
    window.serverStorage = new ByondStorage(client, false);
    const fill = window.serverStorage.fill;
    const writing = new ServerStorageBackend().setReplacing('chat-history-z', 1, ['chat-log-0']);
    await jest.advanceTimersByTimeAsync(5000);

    await expect(writing).resolves.toBe(false);
    expect(JSON.parse(client.file)).toEqual({
      'bluemoon-chat-log-0': '[1]',
      'bluemoon-chat-history-z': '1',
    });
    await jest.advanceTimersByTimeAsync(60000);
    expect(window.serverStorage.fill).toBe(fill);
  });

  test('a stale answer to sync does not undo writes made while waiting', async () => {
    jest.useFakeTimers();
    const client = { file: JSON.stringify({ 'bluemoon-chat-log-0': '[1]' }), updates: 0 };
    window.serverStorage = new ByondStorage(client, false);
    const stale = client.file;
    const proxy = new StorageProxy();
    await proxy.backendPromise;
    const writing = proxy.setReplacing('chat-history-z', 1, ['chat-log-0']);
    await proxy.set('panel-settings', 2);
    window.serverStorage.fill(stale);

    await expect(writing).resolves.toBe(true);
    expect(JSON.parse(client.file)).toEqual({
      'bluemoon-chat-history-z': '1',
      'bluemoon-panel-settings': '2',
    });
  });

  test('a late answer to sync does not undo writes made while waiting', async () => {
    jest.useFakeTimers();
    const client = { file: JSON.stringify({ 'bluemoon-chat-log-0': '[1]' }), updates: 0 };
    window.serverStorage = new ByondStorage(client, false);
    const fill = window.serverStorage.fill;
    const stale = client.file;
    const proxy = new StorageProxy();
    await proxy.backendPromise;
    const writing = proxy.setReplacing('chat-history-z', 1, ['chat-log-0']);
    await proxy.set('panel-settings', 2);
    await jest.advanceTimersByTimeAsync(5000);
    await expect(writing).resolves.toBe(false);

    await jest.advanceTimersByTimeAsync(1000);
    window.serverStorage.fill(stale);
    await proxy.set('telemetry', 3);
    expect(JSON.parse(client.file)).toEqual({
      'bluemoon-chat-log-0': '[1]',
      'bluemoon-chat-history-z': '1',
      'bluemoon-panel-settings': '2',
      'bluemoon-telemetry': '3',
    });
    expect(window.serverStorage.fill).toBe(fill);
  });

  test('storage without sync and fill writes only the key', async () => {
    window.serverStorage = {
      getItem: jest.fn(() => null),
      setItem: jest.fn(),
      removeItem: jest.fn(),
    };
    await expect(new ServerStorageBackend().setReplacing('chat-history-z', 1, ['chat-log-0']))
      .resolves.toBe(false);
    expect(window.serverStorage.setItem).toHaveBeenCalledWith('bluemoon-chat-history-z', '1');
    expect(window.serverStorage.removeItem).not.toHaveBeenCalled();
  });

  test('StorageProxy.setReplacing elsewhere removes the old keys only after the write', async () => {
    localStorage.clear();
    localStorage.setItem('chat-log-0', '[1]');
    localStorage.setItem('panel-settings', '{}');
    const proxy = new StorageProxy();
    const setItem = jest.spyOn(Storage.prototype, 'setItem').mockImplementationOnce(() => {
      throw new Error('quota');
    });

    await expect(proxy.setReplacing('chat-history-z', 1, ['chat-log-0'])).rejects.toThrow('quota');
    expect(localStorage.getItem('chat-log-0')).toBe('[1]');
    setItem.mockRestore();
    await expect(proxy.setReplacing('chat-history-z', 1, ['chat-log-0'])).resolves.toBe(true);
    expect(localStorage.getItem('chat-log-0')).toBeNull();
    expect(localStorage.getItem('chat-history-z')).toBe('1');
    expect(localStorage.getItem('panel-settings')).toBe('{}');
  });

  test('peek does not pull values from older storages', async () => {
    const client = { file: JSON.stringify({}), updates: 0 };
    window.serverStorage = new ByondStorage(client);
    localStorage.clear();
    localStorage.setItem('chat-history', '{"version":2}');
    const proxy = new StorageProxy();

    await expect(proxy.peek('chat-history')).resolves.toBeUndefined();
    expect(client.updates).toBe(0);
    localStorage.clear();
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

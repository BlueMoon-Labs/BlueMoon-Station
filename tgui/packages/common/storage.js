/**
 * Browser-agnostic abstraction of key-value web storage.
 *
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

export const IMPL_MEMORY = 0;
export const IMPL_LOCAL_STORAGE = 1;
export const IMPL_INDEXED_DB = 2;
export const IMPL_HUB_STORAGE = 3;
export const IMPL_SERVER_STORAGE = 4;

const HUB_STORAGE_PREFIX = 'bluemoon-';
const HUB_STORAGE_PROBE_KEY = HUB_STORAGE_PREFIX + '__backend-probe__';
const BYOND_SYNC_TIMEOUT = 5000;
// Сколько после тайм-аута ещё ждём позднего ответа на sync.
const BYOND_SYNC_LATE_WAIT = 60000;

const INDEXED_DB_VERSION = 1;
const INDEXED_DB_NAME = 'tgui-citadel-main';
const INDEXED_DB_STORE_NAME = 'storage-v1';

const READ_ONLY = 'readonly';
const READ_WRITE = 'readwrite';

const testGeneric = testFn => () => {
  try {
    return Boolean(testFn());
  }
  catch {
    return false;
  }
};

// LocalStorage can sometimes throw even when storage appears available.
// See: https://superuser.com/questions/1080011
const testLocalStorage = testGeneric(() => (
  window.localStorage && window.localStorage.getItem
));

const testIndexedDb = testGeneric(() => (
  window.indexedDB && window.IDBTransaction
));

// key и length не требуем: для чтения и записи они не нужны, а без них
// проверка молча отправляла всё в IndexedDB.
const testByondStorage = name => testGeneric(() => (
  window[name]
  && window[name].getItem
  && window[name].setItem
  && window[name].removeItem
));

const testHubStorage = testByondStorage('hubStorage');
const testServerStorage = testByondStorage('serverStorage');

const replayJournal = (items, journal) => {
  for (const [item, value] of journal) {
    if (value === undefined) {
      delete items[item];
    } else {
      items[item] = value;
    }
  }
  return items;
};

/**
 * Ответ клиента на sync - его копия хранилища, и записи этого окна за время
 * ожидания в ней может не быть. Пока ответа нет, setItem/removeItem пишутся
 * в журнал и повторяются поверх ответа, даже позднего: иначе fill(data)
 * откатит копию окна, и следующая запись сотрёт их из файла.
 */
const watchSync = (store, onAnswer) => {
  const { fill, setItem, removeItem } = store;
  const watch = { journal: [], late: false };
  let active = true;
  let lateTimer;
  function onFill(data) {
    if (!active || !watch.late) {
      if (active) {
        onAnswer(data);
      }
      return fill.apply(this, arguments);
    }
    watch.stop();
    let items = null;
    try {
      items = JSON.parse(data);
    }
    catch {}
    if (!items || typeof items !== 'object' || Array.isArray(items)) {
      return fill.apply(this, arguments);
    }
    return fill.call(this, JSON.stringify(replayJournal(items, watch.journal)));
  }
  function onSet(item, value) {
    if (active) {
      watch.journal.push([item, value]);
    }
    return setItem.apply(this, arguments);
  }
  function onRemove(item) {
    if (active) {
      watch.journal.push([item, undefined]);
    }
    return removeItem.apply(this, arguments);
  }
  watch.stop = () => {
    active = false;
    clearTimeout(lateTimer);
    if (store.fill === onFill) {
      store.fill = fill;
    }
    if (store.setItem === onSet) {
      store.setItem = setItem;
    }
    if (store.removeItem === onRemove) {
      store.removeItem = removeItem;
    }
  };
  watch.awaitLate = () => {
    watch.late = true;
    lateTimer = setTimeout(watch.stop, BYOND_SYNC_LATE_WAIT);
  };
  store.fill = onFill;
  store.setItem = onSet;
  store.removeItem = onRemove;
  return watch;
};

const isByondBackend = backend => (
  backend.impl === IMPL_HUB_STORAGE || backend.impl === IMPL_SERVER_STORAGE
);

export class MemoryBackend {
  constructor() {
    this.impl = IMPL_MEMORY;
    this.store = {};
  }

  get(key) {
    return this.store[key];
  }

  set(key, value) {
    this.store[key] = value;
  }

  remove(key) {
    delete this.store[key];
  }

  clear() {
    this.store = {};
  }
}

export class LocalStorageBackend {
  constructor() {
    this.impl = IMPL_LOCAL_STORAGE;
  }

  get(key) {
    const value = localStorage.getItem(key);
    if (typeof value === 'string') {
      return JSON.parse(value);
    }
  }

  set(key, value) {
    if (value === undefined) {
      localStorage.removeItem(key);
    } else {
      localStorage.setItem(key, JSON.stringify(value));
    }
  }

  remove(key) {
    localStorage.removeItem(key);
  }

  clear() {
    localStorage.clear();
  }
}

/**
 * Persistent storage exposed by BYOND 516 when +byondstorage is enabled.
 * BYOND keeps it on disk outside WebView2, so it survives restarts, unlike
 * IndexedDB and localStorage: their origin is a local port that changes on
 * every launch.
 *
 * Keys are namespaced: hubStorage is shared by every server under the same
 * BYOND hub, and serverStorage is shared with the stat panel.
 */
class ByondStorageBackend {
  constructor(storageName, impl) {
    this.storageName = storageName;
    this.impl = impl;
    // Без key и length хранилище не перечислить: clear() сотрёт только ключи,
    // которые этот бэкенд видел сам.
    this.knownKeys = new Set();
  }

  get store() {
    return window[this.storageName];
  }

  async get(key) {
    const storageKey = HUB_STORAGE_PREFIX + key;
    const value = await this.store.getItem(storageKey);
    if (typeof value === 'string') {
      this.knownKeys.add(storageKey);
      return JSON.parse(value);
    }
  }

  async set(key, value) {
    const storageKey = HUB_STORAGE_PREFIX + key;
    if (value === undefined) {
      await this.store.removeItem(storageKey);
      this.knownKeys.delete(storageKey);
      return;
    }
    await this.store.setItem(storageKey, JSON.stringify(value));
    this.knownKeys.add(storageKey);
  }

  async remove(key) {
    const storageKey = HUB_STORAGE_PREFIX + key;
    await this.store.removeItem(storageKey);
    this.knownKeys.delete(storageKey);
  }

  /**
   * Пишет key и убирает keys одной перезаписью файла. Копию хранилища берёт
   * у клиента (sync), чтобы не затереть чужие ключи; от ответа до setItem
   * идёт только синхронный код. Без sync/fill или без ответа клиента пишет
   * один key и возвращает false: keys не тронуты.
   */
  async setReplacing(key, value, keys) {
    const store = this.store;
    const storageKey = HUB_STORAGE_PREFIX + key;
    const text = JSON.stringify(value);
    const fill = store.fill;
    let snapshot;
    let watch = null;
    if (typeof store.sync === 'function' && typeof fill === 'function') {
      watch = watchSync(store, data => {
        snapshot = data;
      });
      let timer;
      let answered = false;
      try {
        answered = await Promise.race([
          store.sync().then(() => true),
          new Promise(resolve => {
            timer = setTimeout(() => resolve(false), BYOND_SYNC_TIMEOUT);
          }),
        ]);
      }
      catch (error) {
        watch.stop();
        throw error;
      }
      finally {
        clearTimeout(timer);
      }
      if (!answered) {
        watch.awaitLate();
      }
    }
    let items = null;
    try {
      items = JSON.parse(snapshot);
    }
    catch {}
    if (!items || typeof items !== 'object' || Array.isArray(items)) {
      if (watch && !watch.late) {
        watch.stop();
      }
      await store.setItem(storageKey, text);
      this.knownKeys.add(storageKey);
      return false;
    }
    replayJournal(items, watch.journal);
    watch.stop();
    for (const removed of keys) {
      delete items[HUB_STORAGE_PREFIX + removed];
      this.knownKeys.delete(HUB_STORAGE_PREFIX + removed);
    }
    fill.call(store, JSON.stringify(items));
    const written = store.setItem(storageKey, text);
    this.knownKeys.add(storageKey);
    await written;
    return true;
  }

  /**
   * Returns false when the storage cannot list its keys and only the keys
   * seen by this backend were removed.
   */
  async clear() {
    // Only remove keys owned by this backend instead of wiping unrelated data.
    const store = this.store;
    if (typeof store.key !== 'function' || typeof store.length !== 'number') {
      for (const storageKey of [...this.knownKeys]) {
        await store.removeItem(storageKey);
        this.knownKeys.delete(storageKey);
      }
      return false;
    }
    this.knownKeys.clear();
    for (let index = store.length - 1; index >= 0; index--) {
      const key = await store.key(index);
      if (typeof key === 'string' && key.startsWith(HUB_STORAGE_PREFIX)) {
        await store.removeItem(key);
      }
    }
  }
}

/** Shared by every server under the same BYOND hub. */
export class HubStorageBackend extends ByondStorageBackend {
  constructor() {
    super('hubStorage', IMPL_HUB_STORAGE);
  }
}

/** Per server address: what the stat panel already uses. */
export class ServerStorageBackend extends ByondStorageBackend {
  constructor() {
    super('serverStorage', IMPL_SERVER_STORAGE);
  }
}

const probeByondBackend = async backend => {
  // Merely exposing the storage does not guarantee that its API is usable.
  // Probe it before selecting it so a disabled/broken WebView2
  // implementation cannot strand TGUI settings.
  await backend.store.getItem(HUB_STORAGE_PROBE_KEY);
  return backend;
};

export class IndexedDbBackend {
  constructor() {
    this.impl = IMPL_INDEXED_DB;
    /** @type {Promise<IDBDatabase>} */
    this.dbPromise = new Promise((resolve, reject) => {
      const indexedDB = window.indexedDB;
      const req = indexedDB.open(INDEXED_DB_NAME, INDEXED_DB_VERSION);
      req.onupgradeneeded = () => {
        try {
          req.result.createObjectStore(INDEXED_DB_STORE_NAME);
        }
        catch (err) {
          reject(new Error('Failed to upgrade IDB: ' + req.error));
        }
      };
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => {
        reject(new Error('Failed to open IDB: ' + req.error));
      };
    });
  }

  getStore(mode) {
    return this.dbPromise.then(db => db
      .transaction(INDEXED_DB_STORE_NAME, mode)
      .objectStore(INDEXED_DB_STORE_NAME));
  }

  async get(key) {
    const store = await this.getStore(READ_ONLY);
    return new Promise((resolve, reject) => {
      const req = store.get(key);
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
  }

  async set(key, value) {
    if (value === null) {
      value = undefined;
    }
    // NOTE: We deliberately make this operation transactionless
    const store = await this.getStore(READ_WRITE);
    store.put(value, key);
  }

  async remove(key) {
    // NOTE: We deliberately make this operation transactionless
    const store = await this.getStore(READ_WRITE);
    store.delete(key);
  }

  async clear() {
    // NOTE: We deliberately make this operation transactionless
    const store = await this.getStore(READ_WRITE);
    store.clear();
  }
}

/**
 * Web Storage Proxy object, which selects the best backend available
 * depending on the environment.
 */
export class StorageProxy {
  constructor() {
    this.legacyBackendPromise = null;
    this.backendPromise = (async () => {
      if (testServerStorage()) {
        try {
          return await probeByondBackend(new ServerStorageBackend());
        }
        catch {}
      }
      if (testHubStorage()) {
        try {
          return await probeByondBackend(new HubStorageBackend());
        }
        catch {}
      }
      if (testIndexedDb()) {
        try {
          const backend = new IndexedDbBackend();
          await backend.dbPromise;
          return backend;
        }
        catch {}
      }
      if (testLocalStorage()) {
        return new LocalStorageBackend();
      }
      return new MemoryBackend();
    })();
  }

  async get(key) {
    return this.run('get', key);
  }

  async set(key, value) {
    return this.run('set', key, value);
  }

  async remove(key) {
    return this.run('remove', key);
  }

  async clear() {
    return this.run('clear');
  }

  /** Значение без переноса из старых хранилищ: для ключей, которых там не бывает. */
  async peek(key) {
    const backend = await this.backendPromise;
    try {
      return await backend.get(key);
    }
    catch {
      return undefined;
    }
  }

  /**
   * Пишет key и убирает keys. На хранилище BYOND - одной перезаписью файла
   * (см. ByondStorageBackend.setReplacing), в остальных - после записи.
   * false - записан только key, keys остались.
   */
  async setReplacing(key, value, keys) {
    const backend = await this.backendPromise;
    if (!isByondBackend(backend)) {
      await this.set(key, value);
      for (const removed of keys) {
        await this.remove(removed);
      }
      return true;
    }
    let done;
    try {
      done = await backend.setReplacing(key, value, keys);
    }
    catch {
      await this.set(key, value);
      return false;
    }
    if (this.legacyBackendPromise) {
      const legacyBackend = await this.legacyBackendPromise;
      await legacyBackend.set(key, value);
    }
    if (done) {
      const legacyBackend = await this.getLegacyBackend();
      for (const removed of keys) {
        await legacyBackend.remove(removed);
      }
    }
    return done;
  }

  async run(operation, ...args) {
    const backend = await this.backendPromise;
    let result;
    try {
      result = await backend[operation](...args);
    }
    catch (error) {
      // BYOND storage can disappear when WebView2 is recreated or when browser
      // options change. Demote only that backend; existing IndexedDB and
      // localStorage errors retain their old, visible failure semantics.
      if (!isByondBackend(backend)) {
        throw error;
      }
      this.backendPromise = this.getLegacyBackend();
      const fallback = await this.backendPromise;
      return fallback[operation](...args);
    }

    if (!isByondBackend(backend)) {
      return result;
    }

    if (operation === 'get' && result === undefined) {
      // Preserve values written before this backend was picked: hubStorage
      // and pre-516 storage. Migrate lazily because opening IndexedDB during
      // every TGUI bootstrap would negate the faster BYOND storage path.
      const legacyValue = await this.getLegacyValue(backend, args[0]);
      if (legacyValue !== undefined) {
        try {
          await backend.set(args[0], legacyValue);
        }
        catch {
          this.backendPromise = this.getLegacyBackend();
        }
        return legacyValue;
      }
    }

    // Once legacy storage has participated in migration, keep it current so
    // fallback cannot restore stale values. Destructive operations must always
    // reach legacy storage, otherwise a later missing hub key resurrects it.
    if (operation === 'remove' || (operation === 'set' && args[1] === undefined)) {
      const legacyBackend = await this.getLegacyBackend();
      await legacyBackend.remove(args[0]);
    }
    else if (operation === 'clear') {
      const legacyBackend = await this.getLegacyBackend();
      await legacyBackend.clear();
    }
    else if (operation === 'set' && this.legacyBackendPromise) {
      const legacyBackend = await this.legacyBackendPromise;
      await legacyBackend.set(...args);
    }

    return result;
  }

  // Под serverStorage старые значения могли остаться в hubStorage. Его только
  // читаем: он общий для всех серверов хаба, и стирать из него при переносе
  // значило бы отнять старые данные у остальных серверов BlueMoon.
  getHubLegacy(backend) {
    if (backend.impl !== IMPL_SERVER_STORAGE || !testHubStorage()) {
      return null;
    }
    return new HubStorageBackend();
  }

  async getLegacyValue(backend, key) {
    const hub = this.getHubLegacy(backend);
    if (hub) {
      try {
        const value = await hub.get(key);
        if (value !== undefined) {
          return value;
        }
      }
      catch {}
    }
    const legacyBackend = await this.getLegacyBackend();
    return legacyBackend.get(key);
  }

  getLegacyBackend() {
    if (!this.legacyBackendPromise) {
      this.legacyBackendPromise = this.createLegacyBackend();
    }
    return this.legacyBackendPromise;
  }

  async createLegacyBackend() {
    if (testIndexedDb()) {
      try {
        const backend = new IndexedDbBackend();
        await backend.dbPromise;
        return backend;
      }
      catch {}
    }
    if (testLocalStorage()) {
      return new LocalStorageBackend();
    }
    return new MemoryBackend();
  }
}

export const storage = new StorageProxy();

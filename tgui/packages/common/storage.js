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
  }

  get store() {
    return window[this.storageName];
  }

  async get(key) {
    const value = await this.store.getItem(HUB_STORAGE_PREFIX + key);
    if (typeof value === 'string') {
      return JSON.parse(value);
    }
  }

  async set(key, value) {
    const storageKey = HUB_STORAGE_PREFIX + key;
    if (value === undefined) {
      await this.store.removeItem(storageKey);
      return;
    }
    await this.store.setItem(storageKey, JSON.stringify(value));
  }

  async remove(key) {
    await this.store.removeItem(HUB_STORAGE_PREFIX + key);
  }

  async clear() {
    // Only remove keys owned by this backend instead of wiping unrelated data.
    const store = this.store;
    if (typeof store.key !== 'function' || typeof store.length !== 'number') {
      return;
    }
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

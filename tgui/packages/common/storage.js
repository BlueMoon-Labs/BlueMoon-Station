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

const testHubStorage = testGeneric(() => (
  window.hubStorage
  && window.hubStorage.getItem
  && window.hubStorage.setItem
  && window.hubStorage.removeItem
  && window.hubStorage.key
  && typeof window.hubStorage.length === 'number'
));

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
 *
 * hubStorage is shared by every browser control connected to the same BYOND
 * hub, so keys are namespaced instead of reusing the generic web-storage keys.
 */
export class HubStorageBackend {
  constructor() {
    this.impl = IMPL_HUB_STORAGE;
  }

  async get(key) {
    const value = await window.hubStorage.getItem(HUB_STORAGE_PREFIX + key);
    if (typeof value === 'string') {
      return JSON.parse(value);
    }
  }

  async set(key, value) {
    const storageKey = HUB_STORAGE_PREFIX + key;
    if (value === undefined) {
      await window.hubStorage.removeItem(storageKey);
      return;
    }
    await window.hubStorage.setItem(storageKey, JSON.stringify(value));
  }

  async remove(key) {
    await window.hubStorage.removeItem(HUB_STORAGE_PREFIX + key);
  }

  async clear() {
    // hubStorage is shared by every browser control under the same BYOND hub.
    // Only remove keys owned by this backend instead of wiping unrelated data.
    for (let index = window.hubStorage.length - 1; index >= 0; index--) {
      const key = await window.hubStorage.key(index);
      if (typeof key === 'string' && key.startsWith(HUB_STORAGE_PREFIX)) {
        await window.hubStorage.removeItem(key);
      }
    }
  }
}

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
      if (testHubStorage()) {
        try {
          const backend = new HubStorageBackend();
          // Merely exposing hubStorage does not guarantee that its async API is
          // usable. Probe it before selecting it so a disabled/broken WebView2
          // implementation cannot strand TGUI settings.
          await window.hubStorage.getItem(HUB_STORAGE_PROBE_KEY);
          return backend;
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
      // hubStorage can disappear when WebView2 is recreated or when browser
      // options change. Demote only that backend; existing IndexedDB and
      // localStorage errors retain their old, visible failure semantics.
      if (backend.impl !== IMPL_HUB_STORAGE) {
        throw error;
      }
      this.backendPromise = this.getLegacyBackend();
      const fallback = await this.backendPromise;
      return fallback[operation](...args);
    }

    if (backend.impl !== IMPL_HUB_STORAGE) {
      return result;
    }

    if (operation === 'get' && result === undefined) {
      // Preserve settings written before the server enabled BYOND 516
      // storage. Migrate lazily because opening IndexedDB during every TGUI
      // bootstrap would negate the faster hubStorage path.
      const legacyBackend = await this.getLegacyBackend();
      const legacyValue = await legacyBackend.get(...args);
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

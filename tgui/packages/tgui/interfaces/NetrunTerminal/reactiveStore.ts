import { NetrunData } from './types';

/** JSON data only. Keep unchanged branches so panels can subscribe independently. */
export const retainValue = <T, >(previous: T, next: T): T => {
  if (Object.is(previous, next)) { return previous; }
  if (!previous || !next || typeof previous !== 'object' || typeof next !== 'object'
    || Array.isArray(previous) !== Array.isArray(next)) { return next; }
  const keys = Object.keys(next);
  let unchanged = keys.length === Object.keys(previous).length;
  const result = (Array.isArray(next) ? [] : {}) as T;
  for (const key of keys) {
    result[key] = retainValue(previous[key], next[key]);
    if (!Object.prototype.hasOwnProperty.call(previous, key) || result[key] !== previous[key]) { unchanged = false; }
  }
  return unchanged ? previous : result;
};

type BackendStore = {
  getState: () => { backend?: { data?: NetrunData } };
  subscribe: (listener: () => void) => () => void;
};
const EMPTY_DATA = {} as NetrunData;

/** One adapter per TGUI window/store, shared by every NetRun panel. */
export class NetrunReactiveStore {
  private source: NetrunData | undefined;
  private data = EMPTY_DATA;

  constructor(private backend: BackendStore) {}

  subscribe = (listener: () => void) => this.backend.subscribe(listener);

  read = (): NetrunData => {
    const source = this.backend.getState().backend?.data || EMPTY_DATA;
    if (this.source === source) { return this.data; }
    const result = {} as NetrunData;
    let changed = Object.keys(source).length !== Object.keys(this.data).length;
    for (const key of Object.keys(source)) {
      // A map packet is an ordered transport message. Its epoch/revisions and
      // retries belong to NetrunMapStream; never deep-compare the retained graph.
      result[key] = key === 'map' ? source[key] : retainValue(this.data[key], source[key]);
      if (result[key] !== this.data[key]) { changed = true; }
    }
    this.source = source;
    if (changed) { this.data = result; }
    return this.data;
  };
}

const stores = new WeakMap<BackendStore, NetrunReactiveStore>();
export const netrunStoreFor = (backend: BackendStore): NetrunReactiveStore => {
  let store = stores.get(backend);
  if (!store) { store = new NetrunReactiveStore(backend); stores.set(backend, store); }
  return store;
};

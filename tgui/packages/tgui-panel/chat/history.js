/**
 * История чата в хранилище.
 *
 * serverStorage BYOND - один файл: любой setItem или removeItem отправляет
 * клиенту всё хранилище целиком, и тот переписывает файл. Поэтому сохранение
 * пишет один ключ (сообщения, номера и состояние вкладок вместе): сжатым
 * в chat-history-z, если браузер умеет deflate-raw, иначе в chat-history.
 *
 * У каждого сообщения постоянный номер logId. Прежние форматы (куски
 * chat-log-N по segmentSize сообщений, один массив chat-messages) читаются
 * при входе и переезжают в новый ключ первым сохранением.
 */

import { serializeMessage } from './model';

export const HISTORY_KEY = 'chat-history';
// Свой ключ у сжатой: старый код её не поймёт и, не найдя chat-history, не затрёт.
export const HISTORY_PACKED_KEY = 'chat-history-z';
export const HISTORY_INDEX_KEY = 'chat-log-index';
export const HISTORY_SEGMENT_PREFIX = 'chat-log-';
export const LEGACY_MESSAGES_KEY = 'chat-messages';
export const LEGACY_STATE_KEY = 'chat-state';
const HISTORY_VERSION = 2;
const PACKED_VERSION = 3;
const SEGMENT_INDEX_VERSION = 1;

const segmentKey = segment => HISTORY_SEGMENT_PREFIX + segment;

const getTimes = message => message.times || 1;

const toEntry = message => ({
  ...serializeMessage(message),
  logId: message.logId,
});

const entrySize = entry => JSON.stringify(entry).length;

const isValidData = data => data?.version === HISTORY_VERSION
  && Number.isInteger(data.first) && Number.isInteger(data.next)
  && Array.isArray(data.entries);

const addDrop = (data, key) => {
  if (!data.drop.includes(key)) {
    data.drop.push(key);
  }
};

export class ChatHistory {
  /**
   * codec - { name, pack, unpack } из codec.js, null - писать без сжатия.
   */
  constructor(storage, { segmentSize, maxMessages, maxChars = Infinity, codec = null }) {
    this.storage = storage;
    this.segmentSize = segmentSize;
    this.maxMessages = maxMessages;
    this.maxChars = maxChars;
    this.codec = codec;
    // { version, first, next, entries, drop, state }: first - самый старый
    // хранимый номер, next - номер для следующего сообщения, entries -
    // сообщения с номерами до next подряд (пропуск в старых кусках - null),
    // drop - старые ключи на удаление, seq - номер записи.
    this.data = null;
    this.dataPromise = null;
    // Счётчик изменений в памяти и его значение на последней записи: всё,
    // что пришло, пока запись шла, остаётся несохранённым.
    this.changes = 0;
    this.savedChanges = 0;
    this.chars = 0;
    this.saving = null;
  }

  get dirty() {
    return this.changes !== this.savedChanges;
  }

  segmentOf(logId) {
    return Math.floor(logId / this.segmentSize);
  }

  entriesStart() {
    return this.data.next - this.data.entries.length;
  }

  ensureData() {
    if (!this.dataPromise) {
      this.dataPromise = this.readData()
        .then(data => {
          this.chars = data.entries.reduce((sum, entry) => sum + entrySize(entry), 0);
          this.data = data;
          return data;
        })
        .catch(err => {
          this.dataPromise = null;
          throw err;
        });
    }
    return this.dataPromise;
  }

  peek(key) {
    return this.storage.peek ? this.storage.peek(key) : this.storage.get(key);
  }

  async readData() {
    const packed = await this.unpack(await this.storage.get(HISTORY_PACKED_KEY));
    const plain = await this.peek(HISTORY_KEY);
    // Обе копии бывают, если сжатие отказало посреди сеанса: верна поздняя.
    const found = [[packed, HISTORY_PACKED_KEY], [plain, HISTORY_KEY]]
      .filter(([data]) => isValidData(data))
      .sort(([a], [b]) => (b.seq || 0) - (a.seq || 0));
    if (found.length) {
      const [[stored]] = found;
      stored.drop = Array.isArray(stored.drop) ? stored.drop : [];
      // Ключ, в который пишем, из drop не удаляется; несжатая копия уйдёт,
      // как только история ляжет сжатой.
      for (const [, key] of found) {
        if (key === HISTORY_KEY || key !== found[0][1]) {
          addDrop(stored, key);
        }
      }
      if (stored.archive) {
        await this.mergeArchive(stored, stored.archive);
        this.changes++;
      }
      delete stored.archive;
      if (await this.findLeftovers(stored)) {
        this.changes++;
      }
      return stored;
    }
    this.changes++;
    return await this.readSegmented() || this.readLegacy();
  }

  // Удалённые старые ключи может вернуть запись другого окна со старой копией.
  async findLeftovers(data) {
    const before = data.drop.length;
    const index = await this.peek(HISTORY_INDEX_KEY);
    if (index !== undefined) {
      addDrop(data, HISTORY_INDEX_KEY);
      if (Number.isInteger(index?.first) && Number.isInteger(index?.next)) {
        for (let segment = this.segmentOf(index.first);
          segment <= this.segmentOf(index.next - 1); segment++) {
          addDrop(data, segmentKey(segment));
        }
      }
    }
    for (const key of [LEGACY_STATE_KEY, LEGACY_MESSAGES_KEY]) {
      if (await this.peek(key) !== undefined) {
        addDrop(data, key);
      }
    }
    return data.drop.length > before;
  }

  async unpack(stored) {
    if (stored?.version !== PACKED_VERSION) {
      return stored;
    }
    // Без распаковки историю не читаем и не перезаписываем.
    if (stored.codec !== this.codec?.name) {
      throw new Error(`Unsupported chat history codec: ${stored.codec}`);
    }
    try {
      return JSON.parse(await this.codec.unpack(stored.data));
    }
    catch (err) {
      console.error('Corrupted chat history:', err);
      return null;
    }
  }

  async readSegmented() {
    const index = await this.storage.get(HISTORY_INDEX_KEY);
    if (index?.version !== SEGMENT_INDEX_VERSION
      || !Number.isInteger(index.first) || !Number.isInteger(index.next)) {
      return null;
    }
    const data = {
      version: HISTORY_VERSION,
      first: index.first,
      next: index.next,
      entries: [],
      drop: [HISTORY_INDEX_KEY, LEGACY_STATE_KEY],
    };
    if (index.next > index.first) {
      await this.mergeArchive(data,
        { from: this.segmentOf(index.first), end: index.next });
    }
    return data;
  }

  // Куски прежнего формата { from, end } встают перед entries, их ключи - в drop.
  async mergeArchive(data, archive) {
    const start = Math.max(data.first, archive.from * this.segmentSize);
    const end = data.next - data.entries.length;
    const entries = new Array(Math.max(0, end - start)).fill(null);
    for (let segment = archive.from;
      segment <= this.segmentOf(archive.end - 1); segment++) {
      for (const entry of await this.readSegment(segment)) {
        if (Number.isInteger(entry?.logId)
          && entry.logId >= start && entry.logId < Math.min(end, archive.end)) {
          entries[entry.logId - start] = entry;
        }
      }
      data.drop.push(segmentKey(segment));
    }
    data.entries = [...entries, ...data.entries];
    let gaps = 0;
    while (gaps < data.entries.length && !data.entries[gaps]) {
      gaps++;
    }
    data.entries.splice(0, gaps);
    data.first = Math.max(data.first, data.next - data.entries.length);
  }

  // Самый старый формат: один массив под chat-messages.
  async readLegacy() {
    const legacy = await this.storage.get(LEGACY_MESSAGES_KEY);
    const entries = Array.isArray(legacy)
      ? legacy.slice(-this.maxMessages)
        .map((message, logId) => ({ ...message, logId }))
      : [];
    return {
      version: HISTORY_VERSION,
      first: 0,
      next: entries.length,
      entries,
      drop: legacy === undefined ? [] : [LEGACY_MESSAGES_KEY, LEGACY_STATE_KEY],
    };
  }

  async readSegment(segment) {
    const stored = await this.storage.get(segmentKey(segment));
    return Array.isArray(stored) ? stored : [];
  }

  /** Состояние вкладок из последнего сохранения. */
  async loadState() {
    const data = await this.ensureData();
    if (data.state !== undefined) {
      return data.state;
    }
    return this.storage.get(LEGACY_STATE_KEY);
  }

  /**
   * Нумерует новые сообщения и запоминает их и склеенные повторы в памяти,
   * не трогая хранилище. Звать до того, как рендерер может их обрезать.
   * Пока история не прочитана, ничего не делает.
   */
  record(messages) {
    const data = this.data;
    if (!data) {
      return;
    }
    const start = this.entriesStart();
    for (const message of messages) {
      if (!Number.isInteger(message.logId)) {
        message.logId = data.next++;
        message.logTimes = getTimes(message);
        const entry = toEntry(message);
        data.entries.push(entry);
        this.chars += entrySize(entry);
        this.changes++;
      }
      // Повтор того же сообщения увеличивает times у старого, и не обязательно
      // у последнего: на вкладке с фильтром склеивается последнее видимое.
      else if (message.logTimes !== getTimes(message)) {
        if (message.logId >= start && message.logId >= data.first) {
          const offset = message.logId - start;
          const entry = toEntry(message);
          this.chars += entrySize(entry) - entrySize(data.entries[offset]);
          data.entries[offset] = entry;
          this.changes++;
        }
        message.logTimes = getTimes(message);
      }
    }
    // Под заливом редкая запись оставила бы в памяти всё пришедшее.
    if (data.entries.length > this.maxMessages + this.segmentSize) {
      this.trim();
    }
  }

  /**
   * Запоминает сообщения, как record(), и пишет всё несохранённое вместе
   * с состоянием вкладок, если оно передано. Возвращает число обращений
   * к хранилищу.
   */
  save(messages, { state } = {}) {
    return this.enqueue(() => this.saveNow(messages, state));
  }

  /**
   * Стирает историю одной записью. Номера не сбрасываются: новые сообщения
   * продолжают счёт и не путаются со старыми.
   */
  clear() {
    // Граница - на момент клика: пришедшее, пока очистка ждёт своей
    // очереди за записью, остаётся.
    const cutoff = this.data?.next;
    return this.enqueue(() => this.clearNow(cutoff));
  }

  // Записи по очереди: сохранение по таймеру, принудительное при выходе
  // и очистка не должны перемешаться.
  enqueue(run) {
    this.saving = (this.saving || Promise.resolve()).then(run, run);
    this.saving.catch(() => {});
    return this.saving;
  }

  async clearNow(cutoff) {
    const data = await this.ensureData();
    const keepFrom = Number.isInteger(cutoff) ? cutoff : data.next;
    data.entries = data.entries.slice(Math.max(0, keepFrom - this.entriesStart()));
    data.first = Math.max(data.first, keepFrom);
    this.chars = data.entries.reduce((sum, entry) => sum + entrySize(entry), 0);
    this.changes++;
    // Старые ключи очистка не трогает: их уберут следующие сохранения.
    return this.write(false);
  }

  async saveNow(messages, state) {
    const data = await this.ensureData();
    this.record(messages);
    if (state !== undefined && state !== data.state) {
      data.state = state;
      this.changes++;
    }
    if (!this.dirty) {
      return 0;
    }
    this.trim();
    return this.write(true);
  }

  trim() {
    const data = this.data;
    const overLimit = data.next - this.maxMessages - this.entriesStart();
    let drop = 0;
    while (drop < data.entries.length
      && (drop < overLimit || this.chars > this.maxChars || !data.entries[drop])) {
      this.chars -= entrySize(data.entries[drop]);
      drop++;
    }
    if (drop > 0) {
      data.entries.splice(0, drop);
    }
    data.first = Math.max(data.first, this.entriesStart());
  }

  async pack() {
    if (this.codec) {
      try {
        return {
          key: HISTORY_PACKED_KEY,
          value: {
            version: PACKED_VERSION,
            codec: this.codec.name,
            data: await this.codec.pack(JSON.stringify(this.data)),
          },
        };
      }
      catch (err) {
        console.error('Chat history compression failed:', err);
        this.codec = null;
        addDrop(this.data, HISTORY_PACKED_KEY);
      }
    }
    return { key: HISTORY_KEY, value: this.data };
  }

  async write(removeStale) {
    const data = this.data;
    data.seq = (data.seq || 0) + 1;
    const changes = this.changes;
    const { key, value } = await this.pack();
    // chat-state уходит, только когда состояние вкладок легло в новый ключ.
    const stale = removeStale ? data.drop.filter(drop => drop !== key
      && (drop !== LEGACY_STATE_KEY || data.state !== undefined)) : [];
    if (!stale.length || !this.storage.setReplacing) {
      await this.storage.set(key, value);
    }
    else if (await this.storage.setReplacing(key, value, stale)) {
      this.savedChanges = changes;
      data.drop = data.drop.filter(drop => !stale.includes(drop));
      return 1;
    }
    this.savedChanges = changes;
    if (!stale.length) {
      return 1;
    }
    // Иначе по одному старому ключу за сохранение. Вычеркиваем после удачного
    // удаления, в хранилище это попадёт со следующей записью.
    await this.storage.remove(stale[0]);
    data.drop = data.drop.filter(drop => drop !== stale[0]);
    return 2;
  }

  /**
   * До count сообщений с номером меньше beforeId (или самых свежих),
   * от старых к новым.
   */
  async load(count, beforeId) {
    const data = await this.ensureData();
    const end = Math.min(
      Number.isInteger(beforeId) ? beforeId : data.next, data.next);
    const start = Math.max(data.first, this.entriesStart());
    const result = [];
    for (let logId = end - 1; logId >= start && result.length < count; logId--) {
      const entry = data.entries[logId - this.entriesStart()];
      if (entry) {
        result.push({ ...entry, logTimes: getTimes(entry) });
      }
    }
    return result.reverse();
  }

  /** Есть ли в хранилище сообщения старше beforeId. */
  hasOlder(beforeId) {
    if (!this.data) {
      return false;
    }
    const end = Number.isInteger(beforeId) ? beforeId : this.data.next;
    return end > this.data.first;
  }
}

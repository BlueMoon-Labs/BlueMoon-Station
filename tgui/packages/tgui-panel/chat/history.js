/**
 * История чата в хранилище кусками по segmentSize сообщений.
 *
 * Раньше весь хвост лежал под одним ключом и переписывался целиком раз в
 * 10 с, поэтому хранили только 1000 сообщений. Здесь у каждого сообщения
 * постоянный номер logId, кусок с номерами [n * size, (n + 1) * size)
 * лежит под своим ключом, и сохранение переписывает только куски с новыми
 * или изменившимися сообщениями.
 */

import { serializeMessage } from './model';

export const HISTORY_INDEX_KEY = 'chat-log-index';
export const HISTORY_SEGMENT_PREFIX = 'chat-log-';
export const LEGACY_MESSAGES_KEY = 'chat-messages';
const HISTORY_INDEX_VERSION = 1;

const segmentKey = segment => HISTORY_SEGMENT_PREFIX + segment;

const getTimes = message => message.times || 1;

export class ChatHistory {
  constructor(storage, { segmentSize, maxMessages }) {
    this.storage = storage;
    this.segmentSize = segmentSize;
    this.maxMessages = maxMessages;
    // { version, first, next }: first - самый старый хранимый номер,
    // next - номер для следующего сообщения.
    this.index = null;
    this.indexPromise = null;
    this.saving = null;
  }

  segmentOf(logId) {
    return Math.floor(logId / this.segmentSize);
  }

  ensureIndex() {
    if (!this.indexPromise) {
      this.indexPromise = this.readIndex()
        .then(index => {
          this.index = index;
          return index;
        })
        .catch(err => {
          this.indexPromise = null;
          throw err;
        });
    }
    return this.indexPromise;
  }

  async readIndex() {
    const index = await this.storage.get(HISTORY_INDEX_KEY);
    if (index?.version === HISTORY_INDEX_VERSION
      && Number.isInteger(index.first) && Number.isInteger(index.next)) {
      return index;
    }
    return this.migrateLegacy();
  }

  // Старый формат: один массив под chat-messages. Переносим его в куски
  // и удаляем, иначе он занимал бы место рядом с новой историей.
  async migrateLegacy() {
    const legacy = await this.storage.get(LEGACY_MESSAGES_KEY);
    const messages = Array.isArray(legacy)
      ? legacy.slice(-this.maxMessages)
      : [];
    const index = {
      version: HISTORY_INDEX_VERSION,
      first: 0,
      next: messages.length,
    };
    for (let start = 0; start < messages.length; start += this.segmentSize) {
      const segment = messages
        .slice(start, start + this.segmentSize)
        .map((message, i) => ({ ...message, logId: start + i }));
      await this.storage.set(segmentKey(this.segmentOf(start)), segment);
    }
    await this.storage.set(HISTORY_INDEX_KEY, index);
    if (legacy !== undefined) {
      await this.storage.remove(LEGACY_MESSAGES_KEY);
    }
    return index;
  }

  async readSegment(segment) {
    const stored = await this.storage.get(segmentKey(segment));
    return Array.isArray(stored) ? stored : [];
  }

  /**
   * Записывает новые и изменившиеся сообщения. Сообщениям без номера
   * присваивает следующий по порядку. Возвращает число записанных кусков.
   */
  save(messages) {
    // Записи по очереди: сохранение по таймеру и принудительное при рестарте
    // раунда не должны переписывать одни и те же куски вперемешку.
    const run = () => this.saveNow(messages);
    this.saving = (this.saving || Promise.resolve()).then(run, run);
    this.saving.catch(() => {});
    return this.saving;
  }

  async saveNow(messages) {
    const index = await this.ensureIndex();
    const { segmentSize } = this;
    const nextBefore = index.next;
    const dirty = new Set();
    for (const message of messages) {
      if (!Number.isInteger(message.logId)) {
        message.logId = index.next++;
        dirty.add(this.segmentOf(message.logId));
      }
      // Повтор того же сообщения увеличивает times у старого, и не обязательно
      // у последнего: на вкладке с фильтром склеивается последнее видимое.
      else if (message.logTimes !== getTimes(message)) {
        dirty.add(this.segmentOf(message.logId));
      }
    }
    if (dirty.size === 0) {
      return 0;
    }
    const first = Math.max(index.first, index.next - this.maxMessages);
    const bySegment = new Map();
    for (const message of messages) {
      const segment = this.segmentOf(message.logId);
      if (message.logId < first) {
        // Уже вытеснено из хранилища, писать некуда.
        message.logTimes = getTimes(message);
      }
      else if (dirty.has(segment)) {
        if (!bySegment.has(segment)) {
          bySegment.set(segment, []);
        }
        bySegment.get(segment).push(message);
      }
    }
    let written = 0;
    for (const [segment, inMemory] of bySegment) {
      const from = Math.max(segment * segmentSize, first);
      const to = Math.min((segment + 1) * segmentSize, index.next);
      let entries = inMemory.map(message => ({
        ...serializeMessage(message),
        logId: message.logId,
      }));
      // Начало куска уже могло уйти из памяти при обрезке - его берём
      // из записанного, а не теряем.
      if (entries.length < to - from) {
        const fresh = new Set(entries.map(entry => entry.logId));
        const kept = (await this.readSegment(segment))
          .filter(entry => entry.logId >= from && !fresh.has(entry.logId));
        entries = kept.concat(entries)
          .sort((a, b) => a.logId - b.logId);
      }
      await this.storage.set(segmentKey(segment), entries);
      for (const message of inMemory) {
        message.logTimes = getTimes(message);
      }
      written++;
    }
    const trimmed = first > index.first;
    if (trimmed) {
      const lastDropped = this.segmentOf(first) - 1;
      for (let segment = this.segmentOf(index.first);
        segment <= lastDropped; segment++) {
        await this.storage.remove(segmentKey(segment));
      }
      index.first = first;
    }
    // Когда только склеился повтор, номера не сдвинулись и индекс прежний.
    if (trimmed || index.next !== nextBefore) {
      await this.storage.set(HISTORY_INDEX_KEY, index);
    }
    return written;
  }

  /**
   * До count сообщений с номером меньше beforeId (или самых свежих),
   * от старых к новым.
   */
  async load(count, beforeId) {
    const index = await this.ensureIndex();
    const end = Math.min(
      Number.isInteger(beforeId) ? beforeId : index.next, index.next);
    const start = Math.max(index.first, end - count);
    if (start >= end) {
      return [];
    }
    const result = [];
    for (let segment = this.segmentOf(start);
      segment <= this.segmentOf(end - 1); segment++) {
      for (const entry of await this.readSegment(segment)) {
        if (entry.logId >= start && entry.logId < end) {
          result.push({ ...entry, logTimes: getTimes(entry) });
        }
      }
    }
    return result;
  }

  /** Есть ли в хранилище сообщения старше beforeId. */
  hasOlder(beforeId) {
    if (!this.index) {
      return false;
    }
    const end = Number.isInteger(beforeId) ? beforeId : this.index.next;
    return end > this.index.first;
  }
}

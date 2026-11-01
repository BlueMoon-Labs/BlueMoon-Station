import { CompressionStream, DecompressionStream } from 'node:stream/web';
import { TextDecoder, TextEncoder } from 'node:util';

import { StorageProxy } from 'common/storage';

import { createCodec } from './codec';
import { ChatHistory, HISTORY_INDEX_KEY, HISTORY_KEY, HISTORY_PACKED_KEY, LEGACY_MESSAGES_KEY, LEGACY_STATE_KEY } from './history';

const createStorage = (initial = {}) => {
  const data = JSON.parse(JSON.stringify(initial));
  return {
    data,
    get: jest.fn(async key => data[key]),
    set: jest.fn(async (key, value) => {
      data[key] = JSON.parse(JSON.stringify(value));
    }),
    remove: jest.fn(async key => {
      delete data[key];
    }),
  };
};

const message = (n, extra) => ({ type: 'say', html: `m${n}`, ...extra });
const makeMessages = (from, to) => {
  const messages = [];
  for (let n = from; n < to; n++) {
    messages.push(message(n));
  }
  return messages;
};
const writtenKeys = storage => storage.set.mock.calls.map(([key]) => key);
// В serverStorage BYOND каждый set и remove переписывает всё хранилище.
const updates = storage => storage.set.mock.calls.length
  + storage.remove.mock.calls.length
  + (storage.setReplacing?.mock.calls.length || 0);
const clearCalls = storage => {
  storage.set.mockClear();
  storage.remove.mockClear();
};
const htmlOf = messages => messages.map(m => m.html);

// Хранилище в формате прошлой версии: индекс, куски по segmentSize и состояние вкладок.
const segmentedStorage = (count, segmentSize, first = 0) => {
  const initial = {
    [HISTORY_INDEX_KEY]: { version: 1, first, next: count },
    [LEGACY_STATE_KEY]: { version: 5, savedAt: 3 },
  };
  for (let start = 0; start < count; start += segmentSize) {
    if (start + segmentSize <= first) {
      continue;
    }
    initial[`chat-log-${start / segmentSize}`] = makeMessages(start, Math.min(start + segmentSize, count))
      .map((m, i) => ({ ...m, logId: start + i }))
      .filter(m => m.logId >= first);
  }
  return createStorage(initial);
};

describe('ChatHistory', () => {
  test('numbers new messages and keeps them in one key', async () => {
    const storage = createStorage();
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    const messages = makeMessages(0, 6);
    await history.save(messages);
    expect(messages.map(m => m.logId)).toEqual([0, 1, 2, 3, 4, 5]);
    expect(writtenKeys(storage)).toEqual([HISTORY_KEY]);
    expect(htmlOf(storage.data[HISTORY_KEY].entries))
      .toEqual(['m0', 'm1', 'm2', 'm3', 'm4', 'm5']);
  });

  test('a busy chat costs one storage write per save', async () => {
    const storage = createStorage();
    const history = new ChatHistory(storage, { segmentSize: 200, maxMessages: 10000 });
    const messages = makeMessages(0, 1000);
    await history.save(messages, { state: { savedAt: 1 } });
    clearCalls(storage);
    for (let n = 1000; n < 1450; n++) {
      messages.push(message(n));
    }
    messages[3].times = 2;
    await history.save(messages, { state: { savedAt: 2 } });
    expect(updates(storage)).toBe(1);
    expect(writtenKeys(storage)).toEqual([HISTORY_KEY]);
    expect(storage.data[HISTORY_KEY].entries).toHaveLength(1450);
    expect(storage.data[HISTORY_KEY].entries[3].times).toBe(2);
    expect(storage.data[HISTORY_KEY].state).toEqual({ savedAt: 2 });
  });

  test('an unchanged chat writes nothing', async () => {
    const storage = createStorage();
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    const messages = makeMessages(0, 6);
    await history.save(messages);
    clearCalls(storage);
    expect(await history.save(messages)).toBe(0);
    expect(updates(storage)).toBe(0);
  });

  test('a failed write is repeated by the next save', async () => {
    const storage = createStorage();
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    const messages = makeMessages(0, 3);
    storage.set.mockRejectedValueOnce(new Error('quota'));
    await expect(history.save(messages)).rejects.toThrow('quota');
    expect(await history.save(messages)).toBe(1);
    const restarted = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    expect(htmlOf(await restarted.load(100))).toEqual(['m0', 'm1', 'm2']);
  });

  test('recorded messages are saved even after the caller dropped them', async () => {
    const storage = createStorage();
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    await history.load(100);
    const messages = makeMessages(0, 3);
    history.record(messages);
    expect(messages.map(m => m.logId)).toEqual([0, 1, 2]);
    expect(updates(storage)).toBe(0);
    await history.save([message(3)]);
    const restarted = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    expect(htmlOf(await restarted.load(100))).toEqual(['m0', 'm1', 'm2', 'm3']);
  });

  test('a message recorded while a write is running goes out with the next one', async () => {
    const storage = createStorage();
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    await history.load(100);
    let finish;
    storage.set.mockImplementationOnce(async (key, value) => {
      storage.data[key] = JSON.parse(JSON.stringify(value));
      await new Promise(resolve => {
        finish = resolve;
      });
    });
    const saving = history.save(makeMessages(0, 2));
    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();
    history.record([message(2)]);
    finish();
    await saving;
    expect(await history.save([])).toBe(1);
    const restarted = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    expect(htmlOf(await restarted.load(100))).toEqual(['m0', 'm1', 'm2']);
  });

  test('a flood between saves keeps memory at the limit', async () => {
    const storage = createStorage();
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 10 });
    await history.load(100);
    for (let n = 0; n < 200; n++) {
      history.record([message(n)]);
      expect(history.data.entries.length).toBeLessThanOrEqual(14);
    }
    await history.save([]);
    const restarted = new ChatHistory(storage, { segmentSize: 4, maxMessages: 10 });
    expect((await restarted.load(100)).map(m => m.logId))
      .toEqual([190, 191, 192, 193, 194, 195, 196, 197, 198, 199]);
  });

  test('clear keeps what arrived after the click while a save was running', async () => {
    const storage = createStorage();
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    await history.save(makeMessages(0, 3));
    let finish;
    storage.set.mockImplementationOnce(async (key, value) => {
      storage.data[key] = JSON.parse(JSON.stringify(value));
      await new Promise(resolve => {
        finish = resolve;
      });
    });
    const saving = history.save([message(3)]);
    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();
    const clearing = history.clear();
    history.record([message(4)]);
    finish();
    await Promise.all([saving, clearing]);
    const restarted = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    expect(htmlOf(await restarted.load(100))).toEqual(['m4']);
  });

  test('tab state is restored from the same key', async () => {
    const storage = createStorage();
    await new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 })
      .save(makeMessages(0, 2), { state: { version: 5, savedAt: 7 } });
    const restarted = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    expect(await restarted.loadState()).toEqual({ version: 5, savedAt: 7 });
  });

  test('keeps messages that were already pruned from memory', async () => {
    const storage = createStorage();
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    const messages = makeMessages(0, 6);
    await history.save(messages);
    const pruned = messages.slice(5);
    pruned.push(message(6));
    await history.save(pruned);
    const restarted = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    expect(htmlOf(await restarted.load(100)))
      .toEqual(['m0', 'm1', 'm2', 'm3', 'm4', 'm5', 'm6']);
  });

  test('drops messages past the limit and never loads trimmed messages', async () => {
    const storage = createStorage();
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 6 });
    const messages = makeMessages(0, 12);
    await history.save(messages);
    expect(storage.data[HISTORY_KEY].first).toBe(6);
    const loaded = await history.load(100);
    expect(htmlOf(loaded)).toEqual(['m6', 'm7', 'm8', 'm9', 'm10', 'm11']);
    expect(history.hasOlder(6)).toBe(false);
    expect(history.hasOlder(8)).toBe(true);
  });

  test('drops the oldest messages once the log outgrows its char budget', async () => {
    const storage = createStorage();
    const entrySize = JSON.stringify({ type: 'say', html: 'm10', logId: 10 }).length;
    const history = new ChatHistory(storage, {
      segmentSize: 4,
      maxMessages: 100,
      maxChars: entrySize * 5,
    });
    await history.save(makeMessages(10, 30));
    const restarted = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    expect(htmlOf(await restarted.load(100)))
      .toEqual(['m25', 'm26', 'm27', 'm28', 'm29']);
  });

  test('loads the newest page, then older pages before a given number', async () => {
    const storage = createStorage();
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    await history.save(makeMessages(0, 10));
    const restarted = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    const recent = await restarted.load(3);
    expect(recent.map(m => m.logId)).toEqual([7, 8, 9]);
    const older = await restarted.load(5, 7);
    expect(older.map(m => m.logId)).toEqual([2, 3, 4, 5, 6]);
    expect(restarted.hasOlder(2)).toBe(true);
    expect(restarted.hasOlder(0)).toBe(false);
  });

  test('restored messages are not written again, new ones continue the numbering', async () => {
    const storage = createStorage();
    await new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 })
      .save(makeMessages(0, 6));
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    const restored = await history.load(100);
    clearCalls(storage);
    expect(await history.save(restored)).toBe(0);
    restored.push(message(6));
    await history.save(restored);
    expect(restored[6].logId).toBe(6);
    expect(writtenKeys(storage)).toEqual([HISTORY_KEY]);
  });

  test('moves the old single-key log in one write', async () => {
    const storage = createStorage({ [LEGACY_MESSAGES_KEY]: makeMessages(0, 5) });
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    const loaded = await history.load(100);
    expect(htmlOf(loaded)).toEqual(['m0', 'm1', 'm2', 'm3', 'm4']);
    expect(loaded.map(m => m.logId)).toEqual([0, 1, 2, 3, 4]);
    expect(updates(storage)).toBe(0);
    await history.save(loaded);
    expect(updates(storage)).toBe(2);
    expect(storage.data[LEGACY_MESSAGES_KEY]).toBeUndefined();
    const restarted = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    expect(htmlOf(await restarted.load(100))).toEqual(htmlOf(loaded));
  });

  test('reads the segmented log as is and keeps its numbering', async () => {
    const storage = segmentedStorage(10, 4, 2);
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    const loaded = await history.load(100);
    expect(loaded.map(m => m.logId)).toEqual([2, 3, 4, 5, 6, 7, 8, 9]);
    expect(await history.loadState()).toEqual({ version: 5, savedAt: 3 });
    expect(updates(storage)).toBe(0);
    const messages = loaded.slice(4);
    messages.push(message(10));
    await history.save(messages, { state: { version: 5, savedAt: 4 } });
    expect(messages[4].logId).toBe(10);
    const restarted = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    expect((await restarted.load(100)).map(m => m.logId))
      .toEqual([2, 3, 4, 5, 6, 7, 8, 9, 10]);
    expect(await restarted.loadState()).toEqual({ version: 5, savedAt: 4 });
  });

  test('without forget the segmented log moves at once and its keys go one per save', async () => {
    const storage = segmentedStorage(12, 4);
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 12 });
    const messages = await history.load(100);
    const save = async state => {
      clearCalls(storage);
      messages.push(message(messages.length));
      await history.save(messages, { state });
      return storage.remove.mock.calls.map(([key]) => key);
    };
    expect(await save({ savedAt: 1 })).toEqual([HISTORY_INDEX_KEY]);
    expect(updates(storage)).toBe(2);
    expect(await save({ savedAt: 2 })).toEqual([LEGACY_STATE_KEY]);
    expect(await save({ savedAt: 3 })).toEqual(['chat-log-0']);
    expect(await save({ savedAt: 4 })).toEqual(['chat-log-1']);
    expect(await save({ savedAt: 5 })).toEqual(['chat-log-2']);
    expect(await save({ savedAt: 6 })).toEqual([]);
    expect(updates(storage)).toBe(1);
    expect(Object.keys(storage.data)).toEqual([HISTORY_KEY]);
    const restarted = new ChatHistory(storage, { segmentSize: 4, maxMessages: 12 });
    expect((await restarted.load(100)).map(m => m.logId))
      .toEqual([6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]);
  });

  test('a failed removal of an old key is repeated in the same session', async () => {
    const storage = segmentedStorage(8, 4);
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    const messages = await history.load(100);
    storage.remove.mockRejectedValueOnce(new Error('gone'));
    await expect(history.save(messages, { state: { savedAt: 1 } })).rejects.toThrow('gone');
    expect(storage.data[HISTORY_INDEX_KEY]).toBeDefined();
    clearCalls(storage);
    await history.save(messages, { state: { savedAt: 2 } });
    expect(storage.remove.mock.calls.map(([key]) => key)).toEqual([HISTORY_INDEX_KEY]);
    expect(storage.data[HISTORY_INDEX_KEY]).toBeUndefined();
  });

  test('the segmented log counts toward the char budget', async () => {
    const storage = segmentedStorage(12, 4);
    const sample = JSON.stringify({ type: 'say', html: 'm10', logId: 10 }).length;
    const history = new ChatHistory(storage, {
      segmentSize: 4,
      maxMessages: 100,
      maxChars: sample * 10,
    });
    const messages = await history.load(100);
    messages.push(message(12), message(13));
    await history.save(messages, { state: { savedAt: 1 } });
    // 12 старых + 2 новых больше 10: самый старый кусок уходит целиком.
    const restarted = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    expect((await restarted.load(100)).map(m => m.logId))
      .toEqual([4, 5, 6, 7, 8, 9, 10, 11, 12, 13]);
  });

  test('a repeat merged into a message of the segmented log lands in the history key', async () => {
    const storage = segmentedStorage(8, 4);
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    const messages = await history.load(100);
    await history.save(messages, { state: { savedAt: 1 } });
    clearCalls(storage);
    messages[5].times = 3;
    await history.save(messages, { state: { savedAt: 2 } });
    expect(writtenKeys(storage)).toEqual([HISTORY_KEY]);
    const restarted = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    expect((await restarted.load(100))[5].times).toBe(3);
  });

  test('a gap in the segmented log is skipped when loading pages', async () => {
    const storage = segmentedStorage(12, 4);
    delete storage.data['chat-log-1'];
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    expect((await history.load(6)).map(m => m.logId)).toEqual([2, 3, 8, 9, 10, 11]);
    expect((await history.load(100, 8)).map(m => m.logId)).toEqual([0, 1, 2, 3]);
    await history.save([message(12)], { state: { savedAt: 1 } });
    const restarted = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    expect((await restarted.load(100)).map(m => m.logId))
      .toEqual([0, 1, 2, 3, 8, 9, 10, 11, 12]);
  });

  test('a history with a segmented archive from the previous version moves it into the key', async () => {
    const storage = segmentedStorage(8, 4);
    storage.data[HISTORY_KEY] = {
      version: 2, first: 0, next: 10,
      entries: [{ ...message(8), logId: 8 }, { ...message(9), logId: 9 }],
      archive: { from: 0, end: 8 }, drop: [HISTORY_INDEX_KEY], state: { savedAt: 2 },
    };
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    expect((await history.load(100)).map(m => m.logId))
      .toEqual([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
    await history.save([], { state: { savedAt: 2 } });
    expect(storage.data[HISTORY_KEY].archive).toBeUndefined();
    expect(storage.data[HISTORY_KEY].entries).toHaveLength(10);
  });

  test('clear drops the whole log in one write, new messages start after the old numbers', async () => {
    const storage = createStorage();
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    await history.save(makeMessages(0, 10), { state: { savedAt: 1 } });
    clearCalls(storage);
    await history.clear();
    expect(updates(storage)).toBe(1);
    expect(await history.load(100)).toEqual([]);
    expect(history.hasOlder()).toBe(false);
    expect(await history.loadState()).toEqual({ savedAt: 1 });
    const fresh = [message(10)];
    await history.save(fresh);
    expect(fresh[0].logId).toBe(10);
    const restarted = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    expect(htmlOf(await restarted.load(100))).toEqual(['m10']);
  });

  test('clear hides the segmented log at once and removes its keys later', async () => {
    const storage = segmentedStorage(8, 4);
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    await history.clear();
    expect(updates(storage)).toBe(1);
    expect(await history.load(100)).toEqual([]);
    const restarted = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    expect(await restarted.load(100)).toEqual([]);
    const messages = [message(8)];
    for (let savedAt = 1; savedAt <= 5; savedAt++) {
      await restarted.save(messages, { state: { savedAt } });
    }
    expect(Object.keys(storage.data)).toEqual([HISTORY_KEY]);
    expect(htmlOf(await restarted.load(100))).toEqual(['m8']);
  });

  test('clear waits for a save already in progress', async () => {
    const storage = createStorage();
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    const saving = history.save(makeMessages(0, 6));
    const clearing = history.clear();
    await Promise.all([saving, clearing]);
    expect(await history.load(100)).toEqual([]);
  });

  test('clear also drops the old single-key log', async () => {
    const storage = createStorage({ [LEGACY_MESSAGES_KEY]: makeMessages(0, 3) });
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    await history.clear();
    expect(await history.load(100)).toEqual([]);
    await history.save([message(3)]);
    expect(storage.data[LEGACY_MESSAGES_KEY]).toBeUndefined();
    const restarted = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    expect(htmlOf(await restarted.load(100))).toEqual(['m3']);
  });
});

// setReplacing как у serverStorage: запись ключа и удаление старых - одна перезапись файла.
const replacingStorage = storage => {
  storage.setReplacing = jest.fn(async (key, value, keys) => {
    for (const removed of keys) {
      delete storage.data[removed];
    }
    storage.data[key] = JSON.parse(JSON.stringify(value));
    return true;
  });
  return storage;
};

const codec = createCodec({ CompressionStream, DecompressionStream, TextEncoder, TextDecoder });

describe('ChatHistory with one-write cleanup and compression', () => {
  test('the segmented log moves with all its keys in one write', async () => {
    const storage = replacingStorage(segmentedStorage(12, 4));
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    const messages = await history.load(100);
    messages.push(message(12));
    expect(await history.save(messages, { state: { savedAt: 1 } })).toBe(1);
    expect(updates(storage)).toBe(1);
    expect(storage.setReplacing).toHaveBeenCalledWith(HISTORY_KEY, expect.anything(),
      [HISTORY_INDEX_KEY, LEGACY_STATE_KEY, 'chat-log-0', 'chat-log-1', 'chat-log-2']);
    expect(Object.keys(storage.data)).toEqual([HISTORY_KEY]);
    storage.setReplacing.mockClear();
    messages.push(message(13));
    await history.save(messages, { state: { savedAt: 2 } });
    expect(storage.setReplacing).not.toHaveBeenCalled();
    expect(storage.data[HISTORY_KEY].drop).toEqual([]);
    const restarted = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    expect((await restarted.load(100)).map(m => m.logId))
      .toEqual([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]);
  });

  test('chat-state stays until the tab state is saved', async () => {
    const storage = replacingStorage(segmentedStorage(4, 4));
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    await history.save([message(0)]);
    expect(storage.data[LEGACY_STATE_KEY]).toEqual({ version: 5, savedAt: 3 });
    await history.save([], { state: { savedAt: 4 } });
    expect(Object.keys(storage.data)).toEqual([HISTORY_KEY]);
  });

  test('when one-write cleanup is refused the old keys go one per save', async () => {
    const storage = replacingStorage(segmentedStorage(8, 4));
    storage.setReplacing.mockImplementation(async (key, value) => {
      storage.data[key] = JSON.parse(JSON.stringify(value));
      return false;
    });
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    const messages = await history.load(100);
    expect(await history.save(messages, { state: { savedAt: 1 } })).toBe(2);
    expect(storage.remove.mock.calls.map(([key]) => key)).toEqual([HISTORY_INDEX_KEY]);
  });

  test('old keys that came back are dropped again', async () => {
    const storage = replacingStorage(createStorage());
    const options = { segmentSize: 4, maxMessages: 100, codec };
    await new ChatHistory(storage, options).save(makeMessages(0, 3), { state: { savedAt: 1 } });
    Object.assign(storage.data, segmentedStorage(8, 4).data);
    const history = new ChatHistory(storage, options);
    expect(htmlOf(await history.load(100))).toEqual(['m0', 'm1', 'm2']);
    await history.save([], { state: { savedAt: 1 } });
    expect(Object.keys(storage.data)).toEqual([HISTORY_PACKED_KEY]);
  });

  test('a lost first segment leaves no endless older page', async () => {
    const storage = segmentedStorage(12, 4);
    delete storage.data['chat-log-0'];
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    expect((await history.load(100)).map(m => m.logId)).toEqual([4, 5, 6, 7, 8, 9, 10, 11]);
    expect(history.hasOlder(4)).toBe(false);
  });

  test('history is written compressed under its own key and read back', async () => {
    const storage = createStorage();
    const options = { segmentSize: 4, maxMessages: 100, codec };
    const messages = makeMessages(0, 50).map((m, n) => ({ ...m, html: `<b>Сообщение ${n}</b>` }));
    await new ChatHistory(storage, options).save(messages, { state: { savedAt: 5 } });
    expect(Object.keys(storage.data)).toEqual([HISTORY_PACKED_KEY]);
    const stored = storage.data[HISTORY_PACKED_KEY];
    expect(stored).toEqual({ version: 3, codec: 'deflate-raw', data: expect.any(String) });
    expect(stored.data.length).toBeLessThan(JSON.stringify(messages).length / 2);
    const restarted = new ChatHistory(storage, options);
    expect(htmlOf(await restarted.load(100))).toEqual(htmlOf(messages));
    expect(await restarted.loadState()).toEqual({ savedAt: 5 });
  });

  test('an uncompressed history is moved into the compressed key', async () => {
    const storage = replacingStorage(createStorage());
    await new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 }).save(makeMessages(0, 3));
    expect(storage.data[HISTORY_KEY].version).toBe(2);
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100, codec });
    const messages = await history.load(100);
    messages.push(message(3));
    expect(await history.save(messages)).toBe(1);
    expect(Object.keys(storage.data)).toEqual([HISTORY_PACKED_KEY]);
    const restarted = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100, codec });
    expect(htmlOf(await restarted.load(100))).toEqual(['m0', 'm1', 'm2', 'm3']);
  });

  test('old code sees no chat-history and the compressed copy survives it', async () => {
    const storage = createStorage();
    const options = { segmentSize: 4, maxMessages: 100, codec };
    await new ChatHistory(storage, options).save(makeMessages(0, 3));
    expect(storage.data[HISTORY_KEY]).toBeUndefined();
    // Старый код начал бы историю заново в chat-history, сжатую не трогая.
    storage.data[HISTORY_KEY] = { version: 2, first: 0, next: 0, entries: [], drop: [] };
    const history = new ChatHistory(storage, options);
    expect(htmlOf(await history.load(100))).toEqual(['m0', 'm1', 'm2']);
  });

  test('a message recorded while compressing goes out with the next write', async () => {
    const storage = createStorage();
    let finish;
    const slowCodec = {
      ...codec,
      pack: async text => {
        await new Promise(resolve => {
          finish = resolve;
        });
        return codec.pack(text);
      },
    };
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100, codec: slowCodec });
    await history.load(100);
    const saving = history.save(makeMessages(0, 2));
    for (let i = 0; i < 10 && !finish; i++) {
      await Promise.resolve();
    }
    history.record([message(2)]);
    finish();
    await saving;
    const restarted = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100, codec });
    expect(htmlOf(await restarted.load(100))).toEqual(['m0', 'm1']);
    finish = null;
    const next = history.save([]);
    for (let i = 0; i < 10 && !finish; i++) {
      await Promise.resolve();
    }
    finish();
    expect(await next).toBe(1);
    expect(htmlOf(await new ChatHistory(storage, { segmentSize: 4, maxMessages: 100, codec })
      .load(100))).toEqual(['m0', 'm1', 'm2']);
  });

  test('old keys stay until the new history is written: a stuck compression loses nothing', async () => {
    localStorage.clear();
    for (const [key, value] of Object.entries(segmentedStorage(8, 4).data)) {
      localStorage.setItem(key, JSON.stringify(value));
    }
    const stuckCodec = { ...codec, pack: () => new Promise(() => {}) };
    const history = new ChatHistory(new StorageProxy(),
      { segmentSize: 4, maxMessages: 100, codec: stuckCodec });
    const messages = await history.load(100);
    history.save(messages, { state: { savedAt: 1 } });
    await new Promise(resolve => setTimeout(resolve, 10));
    expect(localStorage.getItem(HISTORY_INDEX_KEY)).not.toBeNull();
    const restarted = new ChatHistory(new StorageProxy(), { segmentSize: 4, maxMessages: 100 });
    expect((await restarted.load(100)).map(m => m.logId)).toEqual([0, 1, 2, 3, 4, 5, 6, 7]);
    localStorage.clear();
  });

  test('old keys stay when the new history fails to write', async () => {
    localStorage.clear();
    for (const [key, value] of Object.entries(segmentedStorage(8, 4).data)) {
      localStorage.setItem(key, JSON.stringify(value));
    }
    const history = new ChatHistory(new StorageProxy(), { segmentSize: 4, maxMessages: 100, codec });
    const messages = await history.load(100);
    const setItem = jest.spyOn(Storage.prototype, 'setItem').mockImplementation(() => {
      throw new Error('quota');
    });
    await expect(history.save(messages, { state: { savedAt: 1 } })).rejects.toThrow('quota');
    setItem.mockRestore();
    const restarted = new ChatHistory(new StorageProxy(), { segmentSize: 4, maxMessages: 100, codec });
    expect((await restarted.load(100)).map(m => m.logId)).toEqual([0, 1, 2, 3, 4, 5, 6, 7]);
    localStorage.clear();
  });

  test('a failed compression falls back to a plain write', async () => {
    const storage = createStorage();
    const brokenCodec = { ...codec, pack: jest.fn().mockRejectedValue(new Error('no zlib')) };
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100, codec: brokenCodec });
    const error = jest.spyOn(console, 'error').mockImplementation(() => {});
    await history.save(makeMessages(0, 2));
    error.mockRestore();
    expect(storage.data[HISTORY_KEY].version).toBe(2);
    expect(htmlOf(storage.data[HISTORY_KEY].entries)).toEqual(['m0', 'm1']);
  });

  test('after compression broke mid-session the plain copy replaces the packed one', async () => {
    const storage = replacingStorage(createStorage());
    const options = { segmentSize: 4, maxMessages: 100, codec };
    const history = new ChatHistory(storage, options);
    const messages = makeMessages(0, 2);
    await history.save(messages);
    history.codec = { ...codec, pack: jest.fn().mockRejectedValue(new Error('no zlib')) };
    const error = jest.spyOn(console, 'error').mockImplementation(() => {});
    messages.push(message(2));
    await history.save(messages);
    error.mockRestore();
    expect(Object.keys(storage.data)).toEqual([HISTORY_KEY]);
    const restarted = new ChatHistory(storage, options);
    expect(htmlOf(await restarted.load(100))).toEqual(['m0', 'm1', 'm2']);
    await restarted.save([message(3)]);
    expect(Object.keys(storage.data)).toEqual([HISTORY_PACKED_KEY]);
  });

  test('a compressed history is neither read nor overwritten without the codec', async () => {
    const storage = createStorage();
    await new ChatHistory(storage, { segmentSize: 4, maxMessages: 100, codec })
      .save(makeMessages(0, 3));
    const stored = storage.data[HISTORY_PACKED_KEY];
    clearCalls(storage);
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    await expect(history.load(100)).rejects.toThrow('codec');
    await expect(history.save([message(3)])).rejects.toThrow('codec');
    expect(updates(storage)).toBe(0);
    expect(storage.data[HISTORY_PACKED_KEY]).toEqual(stored);
  });

  test('a damaged compressed history starts over', async () => {
    const storage = createStorage({
      [HISTORY_PACKED_KEY]: { version: 3, codec: 'deflate-raw', data: 'AAAAAAAA' },
    });
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100, codec });
    const error = jest.spyOn(console, 'error').mockImplementation(() => {});
    expect(await history.load(100)).toEqual([]);
    error.mockRestore();
    const messages = [message(0)];
    await history.save(messages);
    expect(messages[0].logId).toBe(0);
  });
});

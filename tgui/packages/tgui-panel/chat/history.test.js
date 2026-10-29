import { ChatHistory, HISTORY_INDEX_KEY, LEGACY_MESSAGES_KEY } from './history';

const createStorage = (initial = {}) => {
  const data = { ...initial };
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

describe('ChatHistory', () => {
  test('numbers new messages and writes only the segments they land in', async () => {
    const storage = createStorage();
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    const messages = makeMessages(0, 6);
    await history.save(messages);
    expect(messages.map(m => m.logId)).toEqual([0, 1, 2, 3, 4, 5]);
    expect(storage.data['chat-log-0'].map(m => m.html))
      .toEqual(['m0', 'm1', 'm2', 'm3']);
    expect(storage.data['chat-log-1'].map(m => m.html)).toEqual(['m4', 'm5']);

    storage.set.mockClear();
    messages.push(message(6));
    await history.save(messages);
    expect(writtenKeys(storage)).toEqual(['chat-log-1', HISTORY_INDEX_KEY]);
  });

  test('an unchanged chat writes nothing', async () => {
    const storage = createStorage();
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    const messages = makeMessages(0, 6);
    await history.save(messages);
    storage.set.mockClear();
    expect(await history.save(messages)).toBe(0);
    expect(storage.set).not.toHaveBeenCalled();
  });

  test('a repeat merged into an old message rewrites only its segment', async () => {
    const storage = createStorage();
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    const messages = makeMessages(0, 10);
    await history.save(messages);
    storage.set.mockClear();
    messages[1].times = 3;
    await history.save(messages);
    expect(writtenKeys(storage)).toEqual(['chat-log-0']);
    expect(storage.data['chat-log-0'][1].times).toBe(3);
  });

  test('keeps the segment head that was already pruned from memory', async () => {
    const storage = createStorage();
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    const messages = makeMessages(0, 6);
    await history.save(messages);
    const pruned = messages.slice(5);
    pruned.push(message(6));
    await history.save(pruned);
    expect(storage.data['chat-log-1'].map(m => m.html))
      .toEqual(['m4', 'm5', 'm6']);
  });

  test('drops segments past the limit and never loads trimmed messages', async () => {
    const storage = createStorage();
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 6 });
    const messages = makeMessages(0, 12);
    await history.save(messages);
    expect(storage.data['chat-log-0']).toBeUndefined();
    expect(storage.data[HISTORY_INDEX_KEY].first).toBe(6);
    const loaded = await history.load(100);
    expect(loaded.map(m => m.html)).toEqual(['m6', 'm7', 'm8', 'm9', 'm10', 'm11']);
    expect(history.hasOlder(6)).toBe(false);
    expect(history.hasOlder(8)).toBe(true);
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
    storage.set.mockClear();
    expect(await history.save(restored)).toBe(0);
    restored.push(message(6));
    await history.save(restored);
    expect(restored[6].logId).toBe(6);
    expect(writtenKeys(storage)).toEqual(['chat-log-1', HISTORY_INDEX_KEY]);
  });

  test('moves the old single-key log into segments', async () => {
    const legacy = makeMessages(0, 5);
    const storage = createStorage({ [LEGACY_MESSAGES_KEY]: legacy });
    const history = new ChatHistory(storage, { segmentSize: 4, maxMessages: 100 });
    const loaded = await history.load(100);
    expect(loaded.map(m => m.html)).toEqual(['m0', 'm1', 'm2', 'm3', 'm4']);
    expect(loaded.map(m => m.logId)).toEqual([0, 1, 2, 3, 4]);
    expect(storage.data[LEGACY_MESSAGES_KEY]).toBeUndefined();
  });

  test('a busy chat writes one segment per save, not the whole log', async () => {
    const storage = createStorage();
    const history = new ChatHistory(storage, { segmentSize: 200, maxMessages: 10000 });
    const messages = makeMessages(0, 1000);
    await history.save(messages);
    storage.set.mockClear();
    messages.push(message(1000), message(1001));
    await history.save(messages);
    expect(writtenKeys(storage)).toEqual(['chat-log-5', HISTORY_INDEX_KEY]);
    expect(storage.data['chat-log-5']).toHaveLength(2);
  });
});

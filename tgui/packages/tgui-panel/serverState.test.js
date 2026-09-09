import { backendCreatePayloadQueue, sendMessage } from 'tgui/backend';

import { flushSaveToServer, forgetSentState } from './serverState';

jest.mock('tgui/backend', () => ({
  backendCreatePayloadQueue: jest.fn(payload => ({
    type: 'backend/createPayloadQueue',
    payload,
  })),
  sendMessage: jest.fn(),
}));

const createStore = ({
  dispatch = jest.fn(),
  highlightText = '',
} = {}) => ({
  dispatch,
  getState: () => ({
    settings: {
      version: 1,
      theme: 'default',
      view: {
        visible: false,
      },
      highlightText,
      highlightColor: '#ffdd44',
    },
    chat: {
      version: 5,
      currentPageId: 'page-main',
      pages: ['page-main'],
      pageById: {
        'page-main': {
          id: 'page-main',
          name: 'Main',
          acceptedTypes: {
            system: true,
            ooc: false,
          },
          unreadCount: 2,
          createdAt: 123,
        },
      },
    },
  }),
});

describe('tgui panel serverState', () => {
  let dateNowSpy;

  beforeEach(() => {
    jest.clearAllMocks();
    backendCreatePayloadQueue.mockImplementation(payload => ({
      type: 'backend/createPayloadQueue',
      payload,
    }));
    dateNowSpy = jest.spyOn(Date, 'now').mockReturnValue(1234);
    window.__windowId__ = 'browseroutput';
    global.Byond = {
      topic: jest.fn(),
    };
  });

  afterEach(() => {
    dateNowSpy.mockRestore();
  });

  test('sends compact panel state directly when it fits into a BYOND topic URL', () => {
    const store = createStore({
      highlightText: 'foo',
    });

    flushSaveToServer(store);

    expect(global.Byond.topic).toHaveBeenCalledTimes(1);
    expect(sendMessage).not.toHaveBeenCalled();

    const message = global.Byond.topic.mock.calls[0][0];
    expect(message).toEqual(expect.objectContaining({
      tgui: 1,
      window_id: 'browseroutput',
      type: 'panel/state_set',
    }));
    expect(message).not.toHaveProperty('payload');

    const state = JSON.parse(message.panel_state);
    expect(state.settings.highlightText).toBe('foo');
    expect(state.settings).not.toHaveProperty('theme');
    expect(state.settings).not.toHaveProperty('view');
    expect(state.chat.pageById['0'].acceptedTypes).toEqual(['system']);
  });

  // Раунд 10137: 6230 синхронных записей савфайла на 32.8 с полной заморозки процесса,
  // 30-34% всего дрифта тик-спайков. Серверный гард "состояние не изменилось - не пиши"
  // не мог сработать никогда, потому что savedAt рос на каждой сборке payload'а и
  // строка всегда отличалась.
  test('skips the round trip when the persisted state has not changed', () => {
    const store = createStore({
      highlightText: 'unchanged-marker',
    });

    flushSaveToServer(store);
    expect(global.Byond.topic).toHaveBeenCalledTimes(1);
    const first = JSON.parse(global.Byond.topic.mock.calls[0][0].panel_state);

    flushSaveToServer(store);
    expect(global.Byond.topic).toHaveBeenCalledTimes(1);

    const changed = createStore({
      highlightText: 'changed-marker',
    });
    flushSaveToServer(changed);
    expect(global.Byond.topic).toHaveBeenCalledTimes(2);

    // savedAt обязан остаться монотонным по фактически отправленным состояниям:
    // на нём стоит выбор свежей копии между сервером и браузерным хранилищем.
    const second = JSON.parse(global.Byond.topic.mock.calls[1][0].panel_state);
    expect(second.savedAt).toBe(first.savedAt + 1);
  });

  test('chunks large panel state so long highlight lists avoid HTTP fallback', () => {
    const dispatch = jest.fn();
    const store = createStore({
      dispatch,
      highlightText: 'Ж'.repeat(600),
    });

    flushSaveToServer(store);

    expect(global.Byond.topic).not.toHaveBeenCalled();
    expect(backendCreatePayloadQueue).toHaveBeenCalledTimes(1);
    expect(dispatch).toHaveBeenCalledTimes(1);

    const queuePayload = backendCreatePayloadQueue.mock.calls[0][0];
    expect(queuePayload.id).toMatch(/^panel-state-1234-/);
    expect(queuePayload.chunks.length).toBeGreaterThan(1);
    // Тот же бюджет, что CHUNK_ENCODED_SIZE в serverState.js и CHUNK_BUDGET в tgui/backend.ts.
    expect(queuePayload.chunks.every(
      chunk => encodeURIComponent(chunk).length <= 900,
    )).toBe(true);

    expect(dispatch).toHaveBeenCalledWith({
      type: 'backend/createPayloadQueue',
      payload: queuePayload,
    });
    expect(sendMessage).toHaveBeenCalledWith({
      type: 'oversizedPayloadRequest',
      payload: {
        type: 'panel/state_set',
        id: queuePayload.id,
        chunkCount: queuePayload.chunks.length,
      },
    });

    const payload = JSON.parse(queuePayload.chunks.join(''));
    const state = JSON.parse(payload.state);
    expect(state.settings.highlightText).toBe('Ж'.repeat(600));
  });

  // Дедупликация помечает тело отправленным ДО того, как транспорт отработал. Если отправка
  // упала, отметку надо снять: иначе повторный вызов с тем же состоянием будет отброшен как
  // дубликат, и на сервер не уедет ничего до следующей правки настроек.
  test('resends the same state after the server pushed its own panel/state', () => {
    const store = createStore({
      highlightText: 'reconnect-marker',
    });

    flushSaveToServer(store);
    expect(global.Byond.topic).toHaveBeenCalledTimes(1);

    // Сервер прислал состояние (реконнект): что у него на самом деле лежит, клиент не
    // знает, поэтому следующая сборка обязана уйти даже без изменений.
    forgetSentState();
    flushSaveToServer(store);
    expect(global.Byond.topic).toHaveBeenCalledTimes(2);

    flushSaveToServer(store);
    expect(global.Byond.topic).toHaveBeenCalledTimes(2);
  });

  test('resends the same state after a failed transport instead of skipping it as a duplicate', () => {
    const store = createStore({
      highlightText: 'transport-failure-marker',
    });
    const consoleSpy = jest.spyOn(console, 'error').mockImplementation(() => {});

    global.Byond.topic.mockImplementationOnce(() => {
      throw new Error('topic transport failed');
    });

    flushSaveToServer(store);
    expect(global.Byond.topic).toHaveBeenCalledTimes(1);
    expect(consoleSpy).toHaveBeenCalled();

    flushSaveToServer(store);
    expect(global.Byond.topic).toHaveBeenCalledTimes(2);

    const failed = JSON.parse(global.Byond.topic.mock.calls[0][0].panel_state);
    const resent = JSON.parse(global.Byond.topic.mock.calls[1][0].panel_state);
    expect(resent.settings.highlightText).toBe('transport-failure-marker');
    // Счётчик savedAt тоже откатывается: неудачная отправка не должна его тратить.
    expect(resent.savedAt).toBe(failed.savedAt);

    consoleSpy.mockRestore();
  });
});

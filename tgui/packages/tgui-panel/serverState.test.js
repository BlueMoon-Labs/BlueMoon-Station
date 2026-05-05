import { backendCreatePayloadQueue, sendMessage } from 'tgui/backend';

import { flushSaveToServer } from './serverState';

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
    expect(queuePayload.chunks.every(
      chunk => encodeURIComponent(chunk).length <= 512,
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
});

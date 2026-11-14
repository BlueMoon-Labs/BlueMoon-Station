import { applyMiddleware, combineReducers, createStore } from 'common/redux';

import { loadSettings, updateSettings } from '../settings/actions';
import { settingsReducer } from '../settings/reducer';
import { HISTORY_KEY } from './history';
import { selectChat } from './selectors';

// Stable singleton mock instance.
// `mock`-prefixed name is required so jest.mock() factory can capture it.
const mockChatRenderer = {
  events: {
    on: jest.fn(),
    off: jest.fn(),
    emit: jest.fn(),
  },
  setHighlight: jest.fn(),
  setHighlightSound: jest.fn(),
  setChatClasses: jest.fn(),
  setBgAnimation: jest.fn(),
  setCustomColors: jest.fn(),
  setCustomProperties: jest.fn(),
  setRadioJobsVisible: jest.fn(),
  setNewMessagesMarker: jest.fn(),
  setRadioJobStyle: jest.fn(),
  setStyleOverrides: jest.fn(),
  setTypeOverrides: jest.fn(),
  setGameEffects: jest.fn(),
  setSettleOld: jest.fn(),
  setTimestamps: jest.fn(),
  setTimeDividers: jest.fn(),
  changePage: jest.fn(),
  onStateLoaded: jest.fn(),
  processBatch: jest.fn(),
  rebuildChat: jest.fn(),
  clearChat: jest.fn(),
  pruneSoon: jest.fn(),
  setVisibleLimit: jest.fn(),
  saveToDisk: jest.fn(),
  messages: [],
  messagesVersion: 0,
};

jest.mock('./renderer', () => ({
  chatRenderer: mockChatRenderer,
}));

jest.mock('common/storage', () => ({
  storage: {
    get: jest.fn().mockResolvedValue(undefined),
    set: jest.fn().mockResolvedValue(undefined),
    remove: jest.fn().mockResolvedValue(undefined),
  },
}));

jest.mock('../serverState', () => ({
  scheduleSaveToServer: jest.fn(),
  flushSaveToServer: jest.fn(),
  getLastSavedAt: jest.fn(() => 0),
}));

jest.mock('dompurify', () => ({
  __esModule: true,
  default: { sanitize: (html) => html },
}));

const flushPromises = () => new Promise(resolve => setTimeout(resolve, 0));

// Только микрозадачи: запись при уходе со страницы не может ждать таймер.
const flushMicrotasks = async () => {
  for (let i = 0; i < 50; i++) {
    await Promise.resolve();
  }
};

const clearRendererSpies = () => {
  for (const key of Object.keys(mockChatRenderer)) {
    const value = mockChatRenderer[key];
    if (typeof value?.mockClear === 'function') {
      value.mockClear();
    }
  }
  for (const key of Object.keys(mockChatRenderer.events)) {
    mockChatRenderer.events[key].mockClear();
  }
};

// applySettings now lives in a closure created per-store, so each fresh
// store gets clean diff state without needing module isolation.
const createTestStore = () => {
  // Use require() so the chat reducer (which imports DOMPurify) is loaded
  // *after* the dompurify mock has been registered above.
  // eslint-disable-next-line global-require
  const { chatMiddleware } = require('./middleware');
  // eslint-disable-next-line global-require
  const { chatReducer } = require('./reducer');
  return createStore(
    combineReducers({
      chat: chatReducer,
      settings: settingsReducer,
    }),
    applyMiddleware(chatMiddleware),
  );
};

describe('chatMiddleware applySettings diffing', () => {
  beforeEach(() => {
    // Suppress periodic chat persistence interval set up by middleware
    jest.spyOn(global, 'setInterval').mockImplementation(() => 0);
    if (typeof window.Byond === 'undefined') {
      window.Byond = { topic: jest.fn() };
    }
    clearRendererSpies();
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  test('first dispatch applies all renderer methods', async () => {
    const store = createTestStore();
    store.dispatch(updateSettings({ highlightText: 'foo' }));
    await flushPromises();

    expect(mockChatRenderer.setHighlight).toHaveBeenCalledTimes(1);
    expect(mockChatRenderer.setHighlightSound).toHaveBeenCalledTimes(1);
    expect(mockChatRenderer.setChatClasses).toHaveBeenCalledTimes(1);
    expect(mockChatRenderer.setBgAnimation).toHaveBeenCalledTimes(1);
    expect(mockChatRenderer.setCustomColors).toHaveBeenCalledTimes(1);
    expect(mockChatRenderer.setCustomProperties).toHaveBeenCalledTimes(1);
    expect(mockChatRenderer.setRadioJobsVisible).toHaveBeenCalledTimes(1);
    expect(mockChatRenderer.setNewMessagesMarker).toHaveBeenCalledWith(true);
    expect(mockChatRenderer.setRadioJobStyle).toHaveBeenCalledTimes(1);
    expect(mockChatRenderer.setStyleOverrides).toHaveBeenCalledTimes(1);
    expect(mockChatRenderer.setTypeOverrides).toHaveBeenCalledTimes(1);
    expect(mockChatRenderer.setTimestamps).toHaveBeenCalledTimes(1);
    expect(mockChatRenderer.setTimeDividers).toHaveBeenCalledTimes(1);
  });

  test('typing in highlightText only re-runs setHighlight', async () => {
    const store = createTestStore();
    // Establish baseline (first dispatch always applies everything)
    store.dispatch(updateSettings({ highlightText: '' }));
    await flushPromises();
    // Reset spy counts but not module-level diff state
    clearRendererSpies();

    // Simulate three keystrokes
    store.dispatch(updateSettings({ highlightText: 'a' }));
    store.dispatch(updateSettings({ highlightText: 'ab' }));
    store.dispatch(updateSettings({ highlightText: 'abc' }));
    await flushPromises();

    expect(mockChatRenderer.setHighlight).toHaveBeenCalledTimes(3);
    // None of the unrelated DOM-touching methods should re-run.
    expect(mockChatRenderer.setHighlightSound).not.toHaveBeenCalled();
    expect(mockChatRenderer.setChatClasses).not.toHaveBeenCalled();
    expect(mockChatRenderer.setBgAnimation).not.toHaveBeenCalled();
    expect(mockChatRenderer.setCustomColors).not.toHaveBeenCalled();
    expect(mockChatRenderer.setCustomProperties).not.toHaveBeenCalled();
    expect(mockChatRenderer.setStyleOverrides).not.toHaveBeenCalled();
    expect(mockChatRenderer.setTypeOverrides).not.toHaveBeenCalled();
    expect(mockChatRenderer.setGameEffects).not.toHaveBeenCalled();
    expect(mockChatRenderer.setSettleOld).not.toHaveBeenCalled();
    expect(mockChatRenderer.setRadioJobStyle).not.toHaveBeenCalled();
    expect(mockChatRenderer.setTimestamps).not.toHaveBeenCalled();
    expect(mockChatRenderer.setTimeDividers).not.toHaveBeenCalled();
  });

  test('highlight regex args propagate correctly', async () => {
    const store = createTestStore();
    store.dispatch(updateSettings({
      highlightText: 'foo',
      highlightColor: '#ff0000',
      matchWord: true,
      matchCase: true,
    }));
    await flushPromises();

    expect(mockChatRenderer.setHighlight).toHaveBeenLastCalledWith(
      'foo', '#ff0000', true, true);
  });

  test('changing only color triggers setCustomColors but not setHighlight', async () => {
    const store = createTestStore();
    store.dispatch(updateSettings({ chatBgColor: '#111111' }));
    await flushPromises();
    clearRendererSpies();

    store.dispatch(updateSettings({ chatBgColor: '#222222' }));
    await flushPromises();

    expect(mockChatRenderer.setCustomColors).toHaveBeenCalledTimes(1);
    expect(mockChatRenderer.setCustomColors).toHaveBeenLastCalledWith(
      '#222222', '', '');
    expect(mockChatRenderer.setHighlight).not.toHaveBeenCalled();
    expect(mockChatRenderer.setBgAnimation).not.toHaveBeenCalled();
    expect(mockChatRenderer.setChatClasses).not.toHaveBeenCalled();
  });

  test('changing only chatBgAnimation triggers setBgAnimation only', async () => {
    const store = createTestStore();
    store.dispatch(updateSettings({ chatBgAnimation: 'none' }));
    await flushPromises();
    clearRendererSpies();

    store.dispatch(updateSettings({ chatBgAnimation: 'stars' }));
    await flushPromises();

    expect(mockChatRenderer.setBgAnimation).toHaveBeenCalledTimes(1);
    expect(mockChatRenderer.setBgAnimation).toHaveBeenLastCalledWith(
      'stars', 0.5);
    expect(mockChatRenderer.setCustomColors).not.toHaveBeenCalled();
    expect(mockChatRenderer.setHighlight).not.toHaveBeenCalled();
  });

  test('setCustomProperties only pushes the changed CSS property', async () => {
    const store = createTestStore();
    store.dispatch(updateSettings({ messageSpacing: 2 }));
    await flushPromises();
    clearRendererSpies();

    store.dispatch(updateSettings({ messageSpacing: 5 }));
    await flushPromises();

    expect(mockChatRenderer.setCustomProperties).toHaveBeenCalledTimes(1);
    expect(mockChatRenderer.setCustomProperties).toHaveBeenLastCalledWith({
      '--chat-msg-spacing': '5px',
    });
  });

  test('setCustomProperties is skipped when no CSS prop changed', async () => {
    const store = createTestStore();
    store.dispatch(updateSettings({ borderRadius: 8 }));
    await flushPromises();
    clearRendererSpies();

    // Same value as baseline — no DOM work
    store.dispatch(updateSettings({ borderRadius: 8 }));
    await flushPromises();

    expect(mockChatRenderer.setCustomProperties).not.toHaveBeenCalled();
  });

  test('text glow recomputes on textGlow change and pushes only --chat-glow', async () => {
    const store = createTestStore();
    store.dispatch(updateSettings({ textGlow: 'none' }));
    await flushPromises();
    clearRendererSpies();

    store.dispatch(updateSettings({
      textGlow: 'subtle',
      textGlowColor: '#abcdef',
    }));
    await flushPromises();

    expect(mockChatRenderer.setCustomProperties).toHaveBeenCalledTimes(1);
    expect(mockChatRenderer.setCustomProperties).toHaveBeenLastCalledWith({
      '--chat-glow': '0 0 4px #abcdef',
    });
  });

  test('timestamps and time dividers diff independently', async () => {
    const store = createTestStore();
    store.dispatch(updateSettings({ enableTimestamps: false }));
    await flushPromises();
    clearRendererSpies();

    store.dispatch(updateSettings({ enableTimestamps: true }));
    await flushPromises();
    expect(mockChatRenderer.setTimestamps).toHaveBeenCalledTimes(1);
    expect(mockChatRenderer.setTimeDividers).not.toHaveBeenCalled();

    clearRendererSpies();
    store.dispatch(updateSettings({ timeDividerInterval: 60000 }));
    await flushPromises();
    expect(mockChatRenderer.setTimeDividers).toHaveBeenCalledTimes(1);
    expect(mockChatRenderer.setTimestamps).not.toHaveBeenCalled();
  });

  test('styleOverrides change triggers setStyleOverrides only', async () => {
    const store = createTestStore();
    store.dispatch(updateSettings({ highlightText: '' }));
    await flushPromises();
    clearRendererSpies();

    store.dispatch(updateSettings({
      styleOverrides: {
        emote: { color: '#ff0000', disabled: false },
      },
    }));
    await flushPromises();

    expect(mockChatRenderer.setStyleOverrides).toHaveBeenCalledTimes(1);
    const [overrides, spanAnimations]
      = mockChatRenderer.setStyleOverrides.mock.calls[0];
    // Normalized map always contains every known style id
    expect(overrides.emote).toEqual({ color: '#ff0000', disabled: false });
    expect(overrides.whisper).toEqual({});
    expect(spanAnimations).toBe(true);
    expect(mockChatRenderer.setHighlight).not.toHaveBeenCalled();
    expect(mockChatRenderer.setCustomProperties).not.toHaveBeenCalled();
  });

  test('spanAnimations toggle propagates to setStyleOverrides', async () => {
    const store = createTestStore();
    store.dispatch(updateSettings({ highlightText: '' }));
    await flushPromises();
    clearRendererSpies();

    store.dispatch(updateSettings({ spanAnimations: false }));
    await flushPromises();

    expect(mockChatRenderer.setStyleOverrides).toHaveBeenCalledTimes(1);
    const [, spanAnimations]
      = mockChatRenderer.setStyleOverrides.mock.calls[0];
    expect(spanAnimations).toBe(false);
  });

  test('typeOverrides change triggers setTypeOverrides only', async () => {
    const store = createTestStore();
    store.dispatch(updateSettings({ highlightText: '' }));
    await flushPromises();
    clearRendererSpies();

    store.dispatch(updateSettings({
      typeOverrides: { radio: { border: '#336699' } },
    }));
    await flushPromises();

    expect(mockChatRenderer.setTypeOverrides).toHaveBeenCalledTimes(1);
    expect(mockChatRenderer.setTypeOverrides).toHaveBeenLastCalledWith(
      { radio: { border: '#336699' } });
    expect(mockChatRenderer.setStyleOverrides).not.toHaveBeenCalled();
  });

  test('game effect switches reach the renderer', async () => {
    const store = createTestStore();
    store.dispatch(updateSettings({ highlightText: '' }));
    await flushPromises();
    clearRendererSpies();

    store.dispatch(updateSettings({ gameEffects: { tremble: false } }));
    await flushPromises();
    expect(mockChatRenderer.setGameEffects).toHaveBeenCalledTimes(1);
    expect(mockChatRenderer.setGameEffects).toHaveBeenLastCalledWith(
      { tremble: false }, true);

    store.dispatch(updateSettings({ gameEffectsEnabled: false }));
    await flushPromises();
    expect(mockChatRenderer.setGameEffects).toHaveBeenLastCalledWith(
      { tremble: false }, false);
    expect(mockChatRenderer.setTypeOverrides).not.toHaveBeenCalled();
  });

  test('settle switch reaches the renderer', async () => {
    const store = createTestStore();
    store.dispatch(updateSettings({ highlightText: '' }));
    await flushPromises();
    clearRendererSpies();

    store.dispatch(updateSettings({ settleOldAnimations: false }));
    await flushPromises();
    expect(mockChatRenderer.setSettleOld).toHaveBeenCalledTimes(1);
    expect(mockChatRenderer.setSettleOld).toHaveBeenLastCalledWith(false);
    expect(mockChatRenderer.setGameEffects).not.toHaveBeenCalled();
  });

  test('radio job settings reach the renderer together', async () => {
    const store = createTestStore();
    store.dispatch(updateSettings({ highlightText: '' }));
    await flushPromises();
    clearRendererSpies();

    store.dispatch(updateSettings({ radioJobHeadMark: 'command' }));
    await flushPromises();
    expect(mockChatRenderer.setRadioJobStyle).toHaveBeenCalledTimes(1);
    expect(mockChatRenderer.setRadioJobStyle).toHaveBeenLastCalledWith({
      radioJobColorMode: 'department',
      radioJobHeadMark: 'command',
      radioJobColorNames: false,
      radioJobIcons: true,
      radioJobColors: {},
    });
    store.dispatch(updateSettings({ radioJobColors: { med: '#00ff00' } }));
    await flushPromises();
    expect(mockChatRenderer.setRadioJobStyle).toHaveBeenCalledTimes(2);
    expect(mockChatRenderer.setRadioJobStyle.mock.calls[1][0].radioJobColors)
      .toEqual({ med: '#00ff00' });
    store.dispatch(updateSettings({ radioJobIcons: false }));
    await flushPromises();
    expect(mockChatRenderer.setRadioJobStyle).toHaveBeenCalledTimes(3);
    expect(mockChatRenderer.setRadioJobStyle.mock.calls[2][0].radioJobIcons)
      .toBe(false);
    expect(mockChatRenderer.setRadioJobsVisible).not.toHaveBeenCalled();
    expect(mockChatRenderer.setStyleOverrides).not.toHaveBeenCalled();
  });

  test('matchWord toggle re-runs setHighlight', async () => {
    const store = createTestStore();
    store.dispatch(updateSettings({ highlightText: 'foo' }));
    await flushPromises();
    clearRendererSpies();

    store.dispatch(updateSettings({ matchWord: true }));
    await flushPromises();

    expect(mockChatRenderer.setHighlight).toHaveBeenCalledTimes(1);
    expect(mockChatRenderer.setHighlight).toHaveBeenLastCalledWith(
      'foo', '#ffdd44', true, false);
  });

  test('loadSettings is also diffed: identical state triggers no calls', async () => {
    const store = createTestStore();
    store.dispatch(updateSettings({ highlightText: 'foo' }));
    await flushPromises();
    const baselineSettings = store.getState().settings;
    clearRendererSpies();

    // Re-load the same settings — middleware should diff away every call.
    store.dispatch(loadSettings(baselineSettings));
    await flushPromises();

    expect(mockChatRenderer.setHighlight).not.toHaveBeenCalled();
    expect(mockChatRenderer.setHighlightSound).not.toHaveBeenCalled();
    expect(mockChatRenderer.setChatClasses).not.toHaveBeenCalled();
    expect(mockChatRenderer.setBgAnimation).not.toHaveBeenCalled();
    expect(mockChatRenderer.setCustomColors).not.toHaveBeenCalled();
    expect(mockChatRenderer.setCustomProperties).not.toHaveBeenCalled();
    expect(mockChatRenderer.setStyleOverrides).not.toHaveBeenCalled();
    expect(mockChatRenderer.setTypeOverrides).not.toHaveBeenCalled();
    expect(mockChatRenderer.setGameEffects).not.toHaveBeenCalled();
    expect(mockChatRenderer.setSettleOld).not.toHaveBeenCalled();
    expect(mockChatRenderer.setTimestamps).not.toHaveBeenCalled();
    expect(mockChatRenderer.setTimeDividers).not.toHaveBeenCalled();
  });
});

describe('chatMiddleware new messages marker', () => {
  beforeEach(() => {
    jest.spyOn(global, 'setInterval').mockImplementation(() => 0);
    if (typeof window.Byond === 'undefined') {
      window.Byond = { topic: jest.fn() };
    }
    clearRendererSpies();
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  test('toggle reaches the renderer only when it changes', async () => {
    const store = createTestStore();
    store.dispatch(updateSettings({}));
    store.dispatch(updateSettings({ fontSize: 14 }));
    expect(mockChatRenderer.setNewMessagesMarker).toHaveBeenCalledTimes(1);
    store.dispatch(updateSettings({ newMessagesMarker: false }));
    expect(mockChatRenderer.setNewMessagesMarker).toHaveBeenCalledTimes(2);
    expect(mockChatRenderer.setNewMessagesMarker)
      .toHaveBeenLastCalledWith(false);
  });
});

describe('chatMiddleware periodic save', () => {
  let tick;
  let tickDelay;

  beforeEach(() => {
    jest.spyOn(global, 'setInterval').mockImplementation((fn, delay) => {
      tick = fn;
      tickDelay = delay;
      return 0;
    });
    if (typeof window.Byond === 'undefined') {
      window.Byond = { topic: jest.fn() };
    }
    clearRendererSpies();
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  const writes = (storage, key) => storage.set.mock.calls
    .filter(([written]) => written === key).length;

  test('skips the write when nothing changed since the last save', async () => {
    // eslint-disable-next-line global-require
    const { storage } = require('common/storage');
    // eslint-disable-next-line global-require
    const { updateChatPage } = require('./actions');
    const store = createTestStore();
    store.dispatch(updateSettings({}));
    await flushPromises();
    storage.set.mockClear();

    await tick();
    expect(writes(storage, HISTORY_KEY)).toBe(1);
    await tick();
    await tick();
    expect(writes(storage, HISTORY_KEY)).toBe(1);

    mockChatRenderer.messagesVersion += 1;
    await tick();
    expect(writes(storage, HISTORY_KEY)).toBe(2);

    const pageId = selectChat(store.getState()).currentPageId;
    store.dispatch(updateChatPage({ pageId, name: 'Renamed' }));
    await tick();
    expect(writes(storage, HISTORY_KEY)).toBe(3);

    store.dispatch({ type: 'roundrestart' });
    await flushPromises();
    expect(writes(storage, HISTORY_KEY)).toBe(4);
  });

  test('scrolling without new messages writes nothing', async () => {
    // eslint-disable-next-line global-require
    const { storage } = require('common/storage');
    // eslint-disable-next-line global-require
    const { changeScrollTracking, updateMessageCount } = require('./actions');
    const store = createTestStore();
    store.dispatch(updateSettings({}));
    store.dispatch(updateMessageCount({ say: 3 }));
    await flushPromises();
    await tick();
    storage.set.mockClear();

    store.dispatch(changeScrollTracking(false));
    await tick();
    store.dispatch(changeScrollTracking(true));
    await tick();
    expect(storage.set).not.toHaveBeenCalled();
  });

  test('retries on the next tick after a failed write', async () => {
    // eslint-disable-next-line global-require
    const { storage } = require('common/storage');
    const store = createTestStore();
    store.dispatch(updateSettings({}));
    await flushPromises();
    storage.set.mockClear();
    jest.spyOn(console, 'error').mockImplementation(() => {});
    storage.set.mockRejectedValueOnce(new Error('quota'));

    await tick();
    expect(writes(storage, HISTORY_KEY)).toBe(1);
    await tick();
    expect(writes(storage, HISTORY_KEY)).toBe(2);
    await tick();
    expect(writes(storage, HISTORY_KEY)).toBe(2);
  });

  test('messages and tab state go out in one write, an idle chat writes none', async () => {
    // eslint-disable-next-line global-require
    const { storage } = require('common/storage');
    const store = createTestStore();
    store.dispatch(updateSettings({}));
    await flushPromises();
    storage.set.mockClear();
    storage.remove.mockClear();

    mockChatRenderer.messages = [{ type: 'say', html: 'a' }, { type: 'say', html: 'b' }];
    mockChatRenderer.messagesVersion += 1;
    await tick();
    expect(storage.set).toHaveBeenCalledTimes(1);
    expect(storage.remove).not.toHaveBeenCalled();
    const [key, saved] = storage.set.mock.calls[0];
    expect(key).toBe(HISTORY_KEY);
    expect(saved.entries.map(m => m.html)).toEqual(['a', 'b']);
    expect(saved.state.version).toBe(selectChat(store.getState()).version);
    expect(mockChatRenderer.messages.map(m => m.logId)).toEqual([0, 1]);

    await tick();
    expect(storage.set).toHaveBeenCalledTimes(1);
    mockChatRenderer.messages = [];
  });

  test('without a call from the server saves every five minutes', () => {
    const store = createTestStore();
    store.dispatch(updateSettings({}));
    expect(tickDelay).toBe(300000);
  });

  test('the server call for an idle player saves at once', async () => {
    // eslint-disable-next-line global-require
    const { storage } = require('common/storage');
    const store = createTestStore();
    store.dispatch(updateSettings({}));
    await flushPromises();
    await tick();
    storage.set.mockClear();

    mockChatRenderer.messagesVersion += 1;
    store.dispatch({ type: 'chat/saveIdle' });
    await flushPromises();
    expect(writes(storage, HISTORY_KEY)).toBe(1);
    store.dispatch({ type: 'chat/saveIdle' });
    await flushPromises();
    expect(writes(storage, HISTORY_KEY)).toBe(1);
  });

  test('a hidden window saves at once', async () => {
    // eslint-disable-next-line global-require
    const { storage } = require('common/storage');
    const listen = jest.spyOn(document, 'addEventListener');
    const store = createTestStore();
    const [, onVisibility] = listen.mock.calls.find(([type]) => type === 'visibilitychange');
    store.dispatch(updateSettings({}));
    await flushPromises();
    await tick();
    storage.set.mockClear();

    const hidden = jest.spyOn(document, 'hidden', 'get').mockReturnValue(false);
    mockChatRenderer.messagesVersion += 1;
    onVisibility();
    await flushPromises();
    expect(writes(storage, HISTORY_KEY)).toBe(0);
    hidden.mockReturnValue(true);
    onVisibility();
    await flushPromises();
    expect(writes(storage, HISTORY_KEY)).toBe(1);
  });

  test('leaving the page saves at once', async () => {
    // eslint-disable-next-line global-require
    const { storage } = require('common/storage');
    const listen = jest.spyOn(window, 'addEventListener');
    const store = createTestStore();
    const [, onPageHide] = listen.mock.calls.find(([type]) => type === 'pagehide');
    store.dispatch(updateSettings({}));
    await flushPromises();
    storage.set.mockClear();

    mockChatRenderer.messages = [{ type: 'say', html: 'c' }];
    mockChatRenderer.messagesVersion += 1;
    onPageHide();
    await flushMicrotasks();
    expect(writes(storage, HISTORY_KEY)).toBe(1);
    expect(storage.set.mock.calls[0][1].entries.map(m => m.html)).toContain('c');
    mockChatRenderer.messages = [];
  });

  test('leaving the page right after a round restart writes nothing more', async () => {
    // eslint-disable-next-line global-require
    const { storage } = require('common/storage');
    // eslint-disable-next-line global-require
    const serverState = require('../serverState');
    let savedAt = 10;
    serverState.getLastSavedAt.mockImplementation(() => savedAt);
    // Сервер при отправке состояния поднимает savedAt.
    serverState.flushSaveToServer.mockImplementation(() => {
      savedAt += 1;
    });
    const listen = jest.spyOn(window, 'addEventListener');
    const store = createTestStore();
    const [, onPageHide] = listen.mock.calls.find(([type]) => type === 'pagehide');
    store.dispatch(updateSettings({}));
    await flushPromises();
    mockChatRenderer.messages = [{ type: 'say', html: 'd' }];
    mockChatRenderer.messagesVersion += 1;
    store.dispatch({ type: 'roundrestart' });
    await flushPromises();
    storage.set.mockClear();
    onPageHide();
    await flushPromises();
    expect(storage.set).not.toHaveBeenCalled();
    mockChatRenderer.messages = [];
    serverState.getLastSavedAt.mockImplementation(() => 0);
    serverState.flushSaveToServer.mockImplementation(() => {});
  });

  test('a message pruned by the renderer before the save tick is still saved', async () => {
    // eslint-disable-next-line global-require
    const { storage } = require('common/storage');
    const store = createTestStore();
    const [, onBatch] = mockChatRenderer.events.on.mock.calls
      .find(([event]) => event === 'batchProcessed');
    store.dispatch(updateSettings({}));
    await flushPromises();
    storage.set.mockClear();

    mockChatRenderer.messages = [{ type: 'say', html: 'pruned-early' }];
    mockChatRenderer.messagesVersion += 1;
    onBatch({});
    mockChatRenderer.messages = [];
    mockChatRenderer.messagesVersion += 1;
    await tick();
    expect(writes(storage, HISTORY_KEY)).toBe(1);
    expect(storage.set.mock.calls[0][1].entries.map(m => m.html))
      .toContain('pruned-early');
  });

  test('a stream larger than the screen limit within one interval is saved whole', async () => {
    // eslint-disable-next-line global-require
    const { storage } = require('common/storage');
    const store = createTestStore();
    const [, onBatch] = mockChatRenderer.events.on.mock.calls
      .find(([event]) => event === 'batchProcessed');
    store.dispatch(updateSettings({}));
    await flushPromises();
    storage.set.mockClear();

    // Рендерер держит последние 750, как обрезка после каждой пачки.
    let shown = [];
    for (let batch = 0; batch < 5; batch++) {
      for (let i = 0; i < 400; i++) {
        shown.push({ type: 'say', html: `flood-${batch * 400 + i}` });
      }
      mockChatRenderer.messages = shown;
      mockChatRenderer.messagesVersion += 1;
      onBatch({});
      shown = shown.slice(-750);
    }
    mockChatRenderer.messages = shown;
    await tick();
    const html = storage.set.mock.calls[0][1].entries.map(m => m.html);
    for (const n of [0, 1, 999, 1250, 1999]) {
      expect(html).toContain(`flood-${n}`);
    }
    mockChatRenderer.messages = [];
  });

  test('leaving the page before the history is restored writes nothing', async () => {
    const listen = jest.spyOn(window, 'addEventListener');
    let storage;
    let store;
    let restore;
    const reading = new Promise(resolve => {
      restore = resolve;
    });
    jest.isolateModules(() => {
      // eslint-disable-next-line global-require
      ({ storage } = require('common/storage'));
      storage.get.mockImplementation(() => reading);
      store = createTestStore();
    });
    const [, onPageHide] = listen.mock.calls.find(([type]) => type === 'pagehide');
    store.dispatch(updateSettings({}));
    onPageHide();
    restore(undefined);
    await flushPromises();
    expect(storage.set).not.toHaveBeenCalled();
  });
});

describe('chatMiddleware clear and limit', () => {
  beforeEach(() => {
    jest.spyOn(global, 'setInterval').mockImplementation(() => 0);
    if (typeof window.Byond === 'undefined') {
      window.Byond = { topic: jest.fn() };
    }
    clearRendererSpies();
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  test('clearing the chat wipes the screen and the stored history', async () => {
    // eslint-disable-next-line global-require
    const { chatHistory } = require('./middleware');
    // eslint-disable-next-line global-require
    const { clearChat } = require('./actions');
    const clear = jest.spyOn(chatHistory, 'clear')
      .mockResolvedValue(undefined);
    const store = createTestStore();
    store.dispatch(clearChat());
    await flushPromises();
    expect(mockChatRenderer.clearChat).toHaveBeenCalledTimes(1);
    expect(clear).toHaveBeenCalledTimes(1);
  });

  test('the message limit reaches the renderer only when it changes', () => {
    const store = createTestStore();
    store.dispatch(updateSettings({}));
    expect(mockChatRenderer.setVisibleLimit).toHaveBeenLastCalledWith(750);
    store.dispatch(updateSettings({ fontSize: 15 }));
    expect(mockChatRenderer.setVisibleLimit).toHaveBeenCalledTimes(1);
    store.dispatch(updateSettings({ visibleMessageLimit: 500 }));
    expect(mockChatRenderer.setVisibleLimit).toHaveBeenLastCalledWith(500);
  });
});

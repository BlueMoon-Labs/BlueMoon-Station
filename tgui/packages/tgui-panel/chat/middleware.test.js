import { applyMiddleware, combineReducers, createStore } from 'common/redux';

import { loadSettings, updateSettings } from '../settings/actions';
import { settingsReducer } from '../settings/reducer';

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
  setTimestamps: jest.fn(),
  setTimeDividers: jest.fn(),
  changePage: jest.fn(),
  onStateLoaded: jest.fn(),
  processBatch: jest.fn(),
  rebuildChat: jest.fn(),
  saveToDisk: jest.fn(),
  messages: [],
};

jest.mock('./renderer', () => ({
  chatRenderer: mockChatRenderer,
}));

jest.mock('common/storage', () => ({
  storage: {
    get: jest.fn().mockResolvedValue(undefined),
    set: jest.fn().mockResolvedValue(undefined),
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

const flushPromises = async () => {
  await Promise.resolve();
  await Promise.resolve();
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
    expect(mockChatRenderer.setTimestamps).not.toHaveBeenCalled();
    expect(mockChatRenderer.setTimeDividers).not.toHaveBeenCalled();
  });
});

/**
 * @file
 * Server-side state persistence for tgui panel.
 * Debounces and sends combined settings + chat page state to DM
 * to survive WebView2 storage loss on reconnect.
 *
 * @copyright 2025
 * @license MIT
 */

import { selectChat } from './chat/selectors';
import { selectSettings } from './settings/selectors';

let saveTimer = null;
let saveCounter = 0;
let lastStore = null;
const DEBOUNCE_MS = 3000;

/**
 * Returns the current save counter value.
 * Used by browser storage to track which copy is fresher.
 */
export const getLastSavedAt = () => saveCounter;

/**
 * Builds a JSON string of the current panel state for server persistence.
 * Excludes transient fields (theme, view, scrollTracking, unreadCount, createdAt).
 */
const buildStateJson = (store) => {
  const settings = selectSettings(store.getState());
  const chat = selectChat(store.getState());

  // Strip theme (has its own persistence) and view (transient UI state)
  const { theme, view, ...settingsToSave } = settings;

  // Compact format: remap UUID page IDs to short indices to save ~600 bytes.
  // BYOND's HTTP transport URL-encodes query params; UUIDs are 36 chars each
  // and appear 3x (pages array, pageById key, page.id) — far too large.
  const idMap = {};
  const compactPages = [];
  chat.pages.forEach((uuid, i) => {
    const shortId = String(i);
    idMap[uuid] = shortId;
    compactPages.push(shortId);
  });

  const chatToSave = {
    version: chat.version,
    currentPageId: idMap[chat.currentPageId] || '0',
    pages: compactPages,
    pageById: {},
  };

  for (const uuid of chat.pages) {
    const page = chat.pageById[uuid];
    if (page) {
      // Strip transient fields and redundant id (same as pageById key)
      const { unreadCount, createdAt, id, ...pageData } = page;
      // Convert acceptedTypes from {type: true, ...} to [type, ...]
      if (pageData.acceptedTypes
        && typeof pageData.acceptedTypes === 'object'
        && !Array.isArray(pageData.acceptedTypes)) {
        pageData.acceptedTypes = Object.keys(pageData.acceptedTypes)
          .filter(k => pageData.acceptedTypes[k]);
      }
      chatToSave.pageById[idMap[uuid]] = pageData;
    }
  }

  saveCounter += 1;
  return JSON.stringify({
    v: 1,
    savedAt: saveCounter,
    settings: settingsToSave,
    chat: chatToSave,
  });
};

/**
 * Sends the current panel state to the server immediately.
 */
const doSaveToServer = (store) => {
  try {
    const stateJson = buildStateJson(store);
    // Send state as a direct href parameter to avoid double-JSON-encoding.
    // Previously: payload=JSON.stringify({state: stateJson}) caused the inner
    // JSON to be escaped (" → \") then URL-encoded (\→%5C, "→%22), tripling
    // the URL size and exceeding BYOND's topic URL limit.
    Byond.topic({
      tgui: 1,
      window_id: window.__windowId__,
      type: 'panel/state_set',
      panel_state: stateJson,
    });
  }
  catch (err) {
    // eslint-disable-next-line no-console
    console.error('Failed to save panel state to server:', err);
  }
};

/**
 * Schedules a debounced save of panel state to the server.
 * Multiple calls within DEBOUNCE_MS collapse into one.
 */
export const scheduleSaveToServer = (store) => {
  lastStore = store;
  if (saveTimer) {
    clearTimeout(saveTimer);
  }
  saveTimer = setTimeout(() => {
    saveTimer = null;
    doSaveToServer(store);
  }, DEBOUNCE_MS);
};

/**
 * Flushes any pending debounced save immediately.
 * Use for critical operations (tab add/remove) and before disconnect.
 */
export const flushSaveToServer = (store) => {
  const targetStore = store || lastStore;
  if (saveTimer) {
    clearTimeout(saveTimer);
    saveTimer = null;
  }
  if (targetStore) {
    doSaveToServer(targetStore);
  }
};

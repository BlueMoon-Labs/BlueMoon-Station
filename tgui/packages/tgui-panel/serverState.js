/**
 * @file
 * Server-side state persistence for tgui panel.
 * Debounces and sends combined settings + chat page state to DM
 * to survive WebView2 storage loss on reconnect.
 *
 * @copyright 2025
 * @license MIT
 */

import { backendCreatePayloadQueue, sendMessage } from 'tgui/backend';

import { selectChat } from './chat/selectors';
import { selectSettings } from './settings/selectors';

let saveTimer = null;
let saveCounter = 0;
let lastStore = null;
// Тело последнего отправленного состояния, без savedAt. Счётчик savedAt растёт на
// каждой сборке, поэтому серверный гард "состояние не изменилось - не пиши" не мог
// сработать никогда: строка всегда отличалась. Сравниваем то, что реально
// сохраняется, и молчим, когда сохранять нечего.
let lastSentBody = null;
const DEBOUNCE_MS = 3000;
const DIRECT_TOPIC_URL_LIMIT = 2048;
// Тот же бюджет, что и в tgui/backend.ts: чанк едет внутри JSON и кодируется в URL повторно,
// поэтому 512 давали реальный URL около 840 при лимите 2048 - половина бюджета простаивала,
// а раундтрипов (каждый ждёт подтверждения сервера) было вдвое больше нужного.
const CHUNK_ENCODED_SIZE = 900;

const splitIntoChunks = (str) => {
  const charSeq = Array.from(str);
  const chunks = [];
  let chunk = '';
  let encodedLength = 0;

  for (const char of charSeq) {
    const charEncodedLength = encodeURIComponent(char).length;
    if (chunk && encodedLength + charEncodedLength > CHUNK_ENCODED_SIZE) {
      chunks.push(chunk);
      chunk = '';
      encodedLength = 0;
    }
    chunk += char;
    encodedLength += charEncodedLength;
  }
  if (chunk) {
    chunks.push(chunk);
  }
  return chunks;
};

const getTopicUrlLength = params => Object.entries(params).reduce(
  (url, [key, value], i) => {
    const encodedValue = value === null || value === undefined ? '' : value;
    return url
      + `${i > 0 ? '&' : '?'}${encodeURIComponent(key)}=`
      + encodeURIComponent(encodedValue);
  },
  '',
).length;

const sendStateDirectly = (stateJson) => {
  Byond.topic({
    tgui: 1,
    window_id: window.__windowId__,
    type: 'panel/state_set',
    panel_state: stateJson,
  });
};

const sendStateInChunks = (store, stateJson) => {
  const payload = JSON.stringify({
    state: stateJson,
  });
  const chunks = splitIntoChunks(payload);
  const id = `panel-state-${Date.now()}-${saveCounter}`;
  store.dispatch(backendCreatePayloadQueue({
    id,
    chunks,
  }));
  sendMessage({
    type: 'oversizedPayloadRequest',
    payload: {
      type: 'panel/state_set',
      id,
      chunkCount: chunks.length,
    },
  });
};

/**
 * Returns the current save counter value.
 * Used by browser storage to track which copy is fresher.
 */
export const getLastSavedAt = () => saveCounter;

/**
 * Забывает, что было отправлено. Зовётся, когда сервер сам присылает panel/state
 * (реконнект, перезагрузка панели): lastSentBody живёт в модуле и переживает
 * перезагрузку окна, а сервер за это время мог потерять состояние - без сброса
 * идентичное состояние глушилось бы как дубль и никогда не доехало бы обратно.
 */
export const forgetSentState = () => {
  lastSentBody = null;
};

/**
 * Builds a JSON string of the current panel state for server persistence.
 * Excludes transient fields (theme, view, scrollTracking, unreadCount, createdAt).
 *
 * Returns null when the persisted body is byte-for-byte what we sent last time —
 * the caller must then skip the round trip entirely. savedAt is bumped only for
 * bodies that actually go out, so it stays monotonic for the freshness compare
 * in chat/middleware.
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

  const body = JSON.stringify({
    v: 1,
    settings: settingsToSave,
    chat: chatToSave,
  });
  if (body === lastSentBody) {
    return null;
  }
  lastSentBody = body;

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
  // buildStateJson marks the body as sent before the transport actually runs. If the
  // transport throws, that bookkeeping has to come back or the identical state is
  // suppressed as a duplicate forever and never reaches the server.
  const previousSentBody = lastSentBody;
  const previousSaveCounter = saveCounter;
  try {
    const stateJson = buildStateJson(store);
    if (stateJson === null) {
      return;
    }
    // Send state as a direct href parameter to avoid double-JSON-encoding.
    // Previously: payload=JSON.stringify({state: stateJson}) caused the inner
    // JSON to be escaped (" → \") then URL-encoded (\→%5C, "→%22), tripling
    // the URL size and exceeding BYOND's topic URL limit. If the direct topic
    // is still too large (e.g. long Cyrillic highlight lists), use tgui's
    // existing chunked payload transport to keep every outbound URL under 2KB.
    const directParams = {
      tgui: 1,
      window_id: window.__windowId__,
      type: 'panel/state_set',
      panel_state: stateJson,
    };
    if (getTopicUrlLength(directParams) < DIRECT_TOPIC_URL_LIMIT) {
      sendStateDirectly(stateJson);
    } else {
      sendStateInChunks(store, stateJson);
    }
  }
  catch (err) {
    lastSentBody = previousSentBody;
    saveCounter = previousSaveCounter;
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

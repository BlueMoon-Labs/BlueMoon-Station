/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { storage } from 'common/storage';
import DOMPurify from 'dompurify';

import { flushSaveToServer, getLastSavedAt, scheduleSaveToServer } from '../serverState';
import { loadSettings, updateSettings } from '../settings/actions';
import { MESSAGE_STYLES } from '../settings/constants';
import { selectSettings } from '../settings/selectors';
import { addChatPage, changeChatPage, changeScrollTracking, loadChat, rebuildChat, removeChatPage, saveChatToDisk, toggleAcceptedType, updateChatPage, updateMessageCount } from './actions';
import { MAX_PERSISTED_MESSAGES, MESSAGE_SAVE_INTERVAL } from './constants';
import { createMessage, serializeMessage } from './model';
import { chatRenderer } from './renderer';
import { getChatCustomProps } from './rootAppearance';
import { selectChat, selectCurrentChatPage } from './selectors';

// List of blacklisted tags
const FORBID_TAGS = [
  'iframe',
  'link',
  'video',
];

const saveChatToStorage = async (state, savedAt) => {
  const fromIndex = Math.max(0,
    chatRenderer.messages.length - MAX_PERSISTED_MESSAGES);
  const messages = chatRenderer.messages
    .slice(fromIndex)
    .map(message => serializeMessage(message));
  await Promise.all([
    storage.set('chat-state', { ...state, savedAt }),
    storage.set('chat-messages', messages),
  ]);
};

// Сохранение раз в MESSAGE_SAVE_INTERVAL пишет до MAX_PERSISTED_MESSAGES
// сообщений целиком; если с прошлого раза ничего не поменялось, не пишем.
const createChatSaver = () => {
  let last = null;
  return async (store, force = false) => {
    const state = selectChat(store.getState());
    const savedAt = getLastSavedAt();
    const version = chatRenderer.messagesVersion;
    if (!force && last && last.state === state
      && last.savedAt === savedAt && last.version === version) {
      return;
    }
    try {
      await saveChatToStorage(state, savedAt);
      last = { state, savedAt, version };
    }
    catch (err) {
      // Запомненное не обновляем: следующий тик повторит запись.
      console.error('Failed to save chat history:', err);
    }
  };
};

// Server state tracking for smart merge with browser storage
let serverChatLoaded = false;
let serverSavedAt = 0;

const loadChatFromStorage = async store => {
  const [state, messages] = await Promise.all([
    storage.get('chat-state'),
    storage.get('chat-messages'),
  ]);
  // Discard incompatible versions
  if (state && state.version <= 4) {
    store.dispatch(loadChat());
    return;
  }
  // Always try to restore messages from browser storage (not server-persisted)
  if (messages) {
    for (let message of messages) {
      if (message.html) {
        message.html = DOMPurify.sanitize(message.html, {
          FORBID_TAGS,
        });
      }
    }
    const batch = [
      ...messages,
      createMessage({
        type: 'internal/reconnected',
      }),
    ];
    chatRenderer.processBatch(batch, {
      prepend: true,
    });
  }
  // Compare server vs browser storage by savedAt counter.
  // Use the fresher copy; if equal or both missing, server wins (backward compat).
  const browserSavedAt = (state && typeof state.savedAt === 'number')
    ? state.savedAt
    : 0;
  if (serverChatLoaded && serverSavedAt >= browserSavedAt) {
    return;
  }
  store.dispatch(loadChat(state));
};

const anyChanged = (prev, next, keys) => {
  if (!prev) {
    return true;
  }
  for (const key of keys) {
    if (prev[key] !== next[key]) {
      return true;
    }
  }
  return false;
};

/**
 * Returns an applySettings function that maintains its own diff state.
 *
 * Each renderer call is guarded by a per-feature diff against the previous
 * applied settings so unrelated settings (e.g. typing in highlight text)
 * do not redundantly invalidate styles or rebuild regexes. Setting CSS
 * custom properties on the chat root invalidates styles for every message
 * subtree, so re-applying them on every keystroke causes major input lag
 * once the chat has many messages.
 */
const createApplySettings = () => {
  let lastAppliedSettings = null;
  let lastAppliedCustomProps = null;

  return (settings) => {
    const prev = lastAppliedSettings;

    if (anyChanged(prev, settings,
      ['highlightText', 'highlightColor', 'matchWord', 'matchCase'])) {
      chatRenderer.setHighlight(
        settings.highlightText,
        settings.highlightColor,
        settings.matchWord,
        settings.matchCase);
    }
    if (anyChanged(prev, settings, ['highlightSoundEnabled'])) {
      chatRenderer.setHighlightSound(settings.highlightSoundEnabled);
    }

    if (anyChanged(prev, settings,
      ['chatStyle', 'chatAnimation', 'hoverEffect', 'smoothScroll'])) {
      chatRenderer.setChatClasses(
        settings.chatStyle,
        settings.chatAnimation,
        settings.hoverEffect,
        settings.smoothScroll);
    }
    if (anyChanged(prev, settings, ['chatBgAnimation', 'chatBgAnimOpacity'])) {
      chatRenderer.setBgAnimation(
        settings.chatBgAnimation,
        settings.chatBgAnimOpacity);
    }
    if (anyChanged(prev, settings,
      ['chatBgColor', 'chatTextColor', 'chatAccentColor'])) {
      chatRenderer.setCustomColors(
        settings.chatBgColor,
        settings.chatTextColor,
        settings.chatAccentColor);
    }
    if (anyChanged(prev, settings, ['showRadioJobs'])) {
      chatRenderer.setRadioJobsVisible(settings.showRadioJobs !== false);
    }
    if (anyChanged(prev, settings, ['newMessagesMarker'])) {
      chatRenderer.setNewMessagesMarker(settings.newMessagesMarker !== false);
    }
    if (anyChanged(prev, settings, ['styleOverrides', 'spanAnimations'])) {
      // Normalize so the renderer always sees every known style id and
      // clears stale properties for styles that lost their override.
      const normalized = {};
      for (const style of MESSAGE_STYLES) {
        normalized[style.id] = settings.styleOverrides?.[style.id] || {};
      }
      chatRenderer.setStyleOverrides(
        normalized,
        settings.spanAnimations !== false);
    }
    if (anyChanged(prev, settings, ['settleOldAnimations'])) {
      chatRenderer.setSettleOld(settings.settleOldAnimations !== false);
    }

    const nextCustomProps = getChatCustomProps(settings);
    // Only push CSS custom properties that actually changed value.
    let changedProps = null;
    for (const [key, value] of Object.entries(nextCustomProps)) {
      if (!lastAppliedCustomProps || lastAppliedCustomProps[key] !== value) {
        if (!changedProps) {
          changedProps = {};
        }
        changedProps[key] = value;
      }
    }
    if (changedProps) {
      chatRenderer.setCustomProperties(changedProps);
      lastAppliedCustomProps = nextCustomProps;
    }

    if (anyChanged(prev, settings, ['enableTimestamps', 'timestampFormat'])) {
      chatRenderer.setTimestamps(
        settings.enableTimestamps,
        settings.timestampFormat);
    }
    if (anyChanged(prev, settings,
      ['enableTimeDividers', 'timeDividerInterval'])) {
      chatRenderer.setTimeDividers(
        settings.enableTimeDividers,
        settings.timeDividerInterval);
    }

    lastAppliedSettings = settings;
  };
};

export const chatMiddleware = store => {
  let initialized = false;
  let loaded = false;
  const applySettings = createApplySettings();
  const saveChat = createChatSaver();
  chatRenderer.events.on('batchProcessed', countByType => {
    // Use this flag to workaround unread messages caused by
    // loading them from storage. Side effect of that, is that
    // message count can not be trusted, only unread count.
    if (loaded) {
      store.dispatch(updateMessageCount(countByType));
    }
  });
  chatRenderer.events.on('scrollTrackingChanged', scrollTracking => {
    store.dispatch(changeScrollTracking(scrollTracking));
  });
  setInterval(() => saveChat(store), MESSAGE_SAVE_INTERVAL);
  return next => action => {
    const { type, payload } = action;
    if (!initialized) {
      initialized = true;
      loadChatFromStorage(store);
    }
    // Restore chat pages from server-side persistence
    if (type === 'panel/state') {
      const stateJson = payload?.state;
      if (typeof stateJson === 'string') {
        try {
          const state = JSON.parse(stateJson);
          if (state?.chat && state?.v === 1) {
            serverChatLoaded = true;
            serverSavedAt = typeof state.savedAt === 'number'
              ? state.savedAt
              : 0;
            // Decompact: restore id fields and acceptedTypes format
            const chat = state.chat;
            if (chat.pageById) {
              for (const [id, page] of Object.entries(chat.pageById)) {
                page.id = id;
                if (Array.isArray(page.acceptedTypes)) {
                  const obj = {};
                  for (const t of page.acceptedTypes) {
                    obj[t] = true;
                  }
                  page.acceptedTypes = obj;
                }
              }
            }
            store.dispatch(loadChat(chat));
          }
        }
        catch (err) {
          console.error('Failed to parse chat state from server:', err);
        }
      }
      return next(action);
    }
    if (type === 'panel/state_error') {
      // eslint-disable-next-line no-console
      console.error(
        '[tgui-panel] Server rejected state save:',
        payload?.reason,
        'size:',
        payload?.size);
      return next(action);
    }
    if (type === 'chat/message') {
      // Normalize the payload
      const batch = Array.isArray(payload) ? payload : [payload];
      chatRenderer.processBatch(batch);
      return;
    }
    if (type === loadChat.type) {
      next(action);
      const page = selectCurrentChatPage(store.getState());
      chatRenderer.changePage(page);
      chatRenderer.onStateLoaded();
      loaded = true;
      return;
    }
    if (type === changeChatPage.type
        || type === addChatPage.type
        || type === removeChatPage.type
        || type === toggleAcceptedType.type) {
      next(action);
      const page = selectCurrentChatPage(store.getState());
      chatRenderer.changePage(page);
      // Flush immediately for structural changes (add/remove tab),
      // debounce for less critical ones (switch tab, toggle filter)
      if (type === addChatPage.type || type === removeChatPage.type) {
        flushSaveToServer(store);
      } else {
        scheduleSaveToServer(store);
      }
      return;
    }
    if (type === updateChatPage.type) {
      next(action);
      scheduleSaveToServer(store);
      return;
    }
    if (type === rebuildChat.type) {
      chatRenderer.rebuildChat();
      return next(action);
    }
    if (type === updateSettings.type || type === loadSettings.type) {
      next(action);
      const settings = selectSettings(store.getState());
      applySettings(settings);
      return;
    }
    if (type === 'roundrestart') {
      saveChat(store, true);
      flushSaveToServer(store);
      return next(action);
    }
    if (type === saveChatToDisk.type) {
      chatRenderer.saveToDisk();
      return;
    }
    return next(action);
  };
};

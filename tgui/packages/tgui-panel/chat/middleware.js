/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { storage } from 'common/storage';
import DOMPurify from 'dompurify';

import { flushSaveToServer, getLastSavedAt, scheduleSaveToServer } from '../serverState';
import { loadSettings, updateSettings } from '../settings/actions';
import { CHAT_ANIM_SPEEDS } from '../settings/constants';
import { selectSettings } from '../settings/selectors';
import { addChatPage, changeChatPage, changeScrollTracking, loadChat, rebuildChat, removeChatPage, saveChatToDisk, toggleAcceptedType, updateChatPage, updateMessageCount } from './actions';
import { MAX_PERSISTED_MESSAGES, MESSAGE_SAVE_INTERVAL } from './constants';
import { createMessage, serializeMessage } from './model';
import { chatRenderer } from './renderer';
import { selectChat, selectCurrentChatPage } from './selectors';

// List of blacklisted tags
const FORBID_TAGS = [
  'iframe',
  'link',
  'video',
];

const saveChatToStorage = async store => {
  const state = selectChat(store.getState());
  const savedAt = getLastSavedAt();
  const fromIndex = Math.max(0,
    chatRenderer.messages.length - MAX_PERSISTED_MESSAGES);
  const messages = chatRenderer.messages
    .slice(fromIndex)
    .map(message => serializeMessage(message));
  storage.set('chat-state', { ...state, savedAt });
  storage.set('chat-messages', messages);
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

/**
 * Applies all appearance and feature settings from the Redux state
 * to the chat renderer, respecting classic mode.
 */
const applySettings = (settings) => {
  // Core appearance
  chatRenderer.setHighlight(
    settings.highlightText,
    settings.highlightColor,
    settings.matchWord,
    settings.matchCase);
  chatRenderer.setHighlightSound(settings.highlightSoundEnabled);

  chatRenderer.setChatClasses(
    settings.chatStyle,
    settings.chatAnimation,
    settings.hoverEffect,
    settings.smoothScroll);
  chatRenderer.setBgAnimation(
    settings.chatBgAnimation,
    settings.chatBgAnimOpacity);
  chatRenderer.setCustomColors(
    settings.chatBgColor,
    settings.chatTextColor,
    settings.chatAccentColor);

  // Animation speed
  const speedDef = CHAT_ANIM_SPEEDS.find(
    s => s.id === settings.chatAnimSpeed);
  const animSpeed = speedDef?.value || '200ms';

  // Text glow
  let glowValue = null;
  const glowColor = settings.textGlowColor
    || settings.chatAccentColor || '#ffdd44';
  if (settings.textGlow === 'subtle') {
    glowValue = '0 0 4px ' + glowColor;
  }
  else if (settings.textGlow === 'strong') {
    glowValue = '0 0 10px ' + glowColor
      + ', 0 0 20px ' + glowColor;
  }

  chatRenderer.setCustomProperties({
    '--chat-anim-speed': animSpeed,
    '--chat-glow': glowValue,
    '--chat-msg-spacing': settings.messageSpacing + 'px',
    '--chat-font-weight': String(settings.fontWeight),
    '--chat-letter-spacing': settings.letterSpacing + 'px',
    '--chat-border-radius': settings.borderRadius + 'px',
  });

  // Timestamps & time dividers
  chatRenderer.setTimestamps(
    settings.enableTimestamps,
    settings.timestampFormat);
  chatRenderer.setTimeDividers(
    settings.enableTimeDividers,
    settings.timeDividerInterval);
};

export const chatMiddleware = store => {
  let initialized = false;
  let loaded = false;
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
  setInterval(() => saveChatToStorage(store), MESSAGE_SAVE_INTERVAL);
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
      saveChatToStorage(store);
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

/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { createHighlightSetting, migrateHighlightSettings } from '../chat/highlight';
import { changeSettingsTab, loadSettings, openChatSettings, toggleSettings, updateSettings } from './actions';
import { FONTS, SETTINGS_TABS } from './constants';
import { RADIO_JOB_DEFAULTS } from './radioJobs';

const initialState = {
  version: 8,
  fontSize: 13,
  fontFamily: FONTS[0],
  lineHeight: 1.2,
  theme: 'default',
  adminMusicVolume: 0.5,
  // Группы подсветки: [{ id, enabled, highlightText, highlightColor,
  // matchWord, matchCase, speechOnly, sound }], верхняя главнее.
  highlightSettings: [createHighlightSetting()],
  chatStyle: 'classic',
  chatAnimation: 'none',
  chatBgColor: '',
  chatTextColor: '',
  chatAccentColor: '',
  smoothScroll: false,
  hoverEffect: false,
  chatAnimSpeed: 'normal',
  chatBgAnimation: 'none',
  chatBgAnimOpacity: 0.5,
  textGlow: 'none',
  textGlowColor: '',
  messageSpacing: 2,
  fontWeight: 400,
  letterSpacing: 0,
  borderRadius: 8,
  // Кастомизация стилей сообщений: { [styleId]: { color, disabled } }
  styleOverrides: {},
  spanAnimations: true,
  // Оформление по типу сообщения: { [type]: { border, tint, anim, flash } }
  typeOverrides: {},
  // Игровые эффекты текста: общий тумблер и { [effectId]: false } выключенных
  gameEffectsEnabled: true,
  gameEffects: {},
  // Гасить анимации сообщений вне окна свежих
  settleOldAnimations: true,
  // Timestamps & time dividers
  enableTimestamps: false,
  timestampFormat: 'hm',
  enableTimeDividers: false,
  timeDividerInterval: 300000,
  showRadioJobs: true,
  // Линия "Новые сообщения" и счётчик на кнопке прокрутки вниз
  newMessagesMarker: true,
  // Сообщений на экране: меньше - легче чат на слабом компьютере
  visibleMessageLimit: 750,
  // Теги должностей в рации: режим цвета, метка глав, имя в цвет отдела,
  // свои цвета { [id из radioJobs.js]: '#hex' }
  ...RADIO_JOB_DEFAULTS,
  view: {
    visible: false,
    activeTab: SETTINGS_TABS[0].id,
  },
};

export const settingsReducer = (state = initialState, action) => {
  const { type, payload } = action;
  if (type === updateSettings.type) {
    return {
      ...state,
      ...payload,
    };
  }
  if (type === loadSettings.type) {
    // Validate version and/or migrate state
    if (!payload?.version) {
      return state;
    }
    const {
      view,
      // До v8 подсветка была одной: эти поля переезжают в первую группу.
      highlightText,
      highlightColor,
      highlightSoundEnabled,
      matchWord,
      matchCase,
      ...settings
    } = payload;
    // null: в загрузке нет подсветки вовсе (частичная или поздняя загрузка),
    // текущие группы остаются.
    const loaded = migrateHighlightSettings(payload);
    // Та же ссылка при том же содержимом: чат не пересобирает подсветку.
    const highlightSettings = !loaded || JSON.stringify(loaded)
      === JSON.stringify(state.highlightSettings)
      ? state.highlightSettings : loaded;
    return {
      ...state,
      ...settings,
      highlightSettings,
      version: state.version,
    };
  }
  if (type === toggleSettings.type) {
    return {
      ...state,
      view: {
        ...state.view,
        visible: !state.view.visible,
      },
    };
  }
  if (type === openChatSettings.type) {
    return {
      ...state,
      view: {
        ...state.view,
        visible: true,
        activeTab: 'chatPage',
      },
    };
  }
  if (type === changeSettingsTab.type) {
    const { tabId } = payload;
    return {
      ...state,
      view: {
        ...state.view,
        activeTab: tabId,
      },
    };
  }
  return state;
};

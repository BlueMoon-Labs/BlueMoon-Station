/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { changeSettingsTab, loadSettings, openChatSettings, toggleSettings, updateSettings } from './actions';
import { FONTS, SETTINGS_TABS } from './constants';

const initialState = {
  version: 5,
  fontSize: 13,
  fontFamily: FONTS[0],
  lineHeight: 1.2,
  theme: 'default',
  adminMusicVolume: 0.5,
  highlightText: '',
  highlightColor: '#ffdd44',
  matchWord: false,
  matchCase: false,
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
  // Timestamps & time dividers
  enableTimestamps: false,
  timestampFormat: 'hm',
  enableTimeDividers: false,
  timeDividerInterval: 300000,
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
    const { view, ...settings } = payload;
    return {
      ...state,
      ...settings,
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

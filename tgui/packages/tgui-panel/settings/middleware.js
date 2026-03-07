/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { storage } from 'common/storage';

import { scheduleSaveToServer } from '../serverState';
import { setClientTheme, THEMES } from '../themes';
import { loadSettings, updateSettings } from './actions';
import { FONTS_DISABLED } from './constants';
import { selectSettings } from './selectors';

const setGlobalFontSize = fontSize => {
  document.documentElement.style
    .setProperty('font-size', fontSize + 'px');
  document.body.style
    .setProperty('font-size', fontSize + 'px');
};

const setGlobalFontFamily = fontFamily => {
  if (fontFamily === FONTS_DISABLED) fontFamily = null;

  document.documentElement.style
    .setProperty('font-family', fontFamily);
  document.body.style
    .setProperty('font-family', fontFamily);
};

export const settingsMiddleware = store => {
  let initialized = false;
  let hydrating = false;
  let dirtyKeys = new Set();
  let lastAppliedTheme = null;

  const isValidTheme = theme => THEMES.includes(theme);

  const trackDirtyKeys = payload => {
    if (!hydrating || !payload || typeof payload !== 'object') {
      return;
    }
    for (let key of Object.keys(payload)) {
      dirtyKeys.add(key);
    }
  };

  const loadSettingsFromStorage = () => {
    hydrating = true;
    storage.get('panel-settings')
      .then(settings => {
        if (!settings) {
          return;
        }
        let nextSettings = settings;
        if (dirtyKeys.size > 0 && typeof nextSettings === 'object') {
          nextSettings = { ...nextSettings };
          for (let key of dirtyKeys) {
            delete nextSettings[key];
          }
        }
        store.dispatch(loadSettings(nextSettings));
      })
      .catch(err => {
        console.error('Failed to load panel settings:', err);
      })
      .finally(() => {
        hydrating = false;
        dirtyKeys.clear();
      });
  };

  return next => action => {
    let nextAction = action;
    let { type, payload } = nextAction;
    if (!initialized) {
      initialized = true;
      loadSettingsFromStorage();
    }
    // Restore settings from server-side persistence (WebView2 storage is not durable)
    if (type === 'panel/state') {
      const stateJson = payload?.state;
      if (typeof stateJson === 'string') {
        try {
          const state = JSON.parse(stateJson);
          if (state?.settings && state?.v === 1) {
            // Mark keys dirty so late browser storage hydration
            // does not overwrite server-restored values
            trackDirtyKeys(state.settings);
            store.dispatch(loadSettings({
              version: 1,
              ...state.settings,
            }));
          }
        }
        catch (err) {
          console.error('Failed to parse panel state from server:', err);
        }
      }
      return next(action);
    }
    if (type === 'panel/theme') {
      const theme = payload?.theme;
      if (!isValidTheme(theme)) {
        return;
      }
      trackDirtyKeys({
        theme,
      });
      nextAction = loadSettings({
        version: 1,
        theme,
      });
      ({ type, payload } = nextAction);
    }
    if (type === updateSettings.type) {
      trackDirtyKeys(payload);
    }
    if (type === updateSettings.type || type === loadSettings.type) {
      const previousSettings = selectSettings(store.getState());
      // Pass action to get an updated state
      next(nextAction);
      const settings = selectSettings(store.getState());
      // Set client theme
      if (settings.theme !== lastAppliedTheme) {
        setClientTheme(settings.theme);
        lastAppliedTheme = settings.theme;
      }
      // Update global UI font size
      setGlobalFontSize(settings.fontSize);
      setGlobalFontFamily(settings.fontFamily);
      // Persist theme server-side for clients where browser storage is not durable.
      if (type === updateSettings.type
        && Object.prototype.hasOwnProperty.call(payload || {}, 'theme')
        && isValidTheme(payload.theme)
        && payload.theme !== previousSettings.theme) {
        Byond.topic({
          tgui: 1,
          window_id: window.__windowId__,
          type: 'panel/theme_set',
          payload: JSON.stringify({
            theme: payload.theme,
          }),
        });
      }
      // Save settings to the web storage
      // Only persist on explicit user actions (updateSettings).
      // Do NOT save on loadSettings — that includes server theme pushes
      // and hydration, which may run before stored settings are loaded,
      // overwriting user data with initialState defaults.
      if (type === updateSettings.type) {
        storage.set('panel-settings', settings).catch(err => {
          console.error('Failed to save panel settings:', err);
        });
        scheduleSaveToServer(store);
      }
      return;
    }
    return next(action);
  };
};

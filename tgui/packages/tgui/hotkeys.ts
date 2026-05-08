/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import * as keycodes from 'common/keycodes';

import { globalEvents, KeyEvent } from './events';
import { keyToByond } from './keyToByond';
import { createLogger } from './logging';
import { setupOrphanedKeyUpForwarding } from './orphanedKeyUp';

const logger = createLogger('hotkeys');

// BYOND macros, in `key: command` format.
const byondMacros: Record<string, string> = {};

// Default set of acquired keys, which will not be sent to BYOND.
const hotKeysAcquired: string[] = [
  keycodes.KEY_ESCAPE,
  keycodes.KEY_ENTER,
  keycodes.KEY_SPACE,
  keycodes.KEY_TAB,
  keycodes.KEY_CTRL,
  keycodes.KEY_SHIFT,
  keycodes.KEY_UP,
  keycodes.KEY_DOWN,
  keycodes.KEY_LEFT,
  keycodes.KEY_RIGHT,
  keycodes.KEY_F5,
];

// State of passed-through keys.
const keyState: Record<string, boolean> = {};

/**
 * Keyboard passthrough logic. This allows you to keep doing things
 * in game while the browser window is focused.
 */
const handlePassthrough = (key: KeyEvent) => {
  const keyString = String(key);
  // In addition to F5, support reloading with Ctrl+R and Ctrl+F5
  if (keyString === 'Ctrl+F5' || keyString === 'Ctrl+R') {
    location.reload();
    return;
  }
  // Open/toggle the FindBar on Ctrl+F
  if (keyString === 'Ctrl+F') {
    if (key.isDown()) {
      key.event.preventDefault();
      globalEvents.emit('findbar-toggle');
    }
    return;
  }
  // NOTE: Alt modifier can be sticky and conflict-prone.
  if (key.event.defaultPrevented
      || key.isModifierKey()
      || hotKeysAcquired.includes(key.key)) {
    return;
  }
  const byondKeyCode = keyToByond(key);
  if (!byondKeyCode) {
    return;
  }
  // Macro
  const macro = byondMacros[byondKeyCode];
  if (macro) {
    logger.debug('macro', macro);
    return Byond.command(macro);
  }
  // KeyDown
  if (key.isDown() && !keyState[byondKeyCode]) {
    keyState[byondKeyCode] = true;
    const command = `KeyDown "${byondKeyCode}"`;
    logger.debug(command);
    return Byond.command(command);
  }
  // KeyUp
  if (key.isUp() && keyState[byondKeyCode]) {
    keyState[byondKeyCode] = false;
    const command = `KeyUp "${byondKeyCode}"`;
    logger.debug(command);
    return Byond.command(command);
  }
};

/**
 * Acquires a lock on the hotkey, which prevents it from being
 * passed through to BYOND.
 */
export const acquireHotKey = (key: string) => {
  hotKeysAcquired.push(key);
};

/**
 * Makes the hotkey available to BYOND again.
 */
export const releaseHotKey = (key: string) => {
  const index = hotKeysAcquired.indexOf(key);
  if (index >= 0) {
    hotKeysAcquired.splice(index, 1);
  }
};

export const releaseHeldKeys = () => {
  for (let byondKeyCode of Object.keys(keyState)) {
    if (keyState[byondKeyCode]) {
      keyState[byondKeyCode] = false;
      logger.log(`releasing key "${byondKeyCode}"`);
      Byond.command(`KeyUp "${byondKeyCode}"`);
    }
  }
};

type ByondSkinMacro = {
  command: string;
  name: string;
};

export const setupHotKeys = () => {
  // Read macros
  Byond.winget('default.*').then((data: Record<string, string>) => {
    // Group each macro by ref
    const groupedByRef: Record<string, ByondSkinMacro> = {};
    for (let key of Object.keys(data)) {
      const keyPath = key.split('.');
      const ref = keyPath[1];
      const prop = keyPath[2];
      if (ref && prop) {
        // This piece of code imperatively adds each property to a
        // ByondSkinMacro object in the order we meet it, which is hard
        // to express safely in typescript.
        if (!groupedByRef[ref]) {
          groupedByRef[ref] = {} as any;
        }
        groupedByRef[ref][prop] = data[key];
      }
    }
    // Insert macros
    const escapedQuotRegex = /\\"/g;
    const unescape = (str: string) => str
      .substring(1, str.length - 1)
      .replace(escapedQuotRegex, '"');
    for (let ref of Object.keys(groupedByRef)) {
      const macro = groupedByRef[ref];
      const byondKeyName = unescape(macro.name);
      byondMacros[byondKeyName] = unescape(macro.command);
    }
    logger.debug('loaded macros', byondMacros);
  });
  // Setup event handlers
  globalEvents.on('window-blur', () => {
    releaseHeldKeys();
  });
  globalEvents.on('input-focus', () => {
    releaseHeldKeys();
  });
  globalEvents.on('key', (key: KeyEvent) => {
    handlePassthrough(key);
  });
  setupOrphanedKeyUpForwarding();
};

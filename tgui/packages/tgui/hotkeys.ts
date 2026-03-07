/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import * as keycodes from 'common/keycodes';

import { globalEvents, KeyEvent } from './events';
import { createLogger } from './logging';

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

// Maps event.key -> BYOND direction names
const BYOND_DIRECTION_MAP: Record<string, string> = {
  'ArrowLeft': 'West',
  'ArrowUp': 'North',
  'ArrowRight': 'East',
  'ArrowDown': 'South',
  'PageUp': 'Northeast',
  'PageDown': 'Southeast',
  'End': 'Southwest',
  'Home': 'Northwest',
};

/**
 * Converts a KeyEvent to BYOND key name.
 *
 * Uses event.code (physical key) for layout-independent mapping of letters,
 * digits, and symbols. This ensures hotkeys work regardless of keyboard
 * layout (e.g. Russian, German QWERTZ, French AZERTY).
 */
const keyToByond = (keyEvent: KeyEvent): string | undefined => {
  const { key, code } = keyEvent;

  // Numpad digits — distinguish via event.code
  if (/^Numpad\d$/.test(code)) {
    return 'Numpad' + code.slice(6);
  }

  // Direction/navigation keys (layout-independent in event.key)
  if (BYOND_DIRECTION_MAP[key]) {
    return BYOND_DIRECTION_MAP[key];
  }

  // Modifier and special keys (layout-independent in event.key)
  if (key === 'Shift') return 'Shift';
  if (key === 'Control') return 'Ctrl';
  if (key === 'Alt') return 'Alt';
  if (key === 'Insert') return 'Insert';
  if (key === 'Delete') return 'Delete';

  // Letters — use physical key code (layout-independent)
  // e.g. 'KeyW' → 'W', works for any keyboard layout
  if (/^Key[A-Z]$/.test(code)) {
    return code.charAt(3);
  }

  // Digits — use physical key code (layout-independent)
  // e.g. 'Digit1' → '1'
  if (/^Digit\d$/.test(code)) {
    return code.charAt(5);
  }

  // F-keys (layout-independent in event.key)
  if (/^F\d+$/.test(key)) return key;

  // Symbol keys — use physical key code (layout-independent)
  if (code === 'Comma') return ',';
  if (code === 'Minus') return '-';
  if (code === 'Period') return '.';

  return undefined;
};

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
  globalEvents.on('key', (key: KeyEvent) => {
    handlePassthrough(key);
  });
  // Fix for stuck keys pressed on the map and released in TGUI.
  // Raw DOM listeners bypass the canStealFocus filter in events.js.
  // If keyup has no preceding keydown in this context, the key was
  // pressed on the map side — forward KeyUp to BYOND.
  const pressedInBrowser: Record<string, boolean> = {};

  document.addEventListener('keydown', (e: KeyboardEvent) => {
    const byondKey = keyToByond(new KeyEvent(e, 'keydown', false));
    if (byondKey) {
      pressedInBrowser[byondKey] = true;
    }
  });

  document.addEventListener('keyup', (e: KeyboardEvent) => {
    const byondKey = keyToByond(new KeyEvent(e, 'keyup'));
    if (!byondKey) {
      return;
    }
    if (!pressedInBrowser[byondKey]) {
      logger.debug(`forwarding orphaned KeyUp "${byondKey}"`);
      Byond.command(`KeyUp "${byondKey}"`);
    }
    pressedInBrowser[byondKey] = false;
  });

  window.addEventListener('blur', () => {
    for (const key of Object.keys(pressedInBrowser)) {
      pressedInBrowser[key] = false;
    }
  });
};

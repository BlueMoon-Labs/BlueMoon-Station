/**
 * Basically, hacks from goonchat which try to keep the map focused at all
 * times, except for when some meaningful action happens o
 *
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { defer } from 'common/defer';
import { KEY_ALT, KEY_CTRL, KEY_SHIFT } from 'common/keycodes';
import { vecLength, vecSubtract } from 'common/vector';
import { canStealFocus, globalEvents } from 'tgui/events';
import { focusMap } from 'tgui/focus';

// Empyrically determined number for the smallest possible
// text you can select with the mouse.
const MIN_SELECTION_DISTANCE = 10;

const deferredFocusMap = () => defer(() => focusMap());

// Maps browser event.key values to BYOND key names for modifier keys.
const MODIFIER_TO_BYOND = {
  [KEY_ALT]: 'Alt',
  [KEY_CTRL]: 'Ctrl',
  [KEY_SHIFT]: 'Shift',
};

export const setupPanelFocusHacks = () => {
  let focusStolen = false;
  let clickStartPos = null;
  window.addEventListener('focusin', e => {
    focusStolen = canStealFocus(e.target);
  });
  window.addEventListener('mousedown', e => {
    clickStartPos = [e.screenX, e.screenY];
  });
  window.addEventListener('mouseup', e => {
    if (clickStartPos) {
      const clickEndPos = [e.screenX, e.screenY];
      const dist = vecLength(vecSubtract(clickEndPos, clickStartPos));
      if (dist >= MIN_SELECTION_DISTANCE) {
        focusStolen = true;
      }
    }
    if (!focusStolen) {
      deferredFocusMap();
    }
  });
  globalEvents.on('keydown', key => {
    if (key.isModifierKey()) {
      return;
    }
    deferredFocusMap();
  });

  // Fix for stuck modifier keys (Alt, Ctrl, Shift) after BYOND 516 migration.
  // When a modifier is pressed while the map has focus and released while the
  // WebView2 panel has focus, BYOND never receives the KeyUp event.
  // We track whether each modifier was pressed in the panel; if we see a KeyUp
  // without a preceding KeyDown, the key was pressed on the map side, and we
  // forward the KeyUp to BYOND.
  // Uses raw DOM listeners to bypass the canStealFocus filter in events.js,
  // which would block events when an input/textarea (e.g. chat) is focused.
  const modifierPressedInPanel = {};

  document.addEventListener('keydown', (e) => {
    const byondKey = MODIFIER_TO_BYOND[e.key];
    if (byondKey) {
      modifierPressedInPanel[byondKey] = true;
    }
  });

  document.addEventListener('keyup', (e) => {
    const byondKey = MODIFIER_TO_BYOND[e.key];
    if (byondKey) {
      if (!modifierPressedInPanel[byondKey]) {
        Byond.command(`KeyUp "${byondKey}"`);
      }
      modifierPressedInPanel[byondKey] = false;
    }
  });

  window.addEventListener('blur', () => {
    for (const key of Object.keys(modifierPressedInPanel)) {
      modifierPressedInPanel[key] = false;
    }
  });
};

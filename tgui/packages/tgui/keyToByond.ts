// Maps browser event.key values to BYOND direction names.
const CODE_MAP: Record<string, string> = {
  // Symbol keys
  Backquote: "`",
  Minus: "-",
  Equal: "=",
  BracketLeft: "[",
  BracketRight: "]",
  Backslash: "\\",
  Semicolon: ";",
  Quote: "'",
  Comma: ",",
  Period: ".",
  Slash: "/",

  // Navigation
  ArrowUp: "North",
  ArrowDown: "South",
  ArrowLeft: "West",
  ArrowRight: "East",

  Home: "Northwest",
  PageUp: "Northeast",
  End: "Southwest",
  PageDown: "Southeast",

  // Special
  Enter: "Return",
  Backspace: "Back",
  Space: "Space",
  Tab: "Tab",
  Escape: "Escape",

  Insert: "Insert",
  Delete: "Delete",
  Pause: "Pause",
  PrintScreen: "Snapshot",

  // Windows
  MetaLeft: "LWin",
  MetaRight: "RWin",
  ContextMenu: "Apps",

  // Numpad
  Numpad0: "Numpad0",
  Numpad1: "Numpad1",
  Numpad2: "Numpad2",
  Numpad3: "Numpad3",
  Numpad4: "Numpad4",
  Numpad5: "Numpad5",
  Numpad6: "Numpad6",
  Numpad7: "Numpad7",
  Numpad8: "Numpad8",
  Numpad9: "Numpad9",

  NumpadAdd: "Add",
  NumpadSubtract: "Subtract",
  NumpadMultiply: "Multiply",
  NumpadDivide: "Divide",

  // NumLock-specific
  NumpadDecimal: "Delete",
  NumpadEnter: "Return",
};

type ByondKeyEvent = {
  key: string;
  code: string;
};

/**
 * Converts a browser keyboard event into a BYOND key name.
 *
 * Uses event.code (physical key) for layout-independent mapping of letters,
 * digits, and symbols. This keeps movement keys stable on non-QWERTY layouts.
 */
export const keyToByond = (keyEvent: ByondKeyEvent): string | undefined => {
  const { key, code } = keyEvent;

  // Symbol keys: use physical key code.
  const mapped = CODE_MAP[code];
  if (mapped) {
    return mapped;
  }

  // Modifier and special keys are layout-independent in event.key.
  if (key === 'Shift') return 'Shift';
  if (key === 'Control') return 'Ctrl';
  if (key === 'Alt') return 'Alt';
  if (key === 'Insert') return 'Insert';
  if (key === 'Delete') return 'Delete';

  // Letters: use physical key code, e.g. KeyW -> W.
  if (/^Key[A-Z]$/.test(code)) {
    return code.charAt(3);
  }

  // Digits: use physical key code, e.g. Digit1 -> 1.
  if (/^Digit\d$/.test(code)) {
    return code.charAt(5);
  }

  // F-keys are layout-independent in event.key.
  if (/^F\d+$/.test(key)) return key;

  return undefined;
};

// Maps browser event.key values to BYOND direction names.
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

  // Numpad digits: distinguish via event.code.
  if (/^Numpad\d$/.test(code)) {
    return 'Numpad' + code.slice(6);
  }

  // Direction/navigation keys are layout-independent in event.key.
  if (BYOND_DIRECTION_MAP[key]) {
    return BYOND_DIRECTION_MAP[key];
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

  // Symbol keys: use physical key code.
  if (code === 'Comma') return ',';
  if (code === 'Minus') return '-';
  if (code === 'Period') return '.';

  return undefined;
};

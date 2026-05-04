import { KeyEvent } from './events';
import { keyToByond } from './keyToByond';

export const FORCE_RELEASE_ALL_KEYS_COMMAND = '.force_release_all_keys';

type CommandSender = (command: string) => void;

type OrphanedKeyUpForwardingOptions = {
  command?: CommandSender;
  targetDocument?: Document;
  targetWindow?: Window;
};

const defaultCommand: CommandSender = command => Byond.command(command);

export const forceReleaseAllServerKeys = (
  command: CommandSender = defaultCommand
) => {
  command(FORCE_RELEASE_ALL_KEYS_COMMAND);
};

/**
 * Forwards KeyUp events that were pressed outside the current browser context.
 *
 * This covers the BYOND 516/WebView2 failure mode where a key is pressed on the
 * map, focus moves to TGUI or the panel, and the release never reaches BYOND.
 */
export const setupOrphanedKeyUpForwarding = (
  options: OrphanedKeyUpForwardingOptions = {}
) => {
  const command = options.command || defaultCommand;
  const targetDocument = options.targetDocument || document;
  const targetWindow = options.targetWindow || window;
  const pressedInBrowser: Record<string, boolean> = {};

  const clearPressedInBrowser = () => {
    for (const key of Object.keys(pressedInBrowser)) {
      pressedInBrowser[key] = false;
    }
  };

  const handleKeyDown = (event: KeyboardEvent) => {
    const byondKey = keyToByond(new KeyEvent(event, 'keydown', false));
    if (byondKey) {
      pressedInBrowser[byondKey] = true;
    }
  };

  const handleKeyUp = (event: KeyboardEvent) => {
    const byondKey = keyToByond(new KeyEvent(event, 'keyup'));
    if (!byondKey) {
      return;
    }
    if (!pressedInBrowser[byondKey]) {
      command(`KeyUp "${byondKey}"`);
    }
    pressedInBrowser[byondKey] = false;
  };

  const handleFocusReturn = () => {
    clearPressedInBrowser();
    forceReleaseAllServerKeys(command);
  };

  const handleVisibilityChange = () => {
    if (targetDocument.visibilityState === 'visible') {
      handleFocusReturn();
    }
  };

  targetDocument.addEventListener('keydown', handleKeyDown);
  targetDocument.addEventListener('keyup', handleKeyUp);
  targetDocument.addEventListener('visibilitychange', handleVisibilityChange);
  targetWindow.addEventListener('blur', clearPressedInBrowser);
  targetWindow.addEventListener('focus', handleFocusReturn);

  return () => {
    targetDocument.removeEventListener('keydown', handleKeyDown);
    targetDocument.removeEventListener('keyup', handleKeyUp);
    targetDocument.removeEventListener('visibilitychange', handleVisibilityChange);
    targetWindow.removeEventListener('blur', clearPressedInBrowser);
    targetWindow.removeEventListener('focus', handleFocusReturn);
  };
};

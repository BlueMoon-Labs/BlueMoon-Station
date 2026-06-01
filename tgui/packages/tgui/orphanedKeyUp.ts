import { KeyEvent } from './events';
import { keyToByond } from './keyToByond';

type CommandSender = (command: string) => void;

type OrphanedKeyUpForwardingOptions = {
  command?: CommandSender;
  targetDocument?: Document;
  targetWindow?: Window;
};

const defaultCommand: CommandSender = command => Byond.command(command);

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
    // If focus moved into this browser while a map-side key was already held,
    // the first keydown we see can be an OS auto-repeat. That key did not
    // originate here, so its eventual keyup still needs to be forwarded.
    if (byondKey && !event.repeat) {
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

  targetDocument.addEventListener('keydown', handleKeyDown);
  targetDocument.addEventListener('keyup', handleKeyUp);
  targetWindow.addEventListener('blur', clearPressedInBrowser);

  return () => {
    targetDocument.removeEventListener('keydown', handleKeyDown);
    targetDocument.removeEventListener('keyup', handleKeyUp);
    targetWindow.removeEventListener('blur', clearPressedInBrowser);
  };
};

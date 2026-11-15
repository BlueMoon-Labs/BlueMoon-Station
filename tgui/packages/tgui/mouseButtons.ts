type CommandSender = (command: string) => void;

type MouseButtonPassthroughOptions = {
  command?: CommandSender;
  targetDocument?: Document;
  targetWindow?: Window;
};

const SIDE_BUTTONS: Record<number, string> = {
  3: 'Mouse4',
  4: 'Mouse5',
};

/**
 * Side mouse button as a BYOND keybinding key, same names the map sends.
 */
export const mouseButtonToByond = (button: number): string | undefined =>
  SIDE_BUTTONS[button];

const defaultCommand: CommandSender = (command) => Byond.command(command);

/**
 * Side mouse buttons over a TGUI window act like keys and do not navigate
 * the browser back or forward.
 */
export const setupMouseButtonPassthrough = (
  options: MouseButtonPassthroughOptions = {},
) => {
  const command = options.command || defaultCommand;
  const targetDocument = options.targetDocument || document;
  const targetWindow = options.targetWindow || window;
  const held: Record<string, boolean> = {};

  const release = (key: string) => {
    if (held[key]) {
      held[key] = false;
      command(`KeyUp "${key}"`);
    }
  };

  const handleDown = (event: MouseEvent) => {
    const key = mouseButtonToByond(event.button);
    if (!key || event.defaultPrevented) {
      return;
    }
    event.preventDefault();
    release(key);
    held[key] = true;
    command(`KeyDown "${key}"`);
  };

  const handleUp = (event: MouseEvent) => {
    const key = mouseButtonToByond(event.button);
    if (!key) {
      return;
    }
    event.preventDefault();
    release(key);
  };

  const swallow = (event: MouseEvent) => {
    if (mouseButtonToByond(event.button)) {
      event.preventDefault();
    }
  };

  const releaseAll = () => {
    for (const key of Object.keys(held)) {
      release(key);
    }
  };

  targetDocument.addEventListener('mousedown', handleDown);
  targetDocument.addEventListener('mouseup', handleUp);
  targetDocument.addEventListener('auxclick', swallow);
  targetWindow.addEventListener('blur', releaseAll);

  return () => {
    targetDocument.removeEventListener('mousedown', handleDown);
    targetDocument.removeEventListener('mouseup', handleUp);
    targetDocument.removeEventListener('auxclick', swallow);
    targetWindow.removeEventListener('blur', releaseAll);
  };
};

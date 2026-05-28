import { setupOrphanedKeyUpForwarding } from './orphanedKeyUp';

const keyEvent = (
  type: 'keydown' | 'keyup',
  key: string,
  code: string,
  repeat = false
) => (
  new KeyboardEvent(type, { key, code, repeat, bubbles: true })
);

describe('setupOrphanedKeyUpForwarding', () => {
  let command: jest.Mock;
  let cleanup: () => void;

  beforeEach(() => {
    command = jest.fn();
  });

  afterEach(() => {
    cleanup?.();
    jest.restoreAllMocks();
  });

  const setup = () => {
    cleanup = setupOrphanedKeyUpForwarding({ command });
  };

  test('does not forward a key released in the same browser context', () => {
    setup();

    document.dispatchEvent(keyEvent('keydown', 'w', 'KeyW'));
    document.dispatchEvent(keyEvent('keyup', 'w', 'KeyW'));

    expect(command).not.toHaveBeenCalled();
  });

  test.each([
    ['W movement key', 'w', 'KeyW', 'KeyUp "W"'],
    ['A movement key', 'a', 'KeyA', 'KeyUp "A"'],
    ['S movement key', 's', 'KeyS', 'KeyUp "S"'],
    ['D movement key', 'd', 'KeyD', 'KeyUp "D"'],
    ['Cyrillic physical W', 'ц', 'KeyW', 'KeyUp "W"'],
    ['ArrowUp', 'ArrowUp', 'ArrowUp', 'KeyUp "North"'],
    ['ArrowLeft', 'ArrowLeft', 'ArrowLeft', 'KeyUp "West"'],
    ['Shift', 'Shift', 'ShiftLeft', 'KeyUp "Shift"'],
    ['Control', 'Control', 'ControlLeft', 'KeyUp "Ctrl"'],
    ['Alt', 'Alt', 'AltLeft', 'KeyUp "Alt"'],
  ])('forwards orphaned %s keyup', (_name, key, code, expectedCommand) => {
    setup();

    document.dispatchEvent(keyEvent('keyup', key, code));

    expect(command).toHaveBeenCalledTimes(1);
    expect(command).toHaveBeenCalledWith(expectedCommand);
  });

  test('does not forward an unmapped orphaned keyup', () => {
    setup();

    document.dispatchEvent(keyEvent('keyup', 'Backspace', 'Backspace'));

    expect(command).not.toHaveBeenCalled();
  });

  test('clears local pressed state on window blur before keyup returns', () => {
    setup();

    document.dispatchEvent(keyEvent('keydown', 'w', 'KeyW'));
    window.dispatchEvent(new Event('blur'));
    document.dispatchEvent(keyEvent('keyup', 'w', 'KeyW'));

    expect(command).toHaveBeenCalledWith('KeyUp "W"');
  });

  test('tracks keys independently when one key was pressed in browser and another was not', () => {
    setup();

    document.dispatchEvent(keyEvent('keydown', 'w', 'KeyW'));
    document.dispatchEvent(keyEvent('keyup', 'd', 'KeyD'));
    document.dispatchEvent(keyEvent('keyup', 'w', 'KeyW'));

    expect(command).toHaveBeenCalledTimes(1);
    expect(command).toHaveBeenCalledWith('KeyUp "D"');
  });

  test('forwards repeated orphaned keyups until a real keydown is seen', () => {
    setup();

    document.dispatchEvent(keyEvent('keyup', 'w', 'KeyW'));
    document.dispatchEvent(keyEvent('keyup', 'w', 'KeyW'));
    document.dispatchEvent(keyEvent('keydown', 'w', 'KeyW'));
    document.dispatchEvent(keyEvent('keyup', 'w', 'KeyW'));

    expect(command).toHaveBeenCalledTimes(2);
    expect(command).toHaveBeenNthCalledWith(1, 'KeyUp "W"');
    expect(command).toHaveBeenNthCalledWith(2, 'KeyUp "W"');
  });

  test('forwards keyup after only seeing an auto-repeat keydown', () => {
    setup();

    document.dispatchEvent(keyEvent('keydown', 'w', 'KeyW', true));
    document.dispatchEvent(keyEvent('keyup', 'w', 'KeyW'));

    expect(command).toHaveBeenCalledTimes(1);
    expect(command).toHaveBeenCalledWith('KeyUp "W"');
  });

  test('does not force-release server keys when the browser window gains focus', () => {
    setup();

    window.dispatchEvent(new Event('focus'));

    expect(command).not.toHaveBeenCalled();
  });

  test('does not force-release server keys when the document becomes visible again', () => {
    setup();
    Object.defineProperty(document, 'visibilityState', {
      value: 'hidden',
      configurable: true,
    });

    document.dispatchEvent(new Event('visibilitychange'));
    expect(command).not.toHaveBeenCalled();

    Object.defineProperty(document, 'visibilityState', {
      value: 'visible',
      configurable: true,
    });
    document.dispatchEvent(new Event('visibilitychange'));

    expect(command).not.toHaveBeenCalled();
  });
});

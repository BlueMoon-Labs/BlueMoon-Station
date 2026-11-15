import { mouseButtonToByond, setupMouseButtonPassthrough } from './mouseButtons';

const mouse = (type: string, button: number) =>
  new MouseEvent(type, { button, bubbles: true, cancelable: true });

describe('mouseButtonToByond', () => {
  test.each([
    [0, undefined],
    [1, undefined],
    [2, undefined],
    [3, 'Mouse4'],
    [4, 'Mouse5'],
  ])('button %i -> %s', (button, expected) => {
    expect(mouseButtonToByond(button)).toBe(expected);
  });
});

describe('setupMouseButtonPassthrough', () => {
  let command: jest.Mock;
  let cleanup: () => void;

  beforeEach(() => {
    command = jest.fn();
    cleanup = setupMouseButtonPassthrough({ command });
  });

  afterEach(() => {
    cleanup?.();
  });

  test('side buttons press and release as keys', () => {
    document.dispatchEvent(mouse('mousedown', 3));
    document.dispatchEvent(mouse('mouseup', 3));
    document.dispatchEvent(mouse('mousedown', 4));
    document.dispatchEvent(mouse('mouseup', 4));
    expect(command.mock.calls).toEqual([
      ['KeyDown "Mouse4"'],
      ['KeyUp "Mouse4"'],
      ['KeyDown "Mouse5"'],
      ['KeyUp "Mouse5"'],
    ]);
  });

  test('side buttons do not navigate the browser', () => {
    for (const type of ['mousedown', 'mouseup', 'auxclick']) {
      const event = mouse(type, 3);
      document.dispatchEvent(event);
      expect(event.defaultPrevented).toBe(true);
    }
  });

  test('ordinary buttons are left alone', () => {
    for (const button of [0, 1, 2]) {
      const event = mouse('mousedown', button);
      document.dispatchEvent(event);
      expect(event.defaultPrevented).toBe(false);
    }
    expect(command).not.toHaveBeenCalled();
  });

  test('a lost release does not leave the key stuck', () => {
    document.dispatchEvent(mouse('mousedown', 3));
    document.dispatchEvent(mouse('mousedown', 3));
    expect(command.mock.calls).toEqual([
      ['KeyDown "Mouse4"'],
      ['KeyUp "Mouse4"'],
      ['KeyDown "Mouse4"'],
    ]);
  });

  test('release without a press here sends nothing', () => {
    document.dispatchEvent(mouse('mouseup', 4));
    expect(command).not.toHaveBeenCalled();
  });

  test('window blur releases held side buttons', () => {
    document.dispatchEvent(mouse('mousedown', 4));
    window.dispatchEvent(new Event('blur'));
    expect(command.mock.calls).toEqual([
      ['KeyDown "Mouse5"'],
      ['KeyUp "Mouse5"'],
    ]);
  });

  test('a press already handled by the page is not forwarded', () => {
    const event = mouse('mousedown', 3);
    event.preventDefault();
    document.dispatchEvent(event);
    expect(command).not.toHaveBeenCalled();
  });
});

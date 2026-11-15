import { captureModifiers } from './KeybindingsTab';

const held = { altKey: true, ctrlKey: true, shiftKey: true };
const none = { altKey: false, ctrlKey: false, shiftKey: false };

describe('captureModifiers', () => {
  test('ordinary bindings keep held modifiers', () => {
    expect(captureModifiers(false, held)).toEqual({ alt: 1, ctrl: 1, shift: 1 });
    expect(captureModifiers(false, { ...none, shiftKey: true })).toEqual({ alt: 0, ctrl: 0, shift: 1 });
  });

  test('bindings without modifiers drop held modifiers', () => {
    expect(captureModifiers(true, held)).toEqual({ alt: 0, ctrl: 0, shift: 0 });
  });
});

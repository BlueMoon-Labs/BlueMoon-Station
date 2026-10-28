import { formatScrollButtonLabel } from './ChatScrollButton';

describe('formatScrollButtonLabel', () => {
  test('shows the unread count only when enabled and non-zero', () => {
    expect(formatScrollButtonLabel(0, true)).toBe('Прокрутить вниз');
    expect(formatScrollButtonLabel(7, false)).toBe('Прокрутить вниз');
    expect(formatScrollButtonLabel(7, true)).toBe('Прокрутить вниз (7)');
    expect(formatScrollButtonLabel(1500, true)).toBe('Прокрутить вниз (999+)');
  });
});

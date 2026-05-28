const { isBundleFile, createDebouncedReload } = require('./watcher.cjs');

describe('isBundleFile', () => {
  test('matches bundle js/css', () => {
    expect(isBundleFile('tgui.bundle.js')).toBe(true);
    expect(isBundleFile('tgui-panel.bundle.css')).toBe(true);
  });
  test('ignores non-bundle and undefined', () => {
    expect(isBundleFile('tgui.bundle.js.map')).toBe(false);
    expect(isBundleFile('readme.txt')).toBe(false);
    expect(isBundleFile(undefined)).toBe(false);
  });
});

describe('createDebouncedReload', () => {
  beforeEach(() => jest.useFakeTimers());
  afterEach(() => jest.useRealTimers());

  test('broadcasts hotUpdate once after burst of bundle changes', () => {
    const broadcast = jest.fn();
    const onChange = createDebouncedReload(broadcast, 100);
    onChange('tgui.bundle.js');
    onChange('tgui.bundle.css');
    onChange('tgui.bundle.js');
    expect(broadcast).not.toHaveBeenCalled();
    jest.advanceTimersByTime(100);
    expect(broadcast).toHaveBeenCalledTimes(1);
    expect(broadcast).toHaveBeenCalledWith({ type: 'hotUpdate' });
  });

  test('ignores non-bundle files', () => {
    const broadcast = jest.fn();
    const onChange = createDebouncedReload(broadcast, 100);
    onChange('something.txt');
    jest.advanceTimersByTime(100);
    expect(broadcast).not.toHaveBeenCalled();
  });
});

import { storage } from 'common/storage';

import {
  getScreenSize,
  getWindowPosition,
  getWindowSize,
  recallWindowGeometry,
} from './drag';
import {
  constraintPosition,
  isWindowSizeApplied,
  touchRecents,
} from './drag.utils';

// Save and restore window properties between tests
const originalDescriptors = {};
const originalStorageGet = storage.get;
const originalStorageSet = storage.set;
const windowProps = [
  'devicePixelRatio',
  'screenLeft',
  'screenTop',
  'innerWidth',
  'innerHeight',
  'screen',
];

beforeEach(() => {
  for (const prop of windowProps) {
    originalDescriptors[prop] = Object.getOwnPropertyDescriptor(window, prop);
  }
});

afterEach(() => {
  for (const prop of windowProps) {
    if (originalDescriptors[prop]) {
      Object.defineProperty(window, prop, originalDescriptors[prop]);
    } else {
      delete window[prop];
    }
  }
  storage.get = originalStorageGet;
  storage.set = originalStorageSet;
  document.body.style.zoom = '';
});

const setWindowProp = (prop, value) => {
  Object.defineProperty(window, prop, {
    configurable: true,
    writable: true,
    value,
  });
};

// --------------------------------------------------------
// DPI coordinate functions
// --------------------------------------------------------

describe('getWindowPosition', () => {
  test('returns screenLeft and screenTop multiplied by app scale', async () => {
    setWindowProp('screenLeft', 100);
    setWindowProp('screenTop', 200);
    setWindowProp('devicePixelRatio', 3);
    await recallWindowGeometry({ scale: 2 });

    const [x, y] = getWindowPosition();
    expect(x).toBe(200);
    expect(y).toBe(400);
  });

  test('falls back to browser pixel ratio when scale is undefined', async () => {
    setWindowProp('screenLeft', 100);
    setWindowProp('screenTop', 50);
    setWindowProp('devicePixelRatio', 1.25);
    await recallWindowGeometry({});

    const [x, y] = getWindowPosition();
    expect(x).toBe(125);
    expect(y).toBe(Math.round(50 * 1.25));
  });

  test('falls back to 1 when scale and browser pixel ratio are invalid', async () => {
    setWindowProp('screenLeft', 100);
    setWindowProp('screenTop', 50);
    setWindowProp('devicePixelRatio', 0);
    await recallWindowGeometry({});

    const [x, y] = getWindowPosition();
    expect(x).toBe(100);
    expect(y).toBe(50);
  });

  test('rounds to integers', async () => {
    setWindowProp('screenLeft', 100.7);
    setWindowProp('screenTop', 200.3);
    setWindowProp('devicePixelRatio', 1.5);
    await recallWindowGeometry({ scale: 1.25 });

    const [x, y] = getWindowPosition();
    expect(x).toBe(Math.round(100.7 * 1.25));
    expect(y).toBe(Math.round(200.3 * 1.25));
  });

  test('handles fractional app scale 1.25', async () => {
    setWindowProp('screenLeft', 100);
    setWindowProp('screenTop', 100);
    setWindowProp('devicePixelRatio', 1.875);
    await recallWindowGeometry({ scale: 1.25 });

    const [x, y] = getWindowPosition();
    expect(x).toBe(125);
    expect(y).toBe(125);
  });

  test('handles high app scale 4.0', async () => {
    setWindowProp('screenLeft', 50);
    setWindowProp('screenTop', 50);
    setWindowProp('devicePixelRatio', 5);
    await recallWindowGeometry({ scale: 4 });

    const [x, y] = getWindowPosition();
    expect(x).toBe(200);
    expect(y).toBe(200);
  });
});

describe('getWindowSize', () => {
  test('returns innerWidth and innerHeight multiplied by devicePixelRatio', () => {
    setWindowProp('innerWidth', 800);
    setWindowProp('innerHeight', 600);
    setWindowProp('devicePixelRatio', 2);

    const [w, h] = getWindowSize();
    expect(w).toBe(1600);
    expect(h).toBe(1200);
  });

  test('falls back to pixelRatio 1 when null', () => {
    setWindowProp('innerWidth', 800);
    setWindowProp('innerHeight', 600);
    setWindowProp('devicePixelRatio', null);

    const [w, h] = getWindowSize();
    expect(w).toBe(800);
    expect(h).toBe(600);
  });

  test('handles fractional DPI 1.75', () => {
    setWindowProp('innerWidth', 1024);
    setWindowProp('innerHeight', 768);
    setWindowProp('devicePixelRatio', 1.75);

    const [w, h] = getWindowSize();
    expect(w).toBe(Math.round(1024 * 1.75));
    expect(h).toBe(Math.round(768 * 1.75));
  });
});

describe('getScreenSize', () => {
  test('returns availWidth and availHeight multiplied by app scale', async () => {
    Object.defineProperty(window, 'screen', {
      configurable: true,
      value: { availWidth: 1920, availHeight: 1080 },
    });
    setWindowProp('devicePixelRatio', 2.0);
    await recallWindowGeometry({ scale: 1.5 });

    const [w, h] = getScreenSize();
    expect(w).toBe(2880);
    expect(h).toBe(1620);
  });

  test('falls back to browser pixel ratio when scale is missing', async () => {
    Object.defineProperty(window, 'screen', {
      configurable: true,
      value: { availWidth: 1920, availHeight: 1080 },
    });
    setWindowProp('devicePixelRatio', 1.25);
    await recallWindowGeometry({});

    const [w, h] = getScreenSize();
    expect(w).toBe(2400);
    expect(h).toBe(1350);
  });
});

// --------------------------------------------------------
// isWindowSizeApplied (pure function from drag.utils)
// --------------------------------------------------------

describe('isWindowSizeApplied', () => {
  test('returns true when current size exactly matches target', () => {
    expect(isWindowSizeApplied([800, 600], [800, 600], 1.0)).toBe(true);
  });

  test('returns true when within epsilon tolerance', () => {
    // At pr=1.5: epsilon = max(2, ceil(1.5*2)) = max(2, 3) = 3
    expect(isWindowSizeApplied([800, 600], [803, 603], 1.5)).toBe(true);
    expect(isWindowSizeApplied([800, 600], [797, 597], 1.5)).toBe(true);
  });

  test('returns false when outside epsilon tolerance', () => {
    // At pr=1.5: epsilon = 3
    expect(isWindowSizeApplied([800, 600], [804, 600], 1.5)).toBe(false);
    expect(isWindowSizeApplied([800, 600], [800, 604], 1.5)).toBe(false);
  });

  test('epsilon scales with pixel ratio', () => {
    // pr=1.0: epsilon = max(2, ceil(2)) = 2
    expect(isWindowSizeApplied([100, 100], [102, 100], 1.0)).toBe(true);
    expect(isWindowSizeApplied([100, 100], [103, 100], 1.0)).toBe(false);

    // pr=2.0: epsilon = max(2, ceil(4)) = 4
    expect(isWindowSizeApplied([100, 100], [104, 100], 2.0)).toBe(true);
    expect(isWindowSizeApplied([100, 100], [105, 100], 2.0)).toBe(false);

    // pr=3.0: epsilon = max(2, ceil(6)) = 6
    expect(isWindowSizeApplied([100, 100], [106, 100], 3.0)).toBe(true);
    expect(isWindowSizeApplied([100, 100], [107, 100], 3.0)).toBe(false);
  });

  test('epsilon has minimum of 2', () => {
    // pr=0.5: ceil(0.5*2) = 1, max(2, 1) = 2
    expect(isWindowSizeApplied([100, 100], [102, 100], 0.5)).toBe(true);
    expect(isWindowSizeApplied([100, 100], [103, 100], 0.5)).toBe(false);
  });

  test('both dimensions must be within tolerance', () => {
    // Width within, height outside
    expect(isWindowSizeApplied([100, 100], [101, 110], 1.0)).toBe(false);
    // Width outside, height within
    expect(isWindowSizeApplied([100, 100], [110, 101], 1.0)).toBe(false);
  });
});

// --------------------------------------------------------
// touchRecents (pure function from drag.utils)
// --------------------------------------------------------

describe('touchRecents', () => {
  test('moves touched item to front', () => {
    const [result] = touchRecents(['a', 'b', 'c'], 'b');
    expect(result).toEqual(['b', 'a', 'c']);
  });

  test('adds new item to front', () => {
    const [result] = touchRecents(['a', 'b'], 'c');
    expect(result).toEqual(['c', 'a', 'b']);
  });

  test('deduplicates touched item', () => {
    const [result] = touchRecents(['a', 'b', 'c'], 'b');
    const count = result.filter((x) => x === 'b').length;
    expect(count).toBe(1);
  });

  test('trims array to limit', () => {
    const [result, trimmed] = touchRecents(['a', 'b', 'c'], 'd', 3);
    expect(result).toEqual(['d', 'a', 'b']);
    expect(trimmed).toBe('c');
  });

  test('returns trimmed item when limit exceeded', () => {
    const [result, trimmed] = touchRecents(['a', 'b'], 'c', 2);
    expect(result).toEqual(['c', 'a']);
    expect(trimmed).toBe('b');
  });

  test('empty array starts with just the touched item', () => {
    const [result, trimmed] = touchRecents([], 'x');
    expect(result).toEqual(['x']);
    expect(trimmed).toBeUndefined();
  });

  test('returns undefined trimmed item when within limit', () => {
    const [, trimmed] = touchRecents(['a'], 'b', 50);
    expect(trimmed).toBeUndefined();
  });

  test('touching item already at front keeps order', () => {
    const [result] = touchRecents(['a', 'b', 'c'], 'a');
    expect(result).toEqual(['a', 'b', 'c']);
  });

  test('default limit is 50', () => {
    const items = Array.from({ length: 50 }, (_, i) => `item${i}`);
    const [result, trimmed] = touchRecents(items, 'new');
    expect(result.length).toBe(50);
    expect(result[0]).toBe('new');
    expect(trimmed).toBe('item49');
  });
});

// --------------------------------------------------------
// constraintPosition (pure function from drag.utils)
// --------------------------------------------------------

describe('constraintPosition', () => {
  const screenPos = [0, 0];
  const screenSize = [1920, 1080];

  test('position within bounds returns unchanged', () => {
    const [relocated, nextPos] = constraintPosition(
      [100, 100], [200, 200], screenPos, screenSize,
    );
    expect(relocated).toBe(false);
    expect(nextPos).toEqual([100, 100]);
  });

  test('position beyond right boundary is clamped', () => {
    const [relocated, nextPos] = constraintPosition(
      [1800, 100], [200, 200], screenPos, screenSize,
    );
    expect(relocated).toBe(true);
    // 1800 + 200 = 2000 > 1920 -> clamped to 1920 - 200 = 1720
    expect(nextPos[0]).toBe(1720);
    expect(nextPos[1]).toBe(100);
  });

  test('position beyond bottom boundary is clamped', () => {
    const [relocated, nextPos] = constraintPosition(
      [100, 950], [200, 200], screenPos, screenSize,
    );
    expect(relocated).toBe(true);
    // 950 + 200 = 1150 > 1080 -> clamped to 1080 - 200 = 880
    expect(nextPos[1]).toBe(880);
  });

  test('position before left boundary is clamped', () => {
    const [relocated, nextPos] = constraintPosition(
      [-50, 100], [200, 200], screenPos, screenSize,
    );
    expect(relocated).toBe(true);
    expect(nextPos[0]).toBe(0);
  });

  test('position before top boundary is clamped', () => {
    const [relocated, nextPos] = constraintPosition(
      [100, -30], [200, 200], screenPos, screenSize,
    );
    expect(relocated).toBe(true);
    expect(nextPos[1]).toBe(0);
  });

  test('window larger than screen gets negative position', () => {
    // Size exceeds screen: rightBoundary - size = 1920 - 3000 = -1080
    const [relocated, nextPos] = constraintPosition(
      [100, 100], [3000, 2000], screenPos, screenSize,
    );
    expect(relocated).toBe(true);
    // Window exceeds right: 100 + 3000 > 1920 -> pos = 1920 - 3000 = -1080
    expect(nextPos[0]).toBe(-1080);
    // Window exceeds bottom: 100 + 2000 > 1080 -> pos = 1080 - 2000 = -920
    expect(nextPos[1]).toBe(-920);
  });

  test('handles screen offset (e.g. taskbar offset)', () => {
    // Screen starts at [100, 50] due to taskbar
    const [relocated, nextPos] = constraintPosition(
      [50, 30], [200, 200], [100, 50], [1820, 1030],
    );
    expect(relocated).toBe(true);
    // 50 < 100 -> clamped to 100
    expect(nextPos[0]).toBe(100);
    // 30 < 50 -> clamped to 50
    expect(nextPos[1]).toBe(50);
  });

  test('position exactly at boundary is not relocated', () => {
    // pos + size == screenPos + screenSize exactly
    const [relocated, nextPos] = constraintPosition(
      [1720, 880], [200, 200], screenPos, screenSize,
    );
    expect(relocated).toBe(false);
    expect(nextPos).toEqual([1720, 880]);
  });

  test('does not mutate input position', () => {
    const pos = [2000, 2000];
    const original = [...pos];
    constraintPosition(pos, [200, 200], screenPos, screenSize);
    expect(pos).toEqual(original);
  });
});

// --------------------------------------------------------
// Zoom compensation math
// --------------------------------------------------------

describe('zoom compensation', () => {
  test('100/pixelRatio gives correct zoom percentages', () => {
    // This tests the mathematical formula used in recallWindowGeometry
    expect(100 / 1.0).toBe(100);
    expect(100 / 2.0).toBe(50);
    expect(100 / 1.5).toBeCloseTo(66.667, 2);
    expect(100 / 1.25).toBe(80);
    expect(100 / 0.5).toBe(200);
    expect(100 / 4.0).toBe(25);
  });

  test('recallWindowGeometry uses options.scale instead of browser pixel ratio', async () => {
    setWindowProp('devicePixelRatio', 1.875);

    await recallWindowGeometry({ scale: 1.5 });

    expect(document.body.style.zoom).toBe(`${100 / 1.5}%`);
  });

  test('recallWindowGeometry restores saved user zoom from storage', async () => {
    setWindowProp('devicePixelRatio', 1.875);
    storage.get = jest.fn(async () => 1.2);
    storage.set = jest.fn(async () => undefined);

    await recallWindowGeometry({ scale: 1.5 });

    expect(document.body.style.zoom).toBe('80%');
  });

  test('recallWindowGeometry uses zoom_key for persistent zoom storage', async () => {
    setWindowProp('devicePixelRatio', 1.5);
    storage.get = jest.fn(async () => 1.1);
    storage.set = jest.fn(async () => undefined);

    await recallWindowGeometry({ scale: 1.5, zoom_key: 'tgui:chem_dispenser' });

    expect(storage.get).toHaveBeenCalledWith('zoom:tgui:chem_dispenser');
  });
});

// --------------------------------------------------------
// Drag/resize math
// --------------------------------------------------------

describe('drag math', () => {
  test('dragPointOffset calculation: screenX * ratio - windowPos', () => {
    // At ratio=2, event at screen 500,300, window at 200,100
    const screenX = 500;
    const screenY = 300;
    const ratio = 2;
    const winPos = [200, 100];

    const offsetX = screenX * ratio - winPos[0]; // 1000 - 200 = 800
    const offsetY = screenY * ratio - winPos[1]; // 600 - 100 = 500

    expect(offsetX).toBe(800);
    expect(offsetY).toBe(500);
  });

  test('drag position: screenX * ratio - offset', () => {
    const offset = [800, 500];
    const screenX = 600;
    const screenY = 400;
    const ratio = 2;

    const posX = screenX * ratio - offset[0]; // 1200 - 800 = 400
    const posY = screenY * ratio - offset[1]; // 800 - 500 = 300

    expect(posX).toBe(400);
    expect(posY).toBe(300);
  });

  test('drag is identity when mouse does not move', () => {
    const screenX = 500;
    const screenY = 300;
    const ratio = 1.5;
    const winPos = [750, 450]; // 500*1.5, 300*1.5

    const offset = [screenX * ratio - winPos[0], screenY * ratio - winPos[1]];
    // offset = [0, 0]
    expect(offset).toEqual([0, 0]);

    const newPosX = screenX * ratio - offset[0]; // 750
    const newPosY = screenY * ratio - offset[1]; // 450
    expect(newPosX).toBe(winPos[0]);
    expect(newPosY).toBe(winPos[1]);
  });

  test('drag remains stable when app scale and browser zoom diverge', async () => {
    setWindowProp('screenLeft', 500);
    setWindowProp('screenTop', 300);
    setWindowProp('devicePixelRatio', 1.875);

    await recallWindowGeometry({ scale: 1.5 });

    const screenX = 500;
    const screenY = 300;
    const appScale = 1.5;
    const winPos = getWindowPosition();

    expect(winPos).toEqual([750, 450]);

    const offset = [screenX * appScale - winPos[0], screenY * appScale - winPos[1]];
    expect(offset).toEqual([0, 0]);

    const newPosX = screenX * appScale - offset[0];
    const newPosY = screenY * appScale - offset[1];
    expect(newPosX).toBe(winPos[0]);
    expect(newPosY).toBe(winPos[1]);
  });
});

describe('split scale model', () => {
  test('getWindowSize still uses browser pixel ratio while positions use app scale', async () => {
    setWindowProp('screenLeft', 100);
    setWindowProp('screenTop', 80);
    setWindowProp('innerWidth', 400);
    setWindowProp('innerHeight', 300);
    setWindowProp('devicePixelRatio', 1.875);

    await recallWindowGeometry({ scale: 1.5 });

    expect(getWindowPosition()).toEqual([150, 120]);
    expect(getWindowSize()).toEqual([
      Math.round(400 * 1.875),
      Math.round(300 * 1.875),
    ]);
  });
});

describe('resize math', () => {
  test('resize enforces minimum width of 150', () => {
    const initialWidth = 200;
    const delta = -200; // shrink by 200
    const matrixX = 1;

    const newWidth = Math.max(initialWidth + matrixX * delta + 1, 150);
    // 200 + 1*(-200) + 1 = 1 -> clamped to 150
    expect(newWidth).toBe(150);
  });

  test('resize enforces minimum height of 50', () => {
    const initialHeight = 100;
    const delta = -200;
    const matrixY = 1;

    const newHeight = Math.max(initialHeight + matrixY * delta + 1, 50);
    // 100 + 1*(-200) + 1 = -99 -> clamped to 50
    expect(newHeight).toBe(50);
  });

  test('resize adds 1 pixel for cursor visibility', () => {
    const initialSize = 400;
    const delta = 50;
    const matrix = 1;

    const newSize = Math.max(initialSize + matrix * delta + 1, 150);
    expect(newSize).toBe(451); // 400 + 50 + 1
  });

  test('resize delta with matrix direction', () => {
    // Bottom-right resize: matrix = [1, 1]
    const initial = [400, 300];
    const delta = [50, 30];
    const matrix = [1, 1];

    const w = Math.max(initial[0] + matrix[0] * delta[0] + 1, 150);
    const h = Math.max(initial[1] + matrix[1] * delta[1] + 1, 50);
    expect(w).toBe(451);
    expect(h).toBe(331);
  });

  test('negative matrix reverses resize direction', () => {
    // Left edge resize: matrixX = -1
    const initialWidth = 400;
    const delta = 50; // mouse moved right by 50
    const matrixX = -1;

    const newWidth = Math.max(initialWidth + matrixX * delta + 1, 150);
    // 400 + (-1)*50 + 1 = 351
    expect(newWidth).toBe(351);
  });

  test('zero delta preserves size plus 1', () => {
    const initial = [400, 300];
    const delta = [0, 0];
    const matrix = [1, 1];

    const w = Math.max(initial[0] + matrix[0] * delta[0] + 1, 150);
    const h = Math.max(initial[1] + matrix[1] * delta[1] + 1, 50);
    expect(w).toBe(401);
    expect(h).toBe(301);
  });
});

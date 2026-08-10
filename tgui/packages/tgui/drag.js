/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { storage } from 'common/storage';
import { vecAdd, vecScale } from 'common/vector';

import { constraintPosition, isWindowSizeApplied as isWindowSizeAppliedUtil, touchRecents } from './drag.utils';
import { createLogger } from './logging';

const logger = createLogger('drag');
const now = () => Date.now ? Date.now() : +new Date();

let windowKey = window.__windowId__;
let dragging = false;
let resizing = false;
let screenOffset = [0, 0];
let screenOffsetPromise;
let dragPointOffset;
let resizeMatrix;
let initialSize;
let size;
let appScale = 1;
let cachedAppScale = 1;
let zoomKey = window.__windowId__;
let userZoom = 1;
let zoomControlsInstalled = false;
let zoomIndicator;
let zoomIndicatorHideTimer;

export const isDragOrResizeActive = () => dragging || resizing;

let initialGeometryReady = false;
let resolveInitialGeometryReady;
let initialGeometryReadyPromise;

export const resetInitialGeometryReady = () => {
  initialGeometryReady = false;
  initialGeometryReadyPromise = new Promise(resolve => {
    resolveInitialGeometryReady = resolve;
  });
};

const markInitialGeometryReady = () => {
  if (initialGeometryReady) {
    return;
  }
  initialGeometryReady = true;
  resolveInitialGeometryReady();
};

export const setWindowKey = key => {
  windowKey = key;
};

export const waitForInitialGeometryReady = () => initialGeometryReadyPromise;
resetInitialGeometryReady();

const getBrowserPixelRatio = () => window.devicePixelRatio ?? 1;
const MIN_USER_ZOOM = 0.5;
const MAX_USER_ZOOM = 2.0;
const USER_ZOOM_STEP = 0.1;

const resolveAppScale = scale => {
  const parsedScale = Number(scale);
  if (Number.isFinite(parsedScale) && parsedScale > 0) {
    return parsedScale;
  }

  const browserPixelRatio = getBrowserPixelRatio();
  if (Number.isFinite(browserPixelRatio) && browserPixelRatio > 0) {
    return browserPixelRatio;
  }

  return 1;
};

const clampUserZoom = zoom => (
  Math.min(MAX_USER_ZOOM, Math.max(MIN_USER_ZOOM, zoom))
);

const getZoomStorageKey = () => `zoom:${zoomKey}`;

const ensureZoomIndicator = () => {
  if (zoomIndicator || !document.body) {
    return;
  }

  zoomIndicator = document.createElement('div');
  zoomIndicator.id = 'tguiZoomIndicator';
  zoomIndicator.style.cssText = 'position:fixed;top:12px;right:12px;z-index:2147483647;padding:6px 10px;border-radius:6px;background:rgba(0,0,0,0.75);color:#fff;font:12px/1.2 Verdana,sans-serif;pointer-events:none;opacity:0;transition:opacity 120ms linear;';
  document.body.appendChild(zoomIndicator);
};

const showZoomIndicator = () => {
  ensureZoomIndicator();
  if (!zoomIndicator) {
    return;
  }

  zoomIndicator.textContent = `Scale: ${Math.round(userZoom * 100)}%`;
  zoomIndicator.style.opacity = '1';
  clearTimeout(zoomIndicatorHideTimer);
  zoomIndicatorHideTimer = setTimeout(() => {
    if (zoomIndicator) {
      zoomIndicator.style.opacity = '0';
    }
  }, 1200);
};

const persistUserZoom = () => {
  storage.set(getZoomStorageKey(), userZoom).catch(() => {});
};

const applyBodyZoom = () => {
  const effectiveZoom = (100 / resolveAppScale(appScale)) * userZoom;
  document.body.style.zoom = `${effectiveZoom}%`;
};

const loadUserZoom = async () => {
  userZoom = 1;
  try {
    const storedZoom = Number(await storage.get(getZoomStorageKey()));
    if (Number.isFinite(storedZoom) && storedZoom > 0) {
      userZoom = clampUserZoom(storedZoom);
    }
  }
  catch {}
};

const adjustUserZoom = delta => {
  userZoom = clampUserZoom(Math.round((userZoom + delta) * 100) / 100);
  applyBodyZoom();
  persistUserZoom();
  showZoomIndicator();
};

const handleZoomWheel = event => {
  if (!event.ctrlKey) {
    return;
  }

  const direction = Math.sign(event.deltaY);
  if (!direction) {
    return;
  }

  event.preventDefault();
  adjustUserZoom(direction < 0 ? USER_ZOOM_STEP : -USER_ZOOM_STEP);
};

const installZoomControls = () => {
  if (zoomControlsInstalled) {
    return;
  }

  window.addEventListener('wheel', handleZoomWheel, { passive: false });
  zoomControlsInstalled = true;
};

export const getWindowPosition = () => {
  const scale = resolveAppScale(appScale);
  return [
    Math.round(window.screenLeft * scale),
    Math.round(window.screenTop * scale),
  ];
};

export const getWindowSize = () => {
  const pr = getBrowserPixelRatio();
  return [
    Math.round(window.innerWidth * pr),
    Math.round(window.innerHeight * pr),
  ];
};

// 516 migration: BYOND IPC (winget + winset→resize) can exceed 250ms under load.
// Increase to 1500ms to prevent premature reveal at wrong window size.
const SIZE_APPLY_TIMEOUT_MS = 1500;

const isWindowSizeApplied = targetSize => {
  const pr = getBrowserPixelRatio();
  return isWindowSizeAppliedUtil(targetSize, getWindowSize(), pr);
};

const waitForWindowSizeApplied = targetSize => {
  const startedAt = now();
  const startSize = getWindowSize();
  if (isWindowSizeApplied(targetSize)) {
    return Promise.resolve({
      matched: true,
      reason: 'alreadyApplied',
      elapsedMs: now() - startedAt,
      targetSize,
      startSize,
      endSize: startSize,
      resizeEvents: 0,
    });
  }
  return new Promise(resolve => {
    let done = false;
    let resizeEvents = 0;
    let timeoutId = null;
    let rafId = null;
    let onResize;
    const finish = (reason, matched) => {
      if (done) {
        return;
      }
      done = true;
      if (timeoutId) {
        clearTimeout(timeoutId);
      }
      if (rafId) {
        cancelAnimationFrame(rafId);
      }
      window.removeEventListener('resize', onResize);
      resolve({
        matched,
        reason,
        elapsedMs: now() - startedAt,
        targetSize,
        startSize,
        endSize: getWindowSize(),
        resizeEvents,
      });
    };
    const maybeFinish = reason => {
      if (isWindowSizeApplied(targetSize)) {
        finish(reason, true);
      }
    };
    onResize = () => {
      resizeEvents += 1;
      maybeFinish('resize');
    };
    const onFrame = () => {
      if (done) {
        return;
      }
      maybeFinish('animationFrame');
      if (!done) {
        rafId = requestAnimationFrame(onFrame);
      }
    };
    window.addEventListener('resize', onResize);
    maybeFinish('immediateCheck');
    if (done) {
      return;
    }
    rafId = requestAnimationFrame(onFrame);
    timeoutId = setTimeout(() => {
      finish('timeout', false);
    }, SIZE_APPLY_TIMEOUT_MS);
  });
};

export const setWindowPosition = vec => {
  // All internal coordinates are physical (BYOND) pixels.
  const physPos = vecAdd(vec, screenOffset);
  return Byond.winset(window.__windowId__, {
    pos: Math.round(physPos[0]) + ',' + Math.round(physPos[1]),
  });
};

export const setWindowSize = vec => {
  return Byond.winset(window.__windowId__, {
    size: Math.round(vec[0]) + 'x' + Math.round(vec[1]),
  });
};

// rAF-based batching: accumulate winset calls and flush once per animation frame.
// Prevents CPU spikes when dragging/resizing at high mouse polling rates (125-1000 Hz).
// Ported from tgstation drag.ts.
let winsetRaf;
let pendingWinset = {};
let lastSentWinset = {};

const flushWinset = () => {
  winsetRaf = undefined;
  const payload = {};
  if (pendingWinset.pos && pendingWinset.pos !== lastSentWinset.pos) {
    payload.pos = pendingWinset.pos;
  }
  if (pendingWinset.size && pendingWinset.size !== lastSentWinset.size) {
    payload.size = pendingWinset.size;
  }
  pendingWinset = {};
  if (payload.pos || payload.size) {
    Byond.winset(window.__windowId__, payload);
    lastSentWinset = { ...lastSentWinset, ...payload };
  }
};

const scheduleWinset = () => {
  if (winsetRaf !== undefined) {
    return;
  }
  winsetRaf = requestAnimationFrame(flushWinset);
};

const flushWinsetNow = () => {
  if (winsetRaf !== undefined) {
    cancelAnimationFrame(winsetRaf);
    winsetRaf = undefined;
  }
  flushWinset();
};

const setWindowPositionFast = (x, y) => {
  pendingWinset.pos = Math.round(x + screenOffset[0]) + ',' + Math.round(y + screenOffset[1]);
  scheduleWinset();
};

const setWindowSizeFast = (w, h) => {
  pendingWinset.size = Math.round(w) + 'x' + Math.round(h);
  scheduleWinset();
};

export const getScreenPosition = () => [
  0 - screenOffset[0],
  0 - screenOffset[1],
];

export const getScreenSize = () => {
  const scale = resolveAppScale(appScale);
  return [
    Math.round(window.screen.availWidth * scale),
    Math.round(window.screen.availHeight * scale),
  ];
};

// touchRecents is imported from drag.utils.js

export const storeWindowGeometry = async () => {
  logger.log('storing geometry');
  const geometry = {
    pos: getWindowPosition(),
    size: getWindowSize(),
  };
  storage.set(windowKey, geometry);
  // Update the list of stored geometries
  const [geometries, trimmedKey] = touchRecents(
    await storage.get('geometries') || [],
    windowKey);
  if (trimmedKey) {
    storage.remove(trimmedKey);
  }
  storage.set('geometries', geometries);
};

export const recallWindowGeometry = async (options = {}) => {
  let geometry;
  let geometryReadyForReveal = false;
  try {
    appScale = resolveAppScale(options.scale);
    zoomKey = options.zoom_key || options.key || windowKey;
    await loadUserZoom();
    // Use legacy zoom mode: scale content down to compensate for DPI.
    // This preserves physical window size at any DPI, matching browser.dm behavior.
    applyBodyZoom();
    // Only recall geometry in fancy mode
    if (options.fancy) {
      try {
        geometry = await storage.get(windowKey);
      }
      catch {}
    }
    if (geometry) {
      logger.log('recalled geometry:', geometry);
    }
    let pos = geometry?.pos || options.pos;
    let size = options.size;
    // Wait until screen offset gets resolved
    await screenOffsetPromise;
    // All coordinates are physical (BYOND) pixels.
    const areaAvailable = [
      Math.round(window.screen.availWidth * appScale),
      Math.round(window.screen.availHeight * appScale),
    ];
    // Set window size
    if (size) {
      // Constraint size to not exceed available screen area.
      size = [
        Math.min(areaAvailable[0], size[0]),
        Math.min(areaAvailable[1], size[1]),
      ];
      setWindowSize(size);
      const sizeApplyResult = await waitForWindowSizeApplied(size);
      geometryReadyForReveal = sizeApplyResult.matched;
      if (!sizeApplyResult.matched) {
        logger.warn('window size was not applied before reveal gate timeout', sizeApplyResult);
      }
    }
    else {
      geometryReadyForReveal = true;
    }
    // Set window position
    if (pos) {
      // Constraint window position if monitor lock was set in preferences.
      if (size && options.locked) {
        pos = constraintPositionOnScreen(pos, size)[1];
      }
      setWindowPosition(pos);
    }
    // Set window position at the center of the screen.
    else if (size) {
      pos = vecAdd(
        vecScale(areaAvailable, 0.5),
        vecScale(size, -0.5),
        vecScale(screenOffset, -1.0));
      setWindowPosition(pos);
    }
  }
  finally {
    if (geometryReadyForReveal) {
      markInitialGeometryReady();
    }
  }
};

export const setupDrag = async (scale) => {
  appScale = resolveAppScale(scale);
  installZoomControls();
  // Calculate screen offset caused by the windows taskbar.
  // Both Byond.winget and getWindowPosition return physical pixels.
  const windowPosition = getWindowPosition();
  screenOffsetPromise = Byond.winget(window.__windowId__, 'pos')
    .then(pos => [
      pos.x - windowPosition[0],
      pos.y - windowPosition[1],
    ]);
  screenOffset = await screenOffsetPromise;
  logger.debug('screen offset', screenOffset);
};

/**
 * Constraints window position to safe screen area, accounting for safe
 * margins which could be a system taskbar.
 */
const constraintPositionOnScreen = (pos, size) => {
  return constraintPosition(pos, size, getScreenPosition(), getScreenSize());
};

export const dragStartHandler = event => {
  logger.log('drag start');
  dragging = true;
  cachedAppScale = resolveAppScale(appScale);
  const winPos = getWindowPosition();
  dragPointOffset = [
    event.screenX * cachedAppScale - winPos[0],
    event.screenY * cachedAppScale - winPos[1],
  ];
  // Focus click target
  event.target?.focus();
  document.body.style['pointer-events'] = 'none';
  document.addEventListener('mousemove', dragMoveHandler);
  document.addEventListener('mouseup', dragEndHandler);
  dragMoveHandler(event);
};

const dragEndHandler = event => {
  logger.log('drag end');
  applyDragPosition(event.screenX, event.screenY);
  flushWinsetNow();
  document.removeEventListener('mousemove', dragMoveHandler);
  document.removeEventListener('mouseup', dragEndHandler);
  document.body.style['pointer-events'] = 'auto';
  dragging = false;
  storeWindowGeometry();
};

const applyDragPosition = (screenX, screenY) => {
  setWindowPositionFast(
    screenX * cachedAppScale - dragPointOffset[0],
    screenY * cachedAppScale - dragPointOffset[1]);
};

const dragMoveHandler = event => {
  if (!dragging) {
    return;
  }
  event.preventDefault();
  applyDragPosition(event.screenX, event.screenY);
};

export const resizeStartHandler = (x, y) => event => {
  resizeMatrix = [x, y];
  logger.log('resize start', resizeMatrix);
  resizing = true;
  cachedAppScale = resolveAppScale(appScale);
  const winPos = getWindowPosition();
  dragPointOffset = [
    event.screenX * cachedAppScale - winPos[0],
    event.screenY * cachedAppScale - winPos[1],
  ];
  initialSize = getWindowSize();
  // Focus click target
  event.target?.focus();
  document.body.style['pointer-events'] = 'none';
  document.addEventListener('mousemove', resizeMoveHandler);
  document.addEventListener('mouseup', resizeEndHandler);
  resizeMoveHandler(event);
};

const resizeEndHandler = event => {
  logger.log('resize end', size);
  applyResizeSize(event.screenX, event.screenY);
  flushWinsetNow();
  document.removeEventListener('mousemove', resizeMoveHandler);
  document.removeEventListener('mouseup', resizeEndHandler);
  document.body.style['pointer-events'] = 'auto';
  resizing = false;
  storeWindowGeometry();
};

const applyResizeSize = (screenX, screenY) => {
  const winPos = getWindowPosition();
  const offsetX = screenX * cachedAppScale - winPos[0];
  const offsetY = screenY * cachedAppScale - winPos[1];
  const deltaX = offsetX - dragPointOffset[0];
  const deltaY = offsetY - dragPointOffset[1];
  // Extra 1x1 area is added to ensure the browser can see the cursor.
  size = [
    Math.max(initialSize[0] + resizeMatrix[0] * deltaX + 1, 150),
    Math.max(initialSize[1] + resizeMatrix[1] * deltaY + 1, 50),
  ];
  setWindowSizeFast(size[0], size[1]);
};

const resizeMoveHandler = event => {
  if (!resizing) {
    return;
  }
  event.preventDefault();
  applyResizeSize(event.screenX, event.screenY);
};

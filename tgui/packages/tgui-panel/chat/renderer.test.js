import {
  COMBINE_MAX_MESSAGES,
  COMBINE_MAX_TIME_WINDOW,
  IMAGE_RETRY_LIMIT,
  IMAGE_RETRY_MESSAGE_AGE,
  MAX_VISIBLE_MESSAGES,
} from './constants';
import { createMainPage, createPage } from './model';
import { ChatRenderer } from './renderer';

// Mock Byond global used by logger
if (typeof window.Byond === 'undefined') {
  window.Byond = { topic: jest.fn() };
}

// Mock scrollIntoView which jsdom does not implement
if (typeof HTMLElement.prototype.scrollIntoView === 'undefined') {
  HTMLElement.prototype.scrollIntoView = jest.fn();
}

const setupScrollMetrics = (node, {
  scrollHeight = 1000,
  clientHeight = 400,
  scrollTop = 0,
} = {}) => {
  const metrics = {
    scrollHeight,
    clientHeight,
    scrollTop,
  };
  Object.defineProperty(node, 'scrollHeight', {
    configurable: true,
    get: () => metrics.scrollHeight,
  });
  Object.defineProperty(node, 'clientHeight', {
    configurable: true,
    get: () => metrics.clientHeight,
  });
  Object.defineProperty(node, 'scrollTop', {
    configurable: true,
    get: () => metrics.scrollTop,
    set: value => {
      metrics.scrollTop = value;
    },
  });
  return metrics;
};

/**
 * Create a ready-to-use renderer with rootNode, scrollNode, loaded, and page.
 */
const createReadyRenderer = () => {
  const renderer = new ChatRenderer();
  const rootNode = document.createElement('div');
  const scrollNode = document.createElement('div');
  setupScrollMetrics(scrollNode, { scrollTop: 600 });

  renderer.rootNode = rootNode;
  renderer.scrollNode = scrollNode;
  renderer.loaded = true;
  renderer.page = createMainPage();
  renderer.scrollTracking = true;

  return renderer;
};

describe('ChatRenderer', () => {
  let originalQueueMicrotask;

  beforeEach(() => {
    originalQueueMicrotask = global.queueMicrotask;
    global.queueMicrotask = jest.fn(callback => callback());
    jest.spyOn(global, 'setInterval').mockImplementation(() => 0);
  });

  afterEach(() => {
    global.queueMicrotask = originalQueueMicrotask;
    jest.restoreAllMocks();
  });

  // ---- Original tests ----

  test('mount uses explicitly provided scroll node', () => {
    const renderer = new ChatRenderer();
    const rootNode = document.createElement('div');
    const scrollNode = document.createElement('div');
    setupScrollMetrics(scrollNode);

    renderer.mount(rootNode, scrollNode);

    expect(renderer.scrollNode).toBe(scrollNode);
  });

  test('treats near-bottom offset as tracked', () => {
    const renderer = new ChatRenderer();
    const scrollNode = document.createElement('div');
    const metrics = setupScrollMetrics(scrollNode, {
      scrollTop: 560,
    });

    renderer.scrollNode = scrollNode;
    renderer.scrollTracking = false;

    renderer.handleScroll();
    expect(renderer.scrollTracking).toBe(true);

    metrics.scrollTop = 500;
    renderer.handleScroll();
    expect(renderer.scrollTracking).toBe(false);
  });

  test('auto-scrolls only when tracking is enabled', () => {
    const renderer = new ChatRenderer();
    const scrollNode = document.createElement('div');
    const metrics = setupScrollMetrics(scrollNode, {
      scrollHeight: 1000,
      scrollTop: 600,
    });

    renderer.rootNode = document.createElement('div');
    renderer.scrollNode = scrollNode;
    renderer.loaded = true;
    renderer.page = createMainPage();
    renderer.scrollTracking = true;

    renderer.processBatch([{
      text: 'first message',
    }]);
    expect(metrics.scrollTop).toBe(1000);

    metrics.scrollTop = 300;
    renderer.scrollTracking = false;
    renderer.processBatch([{
      text: 'second message',
    }]);
    expect(metrics.scrollTop).toBe(300);
  });

  // ---- Message combining ----

  describe('message combining', () => {
    test('combines identical text messages within time window', () => {
      const renderer = createReadyRenderer();
      const now = 1000000;
      jest.spyOn(Date, 'now').mockReturnValue(now);

      renderer.processBatch([{ text: 'hello' }]);
      renderer.processBatch([{ text: 'hello' }]);

      // Should be combined into one message with times=2
      expect(renderer.visibleMessages.length).toBe(1);
      expect(renderer.visibleMessages[0].times).toBe(2);
    });

    test('combines identical html messages', () => {
      const renderer = createReadyRenderer();
      const now = 1000000;
      jest.spyOn(Date, 'now').mockReturnValue(now);

      renderer.processBatch([{ html: '<b>test</b>' }]);
      renderer.processBatch([{ html: '<b>test</b>' }]);

      expect(renderer.visibleMessages.length).toBe(1);
      expect(renderer.visibleMessages[0].times).toBe(2);
    });

    test('does not combine different text messages', () => {
      const renderer = createReadyRenderer();
      const now = 1000000;
      jest.spyOn(Date, 'now').mockReturnValue(now);

      renderer.processBatch([{ text: 'hello' }]);
      renderer.processBatch([{ text: 'world' }]);

      expect(renderer.visibleMessages.length).toBe(2);
    });

    test('does not combine messages beyond COMBINE_MAX_MESSAGES window', () => {
      const renderer = createReadyRenderer();
      const now = 1000000;
      jest.spyOn(Date, 'now').mockReturnValue(now);

      // Send the target message first
      renderer.processBatch([{ text: 'target' }]);

      // Fill up COMBINE_MAX_MESSAGES more different messages
      for (let i = 0; i < COMBINE_MAX_MESSAGES; i++) {
        renderer.processBatch([{ text: `filler ${i}` }]);
      }

      // Now try to combine with 'target' — it's outside the window
      renderer.processBatch([{ text: 'target' }]);

      // Should NOT combine — creates a new message
      const targetMessages = renderer.visibleMessages.filter(
        m => m.text === 'target',
      );
      expect(targetMessages.length).toBe(2);
    });

    test('does not combine messages outside time window', () => {
      const renderer = createReadyRenderer();
      let currentTime = 1000000;
      jest.spyOn(Date, 'now').mockImplementation(() => currentTime);

      renderer.processBatch([{ text: 'hello' }]);

      // Advance time beyond COMBINE_MAX_TIME_WINDOW
      currentTime += COMBINE_MAX_TIME_WINDOW + 1;

      renderer.processBatch([{ text: 'hello' }]);

      // Should NOT combine — too old
      expect(renderer.visibleMessages.length).toBe(2);
    });

    test('does not combine internal messages', () => {
      const renderer = createReadyRenderer();
      const now = 1000000;
      jest.spyOn(Date, 'now').mockReturnValue(now);

      renderer.processBatch([{
        type: 'internal/reconnected',
      }]);
      renderer.processBatch([{
        type: 'internal/reconnected',
      }]);

      // Internal messages are never combined
      expect(renderer.messages.length).toBe(2);
    });

    test('badge element is added when messages are combined', () => {
      const renderer = createReadyRenderer();
      const now = 1000000;
      jest.spyOn(Date, 'now').mockReturnValue(now);

      renderer.processBatch([{ text: 'hello' }]);
      renderer.processBatch([{ text: 'hello' }]);

      const badge = renderer.visibleMessages[0].node.querySelector(
        '.Chat__badge',
      );
      expect(badge).not.toBeNull();
      expect(badge.textContent).toBe('2');
    });

    test('times counter increments correctly', () => {
      const renderer = createReadyRenderer();
      const now = 1000000;
      jest.spyOn(Date, 'now').mockReturnValue(now);

      renderer.processBatch([{ text: 'spam' }]);
      renderer.processBatch([{ text: 'spam' }]);
      renderer.processBatch([{ text: 'spam' }]);
      renderer.processBatch([{ text: 'spam' }]);

      expect(renderer.visibleMessages[0].times).toBe(4);
    });
  });

  // ---- Message type detection ----

  describe('message type detection', () => {
    test('detects localchat from .say CSS class', () => {
      const renderer = createReadyRenderer();

      renderer.processBatch([{
        html: '<span class="say">Hello everyone</span>',
      }]);

      expect(renderer.messages[0].type).toBe('localchat');
    });

    test('detects radio from .radio CSS class', () => {
      const renderer = createReadyRenderer();

      renderer.processBatch([{
        html: '<span class="radio">Engineering reporting</span>',
      }]);

      expect(renderer.messages[0].type).toBe('radio');
    });

    test('detects radio from .priority_announcement CSS class', () => {
      const renderer = createReadyRenderer();

      renderer.processBatch([{
        html: '<span class="priority_announcement">Central command notice</span>',
      }]);

      expect(renderer.messages[0].type).toBe('radio');
    });

    test('detects radio from .system_notice CSS class', () => {
      const renderer = createReadyRenderer();

      renderer.processBatch([{
        html: '<span class="system_notice">Security level changed</span>',
      }]);

      expect(renderer.messages[0].type).toBe('radio');
    });

    test('detects system from .boldannounce CSS class', () => {
      const renderer = createReadyRenderer();

      renderer.processBatch([{
        html: '<span class="boldannounce">Server restarting</span>',
      }]);

      expect(renderer.messages[0].type).toBe('system');
    });

    test('detects combat from .danger CSS class', () => {
      const renderer = createReadyRenderer();

      renderer.processBatch([{
        html: '<span class="danger">You were hit!</span>',
      }]);

      expect(renderer.messages[0].type).toBe('combat');
    });

    test('detects deadchat from .deadsay CSS class', () => {
      const renderer = createReadyRenderer();

      renderer.processBatch([{
        html: '<span class="deadsay">Ghost says something</span>',
      }]);

      expect(renderer.messages[0].type).toBe('deadchat');
    });

    test('detects OOC from .ooc CSS class', () => {
      const renderer = createReadyRenderer();

      renderer.processBatch([{
        html: '<span class="ooc">OOC message</span>',
      }]);

      expect(renderer.messages[0].type).toBe('ooc');
    });

    test('falls back to unknown for unrecognized HTML', () => {
      const renderer = createReadyRenderer();

      renderer.processBatch([{
        html: '<span class="nonexistent-class">text</span>',
      }]);

      expect(renderer.messages[0].type).toBe('unknown');
    });

    test('uses explicit type when provided', () => {
      const renderer = createReadyRenderer();

      renderer.processBatch([{
        html: '<span class="say">Hi</span>',
        type: 'ooc',
      }]);

      // Explicit type should NOT be overridden by CSS detection
      expect(renderer.messages[0].type).toBe('ooc');
    });

    test('plain text messages get unknown type', () => {
      const renderer = createReadyRenderer();

      renderer.processBatch([{ text: 'plain text message' }]);

      expect(renderer.messages[0].type).toBe('unknown');
    });
  });

  // ---- Message pruning ----

  describe('message pruning', () => {
    test('does not prune when not ready', () => {
      const renderer = new ChatRenderer();
      renderer.loaded = false;
      renderer.messages = new Array(3000).fill(null).map(() => ({
        text: 'msg',
        node: document.createElement('div'),
      }));

      renderer.pruneMessages();

      expect(renderer.messages.length).toBe(3000);
    });

    test('does not prune when scroll tracking is off', () => {
      const renderer = createReadyRenderer();
      renderer.scrollTracking = false;

      // Add many messages
      const messages = [];
      for (let i = 0; i < MAX_VISIBLE_MESSAGES + 100; i++) {
        const node = document.createElement('div');
        renderer.rootNode.appendChild(node);
        messages.push({ text: `msg ${i}`, node });
      }
      renderer.messages = messages;
      renderer.visibleMessages = [...messages];

      renderer.pruneMessages();

      // Should not have pruned — user is reading history
      expect(renderer.visibleMessages.length).toBe(
        MAX_VISIBLE_MESSAGES + 100,
      );
    });

    test('prunes visible messages above MAX_VISIBLE_MESSAGES', () => {
      const renderer = createReadyRenderer();
      renderer.scrollTracking = true;

      const excess = 10;
      const total = MAX_VISIBLE_MESSAGES + excess;
      const messages = [];
      for (let i = 0; i < total; i++) {
        const node = document.createElement('div');
        renderer.rootNode.appendChild(node);
        messages.push({ text: `msg ${i}`, node });
      }
      renderer.messages = [...messages];
      renderer.visibleMessages = [...messages];

      renderer.pruneMessages();

      expect(renderer.visibleMessages.length).toBe(MAX_VISIBLE_MESSAGES);
    });

    test('marks pruned message nodes as "pruned" string', () => {
      const renderer = createReadyRenderer();
      renderer.scrollTracking = true;

      const total = MAX_VISIBLE_MESSAGES + 5;
      const messages = [];
      for (let i = 0; i < total; i++) {
        const node = document.createElement('div');
        renderer.rootNode.appendChild(node);
        messages.push({ text: `msg ${i}`, node });
      }
      renderer.messages = [...messages];
      renderer.visibleMessages = [...messages];

      renderer.pruneMessages();

      // The first 5 messages should have node = 'pruned'
      expect(messages[0].node).toBe('pruned');
      expect(messages[4].node).toBe('pruned');
      // And they should be removed from messages array
      expect(
        renderer.messages.some((m) => m.node === 'pruned'),
      ).toBe(false);
    });
  });

  // ---- setHighlight ----

  describe('setHighlight', () => {
    test('builds regex from comma-separated patterns', () => {
      const renderer = createReadyRenderer();
      renderer.setHighlight('hello, world', '#ff0');

      expect(renderer.highlightRegex).not.toBeNull();
      expect(renderer.highlightRegex.test('hello')).toBe(true);
      // Reset lastIndex — global flag regex persists state between test() calls
      renderer.highlightRegex.lastIndex = 0;
      expect(renderer.highlightRegex.test('world')).toBe(true);
    });

    test('filters patterns shorter than 2 characters', () => {
      const renderer = createReadyRenderer();
      renderer.setHighlight('a, hi, b', '#ff0');

      expect(renderer.highlightRegex).not.toBeNull();
      expect(renderer.highlightRegex.test('hi')).toBe(true);
      // Single char patterns should be filtered out
      // Reset lastIndex between tests
      renderer.highlightRegex.lastIndex = 0;
      expect(renderer.highlightRegex.test('a')).toBe(false);
    });

    test('escapes regex special characters', () => {
      const renderer = createReadyRenderer();
      renderer.setHighlight('hello.world', '#ff0');

      // The dot should be escaped — should not match 'helloXworld'
      expect(renderer.highlightRegex.test('hello.world')).toBe(true);
      renderer.highlightRegex.lastIndex = 0;
      expect(renderer.highlightRegex.test('helloXworld')).toBe(false);
    });

    test('supports word boundary matching', () => {
      const renderer = createReadyRenderer();
      renderer.setHighlight('test', '#ff0', true, false);

      expect(renderer.highlightRegex.test('test')).toBe(true);
      renderer.highlightRegex.lastIndex = 0;
      expect(renderer.highlightRegex.test('testing')).toBe(false);
    });

    test('default is case insensitive', () => {
      const renderer = createReadyRenderer();
      renderer.setHighlight('Test', '#ff0', false, false);

      expect(renderer.highlightRegex.test('test')).toBe(true);
      renderer.highlightRegex.lastIndex = 0;
      expect(renderer.highlightRegex.test('TEST')).toBe(true);
    });

    test('supports case sensitivity', () => {
      const renderer = createReadyRenderer();
      renderer.setHighlight('Test', '#ff0', false, true);

      expect(renderer.highlightRegex.test('Test')).toBe(true);
      renderer.highlightRegex.lastIndex = 0;
      expect(renderer.highlightRegex.test('test')).toBe(false);
    });

    test('resets highlight when text is empty', () => {
      const renderer = createReadyRenderer();
      renderer.setHighlight('hello', '#ff0');
      expect(renderer.highlightRegex).not.toBeNull();

      renderer.setHighlight('', '#ff0');
      expect(renderer.highlightRegex).toBeNull();
    });

    test('resets highlight when color is empty', () => {
      const renderer = createReadyRenderer();
      renderer.setHighlight('hello', '#ff0');
      expect(renderer.highlightRegex).not.toBeNull();

      renderer.setHighlight('hello', '');
      expect(renderer.highlightRegex).toBeNull();
    });

    test('resets when all patterns are too short', () => {
      const renderer = createReadyRenderer();
      renderer.setHighlight('a, b, c', '#ff0');
      expect(renderer.highlightRegex).toBeNull();
    });

    test('highlight is applied to processed messages', () => {
      const renderer = createReadyRenderer();
      renderer.setHighlight('important', '#ff0000');

      renderer.processBatch([{
        html: '<span class="say">This is important news</span>',
      }]);

      const highlighted = renderer.visibleMessages[0].node.querySelector(
        '.Chat__highlight',
      );
      expect(highlighted).not.toBeNull();
      expect(highlighted.textContent).toBe('important');
    });

    test('highlighted messages get ChatMessage--highlighted class', () => {
      const renderer = createReadyRenderer();
      renderer.setHighlight('match', '#ff0000');

      renderer.processBatch([{
        html: '<span class="say">match this</span>',
      }]);

      expect(
        renderer.visibleMessages[0].node.className,
      ).toContain('ChatMessage--highlighted');
    });
  });

  // ---- Image retry ----

  describe('image retry', () => {
    test('appends hash to src on error', () => {
      const renderer = createReadyRenderer();
      const now = Date.now();
      jest.spyOn(Date, 'now').mockReturnValue(now);

      renderer.processBatch([{
        html: '<img src="test.png">',
        createdAt: now,
      }]);

      const img = renderer.visibleMessages[0].node.querySelector('img');
      expect(img).not.toBeNull();

      // Spy on setTimeout to capture the retry callback
      const timeoutSpy = jest.spyOn(global, 'setTimeout');

      // Trigger error
      const errorEvent = new Event('error');
      Object.defineProperty(errorEvent, 'target', { value: img });
      img.dispatchEvent(errorEvent);

      // Execute the scheduled callback
      expect(timeoutSpy).toHaveBeenCalled();
      const callback = timeoutSpy.mock.calls[
        timeoutSpy.mock.calls.length - 1
      ][0];
      callback();

      // Should have appended #0
      expect(img.src).toContain('#0');
      expect(img.getAttribute('data-reload-n')).toBe('1');
      timeoutSpy.mockRestore();
    });

    test('multiple retries do not accumulate hash fragments', () => {
      const renderer = createReadyRenderer();
      const now = Date.now();
      jest.spyOn(Date, 'now').mockReturnValue(now);

      renderer.processBatch([{
        html: '<img src="test.png">',
        createdAt: now,
      }]);

      const img = renderer.visibleMessages[0].node.querySelector('img');
      const timeoutSpy = jest.spyOn(global, 'setTimeout');

      // Simulate 3 sequential retries
      for (let i = 0; i < 3; i++) {
        const errorEvent = new Event('error');
        Object.defineProperty(errorEvent, 'target', { value: img });
        img.dispatchEvent(errorEvent);

        const callback = timeoutSpy.mock.calls[
          timeoutSpy.mock.calls.length - 1
        ][0];
        callback();
      }

      // Should be test.png#2, NOT test.png#0#1#2
      expect(img.src).toMatch(/test\.png#2$/);
      expect(img.getAttribute('data-reload-n')).toBe('3');
      timeoutSpy.mockRestore();
    });

    test('stops retrying after IMAGE_RETRY_LIMIT', () => {
      const renderer = createReadyRenderer();
      const now = Date.now();
      jest.spyOn(Date, 'now').mockReturnValue(now);

      renderer.processBatch([{
        html: '<img src="test.png">',
        createdAt: now,
      }]);

      const img = renderer.visibleMessages[0].node.querySelector('img');
      img.setAttribute('data-reload-n', String(IMAGE_RETRY_LIMIT));

      const originalSrc = img.src;

      // Use real setTimeout spy to test the retry logic
      const timeoutSpy = jest.spyOn(global, 'setTimeout');
      const errorEvent = new Event('error');
      Object.defineProperty(errorEvent, 'target', { value: img });
      img.dispatchEvent(errorEvent);

      // The timeout was scheduled; execute it manually
      if (timeoutSpy.mock.calls.length > 0) {
        const callback = timeoutSpy.mock.calls[
          timeoutSpy.mock.calls.length - 1
        ][0];
        callback();
      }

      // Should NOT have changed src — at limit
      expect(img.src).toBe(originalSrc);
      timeoutSpy.mockRestore();
    });

    test('does not attach error handler to old messages', () => {
      const renderer = createReadyRenderer();
      const now = 2000000;
      jest.spyOn(Date, 'now').mockReturnValue(now);

      // Message created long ago
      renderer.processBatch([{
        html: '<img src="old.png">',
        createdAt: now - IMAGE_RETRY_MESSAGE_AGE - 1,
      }]);

      const img = renderer.visibleMessages[0].node.querySelector('img');
      // The error handler should not be attached
      const timeoutSpy = jest.spyOn(global, 'setTimeout');
      const callsBefore = timeoutSpy.mock.calls.length;

      const errorEvent = new Event('error');
      Object.defineProperty(errorEvent, 'target', { value: img });
      img.dispatchEvent(errorEvent);

      // No new setTimeout should be scheduled since handler wasn't attached
      expect(timeoutSpy.mock.calls.length).toBe(callsBefore);
      expect(img.getAttribute('data-reload-n')).toBeNull();
      timeoutSpy.mockRestore();
    });
  });

  // ---- Page filtering ----

  describe('page filtering', () => {
    test('only shows messages accepted by current page', () => {
      const renderer = createReadyRenderer();
      // Set page to only accept 'ooc'
      renderer.page = createPage({
        acceptedTypes: { ooc: true },
      });

      renderer.processBatch([
        { text: 'ooc message', type: 'ooc' },
        { text: 'combat message', type: 'combat' },
      ]);

      // Only ooc should be visible
      expect(renderer.visibleMessages.length).toBe(1);
      expect(renderer.visibleMessages[0].text).toBe('ooc message');

      // But both should be in messages
      expect(renderer.messages.length).toBe(2);
    });

    test('internal messages are always visible', () => {
      const renderer = createReadyRenderer();
      renderer.page = createPage({ acceptedTypes: {} });

      renderer.processBatch([{
        type: 'internal/reconnected',
      }]);

      expect(renderer.visibleMessages.length).toBe(1);
    });
  });

  // ---- Queue behavior ----

  describe('queue behavior', () => {
    test('queues messages when not ready', () => {
      const renderer = new ChatRenderer();
      // Not ready — no rootNode, loaded, or page

      renderer.processBatch([{ text: 'queued' }]);

      expect(renderer.queue.length).toBe(1);
      expect(renderer.messages.length).toBe(0);
    });

    test('prepend option puts messages at front of queue', () => {
      const renderer = new ChatRenderer();

      renderer.processBatch([{ text: 'first' }]);
      renderer.processBatch([{ text: 'prepended' }], { prepend: true });

      expect(renderer.queue[0].text).toBe('prepended');
      expect(renderer.queue[1].text).toBe('first');
    });

    test('flushes queue when becoming ready', () => {
      const renderer = new ChatRenderer();
      renderer.processBatch([{ text: 'queued msg' }]);
      expect(renderer.queue.length).toBe(1);

      // Make ready
      const rootNode = document.createElement('div');
      const scrollNode = document.createElement('div');
      setupScrollMetrics(scrollNode);
      renderer.page = createMainPage();
      renderer.loaded = true;
      renderer.mount(rootNode, scrollNode);

      // Queue should be flushed
      expect(renderer.queue.length).toBe(0);
      expect(renderer.messages.length).toBe(1);
    });
  });

  // ---- changePage ----

  describe('changePage', () => {
    test('re-filters messages for new page', () => {
      const renderer = createReadyRenderer();

      // Add messages of different types
      renderer.processBatch([
        { text: 'ooc msg', type: 'ooc' },
        { text: 'combat msg', type: 'combat' },
        { text: 'radio msg', type: 'radio' },
      ]);

      expect(renderer.visibleMessages.length).toBe(3);

      // Switch to page that only accepts OOC
      const oocPage = createPage({ acceptedTypes: { ooc: true } });
      renderer.changePage(oocPage);

      expect(renderer.visibleMessages.length).toBe(1);
      expect(renderer.visibleMessages[0].text).toBe('ooc msg');
    });

    test('clears root node on page change', () => {
      const renderer = createReadyRenderer();
      renderer.processBatch([{ text: 'hello' }]);

      expect(renderer.rootNode.childNodes.length).toBeGreaterThan(0);

      const emptyPage = createPage({ acceptedTypes: {} });
      renderer.changePage(emptyPage);

      // Root should only have internal/matching messages
      // With empty acceptedTypes, only internal messages show
      expect(renderer.visibleMessages.length).toBe(0);
    });
  });

  // ---- Events ----

  describe('events', () => {
    test('emits batchProcessed with count by type', () => {
      const renderer = createReadyRenderer();
      const listener = jest.fn();
      renderer.events.on('batchProcessed', listener);

      renderer.processBatch([
        { text: 'msg1', type: 'ooc' },
        { text: 'msg2', type: 'ooc' },
        { text: 'msg3', type: 'combat' },
      ]);

      expect(listener).toHaveBeenCalledWith({
        ooc: 2,
        combat: 1,
      });
    });

    test('does not emit batchProcessed when notifyListeners is false', () => {
      const renderer = createReadyRenderer();
      const listener = jest.fn();
      renderer.events.on('batchProcessed', listener);

      renderer.processBatch([{ text: 'silent' }], {
        notifyListeners: false,
      });

      expect(listener).not.toHaveBeenCalled();
    });

    test('emits scrollTrackingChanged on scroll state change', () => {
      const renderer = new ChatRenderer();
      const scrollNode = document.createElement('div');
      const metrics = setupScrollMetrics(scrollNode, {
        scrollTop: 560,
      });
      renderer.scrollNode = scrollNode;
      renderer.scrollTracking = false;

      const listener = jest.fn();
      renderer.events.on('scrollTrackingChanged', listener);

      renderer.handleScroll();
      expect(listener).toHaveBeenCalledWith(true);
    });
  });
});

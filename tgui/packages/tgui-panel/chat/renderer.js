/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { defer } from 'common/defer';
import { EventEmitter } from 'common/events';
import { classes } from 'common/react';
import { createLogger } from 'tgui/logging';

import { COMBINE_MAX_MESSAGES, COMBINE_MAX_TIME_WINDOW, IMAGE_RETRY_DELAY, IMAGE_RETRY_LIMIT, IMAGE_RETRY_MESSAGE_AGE, MAX_PERSISTED_MESSAGES, MAX_VISIBLE_MESSAGES, MESSAGE_PRUNE_INTERVAL, MESSAGE_TYPE_INTERNAL, MESSAGE_TYPE_UNKNOWN, MESSAGE_TYPES } from './constants';
import { canPageAcceptType, createMessage, isSameMessage } from './model';
import { highlightNode, linkifyNode } from './replaceInTextNode';

const logger = createLogger('chatRenderer');

// We consider this as the smallest possible scroll offset
// that is still trackable.
const SCROLL_TRACKING_TOLERANCE = 48;
const SCROLLABLE_OVERFLOWS = new Set(['auto', 'scroll', 'overlay']);

const getScrollableRoot = () => (
  document.scrollingElement
  || document.documentElement
  || document.body
);

const canScrollVertically = node => {
  if (!(node instanceof HTMLElement)) {
    return false;
  }
  const style = window.getComputedStyle(node);
  return SCROLLABLE_OVERFLOWS.has(style.overflowY);
};

const findNearestScrollableParent = startingNode => {
  const body = document.body;
  let node = startingNode;
  while (node) {
    if (canScrollVertically(node)) {
      return node;
    }
    if (node === body) {
      break;
    }
    node = node.parentNode;
  }
  return getScrollableRoot();
};

const getDistanceFromBottom = node => (
  Math.max(0, node.scrollHeight - (node.scrollTop + node.clientHeight))
);

const isScrollTracked = node => (
  getDistanceFromBottom(node) <= SCROLL_TRACKING_TOLERANCE
);

const createHighlightNode = (text, color) => {
  const node = document.createElement('span');
  node.className = 'Chat__highlight';
  node.setAttribute('style', 'background-color:' + color);
  node.textContent = text;
  return node;
};

const formatTimestamp = (createdAt, format) => {
  const d = new Date(createdAt);
  const hh = String(d.getHours()).padStart(2, '0');
  const mm = String(d.getMinutes()).padStart(2, '0');
  if (format === 'hms') {
    const ss = String(d.getSeconds()).padStart(2, '0');
    return hh + ':' + mm + ':' + ss;
  }
  return hh + ':' + mm;
};

const createMessageNode = (animation, timestamp) => {
  const node = document.createElement('div');
  node.className = 'ChatMessage'
    + (animation && animation !== 'none'
      ? ' ChatMessage--anim-' + animation
      : '');
  if (timestamp) {
    const ts = document.createElement('span');
    ts.className = 'ChatMessage__timestamp';
    ts.textContent = timestamp;
    node.appendChild(ts);
  }
  return node;
};

const createReconnectedNode = () => {
  const node = document.createElement('div');
  node.className = 'Chat__reconnected';
  return node;
};

const createTimeDividerNode = (timestamp) => {
  const node = document.createElement('div');
  node.className = 'Chat__timeDivider';
  node.textContent = formatTimestamp(timestamp, 'hm');
  return node;
};

const handleImageError = e => {
  setTimeout(() => {
    /** @type {HTMLImageElement} */
    const node = e.target;
    const attempts = parseInt(node.getAttribute('data-reload-n'), 10) || 0;
    if (attempts >= IMAGE_RETRY_LIMIT) {
      logger.error(`failed to load an image after ${attempts} attempts`);
      return;
    }
    const src = node.src.split('#')[0];
    node.removeAttribute('src');
    node.src = src + '#' + attempts;
    node.setAttribute('data-reload-n', attempts + 1);
  }, IMAGE_RETRY_DELAY);
};

/**
 * Assigns a "times-repeated" badge to the message.
 */
const updateMessageBadge = message => {
  const { node, times } = message;
  if (!node || !times) {
    // Nothing to update
    return;
  }
  const foundBadge = node.querySelector('.Chat__badge');
  const badge = foundBadge || document.createElement('div');
  badge.textContent = times;
  badge.className = classes([
    'Chat__badge',
    'Chat__badge--animate',
  ]);
  requestAnimationFrame(() => {
    badge.className = 'Chat__badge';
  });
  if (!foundBadge) {
    node.appendChild(badge);
  }
};

export class ChatRenderer {
  constructor() {
    /** @type {HTMLElement} */
    this.loaded = false;
    /** @type {HTMLElement} */
    this.rootNode = null;
    this.queue = [];
    this.messages = [];
    this.visibleMessages = [];
    this.page = null;
    this.events = new EventEmitter();
    // Scroll handler
    /** @type {HTMLElement} */
    this.scrollNode = null;
    this.scrollTracking = true;
    this._smoothScrollInProgress = false;
    this._smoothScrollTimer = null;
    this.updateScrollTracking = () => {
      const node = this.scrollNode;
      if (!node) {
        return;
      }
      const scrollTracking = isScrollTracked(node);
      // During a programmatic smooth scroll, don't let intermediate
      // scroll positions set tracking to false (causes button flicker).
      if (this._smoothScrollInProgress) {
        if (scrollTracking) {
          // Reached the bottom — animation finished
          this._smoothScrollInProgress = false;
          clearTimeout(this._smoothScrollTimer);
        }
        return;
      }
      if (scrollTracking !== this.scrollTracking) {
        this.scrollTracking = scrollTracking;
        this.events.emit('scrollTrackingChanged', scrollTracking);
        logger.debug('tracking', this.scrollTracking);
      }
    };
    this.handleScroll = () => {
      this.updateScrollTracking();
    };
    this.handleDeferredContentLoad = e => {
      e?.target?.removeEventListener('load', this.handleDeferredContentLoad);
      if (this.scrollTracking) {
        defer(() => this.scrollToBottom());
      }
    };
    this.ensureScrollTracking = () => {
      if (this.scrollTracking) {
        this.scrollToBottom();
      }
      else {
        this.updateScrollTracking();
      }
    };
    // Chat customization state
    this.currentAnimation = 'none';
    this.smoothScroll = false;
    this._pendingAppearance = null;
    this._currentBgAnim = null;
    // Timestamps & time dividers
    this.enableTimestamps = false;
    this.timestampFormat = 'hm';
    this.enableTimeDividers = false;
    this.timeDividerInterval = 300000;
    this._lastDividerTime = 0;
    // Search state
    this._searchMatches = [];
    this._searchCurrentIndex = -1;
    this._searchRegex = null;
    // Periodic message pruning
    setInterval(() => this.pruneMessages(), MESSAGE_PRUNE_INTERVAL);
  }

  isReady() {
    return this.loaded && this.rootNode && this.page;
  }

  mount(node, scrollNode) {
    // Mount existing root node on top of the new node
    if (this.rootNode) {
      node.appendChild(this.rootNode);
    }
    // Initialize the root node
    else {
      this.rootNode = node;
    }
    if (this.scrollNode) {
      this.scrollNode.removeEventListener('scroll', this.handleScroll);
    }
    // Prefer explicit scroll container and fallback to inferred one.
    this.scrollNode = scrollNode || findNearestScrollableParent(this.rootNode);
    this.scrollNode?.addEventListener('scroll', this.handleScroll);
    this.updateScrollTracking();
    defer(() => {
      this.scrollToBottom();
    });
    // Flush the queue
    this.tryFlushQueue();
  }

  onStateLoaded() {
    this.loaded = true;
    this.tryFlushQueue();
  }

  tryFlushQueue() {
    if (this.isReady() && this.queue.length > 0) {
      this.processBatch(this.queue);
      this.queue = [];
    }
  }

  assignStyle(style = {}) {
    for (let key of Object.keys(style)) {
      this.rootNode.style.setProperty(key, style[key]);
    }
  }

  setHighlight(text, color, matchWord, matchCase) {
    if (!text || !color) {
      this.highlightRegex = null;
      this.highlightColor = null;
      return;
    }
    const lines = String(text)
      .split(',')
      // eslint-disable-next-line no-useless-escape
      .map(str => str.trim().replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&'))
      .filter(str => (
        // Must be longer than one character
        str && str.length > 1
      ));
    // Nothing to match, reset highlighting
    if (lines.length === 0) {
      this.highlightRegex = null;
      this.highlightColor = null;
      return;
    }
    const pattern = `${(matchWord ? '\\b' : '')}(${lines.join('|')})${(matchWord ? '\\b' : '')}`;
    const flags = 'g' + (matchCase ? '' : 'i');
    this.highlightRegex = new RegExp(pattern, flags);
    this.highlightColor = color;
  }

  setTimestamps(enable, format) {
    this.enableTimestamps = enable;
    this.timestampFormat = format || 'hm';
  }

  setTimeDividers(enable, interval) {
    this.enableTimeDividers = enable;
    this.timeDividerInterval = interval || 300000;
  }

  scrollToBottom() {
    if (!this.scrollNode) {
      return;
    }
    if (this.smoothScroll) {
      this._smoothScrollInProgress = true;
      // Safety timeout: clear the flag even if the animation is
      // interrupted (e.g. user scrolls up during animation).
      // Smooth scroll typically takes 300-500ms.
      clearTimeout(this._smoothScrollTimer);
      this._smoothScrollTimer = setTimeout(() => {
        this._smoothScrollInProgress = false;
        this.updateScrollTracking();
      }, 700);
      this.scrollNode.scrollTo({
        top: this.scrollNode.scrollHeight,
        behavior: 'smooth',
      });
    }
    else {
      // scrollHeight is always bigger than scrollTop and is
      // automatically clamped to the valid range.
      this.scrollNode.scrollTop = this.scrollNode.scrollHeight;
      this.updateScrollTracking();
    }
    // We're intentionally scrolling to bottom, so tracking should be true.
    // This ensures new messages arriving mid-animation still trigger
    // auto-scroll (processBatch checks this.scrollTracking).
    if (!this.scrollTracking) {
      this.scrollTracking = true;
      this.events.emit('scrollTrackingChanged', true);
    }
  }

  changePage(page) {
    if (!this.isReady()) {
      this.page = page;
      this.tryFlushQueue();
      return;
    }
    this.page = page;
    // Fast clear of the root node
    this.rootNode.textContent = '';
    this.visibleMessages = [];
    // Re-add message nodes
    const fragment = document.createDocumentFragment();
    let node;
    for (let message of this.messages) {
      if (canPageAcceptType(page, message.type)) {
        node = message.node;
        fragment.appendChild(node);
        this.visibleMessages.push(message);
      }
    }
    if (node) {
      this.rootNode.appendChild(fragment);
      node.scrollIntoView();
    }
    this.updateScrollTracking();
  }

  getCombinableMessage(predicate) {
    const now = Date.now();
    const len = this.visibleMessages.length;
    const from = len - 1;
    const to = Math.max(0, len - COMBINE_MAX_MESSAGES);
    for (let i = from; i >= to; i--) {
      const message = this.visibleMessages[i];
      const matches = (
        // Is not an internal message
        !message.type.startsWith(MESSAGE_TYPE_INTERNAL)
        // Text payload must fully match
        && isSameMessage(message, predicate)
        // Must land within the specified time window
        && now < message.createdAt + COMBINE_MAX_TIME_WINDOW
      );
      if (matches) {
        return message;
      }
    }
    return null;
  }

  processBatch(batch, options = {}) {
    const {
      prepend,
      notifyListeners = true,
    } = options;
    const shouldAutoScroll = this.scrollTracking || (
      this.scrollNode && isScrollTracked(this.scrollNode)
    );
    const now = Date.now();
    // Queue up messages until chat is ready
    if (!this.isReady()) {
      if (prepend) {
        this.queue = [...batch, ...this.queue];
      }
      else {
        this.queue = [...this.queue, ...batch];
      }
      return;
    }
    // Insert messages
    const fragment = document.createDocumentFragment();
    const countByType = {};
    let node;
    for (let payload of batch) {
      const message = createMessage(payload);
      // Combine messages
      const combinable = this.getCombinableMessage(message);
      if (combinable) {
        combinable.times = (combinable.times || 1) + 1;
        updateMessageBadge(combinable);
        continue;
      }
      // Time divider check
      if (this.enableTimeDividers && !prepend) {
        const msgTime = message.createdAt || now;
        if (this._lastDividerTime === 0) {
          this._lastDividerTime = msgTime;
        }
        else if (msgTime - this._lastDividerTime
          >= this.timeDividerInterval) {
          fragment.appendChild(createTimeDividerNode(msgTime));
          this._lastDividerTime = msgTime;
        }
      }
      // Compute timestamp string
      const timestamp = this.enableTimestamps
        ? formatTimestamp(message.createdAt || now, this.timestampFormat)
        : null;
      // Reuse message node
      if (message.node) {
        node = message.node;
      }
      // Reconnected
      else if (message.type === 'internal/reconnected') {
        node = createReconnectedNode();
      }
      // Create message node
      else {
        node = createMessageNode(this.currentAnimation, timestamp);
        // Payload is plain text
        if (message.text) {
          node.appendChild(document.createTextNode(message.text));
        }
        // Payload is HTML
        else if (message.html) {
          // Create a temporary container for HTML content
          const htmlContainer = document.createElement('span');
          htmlContainer.innerHTML = message.html;
          node.appendChild(htmlContainer);
        }
        else {
          logger.error('Error: message is missing text payload', message);
        }
        // Highlight text
        if (!message.avoidHighlighting && this.highlightRegex) {
          const highlighted = highlightNode(node,
            this.highlightRegex,
            text => (
              createHighlightNode(text, this.highlightColor)
            ));
          if (highlighted) {
            node.className += ' ChatMessage--highlighted';
          }
        }
        // Linkify text
        const linkifyNodes = node.querySelectorAll('.linkify');
        for (let i = 0; i < linkifyNodes.length; ++i) {
          linkifyNode(linkifyNodes[i]);
        }
        // Assign an image error handler
        if (now < message.createdAt + IMAGE_RETRY_MESSAGE_AGE) {
          const imgNodes = node.querySelectorAll('img');
          for (let i = 0; i < imgNodes.length; i++) {
            const imgNode = imgNodes[i];
            imgNode.addEventListener('error', handleImageError);
            imgNode.addEventListener('load', this.handleDeferredContentLoad);
          }
        }
      }
      // Store the node in the message
      message.node = node;
      // Query all possible selectors to find out the message type
      if (!message.type) {
        const typeDef = MESSAGE_TYPES
          .find(typeDef => (
            typeDef.selector && node.querySelector(typeDef.selector)
          ));
        message.type = typeDef?.type || MESSAGE_TYPE_UNKNOWN;
      }
      updateMessageBadge(message);
      if (!countByType[message.type]) {
        countByType[message.type] = 0;
      }
      countByType[message.type] += 1;
      // TODO: Detect duplicates
      this.messages.push(message);
      if (canPageAcceptType(this.page, message.type)) {
        fragment.appendChild(node);
        this.visibleMessages.push(message);
      }
    }
    if (node) {
      const firstChild = this.rootNode.childNodes[0];
      if (prepend && firstChild) {
        this.rootNode.insertBefore(fragment, firstChild);
      }
      else {
        this.rootNode.appendChild(fragment);
      }
      if (shouldAutoScroll) {
        defer(() => this.scrollToBottom());
      }
      else {
        this.updateScrollTracking();
      }
    }
    // Notify listeners that we have processed the batch
    if (notifyListeners) {
      this.events.emit('batchProcessed', countByType);
    }
  }

  setChatClasses(chatStyle, chatAnimation, hoverEffect, smoothScroll) {
    this.currentAnimation = chatAnimation || 'none';
    this.smoothScroll = smoothScroll || false;
    this._pendingAppearance = {
      ...this._pendingAppearance,
      chatStyle,
      chatAnimation,
      hoverEffect,
      smoothScroll,
    };
    if (!this.rootNode) {
      return;
    }
    const root = this.rootNode;
    // Remove existing customization classes
    const toRemove = [];
    for (const cls of root.classList) {
      if (cls.startsWith('Chat--style-')
        || cls === 'Chat--hover') {
        toRemove.push(cls);
      }
    }
    for (const cls of toRemove) {
      root.classList.remove(cls);
    }
    // Apply new classes
    if (chatStyle && chatStyle !== 'classic') {
      root.classList.add('Chat--style-' + chatStyle);
    }
    if (hoverEffect) {
      root.classList.add('Chat--hover');
    }
    // Per-style scrollbar
    if (this.scrollNode) {
      this.scrollNode.setAttribute('data-chat-style',
        chatStyle || 'classic');
    }
  }

  /**
   * Sets the background animation on the .Chat root element.
   * Uses CSS class on rootNode so the animation layer (::before with
   * negative inset) covers the full content height as messages
   * accumulate, not just the viewport.
   * Only changes the class when the animation actually changes,
   * to avoid restarting CSS animations on unrelated settings changes.
   */
  setBgAnimation(bgAnimation, opacity) {
    this._pendingAppearance = {
      ...this._pendingAppearance,
      bgAnimation,
      bgAnimOpacity: opacity,
    };
    if (!this.rootNode) {
      return;
    }
    const newBgAnim = (bgAnimation && bgAnimation !== 'none')
      ? bgAnimation : 'none';
    if (newBgAnim !== this._currentBgAnim) {
      // Remove old bgAnim class
      if (this._currentBgAnim && this._currentBgAnim !== 'none') {
        this.rootNode.classList.remove(
          'Chat--bgAnim-' + this._currentBgAnim);
      }
      // Add new bgAnim class
      if (newBgAnim !== 'none') {
        this.rootNode.classList.add('Chat--bgAnim-' + newBgAnim);
      }
      this._currentBgAnim = newBgAnim;
    }
    this.rootNode.style.setProperty(
      '--chat-bg-anim-opacity', String(opacity ?? 0.5));
  }

  setCustomColors(bgColor, textColor, accentColor) {
    this._pendingAppearance = {
      ...this._pendingAppearance,
      bgColor,
      textColor,
      accentColor,
    };
    if (!this.rootNode) {
      return;
    }
    const root = this.rootNode;
    if (bgColor) {
      root.style.setProperty('--chat-bg', bgColor);
    }
    else {
      root.style.removeProperty('--chat-bg');
    }
    if (textColor) {
      root.style.setProperty('--chat-text', textColor);
    }
    else {
      root.style.removeProperty('--chat-text');
    }
    if (accentColor) {
      root.style.setProperty('--chat-accent', accentColor);
    }
    else {
      root.style.removeProperty('--chat-accent');
    }
  }

  setCustomProperties(props) {
    this._pendingAppearance = {
      ...this._pendingAppearance,
      _customProps: {
        ...(this._pendingAppearance?._customProps),
        ...props,
      },
    };
    if (!this.rootNode) {
      return;
    }
    const root = this.rootNode;
    for (const [key, value] of Object.entries(props)) {
      if (value !== null && value !== undefined && value !== '') {
        root.style.setProperty(key, value);
      }
      else {
        root.style.removeProperty(key);
      }
    }
  }

  applyPendingAppearance() {
    if (!this._pendingAppearance) {
      return;
    }
    const p = this._pendingAppearance;
    if (p.chatStyle !== undefined) {
      this.setChatClasses(
        p.chatStyle, p.chatAnimation, p.hoverEffect, p.smoothScroll);
    }
    if (p.bgAnimation !== undefined) {
      this.setBgAnimation(p.bgAnimation, p.bgAnimOpacity);
    }
    if (p.bgColor !== undefined || p.textColor !== undefined
      || p.accentColor !== undefined) {
      this.setCustomColors(p.bgColor, p.textColor, p.accentColor);
    }
    if (p._customProps) {
      this.setCustomProperties(p._customProps);
    }
    this._pendingAppearance = null;
  }

  // ============================================================
  // Search
  // ============================================================

  searchMessages(query) {
    this.clearSearch();
    if (!query || query.length < 2) {
      return { total: 0, current: -1 };
    }
    const escaped = query.replace(/[-/\\^$*+?.()|[\]{}]/g, '\\$&');
    this._searchRegex = new RegExp('(' + escaped + ')', 'gi');

    for (let i = 0; i < this.visibleMessages.length; i++) {
      const msg = this.visibleMessages[i];
      if (!msg.node || msg.node === 'pruned') {
        continue;
      }
      this._highlightSearchInNode(msg.node, i);
    }

    if (this._searchMatches.length > 0) {
      // Start at most recent match
      this._searchCurrentIndex = this._searchMatches.length - 1;
      this._focusSearchMatch(this._searchCurrentIndex);
    }
    return {
      total: this._searchMatches.length,
      current: this._searchCurrentIndex,
    };
  }

  _highlightSearchInNode(node, messageIndex) {
    const walker = document.createTreeWalker(
      node, NodeFilter.SHOW_TEXT);
    const textNodes = [];
    while (walker.nextNode()) {
      // Skip timestamp spans
      if (walker.currentNode.parentNode.className
        === 'ChatMessage__timestamp') {
        continue;
      }
      textNodes.push(walker.currentNode);
    }

    for (const textNode of textNodes) {
      const text = textNode.textContent;
      this._searchRegex.lastIndex = 0;
      if (!this._searchRegex.test(text)) {
        continue;
      }
      this._searchRegex.lastIndex = 0;
      const frag = document.createDocumentFragment();
      let lastIdx = 0;
      let match;
      while ((match = this._searchRegex.exec(text)) !== null) {
        if (match.index > lastIdx) {
          frag.appendChild(
            document.createTextNode(text.substring(lastIdx, match.index)));
        }
        const span = document.createElement('span');
        span.className = 'Chat__searchMatch';
        span.textContent = match[0];
        frag.appendChild(span);
        this._searchMatches.push({ node: span, messageIndex });
        lastIdx = match.index + match[0].length;
      }
      if (lastIdx < text.length) {
        frag.appendChild(
          document.createTextNode(text.substring(lastIdx)));
      }
      textNode.parentNode.replaceChild(frag, textNode);
    }
  }

  _focusSearchMatch(index) {
    // Remove active class from previous
    if (this._searchCurrentIndex >= 0
      && this._searchCurrentIndex < this._searchMatches.length) {
      const prev = this._searchMatches[this._searchCurrentIndex]?.node;
      if (prev) {
        prev.classList.remove('Chat__searchMatch--active');
      }
    }
    // Set new
    const current = this._searchMatches[index]?.node;
    if (current) {
      current.classList.add('Chat__searchMatch--active');
      current.scrollIntoView({ block: 'center', behavior: 'smooth' });
    }
    this._searchCurrentIndex = index;
  }

  searchNext() {
    if (this._searchMatches.length === 0) {
      return { total: 0, current: -1 };
    }
    const next = (this._searchCurrentIndex + 1)
      % this._searchMatches.length;
    this._focusSearchMatch(next);
    return { total: this._searchMatches.length, current: next };
  }

  searchPrev() {
    if (this._searchMatches.length === 0) {
      return { total: 0, current: -1 };
    }
    const prev = (this._searchCurrentIndex - 1
      + this._searchMatches.length) % this._searchMatches.length;
    this._focusSearchMatch(prev);
    return { total: this._searchMatches.length, current: prev };
  }

  clearSearch() {
    for (const match of this._searchMatches) {
      const span = match.node;
      if (span.parentNode) {
        span.parentNode.replaceChild(
          document.createTextNode(span.textContent), span);
      }
    }
    if (this.rootNode) {
      this.rootNode.normalize();
    }
    this._searchMatches = [];
    this._searchCurrentIndex = -1;
    this._searchRegex = null;
  }

  // ============================================================

  pruneMessages() {
    if (!this.isReady()) {
      return;
    }
    // Delay pruning because user is currently interacting
    // with chat history
    if (!this.scrollTracking) {
      logger.debug('pruning delayed');
      return;
    }
    // Visible messages
    {
      const messages = this.visibleMessages;
      const fromIndex = Math.max(0,
        messages.length - MAX_VISIBLE_MESSAGES);
      if (fromIndex > 0) {
        this.visibleMessages = messages.slice(fromIndex);
        for (let i = 0; i < fromIndex; i++) {
          const message = messages[i];
          this.rootNode.removeChild(message.node);
          // Mark this message as pruned
          message.node = 'pruned';
        }
        // Remove pruned messages from the message array
        this.messages = this.messages.filter(message => (
          message.node !== 'pruned'
        ));
        logger.log(`pruned ${fromIndex} visible messages`);
      }
    }
    // All messages
    {
      const fromIndex = Math.max(0,
        this.messages.length - MAX_PERSISTED_MESSAGES);
      if (fromIndex > 0) {
        this.messages = this.messages.slice(fromIndex);
        logger.log(`pruned ${fromIndex} stored messages`);
      }
    }
  }

  rebuildChat() {
    if (!this.isReady()) {
      return;
    }
    // Make a copy of messages
    const fromIndex = Math.max(0,
      this.messages.length - MAX_PERSISTED_MESSAGES);
    const messages = this.messages.slice(fromIndex);
    // Remove existing nodes
    for (let message of messages) {
      message.node = undefined;
    }
    // Fast clear of the root node
    this.rootNode.textContent = '';
    this.messages = [];
    this.visibleMessages = [];
    this._lastDividerTime = 0;
    // Repopulate the chat log
    this.processBatch(messages, {
      notifyListeners: false,
    });
  }

  saveToDisk() {
    // Compile currently loaded stylesheets as CSS text
    let cssText = '';
    const styleSheets = document.styleSheets;
    for (let i = 0; i < styleSheets.length; i++) {
      let cssRules;
      try {
        cssRules = styleSheets[i].cssRules;
      }
      catch (e) {
        // Some stylesheets may be inaccessible due to origin restrictions.
        continue;
      }
      for (let j = 0; j < cssRules.length; j++) {
        const rule = cssRules[j];
        if (rule && typeof rule.cssText === 'string') {
          cssText += rule.cssText + '\n';
        }
      }
    }
    cssText += 'body, html { background-color: #141414 }\n';
    // Compile chat log as HTML text
    let messagesHtml = '';
    for (let message of this.visibleMessages) {
      if (message.node) {
        messagesHtml += message.node.outerHTML + '\n';
      }
    }
    // Create a page
    const pageHtml = '<!doctype html>\n'
      + '<html>\n'
      + '<head>\n'
      + '<title>SS13 Chat Log</title>\n'
      + '<style>\n' + cssText + '</style>\n'
      + '</head>\n'
      + '<body>\n'
      + '<div class="Chat">\n'
      + messagesHtml
      + '</div>\n'
      + '</body>\n'
      + '</html>\n';
    // Create and send a nice blob
    const blob = new Blob([pageHtml]);
    const timestamp = new Date()
      .toISOString()
      .substring(0, 19)
      .replace(/[-:]/g, '')
      .replace('T', '-');
    const fileName = `ss13-chatlog-${timestamp}.html`;
    const url = window.URL.createObjectURL(blob);
    const anchor = document.createElement('a');
    anchor.href = url;
    anchor.download = fileName;
    document.body.appendChild(anchor);
    anchor.click();
    document.body.removeChild(anchor);
    window.URL.revokeObjectURL(url);
  }
}

// Make chat renderer global so that we can continue using the same
// instance after hot code replacement.
if (!window.__chatRenderer__) {
  window.__chatRenderer__ = new ChatRenderer();
}

/** @type {ChatRenderer} */
export const chatRenderer = window.__chatRenderer__;

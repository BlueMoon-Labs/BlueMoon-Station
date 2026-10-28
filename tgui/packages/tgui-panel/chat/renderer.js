/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { defer } from 'common/defer';
import { EventEmitter } from 'common/events';
import { classes } from 'common/react';
import { createLogger } from 'tgui/logging';

import highlightSoundUrl from '../assets/chat_notify.ogg';
import { MESSAGE_STYLE_ANIMATIONS, MESSAGE_STYLES } from '../settings/constants';
import { COMBINE_MAX_MESSAGES, COMBINE_MAX_TIME_WINDOW, IMAGE_RETRY_DELAY, IMAGE_RETRY_LIMIT, IMAGE_RETRY_MAX_DELAY, IMAGE_RETRY_MESSAGE_AGE, MAX_PERSISTED_MESSAGES, MAX_VISIBLE_MESSAGES, MESSAGE_PRUNE_INTERVAL, MESSAGE_TYPE_INTERNAL, MESSAGE_TYPE_UNKNOWN, MESSAGE_TYPES } from './constants';
import { getBlockFxClasses, settleOldMessages } from './messageFx';
import { canPageAcceptType, createMessage, isSameMessage } from './model';
import { highlightNode, linkifyNode } from './replaceInTextNode';
import { getChatColorProps, getGameFxRootClasses, getRadioJobRoot, getSettleRootClasses, getStyleOverrideRoot, isGameFxRootClass, isRadioJobRootClass, isStyleOverrideClass, SETTLE_OFF_CLASS } from './rootAppearance';
import { buildTypeOverrideCss } from './typeOverrides';

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

// Слоёв в узле фона, см. ChatBgAnimations.scss.
export const BG_LAYERS = 3;

const STYLE_OVERRIDE_SHEET_ID = 'cs-style-overrides';
const TYPE_OVERRIDE_SHEET_ID = 'cs-type-overrides';

const FONT_OVERRIDE_CSS = {
  normal: 'font-weight: normal; font-style: normal;',
  italic: 'font-weight: normal; font-style: italic;',
  bold: 'font-weight: bold; font-style: normal;',
  bolditalic: 'font-weight: bold; font-style: italic;',
};

/**
 * Builds CSS text for font/size/animation overrides of message styles.
 * Colors go through CSS custom properties instead (see setStyleOverrides),
 * because their theme defaults differ between dark and light.
 */
const buildStyleOverrideCss = (overrides) => {
  let css = '';
  for (const style of MESSAGE_STYLES) {
    const override = overrides[style.id];
    if (!override || override.disabled) {
      continue;
    }
    const classNames = [style.id, ...(style.extraClasses || [])];
    const decls = [];
    if (FONT_OVERRIDE_CSS[override.font]) {
      decls.push(FONT_OVERRIDE_CSS[override.font]);
    }
    const size = parseFloat(override.size);
    if (size && size !== 100) {
      const clamped = Math.min(200, Math.max(50, size));
      decls.push('font-size: ' + clamped + '%;');
    }
    if (decls.length > 0) {
      css += classNames.map(cls => '.Chat .' + cls).join(', ')
        + ' { ' + decls.join(' ') + ' }\n';
    }
    const anim = MESSAGE_STYLE_ANIMATIONS.find(a => a.id === override.anim);
    if (anim?.css) {
      // :not() держит специфичность выше темы, но уступает глобальному
      // тумблеру Chat--fxAnimOff.
      css += classNames
        .map(cls => '.Chat:not(.Chat--fxAnimOff) .' + cls)
        .join(', ')
        + ' { animation: ' + anim.css + '; }\n';
    }
  }
  return css;
};

const updateSheet = (id, cssText) => {
  let node = document.getElementById(id);
  if (!cssText) {
    node?.remove();
    return;
  }
  if (!node) {
    node = document.createElement('style');
    node.id = id;
    document.head.appendChild(node);
  }
  if (node.textContent !== cssText) {
    node.textContent = cssText;
  }
};

const setRootProps = (root, props) => {
  for (const [key, value] of Object.entries(props)) {
    if (value !== null && value !== undefined && value !== '') {
      root.style.setProperty(key, value);
    }
    else {
      root.style.removeProperty(key);
    }
  }
};

const createHighlightNode = (text, color) => {
  const node = document.createElement('span');
  node.className = 'Chat__highlight';
  node.setAttribute('style', 'background-color:' + color);
  node.textContent = text;
  return node;
};

const createHighlightProbeNode = (message) => {
  const node = document.createElement('span');
  if (message.text) {
    node.appendChild(document.createTextNode(message.text));
    return node;
  }
  if (message.html) {
    node.innerHTML = message.html;
    return node;
  }
  return null;
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

const createNewMarkerNode = () => {
  const node = document.createElement('div');
  node.className = 'Chat__newMarker';
  node.textContent = 'Новые сообщения';
  return node;
};

const createTimeDividerNode = (timestamp) => {
  const node = document.createElement('div');
  node.className = 'Chat__timeDivider';
  node.textContent = formatTimestamp(timestamp, 'hm');
  return node;
};

// Ресурсы BYOND едут по тому же каналу, что и всё остальное, и на забитом канале
// приезжают позже; внешние ссылки (админ вставил в ЛС картинку с чужого хоста)
// не приедут никогда, и каждая попытка - это лишний HTTP-запрос и строка в логе.
// Сверяем именно origin разрешённого адреса, а не наличие схемы в атрибуте:
// после первого же ретрая мы сами переписываем src абсолютным адресом, и
// проверка "есть схема - значит чужой" отсекала бы собственные картинки.
const isRetriableImage = node => {
  const attribute = node.getAttribute('src');
  if (!attribute) {
    return false;
  }
  if (attribute.startsWith('data:')) {
    return true;
  }
  const resolved = node.src;
  if (!resolved) {
    return true;
  }
  // Сверяем origin разбором URL, а не префиксом: "https://host" - префикс и для
  // "https://host.evil", то есть чужой хост проходил фильтр и собирал свои ретраи.
  try {
    return new URL(resolved).origin === window.location.origin;
  }
  catch {
    return false;
  }
};

const handleImageError = e => {
  /** @type {HTMLImageElement} */
  const node = e.target;
  if (!isRetriableImage(node)) {
    return;
  }
  const attempts = parseInt(node.getAttribute('data-reload-n'), 10) || 0;
  if (attempts >= IMAGE_RETRY_LIMIT) {
    logger.error(`failed to load an image after ${attempts} attempts`);
    return;
  }
  // Экспоненциальная выдержка: прежний бюджет 10 x 250 мс = 2.5 с был короче
  // одного худшего round-trip, замеренного на проде.
  const delay = Math.min(IMAGE_RETRY_DELAY * 2 ** attempts, IMAGE_RETRY_MAX_DELAY);
  setTimeout(() => {
    const src = node.src.split('#')[0];
    node.removeAttribute('src');
    node.src = src + '#' + attempts;
    node.setAttribute('data-reload-n', attempts + 1);
  }, delay);
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
    // Растёт при любой правке списка сообщений, по нему сохранение
    // в хранилище пропускает неизменившийся чат.
    this.messagesVersion = 0;
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
        if (scrollTracking) {
          this._newMarkerArmed = true;
        }
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
    this.bgNode = null;
    this._bgResizeObserver = null;
    // Highlight state
    this.highlightRegex = null;
    this.highlightColor = null;
    this.highlightSoundEnabled = false;
    this.highlightSoundNode = null;
    // Timestamps & time dividers
    this.enableTimestamps = false;
    this.timestampFormat = 'hm';
    this.enableTimeDividers = false;
    this.timeDividerInterval = 300000;
    this._lastDividerTime = 0;
    // Линия перед первым сообщением, пришедшим, пока читают историю выше
    this.newMarkerEnabled = false;
    this._newMarkerNode = null;
    this._newMarkerMessage = null;
    this._newMarkerArmed = true;
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
    if (this.bgNode) {
      this.observeBgViewport();
    }
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

  setHighlightSound(enabled) {
    this.highlightSoundEnabled = !!enabled;
  }

  messageWouldHighlight(message) {
    if (!this.highlightRegex || message.avoidHighlighting) {
      return false;
    }
    const node = createHighlightProbeNode(message);
    if (!node) {
      return false;
    }
    return highlightNode(
      node,
      this.highlightRegex,
      text => document.createTextNode(text),
    ) > 0;
  }

  playHighlightSound() {
    if (!this.highlightSoundEnabled || typeof Audio !== 'function') {
      return;
    }
    if (!this.highlightSoundNode) {
      this.highlightSoundNode = new Audio(highlightSoundUrl);
      this.highlightSoundNode.preload = 'auto';
    }
    try {
      this.highlightSoundNode.currentTime = 0;
    }
    catch {
      // Ignore seek errors from browsers that block early media access.
    }
    const playResult = this.highlightSoundNode.play?.();
    playResult?.catch?.(() => {});
  }

  setTimestamps(enable, format) {
    this.enableTimestamps = enable;
    this.timestampFormat = format || 'hm';
  }

  setTimeDividers(enable, interval) {
    this.enableTimeDividers = enable;
    this.timeDividerInterval = interval || 300000;
  }

  setNewMessagesMarker(enabled) {
    if (!!enabled !== this.newMarkerEnabled) {
      this._newMarkerArmed = true;
    }
    this.newMarkerEnabled = !!enabled;
    if (!this.newMarkerEnabled) {
      this.dropNewMarker();
    }
  }

  // Не взводит отметку заново: в том же сеансе прокрутки вверх
  // вторая линия не нужна.
  dropNewMarker() {
    this._newMarkerNode?.remove();
    this._newMarkerMessage = null;
  }

  /**
   * Places the marker before the first unread message of the current
   * scroll-up session. Returns the node to insert, if any.
   */
  takeNewMarker(message, shouldAutoScroll) {
    if (!this.newMarkerEnabled || shouldAutoScroll || !this._newMarkerArmed
      || message.type.startsWith(MESSAGE_TYPE_INTERNAL)) {
      return null;
    }
    this._newMarkerArmed = false;
    this._newMarkerNode = this._newMarkerNode || createNewMarkerNode();
    this._newMarkerMessage = message;
    return this._newMarkerNode;
  }

  scrollToBottom() {
    if (!this.scrollNode) {
      return;
    }
    this._newMarkerArmed = true;
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
    this.dropNewMarker();
    // Fast clear of the root node
    this.rootNode.textContent = '';
    this.restoreBgNode();
    this.visibleMessages = [];
    // Разделители зависят от соседей на вкладке: пересчитываем заново.
    this._lastDividerTime = 0;
    const now = Date.now();
    // Re-add message nodes
    const fragment = document.createDocumentFragment();
    let node;
    for (let message of this.messages) {
      if (canPageAcceptType(page, message.type)) {
        node = message.node;
        this.attachTimeDivider(message, now);
        if (message.dividerNode) {
          fragment.appendChild(message.dividerNode);
        }
        fragment.appendChild(node);
        this.visibleMessages.push(message);
      }
      else {
        message.dividerNode = undefined;
      }
    }
    settleOldMessages(this.visibleMessages, true);
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

  /**
   * Divider belongs to the message right after it on the current tab,
   * so pruning removes it together with that message.
   */
  attachTimeDivider(message, now) {
    message.dividerNode = undefined;
    if (!this.enableTimeDividers) {
      return;
    }
    const msgTime = message.createdAt || now;
    if (this._lastDividerTime === 0) {
      this._lastDividerTime = msgTime;
    }
    else if (msgTime - this._lastDividerTime >= this.timeDividerInterval) {
      message.dividerNode = createTimeDividerNode(msgTime);
      this._lastDividerTime = msgTime;
    }
  }

  /**
   * Time divider and the new messages line go right before a message
   * shown on the current tab.
   */
  appendLeadNodes(fragment, message, now, options, shouldAutoScroll) {
    const { prepend, notifyListeners = true } = options;
    if (prepend) {
      return;
    }
    this.attachTimeDivider(message, now);
    if (message.dividerNode) {
      fragment.appendChild(message.dividerNode);
    }
    const marker = notifyListeners
      && this.takeNewMarker(message, shouldAutoScroll);
    if (marker) {
      fragment.appendChild(marker);
    }
  }

  linkifyAndWatchImages(node, message, now) {
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

  processBatch(batch, options = {}) {
    const {
      prepend,
      notifyListeners = true,
    } = options;
    const canPlayHighlightSound = this.highlightSoundEnabled
      && !prepend
      && notifyListeners;
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
    if (batch.length > 0) {
      this.messagesVersion++;
    }
    // Insert messages
    const fragment = document.createDocumentFragment();
    const countByType = {};
    let shouldPlayBatchHighlightSound = false;
    let node;
    // История из хранилища старше всего, что уже есть: копим её отдельно
    // и ставим в начало списков, иначе обрезка и смена вкладки берут
    // новые сообщения за старые.
    const prepended = prepend ? [] : null;
    const prependedVisible = prepend ? [] : null;
    for (let payload of batch) {
      const message = createMessage(payload);
      // Combine messages
      const combinable = !prepend && this.getCombinableMessage(message);
      if (combinable) {
        if (canPlayHighlightSound && this.messageWouldHighlight(message)) {
          shouldPlayBatchHighlightSound = true;
        }
        combinable.times = (combinable.times || 1) + 1;
        updateMessageBadge(combinable);
        continue;
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
            if (canPlayHighlightSound) {
              shouldPlayBatchHighlightSound = true;
            }
          }
        }
        this.linkifyAndWatchImages(node, message, now);
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
      if (!node.dataset.fxTagged) {
        node.dataset.fxTagged = '1';
        node.classList.add('ChatMessage--type-'
          + String(message.type).replace(/[^a-z0-9_-]/gi, '-'));
        for (const cls of getBlockFxClasses(node)) {
          node.classList.add(cls);
        }
      }
      updateMessageBadge(message);
      if (!countByType[message.type]) {
        countByType[message.type] = 0;
      }
      countByType[message.type] += 1;
      // TODO: Detect duplicates
      (prepended || this.messages).push(message);
      if (canPageAcceptType(this.page, message.type)) {
        this.appendLeadNodes(fragment, message, now, options,
          shouldAutoScroll);
        fragment.appendChild(node);
        (prependedVisible || this.visibleMessages).push(message);
      }
    }
    if (prepended?.length) {
      this.messages = prepended.concat(this.messages);
      this.visibleMessages = prependedVisible.concat(this.visibleMessages);
    }
    if (shouldPlayBatchHighlightSound) {
      this.playHighlightSound();
    }
    if (node) {
      const firstChild = this.bgNode
        ? this.bgNode.nextSibling
        : this.rootNode.childNodes[0];
      if (prepend && firstChild) {
        this.rootNode.insertBefore(fragment, firstChild);
      }
      else {
        this.rootNode.appendChild(fragment);
      }
      settleOldMessages(this.visibleMessages, prepend);
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
   * Фон чата: класс Chat--bgAnim-<id> на корне и узел .ChatBg первым
   * ребёнком. Узел липнет к окну прокрутки и размером с него, а не со
   * всю историю; слои внутри двигаются только transform/opacity.
   * Класс меняется лишь при смене фона, чтобы не перезапускать анимации.
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
        this.createBgNode();
      }
      else {
        this.removeBgNode();
      }
      this._currentBgAnim = newBgAnim;
    }
    this.rootNode.style.setProperty(
      '--chat-bg-anim-opacity', String(opacity ?? 0.5));
  }

  createBgNode() {
    if (!this.bgNode) {
      const node = document.createElement('div');
      node.className = 'ChatBg';
      node.setAttribute('aria-hidden', 'true');
      for (let i = 1; i <= BG_LAYERS; i++) {
        const layer = document.createElement('div');
        layer.className = 'ChatBg__layer ChatBg__layer--' + i;
        node.appendChild(layer);
      }
      this.bgNode = node;
    }
    this.restoreBgNode();
    this.observeBgViewport();
  }

  removeBgNode() {
    this._bgResizeObserver?.disconnect();
    this._bgResizeObserver = null;
    this.bgNode?.remove();
    this.bgNode = null;
  }

  // Узел фона всегда первый: очистка корня его снимает, вставка истории
  // идёт после него.
  restoreBgNode() {
    if (this.bgNode && this.rootNode
      && this.rootNode.firstChild !== this.bgNode) {
      this.rootNode.insertBefore(this.bgNode, this.rootNode.firstChild);
    }
  }

  observeBgViewport() {
    const scrollNode = this.scrollNode;
    const bgNode = this.bgNode;
    if (!scrollNode || !bgNode) {
      return;
    }
    const update = () => {
      bgNode.style.setProperty('--chat-view-h',
        scrollNode.clientHeight + 'px');
    };
    update();
    this._bgResizeObserver?.disconnect();
    this._bgResizeObserver = null;
    if (typeof ResizeObserver === 'function') {
      this._bgResizeObserver = new ResizeObserver(update);
      this._bgResizeObserver.observe(scrollNode);
    }
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
    setRootProps(this.rootNode,
      getChatColorProps(bgColor, textColor, accentColor));
  }

  /**
   * Applies per-style customization: color overrides via CSS custom
   * properties (--cs-<id>-color), "plain look" via Chat--plain-<id>
   * classes, font/size/animation via a dynamic stylesheet, plus the
   * global span animation toggle (Chat--fxAnimOff).
   * @param {Object} overrides map of styleId ->
   *   { color, disabled, font, size, anim }
   * @param {boolean} spanAnimations
   */
  setRadioJobsVisible(visible = true) {
    this._pendingAppearance = {
      ...this._pendingAppearance,
      radioJobsVisible: visible,
    };
    if (!this.rootNode) {
      return;
    }
    this.rootNode.classList.toggle('Chat--hideRadioJobs', !visible);
  }

  setRadioJobStyle(settings = {}) {
    this._pendingAppearance = {
      ...this._pendingAppearance,
      radioJobStyle: settings,
    };
    if (!this.rootNode) {
      return;
    }
    const root = this.rootNode;
    const toRemove = [...root.classList].filter(isRadioJobRootClass);
    for (const cls of toRemove) {
      root.classList.remove(cls);
    }
    const { classes: rootClasses, props } = getRadioJobRoot(settings);
    for (const cls of rootClasses) {
      root.classList.add(cls);
    }
    setRootProps(root, props);
  }

  setStyleOverrides(overrides = {}, spanAnimations = true) {
    this._pendingAppearance = {
      ...this._pendingAppearance,
      styleOverrides: overrides,
      spanAnimations,
    };
    if (!this.rootNode) {
      return;
    }
    const root = this.rootNode;
    const toRemove = [...root.classList].filter(isStyleOverrideClass);
    for (const cls of toRemove) {
      root.classList.remove(cls);
    }
    const { classes: rootClasses, props } = getStyleOverrideRoot(
      overrides, spanAnimations);
    for (const cls of rootClasses) {
      root.classList.add(cls);
    }
    setRootProps(root, props);
    updateSheet(STYLE_OVERRIDE_SHEET_ID, buildStyleOverrideCss(overrides));
  }

  setTypeOverrides(overrides = {}) {
    this._pendingAppearance = {
      ...this._pendingAppearance,
      typeOverrides: overrides,
    };
    updateSheet(TYPE_OVERRIDE_SHEET_ID, buildTypeOverrideCss(overrides));
  }

  setGameEffects(effects = {}, enabled = true) {
    this._pendingAppearance = {
      ...this._pendingAppearance,
      gameEffects: effects,
      gameEffectsEnabled: enabled,
    };
    if (!this.rootNode) {
      return;
    }
    const root = this.rootNode;
    const toRemove = [...root.classList].filter(isGameFxRootClass);
    for (const cls of toRemove) {
      root.classList.remove(cls);
    }
    for (const cls of getGameFxRootClasses(effects, enabled)) {
      root.classList.add(cls);
    }
  }

  setSettleOld(enabled = true) {
    this._pendingAppearance = {
      ...this._pendingAppearance,
      settleOld: enabled,
    };
    if (!this.rootNode) {
      return;
    }
    this.rootNode.classList.remove(SETTLE_OFF_CLASS);
    for (const cls of getSettleRootClasses(enabled)) {
      this.rootNode.classList.add(cls);
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
    setRootProps(this.rootNode, props);
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
    if (p.styleOverrides !== undefined) {
      this.setStyleOverrides(p.styleOverrides, p.spanAnimations);
    }
    if (p.typeOverrides !== undefined) {
      this.setTypeOverrides(p.typeOverrides);
    }
    if (p.gameEffects !== undefined) {
      this.setGameEffects(p.gameEffects, p.gameEffectsEnabled);
    }
    if (p.settleOld !== undefined) {
      this.setSettleOld(p.settleOld);
    }
    if (p.radioJobsVisible !== undefined) {
      this.setRadioJobsVisible(p.radioJobsVisible);
    }
    if (p.radioJobStyle !== undefined) {
      this.setRadioJobStyle(p.radioJobStyle);
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
          message.dividerNode?.remove();
          message.dividerNode = undefined;
          if (message === this._newMarkerMessage) {
            this.dropNewMarker();
          }
          // Mark this message as pruned
          message.node = 'pruned';
        }
        // Remove pruned messages from the message array
        this.messages = this.messages.filter(message => (
          message.node !== 'pruned'
        ));
        this.messagesVersion++;
        logger.log(`pruned ${fromIndex} visible messages`);
      }
    }
    // All messages
    {
      const fromIndex = Math.max(0,
        this.messages.length - MAX_PERSISTED_MESSAGES);
      if (fromIndex > 0) {
        this.messages = this.messages.slice(fromIndex);
        this.messagesVersion++;
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
      message.dividerNode = undefined;
    }
    this.dropNewMarker();
    // Fast clear of the root node
    this.rootNode.textContent = '';
    this.restoreBgNode();
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

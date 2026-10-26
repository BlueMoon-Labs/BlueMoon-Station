import { setGlobalStore } from 'common/redux';
import { act } from 'react';
import { createRoot } from 'react-dom/client';

import { MESSAGE_TYPES } from '../chat/constants';
import { getChatColorProps, getChatCustomProps, getStyleOverrideRoot } from '../chat/rootAppearance';
import { ChatPreview, getPreviewRootClasses, getPreviewRootStyle } from './ChatPreview';
import { CHANNEL_TYPES } from './constants';

const mounted = [];

const renderWith = (settings, props = {}) => {
  let state = { settings };
  setGlobalStore({
    getState: () => state,
    dispatch: () => {},
  });
  const container = document.createElement('div');
  document.body.appendChild(container);
  const root = createRoot(container);
  act(() => root.render(<ChatPreview {...props} />));
  mounted.push({ root, container });
  const rerender = next => {
    state = { settings: next };
    act(() => root.render(<ChatPreview {...props} />));
  };
  return { container, rerender };
};

const messagesOf = container => [...container
  .querySelectorAll('.ChatPreview > .ChatMessage')];

const typeOf = node => node.className.match(/ChatMessage--type-([a-z]+)/)[1];

// Тип, который рендерер чата дал бы такому сообщению.
const classifiedType = node => MESSAGE_TYPES
  .find(def => def.selector && node.querySelector(def.selector))?.type;

beforeAll(() => {
  globalThis.IS_REACT_ACT_ENVIRONMENT = true;
});

afterEach(() => {
  for (const { root, container } of mounted.splice(0)) {
    act(() => root.unmount());
    container.remove();
  }
});

test('classic style has only base class', () => {
  expect(getPreviewRootClasses({ chatStyle: 'classic' })).toBe('Chat');
});

test('style class is added', () => {
  expect(getPreviewRootClasses({ chatStyle: 'seccon' }))
    .toBe('Chat Chat--style-seccon');
});

test('settle off adds its class', () => {
  expect(getPreviewRootClasses({
    chatStyle: 'classic',
    settleOldAnimations: false,
  })).toContain('Chat--noSettle');
});

test('text style toggles reach the preview root', () => {
  const classes = getPreviewRootClasses({
    chatStyle: 'classic',
    hoverEffect: true,
    spanAnimations: false,
    styleOverrides: { emote: { disabled: true }, whisper: { color: '#111111' } },
  }).split(' ');
  expect(classes).toContain('Chat--hover');
  expect(classes).toContain('Chat--fxAnimOff');
  expect(classes).toContain('Chat--plain-emote');
  expect(classes).not.toContain('Chat--plain-whisper');
});

test('root style carries custom properties', () => {
  const style = getPreviewRootStyle({ chatAccentColor: '#123456', borderRadius: 3 });
  expect(style['--chat-accent']).toBe('#123456');
  expect(style['--chat-border-radius']).toBe('3px');
});

test('root style is what the chat root gets', () => {
  const settings = {
    chatAnimSpeed: 'slow',
    textGlow: 'subtle',
    chatAccentColor: '#123456',
    chatBgColor: '',
    messageSpacing: 4,
    fontWeight: 600,
    letterSpacing: 0.5,
    borderRadius: 0,
    styleOverrides: { whisper: { color: '#abcdef' } },
  };
  const expected = {
    ...getChatColorProps(settings.chatBgColor, settings.chatTextColor,
      settings.chatAccentColor),
    ...getChatCustomProps(settings),
    ...getStyleOverrideRoot(settings.styleOverrides, true).props,
  };
  const style = getPreviewRootStyle(settings);
  for (const [key, value] of Object.entries(expected)) {
    expect([key, style[key]]).toEqual([key, value === null ? undefined : value]);
  }
  expect(Object.keys(style).sort()).toEqual(Object.keys(expected)
    .filter(key => expected[key] !== null).sort());
});

test('preview renders samples with the chat message classes', () => {
  const { container } = renderWith({
    chatStyle: 'seccon',
    chatAnimation: 'teletype',
    chatAccentColor: '#123456',
  });
  const root = container.querySelector('.ChatPreview');
  expect(root.className).toBe('Chat Chat--style-seccon ChatPreview');
  expect(root.style.getPropertyValue('--chat-accent')).toBe('#123456');
  const messages = root.querySelectorAll(':scope > .ChatMessage');
  expect(messages.length).toBeGreaterThan(4);
  for (const node of messages) {
    expect(node.className).toMatch(/ChatMessage--type-[a-z]+/);
    expect(node.classList.contains('ChatMessage--anim-teletype')).toBe(true);
  }
  const types = [...messages].map(node => node.className
    .match(/ChatMessage--type-([a-z]+)/)[1]);
  expect(types).toEqual(expect.arrayContaining(
    ['localchat', 'radio', 'ooc', 'adminpm']));
});

test('no animation class without an animation', () => {
  const { container } = renderWith({ chatStyle: 'classic', chatAnimation: 'none' });
  const root = container.querySelector('.ChatPreview');
  expect(root.className).toBe('Chat ChatPreview');
  expect(root.querySelector('[class*="ChatMessage--anim-"]')).toBeNull();
});

test('appearance samples are typed the way the chat types them', () => {
  const { container } = renderWith({ chatStyle: 'classic' });
  for (const node of messagesOf(container)) {
    expect(classifiedType(node)).toBe(typeOf(node));
  }
});

test('channels preview has a sample for every channel type', () => {
  const { container } = renderWith({ chatStyle: 'classic' },
    { samples: 'channels' });
  const messages = messagesOf(container);
  expect(messages.map(typeOf)).toEqual(CHANNEL_TYPES.map(c => c.type));
  messages.forEach((node, i) => {
    expect(classifiedType(node)).toBe(CHANNEL_TYPES[i].type);
    expect(node.textContent).toBe(CHANNEL_TYPES[i].example);
  });
});

test('changing animation speed replays the samples', () => {
  const settings = { chatAnimation: 'fadein', chatAnimSpeed: 'normal' };
  const { container, rerender } = renderWith(settings);
  const first = messagesOf(container)[0];
  rerender({ ...settings, chatAccentColor: '#123456' });
  expect(messagesOf(container)[0]).toBe(first);
  rerender({ ...settings, chatAnimSpeed: 'slow' });
  expect(messagesOf(container)[0]).not.toBe(first);
});

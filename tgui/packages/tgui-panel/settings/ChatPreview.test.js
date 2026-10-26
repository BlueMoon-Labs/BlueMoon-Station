import { setGlobalStore } from 'common/redux';
import { act } from 'react';
import { createRoot } from 'react-dom/client';

import { MESSAGE_TYPES } from '../chat/constants';
import { getBlockFxClasses } from '../chat/messageFx';
import { getChatColorProps, getChatCustomProps, getRadioJobRoot, getStyleOverrideRoot } from '../chat/rootAppearance';
import { ChatPreview, getPreviewRootClasses, getPreviewRootStyle } from './ChatPreview';
import { CHANNEL_TYPES } from './constants';

jest.mock('../chat/messageFx', () => ({
  ...jest.requireActual('../chat/messageFx'),
  getBlockFxClasses: jest.fn(),
}));

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

beforeEach(() => {
  getBlockFxClasses.mockImplementation(
    jest.requireActual('../chat/messageFx').getBlockFxClasses);
});

afterEach(() => {
  for (const { root, container } of mounted.splice(0)) {
    act(() => root.unmount());
    container.remove();
  }
});

test('classic style has only base class', () => {
  expect(getPreviewRootClasses({ chatStyle: 'classic', radioJobHeadMark: 'none' })).toBe('Chat');
});

test('style class is added', () => {
  expect(getPreviewRootClasses({ chatStyle: 'seccon', radioJobHeadMark: 'none' }))
    .toBe('Chat Chat--style-seccon');
});

test('game effects off adds off classes', () => {
  expect(getPreviewRootClasses({
    chatStyle: 'classic',
    gameEffectsEnabled: false,
  })).toContain('Chat--gameFxOff');
  expect(getPreviewRootClasses({
    chatStyle: 'classic',
    gameEffects: { tremble: false },
  })).toContain('Chat--fxOff-tremble');
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
    radioJobColors: { sec: '#ff0000' },
  };
  const expected = {
    ...getChatColorProps(settings.chatBgColor, settings.chatTextColor,
      settings.chatAccentColor),
    ...getChatCustomProps(settings),
    ...getStyleOverrideRoot(settings.styleOverrides, true).props,
    ...getRadioJobRoot(settings).props,
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
    radioJobHeadMark: 'none',
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
  const yell = root.querySelector('.yell').closest('.ChatMessage');
  expect(yell.classList.contains('ChatMessage--fx-shake')).toBe(true);
  const say = root.querySelector('.say').closest('.ChatMessage');
  expect(say.classList.contains('ChatMessage--fx-shake')).toBe(false);
});

test('no animation class without an animation', () => {
  const { container } = renderWith({ chatStyle: 'classic', chatAnimation: 'none', radioJobHeadMark: 'none' });
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

test('radio settings reach the preview root', () => {
  const classes = getPreviewRootClasses({
    chatStyle: 'classic',
    radioJobColorMode: 'legacy',
    radioJobHeadMark: 'bold',
    radioJobColorNames: true,
    radioJobIcons: false,
    showRadioJobs: false,
  }).split(' ');
  expect(classes).toEqual(expect.arrayContaining(['Chat--rjLegacy',
    'Chat--rjHead-bold', 'Chat--rjNames', 'Chat--rjNoIcon',
    'Chat--hideRadioJobs']));
  expect(getPreviewRootStyle({ radioJobColors: { med: '#123456' } })['--rj-med'])
    .toBe('#123456');
});

test('radio samples carry a rank-and-file and a head tag', () => {
  const { container } = renderWith({ chatStyle: 'classic' });
  const root = container.querySelector('.ChatPreview');
  expect(root.classList.contains('Chat--rjHead-icon')).toBe(true);
  const tags = [...root.querySelectorAll('.radio .radiojob')];
  expect(tags.length).toBeGreaterThanOrEqual(2);
  expect(tags.some(tag => tag.classList.contains('radiojob-head'))).toBe(true);
  expect(tags.some(tag => !tag.classList.contains('radiojob-head'))).toBe(true);
  const departmentOf = node => [...node.classList].filter(cls => cls !== 'radiojob'
    && cls !== 'radiojob-name' && !cls.includes('legacy-'));
  for (const tag of tags) {
    expect(tag.getAttribute('style')).toBeNull();
    // Как в say.dm: класс старого вывода первым, у имени он свой.
    expect(tag.classList[0]).toMatch(/^radiojob-legacy-/);
    const legacy = tag.classList[0].slice('radiojob-legacy-'.length);
    const name = tag.parentNode.querySelector('.radiojob-name');
    expect(departmentOf(name)).toEqual(departmentOf(tag));
    expect(name.className).not.toContain('radiojob-legacy-');
    expect(name.classList.contains('radiojob-name-legacy-' + legacy)).toBe(true);
    const icon = tag.previousElementSibling;
    expect(icon.className).toMatch(/^radiojob-icon chat16x16 job-[a-z]+$/);
  }
});

test('block effects of a sample are computed once', () => {
  const { rerender } = renderWith({ chatStyle: 'classic' });
  const calls = getBlockFxClasses.mock.calls.length;
  rerender({ chatStyle: 'seccon' });
  rerender({ chatStyle: 'pda' });
  expect(getBlockFxClasses.mock.calls.length).toBe(calls);
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

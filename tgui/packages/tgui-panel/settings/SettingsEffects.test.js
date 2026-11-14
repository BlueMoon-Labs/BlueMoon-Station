import { setGlobalStore } from 'common/redux';
import { act } from 'react';
import { createRoot } from 'react-dom/client';

import { GAME_EFFECTS } from './constants';
import { settingsReducer } from './reducer';
import { SettingsEffects } from './SettingsEffects';

const mounted = [];

const renderWith = settings => {
  const dispatched = [];
  setGlobalStore({
    getState: () => ({ settings: { theme: 'dark', ...settings } }),
    dispatch: action => dispatched.push(action),
  });
  const container = document.createElement('div');
  document.body.appendChild(container);
  const root = createRoot(container);
  act(() => root.render(<SettingsEffects />));
  mounted.push({ root, container });
  return { container, dispatched };
};

const buttonOf = (container, text) => [...container.querySelectorAll('.Button')]
  .find(button => button.textContent.trim() === text);

const click = node => act(() => node.dispatchEvent(
  new MouseEvent('click', { bubbles: true })));

const sampleRoot = container => container.querySelector('.SettingsEffects__samples');

beforeAll(() => {
  globalThis.IS_REACT_ACT_ENVIRONMENT = true;
});

afterEach(() => {
  for (const { root, container } of mounted.splice(0)) {
    act(() => root.unmount());
    container.remove();
  }
});

test('effect checkbox turns only its effect off', () => {
  const { container, dispatched } = renderWith({
    gameEffects: { drunk: false },
  });
  click(buttonOf(container, 'Дрожь'));
  expect(dispatched).toHaveLength(1);
  expect(dispatched[0].payload)
    .toEqual({ gameEffects: { drunk: false, tremble: false } });
});

test('turning an effect back on drops its entry', () => {
  const { container, dispatched } = renderWith({
    gameEffects: { drunk: false, tremble: false },
  });
  click(buttonOf(container, 'Опьянение'));
  expect(dispatched[0].payload).toEqual({ gameEffects: { tremble: false } });
});

test('every effect has a checkbox and a sample', () => {
  const { container } = renderWith({ gameEffects: {} });
  for (const effect of GAME_EFFECTS) {
    expect(buttonOf(container, effect.name)).toBeTruthy();
  }
  expect(sampleRoot(container).querySelectorAll('.ChatMessage'))
    .toHaveLength(GAME_EFFECTS.length);
});

test('samples carry the root and block classes of the real chat', () => {
  const { container } = renderWith({ gameEffects: { gasp: false } });
  const root = sampleRoot(container);
  expect(root.classList.contains('Chat')).toBe(true);
  expect(root.classList.contains('Chat--fxOff-gasp')).toBe(true);
  expect(root.classList.contains('Chat--fxOff-drunk')).toBe(false);
  expect(root.querySelector('.ChatMessage--fx-shake .yell')).toBeTruthy();
  expect(root.querySelector('.ChatMessage--fx-sway .hear_dizzy')).toBeTruthy();
});

test('master toggle turns all effects off and locks their checkboxes', () => {
  const on = renderWith({ gameEffectsEnabled: true, gameEffects: {} });
  click(buttonOf(on.container, 'Игровые эффекты текста'));
  expect(on.dispatched[0].payload).toEqual({ gameEffectsEnabled: false });

  const off = renderWith({ gameEffectsEnabled: false, gameEffects: {} });
  expect(sampleRoot(off.container).classList.contains('Chat--gameFxOff'))
    .toBe(true);
  const tremble = buttonOf(off.container, 'Дрожь');
  expect(tremble.classList.contains('Button--disabled')).toBe(true);
  click(tremble);
  expect(off.dispatched).toHaveLength(0);
  click(buttonOf(off.container, 'Игровые эффекты текста'));
  expect(off.dispatched[0].payload).toEqual({ gameEffectsEnabled: true });
});

test('settle checkbox flips settleOldAnimations', () => {
  const on = renderWith({ settleOldAnimations: true });
  const settle = buttonOf(on.container, 'Гасить анимации старых сообщений');
  expect(settle).toBeTruthy();
  click(settle);
  expect(on.dispatched[0].payload).toEqual({ settleOldAnimations: false });

  const off = renderWith({ settleOldAnimations: false, gameEffectsEnabled: false });
  const settleOff = buttonOf(off.container, 'Гасить анимации старых сообщений');
  expect(settleOff.classList.contains('Button--disabled')).toBe(false);
  click(settleOff);
  expect(off.dispatched[0].payload).toEqual({ settleOldAnimations: true });
});

test('reset restores the defaults', () => {
  const { container, dispatched } = renderWith({
    gameEffects: { tremble: false, yell: false },
    gameEffectsEnabled: false,
    settleOldAnimations: false,
  });
  click(buttonOf(container, 'Сбросить эффекты'));
  const defaults = settingsReducer(undefined, { type: 'init' });
  expect(dispatched[0].payload).toEqual({
    gameEffects: defaults.gameEffects,
    gameEffectsEnabled: defaults.gameEffectsEnabled,
    settleOldAnimations: defaults.settleOldAnimations,
  });
  expect(dispatched[0].payload.settleOldAnimations).toBe(true);
});

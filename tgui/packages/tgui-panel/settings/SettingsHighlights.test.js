import { setGlobalStore } from 'common/redux';
import { act } from 'react';
import { createRoot } from 'react-dom/client';

import { MAX_HIGHLIGHT_SETTINGS } from '../chat/highlight';
import { SettingsHighlights } from './SettingsHighlights';

const mounted = [];

const GROUP_A = {
  id: 'a', enabled: true, highlightText: 'Ваня', highlightColor: '#ff0000',
  matchWord: false, matchCase: false, speechOnly: false, sound: false,
};
const GROUP_B = {
  id: 'b', enabled: true, highlightText: 'медбей', highlightColor: '#00ff00',
  matchWord: false, matchCase: false, speechOnly: false, sound: false,
};

const renderWith = highlightSettings => {
  const dispatched = [];
  setGlobalStore({
    getState: () => ({ settings: { theme: 'dark', highlightSettings } }),
    dispatch: action => dispatched.push(action),
  });
  const container = document.createElement('div');
  document.body.appendChild(container);
  const root = createRoot(container);
  act(() => root.render(<SettingsHighlights />));
  mounted.push({ root, container });
  return { container, dispatched };
};

const buttonsOf = (container, text) => [...container
  .querySelectorAll('.Button')]
  .filter(button => button.textContent.trim() === text);

const click = node => act(() => node.dispatchEvent(
  new MouseEvent('click', { bubbles: true })));

const lastList = dispatched => dispatched.at(-1).payload.highlightSettings;

beforeAll(() => {
  globalThis.IS_REACT_ACT_ENVIRONMENT = true;
});

afterEach(() => {
  for (const { root, container } of mounted.splice(0)) {
    act(() => root.unmount());
    container.remove();
  }
});

test('every group has its own text area and switches', () => {
  const { container } = renderWith([GROUP_A, GROUP_B]);
  expect(container.querySelectorAll('textarea')).toHaveLength(2);
  expect(buttonsOf(container, 'Только речь')).toHaveLength(2);
  expect(buttonsOf(container, 'Звук')).toHaveLength(2);
  expect(buttonsOf(container, 'Группа 2')).toHaveLength(1);
});

test('speech only toggles only its group', () => {
  const { container, dispatched } = renderWith([GROUP_A, GROUP_B]);
  click(buttonsOf(container, 'Только речь')[1]);
  expect(lastList(dispatched)).toEqual([
    GROUP_A,
    { ...GROUP_B, speechOnly: true },
  ]);
});

test('group checkbox disables the group', () => {
  const { container, dispatched } = renderWith([GROUP_A]);
  click(buttonsOf(container, 'Группа 1')[0]);
  expect(lastList(dispatched)).toEqual([{ ...GROUP_A, enabled: false }]);
});

test('add group appends a group with the next preset color', () => {
  const { container, dispatched } = renderWith([GROUP_A]);
  click(buttonsOf(container, 'Добавить группу')[0]);
  const list = lastList(dispatched);
  expect(list).toHaveLength(2);
  expect(list[0]).toBe(GROUP_A);
  expect(list[1]).toMatchObject({ enabled: true, highlightText: '',
    speechOnly: false, sound: false });
  expect(list[1].highlightColor).not.toBe(GROUP_A.highlightColor);
  expect(list[1].id).not.toBe(GROUP_A.id);
});

test('add group stops at the limit', () => {
  const list = Array.from({ length: MAX_HIGHLIGHT_SETTINGS },
    (_, i) => ({ ...GROUP_A, id: 'g' + i }));
  const { container } = renderWith(list);
  expect(buttonsOf(container, 'Добавить группу')[0].className)
    .toContain('Button--disabled');
});

test('arrow buttons reorder groups', () => {
  const { container, dispatched } = renderWith([GROUP_A, GROUP_B]);
  const down = container.querySelectorAll('.Button .fa-arrow-down')[0]
    .closest('.Button');
  click(down);
  expect(lastList(dispatched)).toEqual([GROUP_B, GROUP_A]);
});

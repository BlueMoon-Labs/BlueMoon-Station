import { setGlobalStore } from 'common/redux';
import { act } from 'react';
import { createRoot } from 'react-dom/client';

import { SettingsChannels } from './SettingsChannels';

const mounted = [];

const renderWith = typeOverrides => {
  const dispatched = [];
  setGlobalStore({
    getState: () => ({ settings: { theme: 'dark', typeOverrides } }),
    dispatch: action => dispatched.push(action),
  });
  const container = document.createElement('div');
  document.body.appendChild(container);
  const root = createRoot(container);
  act(() => root.render(<SettingsChannels />));
  mounted.push({ root, container });
  return { container, dispatched };
};

const rowOf = (container, name) => [...container.querySelectorAll('.Table__row')]
  .find(row => row.textContent.includes(name));

const clearButtonOf = row => row?.querySelector('.ColorInput__clear');

beforeAll(() => {
  globalThis.IS_REACT_ACT_ENVIRONMENT = true;
});

afterEach(() => {
  for (const { root, container } of mounted.splice(0)) {
    act(() => root.unmount());
    container.remove();
  }
});

test('clearing the stripe color keeps the rest of the row', () => {
  const { container, dispatched } = renderWith({
    radio: { border: '#111111', anim: 'teletype', flash: true },
  });
  const button = clearButtonOf(rowOf(container, 'Рация'));
  expect(button).toBeTruthy();
  act(() => button.dispatchEvent(new MouseEvent('click', { bubbles: true })));
  expect(dispatched).toHaveLength(1);
  expect(dispatched[0].payload.typeOverrides)
    .toEqual({ radio: { anim: 'teletype', flash: true } });
});

test('clear button keeps its place but is hidden without a color', () => {
  const { container } = renderWith({ radio: { border: '#111111' } });
  const set = clearButtonOf(rowOf(container, 'Рация'));
  const empty = clearButtonOf(rowOf(container, 'OOC'));
  expect(set).toBeTruthy();
  expect(set.style.visibility).not.toBe('hidden');
  expect(empty).toBeTruthy();
  expect(empty.style.visibility).toBe('hidden');
});

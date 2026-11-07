import { setGlobalStore } from 'common/redux';
import { act } from 'react';
import { createRoot } from 'react-dom/client';

import { clearChat } from '../chat/actions';
import { settingsReducer } from './reducer';
import { SettingsGeneral } from './SettingsPanel';

const DEFAULTS = settingsReducer(undefined, { type: 'init' });

let mounted;

beforeAll(() => {
  globalThis.IS_REACT_ACT_ENVIRONMENT = true;
});

afterEach(() => {
  act(() => mounted.root.unmount());
  mounted.container.remove();
});

const render = settings => {
  const dispatched = [];
  setGlobalStore({
    getState: () => ({ settings: { ...DEFAULTS, ...settings } }),
    dispatch: action => dispatched.push(action),
  });
  const container = document.createElement('div');
  document.body.appendChild(container);
  const root = createRoot(container);
  act(() => root.render(<SettingsGeneral />));
  mounted = { root, container };
  return { container, dispatched };
};

const findButton = (container, text) => [...container.querySelectorAll('.Button')]
  .find(node => node.textContent.trim() === text);

const click = node => act(() => {
  node.dispatchEvent(new MouseEvent('click', { bubbles: true }));
});

test('clear chat asks once more before clearing', () => {
  const { container, dispatched } = render();
  click(findButton(container, 'Очистить чат'));
  expect(dispatched.some(action => action.type === clearChat.type)).toBe(false);
  click(findButton(container, 'Точно очистить?'));
  expect(dispatched.filter(action => action.type === clearChat.type))
    .toHaveLength(1);
});

test('shows the chosen message limit', () => {
  const { container } = render({ visibleMessageLimit: 500 });
  expect(container.textContent).toContain('Лимит чата');
  expect(container.textContent).toContain('500');
});

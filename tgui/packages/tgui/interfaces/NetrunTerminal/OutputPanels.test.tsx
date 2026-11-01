import { act, fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../../backend';
import { debugReducer } from '../../debug';
import { ConsoleLog, NetChat } from './Panels';

const setup = () => {
  (global as any).Byond = { topic: jest.fn(), winset: () => {} };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'NetrunTerminal' }, data: {
    log: [{ text: 'First', kind: 'label' }], networks: [], storage: { files: [] },
    chat: { handle: 'runner', messages: ['First'] }, uplink: true,
  } }));
  return (data) => act(() => store.dispatch(backendUpdate({ data })));
};
const sizeScroller = (element: HTMLElement) => Object.defineProperties(element, {
  scrollHeight: { configurable: true, value: 1000 },
  clientHeight: { configurable: true, value: 200 },
});

test('new terminal output preserves reading position and offers an explicit return to live output', () => {
  const update = setup();
  const panel = render(<ConsoleLog />);
  const log = panel.getByLabelText('Журнал терминала');
  sizeScroller(log);
  log.scrollTop = 300;
  fireEvent.scroll(log);
  update({ log: [{ text: 'Second', kind: 'label' }] });
  panel.rerender(<ConsoleLog />);
  expect(log.scrollTop).toBe(300);
  fireEvent.click(panel.getByText('К новым сообщениям'));
  expect(log.scrollTop).toBe(1000);
  expect(panel.queryByText('К новым сообщениям')).toBeNull();
});

test('a capped chat advances at the bottom even when the message count is unchanged', () => {
  const update = setup();
  const panel = render(<NetChat />);
  const log = panel.getByLabelText('Сообщения noosphere');
  sizeScroller(log);
  log.scrollTop = 800;
  fireEvent.scroll(log);
  update({ chat: { handle: 'runner', messages: ['Second'] } });
  panel.rerender(<NetChat />);
  expect(log.scrollTop).toBe(1000);
  expect(panel.getByText('Second')).toBeTruthy();
});

test('returning to a hidden chat follows the latest output while a manual reading position survives navigation', () => {
  const update = setup();
  const panel = render(<NetChat active={false} />);
  const log = panel.getByLabelText('Сообщения noosphere');
  sizeScroller(log);
  update({ chat: { handle: 'runner', messages: ['Second'] } });
  expect(log.scrollTop).toBe(0);
  panel.rerender(<NetChat active />);
  expect(log.scrollTop).toBe(1000);
  log.scrollTop = 200;
  fireEvent.scroll(log);
  panel.rerender(<NetChat active={false} />);
  panel.rerender(<NetChat active />);
  expect(log.scrollTop).toBe(200);
  expect(panel.queryByText('К новым сообщениям')).toBeNull();
});

import { fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../../backend';
import { debugReducer } from '../../debug';
import { ConsoleLog } from './TerminalConsole';

beforeEach(() => {
	let time = Date.now();
	jest.spyOn(Date, 'now').mockImplementation(() => { time += 100; return time; });
});
afterEach(() => jest.restoreAllMocks());

const sent = (topic: jest.Mock) => topic.mock.calls.filter(([message]) => message.type === 'act/cli')
	.map(([message]) => JSON.parse(message.payload).text);

const setup = () => {
  const topic = jest.fn();
  (global as any).Byond = { topic, winset: () => {} };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'NetrunTerminal' }, data: {
    log: [], networks: [], storage: { files: [{ uid: '1', name: 'My shield.exe', kind: 'program' }] },
    cli: { verbs: [
      { id: 'exec', args: '<file>', desc: 'Launch the current filename', completion_key: 'files' },
      { id: 'help', args: '', desc: 'Command help' },
      { id: 'hello', args: '', desc: 'Other command' },
    ], completions: { files: ['My shield.exe'] } },
  } }));
  return topic;
};

test('file completion inserts a quoted current name and Enter executes that same argument', () => {
  const topic = setup();
  const panel = render(<ConsoleLog />);
  const input = panel.getByLabelText('Командная строка') as HTMLInputElement;
  fireEvent.change(input, { target: { value: 'exec My' } });
  fireEvent.keyDown(input, { key: 'Tab' });
  expect(input.value).toBe('exec "My shield.exe" ');
  fireEvent.keyDown(input, { key: 'Enter' });
  expect(sent(topic)).toEqual(['exec "My shield.exe"']);
  expect(input.value).toBe('');
});

test('ambiguous completions are inspectable and keyboard-selectable before executing', () => {
  const topic = setup();
  const panel = render(<ConsoleLog />);
  const input = panel.getByLabelText('Командная строка') as HTMLInputElement;
  fireEvent.change(input, { target: { value: 'he' } });
  fireEvent.keyDown(input, { key: 'Tab' });
  expect(panel.getByText(/^ДОПОЛНЕНИЕ/)).toBeTruthy();
  expect(input.value).toBe('he');
  fireEvent.keyDown(input, { key: 'ArrowDown' });
  fireEvent.keyDown(input, { key: 'Enter' });
  expect(input.value).toBe('hello ');
  expect(topic).not.toHaveBeenCalled();
  fireEvent.keyDown(input, { key: 'Enter' });
  expect(sent(topic)).toEqual(['hello']);
});

test('history search recalls without running and Ctrl+L preserves the current draft', () => {
  const topic = setup();
  const panel = render(<ConsoleLog />);
  const input = panel.getByLabelText('Командная строка') as HTMLInputElement;
  fireEvent.change(input, { target: { value: 'exec "My shield.exe"' } });
  fireEvent.keyDown(input, { key: 'Enter' });
  fireEvent.change(input, { target: { value: 'shield' } });
  fireEvent.keyDown(input, { key: 'r', ctrlKey: true });
  expect(panel.getByText('ПОИСК В ИСТОРИИ', { exact: false })).toBeTruthy();
  fireEvent.keyDown(input, { key: 'Enter' });
  expect(input.value).toBe('exec "My shield.exe"');
  expect(topic).toHaveBeenCalledTimes(1);
  fireEvent.keyDown(input, { key: 'l', ctrlKey: true });
  expect(input.value).toBe('exec "My shield.exe"');
  expect(sent(topic)).toEqual(['exec "My shield.exe"', 'clear']);
});

test('Enter on an empty history search never launches the search query', () => {
  const topic = setup();
  const panel = render(<ConsoleLog />);
  const input = panel.getByLabelText('Командная строка') as HTMLInputElement;
  fireEvent.change(input, { target: { value: 'unmatched search' } });
  fireEvent.keyDown(input, { key: 'r', ctrlKey: true });
  fireEvent.keyDown(input, { key: 'Enter' });
  expect(topic).not.toHaveBeenCalled();
  expect(input.value).toBe('unmatched search');
  fireEvent.keyDown(input, { key: 'Escape' });
  fireEvent.keyDown(input, { key: 'Enter' });
  expect(sent(topic)).toEqual(['unmatched search']);
});

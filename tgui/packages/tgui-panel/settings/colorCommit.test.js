import { debouncedColorCommit } from './colorCommit';

beforeEach(() => {
  jest.useFakeTimers();
});

afterEach(() => {
  jest.useRealTimers();
});

test('commits the value picked, not the one after a re-render', () => {
  const commit = jest.fn();
  const input = { value: '#3a9a5c' };
  debouncedColorCommit(input, commit);
  // Перерендер контролируемого поля до срабатывания таймера.
  input.value = '#000000';
  jest.advanceTimersByTime(250);
  expect(commit).toHaveBeenCalledTimes(1);
  expect(commit).toHaveBeenCalledWith('#3a9a5c');
});

test('only the last value of a drag is committed', () => {
  const commit = jest.fn();
  const input = { value: '#111111' };
  debouncedColorCommit(input, commit);
  input.value = '#222222';
  debouncedColorCommit(input, commit);
  jest.advanceTimersByTime(250);
  expect(commit).toHaveBeenCalledTimes(1);
  expect(commit).toHaveBeenCalledWith('#222222');
});

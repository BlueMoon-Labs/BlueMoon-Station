/**
 * Behavioral tests for RestrictedInput after the React migration.
 * The key regression this guards against: clamping must happen on
 * commit (blur or Enter), never per keystroke, otherwise typing 55
 * with minValue=10 becomes impossible (the upstream #80490 bug class).
 */
import { fireEvent, render } from '@testing-library/react';

import { RestrictedInput } from './RestrictedInput';

const getInput = container => container.querySelector('input');

describe('RestrictedInput', () => {
  // React warns (console.error) when component-only props leak onto DOM
  // elements, and dedupes each warning per prop name globally - so the
  // spy must cover every test, not just a dedicated one, to catch the
  // first occurrence.
  let errorSpy;
  beforeEach(() => {
    errorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
  });
  afterEach(() => {
    const calls = errorSpy.mock.calls;
    errorSpy.mockRestore();
    expect(calls).toEqual([]);
  });

  test('mounts with the clamped initial value', () => {
    const { container } = render(
      <RestrictedInput value={50} minValue={0} maxValue={10} />,
    );
    expect(getInput(container).value).toBe('10');
  });

  test('typing below the minimum is not clamped mid-edit', () => {
    const onChange = jest.fn();
    const { container } = render(
      <RestrictedInput
        value={20}
        minValue={10}
        maxValue={100}
        onChange={onChange}
      />,
    );
    const input = getInput(container);
    fireEvent.focus(input);
    // User wants to type 55: the first keystroke produces "5",
    // which is below minValue and must stay as-is while editing.
    fireEvent.input(input, { target: { value: '5' } });
    expect(input.value).toBe('5');
    fireEvent.input(input, { target: { value: '55' } });
    expect(input.value).toBe('55');
    expect(onChange).not.toHaveBeenCalled();
  });

  test('blur clamps and commits once', () => {
    const onChange = jest.fn();
    const { container } = render(
      <RestrictedInput
        value={20}
        minValue={10}
        maxValue={100}
        onChange={onChange}
      />,
    );
    const input = getInput(container);
    fireEvent.focus(input);
    fireEvent.input(input, { target: { value: '5' } });
    fireEvent.blur(input);
    expect(input.value).toBe('10');
    expect(onChange).toHaveBeenCalledTimes(1);
    expect(onChange).toHaveBeenCalledWith(expect.anything(), 10);
  });

  test('Enter clamps, commits once, and the follow-up blur does not double-fire', () => {
    const onChange = jest.fn();
    const onEnter = jest.fn();
    const { container } = render(
      <RestrictedInput
        value={20}
        minValue={10}
        maxValue={100}
        onChange={onChange}
        onEnter={onEnter}
      />,
    );
    const input = getInput(container);
    fireEvent.focus(input);
    fireEvent.input(input, { target: { value: '500' } });
    fireEvent.keyDown(input, { key: 'Enter' });
    // jsdom does not blur automatically on e.target.blur() inside the
    // handler chain, so simulate the follow-up blur explicitly.
    fireEvent.blur(input);
    expect(input.value).toBe('100');
    expect(onChange).toHaveBeenCalledTimes(1);
    expect(onChange).toHaveBeenCalledWith(expect.anything(), 100);
    expect(onEnter).toHaveBeenCalledTimes(1);
  });

  test('component-only props do not leak to the DOM', () => {
    // onEscape is not exercised by the other tests, so render it here;
    // the afterEach spy assertion catches any leak warning.
    render(
      <RestrictedInput
        value={5}
        minValue={0}
        maxValue={10}
        onEscape={() => {}}
      />,
    );
  });

  test('blur without modification does not fire onChange', () => {
    const onChange = jest.fn();
    const { container } = render(
      <RestrictedInput
        value={20}
        minValue={10}
        maxValue={100}
        onChange={onChange}
      />,
    );
    const input = getInput(container);
    fireEvent.focus(input);
    fireEvent.blur(input);
    expect(onChange).not.toHaveBeenCalled();
  });
});

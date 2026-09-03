/**
 * Behavioral tests for the uncontrolled Input component after the
 * React migration. The contract: onInput fires per keystroke,
 * onChange fires once on commit (blur or Enter), Escape reverts.
 */
import { fireEvent, render } from '@testing-library/react';

import { Input } from './Input';

const getInput = container => container.querySelector('input');

describe('Input', () => {
  test('syncs initial value into the DOM imperatively', () => {
    const { container } = render(<Input value="hello" />);
    expect(getInput(container).value).toBe('hello');
  });

  test('typing fires onInput per keystroke, but not onChange', () => {
    const onInput = jest.fn();
    const onChange = jest.fn();
    const { container } = render(
      <Input value="" onInput={onInput} onChange={onChange} />,
    );
    const input = getInput(container);
    fireEvent.focus(input);
    fireEvent.input(input, { target: { value: 'a' } });
    fireEvent.input(input, { target: { value: 'ab' } });
    expect(onInput).toHaveBeenCalledTimes(2);
    expect(onInput).toHaveBeenLastCalledWith(expect.anything(), 'ab');
    expect(onChange).not.toHaveBeenCalled();
  });

  test('blur commits the value through onChange', () => {
    const onChange = jest.fn();
    const { container } = render(<Input value="" onChange={onChange} />);
    const input = getInput(container);
    fireEvent.focus(input);
    fireEvent.input(input, { target: { value: 'done' } });
    fireEvent.blur(input);
    expect(onChange).toHaveBeenCalledTimes(1);
    expect(onChange).toHaveBeenCalledWith(expect.anything(), 'done');
  });

  test('Enter commits via onChange and onEnter', () => {
    const onChange = jest.fn();
    const onEnter = jest.fn();
    const { container } = render(
      <Input value="" onChange={onChange} onEnter={onEnter} />,
    );
    const input = getInput(container);
    fireEvent.focus(input);
    fireEvent.input(input, { target: { value: 'go' } });
    fireEvent.keyDown(input, { key: 'Enter' });
    expect(onChange).toHaveBeenCalledWith(expect.anything(), 'go');
    expect(onEnter).toHaveBeenCalledWith(expect.anything(), 'go');
  });

  test('Escape reverts to the value prop', () => {
    const { container } = render(<Input value="original" />);
    const input = getInput(container);
    fireEvent.focus(input);
    fireEvent.input(input, { target: { value: 'changed' } });
    fireEvent.keyDown(input, { key: 'Escape' });
    expect(input.value).toBe('original');
  });

  test('external value update syncs the DOM when not editing', () => {
    const { container, rerender } = render(<Input value="one" />);
    const input = getInput(container);
    expect(input.value).toBe('one');
    rerender(<Input value="two" />);
    expect(input.value).toBe('two');
  });

  test('external value update does not clobber the input while editing', () => {
    const { container, rerender } = render(<Input value="one" />);
    const input = getInput(container);
    fireEvent.focus(input);
    fireEvent.input(input, { target: { value: 'typing' } });
    rerender(<Input value="two" />);
    expect(input.value).toBe('typing');
  });
});

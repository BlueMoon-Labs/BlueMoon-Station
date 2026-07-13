/**
 * Behavioral tests for TextArea after the React migration.
 * Commit semantics: onInput per keystroke, onChange once on blur,
 * Escape reverts, Tab inserts indentation, paste respects maxLength.
 */
import { fireEvent, render } from '@testing-library/react';

import { TextArea } from './TextArea';

const getTextArea = container => container.querySelector('textarea');

describe('TextArea', () => {
  test('syncs initial value into the DOM imperatively', () => {
    const { container } = render(<TextArea value="hello" />);
    expect(getTextArea(container).value).toBe('hello');
  });

  test('typing fires onInput per keystroke, but not onChange', () => {
    const onInput = jest.fn();
    const onChange = jest.fn();
    const { container } = render(
      <TextArea value="" onInput={onInput} onChange={onChange} />,
    );
    const textarea = getTextArea(container);
    fireEvent.focus(textarea);
    fireEvent.input(textarea, { target: { value: 'a' } });
    fireEvent.input(textarea, { target: { value: 'ab' } });
    expect(onInput).toHaveBeenCalledTimes(2);
    expect(onChange).not.toHaveBeenCalled();
  });

  test('blur commits the value through onChange exactly once', () => {
    const onChange = jest.fn();
    const { container } = render(<TextArea value="" onChange={onChange} />);
    const textarea = getTextArea(container);
    fireEvent.focus(textarea);
    fireEvent.input(textarea, { target: { value: 'note text' } });
    fireEvent.blur(textarea);
    expect(onChange).toHaveBeenCalledTimes(1);
    expect(onChange).toHaveBeenCalledWith(expect.anything(), 'note text');
  });

  test('Escape reverts to the value prop', () => {
    const { container } = render(<TextArea value="original" />);
    const textarea = getTextArea(container);
    fireEvent.focus(textarea);
    fireEvent.input(textarea, { target: { value: 'changed' } });
    fireEvent.keyDown(textarea, { key: 'Escape' });
    expect(textarea.value).toBe('original');
  });

  test('Tab inserts a tab character at the cursor', () => {
    const { container } = render(<TextArea value="" />);
    const textarea = getTextArea(container);
    fireEvent.focus(textarea);
    fireEvent.input(textarea, { target: { value: 'ab' } });
    textarea.selectionStart = 1;
    textarea.selectionEnd = 1;
    fireEvent.keyDown(textarea, { key: 'Tab' });
    expect(textarea.value).toBe('a\tb');
  });

  test('paste inserts clipboard text and respects maxLength', () => {
    const onInput = jest.fn();
    const { container } = render(
      <TextArea value="" maxLength={5} onInput={onInput} />,
    );
    const textarea = getTextArea(container);
    fireEvent.focus(textarea);
    fireEvent.paste(textarea, {
      clipboardData: { getData: () => '1234567890' },
    });
    expect(textarea.value).toBe('12345');
    expect(onInput).toHaveBeenCalledWith(expect.anything(), '12345');
  });
});

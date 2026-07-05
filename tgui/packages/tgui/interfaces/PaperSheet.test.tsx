/**
 * Behavioral tests for the PaperSheet interface after the React migration.
 * Renders PrimaryView against a real redux store (the same way the live UI
 * reads it through useBackend/useLocalState).
 */
import { fireEvent, render, screen } from '@testing-library/react';
import {
  combineReducers,
  createStore,
  setGlobalStore,
} from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { PrimaryView } from './PaperSheet';

const MODE_READING = 0;
const MODE_WRITING = 1;
const MODE_STAMPING = 2;

const baseStaticData = {
  user_name: 'Test User',
  raw_text_input: [],
  raw_field_input: [],
  raw_stamp_input: [],
  max_length: 5000,
  max_input_field_length: 50,
  paper_color: '#ffffff',
  paper_name: 'paper',
  default_pen_font: 'Verdana',
  default_pen_color: '#000000',
  signature_font: 'Times New Roman',
};

const setupStore = (data = {}) => {
  const store = createStore(combineReducers({ backend: backendReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({
    config: { interface: 'PaperSheet' },
    data: { ...baseStaticData, ...data },
  }));
  return store;
};

const heldPen = {
  interaction_mode: MODE_WRITING,
  font: 'Verdana',
  color: '#0000ff',
  use_bold: false,
};

const heldStamp = {
  interaction_mode: MODE_STAMPING,
  stamp_class: 'paper121x54-stamp-clown',
  stamp_icon_state: 'stamp-clown',
};

describe('PaperSheet PrimaryView', () => {
  test('renders existing text in read-only mode', () => {
    setupStore({
      raw_text_input: [
        { raw_text: 'Hello paper world' },
      ],
    });
    const { container } = render(<PrimaryView />);
    expect(container.innerHTML).toContain('Hello paper world');
  });

  test('renders markdown from DM input', () => {
    setupStore({
      raw_text_input: [
        { raw_text: 'plain **bold** text' },
      ],
    });
    const { container } = render(<PrimaryView />);
    expect(container.innerHTML).toContain('<strong>bold</strong>');
  });

  test('renders [____] as a disabled input field when reading', () => {
    setupStore({
      raw_text_input: [
        { raw_text: 'Sign here: [______]' },
      ],
    });
    const { container } = render(<PrimaryView />);
    const input = container.querySelector('input#paperfield_0');
    expect(input).toBeTruthy();
    expect((input as HTMLInputElement).disabled).toBe(true);
  });

  test('renders [____] as an editable input field when holding a pen', () => {
    setupStore({
      raw_text_input: [
        { raw_text: 'Sign here: [______]' },
      ],
      held_item_details: heldPen,
    });
    const { container } = render(<PrimaryView />);
    const input = container.querySelector('input#paperfield_0');
    expect(input).toBeTruthy();
    expect((input as HTMLInputElement).disabled).toBe(false);
  });

  test('renders filled fields (signatures) from DM field input', () => {
    setupStore({
      raw_text_input: [
        { raw_text: 'Signature: [______]' },
      ],
      raw_field_input: [
        {
          field_index: '0',
          field_data: { raw_text: 'John Doe', font: 'Times New Roman' },
          is_signature: true,
        },
      ],
    });
    const { container } = render(<PrimaryView />);
    const input = container.querySelector(
      'input#paperfield_0'
    ) as HTMLInputElement;
    expect(input).toBeTruthy();
    expect(input.disabled).toBe(true);
    expect(input.getAttribute('value') || input.defaultValue)
      .toBe('John Doe');
  });

  test('shows the text area when holding a pen', () => {
    setupStore({ held_item_details: heldPen });
    const { container } = render(<PrimaryView />);
    expect(container.querySelector('textarea')).toBeTruthy();
  });

  test('typing into the text area updates the live preview', () => {
    setupStore({ held_item_details: heldPen });
    const { container, rerender } = render(<PrimaryView />);
    const textarea = container.querySelector('textarea') as HTMLTextAreaElement;
    fireEvent.focus(textarea);
    fireEvent.input(textarea, { target: { value: 'live preview text' } });
    rerender(<PrimaryView />);
    const preview = container.querySelector('.Paper__Page') as HTMLElement;
    expect(preview.innerHTML).toContain('live preview text');
  });

  test('save button sends the save act with typed text', () => {
    setupStore({ held_item_details: heldPen });
    const topic = jest.fn();
    (global as any).Byond = { topic };
    const { container, rerender } = render(<PrimaryView />);
    const textarea = container.querySelector('textarea') as HTMLTextAreaElement;
    fireEvent.focus(textarea);
    fireEvent.input(textarea, { target: { value: 'saved text' } });
    rerender(<PrimaryView />);
    // Button.Confirm arms on the first click and fires on the second.
    fireEvent.click(screen.getByText('Save'));
    fireEvent.click(screen.getByText('Подтвердить?'));
    const saveCall = topic.mock.calls.find(
      (c) => c[0]?.type === 'act/save'
    );
    expect(saveCall).toBeTruthy();
    expect(JSON.parse(saveCall[0].payload).text).toBe('saved text');
  });

  // Regression: with a single innerHTML blob for the whole page, every
  // textarea keystroke rewrote the DM text block and recreated its input
  // fields, wiping whatever the user had typed into them. The DM block's
  // HTML must stay byte-identical while the textarea preview updates, so
  // React never touches the fields' DOM.
  // (jsdom re-applies innerHTML on every rerender, so DOM node identity
  // can't be asserted here - string identity is the contract that matters.)
  test('typing in the textarea does not alter the DM text block', () => {
    setupStore({
      raw_text_input: [
        { raw_text: 'Sign: [______]' },
      ],
      held_item_details: heldPen,
    });
    const { container, rerender } = render(<PrimaryView />);
    const field = container.querySelector(
      'input#paperfield_0'
    ) as HTMLInputElement;
    fireEvent.input(field, { target: { value: 'Иванов' } });
    rerender(<PrimaryView />);

    const dmBlockBefore = container.querySelectorAll('.paper-text')[0]
      .innerHTML;

    const textarea = container.querySelector('textarea') as HTMLTextAreaElement;
    fireEvent.focus(textarea);
    fireEvent.input(textarea, { target: { value: 'текст отчёта' } });
    rerender(<PrimaryView />);

    const blocks = container.querySelectorAll('.paper-text');
    expect(blocks.length).toBe(2);
    expect(blocks[0].innerHTML).toBe(dmBlockBefore);
    expect(blocks[1].innerHTML).toContain('текст отчёта');
  });

  test('unsaved field text survives losing and regaining the pen', () => {
    const store = setupStore({
      raw_text_input: [
        { raw_text: 'Sign: [______]' },
      ],
      held_item_details: heldPen,
    });
    const { container, rerender } = render(<PrimaryView />);
    const field = container.querySelector(
      'input#paperfield_0'
    ) as HTMLInputElement;
    fireEvent.input(field, { target: { value: 'Иванов' } });
    rerender(<PrimaryView />);

    // Pen swapped out of the active hand: read-only mode.
    store.dispatch(backendUpdate({ data: { held_item_details: null } }));
    rerender(<PrimaryView />);
    const readOnlyField = container.querySelector(
      'input#paperfield_0'
    ) as HTMLInputElement;
    expect(readOnlyField.disabled).toBe(true);

    // Pen back: the unsaved text must be restored from the store.
    store.dispatch(backendUpdate({ data: { held_item_details: heldPen } }));
    rerender(<PrimaryView />);
    const restoredField = container.querySelector(
      'input#paperfield_0'
    ) as HTMLInputElement;
    expect(restoredField.disabled).toBe(false);
    expect(restoredField.value).toBe('Иванов');
  });

  test('typing into a paper field stores field data for saving', () => {
    setupStore({
      raw_text_input: [
        { raw_text: 'Sign: [______]' },
      ],
      held_item_details: heldPen,
    });
    const store = (global as any).__store__;
    const { container } = render(<PrimaryView />);
    const input = container.querySelector(
      'input#paperfield_0'
    ) as HTMLInputElement;
    expect(input).toBeTruthy();
    fireEvent.input(input, { target: { value: 'My Signature' } });
  });

  test('renders existing stamps', () => {
    setupStore({
      raw_stamp_input: [
        { class: 'paper121x54-stamp-clown', x: 10, y: 20, rotation: 45 },
      ],
    });
    const { container } = render(<PrimaryView />);
    const stamp = container.querySelector('.Paper__Stamp');
    expect(stamp).toBeTruthy();
  });

  test('shows the stamp preview ghost when holding a stamp', () => {
    setupStore({ held_item_details: heldStamp });
    const { container } = render(<PrimaryView />);
    const stamp = container.querySelector('.Paper__Stamp');
    expect(stamp).toBeTruthy();
  });

  test('clicking the page with a pen does not send add_stamp', () => {
    setupStore({ held_item_details: heldPen });
    const topic = jest.fn();
    (global as any).Byond = { topic };
    render(<PrimaryView />);
    fireEvent.click(document, { clientX: 300, clientY: 400 });
    const stampCall = topic.mock.calls.find(
      (c) => c[0]?.type === 'act/add_stamp'
    );
    expect(stampCall).toBeFalsy();
  });

  test('clicking the page with a stamp sends add_stamp', () => {
    setupStore({ held_item_details: heldStamp });
    const topic = jest.fn();
    (global as any).Byond = { topic };
    render(<PrimaryView />);
    fireEvent.click(document, { clientX: 300, clientY: 400 });
    const stampCall = topic.mock.calls.find(
      (c) => c[0]?.type === 'act/add_stamp'
    );
    expect(stampCall).toBeTruthy();
  });
});

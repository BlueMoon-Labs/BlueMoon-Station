import { applyRecommended, createChannelEditor, dropStrayTint, isEntryEdited, patchTypeOverride, resetTypeOverride } from './channelsModel';
import { RECOMMENDED_TYPE_OVERRIDES } from './constants';

test('patch merges into entry', () => {
  const next = patchTypeOverride({ radio: { border: '#111111' } }, 'radio', { tint: true });
  expect(next.radio).toEqual({ border: '#111111', tint: true });
});

test('patch does not mutate input', () => {
  const input = { radio: { border: '#111111' } };
  patchTypeOverride(input, 'radio', { tint: true });
  expect(input.radio.tint).toBeUndefined();
});

test('clearing the stripe drops its tint', () => {
  const next = patchTypeOverride(
    { radio: { border: '#111111', tint: true, anim: 'fadein' } },
    'radio', { border: '' });
  expect(next.radio).toEqual({ anim: 'fadein' });
  expect(patchTypeOverride({}, 'ooc', { tint: true })).toEqual({});
});

test('stray tint without a stripe is dropped from stored data', () => {
  expect(dropStrayTint({
    radio: { tint: true, anim: 'fadein' },
    ooc: { tint: true },
    looc: { border: '#222222', tint: true },
  })).toEqual({
    radio: { anim: 'fadein' },
    looc: { border: '#222222', tint: true },
  });
});

test('reset removes the entry', () => {
  expect(resetTypeOverride({ radio: { border: '#111111' }, ooc: {} }, 'radio'))
    .toEqual({ ooc: {} });
});

test('recommended keeps user entries for other types', () => {
  const next = applyRecommended({ looc: { border: '#222222' } });
  expect(next.looc).toEqual({ border: '#222222' });
  expect(next.adminpm).toEqual(RECOMMENDED_TYPE_OVERRIDES.adminpm);
});

test('recommended keeps user fields it does not set', () => {
  const input = { radio: { border: '#111111', tint: true, anim: 'teletype' } };
  const next = applyRecommended(input);
  expect(next.radio).toEqual({
    ...input.radio,
    ...RECOMMENDED_TYPE_OVERRIDES.radio,
  });
  expect(next.radio.anim).toBe('teletype');
  expect(input.radio.border).toBe('#111111');
});

describe('createChannelEditor', () => {
  test('delayed patch builds on the latest commit', () => {
    const commits = [];
    const editor = createChannelEditor(next => commits.push(next));
    editor.sync({});
    // Колбэк, захваченный до клика, как отложенная запись цвета.
    const delayedBorder = value => editor.patch('radio', { border: value });
    editor.patch('radio', { flash: true });
    delayedBorder('#111111');
    expect(commits[commits.length - 1].radio)
      .toEqual({ flash: true, border: '#111111' });
  });

  test('sync replaces state from the store', () => {
    const commits = [];
    const editor = createChannelEditor(next => commits.push(next));
    editor.sync({ ooc: { border: '#222222' }, radio: { tint: true } });
    editor.reset('ooc');
    expect(commits[0]).toEqual({ radio: { tint: true } });
  });

  test('recommended and clear go through the same state', () => {
    const commits = [];
    const editor = createChannelEditor(next => commits.push(next));
    editor.sync({ looc: { border: '#222222' } });
    editor.recommended();
    editor.patch('looc', { flash: true });
    expect(commits[1].looc).toEqual({ border: '#222222', flash: true });
    expect(commits[1].adminpm).toEqual(RECOMMENDED_TYPE_OVERRIDES.adminpm);
    editor.clear();
    editor.patch('ooc', { flash: true });
    expect(commits[3]).toEqual({ ooc: { flash: true } });
  });
});

describe('empty fields', () => {
  test('toggling flash on and off leaves no entry', () => {
    const on = patchTypeOverride({}, 'radio', { flash: true });
    expect(patchTypeOverride(on, 'radio', { flash: false })).toEqual({});
  });

  test('cleared fields are dropped, meaningful ones kept', () => {
    const input = { radio: { border: '#111111', anim: 'teletype', flash: true } };
    expect(patchTypeOverride(input, 'radio', { border: '', anim: '' }))
      .toEqual({ radio: { flash: true } });
    expect(patchTypeOverride({}, 'ooc', { anim: 'none' }))
      .toEqual({ ooc: { anim: 'none' } });
  });

  test('edited only with a visible setting', () => {
    expect(isEntryEdited(undefined)).toBe(false);
    expect(isEntryEdited({ flash: false, border: '', anim: '' })).toBe(false);
    expect(isEntryEdited({ tint: true })).toBe(false);
    expect(isEntryEdited({ border: '#111111' })).toBe(true);
    expect(isEntryEdited({ anim: 'none' })).toBe(true);
    expect(isEntryEdited({ flash: true })).toBe(true);
  });
});

import { setGlobalStore } from 'common/redux';
import fs from 'fs';
import path from 'path';
import { act } from 'react';
import { createRoot } from 'react-dom/client';

import { RADIO_JOB_COLOR_MODES, RADIO_JOB_DEFAULTS, RADIO_JOB_GROUPS, RADIO_JOB_HEAD_MARKS, RADIO_JOB_IDS, RADIO_JOB_PALETTE } from './radioJobs';
import { settingsReducer } from './reducer';
import { SettingsRadioJobs } from './SettingsRadioJobs';

const mounted = [];

const renderWith = settings => {
  const dispatched = [];
  setGlobalStore({
    getState: () => ({ settings: { ...RADIO_JOB_DEFAULTS, ...settings } }),
    dispatch: action => dispatched.push(action),
  });
  const container = document.createElement('div');
  document.body.appendChild(container);
  const root = createRoot(container);
  act(() => root.render(<SettingsRadioJobs />));
  mounted.push({ root, container });
  return { container, dispatched };
};

const buttonOf = (container, text) => [...container.querySelectorAll('.Button')]
  .find(button => button.textContent.trim().startsWith(text));

const click = node => act(() => node.dispatchEvent(
  new MouseEvent('click', { bubbles: true })));

beforeAll(() => {
  globalThis.IS_REACT_ACT_ENVIRONMENT = true;
});

afterEach(() => {
  for (const { root, container } of mounted.splice(0)) {
    act(() => root.unmount());
    container.remove();
  }
});

test('defaults: color by department, head icon, names plain', () => {
  const state = settingsReducer(undefined, { type: 'init' });
  expect(state.radioJobColorMode).toBe('department');
  expect(state.radioJobHeadMark).toBe('icon');
  expect(state.radioJobColorNames).toBe(false);
  expect(state.radioJobColors).toEqual({});
  expect(state.showRadioJobs).toBe(true);
});

test('every mode and head mark button sends its id', () => {
  let now = Date.now();
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  for (const mode of RADIO_JOB_COLOR_MODES) {
    const { container, dispatched } = renderWith({});
    click(buttonOf(container, mode.name));
    expect(dispatched.at(-1).payload).toEqual({ radioJobColorMode: mode.id });
  }
  for (const mark of RADIO_JOB_HEAD_MARKS) {
    const { container, dispatched } = renderWith({});
    click(buttonOf(container, mark.name));
    expect(dispatched.at(-1).payload).toEqual({ radioJobHeadMark: mark.id });
  }
});

test('every option explains itself in a tooltip', () => {
  for (const option of [...RADIO_JOB_COLOR_MODES, ...RADIO_JOB_HEAD_MARKS]) {
    expect(option.tooltip.length).toBeGreaterThan(10);
  }
});

test('show and name checkboxes toggle their settings', () => {
  const { container, dispatched } = renderWith({ showRadioJobs: true });
  click(buttonOf(container, 'Должности в рации'));
  expect(dispatched.at(-1).payload).toEqual({ showRadioJobs: false });
  click(buttonOf(container, 'Имя в цвет отдела'));
  expect(dispatched.at(-1).payload).toEqual({ radioJobColorNames: true });
});

test('color list shows a sample tag per department and resets', () => {
  const { container, dispatched } = renderWith({
    radioJobColors: { med: '#00ff00' },
  });
  expect(buttonOf(container, 'Сбросить цвета').className)
    .not.toContain('Button--disabled');
  click(buttonOf(container, 'Цвета отделов'));
  const list = container.querySelector('.SettingsRadioJobs__colors');
  expect(list.classList.contains('Chat')).toBe(true);
  expect(list.style.getPropertyValue('--rj-med')).toBe('#00ff00');
  for (const id of RADIO_JOB_IDS) {
    expect(list.querySelector('.radiojob.radiojob-' + id)).not.toBeNull();
  }
  click(buttonOf(container, 'Сбросить цвета'));
  expect(dispatched.at(-1).payload).toEqual({ radioJobColors: {} });
  click(buttonOf(container, 'Сбросить должности'));
  expect(dispatched.at(-1).payload).toEqual({
    ...RADIO_JOB_DEFAULTS,
    showRadioJobs: true,
  });
});

test('empty swatch shows the default color of the theme', () => {
  const swatchOf = theme => {
    const { container } = renderWith({ theme });
    click(buttonOf(container, 'Цвета отделов'));
    return container.querySelector('.SettingsRadioJobs__colors input[type=color]')
      .value;
  };
  const first = RADIO_JOB_PALETTE.find(
    entry => entry.id === RADIO_JOB_GROUPS[0].ids[0]);
  expect(swatchOf('dark')).toBe(first.dark);
  expect(swatchOf('default')).toBe(first.light);
});

test('legacy mode swatches show the old faction colors', () => {
  const { container } = renderWith({ radioJobColorMode: 'legacy' });
  click(buttonOf(container, 'Цвета отделов'));
  const swatches = [...container.querySelectorAll(
    '.SettingsRadioJobs__colors input[type=color]')].map(input => input.value);
  const order = RADIO_JOB_GROUPS.flatMap(group => group.ids);
  for (const [id, color] of [['synd', '#8f4a4b'], ['sol', '#3434fd'],
    ['nri', '#ff4444']]) {
    expect([id, swatches[order.indexOf(id)]]).toEqual([id, color]);
  }
});

// Запись цвета отложена на 250 мс: вторая правка за это время не должна
// затереть первую старым списком из рендера.
test('two quick color picks both survive', () => {
  jest.useFakeTimers();
  try {
    const { container, dispatched } = renderWith({});
    click(buttonOf(container, 'Цвета отделов'));
    const inputs = [...container.querySelectorAll(
      '.SettingsRadioJobs__colors input[type=color]')];
    const order = RADIO_JOB_GROUPS.flatMap(group => group.ids);
    const pick = (id, color) => {
      const input = inputs[order.indexOf(id)];
      Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value')
        .set.call(input, color);
      act(() => input.dispatchEvent(new Event('input', { bubbles: true })));
    };
    pick('cmd', '#111111');
    pick('sec', '#222222');
    act(() => jest.runAllTimers());
    expect(dispatched.at(-1).payload).toEqual({
      radioJobColors: { cmd: '#111111', sec: '#222222' },
    });
  }
  finally {
    jest.useRealTimers();
  }
});

test('groups cover the palette once', () => {
  const grouped = RADIO_JOB_GROUPS.flatMap(group => group.ids);
  expect([...grouped].sort()).toEqual([...RADIO_JOB_IDS].sort());
});

test('class ids from say.dm match the palette', () => {
  const dm = fs.readFileSync(path.join(__dirname,
    '../../../../code/game/say.dm'), 'utf8').replace(/\r\n/g, '\n');
  const ids = new Set();
  for (const procName of ['get_radio_job_class', 'get_radio_job_faction',
    'get_radio_department_class', 'get_radio_job_legacy_class']) {
    const start = dm.indexOf('\n/proc/' + procName + '(');
    expect(start).toBeGreaterThan(-1);
    const end = dm.indexOf('\n/', start + 1);
    const body = dm.slice(start, end);
    for (const match of body.matchAll(/(?:return|department =) "([a-z]+)"/g)) {
      ids.add(match[1]);
    }
  }
  for (const match of dm.matchAll(/"radiojob-([a-z]+)"/g)) {
    ids.add(match[1]);
  }
  const legacyOnly = ['clown'];
  expect([...ids].filter(id => !RADIO_JOB_IDS.includes(id)).sort())
    .toEqual(legacyOnly);
  expect(RADIO_JOB_IDS.filter(id => !ids.has(id))).toEqual([]);
  const scss = fs.readFileSync(path.join(__dirname,
    '../styles/components/ChatRadioJobs.scss'), 'utf8');
  for (const id of legacyOnly) {
    expect(scss).toContain('.radiojob-' + id + ',');
    expect(scss).toContain('.radiojob-legacy-' + id + ' {');
  }
});

test('stylesheet defaults match the palette', () => {
  const scss = fs.readFileSync(path.join(__dirname,
    '../styles/components/ChatRadioJobs.scss'), 'utf8');
  for (const entry of RADIO_JOB_PALETTE) {
    expect(scss).toContain(`'${entry.id}': (${entry.dark}, ${entry.light})`);
    if (entry.legacy) {
      expect(scss).toContain(`'${entry.id}': ${entry.legacy},`);
    }
  }
});

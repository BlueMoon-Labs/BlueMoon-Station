import { act, fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../../backend';
import { debugReducer } from '../../debug';
import { AppearancePanel } from './AppearancePanel';
import { CommandTooltip } from './CommandTooltip';
import { NetrunContent } from './Content';
import { NETRUN_THEMES, themeId } from './themes';
import { NetCommand, NetrunData, Persona } from './types';

const persona: Persona = { avatar: 'cipher', accent: 'cyan', tagline: 'Сигнал найден', options: {
  avatars: [{ id: 'cipher', name: 'Шифр', icon: 'code' }, { id: 'fox', name: 'Лис', icon: 'paw' }],
  accents: [{ id: 'cyan', name: 'Циан', color: '#72ddea' }, { id: 'amber', name: 'Янтарь', color: '#f5c477' }],
  themes: Object.keys(NETRUN_THEMES),
} };
const setup = (extra: Partial<NetrunData> = {}) => {
  const topic = jest.fn();
  (global as any).Byond = { topic, winset: () => {} };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer })); setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'NetrunTerminal' }, data: {
    origin: 'entity', workspace_view: 'terminal', ui_theme: 'ion', wireless: true, uplink: true,
    trace: 0, locked: 0, can_breach: false, log: [], jack: null, host_actions: [],
    networks: [], selected: null, selected_network: null, map: null,
    storage: { files: [], used: 0, capacity: 10 }, shard: null, file: null,
    breach: null, entity: { name: 'Ghost', host: 'ENG:1', host_name: 'Сервер', integrity: 90, max_integrity: 100, diving: false, persona },
    combat: null, chat: { handle: 'Ghost', messages: [] }, web: null, windows: [], window: null,
    cli: { verbs: [] }, ...extra,
  } }));
  return { topic, store };
};
const sent = (topic, action: string) => topic.mock.calls.filter((call) => call[0]?.type === `act/${action}`)
  .map((call) => { const { _netrun_action: _receipt, ...payload } = JSON.parse(call[0].payload); return payload; });

test('theme selection waits for the server and changes the mounted workspace without losing a terminal draft', () => {
  const { topic, store } = setup();
  const panel = render(<NetrunContent />);
  const terminal = panel.getByLabelText('Командная строка') as HTMLInputElement;
  fireEvent.change(terminal, { target: { value: 'exec "Мой демон.exe"' } });
  const opener = panel.getByLabelText('Оформление и сетевая личность'); opener.focus(); fireEvent.click(opener);
  fireEvent.click(panel.getByRole('button', { name: /Amber/ }));
  expect(sent(topic, 'set_theme')).toEqual([{ id: 'amber' }]);
  expect(panel.container.querySelector('[data-net-theme]')?.getAttribute('data-net-theme')).toBe('ion');
  act(() => store.dispatch(backendUpdate({ data: { ui_theme: 'amber' } })));
  const shell = panel.container.querySelector<HTMLElement>('.netrun-shell');
  expect(shell.dataset.netTheme).toBe('amber');
  expect(shell.style.getPropertyValue('--net-accent')).toBe(NETRUN_THEMES.amber.palette.accent);
  fireEvent.keyDown(document, { key: 'Escape' });
  expect(panel.queryByRole('dialog')).toBeNull();
  expect(terminal.value).toBe('exec "Мой демон.exe"');
  expect(document.activeElement).toBe(opener);
});

test('profile editing previews locally and sends one curated patch rather than renaming on each keystroke', () => {
  const { topic } = setup();
  const panel = render(<AppearancePanel onClose={() => {}} />);
  fireEvent.click(panel.getByRole('button', { name: 'Лис' }));
  fireEvent.click(panel.getByRole('button', { name: 'Янтарь' }));
  fireEvent.change(panel.getByLabelText('Имя процесса'), { target: { value: 'Fox-7' } });
  fireEvent.change(panel.getByLabelText(/Подпись/), { target: { value: 'В эфире' } });
  expect(panel.getAllByRole('img', { name: 'Аватар: Лис' })).toHaveLength(2);
  expect(sent(topic, 'appearance_update')).toEqual([]);
  fireEvent.click(panel.getByText('Сохранить профиль'));
  expect(sent(topic, 'appearance_update')).toEqual([{ name: 'Fox-7', avatar: 'fox', accent: 'amber', tagline: 'В эфире' }]);
});

test('themes work for ordinary consoles and profile controls appear only for a network entity', () => {
  setup({ entity: null, origin: 'deck' });
  const panel = render(<AppearancePanel onClose={() => {}} />);
  expect(panel.getByRole('button', { name: /Phosphor/ })).toBeTruthy();
  expect(panel.queryByLabelText('Имя процесса')).toBeNull();
  expect(themeId('unknown-css-url')).toBe('ion');
});

test('command help separates description, native conditions and facts and reacts to a live denial', () => {
  const { store } = setup({ ui_theme: 'amber' });
  const command: NetCommand = { id: 'mod_lights', name: 'Фонарь MOD', icon: 'lightbulb', access: 2, allowed: true,
    illegal: true, trace: 6, danger: false, desc: 'Переключить фонарь.', details: 'Модуль должен быть установлен.\nНужен заряд батареи.', latency_ms: 125 };
  const panel = render(<CommandTooltip command={command} />);
  expect(panel.getByRole('tooltip').querySelectorAll('p')).toHaveLength(3);
  expect(panel.getByText('~125 мс')).toBeTruthy(); expect(panel.getByText('+6%')).toBeTruthy();
  expect(panel.getByText('Требуется онлайн')).toBeTruthy();
  act(() => store.dispatch(backendUpdate({ data: { ui_theme: 'noir' } })));
  panel.rerender(<CommandTooltip command={{ ...command, allowed: false, unavailable_reason: 'Узел не отвечает.' }} />);
  expect(panel.getByText('Узел не отвечает.')).toBeTruthy();
  expect((panel.getByRole('tooltip') as HTMLElement).style.getPropertyValue('--net-accent')).toBe(NETRUN_THEMES.noir.palette.accent);
});

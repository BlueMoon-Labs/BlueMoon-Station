import { act, fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../../backend';
import { AgentsPanel } from './AgentsPanel';
import { ungroupedCommands } from './CommandList';
import { FortressPanel } from './FortressPanel';
import { FortressDetails, NetCommand } from './types';

const command = (id: string, extra: Partial<NetCommand> = {}): NetCommand => ({ id, name: id, desc: '', icon: 'hammer',
  danger: false, access: 3, allowed: true, illegal: false, trace: 0, group: 'fortress', ...extra });
const fortress: FortressDetails = {
  name: 'Архив РнД', owner: 'Станция', faction: 'station', preset: 'Архив РнД', security_bonus: 2,
  slots_used: 9, slots_max: 12, can_manage: false, manage_reason: 'Нужен демон forge.exe в памяти или на подключённом шарде.',
  modules: [
    { ref: 'm1', kind: 'wall', name: 'Стена', desc: '', integrity: 160, max_integrity: 160, status: 'online' },
    { ref: 'm2', kind: 'turret', name: 'Турель', desc: '', integrity: 0, max_integrity: 90, status: 'destroyed' },
    { ref: 'm3', kind: 'vault', name: 'Хранилище', desc: '', integrity: 30, max_integrity: 110, status: 'building', remaining: 12 },
  ],
};
const setupBackend = (data: object) => {
  const topic = jest.fn();
  (global as any).Byond = { topic, winset: () => {} };
  const store = createStore(combineReducers({ backend: backendReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ data }));
  return { topic, store };
};

test('fortress requests leave the generic command grid for their own section', () => {
  const commands = [command('scan', { group: null }), command('fort_build@wall'), command('fort_repair')];
  expect(ungroupedCommands(commands).map((entry) => entry.id)).toEqual(['scan']);
});

test('the fortress section shows modules, slots and why the viewer cannot manage it', () => {
  const onCommand = jest.fn();
  const panel = render(<FortressPanel fortress={fortress} access={2} onCommand={onCommand}
    commands={[command('fort_build@wall', { allowed: false, unavailable_reason: 'Нужен ROOT.' }), command('fort_repair')]} />);
  expect(panel.getByText('Архив РнД', { selector: 'div' })).toBeTruthy();
  expect(panel.getByText('Слоты: 9/12')).toBeTruthy();
  expect(panel.getByText('разрушен')).toBeTruthy();
  expect(panel.getByText('строится · 12 с')).toBeTruthy();
  expect(panel.getByText(/Нужен демон forge.exe/)).toBeTruthy();
  fireEvent.click(panel.getByText('fort_repair'));
  expect(onCommand).toHaveBeenCalledWith('fort_repair');
  fireEvent.click(panel.getByText('Построить'));
  expect(panel.getByRole('group', { name: 'Постройка модулей' })).toBeTruthy();
});

test('agents list their state and send orders with the selected node', () => {
  const { topic } = setupBackend({
    selected: { address: 'NODE-7' },
    agents: [{ ref: 'agent-1', name: 'GUARD-01', bot_kind: 'sentinel', node: 'NODE-1', node_name: 'Терминал',
      integrity: 90, max_integrity: 120, state: 'охрана', goal: 'охрана узла Терминал', storage: { used: 8, capacity: 16 },
      orders: [{ id: 'recall', name: 'Отозвать' }, { id: 'guard', name: 'Перевести на выбранный узел', needs_node: true }] }],
  });
  const panel = render(<AgentsPanel />);
  expect(panel.getByText('GUARD-01')).toBeTruthy();
  expect(panel.getByText('Задача: охрана узла Терминал')).toBeTruthy();
  act(() => { fireEvent.click(panel.getByText('Перевести на выбранный узел')); });
  const request = topic.mock.calls.find(([message]) => message.type === 'act/agent_order')[0];
  expect(JSON.parse(request.payload)).toEqual(expect.objectContaining({ ref: 'agent-1', order: 'guard', address: 'NODE-7' }));
});

test('module actions retain exact instance ids and show protected vault capacity', () => {
  const onCommand = jest.fn();
  const details = { ...fortress, storage: { used: 8, capacity: 24, vault_bonus: 12, required_access: 3 }, modules: [
    { ...fortress.modules[0], id: 'wall-2', repair_command: 'fort_repair@wall-2', dismantle_command: 'fort_dismantle@wall-2' },
  ] };
  const panel = render(<FortressPanel fortress={details} access={3} onCommand={onCommand} commands={[
    command('fort_repair@wall-2', { allowed: false }), command('fort_dismantle@wall-2'), command('fort_dismantle@wall'),
  ]} />);
  expect(panel.getByText('Доступ к файлам: ROOT.')).toBeTruthy();
  expect(panel.getByRole('meter', { name: 'Память крепости' }).getAttribute('aria-valuemax')).toBe('24');
  fireEvent.click(panel.getByText('Починить')); expect(onCommand).not.toHaveBeenCalled();
  fireEvent.click(panel.getByText('Разобрать')); expect(onCommand).toHaveBeenCalledWith('fort_dismantle@wall-2');
  expect(panel.queryByText('fort_dismantle@wall')).toBeNull();
});

test('agent controls transmit persona, file and delegated commands through agent_order only', () => {
  const { topic } = setupBackend({
    selected: { address: 'TARGET', name: 'Устройство', commands: [command('scan', { name: 'Сканировать', allowed: false })] },
    storage: { used: 3, capacity: 10, files: [{ uid: 'local-1', name: 'shield.exe', kind: 'combat', size: 3, preview: null }] },
    agents: [{ ref: 'bot-1', name: 'STEW-01', bot_kind: 'mender', node: 'HOME', node_name: 'APC', integrity: 80, max_integrity: 100,
      state: 'ожидает', goal: 'охрана', storage: { used: 2, capacity: 10 }, persona: { avatar: 'fox', accent: 'mint', tagline: 'На связи.' },
      files: [{ uid: 'bot-file', name: 'report.txt', kind: 'text', size: 2, preview: 'Отчёт' }], programs: [],
      goals: [{ id: 'goal-1', name: 'Проверить узел', desc: 'Диагностика APC.', selected: true }],
      orders: ['persona', 'command', 'upload', 'download'].map((id) => ({ id, name: id })) }],
  });
  const panel = render(<AgentsPanel />);
  fireEvent.change(panel.getByLabelText('Команда агента STEW-01'), { target: { value: 'scan' } });
  fireEvent.click(panel.getByText('Поручить'));
  fireEvent.change(panel.getByLabelText('Локальный файл'), { target: { value: 'local-1' } });
  fireEvent.click(panel.getByText('Загрузить'));
  fireEvent.click(panel.getByLabelText('Забрать report.txt у STEW-01'));
  fireEvent.click(panel.getByText('Личность'));
  fireEvent.change(panel.getByLabelText('Имя'), { target: { value: 'STEW-02' } });
  fireEvent.click(panel.getByText('Сохранить личность'));
  const requests = topic.mock.calls.filter(([message]) => message.type === 'act/agent_order').map(([message]) => JSON.parse(message.payload));
  expect(requests).toEqual(expect.arrayContaining([
    expect.objectContaining({ ref: 'bot-1', order: 'command', address: 'TARGET', command: 'scan' }),
    expect.objectContaining({ ref: 'bot-1', order: 'upload', uid: 'local-1' }),
    expect.objectContaining({ ref: 'bot-1', order: 'download', uid: 'bot-file' }),
    expect.objectContaining({ ref: 'bot-1', order: 'persona', name: 'STEW-02', avatar: 'fox', accent: 'mint' }),
  ]));
  expect(topic.mock.calls.some(([message]) => message.type === 'act/command')).toBe(false);
});

import { act, fireEvent, render, within } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../../backend';
import { AgentsWorkspace } from './AgentsWorkspace';

const template = { uid: 'template-1', name: 'hacker.bot', kind: 'bot', size: 8, agent_profile: 'hacker', preview: 'Взломщик доступных рубежей' };
const builder = { template_uid: template.uid, profile: 'hacker', name: 'Взломщик', description: 'Подбирает доступ', capacity: 64, base_size: 5,
  defaults: [], programs: [], avatars: [{ id: 'cipher', name: 'Шифр' }], accents: [{ id: 'violet', name: 'Ирис', color: '#b7a0ff' }],
  themes: ['ion'], orders: [{ id: 'guard', name: 'На месте' }] };
const agent = { ref: 'agent-1', name: 'ХАК-1', bot_kind: 'hacker', integrity: 90, max_integrity: 90, node: 'HOME', node_name: 'Терминал',
  state: 'ожидает', goal: 'охрана узла', storage: { used: 4, capacity: 64 }, programs: [], files: [], goals: [],
  behavior: { strategy: 'profile', aggression: 40, caution: 60, cooperation: true },
  orders: [{ id: 'hack', name: 'Взломать выбранный узел', needs_node: true }, { id: 'recall', name: 'Отозвать' }, { id: 'behavior', name: 'Настроить поведение' }] };
const setup = () => {
  const topic = jest.fn(); (global as any).Byond = { topic, winset: () => {} };
  const store = createStore(combineReducers({ backend: backendReducer })); setGlobalStore(store);
  store.dispatch(backendUpdate({ data: { workspace_view: 'agents', storage: { files: [template], used: 8, capacity: 128 },
    shard: { name: 'Шард', used: 8, capacity: 128, files: [{ ...template, uid: 'shard-template', name: 'breacher.bot' }] },
    selected: { address: 'TARGET', name: 'Сервер', commands: [] }, entity: { host: 'HOME', host_name: 'Терминал' },
    file: { ...template, source: 'local', content: null, image: null, agent_builder: builder },
    agents: [agent],
  } }));
  const panel = render(<AgentsWorkspace />);
  const update = (data: object) => act(() => store.dispatch(backendUpdate({ data })));
  const sent = (action: string) => topic.mock.calls.filter(([message]) => message.type === `act/${action}`).map(([message]) => JSON.parse(message.payload));
  return { panel, update, sent };
};

test('agent overview exposes target-aware quick orders, owned templates and an explicit launch', () => {
  const { panel, sent } = setup();
  expect(panel.getByText('Активные агенты (1)')).toBeTruthy();
  expect(panel.getByText('ХАК-1')).toBeTruthy();
  expect(panel.getByText('Цель адресных приказов')).toBeTruthy();
  const card = panel.container.querySelector<HTMLElement>('[data-net-agent="hacker"]');
  expect([...card.querySelectorAll('details')].every((details) => !details.open)).toBe(true);
  fireEvent.click(within(card).getByText('Взломать выбранный узел'));
  expect(sent('agent_order')).toEqual([{ ref: 'agent-1', order: 'hack', address: 'TARGET' }]);
  fireEvent.click(panel.getByText('Запустить агента'));
  expect(sent('bot_launch')).toEqual([{ uid: 'template-1' }]);
  fireEvent.click(panel.getByRole('button', { name: 'Шаблон breacher.bot' }));
  expect(sent('file_select')).toEqual([{ uid: 'shard-template' }]);
  fireEvent.click(panel.getByText('Выбрать на карте'));
  expect(sent('workspace_view')).toEqual([{ page: 'map' }]);
});

test('hidden builders preserve drafts, but an authoritative active deletion clears the selected launch card', () => {
  const { panel, update } = setup();
  fireEvent.click(panel.getByText('Собрать своего агента'));
  fireEvent.change(panel.getByLabelText('Имя агента'), { target: { value: 'Мой черновик' } });
  update({ workspace_view: 'map', file: null, agents: [] });
  expect((panel.getByLabelText('Имя агента') as HTMLInputElement).value).toBe('Мой черновик');
  expect(panel.getByText('ХАК-1')).toBeTruthy();
  update({ workspace_view: 'agents', file: null, agents: [] });
  expect(panel.queryByLabelText('Имя агента')).toBeNull();
  expect(panel.queryByText('Запустить агента')).toBeNull();
  expect(panel.queryByText('ХАК-1')).toBeNull();
});

test('collection keeps an explicit target and agent details explain turn recovery and full memory', () => {
  const { panel, update, sent } = setup();
  update({ agents: [{ ref: 'agent-1', name: 'ХАК-1', bot_kind: 'hacker', integrity: 90, max_integrity: 90, node: 'HOME', node_name: 'Терминал',
    state: 'ожидание хода', goal: 'сбор ценных обломков', storage: { used: 64, capacity: 64 },
    programs: [{ id: 'jam', uid: 'jam-file', name: 'jam.exe', role: 'stun', desc: 'Подавление процесса', power: 20, ap_cost: 1, ready_in: 0, ready_turns: 2 }],
    files: [{ uid: 'session', name: 'ID сеанса', kind: 'access', size: 1, session_bound: true, transferable: false }], goals: [],
    orders: [{ id: 'collect', name: 'Собрать трофеи на выбранном узле', needs_node: true }, { id: 'download', name: 'Забрать файл' }],
  }] });
  expect(panel.getByText('Восстановление через 2 ход.')).toBeTruthy();
  expect(panel.getByText(/подавление · мощность 20 · 1 ОД/)).toBeTruthy();
  expect(panel.getByText(/Память заполнена: заберите файлы/)).toBeTruthy();
  fireEvent.click(panel.getByLabelText('Забрать ID сеанса у ХАК-1'));
  expect(sent('agent_order')).toEqual([]);
  fireEvent.click(panel.getByText('Собрать трофеи на выбранном узле'));
  expect(sent('agent_order')).toEqual([{ ref: 'agent-1', order: 'collect', address: 'TARGET' }]);
  update({ selected: null });
  fireEvent.click(panel.getByText('Собрать трофеи на выбранном узле'));
  expect(sent('agent_order')).toHaveLength(1);
});

test('behavior settings send one complete policy and preserve drafts across status patches', () => {
  const { panel, update, sent } = setup();
  expect(panel.queryByText('Настроить поведение')).toBeNull();
  const summary = panel.getByText('Поведение');
  const details = summary.closest('details');
  fireEvent.click(summary);
  const strategy = panel.getByLabelText('Стратегия агента ХАК-1') as HTMLSelectElement;
  const aggression = panel.getByLabelText('Агрессия агента ХАК-1') as HTMLInputElement;
  const caution = panel.getByLabelText('Осторожность агента ХАК-1') as HTMLInputElement;
  fireEvent.change(strategy, { target: { value: 'scavenge' } });
  fireEvent.change(aggression, { target: { value: '25' } });
  fireEvent.change(caution, { target: { value: '85' } });
  fireEvent.click(panel.getByLabelText('Помогать союзникам'));
  expect(sent('agent_order')).toEqual([]);
  update({ agents: [{ ...agent, state: 'переход в соседний узел', behavior: { ...agent.behavior } }] });
  expect(panel.getByText('Поведение').closest('details')).toBe(details);
  expect(strategy.value).toBe('scavenge');
  expect(aggression.value).toBe('25');
  fireEvent.click(panel.getByText('Применить поведение'));
  expect(sent('agent_order')).toEqual([{ ref: 'agent-1', order: 'behavior', strategy: 'scavenge', aggression: 25, caution: 85, cooperation: false }]);
  update({ agents: [{ ...agent, behavior: { strategy: 'guard', aggression: 10, caution: 90, cooperation: true } }] });
  expect(strategy.value).toBe('guard');
  expect(aggression.value).toBe('10');
  expect(caution.value).toBe('90');
  expect((panel.getByLabelText('Помогать союзникам') as HTMLInputElement).checked).toBe(true);
});

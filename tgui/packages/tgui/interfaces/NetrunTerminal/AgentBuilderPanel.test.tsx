import { act, fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../../backend';
import { AgentBuilderPanel } from './AgentBuilderPanel';
import { AgentBuilder } from './types';

const builder: AgentBuilder = {
  template_uid: 'template', profile: 'surveyor', name: 'Разведчик', description: 'Исследует доступные узлы.', capacity: 12, base_size: 4,
  defaults: [{ id: 'scan', name: 'Разведка', size: 3 }], programs: [{ uid: 'owned-program', name: 'Лечение', program_id: 'repair', size: 2 }],
  orders: [{ id: 'guard', name: 'На месте' }, { id: 'patrol', name: 'Патруль' }],
  avatars: [{ id: 'cipher', name: 'Шифр' }, { id: 'fox', name: 'Лис' }],
  accents: [{ id: 'cyan', name: 'Лёд', color: '#72ddea' }, { id: 'mint', name: 'Мята', color: '#77d9ad' }], themes: ['ion'], max_programs: 8,
};
const setup = () => {
  const topic = jest.fn(); (global as any).Byond = { topic, winset: () => {} };
  const store = createStore(combineReducers({ backend: backendReducer })); setGlobalStore(store);
  store.dispatch(backendUpdate({ data: { storage: { used: 1, capacity: 40, files: [] }, shard: { name: 'Мой шард', used: 0, capacity: 30, files: [] } } }));
  const panel = render(<AgentBuilderPanel builder={builder} />);
  fireEvent.click(panel.getByText('Собрать своего агента'));
  const sent = () => topic.mock.calls.filter(([message]) => message.type === 'act/agent_create').map(([message]) => JSON.parse(message.payload));
  return { panel, store, sent };
};

test('a named agent package uses the selected template, persona, owned programs and destination', () => {
  const { panel, sent } = setup();
  fireEvent.change(panel.getByLabelText('Имя агента'), { target: { value: 'Кира' } });
  fireEvent.change(panel.getByLabelText('Аватар'), { target: { value: 'fox' } });
  fireEvent.change(panel.getByLabelText('Цвет'), { target: { value: 'mint' } });
  fireEvent.change(panel.getByLabelText('Подпись'), { target: { value: 'Картограф' } });
  fireEvent.change(panel.getByLabelText('Начальная задача'), { target: { value: 'patrol' } });
  fireEvent.click(panel.getByLabelText('Лечение · 2'));
  fireEvent.change(panel.getByLabelText('Сохранить агента'), { target: { value: 'shard' } });
  expect(panel.getByText('Файл займёт 9; свободно 30.')).toBeTruthy();
  fireEvent.click(panel.getByText('Создать агента'));
  expect(sent()).toEqual([{ uid: 'template', name: 'Кира', avatar: 'fox', accent: 'mint', tagline: 'Картограф', theme: 'ion', order: 'patrol',
    include_defaults: true, program_uids: ['owned-program'], module_uids: [], to_shard: true }]);
});

test('owned capability modules use their memory cost and UID while denied modules explain their requirement', () => {
  const { panel, sent } = setup();
  const hacking = { uid: 'owned-hacker', id: 'hacking', name: 'Модуль взлома', desc: 'Подбирает доступ штатным протоколом.', size: 4, requirements: [], allowed: true };
  panel.rerender(<AgentBuilderPanel builder={{ ...builder, modules: [hacking,
    { ...hacking, uid: 'blocked', id: 'icepick', name: 'Обход прошивки', allowed: false, reason: 'Нужен модуль взлома.' }], max_modules: 1 }} />);
  expect(panel.getByText('Нужен модуль взлома.')).toBeTruthy();
  fireEvent.click(panel.getByLabelText('Обход прошивки · 4'));
  fireEvent.click(panel.getByLabelText('Модуль взлома · 4'));
  expect(panel.getByText('Файл займёт 11; свободно 39.')).toBeTruthy();
  fireEvent.click(panel.getByText('Создать агента'));
  expect(sent()).toEqual([expect.objectContaining({ module_uids: ['owned-hacker'], program_uids: [] })]);
});

test('capacity limits prevent creation and removed media cannot leave stale program UIDs in a request', () => {
  const { panel, store, sent } = setup();
  fireEvent.click(panel.getByLabelText('Лечение · 2'));
  act(() => store.dispatch(backendUpdate({ data: { storage: { used: 35, capacity: 40, files: [] } } })));
  expect(panel.getByText('Недостаточно места: нужно 9, свободно 5.')).toBeTruthy();
  fireEvent.click(panel.getByText('Создать агента')); expect(sent()).toHaveLength(0);
  fireEvent.change(panel.getByLabelText('Сохранить агента'), { target: { value: 'shard' } });
  panel.rerender(<AgentBuilderPanel builder={{ ...builder, programs: [] }} />);
  fireEvent.click(panel.getByLabelText('Штатный набор'));
  expect(panel.getByText('Файл займёт 4; свободно 30.')).toBeTruthy();
  fireEvent.click(panel.getByText('Создать агента'));
  expect(sent()).toEqual([expect.objectContaining({ program_uids: [], include_defaults: false, to_shard: true })]);
});

import { act, fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../../backend';
import { AccessExport } from './AccessExport';
import { EntityContacts } from './EntityContacts';
import { StoragePanel } from './Panels';

const setup = () => {
  const topic = jest.fn(); (global as any).Byond = { topic, winset: () => {} };
  const store = createStore(combineReducers({ backend: backendReducer })); setGlobalStore(store);
  store.dispatch(backendUpdate({ data: { access_export: { node_count: 2, network_count: 1, can_export: true },
    shard: { name: 'Шард', files: [], used: 0, capacity: 128 } } }));
  const update = (data: object) => act(() => store.dispatch(backendUpdate({ data })));
  const sent = (action: string) => topic.mock.calls.filter(([message]) => message.type === `act/${action}`).map(([message]) => JSON.parse(message.payload));
  return { sent, update };
};

test('the accumulated access file can be opened and copied while a server denial prevents export', () => {
  const { sent, update } = setup();
  const panel = render(<AccessExport />);
  expect(panel.getByText('Узлов: 2 · сетей: 1')).toBeTruthy();
  update({ access_export: { node_count: 2, network_count: 1, can_export: true,
    key_uid: 'owned-grants', key_name: 'Мои доступы.grants' } });
  fireEvent.click(panel.getByText('Мои доступы.grants'));
  expect(sent('file_select')).toEqual([{ uid: 'owned-grants' }]);
  fireEvent.change(panel.getByLabelText('Имя ключа'), { target: { value: 'Инженерный.key' } });
  fireEvent.change(panel.getByLabelText('Сохранить ключ'), { target: { value: 'shard' } });
  fireEvent.click(panel.getByText('Скопировать ключ'));
  expect(sent('access_export')).toEqual([{ name: 'Инженерный.key', to_shard: true }]);
  update({ access_export: { node_count: 0, network_count: 0, can_export: false, reason: 'Нет полученных взломом прав.' } });
  expect(panel.getByText('Нет полученных взломом прав.')).toBeTruthy();
  fireEvent.click(panel.getByText('Скопировать ключ'));
  expect(sent('access_export')).toHaveLength(1);
});

test('session ID snapshots are visible and revocable but never offered, uploaded or copied', () => {
  const { sent, update } = setup();
  const snapshot = { uid: 'session-id', name: 'Мой ID', kind: 'access', size: 1, preview: 'Допуски ID текущего погружения',
    session_bound: true, transferable: false };
  const key = { uid: 'acquired', name: 'Взлом.key', kind: 'grants', size: 1, preview: 'Полученный доступ', transferable: true };
  update({ workspace_view: 'files', storage: { files: [snapshot, key], used: 2, capacity: 128 },
    selected: { address: 'NODE', access: 3, files: [] }, file: { ...snapshot, source: 'session', content: null, image: null },
  });
  const contact = { ref: 'recipient', name: 'Сосед', kind: 'entity' as const, integrity: 100, max_integrity: 100, state: 'резидент',
    self: false, can_signal: true, can_message: true, can_offer: true };
  const panel = render(<><StoragePanel /><EntityContacts address="NODE" contacts={[contact]} pending={false} localEntity /></>);
  const snapshotRow = panel.getByRole('button', { name: `Выбрать файл ${snapshot.name}` });
  const keyRow = panel.getByRole('button', { name: `Выбрать файл ${key.name}` });
  expect(snapshotRow.querySelector('.fa-upload')).toBeNull();
  expect(keyRow.querySelector('.fa-upload')).not.toBeNull();
  fireEvent.click(snapshotRow.querySelector('.fa-ban').parentElement);
  expect(sent('delete_local')).toEqual([{ uid: 'session-id' }]);
  expect(panel.getByText('Только для текущего погружения')).toBeTruthy();
  const name = panel.getByLabelText('Имя снимка ID') as HTMLInputElement;
  expect(name.readOnly).toBe(true);
  expect(name.value).toBe('Мой ID');
  expect(panel.queryByText('Переименовать')).toBeNull();
  expect(panel.queryByText('Копировать в память')).toBeNull();
  fireEvent.click(panel.getByText('Предложить копию файла'));
  const choices = [...(panel.getByLabelText('Файл для Сосед') as HTMLSelectElement).options].map((option) => option.value);
  expect(choices).toContain('acquired'); expect(choices).not.toContain('session-id');
});

import { act, fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../../backend';
import { FilePanel } from './FilePanel';

const original = { uid: 'file:one', name: 'note.txt', content: 'Исходный текст', kind: 'text', size: 1, source: 'local' };
const setup = () => {
  const topic = jest.fn();
  (global as any).Byond = { topic, winset: () => {} };
  const store = createStore(combineReducers({ backend: backendReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ data: { file: original, shard: null } }));
  const panel = render(<FilePanel />);
  const textarea = () => panel.container.querySelector('textarea');
  const name = () => panel.container.querySelector('input');
  const update = (file: Partial<typeof original>) => act(() => store.dispatch(backendUpdate({ data: { file: { ...original, ...file } } })));
  const editText = (value: string) => fireEvent.change(textarea(), { target: { value } });
  const editName = (value: string) => fireEvent.input(name(), { target: { value } });
  return { panel, textarea, name, update, editText, editName, topic, store };
};

test('clean fields follow external edits to the same file without remounting its editor', () => {
  const { textarea, name, update } = setup();
  const editor = textarea();
  update({ name: 'renamed.txt', content: 'Текст другого редактора' });
  expect(textarea()).toBe(editor);
  expect(textarea().value).toBe('Текст другого редактора');
  expect(name().value).toBe('renamed.txt');
});

test('dirty fields preserve their drafts while untouched fields follow external updates', () => {
  const { name, textarea, update, editText, editName } = setup();
  editText('Мой черновик');
  update({ name: 'server-name.txt', content: 'Правка сервера' });
  expect(textarea().value).toBe('Мой черновик');
  expect(name().value).toBe('server-name.txt');
  editName('draft-name.txt');
  update({ name: 'another-name.txt', content: 'Ещё одна правка' });
  expect(name().value).toBe('draft-name.txt');
  expect(textarea().value).toBe('Мой черновик');
});

test('a save receipt keeps later typing and only the acknowledged draft becomes clean', () => {
  const { panel, textarea, update, editText, topic } = setup();
  editText('Отправленный текст');
  fireEvent.click(panel.getByText('Сохранить'));
  const request = topic.mock.calls.find(([message]) => message.type === 'act/file_edit')[0];
  expect(JSON.parse(request.payload).content).toBe('Отправленный текст');
  editText('Продолжение после отправки');
  update({ content: 'Отправленный текст' });
  expect(textarea().value).toBe('Продолжение после отправки');
  // A later successful save confirms the current draft. Future external edits
  // can now update it, without leaving the editor permanently dirty.
  update({ content: 'Продолжение после отправки' });
  expect(textarea().value).toBe('Продолжение после отправки');
  update({ content: 'Новая внешняя версия' });
  expect(textarea().value).toBe('Новая внешняя версия');
});

test('selecting another file starts its own editor even when the old file has unsaved edits', () => {
  const { name, textarea, update, editText } = setup();
  editText('Незавершённая правка');
  update({ uid: 'file:two', name: 'other.txt', content: 'Другой файл' });
  expect(textarea().value).toBe('Другой файл');
  expect(name().value).toBe('other.txt');
});

test('a shard file can be copied or moved explicitly into local memory', () => {
  const { panel, topic, store } = setup();
  act(() => store.dispatch(backendUpdate({ data: {
    file: { ...original, source: 'shard', can_import: true },
    shard: { name: 'Шард', used: 1, capacity: 10, files: [original] }, storage: { used: 0, capacity: 10, files: [] },
  } })));
  fireEvent.click(panel.getByText('Копировать в память'));
  fireEvent.click(panel.getByText('Перенести в память'));
  expect(topic.mock.calls.filter(([message]) => message.type === 'act/file_import').map(([message]) => JSON.parse(message.payload)))
    .toEqual([{ uid: original.uid, move: false }, { uid: original.uid, move: true }]);
});

test('a full destination key can merge while server transfer denials remain visible', () => {
  const { panel, topic, store } = setup();
  const key = { ...original, uid: 'key-shard', name: 'key.grants', kind: 'grants', source: 'shard', can_import: true };
  act(() => store.dispatch(backendUpdate({ data: { file: key,
    storage: { used: 1, capacity: 1, files: [{ ...key, uid: 'key-local' }] },
    shard: { name: 'Шард', used: 1, capacity: 1, files: [key] },
  } })));
  fireEvent.click(panel.getByText('Объединить с ключом в памяти'));
  expect(topic.mock.calls.some(([message]) => message.type === 'act/file_import')).toBe(true);
  const previous = topic.mock.calls.length;
  act(() => store.dispatch(backendUpdate({ data: { file: { ...key, transfer: {
    local: { copy: false, move: false, reason: 'Носитель назначения доступен только для чтения.', merge: true },
  } } } })));
  expect(panel.getByText('Носитель назначения доступен только для чтения.')).toBeTruthy();
  fireEvent.click(panel.getByText('Объединить с ключом в памяти'));
  expect(topic.mock.calls).toHaveLength(previous);
});

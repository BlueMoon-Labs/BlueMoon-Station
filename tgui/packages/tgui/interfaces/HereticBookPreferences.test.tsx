import { act, fireEvent, render, renderHook, screen, waitFor } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';
import { storage } from 'common/storage';

import { backendReducer, backendUpdate } from '../backend';
import { ForbiddenLoreContent, ForbiddenLoreData } from './ForbiddenLore';
import { BookPresentation } from './HereticBookAtmosphere';
import { HereticBookPreferences, useBookPresentation } from './HereticBookPreferences';

jest.mock('common/storage', () => ({ storage: { get: jest.fn(), set: jest.fn() } }));

const getStored = storage.get as jest.Mock;
const setStored = storage.set as jest.Mock;
const saved = new Map<string, unknown>();
let readerNumber = 0;
const reader = () => `reading-test-${++readerNumber}`;
const storageKey = (name: string) => `heretic-book-view-v1:${name}`;
function deferred<T>() {
  let resolve!: (value: T) => void;
  let reject!: (reason: Error) => void;
  const promise = new Promise<T>((success, failure) => { resolve = success; reject = failure; });
  return { promise, resolve, reject };
}
const originalMatchMedia = window.matchMedia;

beforeEach(() => {
  saved.clear();
  getStored.mockImplementation(async (key: string) => saved.get(key));
  setStored.mockImplementation(async (key: string, value: unknown) => { saved.set(key, value); });
});

afterEach(() => {
  window.matchMedia = originalMatchMedia;
});

describe('Вид книги на устройстве', () => {
  test.each<BookPresentation>(['living', 'muted', 'plain'])('восстанавливает сохранённый режим %s', async (mode) => {
    const name = reader();
    saved.set(storageKey(name), mode);
    const { result } = renderHook(() => useBookPresentation(name));
    await waitFor(() => expect(getStored).toHaveBeenCalledWith(storageKey(name)));
    await waitFor(() => expect(result.current.presentation).toBe(mode));
    expect(result.current.effectivePresentation).toBe(mode);
    expect(setStored).not.toHaveBeenCalled();
  });

  test.each([undefined, null, '', 'broken', { mode: 'plain' }, 7])('не принимает повреждённое значение %p', async (value) => {
    const name = reader();
    saved.set(storageKey(name), value);
    const { result } = renderHook(() => useBookPresentation(name));
    await waitFor(() => expect(result.current.effectivePresentation).toBe('living'));
    expect(result.current.presentation).toBe('living');
    expect(setStored).not.toHaveBeenCalled();
  });

  test('до окончания чтения не запускает живое оформление', async () => {
    const loading = deferred<unknown>();
    const name = reader();
    getStored.mockReturnValueOnce(loading.promise);
    const { result } = renderHook(() => useBookPresentation(name));
    expect(result.current.effectivePresentation).toBe('muted');
    await act(async () => { loading.resolve('plain'); });
    expect(result.current.effectivePresentation).toBe('plain');
  });

  test('ранний выбор виден сразу, записывается после чтения и не заменяется старым значением', async () => {
    const loading = deferred<unknown>();
    const name = reader();
    getStored.mockReturnValueOnce(loading.promise);
    const { result } = renderHook(() => useBookPresentation(name));
    await waitFor(() => expect(getStored).toHaveBeenCalledTimes(1));
    act(() => result.current.choose('plain'));
    expect(result.current.effectivePresentation).toBe('plain');
    expect(setStored).not.toHaveBeenCalled();
    await act(async () => { loading.resolve('living'); });
    await waitFor(() => expect(setStored).toHaveBeenCalledWith(storageKey(name), 'plain'));
    expect(result.current.presentation).toBe('plain');
    expect(result.current.effectivePresentation).toBe('plain');
  });

  test('последовательные записи и новое окно ждут незавершённого сохранения', async () => {
    const writing = deferred<void>();
    const name = reader();
    const first = renderHook(() => useBookPresentation(name));
    await waitFor(() => expect(first.result.current.effectivePresentation).toBe('living'));
    setStored.mockImplementationOnce(async (key: string, mode: unknown) => {
      await writing.promise;
      saved.set(key, mode);
    });
    act(() => first.result.current.choose('muted'));
    await waitFor(() => expect(setStored).toHaveBeenCalledTimes(1));
    act(() => first.result.current.choose('plain'));
    first.unmount();
    const second = renderHook(() => useBookPresentation(name));
    expect(second.result.current.effectivePresentation).toBe('muted');
    expect(getStored).toHaveBeenCalledTimes(1);
    expect(setStored).toHaveBeenCalledTimes(1);
    await act(async () => { writing.resolve(); });
    await waitFor(() => expect(second.result.current.effectivePresentation).toBe('plain'));
    expect(setStored.mock.calls).toEqual([[storageKey(name), 'muted'], [storageKey(name), 'plain']]);
    expect(getStored).toHaveBeenCalledTimes(2);
  });

  test('ошибки чтения и записи не мешают выбрать режим и сохранить следующий', async () => {
    getStored.mockRejectedValueOnce(new Error('Хранилище недоступно'));
    setStored.mockRejectedValueOnce(new Error('Нет места'));
    const name = reader();
    const { result } = renderHook(() => useBookPresentation(name));
    await waitFor(() => expect(result.current.effectivePresentation).toBe('living'));
    act(() => result.current.choose('plain'));
    await waitFor(() => expect(setStored).toHaveBeenCalledTimes(1));
    expect(result.current.effectivePresentation).toBe('plain');
    act(() => result.current.choose('muted'));
    await waitFor(() => expect(saved.get(storageKey(name))).toBe('muted'));
    expect(result.current.effectivePresentation).toBe('muted');
  });

  test('поздний ответ предыдущего читателя не меняет настройку нового', async () => {
    const loading = deferred<unknown>();
    const firstReader = reader();
    const secondReader = reader();
    getStored.mockImplementation(async (key: string) => (
      key === storageKey(firstReader) ? loading.promise : 'plain'
    ));
    const { result, rerender } = renderHook(({ name }) => useBookPresentation(name), {
      initialProps: { name: firstReader },
    });
    await waitFor(() => expect(getStored).toHaveBeenCalledWith(storageKey(firstReader)));
    rerender({ name: secondReader });
    await waitFor(() => expect(result.current.effectivePresentation).toBe('plain'));
    await act(async () => { loading.resolve('living'); });
    expect(result.current.effectivePresentation).toBe('plain');
  });

  test('без идентификатора читателя использует локальный ключ', async () => {
    const { result } = renderHook(() => useBookPresentation(''));
    await waitFor(() => expect(result.current.effectivePresentation).toBe('living'));
    expect(getStored).toHaveBeenCalledWith('heretic-book-view-v1:local');
  });
});

describe('Системная настройка движения', () => {
  test.each([false, true])('слушает изменение настройки и снимает обработчик, старый API: %s', async (legacy) => {
    const listeners = new Set<() => void>();
    const add = jest.fn((...args: unknown[]) => listeners.add(args[args.length - 1] as () => void));
    const remove = jest.fn((...args: unknown[]) => listeners.delete(args[args.length - 1] as () => void));
    const media = {
      matches: true,
      ...(legacy ? { addListener: add, removeListener: remove } : { addEventListener: add, removeEventListener: remove }),
    };
    window.matchMedia = jest.fn(() => media) as unknown as typeof window.matchMedia;
    const name = reader();
    const { result, unmount } = renderHook(() => useBookPresentation(name));
    await waitFor(() => expect(result.current.effectivePresentation).toBe('living'));
    expect(result.current.reducedMotion).toBe(true);
    act(() => { media.matches = false; listeners.forEach((callback) => callback()); });
    expect(result.current.reducedMotion).toBe(false);
    act(() => { media.matches = true; listeners.forEach((callback) => callback()); });
    expect(result.current.reducedMotion).toBe(true);
    expect(result.current.presentation).toBe('living');
    expect(setStored).not.toHaveBeenCalled();
    expect(listeners.size).toBe(1);
    unmount();
    expect(remove.mock.calls).toEqual(add.mock.calls);
    expect(listeners.size).toBe(0);
  });

  test('переключатель доступен с клавиатуры, Escape возвращает фокус к заголовку', () => {
    const choose = jest.fn();
    render(<HereticBookPreferences presentation="muted" reducedMotion onChange={choose} />);
    const summary = screen.getByLabelText('Настроить вид книги');
    const panel = summary.closest('details')!;
    panel.open = true;
    const plain = screen.getByRole('radio', { name: /^Простой/ });
    fireEvent.click(plain);
    expect(choose).toHaveBeenCalledWith('plain');
    expect((screen.getByRole('radio', { name: /^Приглушённый/ }) as HTMLInputElement).checked).toBe(true);
    expect(screen.getByRole('status').textContent).toMatch(/системной настройкой/);
    plain.focus();
    fireEvent.keyDown(plain, { key: 'Escape' });
    expect(panel.open).toBe(false);
    expect(document.activeElement).toBe(summary);
  });
});

const renderStoredBook = async () => {
  const name = reader();
  const topic = jest.fn();
  (global as any).Byond = { topic };
  const data: ForbiddenLoreData = {
    selected_path: 'Ash', path_stage: 4, total_sacrifices: 2, points: 3, ascended: false,
    paths: [{ id: 'Ash', name: 'Пепел', desc: 'Учение огня.', strengths: [], weaknesses: [] }],
    knowledge: [],
    rituals: [
      { id: 'blade', name: 'Клинок', desc: 'Огненный клинок.', ingredients: [{ name: 'Спичка', amount: 1 }], ascension: false },
      { id: 'heart', name: 'Сердце', desc: 'Живое сердце.', ingredients: [{ name: 'Мак', amount: 1 }], ascension: false },
    ],
    combat_resource: null,
    hunt: {
      target_name: null, target_role: null, target_status: 'Цели ещё нет.', can_retarget: true,
      retarget_seconds: 0, sacrifices_required: 5, influences_harvested: 2, influence_limit: 6,
    },
  };
  const store = createStore(combineReducers({ backend: backendReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'ForbiddenLore', client: { ckey: name } }, data }));
  const view = render(<ForbiddenLoreContent />);
  const book = view.container.querySelector('[data-book-view]')!;
  await waitFor(() => expect(book.getAttribute('data-book-view')).toBe('living'));
  return { name, topic, store, view, book };
};

test('смена оформления сохраняет открытую главу, фильтр ритуалов и игровой прогресс', async () => {
  const { name, topic, store, book } = await renderStoredBook();
  fireEvent.click(screen.getByRole('tab', { name: 'Ритуалы' }));
  const search = screen.getByRole('textbox', { name: 'Найти запись или ингредиент' });
  fireEvent.change(search, { target: { value: 'Спичка' } });
  topic.mockClear();
  const before = store.getState().backend;
  (screen.getByLabelText('Настроить вид книги').closest('details') as HTMLDetailsElement).open = true;
  for (const [mode, label] of [['plain', /^Простой/], ['muted', /^Приглушённый/], ['living', /^Живая книга/]] as const) {
    fireEvent.click(screen.getByRole('radio', { name: label }));
    expect(book.getAttribute('data-book-view')).toBe(mode);
    expect(screen.getByRole('tabpanel', { name: 'Ритуалы' })).toBeTruthy();
    expect((screen.getByRole('textbox', { name: 'Найти запись или ингредиент' }) as HTMLInputElement).value).toBe('Спичка');
    expect(screen.queryByRole('button', { name: /Сердце/ })).toBeNull();
    expect(store.getState().backend).toBe(before);
    expect(topic).not.toHaveBeenCalled();
  }
  await waitFor(() => expect(setStored).toHaveBeenLastCalledWith(storageKey(name), 'living'));
});

test('возврат к живой книге не повторяет законченное или прерванное перелистывание', async () => {
  const listeners = new Set<() => void>();
  const media = {
    matches: false,
    addEventListener: (_event: string, callback: () => void) => listeners.add(callback),
    removeEventListener: (_event: string, callback: () => void) => listeners.delete(callback),
  };
  window.matchMedia = jest.fn(() => media) as unknown as typeof window.matchMedia;
  const { name, view } = await renderStoredBook();
  const leaf = () => view.container.querySelector('.HereticBook__turningLeaf');
  (screen.getByLabelText('Настроить вид книги').closest('details') as HTMLDetailsElement).open = true;
  expect(leaf()).toBeNull();
  fireEvent.click(screen.getByRole('tab', { name: 'Ритуалы' }));
  expect(leaf()).toBeTruthy();
  fireEvent.animationEnd(leaf()!);
  expect(leaf()).toBeNull();
  fireEvent.click(screen.getByRole('radio', { name: /^Простой/ }));
  fireEvent.click(screen.getByRole('radio', { name: /^Живая книга/ }));
  expect(leaf()).toBeNull();
  fireEvent.click(screen.getByRole('tab', { name: 'Охота' }));
  expect(leaf()).toBeTruthy();
  fireEvent.click(screen.getByRole('radio', { name: /^Приглушённый/ }));
  fireEvent.click(screen.getByRole('radio', { name: /^Живая книга/ }));
  expect(leaf()).toBeNull();
  fireEvent.click(screen.getByRole('tab', { name: 'Помощь' }));
  expect(leaf()).toBeTruthy();
  act(() => { media.matches = true; listeners.forEach((callback) => callback()); });
  expect(leaf()).toBeNull();
  act(() => { media.matches = false; listeners.forEach((callback) => callback()); });
  expect(leaf()).toBeNull();
  fireEvent.click(screen.getByRole('tab', { name: 'Путь' }));
  expect(leaf()).toBeTruthy();
  await waitFor(() => expect(setStored).toHaveBeenLastCalledWith(storageKey(name), 'living'));
});

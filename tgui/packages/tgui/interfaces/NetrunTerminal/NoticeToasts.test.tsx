import { act, fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../../backend';
import { debugReducer } from '../../debug';
import { NoticeToasts } from './NoticeToasts';
import { NetrunNotice } from './types';

const notice = (id: number, text = 'Ваш ход', kind: NetrunNotice['kind'] = 'good'): NetrunNotice => ({ id, text, kind });
const setup = (notices: NetrunNotice[] | undefined = []) => {
  const topic = jest.fn();
  (global as any).Byond = { topic, winset: () => {} };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'NetrunTerminal' }, data: { notices, ui_theme: 'ion' } }));
  const publish = (notices: NetrunNotice[]) => act(() => store.dispatch(backendUpdate({ data: { notices } })));
  return { topic, store, publish };
};

beforeEach(() => jest.useFakeTimers());
afterEach(() => { jest.useRealTimers(); });

test('the opening snapshot is a silent baseline and later IDs appear once', () => {
  const old = notice(8, 'Сообщение до открытия окна');
  const { publish, topic } = setup([old]);
  const panel = render(<NoticeToasts />);
  expect(panel.queryByRole('region')).toBeNull();
  expect(jest.getTimerCount()).toBe(0);
  publish([old, notice(9)]);
  expect(panel.getByRole('status').textContent).toContain('Ваш ход');
  expect(panel.queryByText(old.text)).toBeNull();
  publish([{ ...old }, { ...notice(9) }]);
  expect(panel.queryByText('×2')).toBeNull();
  expect(topic).not.toHaveBeenCalled();
});

test('the first server snapshot remains history when the component mounted before data arrived', () => {
  const { store, publish } = setup();
  store.dispatch(backendUpdate({ data: { notices: undefined } }));
  const panel = render(<NoticeToasts />);
  publish([notice(4, 'Старое сообщение')]);
  expect(panel.queryByRole('region')).toBeNull();
  publish([notice(4, 'Старое сообщение'), notice(5, 'Новый результат')]);
  expect(panel.getByText('Новый результат')).toBeTruthy();
  expect(panel.queryByText('Старое сообщение')).toBeNull();
});

test('ordinary notices expire at five seconds and errors at seven using one deadline timer', () => {
  const { publish, topic } = setup();
  const panel = render(<NoticeToasts />);
  publish([notice(1, 'Файл получен'), notice(2, 'Нет маршрута', 'bad')]);
  expect(panel.getByRole('alert').getAttribute('aria-live')).toBe('polite');
  expect(jest.getTimerCount()).toBe(1);
  act(() => jest.advanceTimersByTime(5000));
  expect(panel.queryByText('Файл получен')).toBeNull();
  expect(panel.getByText('Нет маршрута')).toBeTruthy();
  expect(jest.getTimerCount()).toBe(1);
  act(() => jest.advanceTimersByTime(2000));
  expect(panel.queryByRole('region')).toBeNull();
  expect(jest.getTimerCount()).toBe(0);
  expect(topic).not.toHaveBeenCalled();
});

test('quiet backend snapshots and theme changes do not restart the notice lifetime', () => {
  const { publish, store } = setup();
  const panel = render(<NoticeToasts />);
  publish([notice(1)]);
  act(() => jest.advanceTimersByTime(4000));
  publish([{ ...notice(1) }]);
  act(() => store.dispatch(backendUpdate({ data: { ui_theme: 'amber' } })));
  expect(panel.getByRole('region').style.getPropertyValue('--net-accent')).toBe('#f3c070');
  act(() => jest.advanceTimersByTime(1000));
  expect(panel.queryByRole('region')).toBeNull();
});

test('new repeated events coalesce in place and a burst never exceeds three small cards', () => {
  const { publish } = setup();
  const panel = render(<NoticeToasts />);
  publish([notice(1, 'Получен файл'), notice(2, 'Получен файл')]);
  const card = document.querySelector('[data-net-notice="1"]');
  expect(panel.getByText('×2')).toBeTruthy();
  expect(document.querySelectorAll('[data-net-notice]')).toHaveLength(1);
  act(() => jest.advanceTimersByTime(4000));
  publish([notice(1, 'Получен файл'), notice(2, 'Получен файл'), notice(3, 'Получен файл')]);
  expect(document.querySelector('[data-net-notice="1"]')).toBe(card);
  expect(panel.getByText('×3')).toBeTruthy();
  act(() => jest.advanceTimersByTime(1000));
  expect(panel.getByText('×3')).toBeTruthy();
  publish([notice(3, 'Получен файл'), notice(4, 'Слабый сигнал', 'average'), notice(5, 'Нет доступа', 'bad'), notice(6, 'Сканирование завершено', 'label')]);
  expect(document.querySelectorAll('[data-net-notice]')).toHaveLength(3);
  expect(panel.queryByText('Получен файл')).toBeNull();
  expect(panel.getByText('Слабый сигнал')).toBeTruthy();
  expect(panel.getByText('Нет доступа')).toBeTruthy();
  expect(panel.getByText('Сканирование завершено')).toBeTruthy();
});

test('hover dismissal is local, old IDs do not reappear, and unmount cancels the remaining timer', () => {
  const { publish, topic } = setup();
  const panel = render(<NoticeToasts />);
  publish([notice(1)]);
  fireEvent.mouseEnter(panel.getByRole('status'));
  expect(panel.queryByRole('region')).toBeNull();
  expect(jest.getTimerCount()).toBe(0);
  publish([notice(1)]);
  expect(panel.queryByRole('region')).toBeNull();
  publish([notice(1), notice(2, 'Ещё одно событие')]);
  expect(jest.getTimerCount()).toBe(1);
  panel.unmount();
  expect(jest.getTimerCount()).toBe(0);
  expect(topic).not.toHaveBeenCalled();
});

test('the combat page discards combat notices without hiding file notices or replaying combat history on exit', () => {
  const { publish, store, topic } = setup();
  const panel = render(<NoticeToasts />);
  const combat: NetrunNotice = { ...notice(1, 'Ваш ход'), topic: 'combat' };
  const file = notice(2, 'Файл получен');
  publish([combat, file]);
  expect(panel.getByText('Ваш ход')).toBeTruthy();
  act(() => store.dispatch(backendUpdate({ data: { workspace_view: 'combat' } })));
  expect(panel.queryByText('Ваш ход')).toBeNull();
  expect(panel.getByText('Файл получен')).toBeTruthy();
  publish([combat, file, { ...combat, id: 3 }]);
  expect(panel.queryByText('Ваш ход')).toBeNull();
  act(() => store.dispatch(backendUpdate({ data: { workspace_view: 'map' } })));
  expect(panel.queryByText('Ваш ход')).toBeNull();
  expect(panel.getByText('Файл получен')).toBeTruthy();
  expect(topic).not.toHaveBeenCalled();
});

test('toast insertion preserves existing control nodes, their DOM positions and input focus', () => {
  const { publish } = setup();
  const panel = render(<>
    <main data-testid="workspace"><input aria-label="Команда" defaultValue="scan" /><button type="button">Запустить</button></main>
    <NoticeToasts />
                       </>);
  const workspace = panel.getByTestId('workspace');
  const input = panel.getByRole('textbox');
  const button = panel.getByRole('button', { name: 'Запустить' });
  const content = workspace.innerHTML;
  const position = input.compareDocumentPosition(button);
  input.focus();
  publish([notice(1, 'Ваш ход'), notice(2, 'Недостаточно ОД', 'bad')]);
  expect(document.activeElement).toBe(input);
  expect(panel.getByRole('textbox')).toBe(input);
  expect(panel.getByRole('button', { name: 'Запустить' })).toBe(button);
  expect(input.nextElementSibling).toBe(button);
  expect(input.compareDocumentPosition(button)).toBe(position);
  expect(workspace.innerHTML).toBe(content);
  expect(panel.getByRole('region').parentElement).toBe(document.body);
  expect(workspace.contains(panel.getByRole('region'))).toBe(false);
  act(() => jest.advanceTimersByTime(7000));
  expect(document.activeElement).toBe(input);
  expect(workspace.innerHTML).toBe(content);
});

test('a restarted console establishes a fresh baseline instead of replaying its history', () => {
  const { publish } = setup();
  const panel = render(<NoticeToasts />);
  publish([notice(20, 'Старый сеанс')]);
  publish([notice(1, 'История нового сеанса')]);
  expect(panel.queryByRole('region')).toBeNull();
  publish([notice(1, 'История нового сеанса'), notice(2, 'Новое уведомление')]);
  expect(panel.getByText('Новое уведомление')).toBeTruthy();
});

import { fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';
import { ReactElement } from 'react';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { formatClock, resetLocked, SectorBooking, sectorClosed, SquadData, SquadEntry, TrainingSquads } from './AntagTrainingSquads';

const members = [
  { id: 'me', name: 'Ая', self: 1, connected: 1 },
  { id: 'bo', name: 'Бо', self: 0, connected: 1 },
  { id: 've', name: 'Ве', self: 0, connected: 1 },
];
const alpha: SquadEntry = { id: 'alpha', name: 'Альфа', color: '#e05d5d', open: 1, leader: 'Ая', members: [{ id: 'me', name: 'Ая', leader: 1 }, { id: 'bo', name: 'Бо', leader: 0 }], sector: null, sector_id: null, mine: 1, invited: [] };
const beta: SquadEntry = { id: 'beta', name: 'Бета', color: '#4fb3d9', open: 1, leader: 'Ве', members: [{ id: 've', name: 'Ве', leader: 1 }], sector: 'Тёмный сектор', sector_id: 'dark', mine: 0, invited: [] };
const freeBooking = { id: 'atmos', squad: null, color: null, mine: 0, leader: 0, waitlist: [], on_waitlist: 0, remaining: 0, idle_remaining: 0 };
const base: SquadData = { squads: [], squad_invites: [], squad: null, squad_leader: 0, bookings: {}, booking_used: 0, booking_max: 4, booking_minutes: 40, booking_idle_minutes: 5, squad_invite_seconds: 30 };

let now = Date.now();

const setup = (data: SquadData, element: ReactElement) => {
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'AntagTraining' }, data: { ...base, ...data } }));
  const sent = (type: string) => topic.mock.calls.map(([message]) => message).find((message) => message.type === `act/${type}`);
  return { ...render(element), topic, sent };
};

test('без группы: собрать группу с названием и закрытым входом', () => {
  const ui = setup({}, <TrainingSquads members={members} />);
  fireEvent.input(ui.getByPlaceholderText('Название (можно не указывать)'), { target: { value: 'Гамма' } });
  fireEvent.click(ui.getByText('Открытая'));
  fireEvent.click(ui.getByText('Собрать группу'));
  expect(JSON.parse(ui.sent('squad_create').payload)).toEqual({ name: 'Гамма', open: false });
});

test('приглашение принимается и отклоняется, в открытую чужую группу можно войти', () => {
  const ui = setup({ squads: [beta], squad_invites: [{ id: 'beta', name: 'Бета', color: '#4fb3d9', remaining: 21 }] }, <TrainingSquads members={members} />);
  expect(ui.getByText(/Ответьте в течение 21 с/)).toBeTruthy();
  fireEvent.click(ui.getByText('Принять'));
  expect(JSON.parse(ui.sent('squad_accept').payload)).toEqual({ id: 'beta' });
  fireEvent.click(ui.getByText('Отказаться'));
  expect(JSON.parse(ui.sent('squad_decline').payload)).toEqual({ id: 'beta' });
  fireEvent.click(ui.getByText('Войти'));
  expect(JSON.parse(ui.sent('squad_join').payload)).toEqual({ id: 'beta' });
});

test('лидер приглашает, исключает, передаёт главенство и закрывает группу', () => {
  const ui = setup({ squads: [alpha], squad: 'alpha', squad_leader: 1 }, <TrainingSquads members={members} />);
  expect(ui.queryByText('Бо', { selector: 'button *' })).toBeNull();
  fireEvent.click(ui.getByText('Ве'));
  expect(JSON.parse(ui.sent('squad_invite').payload)).toEqual({ id: 've' });
  fireEvent.click(ui.getByText('Исключить'));
  expect(JSON.parse(ui.sent('squad_kick').payload)).toEqual({ id: 'bo' });
  fireEvent.click(ui.getByText('Сделать лидером'));
  expect(JSON.parse(ui.sent('squad_leader').payload)).toEqual({ id: 'bo' });
  fireEvent.click(ui.getByText('Открытая группа: войти может любой'));
  expect(ui.sent('squad_open')).toBeTruthy();
  fireEvent.click(ui.getByText('Выйти из группы'));
  fireEvent.click(ui.getByText('Лидером станет следующий. Выйти?'));
  expect(ui.sent('squad_leave')).toBeTruthy();
});

test('ожидающее приглашение видно лидеру и не дублируется', () => {
  const ui = setup({ squads: [{ ...alpha, invited: [{ id: 've', name: 'Ве', remaining: 12 }] }], squad: 'alpha', squad_leader: 1 }, <TrainingSquads members={members} />);
  const button = ui.getByText('Ве · ждём 12 с').closest('.Button');
  expect(button?.className).toContain('Button--disabled');
});

test('свободный сектор: лидер бронирует, при потолке кнопка закрыта', () => {
  const ui = setup({ squads: [alpha], squad: 'alpha', squad_leader: 1, bookings: { atmos: freeBooking } }, <SectorBooking sectorId="atmos" />);
  fireEvent.click(ui.getByText('Забронировать'));
  expect(JSON.parse(ui.sent('booking_book').payload)).toEqual({ id: 'atmos' });
  ui.unmount();
  const full = setup({ squads: [alpha], squad: 'alpha', squad_leader: 1, bookings: { atmos: freeBooking }, booking_used: 4 }, <SectorBooking sectorId="atmos" />);
  expect(full.getByText('Забронировать').closest('.Button')?.className).toContain('Button--disabled');
});

test('чужая бронь: срок, очередь и кнопки очереди', () => {
  const booking = { id: 'dark', squad: 'Бета', color: '#4fb3d9', mine: 0, leader: 0, waitlist: ['Бо'], on_waitlist: 0, remaining: 725, idle_remaining: 300 };
  const data = { squads: [beta], bookings: { dark: booking } };
  const ui = setup(data, <SectorBooking sectorId="dark" />);
  expect(ui.getByText(/Занят группой «Бета» · ещё 12:05/)).toBeTruthy();
  expect(ui.getByText(/В очереди: 1 \(Бо\)/)).toBeTruthy();
  fireEvent.click(ui.getByText('Встать в очередь'));
  expect(JSON.parse(ui.sent('waitlist_join').payload)).toEqual({ id: 'dark' });
  expect(sectorClosed(data, 'dark')).toBe(true);
  expect(resetLocked(data, 'dark')).toBe(true);
  ui.unmount();
  const waiting = setup({ squads: [beta], bookings: { dark: { ...booking, on_waitlist: 1 } } }, <SectorBooking sectorId="dark" />);
  fireEvent.click(waiting.getByText('Выйти из очереди'));
  expect(JSON.parse(waiting.sent('waitlist_leave').payload)).toEqual({ id: 'dark' });
});

test('освободившийся сектор придержан за группой из очереди: чужой лидер видит срок и не бронирует, своя группа бронирует', () => {
  const held = { ...freeBooking, id: 'dark', priority: 'Бета', priority_mine: 0, priority_remaining: 42 };
  const data = { squads: [alpha], squad: 'alpha', squad_leader: 1, bookings: { dark: held } };
  const ui = setup(data, <SectorBooking sectorId="dark" />);
  expect(ui.getByText(/Первой занять может группа «Бета» из очереди · ещё 0:42/)).toBeTruthy();
  fireEvent.click(ui.getByText('Забронировать'));
  expect(ui.sent('booking_book')).toBeUndefined();
  ui.unmount();
  const mine = setup({ ...data, bookings: { dark: { ...held, priority: 'Альфа', priority_mine: 1 } } }, <SectorBooking sectorId="dark" />);
  expect(mine.getByText(/Придержан за вашей группой из очереди · ещё 0:42/)).toBeTruthy();
  fireEvent.click(mine.getByText('Забронировать'));
  expect(JSON.parse(mine.sent('booking_book').payload)).toEqual({ id: 'dark' });
});

test('своя бронь: лидер продлевает без очереди и освобождает', () => {
  const booking = { id: 'dark', squad: 'Альфа', color: '#e05d5d', mine: 1, leader: 1, waitlist: [], on_waitlist: 0, remaining: 2400, idle_remaining: 299 };
  const data = { squads: [{ ...alpha, sector: 'Тёмный сектор', sector_id: 'dark' }], squad: 'alpha', squad_leader: 1, bookings: { dark: booking } };
  const ui = setup(data, <SectorBooking sectorId="dark" />);
  expect(sectorClosed(data, 'dark')).toBe(false);
  expect(resetLocked(data, 'dark')).toBe(false);
  expect(ui.getByText(/бронь снимется через 4:59/)).toBeTruthy();
  fireEvent.click(ui.getByText('Продлить'));
  expect(ui.sent('booking_extend')).toBeTruthy();
  fireEvent.click(ui.getByText('Освободить'));
  fireEvent.click(ui.getByText('Снять бронь?'));
  expect(ui.sent('booking_release')).toBeTruthy();
  ui.unmount();
  const queued = setup({ ...data, bookings: { dark: { ...booking, waitlist: ['Ве'] } } }, <SectorBooking sectorId="dark" />);
  expect(queued.getByText('Продлить').closest('.Button')?.className).toContain('Button--disabled');
});

test('часы в формате м:сс', () => {
  expect(formatClock(0)).toBe('0:00');
  expect(formatClock(65)).toBe('1:05');
  expect(formatClock(2400)).toBe('40:00');
});

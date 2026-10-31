import { act, fireEvent, render, within } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../../backend';
import { EntityContacts } from './EntityContacts';
import { FileExchangePanel } from './FileExchange';
import { FilePanel } from './FilePanel';
import { EntityContact, IncomingFileOffer } from './types';

const contact: EntityContact = { ref: 'recipient', name: 'Мотылёк', kind: 'entity', integrity: 90, max_integrity: 100,
  state: 'резидент', self: false, can_signal: true, can_message: true, can_offer: true,
  faction_name: 'Станционная сеть', faction_color: '#6fb6ff' };
const incoming: IncomingFileOffer = { id: 'offer-1', sender: 'Мотылёк', name: 'разведчик.bot', kind: 'bot', size: 8, ttl: 118, can_accept: true };
let actionTime = Date.now();
beforeEach(() => { actionTime += 1000; jest.spyOn(Date, 'now').mockReturnValue(actionTime); });
afterEach(() => jest.restoreAllMocks());
const setup = () => {
  const topic = jest.fn(); (global as any).Byond = { topic, winset: () => {} };
  const store = createStore(combineReducers({ backend: backendReducer })); setGlobalStore(store);
  store.dispatch(backendUpdate({ data: { storage: { used: 1, capacity: 20, files: [{ uid: 'local', name: 'Заметка.txt', kind: 'text', size: 1 }] },
    shard: { name: 'Шард', files: [{ uid: 'shard-bot', name: 'Разведчик.bot', kind: 'bot', size: 8 }] },
    file_exchange: { incoming: [incoming], max_offers: 8 }, file: null } }));
  const sent = (action: string) => topic.mock.calls.filter(([message]) => message.type === `act/${action}`).map(([message]) => JSON.parse(message.payload));
  const update = (data: object) => act(() => store.dispatch(backendUpdate({ data })));
  return { sent, update };
};

test('an explicit file proposal uses the current contact/node and owned UID, with its faction badge', () => {
  const { sent, update } = setup();
  const panel = render(<EntityContacts address="LAN:0042" contacts={[contact]} pending={false} localEntity />);
  expect(panel.getByText('Станционная сеть')).toBeTruthy();
  expect(panel.queryByLabelText('Файл для Мотылёк')).toBeNull();
  fireEvent.click(panel.getByText('Предложить копию файла'));
  fireEvent.change(panel.getByLabelText('Файл для Мотылёк'), { target: { value: 'shard-bot' } });
  fireEvent.click(panel.getByText('Отправить предложение'));
  expect(sent('entity_file_offer')).toEqual([{ ref: 'recipient', address: 'LAN:0042', uid: 'shard-bot' }]);
  update({ shard: null });
  fireEvent.click(panel.getByText('Отправить предложение'));
  expect(sent('entity_file_offer')).toHaveLength(1);
  panel.rerender(<EntityContacts address="LAN:0042" contacts={[{ ...contact, can_offer: false, offer_reason: 'Нет маршрута к получателю.' }]} pending={false} localEntity />);
  expect(panel.getByText('Нет маршрута к получателю.')).toBeTruthy();
  fireEvent.change(panel.getByLabelText('Файл для Мотылёк'), { target: { value: 'local' } });
  fireEvent.click(panel.getByText('Отправить предложение'));
  expect(sent('entity_file_offer')).toHaveLength(1);
});

test('incoming metadata requires explicit acceptance and remains visible until a server update', () => {
  const { sent, update } = setup();
  const panel = render(<FilePanel />);
  const mailbox = panel.getByRole('region', { name: 'Входящие предложения файлов' });
  expect(within(mailbox).getByText('разведчик.bot')).toBeTruthy();
  expect(sent('entity_file_accept')).toHaveLength(0);
  fireEvent.click(within(mailbox).getByText('Принять в память'));
  expect(sent('entity_file_accept')).toEqual([{ id: 'offer-1' }]);
  expect(panel.container.querySelector('[data-net-file-offer="offer-1"]')).not.toBeNull();
  fireEvent.click(within(mailbox).getByText('Отклонить'));
  expect(sent('entity_file_reject')).toEqual([{ id: 'offer-1' }]);
  update({ file_exchange: { incoming: [], max_offers: 8 } });
  expect(panel.queryByRole('region', { name: 'Входящие предложения файлов' })).toBeNull();
});

test('a full recipient keeps a reject option and receives a visible acceptance denial', () => {
  const { sent, update } = setup();
  update({ file_exchange: { incoming: [{ ...incoming, can_accept: false, reason: 'В памяти не хватает места.' }], max_offers: 8 } });
  const panel = render(<FileExchangePanel />);
  expect(panel.getByText('В памяти не хватает места.')).toBeTruthy();
  fireEvent.click(panel.getByText('Принять в память'));
  expect(sent('entity_file_accept')).toHaveLength(0);
  fireEvent.click(panel.getByText('Отклонить'));
  expect(sent('entity_file_reject')).toEqual([{ id: 'offer-1' }]);
});

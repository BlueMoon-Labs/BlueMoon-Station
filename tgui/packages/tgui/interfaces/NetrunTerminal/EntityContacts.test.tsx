import { fireEvent, render } from '@testing-library/react';

import { BotAvatar, EntityContacts, factionLabel } from './EntityContacts';
import type { EntityContact } from './types';

const mockAct = jest.fn();
const mockData = { storage: { files: [{ uid: 'local-note', name: 'note.txt', kind: 'text', size: 1 }], used: 1, capacity: 20 } };
jest.mock('./useNetrunBackend', () => ({ useNetrunBackend: () => ({ act: mockAct, data: mockData }) }));

test('contact avatars resolve visitor roles and use sanitized faction metadata', () => {
  const panel = render(<BotAvatar kind="redshift_hacker" faction="redshift" factionColor="#123456" />);
  const avatar = panel.getByRole('img', { name: 'Бот: Диверсант Красного смещения' });
  expect(avatar.getAttribute('data-bot-glyph')).toBe('cipher');
  expect(avatar.style.color).toBe('rgb(18, 52, 86)');
  expect(avatar.querySelectorAll('svg path')).toHaveLength(2);
  panel.rerender(<BotAvatar kind="unknown" faction="owner:4" factionColor="var(--untrusted)" />);
  expect(panel.getByRole('img').style.color).toBe('rgb(119, 217, 173)');
  expect(panel.getByRole('img').getAttribute('data-bot-glyph')).toBe('robot');
  expect(factionLabel('bot', 'archivists')).toBe('Вольный архив');
  expect(factionLabel('fortress', 'owner:4')).toBe('частная');
});

test('contact card, faction label and role icon agree on the authoritative faction colour', () => {
  const contact: EntityContact = { ref: 'r', name: 'A-7', kind: 'bot', bot_kind: 'archive_collector', faction: 'archivists',
    faction_name: 'Вольный архив', faction_color: '#d5c77d', integrity: 70, max_integrity: 90, state: 'сбор',
    self: false, can_signal: false, can_message: false };
  const panel = render(<EntityContacts address="ENG:1" contacts={[contact]} pending={false} localEntity={false} />);
  expect(panel.getByRole('img').getAttribute('data-bot-glyph')).toBe('archive');
  expect(panel.getByRole('img').style.color).toBe('rgb(213, 199, 125)');
  expect(panel.getByText('Вольный архив').style.color).toBe('rgb(213, 199, 125)');
  expect(panel.container.querySelector<HTMLElement>('[data-net-contact]').style.borderColor).toBe('rgb(213, 199, 125)');
  expect(panel.getByText(/Собиратель Вольного архива/)).toBeTruthy();
});

test('ICE capabilities expose routed messages and file offers while preserving BLACK ICE danger', () => {
  const contact: EntityContact = { ref: 'black-ice', name: 'ICE-A', kind: 'ice', ice_kind: 'black',
    integrity: 120, max_integrity: 120, state: 'охрана', self: false,
    can_signal: true, can_message: true, can_offer: true, threat: 'Доступ USER не защищает. Выход из узла срывает доставку.' };
  const panel = render(<EntityContacts address="LAN:42" contacts={[contact]} pending={false} localEntity />);
  expect(panel.getByText(/Нелегальный BLACK ICE: нейрообратная связь/)).toBeTruthy();
  expect(panel.getByText(contact.threat)).toBeTruthy();
  fireEvent.click(panel.getByText('Послать сигнал'));
  expect(mockAct).toHaveBeenCalledWith('entity_signal', { ref: 'black-ice' });
  const input = panel.getByLabelText('Сообщение для ICE-A') as HTMLInputElement;
  fireEvent.change(input, { target: { value: 'Принять связь' } });
  fireEvent.submit(input.closest('form'));
  expect(mockAct).toHaveBeenCalledWith('entity_message', { ref: 'black-ice', text: 'Принять связь' });
  fireEvent.click(panel.getByText('Предложить копию файла'));
  fireEvent.change(panel.getByLabelText('Файл для ICE-A'), { target: { value: 'local-note' } });
  fireEvent.click(panel.getByText('Отправить предложение'));
  expect(mockAct).toHaveBeenCalledWith('entity_file_offer', { ref: 'black-ice', address: 'LAN:42', uid: 'local-note' });
  expect(panel.getByText(/Нелегальный BLACK ICE: нейрообратная связь/)).toBeTruthy();
  expect(panel.getByText(contact.threat)).toBeTruthy();
});

test('bot communication follows server capabilities and pending ICE controls cannot emit actions', () => {
  const contact: EntityContact = { ref: 'bot-peer', name: 'BOT-A', kind: 'bot', bot_kind: 'mender',
    integrity: 90, max_integrity: 90, state: 'ремонт', self: false, can_signal: true, can_message: true };
  const panel = render(<EntityContacts address="LAN:42" contacts={[contact]} pending={false} localEntity />);
  const input = panel.getByLabelText('Сообщение для BOT-A');
  fireEvent.change(input, { target: { value: 'Связь с агентом' } });
  fireEvent.submit(input.closest('form'));
  expect(mockAct).toHaveBeenCalledWith('entity_message', { ref: 'bot-peer', text: 'Связь с агентом' });
  mockAct.mockClear();
  const ice: EntityContact = { ...contact, ref: 'ice-peer', name: 'ICE-A', kind: 'ice', ice_kind: 'sentry', can_offer: true };
  panel.rerender(<EntityContacts address="LAN:42" contacts={[ice]} pending localEntity />);
  fireEvent.click(panel.getByText('Послать сигнал'));
  fireEvent.click(panel.getByText('Предложить копию файла'));
  expect((panel.getByLabelText('Сообщение для ICE-A') as HTMLInputElement).disabled).toBe(true);
  expect(mockAct).not.toHaveBeenCalled();
  panel.rerender(<EntityContacts address="LAN:42" contacts={[{ ...ice, can_signal: false, can_message: false, can_offer: false,
    offer_reason: 'Нет доступа к процессу.' }]} pending={false} localEntity />);
  expect(panel.queryByLabelText('Сообщение для ICE-A')).toBeNull();
  expect(panel.getByText('Нет доступа к процессу.')).toBeTruthy();
});

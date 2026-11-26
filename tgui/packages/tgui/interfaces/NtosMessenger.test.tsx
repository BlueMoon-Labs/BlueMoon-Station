import { fireEvent, render, screen } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { CreditsTransferNote, NtosMessenger } from './NtosMessenger';

const setup = (data: Record<string, unknown>) => {
  (global as any).Byond = { winset: () => {}, topic: jest.fn() };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'NtosMessenger' }, data }));
  return store;
};

describe('CreditsTransferNote', () => {
  it('показывает лимит и кулдаун перевода из данных сервера', () => {
    setup({ credits_transfer_max: 50000, credits_transfer_cooldown: 5 });
    const { container } = render(<CreditsTransferNote />);
    const text = container.textContent || '';
    expect(text).toContain('до 50000 кр. за раз');
    expect(text).toContain('не чаще раза в 5 с');
    expect(text).toContain('Только с личного счёта на личный');
  });
});

it('сохраняет ввод при получении первого сообщения и разделяет черновики разных адресатов', () => {
  const recipient = { ref: 'messenger1', name: 'Алекс', job: 'Повар' };
  const other = { ref: 'messenger2', name: 'Саша', job: 'Ассистент' };
  const store = setup({
    open_chat: recipient.ref,
    messengers: { [recipient.ref]: recipient, [other.ref]: other },
    saved_chats: {},
  });
  const { rerender } = render(<NtosMessenger />);
  const input = () => screen.getByPlaceholderText(/Отправить сообщение/) as HTMLInputElement;
  fireEvent.input(input(), { target: { value: 'Текст до первого сообщения' } });
  expect(input().value).toBe('Текст до первого сообщения');

  store.dispatch(backendUpdate({
    data: {
      open_chat: 'chat1',
      saved_chats: {
        chat1: {
          ref: 'chat1',
          recipient,
          messages: [{ message: 'Привет', outgoing: 0 }],
          unread_messages: 1,
          can_reply: 1,
          blocked: 0,
        },
      },
    },
  }));
  rerender(<NtosMessenger />);
  expect(input().value).toBe('Текст до первого сообщения');

  store.dispatch(backendUpdate({ data: { open_chat: other.ref } }));
  rerender(<NtosMessenger />);
  expect(input().value).toBe('');
});

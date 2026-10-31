import { act, fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { NtosMessenger } from './NtosMessenger';

const setup = () => {
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, winget: () => Promise.resolve('600x850'), topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({
    config: { interface: 'NtosMessenger', title: 'Messenger', window: { key: 'messenger-test', fancy: false } },
    data: {
      saved_chats: {}, open_chat: 'recipient',
      messengers: { recipient: { ref: 'recipient', name: 'Получатель', job: 'Инженер' } },
      emoji_list: [], delivery_status: null,
    },
  }));
  return { store, topic };
};

test('delivery updates announce their status without replacing an unfinished message', () => {
  const { store, topic } = setup();
  const panel = render(<NtosMessenger />);
  const composer = panel.getByPlaceholderText('Отправить сообщение Получатель...');
  fireEvent.input(composer, { target: { value: 'Текст следующего сообщения' } });
  for (const [status, pending, error] of [
    ['Запрос отправлен. Ожидается подтверждение доставки.', true, false],
    ['Сообщение доставлено.', false, false],
    ['Доставка отклонена: получатель отключён от сети.', false, true],
  ]) {
    act(() => store.dispatch(backendUpdate({ data: {
      delivery_status: status, delivery_pending: pending, delivery_error: error,
    } })));
    panel.rerender(<NtosMessenger />);
    expect(panel.getByRole('status').textContent).toBe(status);
    expect(panel.getByPlaceholderText('Отправить сообщение Получатель...')).toBe(composer);
    expect((composer as HTMLInputElement).value).toBe('Текст следующего сообщения');
  }
  fireEvent.keyDown(composer, { key: 'Enter', keyCode: 13 });
  expect(topic.mock.calls.some(([message]) => message.type === 'act/PDA_sendMessage')).toBe(true);
});

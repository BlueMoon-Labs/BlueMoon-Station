import { sendMessage } from 'tgui/backend';

import { chatRenderer } from '../chat/renderer';
import { pingMiddleware } from './middleware';

jest.mock('tgui/backend', () => ({ sendMessage: jest.fn() }));
jest.mock('../chat/renderer', () => ({ chatRenderer: { visibleMessages: [] } }));

describe('pingMiddleware', () => {
  beforeEach(() => {
    jest.useFakeTimers();
    sendMessage.mockClear();
  });

  afterEach(() => {
    jest.clearAllTimers();
    jest.useRealTimers();
  });

  it('шлёт в пинге число сообщений на экране чата', () => {
    chatRenderer.visibleMessages = new Array(42);
    const dispatch = pingMiddleware({ dispatch: jest.fn() })(() => {});
    dispatch({ type: 'noop' });
    expect(sendMessage).toHaveBeenCalledTimes(1);
    const { payload } = sendMessage.mock.calls[0][0];
    expect(payload.metrics.chatMessages).toBe(42);
    expect(payload.metrics).not.toHaveProperty('netRtt');
  });
});

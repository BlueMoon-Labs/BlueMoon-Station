import { ACTION_FEEDBACK_TIMING, NetrunActionFeedback } from './actionFeedback';

describe('Netrun action receipts', () => {
  beforeEach(() => jest.useFakeTimers());
  afterEach(() => jest.useRealTimers());

  test('a local action publishes immediately and duplicate WebView clicks retain one nonce', () => {
    const feedback = new NetrunActionFeedback();
    const listener = jest.fn();
    feedback.subscribe(listener);
    const nonce = feedback.begin('remote_act', { address: 'pump', arguments: { pressure: 100 } }, 'Установить давление');
    expect(listener).toHaveBeenCalledTimes(1);
    expect(feedback.snapshot()).toEqual(expect.objectContaining({ nonce, phase: 'sent', label: 'Установить давление' }));
    expect(feedback.begin('remote_act', { address: 'pump', arguments: { pressure: 100 } }, 'Установить давление')).toBe(nonce);
    expect(listener).toHaveBeenCalledTimes(1);
    jest.advanceTimersByTime(ACTION_FEEDBACK_TIMING.duplicate);
    expect(feedback.begin('remote_act', { address: 'pump', arguments: { pressure: 100 } }, 'Установить давление')).not.toBe(nonce);
    feedback.dispose();
    expect(jest.getTimerCount()).toBe(0);
  });

  test('only a matching receipt acknowledges the latest operation; no timeout retries game actions', () => {
    const feedback = new NetrunActionFeedback();
    const older = feedback.begin('command', { id: 'first' }, 'Первая команда');
    const latest = feedback.begin('command', { id: 'second' }, 'Вторая команда');
    feedback.acknowledge(older);
    expect(feedback.snapshot()).toEqual(expect.objectContaining({ nonce: latest, phase: 'sent' }));
    jest.advanceTimersByTime(ACTION_FEEDBACK_TIMING.response);
    expect(feedback.snapshot()?.phase).toBe('delayed');
    expect(jest.getTimerCount()).toBe(0);
    feedback.acknowledge(latest);
    expect(feedback.snapshot()?.phase).toBe('received');
    jest.advanceTimersByTime(ACTION_FEEDBACK_TIMING.receipt);
    expect(feedback.snapshot()).toBeNull();
    feedback.dispose();
  });

  test('feedback retains no file contents, chat text or native arguments and releases listeners', () => {
    const feedback = new NetrunActionFeedback();
    const listener = jest.fn();
    const unsubscribe = feedback.subscribe(listener);
    feedback.begin('file_edit', { address: 'server', content: 'private text', arguments: { passcode: 'secret' } }, 'Сохранение файла');
    expect(feedback.snapshot()?.payload).toEqual({ address: 'server' });
    unsubscribe();
    feedback.acknowledge(feedback.snapshot()?.nonce);
    expect(listener).toHaveBeenCalledTimes(1);
    feedback.dispose();
    expect(feedback.snapshot()).toBeNull();
    expect(jest.getTimerCount()).toBe(0);
  });
});

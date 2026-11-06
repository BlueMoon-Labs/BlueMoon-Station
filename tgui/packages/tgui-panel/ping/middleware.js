/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { sendMessage } from 'tgui/backend';

import { chatRenderer } from '../chat/renderer';
import { pingFail, pingSuccess } from './actions';
import { createClientMetrics, LOOP_PROBE_INTERVAL } from './clientMetrics';
import { PING_INTERVAL, PING_QUEUE_SIZE, PING_TIMEOUT } from './constants';

export const pingMiddleware = store => {
  let initialized = false;
  let index = 0;
  let interval;
  const pings = [];
  const metrics = createClientMetrics();
  // Одна цепочка rAF на окно счёта: у скрытого окна кадр висит, вторую не заводим.
  let counting = false;
  const countFrames = () => {
    counting = metrics.frame();
    if (counting) {
      requestAnimationFrame(countFrames);
    }
  };
  const startProbes = () => {
    setInterval(() => metrics.loopTick(), LOOP_PROBE_INTERVAL);
    document.addEventListener('visibilitychange', () =>
      metrics.noteVisibility(document.hidden),
    );
  };
  const sendPing = () => {
    for (let i = 0; i < PING_QUEUE_SIZE; i++) {
      const ping = pings[i];
      if (ping && Date.now() - ping.sentAt > PING_TIMEOUT) {
        pings[i] = null;
        store.dispatch(pingFail());
      }
    }
    const ping = { index, sentAt: Date.now() };
    pings[index] = ping;
    sendMessage({
      type: 'ping',
      payload: {
        index,
        metrics: metrics.take(document.hidden, chatRenderer.visibleMessages.length),
      },
    });
    metrics.startFrames();
    if (!counting) {
      counting = true;
      requestAnimationFrame(countFrames);
    }
    index = (index + 1) % PING_QUEUE_SIZE;
  };
  return next => action => {
    const { type, payload } = action;
    if (!initialized) {
      initialized = true;
      startProbes();
      interval = setInterval(sendPing, PING_INTERVAL);
      sendPing();
    }
    if (type === 'roundrestart') {
      // Stop pinging because dreamseeker is currently reconnecting.
      // Topic calls in the middle of reconnect will crash the connection.
      clearInterval(interval);
      return next(action);
    }
    if (type === 'pingReply') {
      const { index } = payload;
      const ping = pings[index];
      // Received a timed out ping
      if (!ping) {
        return;
      }
      metrics.noteRoundtrip(Date.now() - ping.sentAt);
      pings[index] = null;
      return next(pingSuccess(ping));
    }
    return next(action);
  };
};

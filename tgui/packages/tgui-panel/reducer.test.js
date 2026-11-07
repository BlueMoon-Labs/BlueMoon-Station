import { configureStore } from 'tgui/store';

import { panelReducer } from './reducer';
import { flushSaveToServer, forgetSentState } from './serverState';
import { updateSettings } from './settings/actions';

describe('tgui panel store', () => {
  beforeEach(() => {
    forgetSentState();
    window.__windowId__ = 'browseroutput';
    global.Byond = {
      topic: jest.fn(),
    };
  });

  test('chunked panel state reaches the server whole', () => {
    const store = configureStore({ reducer: panelReducer });
    store.dispatch(updateSettings({
      highlightText: 'капитан, синдикат, генокрад, еретик, '.repeat(20),
    }));
    flushSaveToServer(store);

    const sent = global.Byond.topic.mock.calls.map(([params]) => params);
    const request = sent.find(params => params.type === 'oversizedPayloadRequest');
    const { id, chunkCount } = JSON.parse(request.payload);
    const queued = store.getState().backend.outgoingPayloadQueues[id].chunks;
    expect(queued).toHaveLength(chunkCount);
    expect(chunkCount).toBeGreaterThan(2);

    // Сервер разрешает передачу и подтверждает каждый пришедший чанк.
    store.dispatch({ type: 'oversizePayloadResponse', payload: { allow: 1, id } });
    const received = [];
    for (let i = 0; i < chunkCount; i++) {
      const chunkMessages = global.Byond.topic.mock.calls
        .map(([params]) => params)
        .filter(params => params.type === 'payloadChunk');
      if (chunkMessages.length === received.length) {
        break;
      }
      received.push(JSON.parse(chunkMessages[received.length].payload).chunk);
      store.dispatch({
        type: 'acknowlegePayloadChunk',
        payload: { id, index: received.length },
      });
    }

    expect(received).toEqual(queued);
    expect(store.getState().backend.outgoingPayloadQueues[id]).toBeUndefined();
  });

  // WebView2 умеет доставить сообщение дважды: повтор подтверждения не должен ни снимать
  // лишний чанк, ни отправлять тот же чанк заново.
  test('a repeated chunk acknowledgement changes nothing', () => {
    const store = configureStore({ reducer: panelReducer });
    store.dispatch(updateSettings({
      highlightText: 'капитан, синдикат, генокрад, еретик, '.repeat(20),
    }));
    flushSaveToServer(store);
    const request = global.Byond.topic.mock.calls
      .map(([params]) => params)
      .find(params => params.type === 'oversizedPayloadRequest');
    const { id } = JSON.parse(request.payload);
    store.dispatch({ type: 'oversizePayloadResponse', payload: { allow: 1, id } });

    store.dispatch({ type: 'acknowlegePayloadChunk', payload: { id, index: 1 } });
    const sentAfterAck = global.Byond.topic.mock.calls.length;
    store.dispatch({ type: 'acknowlegePayloadChunk', payload: { id, index: 1 } });

    expect(global.Byond.topic.mock.calls.length).toBe(sentAfterAck);
    expect(store.getState().backend.outgoingPayloadQueues[id].acked).toBe(1);
    const lastChunk = JSON.parse(global.Byond.topic.mock.calls[sentAfterAck - 1][0].payload);
    expect(lastChunk.index).toBe(2);
  });
});

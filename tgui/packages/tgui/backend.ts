/**
 * This file provides a clear separation layer between backend updates
 * and what state our React app sees.
 *
 * Sometimes backend can response without a "data" field, but our final
 * state will still contain previous "data" because we are merging
 * the response with already existing state.
 *
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { defer } from 'common/defer';
import { perf } from 'common/perf';
import { createAction } from 'common/redux';

import {
  resetInitialGeometryReady,
  setupDrag,
  waitForInitialGeometryReady,
} from './drag';
import { focusMap } from './focus';
import { createLogger } from './logging';
import { resumeRenderer, suspendRenderer } from './renderer';

const logger = createLogger('backend');

export const backendUpdate = createAction('backend/update');
export const backendSetSharedState = createAction('backend/setSharedState');
export const backendSuspendStart = createAction('backend/suspendStart');
export const backendCreatePayloadQueue = createAction(
  'backend/createPayloadQueue',
);
export const backendDequeuePayloadQueue = createAction(
  'backend/dequeuePayloadQueue',
);
export const backendRemovePayloadQueue = createAction(
  'backend/removePayloadQueue',
);
export const nextPayloadChunk = createAction('nextPayloadChunk');

export const backendSuspendSuccess = () => ({
  type: 'backend/suspendSuccess',
  payload: {
    timestamp: Date.now(),
  },
});

const initialState = {
  config: {},
  data: {},
  shared: {},
  outgoingPayloadQueues: {} as Record<string, string[]>,
  // Start as suspended
  suspended: Date.now(),
  suspending: false,
};

export const backendReducer = (state = initialState, action) => {
  const { type, payload } = action;

  if (type === 'backend/update') {
    // Merge config
    const config = {
      ...state.config,
      ...payload.config,
    };
    // Merge data
    const data = {
      ...state.data,
      ...payload.static_data,
      ...payload.data,
    };
    // Merge shared states
    const shared = { ...state.shared };
    if (payload.shared) {
      for (let key of Object.keys(payload.shared)) {
        const value = payload.shared[key];
        if (value === '') {
          shared[key] = undefined;
        }
        else {
          shared[key] = JSON.parse(value);
        }
      }
    }
    // Return new state
    return {
      ...state,
      config,
      data,
      shared,
      suspended: false,
    };
  }

  if (type === 'backend/setSharedState') {
    const { key, nextState } = payload;
    return {
      ...state,
      shared: {
        ...state.shared,
        [key]: nextState,
      },
    };
  }

  if (type === 'backend/suspendStart') {
    return {
      ...state,
      suspending: true,
    };
  }

  if (type === 'backend/suspendSuccess') {
    const { timestamp } = payload;
    return {
      ...state,
      data: {},
      shared: {},
      config: {
        ...state.config,
        title: '',
        status: 1,
      },
      suspending: false,
      suspended: timestamp,
    };
  }

  if (type === 'backend/createPayloadQueue') {
    const { id, chunks } = payload;
    const { outgoingPayloadQueues } = state;
    return {
      ...state,
      outgoingPayloadQueues: {
        ...outgoingPayloadQueues,
        [id]: chunks,
      },
    };
  }

  if (type === 'backend/dequeuePayloadQueue') {
    const { id } = payload;
    const { outgoingPayloadQueues } = state;
    const { [id]: targetQueue, ...otherQueues } = outgoingPayloadQueues;
    const [_, ...rest] = targetQueue;
    return {
      ...state,
      outgoingPayloadQueues: rest.length
        ? {
            ...otherQueues,
            [id]: rest,
          }
        : otherQueues,
    };
  }

  if (type === 'backend/removePayloadQueue') {
    const { id } = payload;
    const { outgoingPayloadQueues } = state;
    const { [id]: _, ...otherQueues } = outgoingPayloadQueues;
    return {
      ...state,
      outgoingPayloadQueues: otherQueues,
    };
  }

  return state;
};

export const backendMiddleware = store => {
  // 516 migration: increased from 500ms; allows SIZE_APPLY_TIMEOUT_MS to complete
  // before the fallback reveal fires, preventing fullscreen flash on slow servers.
  const INITIAL_VISIBILITY_GATE_TIMEOUT = 2000;
  let fancyState;
  let suspendInterval;

  return next => action => {
    const { suspended, outgoingPayloadQueues } = selectBackend(
      store.getState(),
    );
    const { type, payload } = action;

    if (type === 'update') {
      store.dispatch(backendUpdate(payload));
      return;
    }

    if (type === 'suspend') {
      store.dispatch(backendSuspendSuccess());
      return;
    }

    if (type === 'ping') {
      sendMessage({
        type: 'pingReply',
      });
      return;
    }

    if (type === 'backend/suspendStart' && !suspendInterval) {
      logger.log(`suspending (${window.__windowId__})`);
      // Keep sending suspend messages until it succeeds.
      // It may fail multiple times due to topic rate limiting.
      const suspendFn = () => sendMessage({
        type: 'suspend',
      });
      suspendFn();
      suspendInterval = setInterval(suspendFn, 2000);
    }

    if (type === 'backend/suspendSuccess') {
      suspendRenderer();
      clearInterval(suspendInterval);
      suspendInterval = undefined;
      Byond.winset(window.__windowId__, {
        'is-visible': false,
      });
      defer(() => focusMap());
    }

    if (type === 'backend/update') {
      const fancy = payload.config?.window?.fancy;
      // Initialize fancy state
      if (fancyState === undefined) {
        fancyState = fancy;
      }
      // React to changes in fancy
      else if (fancyState !== fancy) {
        logger.log('changing fancy mode to', fancy);
        fancyState = fancy;
        Byond.winset(window.__windowId__, {
          titlebar: !fancy,
          'can-resize': !fancy,
        });
      }
    }

    // Resume on incoming update
    if (type === 'backend/update' && suspended) {
      resetInitialGeometryReady();
      // Show the payload
      logger.log('backend/update', payload);
      // Signal renderer that we have resumed
      resumeRenderer();
      // Setup drag
      setupDrag(payload.config?.window?.scale);
      // We schedule this for the next tick here because resizing and unhiding
      // during the same tick will flash with a white background.
      defer(async () => {
        perf.mark('resume/start');
        const revealReason = await Promise.race([
          waitForInitialGeometryReady()
            .then(() => 'geometryReady'),
          new Promise<'timeout'>(resolve => {
            setTimeout(() => resolve('timeout'), INITIAL_VISIBILITY_GATE_TIMEOUT);
          }),
        ]);
        // Doublecheck if we are not re-suspended.
        const { suspended } = selectBackend(store.getState());
        if (suspended) {
          return;
        }
        logger.log('showing window after', revealReason);
        Byond.winset(window.__windowId__, {
          'is-visible': true,
        });
        sendMessage({ type: 'visible' });
        perf.mark('resume/finish');
        if (process.env.NODE_ENV !== 'production') {
          logger.log('visible in',
            perf.measure('render/finish', 'resume/finish'));
        }
      });
    }

    if (type === 'oversizePayloadResponse') {
      const { allow } = payload;
      if (allow) {
        store.dispatch(nextPayloadChunk(payload));
      } else {
        store.dispatch(backendRemovePayloadQueue(payload));
      }
    }

    if (type === 'payloadDropped') {
      // Server timed out or rejected this payload — discard queue, stop sending
      store.dispatch(backendRemovePayloadQueue(payload));
    }

    if (type === 'acknowlegePayloadChunk') {
      store.dispatch(backendDequeuePayloadQueue(payload));
      store.dispatch(nextPayloadChunk(payload));
    }

    if (type === 'nextPayloadChunk') {
      const { id } = payload;
      // Always read fresh state after any prior dispatches to get the updated queue
      const { outgoingPayloadQueues: freshQueues } = selectBackend(store.getState());
      if (freshQueues[id]?.length) {
        const chunk = freshQueues[id][0];
        sendMessage({
          type: 'payloadChunk',
          payload: { id, chunk },
        });
      }
    }

    return next(action);
  };
};

/**
 * Sends a message to /datum/tgui_window.
 */
export const sendMessage = (message: any = {}) => {
  const { payload, ...rest } = message;
  const data: any = {
    // Message identifying header
    tgui: 1,
    window_id: window.__windowId__,
    // Message body
    ...rest,
  };
  // JSON-encode the payload
  if (payload !== null && payload !== undefined) {
    data.payload = JSON.stringify(payload);
  }
  Byond.topic(data);
};

const encodedLengthBinarySearch = (charSeq: string[], length: number) => {
  const haystackLength = charSeq.length;
  let high = haystackLength - 1;
  let low = 0;
  let mid = 0;
  while (low < high) {
    mid = Math.round((low + high) / 2);
    const substringLength = encodeURIComponent(
      charSeq.slice(0, mid).join(''),
    ).length;
    if (substringLength === length) {
      break;
    }
    if (substringLength < length) {
      low = mid + 1;
    } else {
      high = mid - 1;
    }
  }
  return mid;
};

const splitIntoChunks = (str: string): string[] => {
  const charSeq = Array.from(str);
  const length = charSeq.length;
  const chunks: string[] = [];
  let startIndex = 0;
  let endIndex = 512;
  while (startIndex < length) {
    const cut = charSeq.slice(
      startIndex,
      endIndex < length ? endIndex : undefined,
    );
    const cutString = cut.join('');
    if (encodeURIComponent(cutString).length > 512) {
      const splitIndex = startIndex + encodedLengthBinarySearch(cut, 512);
      chunks.push(
        charSeq
          .slice(startIndex, splitIndex < length ? splitIndex : undefined)
          .join(''),
      );
      startIndex = splitIndex;
    } else {
      chunks.push(cutString);
      startIndex = endIndex;
    }
    endIndex = startIndex + 512;
  }
  return chunks;
};

/**
 * Debounce state for sendAct — guards against WebView2 duplicate delivery.
 */
let lastActTime = 0;
let lastActKey = '';
let actSequence = 0;

/**
 * Sends an action to `ui_act` on `src_object` that this tgui window
 * is associated with.
 */
export const sendAct = (action: string, payload: object = {}) => {
  // Validate that payload is an object
  const isObject = typeof payload === 'object'
    && payload !== null
    && !Array.isArray(payload);
  if (!isObject) {
    logger.error(`Payload for act() must be an object, got this:`, payload);
    return;
  }
  const stringifiedPayload = JSON.stringify(payload);
  // Debounce identical act calls within 50ms (WebView2 double-delivery guard)
  const now = Date.now();
  const actKey = action + stringifiedPayload;
  if (now - lastActTime < 50 && actKey === lastActKey) {
    return;
  }
  lastActTime = now;
  lastActKey = actKey;
  const seq = ++actSequence;
  const urlSize = Object.entries({
    type: 'act/' + action,
    payload: stringifiedPayload,
    tgui: 1,
    window_id: window.__windowId__,
  }).reduce(
    (url, [key, value], i) =>
      url +
      `${i > 0 ? '&' : '?'}${encodeURIComponent(key)}=${encodeURIComponent(String(value))}`,
    '',
  ).length;
  if (urlSize > 2048) {
    const chunks: string[] = splitIntoChunks(stringifiedPayload);
    const id = `${Date.now()}`;
    (window as any).__store__?.dispatch(
      backendCreatePayloadQueue({ id, chunks }),
    );
    sendMessage({
      type: 'oversizedPayloadRequest',
      payload: {
        type: 'act/' + action,
        id,
        chunkCount: chunks.length,
      },
    });
    return;
  }
  sendMessage({
    type: 'act/' + action,
    payload,
    seq,
  });
};

type BackendState<TData> = {
  config: {
    title: string,
    status: number,
    interface: string,
    refreshing: boolean,
    window: {
      key: string,
      size: [number, number],
      fancy: boolean,
      locked: boolean,
    },
    client: {
      ckey: string,
      address: string,
      computer_id: string,
    },
    user: {
      name: string,
      observer: number,
    },
  },
  data: TData,
  shared: Record<string, any>,
  outgoingPayloadQueues: Record<string, any[]>,
  suspending: boolean,
  suspended: boolean,
}

/**
 * Selects a backend-related slice of Redux state
 */
export const selectBackend = <TData>(state: any): BackendState<TData> => (
  state.backend || {}
);

/**
 * A React hook (sort of) for getting tgui state and related functions.
 *
 * This is supposed to be replaced with a real React Hook, which can only
 * be used in functional components.
 *
 * You can make
 */
export const useBackend = <TData>(context: any) => {
  const { store } = context;
  const state = selectBackend<TData>(store.getState());
  return {
    ...state,
    act: sendAct,
  };
};

/**
 * A tuple that contains the state and a setter function for it.
 */
type StateWithSetter<T> = [T, (nextState: T) => void];

/**
 * Allocates state on Redux store without sharing it with other clients.
 *
 * Use it when you want to have a stateful variable in your component
 * that persists between renders, but will be forgotten after you close
 * the UI.
 *
 * It is a lot more performant than `setSharedState`.
 *
 * @param context React context.
 * @param key Key which uniquely identifies this state in Redux store.
 * @param initialState Initializes your global variable with this value.
 */
export const useLocalState = <T>(
  context: any,
  key: string,
  initialState: T,
): StateWithSetter<T> => {
  const { store } = context;
  const state = selectBackend(store.getState());
  const sharedStates = state.shared ?? {};
  const sharedState = (key in sharedStates)
    ? sharedStates[key]
    : initialState;
  return [
    sharedState,
    nextState => {
      store.dispatch(backendSetSharedState({
        key,
        nextState: (
          typeof nextState === 'function'
            ? nextState(sharedState)
            : nextState
        ),
      }));
    },
  ];
};

/**
 * Allocates state on Redux store, and **shares** it with other clients
 * in the game.
 *
 * Use it when you want to have a stateful variable in your component
 * that persists not only between renders, but also gets pushed to other
 * clients that observe this UI.
 *
 * This makes creation of observable s
 *
 * @param context React context.
 * @param key Key which uniquely identifies this state in Redux store.
 * @param initialState Initializes your global variable with this value.
 */
export const useSharedState = <T>(
  context: any,
  key: string,
  initialState: T,
): StateWithSetter<T> => {
  const { store } = context;
  const state = selectBackend(store.getState());
  const sharedStates = state.shared ?? {};
  const sharedState = (key in sharedStates)
    ? sharedStates[key]
    : initialState;
  return [
    sharedState,
    nextState => {
      sendMessage({
        type: 'setSharedState',
        key,
        value: JSON.stringify(
          typeof nextState === 'function'
            ? nextState(sharedState)
            : nextState
        ) || '',
      });
    },
  ];
};

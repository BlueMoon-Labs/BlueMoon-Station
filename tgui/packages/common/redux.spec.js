import {
  applyMiddleware,
  combineReducers,
  createAction,
  createStore,
  useDispatch,
  useSelector,
} from './redux';

describe('createStore', () => {
  test('инициализируется через @@INIT dispatch', () => {
    const reducer = (state = { count: 0 }) => state;
    const store = createStore(reducer);
    expect(store.getState()).toEqual({ count: 0 });
  });

  test('dispatch обновляет state', () => {
    const reducer = (state = 0, action) => {
      if (action.type === 'INC') return state + 1;
      return state;
    };
    const store = createStore(reducer);
    expect(store.getState()).toBe(0);
    store.dispatch({ type: 'INC' });
    expect(store.getState()).toBe(1);
  });

  test('subscribe вызывает listener при dispatch', () => {
    const reducer = (state = 0, action) => {
      if (action.type === 'INC') return state + 1;
      return state;
    };
    const store = createStore(reducer);
    const listener = jest.fn();
    store.subscribe(listener);
    store.dispatch({ type: 'INC' });
    expect(listener).toHaveBeenCalledTimes(1);
  });

  test('несколько subscribers', () => {
    const reducer = (state = 0) => state;
    const store = createStore(reducer);
    const listener1 = jest.fn();
    const listener2 = jest.fn();
    store.subscribe(listener1);
    store.subscribe(listener2);
    store.dispatch({ type: 'TEST' });
    expect(listener1).toHaveBeenCalledTimes(1);
    expect(listener2).toHaveBeenCalledTimes(1);
  });
});

describe('createAction', () => {
  test('создаёт action с type и payload', () => {
    const increment = createAction('INC');
    const action = increment(5);
    expect(action).toEqual({ type: 'INC', payload: 5 });
  });

  test('toString() возвращает type', () => {
    const increment = createAction('INC');
    expect(String(increment)).toBe('INC');
    expect(`${increment}`).toBe('INC');
  });

  test('.type свойство', () => {
    const increment = createAction('INC');
    expect(increment.type).toBe('INC');
  });

  test('.match() проверяет совпадение type', () => {
    const increment = createAction('INC');
    expect(increment.match({ type: 'INC' })).toBe(true);
    expect(increment.match({ type: 'DEC' })).toBe(false);
  });

  test('с prepare callback', () => {
    const addTodo = createAction('ADD_TODO', (text, priority) => ({
      payload: { text, priority },
      meta: { timestamp: 123 },
    }));
    const action = addTodo('test', 'high');
    expect(action).toEqual({
      type: 'ADD_TODO',
      payload: { text: 'test', priority: 'high' },
      meta: { timestamp: 123 },
    });
  });

  test('prepare без payload/meta — только type', () => {
    const noop = createAction('NOOP', () => ({}));
    expect(noop()).toEqual({ type: 'NOOP' });
  });

  test('prepare вернул falsy -> throw', () => {
    const broken = createAction('BROKEN', () => null);
    expect(() => broken()).toThrow('prepare function did not return an object');
  });

  test('без аргументов -> payload = undefined', () => {
    const action = createAction('TEST');
    expect(action()).toEqual({ type: 'TEST', payload: undefined });
  });
});

describe('combineReducers', () => {
  test('комбинирует несколько reducers', () => {
    const combined = combineReducers({
      count: (state = 0, action) => {
        if (action.type === 'INC') return state + 1;
        return state;
      },
      name: (state = 'default', action) => {
        if (action.type === 'SET_NAME') return action.payload;
        return state;
      },
    });

    let state = combined(undefined, { type: '@@INIT' });
    expect(state).toEqual({ count: 0, name: 'default' });

    state = combined(state, { type: 'INC' });
    expect(state.count).toBe(1);
    expect(state.name).toBe('default');
  });

  test('сохраняет ключи не описанные в reducers', () => {
    const combined = combineReducers({
      managed: (state = 0) => state,
    });
    const prevState = { managed: 0, extra: 'keep me' };
    const nextState = combined(prevState, { type: 'WHATEVER' });
    expect(nextState.extra).toBe('keep me');
  });

  // BUG: hasChanged объявлен в замыкании и никогда не сбрасывается в false
  // После первого изменения state, каждый последующий dispatch возвращает
  // НОВЫЙ объект даже если ничего не изменилось.
  // Это ломает оптимизацию referential equality.
  test('при неизменном state должен возвращать тот же объект (referential equality)', () => {
    const combined = combineReducers({
      count: (state = 0, action) => {
        if (action.type === 'INC') return state + 1;
        return state;
      },
    });

    // Инициализация
    const state1 = combined(undefined, { type: '@@INIT' });

    // Изменение — новый объект (ожидаемо)
    const state2 = combined(state1, { type: 'INC' });
    expect(state2).not.toBe(state1);
    expect(state2.count).toBe(1);

    // Неизменяющий dispatch — ДОЛЖЕН вернуть тот же объект
    // BUG: hasChanged навсегда true после state2, поэтому возвращает новый объект
    const state3 = combined(state2, { type: 'NOOP' });
    expect(state3).toBe(state2); // Fails! state3 !== state2
  });
});

describe('applyMiddleware', () => {
  test('middleware перехватывает dispatch', () => {
    const log = [];
    const logger = store => next => action => {
      log.push(action.type);
      return next(action);
    };

    const reducer = (state = 0, action) => {
      if (action.type === 'INC') return state + 1;
      return state;
    };

    const store = createStore(reducer, applyMiddleware(logger));
    store.dispatch({ type: 'INC' });

    // @@INIT происходит ДО замены dispatch на middleware chain,
    // поэтому middleware видит только INC
    expect(log).toContain('INC');
    expect(store.getState()).toBe(1);
  });

  test('несколько middlewares применяются в правильном порядке', () => {
    const order = [];
    const mid1 = () => next => action => {
      order.push('mid1-before');
      const result = next(action);
      order.push('mid1-after');
      return result;
    };
    const mid2 = () => next => action => {
      order.push('mid2-before');
      const result = next(action);
      order.push('mid2-after');
      return result;
    };

    const reducer = (state = 0) => state;
    const store = createStore(reducer, applyMiddleware(mid1, mid2));

    order.length = 0; // Очищаем после @@INIT
    store.dispatch({ type: 'TEST' });

    // mid1 оборачивает mid2: mid1 -> mid2 -> reducer -> mid2 -> mid1
    expect(order).toEqual([
      'mid1-before',
      'mid2-before',
      'mid2-after',
      'mid1-after',
    ]);
  });

  test('dispatch во время конструирования middleware -> throw', () => {
    const badMiddleware = store => {
      // Пытаемся dispatch во время конструирования
      store.dispatch({ type: 'BAD' });
      return next => action => next(action);
    };

    const reducer = (state = 0) => state;
    expect(() => {
      createStore(reducer, applyMiddleware(badMiddleware));
    }).toThrow('Dispatching while constructing');
  });
});

describe('useDispatch', () => {
  test('возвращает dispatch из store', () => {
    const reducer = (state = 0) => state;
    const store = createStore(reducer);
    const context = { store };
    expect(useDispatch(context)).toBe(store.dispatch);
  });

  test('dispatch через useDispatch обновляет state', () => {
    const reducer = (state = 0, action) => {
      if (action.type === 'INC') return state + 1;
      return state;
    };
    const store = createStore(reducer);
    const dispatch = useDispatch({ store });
    dispatch({ type: 'INC' });
    dispatch({ type: 'INC' });
    expect(store.getState()).toBe(2);
  });
});

describe('useSelector', () => {
  test('вызывает selector с текущим state', () => {
    const reducer = (state = { count: 42, name: 'test' }) => state;
    const store = createStore(reducer);
    const context = { store };
    const result = useSelector(context, state => state);
    expect(result).toEqual({ count: 42, name: 'test' });
  });

  test('selector возвращает часть state', () => {
    const reducer = (state = { count: 42, name: 'test' }) => state;
    const store = createStore(reducer);
    const context = { store };
    expect(useSelector(context, state => state.count)).toBe(42);
    expect(useSelector(context, state => state.name)).toBe('test');
  });

  test('selector видит актуальный state после dispatch', () => {
    const reducer = (state = 0, action) => {
      if (action.type === 'INC') return state + 1;
      return state;
    };
    const store = createStore(reducer);
    const context = { store };
    expect(useSelector(context, s => s)).toBe(0);
    store.dispatch({ type: 'INC' });
    expect(useSelector(context, s => s)).toBe(1);
  });
});

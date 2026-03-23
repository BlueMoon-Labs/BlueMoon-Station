import { EventEmitter } from './events';

describe('EventEmitter', () => {
  let emitter;

  beforeEach(() => {
    emitter = new EventEmitter();
  });

  describe('on / emit', () => {
    test('подписка и вызов listener', () => {
      const listener = jest.fn();
      emitter.on('test', listener);
      emitter.emit('test');
      expect(listener).toHaveBeenCalledTimes(1);
    });

    test('передача аргументов в listener', () => {
      const listener = jest.fn();
      emitter.on('data', listener);
      emitter.emit('data', 'arg1', 42, { key: 'val' });
      expect(listener).toHaveBeenCalledWith('arg1', 42, { key: 'val' });
    });

    test('несколько listeners на одно событие', () => {
      const listener1 = jest.fn();
      const listener2 = jest.fn();
      emitter.on('test', listener1);
      emitter.on('test', listener2);
      emitter.emit('test');
      expect(listener1).toHaveBeenCalledTimes(1);
      expect(listener2).toHaveBeenCalledTimes(1);
    });

    test('listeners вызываются в порядке подписки', () => {
      const order = [];
      emitter.on('test', () => order.push(1));
      emitter.on('test', () => order.push(2));
      emitter.on('test', () => order.push(3));
      emitter.emit('test');
      expect(order).toEqual([1, 2, 3]);
    });

    test('один listener можно подписать несколько раз', () => {
      const listener = jest.fn();
      emitter.on('test', listener);
      emitter.on('test', listener);
      emitter.emit('test');
      expect(listener).toHaveBeenCalledTimes(2);
    });
  });

  describe('off', () => {
    test('отписывает listener', () => {
      const listener = jest.fn();
      emitter.on('test', listener);
      emitter.off('test', listener);
      emitter.emit('test');
      expect(listener).not.toHaveBeenCalled();
    });

    test('несуществующее событие -> throw', () => {
      expect(() => {
        emitter.off('nonexistent', () => {});
      }).toThrow('There is no listeners for "nonexistent"');
    });

    test('отписка одного из нескольких listeners', () => {
      const listener1 = jest.fn();
      const listener2 = jest.fn();
      emitter.on('test', listener1);
      emitter.on('test', listener2);
      emitter.off('test', listener1);
      emitter.emit('test');
      expect(listener1).not.toHaveBeenCalled();
      expect(listener2).toHaveBeenCalledTimes(1);
    });
  });

  describe('emit несуществующее событие', () => {
    test('тихо ничего не делает', () => {
      expect(() => {
        emitter.emit('nonexistent', 'data');
      }).not.toThrow();
    });
  });

  describe('clear', () => {
    test('очищает все listeners', () => {
      const listener1 = jest.fn();
      const listener2 = jest.fn();
      emitter.on('event1', listener1);
      emitter.on('event2', listener2);
      emitter.clear();
      emitter.emit('event1');
      emitter.emit('event2');
      expect(listener1).not.toHaveBeenCalled();
      expect(listener2).not.toHaveBeenCalled();
    });

    test('после clear можно снова подписаться', () => {
      const listener = jest.fn();
      emitter.on('test', listener);
      emitter.clear();
      emitter.on('test', listener);
      emitter.emit('test');
      expect(listener).toHaveBeenCalledTimes(1);
    });
  });
});

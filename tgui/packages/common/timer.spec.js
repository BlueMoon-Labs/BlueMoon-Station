import { debounce, sleep } from './timer';

describe('debounce', () => {
  beforeEach(() => {
    jest.useFakeTimers();
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  test('возвращает функцию', () => {
    const fn = jest.fn();
    expect(typeof debounce(fn, 100)).toBe('function');
  });

  // Trailing edge (по умолчанию)

  test('trailing: функция вызывается после задержки', () => {
    const fn = jest.fn();
    const debounced = debounce(fn, 100);
    debounced();
    expect(fn).not.toHaveBeenCalled();
    jest.advanceTimersByTime(100);
    expect(fn).toHaveBeenCalledTimes(1);
  });

  test('trailing: повторные вызовы сбрасывают таймер', () => {
    const fn = jest.fn();
    const debounced = debounce(fn, 100);
    debounced();
    jest.advanceTimersByTime(50);
    debounced(); // сброс таймера
    jest.advanceTimersByTime(50);
    expect(fn).not.toHaveBeenCalled(); // ещё не прошло 100мс с последнего вызова
    jest.advanceTimersByTime(50);
    expect(fn).toHaveBeenCalledTimes(1);
  });

  test('trailing: аргументы передаются в оригинальную функцию', () => {
    const fn = jest.fn();
    const debounced = debounce(fn, 100);
    debounced('arg1', 'arg2');
    jest.advanceTimersByTime(100);
    expect(fn).toHaveBeenCalledWith('arg1', 'arg2');
  });

  test('trailing: используются аргументы последнего вызова', () => {
    const fn = jest.fn();
    const debounced = debounce(fn, 100);
    debounced('first');
    debounced('second');
    debounced('third');
    jest.advanceTimersByTime(100);
    expect(fn).toHaveBeenCalledTimes(1);
    expect(fn).toHaveBeenCalledWith('third');
  });

  test('trailing: НЕ вызывается до истечения задержки', () => {
    const fn = jest.fn();
    const debounced = debounce(fn, 100);
    debounced();
    jest.advanceTimersByTime(99);
    expect(fn).not.toHaveBeenCalled();
  });

  test('trailing: после вызова — следующий вызов снова ждёт задержку', () => {
    const fn = jest.fn();
    const debounced = debounce(fn, 100);
    debounced();
    jest.advanceTimersByTime(100);
    expect(fn).toHaveBeenCalledTimes(1);
    debounced();
    jest.advanceTimersByTime(100);
    expect(fn).toHaveBeenCalledTimes(2);
  });

  // Leading edge (immediate=true)

  test('immediate: функция вызывается сразу при первом вызове', () => {
    const fn = jest.fn();
    const debounced = debounce(fn, 100, true);
    debounced();
    expect(fn).toHaveBeenCalledTimes(1);
  });

  test('immediate: повторный вызов в период ожидания НЕ вызывает функцию', () => {
    const fn = jest.fn();
    const debounced = debounce(fn, 100, true);
    debounced();
    debounced();
    debounced();
    expect(fn).toHaveBeenCalledTimes(1);
  });

  test('immediate: после истечения таймера можно вызвать снова', () => {
    const fn = jest.fn();
    const debounced = debounce(fn, 100, true);
    debounced();
    expect(fn).toHaveBeenCalledTimes(1);
    jest.advanceTimersByTime(100);
    debounced();
    expect(fn).toHaveBeenCalledTimes(2);
  });

  test('immediate: НЕ вызывает trailing edge', () => {
    const fn = jest.fn();
    const debounced = debounce(fn, 100, true);
    debounced();
    expect(fn).toHaveBeenCalledTimes(1);
    jest.advanceTimersByTime(200);
    // Не должно быть дополнительного вызова на trailing edge
    expect(fn).toHaveBeenCalledTimes(1);
  });

  test('immediate: аргументы передаются в функцию', () => {
    const fn = jest.fn();
    const debounced = debounce(fn, 100, true);
    debounced('hello', 42);
    expect(fn).toHaveBeenCalledWith('hello', 42);
  });
});

describe('sleep', () => {
  beforeEach(() => {
    jest.useFakeTimers();
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  test('возвращает Promise', () => {
    const result = sleep(100);
    expect(result).toBeInstanceOf(Promise);
  });

  test('Promise разрешается после указанного времени', async () => {
    let resolved = false;
    sleep(100).then(() => { resolved = true; });
    expect(resolved).toBe(false);
    jest.advanceTimersByTime(100);
    // Нужно дождаться microtask queue
    await Promise.resolve();
    expect(resolved).toBe(true);
  });

  test('sleep(0) разрешается при следующем тике', async () => {
    let resolved = false;
    sleep(0).then(() => { resolved = true; });
    jest.advanceTimersByTime(0);
    await Promise.resolve();
    expect(resolved).toBe(true);
  });
});

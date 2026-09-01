import { compose, flow } from './fp';

describe('flow', () => {
  test('последовательное применение функций (left-to-right)', () => {
    const add1 = x => x + 1;
    const double = x => x * 2;
    expect(flow(add1, double)(3)).toBe(8); // (3 + 1) * 2 = 8
  });

  test('одна функция', () => {
    const add1 = x => x + 1;
    expect(flow(add1)(5)).toBe(6);
  });

  test('вложенные массивы функций — рекурсивно разворачиваются', () => {
    const add1 = x => x + 1;
    const double = x => x * 2;
    const sub3 = x => x - 3;
    // [add1, double] обрабатывается как вложенный flow
    expect(flow([add1, double], sub3)(3)).toBe(5); // ((3+1)*2) - 3 = 5
  });

  test('falsy элементы пропускаются', () => {
    const add1 = x => x + 1;
    expect(flow(null, add1, undefined, false, add1)(0)).toBe(2);
  });

  test('без функций — возвращает input', () => {
    expect(flow()(42)).toBe(42);
  });

  test('дополнительные аргументы передаются всем функциям', () => {
    const add = (x, y) => x + y;
    const mul = (x, y) => x * y;
    // flow(add, mul)(2, 3):
    // add(2, 3) = 5, mul(5, 3) = 15
    expect(flow(add, mul)(2, 3)).toBe(15);
  });
});

describe('compose', () => {
  test('right-to-left композиция', () => {
    const add1 = x => x + 1;
    const double = x => x * 2;
    // compose(add1, double)(3) = add1(double(3)) = add1(6) = 7
    expect(compose(add1, double)(3)).toBe(7);
  });

  test('0 функций -> identity', () => {
    expect(compose()(42)).toBe(42);
    expect(compose()('hello')).toBe('hello');
  });

  test('1 функция -> passthrough', () => {
    const add1 = x => x + 1;
    expect(compose(add1)(5)).toBe(6);
    // compose(f) возвращает f напрямую, а не обёртку
    expect(compose(add1)).toBe(add1);
  });

  test('три функции', () => {
    const add1 = x => x + 1;
    const double = x => x * 2;
    const square = x => x * x;
    // compose(add1, double, square)(3) = add1(double(square(3))) = add1(double(9)) = add1(18) = 19
    expect(compose(add1, double, square)(3)).toBe(19);
  });

  test('дополнительные аргументы (context) передаются всем функциям', () => {
    const add = (x, y) => x + y;
    const mul = (x, y) => x * y;
    // compose(add, mul)(2, 3):
    // mul(2, 3) = 6, add(6, 3) = 9
    expect(compose(add, mul)(2, 3)).toBe(9);
  });
});

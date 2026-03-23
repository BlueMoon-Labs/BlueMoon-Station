import { Color } from './color';

describe('Color', () => {
  describe('конструктор', () => {
    test('значения по умолчанию: r=0, g=0, b=0, a=1', () => {
      const c = new Color();
      expect(c.r).toBe(0);
      expect(c.g).toBe(0);
      expect(c.b).toBe(0);
      expect(c.a).toBe(1);
    });

    test('кастомные значения', () => {
      const c = new Color(255, 128, 0, 0.5);
      expect(c.r).toBe(255);
      expect(c.g).toBe(128);
      expect(c.b).toBe(0);
      expect(c.a).toBe(0.5);
    });
  });

  describe('toString', () => {
    test('формат rgba()', () => {
      const c = new Color(255, 128, 0, 0.5);
      expect(c.toString()).toBe('rgba(255, 128, 0, 0.5)');
    });

    test('truncation — дробные значения обрезаются через | 0', () => {
      const c = new Color(255.7, 128.3, 0.9, 0.5);
      // | 0 обрезает до целого
      expect(c.toString()).toBe('rgba(255, 128, 0, 0.5)');
    });

    test('alpha не truncated', () => {
      const c = new Color(0, 0, 0, 0.333);
      expect(c.toString()).toBe('rgba(0, 0, 0, 0.333)');
    });
  });
});

describe('Color.fromHex', () => {
  test('стандартный hex цвет', () => {
    const c = Color.fromHex('#ff8000');
    expect(c.r).toBe(255);
    expect(c.g).toBe(128);
    expect(c.b).toBe(0);
  });

  test('чёрный', () => {
    const c = Color.fromHex('#000000');
    expect(c.r).toBe(0);
    expect(c.g).toBe(0);
    expect(c.b).toBe(0);
  });

  test('белый', () => {
    const c = Color.fromHex('#ffffff');
    expect(c.r).toBe(255);
    expect(c.g).toBe(255);
    expect(c.b).toBe(255);
  });

  test('alpha по умолчанию = 1', () => {
    const c = Color.fromHex('#ff0000');
    expect(c.a).toBe(1);
  });
});

describe('Color.lerp', () => {
  const black = new Color(0, 0, 0, 1);
  const white = new Color(255, 255, 255, 1);

  test('n=0 -> первый цвет', () => {
    const result = Color.lerp(black, white, 0);
    expect(result.r).toBe(0);
    expect(result.g).toBe(0);
    expect(result.b).toBe(0);
  });

  test('n=1 -> второй цвет', () => {
    const result = Color.lerp(black, white, 1);
    expect(result.r).toBe(255);
    expect(result.g).toBe(255);
    expect(result.b).toBe(255);
  });

  test('n=0.5 -> середина', () => {
    const result = Color.lerp(black, white, 0.5);
    expect(result.r).toBe(127.5);
    expect(result.g).toBe(127.5);
    expect(result.b).toBe(127.5);
  });

  test('alpha интерполяция', () => {
    const transparent = new Color(0, 0, 0, 0);
    const opaque = new Color(0, 0, 0, 1);
    const result = Color.lerp(transparent, opaque, 0.5);
    expect(result.a).toBe(0.5);
  });
});

describe('Color.lookup', () => {
  const red = new Color(255, 0, 0);
  const green = new Color(0, 255, 0);
  const blue = new Color(0, 0, 255);

  test('value=0 -> первый цвет', () => {
    const result = Color.lookup(0, [red, green, blue]);
    expect(result).toBe(red); // Возвращает сам объект, не копию
  });

  test('value=1 -> последний цвет', () => {
    const result = Color.lookup(1, [red, green, blue]);
    expect(result).toBe(blue);
  });

  test('value=0.5 -> интерполяция между green и blue (3 цвета)', () => {
    // 3 цвета: scaled = 0.5 * 2 = 1.0 -> index=1, ratio=0 -> green
    const result = Color.lookup(0.5, [red, green, blue]);
    expect(result.g).toBe(255);
  });

  test('mid-range интерполяция (2 цвета)', () => {
    const result = Color.lookup(0.5, [red, blue]);
    // 2 цвета: scaled = 0.5 * 1 = 0.5 -> index=0, ratio=0.5
    // lerp(red, blue, 0.5): r=127.5, g=0, b=127.5
    expect(result.r).toBeCloseTo(127.5);
    expect(result.b).toBeCloseTo(127.5);
  });

  test('менее 2 цветов -> throw', () => {
    expect(() => Color.lookup(0.5, [red])).toThrow('Needs at least two colors');
    expect(() => Color.lookup(0.5, [])).toThrow('Needs at least two colors');
  });

  test('EPSILON граница — очень маленькое значение -> первый цвет', () => {
    const result = Color.lookup(0.00001, [red, green]);
    expect(result).toBe(red);
  });

  test('EPSILON граница — значение близкое к 1 -> последний цвет', () => {
    const result = Color.lookup(0.99999, [red, green]);
    expect(result).toBe(green);
  });
});

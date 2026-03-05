import { CSS_COLORS, getGasColor, getGasLabel } from './constants';

describe('getGasLabel', () => {
  test('поиск по id — возвращает label', () => {
    expect(getGasLabel('o2')).toBe('O₂');
  });

  test('поиск по name (case-insensitive)', () => {
    expect(getGasLabel('oxygen')).toBe('O₂');
  });

  test('поиск по name с заглавными буквами', () => {
    expect(getGasLabel('Oxygen')).toBe('O₂');
    expect(getGasLabel('OXYGEN')).toBe('O₂');
  });

  test('CO₂ по id', () => {
    expect(getGasLabel('co2')).toBe('CO₂');
  });

  test('Plasma по id', () => {
    expect(getGasLabel('plasma')).toBe('Plasma');
  });

  test('Tritium по id', () => {
    expect(getGasLabel('tritium')).toBe('Tritium');
  });

  test('Water Vapor по name', () => {
    expect(getGasLabel('water vapor')).toBe('H₂O');
  });

  test('числовой id конвертируется в строку и не находит совпадение', () => {
    // String(123).toLowerCase() = '123' — нет газа с таким id/name
    // Возвращает gasId = 123 (число)
    expect(getGasLabel(123)).toBe(123);
  });

  test('несуществующий газ без fallback — возвращает gasId', () => {
    expect(getGasLabel('nonexistent')).toBe('nonexistent');
  });

  test('несуществующий газ с fallback — возвращает fallbackValue', () => {
    expect(getGasLabel('nonexistent', 'Неизвестно')).toBe('Неизвестно');
  });

  test('пустая строка без fallback — возвращает пустую строку', () => {
    // gas не найден -> fallbackValue undefined -> gasId = ''
    // Но '' || '' — falsy, цепочка: gas && gas.label || fallbackValue || gasId
    // undefined || undefined || '' = ''
    expect(getGasLabel('')).toBe('');
  });

  test('все 18 газов доступны по id', () => {
    const gasIds = [
      'o2', 'n2', 'co2', 'plasma', 'water_vapor', 'nob', 'n2o', 'no',
      'no2', 'tritium', 'bz', 'stim', 'pluox', 'miasma', 'hydrogen',
      'methane', 'methyl_bromide', 'qcd',
    ];
    for (const id of gasIds) {
      const label = getGasLabel(id);
      // Каждый газ должен вернуть label (строку), а не id обратно
      expect(typeof label).toBe('string');
      expect(label.length).toBeGreaterThan(0);
    }
  });
});

describe('getGasColor', () => {
  test('поиск по id — возвращает цвет', () => {
    expect(getGasColor('o2')).toBe('blue');
  });

  test('поиск по name (case-insensitive)', () => {
    expect(getGasColor('plasma')).toBe('pink');
    expect(getGasColor('Plasma')).toBe('pink');
  });

  test('несуществующий газ — undefined', () => {
    expect(getGasColor('nonexistent')).toBeUndefined();
  });

  test('поиск по name с пробелами', () => {
    expect(getGasColor('water vapor')).toBe('grey');
    expect(getGasColor('Water Vapor')).toBe('grey');
  });

  test('числовой id — undefined (нет совпадения)', () => {
    expect(getGasColor(42)).toBeUndefined();
  });

  test('все газы возвращают валидный CSS цвет', () => {
    const gasIds = [
      'o2', 'n2', 'co2', 'plasma', 'water_vapor', 'nob', 'n2o', 'no',
      'no2', 'tritium', 'bz', 'stim', 'pluox', 'miasma', 'hydrogen',
      'methane', 'methyl_bromide', 'qcd',
    ];
    for (const id of gasIds) {
      const color = getGasColor(id);
      expect(typeof color).toBe('string');
      // Все цвета должны быть из CSS_COLORS
      expect(CSS_COLORS).toContain(color);
    }
  });

  test('Nitrogen и Nitrous Oxide — оба red', () => {
    expect(getGasColor('n2')).toBe('red');
    expect(getGasColor('n2o')).toBe('red');
  });

  test('разные газы с одинаковым цветом', () => {
    // co2, water_vapor, methane — все grey
    expect(getGasColor('co2')).toBe('grey');
    expect(getGasColor('water_vapor')).toBe('grey');
    expect(getGasColor('methane')).toBe('grey');
  });
});

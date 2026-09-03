import { computeBoxClassName, computeBoxProps, halfUnit, unit } from './Box';

describe('unit', () => {
  test('converts number to rem', () => {
    expect(unit(2)).toBe('2rem');
  });

  test('converts zero to 0rem', () => {
    expect(unit(0)).toBe('0rem');
  });

  test('converts negative number to negative rem', () => {
    expect(unit(-1)).toBe('-1rem');
  });

  test('converts fractional number to rem', () => {
    expect(unit(1.5)).toBe('1.5rem');
  });

  test('converts pixel string to rem (24px / 12 = 2)', () => {
    expect(unit('24px')).toBe('2rem');
  });

  test('converts 12px to 1rem', () => {
    expect(unit('12px')).toBe('1rem');
  });

  test('converts 6px to 0.5rem', () => {
    expect(unit('6px')).toBe('0.5rem');
  });

  test('passes through percentage string', () => {
    expect(unit('50%')).toBe('50%');
  });

  test('passes through other CSS units', () => {
    expect(unit('10em')).toBe('10em');
    expect(unit('100vh')).toBe('100vh');
  });

  test('returns undefined for undefined', () => {
    expect(unit(undefined)).toBeUndefined();
  });

  test('returns undefined for null', () => {
    expect(unit(null)).toBeUndefined();
  });

  test('returns undefined for boolean', () => {
    expect(unit(true)).toBeUndefined();
    expect(unit(false)).toBeUndefined();
  });
});

describe('halfUnit', () => {
  test('halves a number then converts to rem', () => {
    expect(halfUnit(2)).toBe('1rem');
  });

  test('halves 1 to 0.5rem', () => {
    expect(halfUnit(1)).toBe('0.5rem');
  });

  test('zero stays 0rem', () => {
    expect(halfUnit(0)).toBe('0rem');
  });

  test('delegates pixel string to unit (no halving)', () => {
    expect(halfUnit('24px')).toBe('2rem');
  });

  test('delegates percentage string to unit', () => {
    expect(halfUnit('50%')).toBe('50%');
  });

  test('returns undefined for undefined', () => {
    expect(halfUnit(undefined)).toBeUndefined();
  });

  test('returns undefined for null', () => {
    expect(halfUnit(null)).toBeUndefined();
  });

  test('returns undefined for boolean', () => {
    expect(halfUnit(true)).toBeUndefined();
  });
});

describe('computeBoxProps', () => {
  test('maps width number to style with unit', () => {
    const result = computeBoxProps({ width: 10 });
    expect(result.style).toEqual({ width: '10rem' });
  });

  test('maps width string to style', () => {
    const result = computeBoxProps({ width: '100%' });
    expect(result.style).toEqual({ width: '100%' });
  });

  test('maps height to style', () => {
    const result = computeBoxProps({ height: 5 });
    expect(result.style).toEqual({ height: '5rem' });
  });

  test('maps margin shorthand with halfUnit', () => {
    const result = computeBoxProps({ m: 2 });
    // m=2 -> halfUnit(2) = 1rem for all four directions
    expect(result.style).toEqual({
      marginTop: '1rem',
      marginBottom: '1rem',
      marginLeft: '1rem',
      marginRight: '1rem',
    });
  });

  test('maps padding shorthand with halfUnit', () => {
    const result = computeBoxProps({ p: 1 });
    // p=1 -> halfUnit(1) = 0.5rem for all four directions
    expect(result.style).toEqual({
      paddingTop: '0.5rem',
      paddingBottom: '0.5rem',
      paddingLeft: '0.5rem',
      paddingRight: '0.5rem',
    });
  });

  test('maps mx to horizontal margins only', () => {
    const result = computeBoxProps({ mx: 2 });
    expect(result.style).toEqual({
      marginLeft: '1rem',
      marginRight: '1rem',
    });
  });

  test('maps my to vertical margins only', () => {
    const result = computeBoxProps({ my: 2 });
    expect(result.style).toEqual({
      marginTop: '1rem',
      marginBottom: '1rem',
    });
  });

  test('maps individual margin direction', () => {
    const result = computeBoxProps({ mt: 4 });
    // mt=4 -> halfUnit(4) = 2rem
    expect(result.style).toEqual({ marginTop: '2rem' });
  });

  test('passes through non-style props', () => {
    const result = computeBoxProps({ className: 'foo', id: 'bar' });
    expect(result.className).toBe('foo');
    expect(result.id).toBe('bar');
    expect(result.style).toBeUndefined();
  });

  test('merges computed styles with explicit style object', () => {
    const result = computeBoxProps({
      width: 5,
      style: { color: 'red' },
    });
    expect(result.style).toEqual({
      width: '5rem',
      color: 'red',
    });
  });

  test('bold sets fontWeight bold', () => {
    const result = computeBoxProps({ bold: true });
    expect(result.style).toEqual({ fontWeight: 'bold' });
  });

  test('italic sets fontStyle italic', () => {
    const result = computeBoxProps({ italic: true });
    expect(result.style).toEqual({ fontStyle: 'italic' });
  });

  test('inline sets display inline-block', () => {
    const result = computeBoxProps({ inline: true });
    expect(result.style).toEqual({ display: 'inline-block' });
  });

  test('nowrap sets whiteSpace nowrap', () => {
    const result = computeBoxProps({ nowrap: true });
    expect(result.style).toEqual({ whiteSpace: 'nowrap' });
  });

  test('preserveWhitespace sets whiteSpace pre-wrap', () => {
    const result = computeBoxProps({ preserveWhitespace: true });
    expect(result.style).toEqual({ whiteSpace: 'pre-wrap' });
  });

  test('fillPositionedParent sets position absolute and all edges', () => {
    const result = computeBoxProps({ fillPositionedParent: true });
    expect(result.style).toEqual({
      position: 'absolute',
      top: 0,
      bottom: 0,
      left: 0,
      right: 0,
    });
  });

  test('lineHeight number is raw value', () => {
    const result = computeBoxProps({ lineHeight: 1.5 });
    expect(result.style).toEqual({ lineHeight: 1.5 });
  });

  test('lineHeight string goes through unit()', () => {
    const result = computeBoxProps({ lineHeight: '24px' });
    expect(result.style).toEqual({ lineHeight: '2rem' });
  });

  test('position is raw string', () => {
    const result = computeBoxProps({ position: 'relative' });
    expect(result.style).toEqual({ position: 'relative' });
  });

  test('opacity is raw number', () => {
    const result = computeBoxProps({ opacity: 0.5 });
    expect(result.style).toEqual({ opacity: 0.5 });
  });

  test('textAlign is raw string', () => {
    const result = computeBoxProps({ textAlign: 'center' });
    expect(result.style).toEqual({ textAlign: 'center' });
  });

  test('fontSize uses unit()', () => {
    const result = computeBoxProps({ fontSize: 2 });
    expect(result.style).toEqual({ fontSize: '2rem' });
  });

  test('color code goes to style (not class)', () => {
    const result = computeBoxProps({ color: '#ff0000' });
    expect(result.style).toEqual({ color: '#ff0000' });
  });

  test('CSS color class name does NOT go to style', () => {
    const result = computeBoxProps({ color: 'red' });
    // 'red' is in CSS_COLORS, so isColorCode returns false
    // and mapColorPropTo does NOT set style
    expect(result.style).toBeUndefined();
  });

  test('backgroundColor code goes to style', () => {
    const result = computeBoxProps({ backgroundColor: '#00ff00' });
    expect(result.style).toEqual({ backgroundColor: '#00ff00' });
  });

  test('boolean false does not set style', () => {
    const result = computeBoxProps({ bold: false });
    expect(result.style).toBeUndefined();
  });

  test('empty props returns no style', () => {
    const result = computeBoxProps({});
    expect(result.style).toBeUndefined();
  });
});

describe('computeBoxClassName', () => {
  test('known CSS color produces color- class', () => {
    const className = computeBoxClassName({ color: 'red' });
    expect(className).toContain('color-red');
  });

  test('hex color code does NOT produce a class', () => {
    const className = computeBoxClassName({ color: '#ff0000' });
    expect(className).toBeFalsy();
  });

  test('backgroundColor produces color-bg- class', () => {
    const className = computeBoxClassName({ backgroundColor: 'blue' });
    expect(className).toContain('color-bg-blue');
  });

  test('textColor is used over color for text class', () => {
    const className = computeBoxClassName({
      textColor: 'green',
      color: 'red',
    });
    expect(className).toContain('color-green');
    expect(className).not.toContain('color-red');
  });

  test('both color and backgroundColor produce both classes', () => {
    const className = computeBoxClassName({
      color: 'red',
      backgroundColor: 'blue',
    });
    expect(className).toContain('color-red');
    expect(className).toContain('color-bg-blue');
  });

  test('no color props returns falsy', () => {
    const className = computeBoxClassName({});
    expect(className).toBeFalsy();
  });

  test('good/bad/average/label are valid CSS color classes', () => {
    expect(computeBoxClassName({ color: 'good' })).toContain('color-good');
    expect(computeBoxClassName({ color: 'bad' })).toContain('color-bad');
    expect(computeBoxClassName({ color: 'average' })).toContain(
      'color-average',
    );
    expect(computeBoxClassName({ color: 'label' })).toContain('color-label');
  });
});

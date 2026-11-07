import { contrast, parseColor, parseRules, resolveVars, specificity, winningDeclaration } from './cssCascade';

describe('specificity', () => {
  test.each([
    ['.a', [0, 1, 0]],
    ['#x .a > b', [1, 1, 1]],
    ['.a::after', [0, 1, 1]],
    ['.a:after', [0, 1, 1]],
    ['.a:hover', [0, 2, 0]],
    ['[data-x="1"]', [0, 1, 0]],
    ['*', [0, 0, 0]],
    // :not, :is, :has - самый специфичный аргумент, :where - ноль.
    ['.a:not(.b, #c)', [1, 1, 0]],
    ['.a:not(.b):not(.c .d)', [0, 4, 0]],
    ['.a:is(div, .b)', [0, 2, 0]],
    ['.a:where(#c)', [0, 1, 0]],
    ['.a:not(.b:not(.c .d))', [0, 4, 0]],
    ['.a > .b:nth-child(even of .b)', [0, 4, 0]],
    ['.a > .b:nth-child(even)', [0, 3, 0]],
    ['.Chat .ChatMessage:not(.ChatMessage--highlighted)'
      + ':not(.Chat:not(.Chat--noSettle) .ChatMessage--settled)::after',
    [0, 6, 1]],
  ])('%s', (selector, expected) => {
    expect(specificity(selector)).toEqual(expected);
  });
});

describe('winningDeclaration', () => {
  const rules = parseRules(`
    .a { color: red; }
    /* комментарий { } */
    .box .a { color: blue; }
    .a { color: green; border-left: 2px solid var(--x, #111111); }
    @keyframes k { from { color: pink; } }
    @media (prefers-reduced-motion: reduce) { .a { color: gray !important; } }
    .a:not(.on)::after { content: ''; }
    .box { --x: #222222; --y: var(--missing); }
    .b { color: black !important; }
  `);
  const box = document.createElement('div');
  box.className = 'box';
  const node = document.createElement('div');
  node.className = 'a b';
  box.appendChild(node);
  test('specificity, then order, then importance', () => {
    expect(winningDeclaration(rules, node, 'color').value).toBe('black');
    node.className = 'a';
    expect(winningDeclaration(rules, node, 'color').value).toBe('blue');
  });
  test('shorthand sets the longhand', () => {
    expect(winningDeclaration(rules, node, 'border-left-color').value)
      .toBe('2px solid var(--x, #111111)');
  });
  test('pseudo elements match by their own selector', () => {
    expect(winningDeclaration(rules, node, 'content', '::after').value)
      .toBe('\'\'');
    expect(winningDeclaration(rules, node, 'content')).toBeNull();
    node.classList.add('on');
    expect(winningDeclaration(rules, node, 'content', '::after')).toBeNull();
  });
  test('variables inherit and fall back', () => {
    expect(resolveVars(rules, node, 'var(--x, #111111)')).toBe('#222222');
    expect(resolveVars(rules, node, 'var(--y, #333333)')).toBe('#333333');
    expect(resolveVars(rules, node, 'var(--y)')).toBeNull();
  });
});

test('contrast', () => {
  expect(contrast(parseColor('#000'), parseColor('#ffffff')))
    .toBeCloseTo(21, 0);
  expect(parseColor('rgba(10, 20, 30, 0.5)')).toEqual([10, 20, 30, 0.5]);
});

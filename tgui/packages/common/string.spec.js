import {
  buildQueryString,
  capitalize,
  capitalizeAll,
  createGlobPattern,
  createSearch,
  decodeHtmlEntities,
  multiline,
  toTitleCase,
} from './string';

describe('multiline', () => {
  test('убирает общий отступ из многострочного текста', () => {
    const input = `
      line one
      line two
      line three
    `;
    const result = multiline(input);
    expect(result).toBe('line one\nline two\nline three');
  });

  test('сохраняет относительные отступы', () => {
    const input = `
      parent
        child
          grandchild
    `;
    const result = multiline(input);
    expect(result).toBe('parent\n  child\n    grandchild');
  });

  test('работает как template tag (массив)', () => {
    const result = multiline(['  hello\n  world']);
    expect(result).toBe('hello\nworld');
  });

  test('без отступа — возвращает trimmed строку', () => {
    expect(multiline('hello\nworld')).toBe('hello\nworld');
  });

  test('одна строка', () => {
    expect(multiline('  hello  ')).toBe('hello');
  });

  test('пустая строка', () => {
    expect(multiline('')).toBe('');
  });
});

describe('createGlobPattern', () => {
  test('* в конце — совпадает с любым суффиксом', () => {
    const match = createGlobPattern('hello*');
    expect(match('hello world')).toBe(true);
    expect(match('hello')).toBe(true);
    expect(match('hi')).toBe(false);
  });

  test('* в начале — совпадает с любым префиксом', () => {
    const match = createGlobPattern('*@domain');
    expect(match('user@domain')).toBe(true);
    expect(match('@domain')).toBe(true);
    expect(match('user@other')).toBe(false);
  });

  test('* в середине', () => {
    const match = createGlobPattern('hello*world');
    expect(match('hello world')).toBe(true);
    expect(match('helloworld')).toBe(true);
    expect(match('hello cruel world')).toBe(true);
    expect(match('hi world')).toBe(false);
  });

  test('без * — точное совпадение', () => {
    const match = createGlobPattern('exact');
    expect(match('exact')).toBe(true);
    expect(match('exactl')).toBe(false);
    expect(match('exac')).toBe(false);
  });

  test('спецсимволы regex экранируются', () => {
    const match = createGlobPattern('file.txt');
    expect(match('file.txt')).toBe(true);
    expect(match('fileAtxt')).toBe(false); // . не должна совпасть с любым символом
  });

  test('несколько *', () => {
    const match = createGlobPattern('*hello*world*');
    expect(match('say hello cruel world!')).toBe(true);
    expect(match('helloworld')).toBe(true);
    expect(match('hello')).toBe(false);
  });
});

describe('createSearch', () => {
  test('пустой поиск — совпадает со всем', () => {
    const search = createSearch('');
    expect(search('anything')).toBe(true);
    expect(search('')).toBe(true);
  });

  test('пробельный поиск — совпадает со всем', () => {
    const search = createSearch('   ');
    expect(search('anything')).toBe(true);
  });

  test('регистронезависимый поиск', () => {
    const search = createSearch('Hello');
    expect(search('hello world')).toBe(true);
    expect(search('HELLO WORLD')).toBe(true);
    expect(search('HeLLo')).toBe(true);
  });

  test('подстрока ищется', () => {
    const search = createSearch('world');
    expect(search('hello world')).toBe(true);
    expect(search('worldwide')).toBe(true);
    expect(search('hello')).toBe(false);
  });

  test('с stringifier', () => {
    const search = createSearch('john', obj => obj.name);
    expect(search({ name: 'John Doe' })).toBe(true);
    expect(search({ name: 'Jane Doe' })).toBe(false);
  });

  test('объект с falsy строкой -> false', () => {
    const search = createSearch('test');
    expect(search(null)).toBe(false);
    expect(search('')).toBe(false);
    expect(search(undefined)).toBe(false);
  });
});

describe('capitalize', () => {
  test('первая буква заглавная, остальные строчные', () => {
    expect(capitalize('hELLO')).toBe('Hello');
  });

  test('массив строк', () => {
    expect(capitalize(['hello', 'world'])).toEqual(['Hello', 'World']);
  });

  test('одна буква', () => {
    expect(capitalize('a')).toBe('A');
  });
});

describe('capitalizeAll', () => {
  test('первая буква каждого слова заглавная', () => {
    expect(capitalizeAll('hello world')).toBe('Hello World');
  });

  test('сохраняет остальные буквы как есть', () => {
    expect(capitalizeAll('heLLo woRLd')).toBe('HeLLo WoRLd');
  });

  test('одно слово', () => {
    expect(capitalizeAll('hello')).toBe('Hello');
  });
});

describe('toTitleCase', () => {
  test('каждое слово с заглавной', () => {
    expect(toTitleCase('hello world')).toBe('Hello World');
  });

  test('артикли в середине остаются строчными', () => {
    const result = toTitleCase('the lord of the rings');
    expect(result).toContain(' of ');
    expect(result).toContain(' the ');
  });

  test('первое слово всегда с заглавной (даже если артикль)', () => {
    const result = toTitleCase('the great gatsby');
    // Первое слово — WORDS_LOWER не ловит его, т.к. regex \\s...\\s
    // требует пробел до слова, а первое слово начинается без пробела
    expect(result[0]).toBe('T');
  });

  test('WORDS_UPPER (Id, Tv) преобразуются в нижний регистр', () => {
    const result = toTitleCase('the tv id');
    expect(result).toContain('tv');
    expect(result).toContain('id');
  });

  test('массив строк', () => {
    expect(toTitleCase(['hello', 'world'])).toEqual(['Hello', 'World']);
  });

  test('не-строка возвращается как есть', () => {
    expect(toTitleCase(42)).toBe(42);
    expect(toTitleCase(null)).toBe(null);
  });
});

describe('decodeHtmlEntities', () => {
  test('именованные entities', () => {
    expect(decodeHtmlEntities('&amp;')).toBe('&');
    expect(decodeHtmlEntities('&lt;')).toBe('<');
    expect(decodeHtmlEntities('&gt;')).toBe('>');
    expect(decodeHtmlEntities('&quot;')).toBe('"');
    expect(decodeHtmlEntities('&apos;')).toBe("'");
    expect(decodeHtmlEntities('&nbsp;')).toBe(' ');
  });

  test('decimal entities', () => {
    expect(decodeHtmlEntities('&#65;')).toBe('A');
    expect(decodeHtmlEntities('&#97;')).toBe('a');
  });

  test('hex entities', () => {
    expect(decodeHtmlEntities('&#x41;')).toBe('A');
    expect(decodeHtmlEntities('&#x61;')).toBe('a');
  });

  test('<br> -> перевод строки', () => {
    expect(decodeHtmlEntities('line1<br>line2')).toBe('line1\nline2');
  });

  test('HTML теги удаляются', () => {
    expect(decodeHtmlEntities('<b>bold</b>')).toBe('bold');
    expect(decodeHtmlEntities('<span class="test">text</span>')).toBe('text');
  });

  test('комбинированный текст', () => {
    expect(decodeHtmlEntities('<b>Hello</b> &amp; <i>World</i>')).toBe('Hello & World');
  });

  test('falsy input возвращается как есть', () => {
    expect(decodeHtmlEntities('')).toBe('');
    expect(decodeHtmlEntities(null)).toBe(null);
    expect(decodeHtmlEntities(undefined)).toBe(undefined);
  });
});

describe('buildQueryString', () => {
  test('строит query string из объекта', () => {
    expect(buildQueryString({ a: '1', b: '2' })).toBe('a=1&b=2');
  });

  test('пустой объект', () => {
    expect(buildQueryString({})).toBe('');
  });
});

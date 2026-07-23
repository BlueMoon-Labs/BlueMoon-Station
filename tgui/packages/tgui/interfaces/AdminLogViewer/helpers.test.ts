import { formatBytes, parseCsv, splitByMatches } from './helpers';

describe('formatBytes', () => {
  it('форматирует байты в читаемые единицы', () => {
    expect(formatBytes(-1)).toBe('—');
    expect(formatBytes(0)).toBe('0 Б');
    expect(formatBytes(512)).toBe('512 Б');
    expect(formatBytes(2048)).toBe('2.0 КиБ');
    expect(formatBytes(775603)).toBe('757.4 КиБ');
    expect(formatBytes(5 * 1024 * 1024)).toBe('5.0 МиБ');
  });
  it('переходит в КиБ ровно на границе 1024 байт', () => {
    expect(formatBytes(1023)).toBe('1023 Б');
    expect(formatBytes(1024)).toBe('1.0 КиБ');
  });
});

describe('splitByMatches', () => {
  it('без запроса возвращает один сегмент без совпадений', () => {
    const result = splitByMatches('abc', '');
    expect(result.count).toBe(0);
    expect(result.segments).toEqual([{ text: 'abc', match: false }]);
  });
  it('находит совпадения без учёта регистра и сохраняет текст целиком', () => {
    const result = splitByMatches('Alpha beta ALPHA', 'alpha');
    expect(result.count).toBe(2);
    expect(result.segments.map((s) => s.text).join('')).toBe('Alpha beta ALPHA');
    expect(result.segments.filter((s) => s.match).map((s) => s.text)).toEqual(['Alpha', 'ALPHA']);
  });
  it('уважает кап совпадений', () => {
    const result = splitByMatches('aaaa', 'a', 2);
    expect(result.count).toBe(2);
  });
});

describe('parseCsv', () => {
  it('разбирает строки и колонки', () => {
    expect(parseCsv('a,b\nc,d\n')).toEqual([['a', 'b'], ['c', 'd']]);
  });
  it('уважает кап строк', () => {
    expect(parseCsv('a\nb\nc', 2)).toHaveLength(2);
  });
  it('срезает завершающий \\r у строк с Windows-переносами', () => {
    expect(parseCsv('a,b\r\nc,d\r\n')).toEqual([
      ['a', 'b'],
      ['c', 'd'],
    ]);
  });
});

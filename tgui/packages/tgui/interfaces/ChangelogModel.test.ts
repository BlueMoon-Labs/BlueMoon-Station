import {
  avatarUrl,
  categoryOf,
  countByCategory,
  countEntries,
  countNew,
  filterBase,
  filterDays,
  formatDay,
  formatMonth,
  groupByPr,
  groupByYear,
  isNewDate,
  kindOf,
  monthHasNew,
  normalizeTestMerges,
  parseMonth,
} from './ChangelogModel';

const raw = {
  '2026-10-01': {
    'DuLL-FoX': [{ rscadd: 'Добавлен путь Пляски' }, { bugfix: 'Исправлено удержание жертв' }],
  },
  '2026-10-15': {
    Pingvas: [{ tweak: 'Ёлка стала зеленее' }, { imageadd: 'Новые спрайты' }],
    Ghost: [{ balance: 42 }],
  },
  '2026-10-07': {
    Broken: 'не список',
    Empty: [],
    Mixed: [null, 'строка', { rscdel: null }, { someday_type: 'Неизвестный тип' }],
  },
  '2026-10-09': null,
};

const base = { query: '', categories: [] as string[], onlyNew: false, lastSeen: '' };

test('месяц разбирается в дни свежими первыми, кривые узлы пропускаются', () => {
  const days = parseMonth(raw);
  expect(days.map((day) => day.date)).toEqual(['2026-10-15', '2026-10-07', '2026-10-01']);
  expect(days[0].authors.map((block) => block.author)).toEqual(['Pingvas', 'Ghost']);
  expect(days[0].authors[1].changes).toEqual([{ type: 'balance', text: '42' }]);
  expect(days[1].authors).toEqual([{ author: 'Mixed', changes: [{ type: 'someday_type', text: 'Неизвестный тип' }] }]);
  expect(parseMonth(null)).toEqual([]);
  expect(parseMonth('Cannot find 2026-10.yml')).toEqual([]);
});

test('номер PR читается в любом порядке ключей, мусор вместо номера отбрасывается', () => {
  const days = parseMonth({
    '2026-10-20': {
      A: [{ pr: 4100, rscadd: 'до типа' }, { bugfix: 'после типа', pr: 4101 }, { tweak: 'мусор', pr: 'abc' }, { pr: 7 }],
    },
  });
  expect(days[0].authors[0].changes).toEqual([
    { type: 'rscadd', text: 'до типа', pr: 4100 },
    { type: 'bugfix', text: 'после типа', pr: 4101 },
    { type: 'tweak', text: 'мусор' },
  ]);
});

test('подряд идущие записи одного PR группируются, аватарка только для похожих на логин имён', () => {
  const groups = groupByPr([
    { type: 'rscadd', text: 'a', pr: 1 },
    { type: 'bugfix', text: 'b', pr: 1 },
    { type: 'tweak', text: 'c' },
    { type: 'tweak', text: 'd', pr: 2 },
  ]);
  expect(groups.map((group) => [group.pr, group.changes.length])).toEqual([
    [1, 2],
    [undefined, 1],
    [2, 1],
  ]);
  expect(avatarUrl('DuLL-FoX')).toBe('https://github.com/DuLL-FoX.png?size=48');
  expect(avatarUrl('Имя Фамилия')).toBeNull();
  expect(avatarUrl('-bad')).toBeNull();
  expect(avatarUrl('../evil')).toBeNull();
});

test('теги из описания PR понимаются как теги архива', () => {
  expect(kindOf('typo').label).toBe('Текст');
  expect(categoryOf('del')).toBe('del');
  expect(categoryOf('rebalance')).toBe('balance');
  expect(categoryOf('fix')).toBe('fix');
  expect(categoryOf('code')).toBe('tech');
});

test('тест-мерджи: кривые записи отбрасываются, ссылка только https', () => {
  const merges = normalizeTestMerges([
    { number: 1, title: 'A', author: 'x', url: 'https://example.org/pull/1', changes: [{ type: 'add', text: 5 }, null, { text: 'без типа' }] },
    { number: 'abc' },
    null,
    { number: 2, title: 'B', author: 'y', url: 'javascript:alert(1)' },
  ]);
  expect(merges).toEqual([
    { number: 1, title: 'A', author: 'x', url: 'https://example.org/pull/1', changes: [{ type: 'add', text: '5' }] },
    { number: 2, title: 'B', author: 'y', url: 'https://github.com/BlueMoon-Labs/BlueMoon-Station/pull/2', changes: [] },
  ]);
  expect(normalizeTestMerges(undefined)).toEqual([]);
});

test('даты и месяцы подписываются по-русски', () => {
  expect(formatMonth('2026-10')).toBe('Октябрь 2026');
  expect(formatDay('2026-10-08')).toBe('8 октября 2026');
  expect(formatDay('2026-05-31')).toBe('31 мая 2026');
  expect(formatDay('not-a-date')).toBe('not-a-date');
});

test('у неизвестного типа своя иконка и категория «техническое»', () => {
  expect(kindOf('rscadd').label).toBe('Добавлено');
  expect(categoryOf('imagedel')).toBe('media');
  expect(categoryOf('qol')).toBe('tweak');
  expect(kindOf('someday_type').icon).toBe('circle-info');
  expect(categoryOf('someday_type')).toBe('tech');
});

test('поиск идёт по тексту и автору без учёта регистра и ё', () => {
  const days = parseMonth(raw);
  expect(countEntries(filterDays(days, { ...base, query: 'ЕЛКА' }))).toBe(1);
  expect(countEntries(filterDays(days, { ...base, query: 'dull' }))).toBe(2);
  expect(filterDays(days, { ...base, query: 'нет такого' })).toEqual([]);
  expect(filterDays(days, { ...base, query: '   ' })).toBe(days);
});

test('категории фильтруют поверх поиска, а чипы считаются без фильтра категорий', () => {
  const days = parseMonth(raw);
  const filters = { ...base, query: 'о', categories: ['fix'] };
  expect(filterDays(days, filters).map((day) => day.date)).toEqual(['2026-10-01']);
  const counts = countByCategory(filterBase(days, filters));
  expect(counts).toEqual({ add: 1, fix: 1, media: 1 });
});

test('новым считается только то, что свежее отметки, и ничего без отметки', () => {
  const days = parseMonth(raw);
  expect(isNewDate('2026-10-15', '2026-10-07')).toBe(true);
  expect(isNewDate('2026-10-07', '2026-10-07')).toBe(false);
  expect(isNewDate('2026-10-15', '')).toBe(false);
  expect(countNew(days, '2026-10-07')).toBe(3);
  expect(countNew(days, '')).toBe(0);
  const onlyNew = filterDays(days, { ...base, onlyNew: true, lastSeen: '2026-10-07' });
  expect(onlyNew.map((day) => day.date)).toEqual(['2026-10-15']);
});

test('метка месяца: позже месяца отметки - да, сам месяц - по загрузке, раньше - нет', () => {
  expect(monthHasNew('2026-11', '2026-10-28')).toBe(true);
  expect(monthHasNew('2026-10', '2026-10-28')).toBe(false);
  expect(monthHasNew('2026-10', '2026-10-28', 2)).toBe(true);
  expect(monthHasNew('2026-10', '2026-10-28', 0)).toBe(false);
  expect(monthHasNew('2026-09', '2026-10-28')).toBe(false);
  expect(monthHasNew('2026-11', '')).toBe(false);
});

test('месяцы группируются по годам с сохранением порядка', () => {
  expect(groupByYear(['2026-02', '2026-01', '2025-12', '2024-03'])).toEqual([
    { year: '2026', months: ['2026-02', '2026-01'] },
    { year: '2025', months: ['2025-12'] },
    { year: '2024', months: ['2024-03'] },
  ]);
});

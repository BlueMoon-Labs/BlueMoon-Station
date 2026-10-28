export type ChangeEntry = {
  type: string;
  text: string;
  pr?: number;
};

/** Номера PR в архиве - всегда этого репозитория, а не githuburl из конфига сервера. */
export const REPO_URL = 'https://github.com/BlueMoon-Labs/BlueMoon-Station';

export const prUrl = (pr: number) => `${REPO_URL}/pull/${pr}`;

const GITHUB_LOGIN = /^[A-Za-z0-9](?:[A-Za-z0-9]|-(?=[A-Za-z0-9])){0,38}$/;

/** Аватарка автора, если его имя похоже на логин GitHub; в CL можно вписать и произвольное имя. */
export const avatarUrl = (author: string): string | null =>
  GITHUB_LOGIN.test(author) ? `https://github.com/${author}.png?size=48` : null;

export type PrGroup = {
  pr?: number;
  changes: ChangeEntry[];
};

/** Подряд идущие записи одного PR - один блок со ссылкой. */
export const groupByPr = (changes: ChangeEntry[]): PrGroup[] => {
  const groups: PrGroup[] = [];
  for (const change of changes) {
    const last = groups[groups.length - 1];
    if (last && last.pr === change.pr) {
      last.changes.push(change);
    } else {
      groups.push({ pr: change.pr, changes: [change] });
    }
  }
  return groups;
};

export type AuthorBlock = {
  author: string;
  changes: ChangeEntry[];
};

export type DayBlock = {
  date: string;
  authors: AuthorBlock[];
};

export type ChangeKind = {
  icon: string;
  color: string;
  label: string;
};

export type Category = {
  id: string;
  label: string;
  icon: string;
};

export const CATEGORIES: Category[] = [
  { id: 'add', label: 'Добавлено', icon: 'circle-plus' },
  { id: 'fix', label: 'Исправления', icon: 'bug' },
  { id: 'tweak', label: 'Изменения', icon: 'wrench' },
  { id: 'balance', label: 'Баланс', icon: 'scale-balanced' },
  { id: 'del', label: 'Удалено', icon: 'circle-minus' },
  { id: 'media', label: 'Графика, звук, карты', icon: 'palette' },
  { id: 'tech', label: 'Техническое', icon: 'code' },
];

const KINDS: Record<string, ChangeKind & { category: string }> = {
  rscadd: { icon: 'circle-plus', color: 'good', label: 'Добавлено', category: 'add' },
  add: { icon: 'circle-plus', color: 'good', label: 'Добавлено', category: 'add' },
  expansion: { icon: 'circle-plus', color: 'good', label: 'Добавлено', category: 'add' },
  bugfix: { icon: 'bug', color: 'teal', label: 'Исправлено', category: 'fix' },
  fix: { icon: 'bug', color: 'teal', label: 'Исправлено', category: 'fix' },
  tweak: { icon: 'wrench', color: 'blue', label: 'Изменено', category: 'tweak' },
  qol: { icon: 'hand-holding-heart', color: 'blue', label: 'Удобство', category: 'tweak' },
  spellcheck: { icon: 'spell-check', color: 'blue', label: 'Текст', category: 'tweak' },
  balance: { icon: 'scale-balanced', color: 'yellow', label: 'Баланс', category: 'balance' },
  rscdel: { icon: 'circle-minus', color: 'bad', label: 'Удалено', category: 'del' },
  rscremove: { icon: 'circle-minus', color: 'bad', label: 'Удалено', category: 'del' },
  remove: { icon: 'circle-minus', color: 'bad', label: 'Удалено', category: 'del' },
  image: { icon: 'image', color: 'violet', label: 'Графика', category: 'media' },
  imageadd: { icon: 'tg-image-plus', color: 'violet', label: 'Новая графика', category: 'media' },
  imagedel: { icon: 'tg-image-minus', color: 'violet', label: 'Удалена графика', category: 'media' },
  sound: { icon: 'volume-high', color: 'violet', label: 'Звук', category: 'media' },
  soundadd: { icon: 'tg-sound-plus', color: 'violet', label: 'Новый звук', category: 'media' },
  sounddel: { icon: 'tg-sound-minus', color: 'violet', label: 'Удалён звук', category: 'media' },
  map: { icon: 'map', color: 'violet', label: 'Карты', category: 'media' },
  code_imp: { icon: 'code', color: 'label', label: 'Код', category: 'tech' },
  code: { icon: 'code', color: 'label', label: 'Код', category: 'tech' },
  refactor: { icon: 'screwdriver-wrench', color: 'label', label: 'Рефакторинг', category: 'tech' },
  admin: { icon: 'user-shield', color: 'purple', label: 'Администрации', category: 'tech' },
  server: { icon: 'server', color: 'purple', label: 'Сервер', category: 'tech' },
  config: { icon: 'gears', color: 'purple', label: 'Конфиг', category: 'tech' },
  tgs: { icon: 'toolbox', color: 'purple', label: 'TGS', category: 'tech' },
  experiment: { icon: 'flask', color: 'orange', label: 'Эксперимент', category: 'tech' },
  experimental: { icon: 'flask', color: 'orange', label: 'Эксперимент', category: 'tech' },
  wip: { icon: 'hammer', color: 'orange', label: 'В работе', category: 'tech' },
};

const UNKNOWN_KIND = { icon: 'circle-info', color: 'label', label: 'Прочее', category: 'tech' };

/** Теги из описания PR (tools/changelog/tags.yml) -> теги архива; у тест-мерджей они ещё не переведены. */
const TAG_ALIASES: Record<string, string> = {
  fixes: 'bugfix',
  rsctweak: 'tweak',
  tweaks: 'tweak',
  adds: 'rscadd',
  del: 'rscdel',
  dels: 'rscdel',
  typo: 'spellcheck',
  rebalance: 'balance',
};

const resolveKind = (type: string) => KINDS[TAG_ALIASES[type] || type] || UNKNOWN_KIND;

export const kindOf = (type: string): ChangeKind => resolveKind(type);

export const categoryOf = (type: string): string => resolveKind(type).category;

export type TestMerge = {
  number: number;
  title: string;
  author: string;
  url: string;
  changes: ChangeEntry[];
};

/** Тест-мерджи из static data; кривые записи отбрасываются. */
export const normalizeTestMerges = (raw: unknown): TestMerge[] => {
  if (!Array.isArray(raw)) {
    return [];
  }
  const result: TestMerge[] = [];
  for (const item of raw) {
    const number = Number(item?.number);
    if (!Number.isInteger(number) || number <= 0) {
      continue;
    }
    const changes = Array.isArray(item.changes)
      ? item.changes
          .filter((change: any) => change && typeof change.type === 'string' && change.text !== undefined)
          .map((change: any) => ({ type: change.type, text: String(change.text) }))
      : [];
    result.push({
      number,
      title: String(item.title || ''),
      author: String(item.author || ''),
      url: typeof item.url === 'string' && item.url.startsWith('https://') ? item.url : prUrl(number),
      changes,
    });
  }
  return result;
};

const MONTHS_NOMINATIVE = ['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'];
const MONTHS_GENITIVE = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];

/** "2026-10" -> "Октябрь 2026". */
export const formatMonth = (month: string): string => {
  const [year, number] = month.split('-');
  return `${MONTHS_NOMINATIVE[Number(number) - 1] || number} ${year}`;
};

/** "2026-10" -> "Октябрь", для списка внутри года. */
export const monthName = (month: string): string => MONTHS_NOMINATIVE[Number(month.split('-')[1]) - 1] || month;

/** "2026-10-08" -> "8 октября 2026". */
export const formatDay = (date: string): string => {
  const [year, month, day] = date.split('-');
  const name = MONTHS_GENITIVE[Number(month) - 1];
  return name ? `${Number(day)} ${name} ${year}` : date;
};

/**
 * Разбирает месяц архива: { "YYYY-MM-DD": { автор: [{ тип: текст }] } }.
 * Свежие дни первыми; кривые узлы пропускаются, а не роняют окно.
 */
export const parseMonth = (raw: unknown): DayBlock[] => {
  if (!raw || typeof raw !== 'object') {
    return [];
  }
  const days: DayBlock[] = [];
  for (const [date, byAuthor] of Object.entries(raw as Record<string, unknown>)) {
    if (!byAuthor || typeof byAuthor !== 'object') {
      continue;
    }
    const authors: AuthorBlock[] = [];
    for (const [author, list] of Object.entries(byAuthor as Record<string, unknown>)) {
      if (!Array.isArray(list)) {
        continue;
      }
      const changes: ChangeEntry[] = [];
      for (const item of list) {
        if (!item || typeof item !== 'object') {
          continue;
        }
        // Компилятор пишет ключи по алфавиту, поэтому "pr" может стоять и перед типом.
        const { pr, ...rest } = item as Record<string, unknown>;
        const [type, text] = Object.entries(rest)[0] || [];
        if (type === undefined || text === null || text === undefined) {
          continue;
        }
        const number = Number(pr);
        changes.push(Number.isInteger(number) && number > 0 ? { type, text: String(text), pr: number } : { type, text: String(text) });
      }
      if (changes.length) {
        authors.push({ author, changes });
      }
    }
    if (authors.length) {
      days.push({ date, authors });
    }
  }
  return days.sort((a, b) => (a.date < b.date ? 1 : a.date > b.date ? -1 : 0));
};

/** Запись новее последней увиденной. Без отметки о просмотре новым не считается ничего. */
export const isNewDate = (date: string, lastSeen: string): boolean => !!lastSeen && date > lastSeen;

const normalize = (text: string) => text.toLowerCase().replace(/ё/g, 'е');

export type Filters = {
  query: string;
  categories: string[];
  onlyNew: boolean;
  lastSeen: string;
};

const filterBy = (days: DayBlock[], keep: (day: DayBlock, author: string, change: ChangeEntry) => boolean): DayBlock[] => {
  const result: DayBlock[] = [];
  for (const day of days) {
    const authors: AuthorBlock[] = [];
    for (const block of day.authors) {
      const changes = block.changes.filter((change) => keep(day, block.author, change));
      if (changes.length) {
        authors.push({ author: block.author, changes });
      }
    }
    if (authors.length) {
      result.push({ date: day.date, authors });
    }
  }
  return result;
};

/** Поиск и «только новое», без фильтра по категориям: от этого считаются чипы. */
export const filterBase = (days: DayBlock[], filters: Filters): DayBlock[] => {
  const query = normalize(filters.query.trim());
  if (!query && !filters.onlyNew) {
    return days;
  }
  return filterBy(days, (day, author, change) => {
    if (filters.onlyNew && !isNewDate(day.date, filters.lastSeen)) {
      return false;
    }
    if (!query) {
      return true;
    }
    if (/^#\d+$/.test(query)) {
      return change.pr === Number(query.slice(1));
    }
    return normalize(change.text).includes(query) || normalize(author).includes(query);
  });
};

export const filterDays = (days: DayBlock[], filters: Filters): DayBlock[] => {
  const base = filterBase(days, filters);
  if (!filters.categories.length) {
    return base;
  }
  return filterBy(base, (_day, _author, change) => filters.categories.includes(categoryOf(change.type)));
};

export const countEntries = (days: DayBlock[]): number => {
  let total = 0;
  for (const day of days) {
    for (const block of day.authors) {
      total += block.changes.length;
    }
  }
  return total;
};

export const countByCategory = (days: DayBlock[]): Record<string, number> => {
  const counts: Record<string, number> = {};
  for (const day of days) {
    for (const block of day.authors) {
      for (const change of block.changes) {
        const category = categoryOf(change.type);
        counts[category] = (counts[category] || 0) + 1;
      }
    }
  }
  return counts;
};

export const countNew = (days: DayBlock[], lastSeen: string): number =>
  countEntries(days.filter((day) => isNewDate(day.date, lastSeen)));

/** Месяцы ("YYYY-MM", свежие первыми) по годам, порядок сохраняется. */
export const groupByYear = (months: string[]): { year: string; months: string[] }[] => {
  const groups: { year: string; months: string[] }[] = [];
  for (const month of months) {
    const year = month.split('-')[0];
    const last = groups[groups.length - 1];
    if (last && last.year === year) {
      last.months.push(month);
    } else {
      groups.push({ year, months: [month] });
    }
  }
  return groups;
};

/**
 * Есть ли в месяце новое. Месяцы после месяца отметки - точно да; сам месяц отметки
 * известен только после загрузки (loadedNew), раньше него - точно нет.
 */
export const monthHasNew = (month: string, lastSeen: string, loadedNew?: number): boolean => {
  if (!lastSeen) {
    return false;
  }
  if (loadedNew !== undefined) {
    return loadedNew > 0;
  }
  return month > lastSeen.slice(0, 7);
};

/** Есть ли новое в каком-нибудь другом месяце: для точки на кнопке свёрнутого архива. */
export const monthHasNewOutside = (
  months: string[],
  current: string | undefined,
  lastSeen: string,
  newByMonth: Record<string, number>,
): boolean => months.some((month) => month !== current && monthHasNew(month, lastSeen, newByMonth[month]));

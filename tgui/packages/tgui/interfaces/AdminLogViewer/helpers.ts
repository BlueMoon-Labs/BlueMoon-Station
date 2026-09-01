export type MatchSegment = { text: string; match: boolean };

/** Человекочитаемый размер в байтах; -1 (нет данных) отображается прочерком. */
export const formatBytes = (n: number): string => {
  if (n < 0 || !Number.isFinite(n)) {
    return '—';
  }
  if (n < 1024) {
    return `${n} Б`;
  }
  const units = ['КиБ', 'МиБ', 'ГиБ'];
  let value = n;
  let unit = '';
  for (const next of units) {
    value /= 1024;
    unit = next;
    if (value < 1024) {
      break;
    }
  }
  return `${value.toFixed(1)} ${unit}`;
};

/**
 * Режет текст на сегменты по вхождениям запроса (без учёта регистра).
 * Конкатенация сегментов всегда равна исходному тексту.
 */
export const splitByMatches = (
  text: string,
  query: string,
  cap = 2000,
): { segments: MatchSegment[]; count: number } => {
  if (!query) {
    return { segments: [{ text, match: false }], count: 0 };
  }
  const lower = text.toLowerCase();
  const q = query.toLowerCase();
  const segments: MatchSegment[] = [];
  let count = 0;
  let pos = 0;
  while (count < cap) {
    const found = lower.indexOf(q, pos);
    if (found === -1) {
      break;
    }
    if (found > pos) {
      segments.push({ text: text.slice(pos, found), match: false });
    }
    segments.push({ text: text.slice(found, found + q.length), match: true });
    pos = found + q.length;
    count += 1;
  }
  if (pos < text.length || segments.length === 0) {
    segments.push({ text: text.slice(pos), match: false });
  }
  return { segments, count };
};

/** Наивный CSV-парсер (без кавычек-экранирования - перф-логам хватает). */
export const parseCsv = (text: string, maxRows = 2000): string[][] => {
  return text
    .split('\n')
    .map((line) => (line.endsWith('\r') ? line.slice(0, -1) : line))
    .filter((line) => line.length > 0)
    .slice(0, maxRows)
    .map((line) => line.split(','));
};

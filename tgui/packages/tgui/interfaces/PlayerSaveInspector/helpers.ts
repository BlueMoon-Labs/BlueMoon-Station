export type SaveFileKind = 'root' | 'recovery' | 'legacy' | 'slot' | 'other';

export type SaveFile = {
  path: string;
  kind: SaveFileKind;
  slot: number | null;
  character?: string | null;
  recovery: boolean | number;
  size: number;
};

export type SaveGroup = {
  id: string;
  title: string;
  slot: number | null;
  active: boolean;
  files: SaveFile[];
};

export const formatSize = (bytes: number) => {
  if (bytes < 1024) {
    return `${bytes} Б`;
  }
  if (bytes < 1024 * 1024) {
    return `${(bytes / 1024).toFixed(1)} КБ`;
  }
  return `${(bytes / (1024 * 1024)).toFixed(1)} МБ`;
};

const matches = (file: SaveFile, query: string) =>
  !query ||
  file.path.toLowerCase().includes(query) ||
  (file.character || '').toLowerCase().includes(query) ||
  (file.slot !== null && `слот ${file.slot}` === query) ||
  (file.slot !== null && String(file.slot) === query);

/** Аккаунт, затем активный слот, остальные слоты по номеру, разделы без номера и прочие файлы. */
export const groupFiles = (files: SaveFile[], defaultSlot: number | null, filter = ''): SaveGroup[] => {
  const query = filter.trim().toLowerCase();
  const account: SaveFile[] = [];
  const other: SaveFile[] = [];
  const unknown: SaveFile[] = [];
  const slots = new Map<number, SaveFile[]>();
  for (const file of files) {
    if (!matches(file, query)) {
      continue;
    }
    if (file.kind === 'slot') {
      if (file.slot === null) {
        unknown.push(file);
      } else {
        slots.set(file.slot, [...(slots.get(file.slot) || []), file]);
      }
    } else if (file.kind === 'other') {
      other.push(file);
    } else {
      account.push(file);
    }
  }
  const groups: SaveGroup[] = [];
  if (account.length) {
    groups.push({ id: 'account', title: 'Аккаунт', slot: null, active: false, files: account });
  }
  const numbers = [...slots.keys()].sort((a, b) => {
    if (a === defaultSlot) return -1;
    if (b === defaultSlot) return 1;
    return a - b;
  });
  for (const slot of numbers) {
    const slotFiles = slots.get(slot)!;
    const character = slotFiles.find((file) => file.character)?.character;
    groups.push({
      id: `slot-${slot}`,
      title: character ? `Слот ${slot} · ${character}` : `Слот ${slot}`,
      slot,
      active: slot === defaultSlot,
      files: slotFiles.sort((a, b) => Number(!!a.recovery) - Number(!!b.recovery)),
    });
  }
  if (unknown.length) {
    groups.push({ id: 'unknown', title: 'Разделы без номера слота', slot: null, active: false, files: unknown });
  }
  if (other.length) {
    groups.push({ id: 'other', title: 'Прочие файлы', slot: null, active: false, files: other });
  }
  return groups;
};

export const fileLabel = (file: SaveFile) => {
  if (file.kind === 'slot' && file.slot !== null) {
    return file.recovery ? 'откат (.recovery)' : 'раздел слота';
  }
  switch (file.kind) {
    case 'root':
      return 'корень (preferences.sav.json)';
    case 'recovery':
      return 'откат корня (.recovery)';
    default:
      return file.path;
  }
};

const unescapeText = (value: string) =>
  value.replace(/%([0-9a-f]{2})/gi, (_, code: string) => (code.toLowerCase() === 'ff' ? '' : String.fromCharCode(parseInt(code, 16))));

/** Узел значения JSON-сейва в обычное значение JS: так поля читаются без обёрток type/items. */
export const decodeSaveValue = (value: unknown): unknown => {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) {
    return value;
  }
  const node = value as Record<string, any>;
  switch (node.type) {
    case 'text':
      return typeof node.value === 'string' ? unescapeText(node.value) : node.value;
    case 'number':
      return Number(node.value);
    case 'path':
      return node.value;
    case 'matrix': {
      const numbers = decodeSaveValue(node.values);
      return `matrix(${Array.isArray(numbers) ? numbers.join(', ') : '?'})`;
    }
    case 'byond': {
      const text = String(decodeSaveValue(node.text) ?? '');
      const file = /filedata\("name=([^;"]*)/.exec(text);
      if (file) {
        let name = file[1];
        try {
          name = decodeURIComponent(decodeURIComponent(name));
        } catch {
          // Имя показываем как есть.
        }
        return `[BYOND: файл ${name}, ${text.length} симв.]`;
      }
      const compact = text.replace(/%0a/g, ' ').trim();
      return `[BYOND: ${compact.length > 120 ? `${compact.slice(0, 120)}…` : compact}]`;
    }
    case 'list': {
      const items: unknown[] = Array.isArray(node.items) ? node.items : [];
      const associations: unknown[] = Array.isArray(node.associations) ? node.associations : [];
      if (associations.every((association) => association === null || association === undefined)) {
        return items.map(decodeSaveValue);
      }
      const result: Record<string, unknown> = {};
      items.forEach((item, index) => {
        const decoded = decodeSaveValue(item);
        const base = typeof decoded === 'string' ? decoded : JSON.stringify(decoded);
        let key = base;
        for (let copy = 2; key in result; copy++) {
          key = `${base} (${copy})`;
        }
        result[key] = decodeSaveValue(associations[index] ?? null);
      });
      return result;
    }
    default:
      return value;
  }
};

const decodeTree = (tree: Record<string, any>): Record<string, unknown> => {
  const result: Record<string, unknown> = {};
  for (const [key, node] of Object.entries(tree)) {
    if (!node || typeof node !== 'object') {
      result[key] = node;
      continue;
    }
    const children = node.children && typeof node.children === 'object' && !Array.isArray(node.children) ? node.children : {};
    const value = decodeSaveValue(node.value ?? null);
    if (!Object.keys(children).length) {
      result[key] = value;
      continue;
    }
    result[key] = value === null ? decodeTree(children) : { '(значение)': value, ...decodeTree(children) };
  }
  return result;
};

/** Удобочитаемый вид JSON-сейва; null, если текст не JSON-сейв (старый .sav, обрезанный файл). */
export const readableSave = (text: string | null): string | null => {
  if (!text) {
    return null;
  }
  try {
    const document = JSON.parse(text);
    if (!document || typeof document !== 'object' || !document.tree || typeof document.tree !== 'object') {
      return null;
    }
    // Поля сейва важнее служебных поколений и контрольной суммы, поэтому идут первыми.
    const { tree, format, version, ...service } = document;
    return JSON.stringify({ format, version, tree: decodeTree(tree), ...service }, null, 2);
  } catch {
    return null;
  }
};

export const prettyJson = (text: string | null): string | null => {
  if (!text) {
    return null;
  }
  try {
    return JSON.stringify(JSON.parse(text), null, 2);
  } catch {
    return null;
  }
};

export const MAX_FILTERED_LINES = 2000;

/** Строки с совпадением и их номера; поиск без учёта регистра. */
export const filterLines = (text: string, query: string) => {
  const needle = query.trim().toLowerCase();
  const lines = text.split('\n');
  const found: { line: number; text: string }[] = [];
  let total = 0;
  lines.forEach((line, index) => {
    if (line.toLowerCase().includes(needle)) {
      total++;
      if (found.length < MAX_FILTERED_LINES) {
        found.push({ line: index + 1, text: line });
      }
    }
  });
  return { found, total };
};

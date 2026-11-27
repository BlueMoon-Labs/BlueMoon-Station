import { decodeSaveValue, filterLines, formatSize, groupFiles, readableSave, SaveFile } from './helpers';

const file = (path: string, kind: SaveFile['kind'], slot: number | null = null, extra: Partial<SaveFile> = {}): SaveFile => ({
  path,
  kind,
  slot,
  recovery: path.endsWith('.recovery'),
  size: 100,
  ...extra,
});

describe('groupFiles', () => {
  const files = [
    file('pai.sav', 'other'),
    file('preferences.sav', 'legacy'),
    file('preferences.sav.json', 'root'),
    file('preferences.sav.json.d/aa.sav.json.recovery', 'slot', 3, { character: 'Агнес' }),
    file('preferences.sav.json.d/aa.sav.json', 'slot', 3, { character: 'Агнес' }),
    file('preferences.sav.json.d/bb.sav.json', 'slot', 31, { character: 'Anahit' }),
    file('preferences.sav.json.d/cc.sav.json', 'slot', null),
  ];

  it('ставит аккаунт первым, активный слот перед остальными, раздел перед откатом', () => {
    const groups = groupFiles(files, 31);
    expect(groups.map((group) => group.id)).toEqual(['account', 'slot-31', 'slot-3', 'unknown', 'other']);
    expect(groups[1].active).toBe(true);
    expect(groups[1].title).toBe('Слот 31 · Anahit');
    expect(groups[2].files.map((entry) => entry.path)).toEqual([
      'preferences.sav.json.d/aa.sav.json',
      'preferences.sav.json.d/aa.sav.json.recovery',
    ]);
  });

  it('фильтрует по имени персонажа и номеру слота', () => {
    expect(groupFiles(files, 31, 'агнес').map((group) => group.id)).toEqual(['slot-3']);
    expect(groupFiles(files, 31, '31').map((group) => group.id)).toEqual(['slot-31']);
  });
});

describe('decodeSaveValue', () => {
  it('раскрывает списки, числа, пути, текст и вшитые файлы', () => {
    expect(decodeSaveValue({ type: 'list', items: ['a', 'b'], associations: [null, null] })).toEqual(['a', 'b']);
    expect(decodeSaveValue({ type: 'list', items: ['k', 'k'], associations: [1, 2] })).toEqual({ k: 1, 'k (2)': 2 });
    expect(decodeSaveValue({ type: 'number', value: '12487411' })).toBe(12487411);
    expect(decodeSaveValue({ type: 'path', value: '/datum/gear/suit' })).toBe('/datum/gear/suit');
    expect(decodeSaveValue({ type: 'text', value: 'a%0ab%25' })).toBe('a\nb%');
    const sound = decodeSaveValue({
      type: 'byond',
      text: { type: 'text', value: '%0avalue = filedata("name=modular_sand%252fsound%252fpurr2.ogg;length=3")' },
    });
    expect(sound).toMatch(/^\[BYOND: файл modular_sand\/sound\/purr2\.ogg/);
  });
});

describe('readableSave', () => {
  it('сворачивает дерево узлов в поля', () => {
    const text = JSON.stringify({
      format: 'bluemoon-player-save',
      version: 1,
      tree: {
        default_slot: { value: 31, children: {} },
        character31: {
          value: { type: 'list', items: ['Anahit', ''], associations: [null, null] },
          children: { real_name: { value: 'Anahit', children: {} } },
        },
      },
    });
    const parsed = JSON.parse(readableSave(text)!);
    expect(parsed.tree.default_slot).toBe(31);
    expect(parsed.tree.character31).toEqual({ '(значение)': ['Anahit', ''], real_name: 'Anahit' });
  });

  it('не выдаёт читаемый вид для старого .sav и обрезанного JSON', () => {
    expect(readableSave('version = 79')).toBeNull();
    expect(readableSave('{"tree": {')).toBeNull();
  });
});

it('formatSize и filterLines', () => {
  expect(formatSize(512)).toBe('512 Б');
  expect(formatSize(14287628)).toBe('13.6 МБ');
  const result = filterLines('one\nTwo\nthree two', 'two');
  expect(result.total).toBe(2);
  expect(result.found.map((entry) => entry.line)).toEqual([2, 3]);
});

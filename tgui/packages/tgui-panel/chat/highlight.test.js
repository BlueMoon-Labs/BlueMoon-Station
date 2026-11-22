import { compileHighlightSettings, createHighlightSetting, highlightMessageNode, MAX_HIGHLIGHT_SETTINGS, migrateHighlightSettings, parseHighlightTerms } from './highlight';

// Разметка как у compose_message в code/game/say.dm
const SAY = '<span class="game say"><span class="name">Ваня Петров</span>'
  + ' <span class="message">говорит, "<span class="">Ваня, иди сюда!</span>"'
  + '</span></span>';
const RADIO = '<span class="secradio"><span class="name">[Охрана] '
  + '<span class="radiojob">[Офицер] </span>Анна</span>'
  + ' <span class="message">сообщает, "<span class="">Ваня на мостике</span>"'
  + '</span></span>';
const EMOTE = '<span class="emote"><b>Ваня Петров</b> чешет затылок.</span>';
const OOC = '<span class="ooc"><span class="prefix">OOC:</span>'
  + ' <EM>Ваня:</EM> <span class="message">Ваня тут</span></span>';
const SYSTEM = '<span class="notice">Ваня Петров хлопает вас по плечу.</span>';

const render = (html, settings) => {
  const node = document.createElement('div');
  node.innerHTML = html;
  const result = highlightMessageNode(node,
    compileHighlightSettings(settings));
  const marks = [...node.querySelectorAll('.Chat__highlight')]
    .map(mark => [mark.textContent, mark.style.backgroundColor]);
  return { result, marks, words: marks.map(mark => mark[0]) };
};

const group = fields => createHighlightSetting(fields);

describe('parseHighlightTerms', () => {
  test('splits by comma and new line, drops short terms', () => {
    expect(parseHighlightTerms('Ваня, Иван\nкэп , a,  '))
      .toEqual(['Ваня', 'Иван', 'кэп']);
  });
});

describe('compileHighlightSettings', () => {
  test('skips disabled, empty and colorless groups', () => {
    expect(compileHighlightSettings([
      group({ highlightText: 'Ваня', enabled: false }),
      group({ highlightText: ' , a' }),
      group({ highlightText: 'Ваня', highlightColor: '' }),
    ])).toEqual([]);
    expect(compileHighlightSettings(undefined)).toEqual([]);
  });

  test('escapes regex characters', () => {
    const { words } = render('<span>a.b axb (c)</span>', [
      group({ highlightText: 'a.b, (c)' }),
    ]);
    expect(words).toEqual(['a.b', '(c)']);
  });
});

describe('highlightMessageNode', () => {
  test('highlights everywhere without speechOnly', () => {
    expect(render(EMOTE, [group({ highlightText: 'Ваня' })]).words)
      .toEqual(['Ваня']);
  });

  test('speechOnly highlights speech and radio text only', () => {
    const settings = [group({ highlightText: 'Ваня', speechOnly: true })];
    expect(render(SAY, settings).words).toEqual(['Ваня']);
    expect(render(RADIO, settings).words).toEqual(['Ваня']);
    expect(render(EMOTE, settings).result).toBeNull();
    expect(render(OOC, settings).result).toBeNull();
    expect(render(SYSTEM, settings).result).toBeNull();
  });

  test('speechOnly ignores speaker name and radio job', () => {
    expect(render(SAY, [
      group({ highlightText: 'Петров', speechOnly: true }),
    ]).result).toBeNull();
    expect(render(RADIO, [
      group({ highlightText: 'Офицер, Анна', speechOnly: true }),
    ]).result).toBeNull();
  });

  test('each group keeps its color, upper group wins', () => {
    const { result, marks } = render(RADIO, [
      group({ highlightText: 'мостик', highlightColor: '#ff0000' }),
      group({ highlightText: 'Ваня, мостик', highlightColor: '#00ff00' }),
    ]);
    expect(result).toEqual({ color: '#ff0000', sound: false });
    expect(marks).toEqual([
      ['Ваня', 'rgb(0, 255, 0)'],
      ['мостик', 'rgb(255, 0, 0)'],
    ]);
  });

  test('sound comes from any matched group', () => {
    const settings = [
      group({ highlightText: 'Ваня' }),
      group({ highlightText: 'сюда', sound: true }),
      group({ highlightText: 'нигде', sound: true }),
    ];
    expect(render(SAY, settings).result.sound).toBe(true);
    expect(render(RADIO, settings).result.sound).toBe(false);
  });

  test('match word works with Cyrillic', () => {
    const settings = [group({ highlightText: 'Ваня', matchWord: true })];
    expect(render('<span>Ванялка, Ваня! Ваня,Ваня</span>', settings)
      .words).toEqual(['Ваня', 'Ваня', 'Ваня']);
  });

  test('ignores case unless matchCase is set', () => {
    expect(render('<span>ВАНЯ</span>', [
      group({ highlightText: 'ваня' }),
    ]).words).toEqual(['ВАНЯ']);
    expect(render('<span>ваня</span>', [
      group({ highlightText: 'Ваня', matchCase: true }),
    ]).result).toBeNull();
  });

  test('prefers longer phrases inside one group', () => {
    expect(render('<span>Иван Петров</span>', [
      group({ highlightText: 'Иван, Иван Петров' }),
    ]).words).toEqual(['Иван Петров']);
  });
});

describe('migrateHighlightSettings', () => {
  test('turns legacy single highlight into the first group', () => {
    const list = migrateHighlightSettings({
      highlightText: 'Ваня',
      highlightColor: '#123456',
      highlightSoundEnabled: true,
      matchWord: true,
    });
    expect(list).toHaveLength(1);
    expect(list[0]).toMatchObject({
      highlightText: 'Ваня',
      highlightColor: '#123456',
      sound: true,
      matchWord: true,
      matchCase: false,
      speechOnly: false,
      enabled: true,
    });
    expect(list[0].id).toBeTruthy();
  });

  test('keeps groups, fills missing fields, fixes ids and limit', () => {
    const list = migrateHighlightSettings({
      highlightText: 'ignored',
      highlightSettings: [
        { id: 'a', highlightText: 'x1' },
        null,
        'junk',
        { id: 'a', highlightText: 'x2' },
        ...Array.from({ length: 20 }, () => ({})),
      ],
    });
    expect(list).toHaveLength(MAX_HIGHLIGHT_SETTINGS);
    expect(list[0]).toMatchObject({ id: 'a', highlightText: 'x1',
      speechOnly: false, sound: false });
    expect(list[1].highlightText).toBe('x2');
    expect(new Set(list.map(item => item.id)).size).toBe(list.length);
  });
});

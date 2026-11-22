import { compileHighlightSettings, createHighlightSetting, DEFAULT_HIGHLIGHT_COLOR, highlightMessageNode, MAX_HIGHLIGHT_SETTINGS, migrateHighlightSettings, parseHighlightTerms } from './highlight';

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

  test('falls back to a shorter phrase when the longer one is not a word', () => {
    expect(render('<span>Иван Петрович</span>', [
      group({ highlightText: 'Иван, Иван Петров', matchWord: true }),
    ]).words).toEqual(['Иван']);
  });
});

describe('word boundaries across groups', () => {
  test('a word cut by an upper group is not a separate word below', () => {
    const { marks } = render('<span>Роботех и тех</span>', [
      group({ highlightText: 'робо', highlightColor: '#ff0000' }),
      group({ highlightText: 'тех', highlightColor: '#00ff00',
        matchWord: true }),
    ]);
    expect(marks).toEqual([
      ['Робо', 'rgb(255, 0, 0)'],
      ['тех', 'rgb(0, 255, 0)'],
    ]);
  });

  test('word start and word end', () => {
    const text = '<span>роботех киборобот техник тех</span>';
    expect(render(text, [group({ highlightText: 'робо', matchStart: true })])
      .words).toEqual(['робо']);
    expect(render(text, [group({ highlightText: 'тех', matchEnd: true })])
      .words).toEqual(['тех', 'тех']);
    expect(render(text, [group({ highlightText: 'тех', matchStart: true })])
      .words).toEqual(['тех', 'тех']);
    expect(render(text, [group({ highlightText: 'тех', matchWord: true })])
      .words).toEqual(['тех']);
  });

  test('matchWord overrides word start/end flags', () => {
    expect(render('<span>техник</span>', [
      group({ highlightText: 'тех', matchWord: true, matchStart: true }),
    ]).result).toBeNull();
  });

  test('a word split by markup is still one word', () => {
    expect(render('<span>Ва<b>ня</b>шка, <i>Ва</i>ня</span>', [
      group({ highlightText: 'Ваня', matchWord: true }),
    ]).words).toEqual(['Ва', 'ня']);
  });

  test('timestamp is not part of the first word', () => {
    const node = document.createElement('div');
    node.innerHTML = '<span class="ChatMessage__timestamp">12:30</span>'
      + '<span>Ваня тут</span>';
    const result = highlightMessageNode(node, compileHighlightSettings([
      group({ highlightText: 'Ваня', matchWord: true }),
      group({ highlightText: '30Ва' }),
    ]));
    expect(result).toEqual({ color: DEFAULT_HIGHLIGHT_COLOR, sound: false });
    expect([...node.querySelectorAll('.Chat__highlight')]
      .map(mark => mark.textContent)).toEqual(['Ваня']);
    expect(node.querySelector('.ChatMessage__timestamp').textContent)
      .toBe('12:30');
  });
});

describe('speechOnly for AI messages', () => {
  // robot_talk в code/modules/mob/living/silicon/say.dm, говорит ИИ
  const BINARY_AI = '<span class="binarysay"><span class="binarysay">Robotic'
    + ' Talk,</span> <font size="3"><b>ИИ Ваня</b></font> <font size="3">'
    + '<span class="command"><b>states, "Ваня на связи"</b></span></font>'
    + '</span>';
  // То же, говорит киборг
  const BINARY_BORG = '<span class="binarysay"><span class="binarysay">Robotic'
    + ' Talk,</span> <span class="name">Ваня</span>'
    + ' <span class="message">states, "Ваня тут"</span></span>';
  // relay_speech и relay_emote в code/modules/mob/living/silicon/ai/ai.dm
  const RELAYED_SPEECH = '<i><span class="game say">Relayed Speech: '
    + '<span class="name"><a href="#">Ваня (Инженер)</a> </span>'
    + '<span class="message">говорит, "Ваня тут"</span></span></i>';
  const RELAYED_EMOTE = '<i><span class="game say relayed_emote">Relayed'
    + ' Emote: <span class="name"><a href="#">Ваня (Инженер)</a> </span>'
    + '<span class="message">машет Ване.</span></span></i>';

  const settings = [group({ highlightText: 'Ваня, Ване', speechOnly: true })];

  test('AI speech in binary chat is speech, its name is not', () => {
    expect(render(BINARY_AI, settings).words).toEqual(['Ваня']);
    expect(render(BINARY_BORG, settings).words).toEqual(['Ваня']);
  });

  test('relayed speech counts, relayed emote does not', () => {
    expect(render(RELAYED_SPEECH, settings).words).toEqual(['Ваня']);
    expect(render(RELAYED_EMOTE, settings).result).toBeNull();
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

  test('returns null when settings carry no highlight at all', () => {
    expect(migrateHighlightSettings({ version: 1, theme: 'dark' })).toBeNull();
    expect(migrateHighlightSettings(undefined)).toBeNull();
    expect(migrateHighlightSettings({ matchCase: false })).toHaveLength(1);
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

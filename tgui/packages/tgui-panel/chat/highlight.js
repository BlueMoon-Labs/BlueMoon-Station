/**
 * @file
 * Группы подсветки чата: у каждой свои слова, цвет, звук и флаги.
 * "Только речь" ищет совпадения лишь в репликах персонажей (голос и рация),
 * не трогая имя говорящего, эмоции, действия, OOC и системные сообщения.
 *
 * Поиск идёт по сплошному тексту сообщения, а не по кускам, которые уже
 * порезала другая группа: границы слова проверяются по исходным соседним
 * символам, поэтому "тех" внутри "роботех" не считается отдельным словом,
 * даже если "робо" уже подсвечено.
 * @license MIT
 */

export const HIGHLIGHT_CLASS = 'Chat__highlight';
export const DEFAULT_HIGHLIGHT_COLOR = '#ffdd44';
export const MAX_HIGHLIGHT_SETTINGS = 10;

// Цвета новых групп по кругу, чтобы группы сразу различались.
export const HIGHLIGHT_PRESET_COLORS = [
  '#ffdd44',
  '#ff8080',
  '#7fd4ff',
  '#8ee68e',
  '#d9a0ff',
  '#ffb060',
];

/**
 * Корни, которыми сервер помечает речь (compose_message в code/game/say.dm):
 * "game say" для голоса, остальные - каналы рации (GLOB.freqtospan) и
 * бинарный канал синтетиков. Имя говорящего лежит в span.name,
 * сама реплика - в span.message.
 */
export const SPEECH_ROOT_CLASSES = [
  'say',
  'radio',
  'deptradio',
  'comradio',
  'secradio',
  'engradio',
  'medradio',
  'sciradio',
  'suppradio',
  'servradio',
  'aiprivradio',
  'syndradio',
  'centcomradio',
  'inteqradio',
  'lawradio',
  'blueteamradio',
  'redteamradio',
  'binarysay',
];

// Эмоции, которые ИИ видит через камеры (relay_emote), размечены как речь.
const NOT_SPEECH_CLASSES = ['relayed_emote', 'emote'];
// Сообщения из истории, пришедшие до класса relayed_emote.
const RELAYED_EMOTE_PREFIX = 'Relayed Emote';

const SPEECH_TEXT_CLASS = 'message';
// В бинарном канале реплика самого ИИ лежит в span.command (robot_talk).
const BINARY_ROOT_CLASS = 'binarysay';
const BINARY_TEXT_CLASS = 'command';

// Не текст сообщения: время слева. Разрывает слово, как перенос строки.
const SKIP_CLASSES = ['ChatMessage__timestamp', 'Chat__badge'];
const BREAK_TAGS = ['BR', 'DIV', 'P', 'LI', 'TR', 'TD', 'HR', 'IMG'];

const WORD_CHAR = /[0-9A-Za-z_À-ɏЀ-ӿ]/;
const BREAK = '\n';
// Невидимые символы не участвуют в поиске: сервер ставит &#8203; после
// разметки выделения в речи (say_emphasis), и "<b>Ва</b>&#8203;ня" - это "Ваня".
const INVISIBLE_CHAR = /[\u00AD\u200B-\u200F\u2060-\u2064\uFEFF]/;
const INVISIBLE_CHARS = /[\u00AD\u200B-\u200F\u2060-\u2064\uFEFF]/g;

let lastId = 0;

const createHighlightId = () => {
  lastId += 1;
  return 'hl' + Date.now().toString(36) + lastId.toString(36);
};

export const createHighlightSetting = (fields = {}) => ({
  id: createHighlightId(),
  enabled: true,
  highlightText: '',
  highlightColor: DEFAULT_HIGHLIGHT_COLOR,
  matchWord: false,
  matchStart: false,
  matchEnd: false,
  matchCase: false,
  speechOnly: false,
  sound: false,
  ...fields,
});

const escapeRegExp = str => str.replace(/[-/\\^$*+?.()|[\]{}]/g, '\\$&');

/**
 * Слова и фразы группы: через запятую или с новой строки.
 * Короче двух символов не подсвечиваются. Невидимые символы вырезаются:
 * текст, скопированный из чата, несёт &#8203; после разметки выделения,
 * а в тексте сообщения при поиске их нет.
 */
export const parseHighlightTerms = text => String(text || '')
  .split(/[,\n]/)
  .map(str => str.replace(INVISIBLE_CHARS, '').trim())
  .filter(str => str.length > 1);

/**
 * Готовая к поиску группа или null, если подсвечивать нечего.
 * "Целое слово" = граница и в начале, и в конце.
 */
export const compileHighlightSetting = setting => {
  if (!setting || setting.enabled === false || !setting.highlightColor) {
    return null;
  }
  const terms = parseHighlightTerms(setting.highlightText);
  if (terms.length === 0) {
    return null;
  }
  // Длинные фразы первыми: "Иван Петров" не должен съедаться словом "Иван".
  terms.sort((a, b) => b.length - a.length);
  const flags = 'g' + (setting.matchCase ? '' : 'i');
  return {
    color: setting.highlightColor,
    speechOnly: !!setting.speechOnly,
    sound: !!setting.sound,
    wordStart: !!(setting.matchWord || setting.matchStart),
    wordEnd: !!(setting.matchWord || setting.matchEnd),
    regexes: terms.map(term => new RegExp(escapeRegExp(term), flags)),
  };
};

export const compileHighlightSettings = settings => (
  (Array.isArray(settings) ? settings : [])
    .map(compileHighlightSetting)
    .filter(Boolean)
);

const hasClass = (node, className) => {
  const value = node.className;
  return typeof value === 'string'
    && (' ' + value + ' ').indexOf(' ' + className + ' ') !== -1;
};

const hasAnyClass = (node, classNames) => (
  classNames.some(className => hasClass(node, className))
);

const NOT_SPEECH_ROOT = '!';

const isNotSpeechRoot = node => {
  if (hasAnyClass(node, NOT_SPEECH_CLASSES)) {
    return true;
  }
  const first = node.firstChild;
  return !!first && first.nodeType === Node.TEXT_NODE
    && first.nodeValue.trimStart().startsWith(RELAYED_EMOTE_PREFIX);
};

/**
 * Сплошной текст сообщения без невидимых символов и откуда взялся каждый
 * кусок. У куска speech - он внутри реплики персонажа; offsets[i] - позиция
 * i-го символа куска в исходном тексте узла (последний элемент - длина узла).
 */
export const collectMessageText = root => {
  let text = '';
  const segments = [];
  const addBreak = () => {
    if (text && text[text.length - 1] !== BREAK) {
      text += BREAK;
    }
  };
  // rootClass: '' - корень ещё не найден, NOT_SPEECH_ROOT - внутри эмоции,
  // иначе класс корня речи; speech - внутри реплики.
  const walk = (node, rootClass, speech) => {
    for (const child of Array.from(node.childNodes)) {
      if (child.nodeType === Node.TEXT_NODE) {
        const value = child.nodeValue;
        let visible = '';
        const offsets = [];
        for (let i = 0; i < value.length; i++) {
          if (!INVISIBLE_CHAR.test(value[i])) {
            visible += value[i];
            offsets.push(i);
          }
        }
        offsets.push(value.length);
        if (visible) {
          segments.push({ node: child, start: text.length,
            end: text.length + visible.length, speech, offsets });
          text += visible;
        }
        continue;
      }
      if (child.nodeType !== Node.ELEMENT_NODE) {
        continue;
      }
      if (hasAnyClass(child, SKIP_CLASSES)) {
        addBreak();
        continue;
      }
      const isBreak = BREAK_TAGS.indexOf(child.tagName) !== -1;
      if (isBreak) {
        addBreak();
      }
      let childRoot = rootClass;
      let childSpeech = speech;
      if (!rootClass) {
        // Корень решается один раз: внутри эмоции речи нет, вложенное
        // уже не проверяется.
        childRoot = isNotSpeechRoot(child) ? NOT_SPEECH_ROOT
          : SPEECH_ROOT_CLASSES
            .find(className => hasClass(child, className)) || '';
      }
      else if (rootClass !== NOT_SPEECH_ROOT && !speech) {
        childSpeech = hasClass(child, SPEECH_TEXT_CLASS)
          || (rootClass === BINARY_ROOT_CLASS
            && hasClass(child, BINARY_TEXT_CLASS));
      }
      walk(child, childRoot, childSpeech);
      if (isBreak) {
        addBreak();
      }
    }
  };
  walk(root, '', false);
  return { text, segments };
};

const isWordChar = ch => !!ch && WORD_CHAR.test(ch);

// Весь диапазон [start, end) покрыт подходящими кусками без разрывов.
const isCovered = (segments, start, end, speechOnly) => {
  let pos = start;
  for (const segment of segments) {
    if (segment.end <= pos) {
      continue;
    }
    if (segment.start > pos || (speechOnly && !segment.speech)) {
      return false;
    }
    pos = segment.end;
    if (pos >= end) {
      return true;
    }
  }
  return false;
};

const overlaps = (claims, start, end) => claims.some(claim => (
  claim.start < end && start < claim.end));

/**
 * Находит совпадения всех групп в сплошном тексте. Верхняя группа главнее:
 * занятый ею кусок текста нижние группы уже не берут. Внутри группы - как
 * у обычного поиска: левое совпадение раньше, при общем начале длиннее
 * ("аб, бвг" в "абвг" подсветит "аб").
 */
export const findHighlightMatches = (message, compiledSettings) => {
  const { text, segments } = message;
  const claims = [];
  compiledSettings.forEach((compiled, group) => {
    const candidates = [];
    for (const regex of compiled.regexes) {
      regex.lastIndex = 0;
      let match;
      while ((match = regex.exec(text))) {
        const start = match.index;
        const end = start + match[0].length;
        // Следующий поиск со следующего символа: совпадения могут
        // перекрываться, а это могло не подойти по границам.
        regex.lastIndex = start + 1;
        if (compiled.wordStart && isWordChar(text[start - 1])) {
          continue;
        }
        if (compiled.wordEnd && isWordChar(text[end])) {
          continue;
        }
        if (overlaps(claims, start, end)
          || !isCovered(segments, start, end, compiled.speechOnly)) {
          continue;
        }
        candidates.push({ start, end });
      }
    }
    candidates.sort((a, b) => a.start - b.start || b.end - a.end);
    const taken = [];
    for (const { start, end } of candidates) {
      if (!overlaps(taken, start, end)) {
        taken.push({ start, end });
        claims.push({ start, end, group, color: compiled.color });
      }
    }
  });
  return claims.sort((a, b) => a.start - b.start);
};

export const createHighlightNode = (text, color) => {
  const node = document.createElement('span');
  node.className = HIGHLIGHT_CLASS;
  node.setAttribute('style', 'background-color:' + color);
  node.textContent = text;
  return node;
};

const wrapSegment = (segment, claims) => {
  const value = segment.node.nodeValue;
  const { offsets } = segment;
  let fragment = null;
  let pos = 0;
  for (const claim of claims) {
    const visibleFrom = Math.max(claim.start, segment.start) - segment.start;
    const visibleTo = Math.min(claim.end, segment.end) - segment.start;
    if (visibleFrom >= visibleTo) {
      continue;
    }
    // В исходный текст узла: невидимые символы по краям остаются снаружи.
    const from = offsets[visibleFrom];
    const to = offsets[visibleTo - 1] + 1;
    if (!fragment) {
      fragment = document.createDocumentFragment();
    }
    if (pos < from) {
      fragment.appendChild(document.createTextNode(value.slice(pos, from)));
    }
    fragment.appendChild(createHighlightNode(value.slice(from, to),
      claim.color));
    pos = to;
  }
  if (fragment) {
    if (pos < value.length) {
      fragment.appendChild(document.createTextNode(value.slice(pos)));
    }
    segment.node.parentNode.replaceChild(fragment, segment.node);
  }
};

/**
 * Подсвечивает узел сообщения всеми группами.
 * Возвращает null, если ничего не нашлось, иначе цвет самой верхней
 * сработавшей группы и нужен ли звук (его просит любая сработавшая группа).
 */
export const highlightMessageNode = (node, compiledSettings) => {
  if (!compiledSettings.length) {
    return null;
  }
  const message = collectMessageText(node);
  const claims = findHighlightMatches(message, compiledSettings);
  if (!claims.length) {
    return null;
  }
  for (const segment of message.segments) {
    wrapSegment(segment, claims.filter(claim => (
      claim.start < segment.end && segment.start < claim.end)));
  }
  let top = claims[0];
  let sound = false;
  for (const claim of claims) {
    if (claim.group < top.group) {
      top = claim;
    }
    sound = sound || compiledSettings[claim.group].sound;
  }
  return { color: top.color, sound };
};

const isObject = value => !!value
  && typeof value === 'object' && !Array.isArray(value);

// Поля одиночной подсветки до v8 настроек.
export const LEGACY_HIGHLIGHT_KEYS = ['highlightText', 'highlightColor',
  'highlightSoundEnabled', 'matchWord', 'matchCase'];

/**
 * Список групп из загруженных настроек или null, если в них нет ни групп,
 * ни старой одиночной подсветки (частичная загрузка: оставить как есть).
 * Старая подсветка становится первой группой.
 */
export const migrateHighlightSettings = settings => {
  const list = settings?.highlightSettings;
  if (Array.isArray(list)) {
    const seen = {};
    return list
      .filter(isObject)
      .slice(0, MAX_HIGHLIGHT_SETTINGS)
      .map(item => {
        let id = typeof item.id === 'string' && item.id;
        if (!id || seen[id]) {
          id = createHighlightId();
        }
        seen[id] = true;
        return createHighlightSetting({ ...item, id });
      });
  }
  if (!isObject(settings)
    || !LEGACY_HIGHLIGHT_KEYS.some(key => settings[key] !== undefined)) {
    return null;
  }
  return [createHighlightSetting({
    highlightText: settings.highlightText || '',
    highlightColor: settings.highlightColor || DEFAULT_HIGHLIGHT_COLOR,
    matchWord: !!settings.matchWord,
    matchCase: !!settings.matchCase,
    sound: !!settings.highlightSoundEnabled,
  })];
};

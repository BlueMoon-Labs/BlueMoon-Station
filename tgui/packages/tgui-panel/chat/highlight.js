/**
 * @file
 * Группы подсветки чата: у каждой свои слова, цвет, звук и флаги.
 * "Только речь" ищет совпадения лишь в репликах персонажей (голос и рация),
 * не трогая имя говорящего, эмоции, действия, OOC и системные сообщения.
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
 * "game say" для голоса, остальные - каналы рации (GLOB.freqtospan).
 * Внутри корня имя говорящего лежит в span.name, сама реплика - в span.message.
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

const SPEECH_TEXT_CLASS = 'message';

// \b в JS видит только латиницу: границы слова задаются вручную,
// чтобы "Целое слово" работало и с кириллицей.
const WORD_CHARS = '0-9A-Za-z_\\u00C0-\\u024F\\u0400-\\u04FF';

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
  matchCase: false,
  speechOnly: false,
  sound: false,
  ...fields,
});

const escapeRegExp = str => str.replace(/[-/\\^$*+?.()|[\]{}]/g, '\\$&');

/**
 * Слова и фразы группы: через запятую или с новой строки.
 * Короче двух символов не подсвечиваются.
 */
export const parseHighlightTerms = text => String(text || '')
  .split(/[,\n]/)
  .map(str => str.trim())
  .filter(str => str.length > 1);

/**
 * Регулярка группы или null, если подсвечивать нечего.
 * Группа 1 - левая граница слова (пустая без matchWord), группа 2 - совпадение.
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
  const body = terms.map(escapeRegExp).join('|');
  const pattern = setting.matchWord
    ? `(^|[^${WORD_CHARS}])(${body})(?![${WORD_CHARS}])`
    : `()(${body})`;
  return {
    color: setting.highlightColor,
    speechOnly: !!setting.speechOnly,
    sound: !!setting.sound,
    regex: new RegExp(pattern, 'g' + (setting.matchCase ? '' : 'i')),
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

/**
 * Текстовые узлы для поиска. Уже подсвеченное пропускается:
 * группа выше по списку главнее.
 */
export const collectHighlightTextNodes = (root, speechOnly) => {
  const result = [];
  const walk = (node, inSpeechRoot, inSpeechText) => {
    for (const child of Array.from(node.childNodes)) {
      if (child.nodeType === Node.TEXT_NODE) {
        if (!speechOnly || inSpeechText) {
          result.push(child);
        }
        continue;
      }
      if (child.nodeType !== Node.ELEMENT_NODE
        || hasClass(child, HIGHLIGHT_CLASS)) {
        continue;
      }
      const childInRoot = inSpeechRoot
        || hasAnyClass(child, SPEECH_ROOT_CLASSES);
      const childInText = inSpeechText
        || (childInRoot && hasClass(child, SPEECH_TEXT_CLASS));
      walk(child, childInRoot, childInText);
    }
  };
  walk(root, false, false);
  return result;
};

export const createHighlightNode = (text, color) => {
  const node = document.createElement('span');
  node.className = HIGHLIGHT_CLASS;
  node.setAttribute('style', 'background-color:' + color);
  node.textContent = text;
  return node;
};

const highlightTextNode = (textNode, compiled) => {
  const text = textNode.textContent;
  const regex = compiled.regex;
  regex.lastIndex = 0;
  let fragment = null;
  let lastIndex = 0;
  let count = 0;
  let match;
  while ((match = regex.exec(text))) {
    const start = match.index + match[1].length;
    const matchText = match[2];
    if (!fragment) {
      fragment = document.createDocumentFragment();
    }
    if (lastIndex < start) {
      fragment.appendChild(document.createTextNode(
        text.substring(lastIndex, start)));
    }
    fragment.appendChild(createHighlightNode(matchText, compiled.color));
    lastIndex = start + matchText.length;
    // Левая граница уже съедена: следующий поиск сразу после слова.
    regex.lastIndex = lastIndex;
    count += 1;
  }
  if (fragment) {
    if (lastIndex < text.length) {
      fragment.appendChild(document.createTextNode(
        text.substring(lastIndex)));
    }
    textNode.parentNode.replaceChild(fragment, textNode);
  }
  return count;
};

/**
 * Подсвечивает узел сообщения всеми группами по порядку.
 * Возвращает null, если ничего не нашлось, иначе цвет первой сработавшей
 * группы и нужен ли звук (его просит любая сработавшая группа).
 */
export const highlightMessageNode = (node, compiledSettings) => {
  let result = null;
  for (const compiled of compiledSettings) {
    let count = 0;
    for (const textNode of collectHighlightTextNodes(
      node, compiled.speechOnly)) {
      count += highlightTextNode(textNode, compiled);
    }
    if (count > 0) {
      if (!result) {
        result = { color: compiled.color, sound: false };
      }
      result.sound = result.sound || compiled.sound;
    }
  }
  return result;
};

const isObject = value => !!value
  && typeof value === 'object' && !Array.isArray(value);

/**
 * Список групп из сохранённых настроек. Старая одиночная подсветка
 * (highlightText, highlightColor, matchWord, matchCase, highlightSoundEnabled)
 * становится первой группой.
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
  return [createHighlightSetting({
    highlightText: settings?.highlightText || '',
    highlightColor: settings?.highlightColor || DEFAULT_HIGHLIGHT_COLOR,
    matchWord: !!settings?.matchWord,
    matchCase: !!settings?.matchCase,
    sound: !!settings?.highlightSoundEnabled,
  })];
};

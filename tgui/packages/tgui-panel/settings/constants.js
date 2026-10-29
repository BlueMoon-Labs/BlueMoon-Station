/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

export const SETTINGS_TABS = [
  {
    id: 'general',
    name: 'Основные',
  },
  {
    id: 'appearance',
    name: 'Оформление',
  },
  {
    id: 'textStyles',
    name: 'Стили текста',
  },
  {
    id: 'channels',
    name: 'Каналы',
  },
  {
    id: 'effects',
    name: 'Игровые эффекты',
  },
  {
    id: 'chatPage',
    name: 'Вкладки чата',
  },
];

// Стили сообщений, доступные для кастомизации игроком.
// id совпадает с CSS-классом спана и именем переменной --cs-<id>-color.
// extraClasses - дополнительные спаны, которые красятся той же переменной
// и сбрасываются тем же plain-классом.
export const MESSAGE_STYLES = [
  { id: 'emote', name: 'Эмоции', example: '* Пример эмоции персонажа' },
  { id: 'whisper', name: 'Шёпот', example: 'Пример шёпота' },
  { id: 'singing', name: 'Пение', example: 'Пример песни ~' },
  { id: 'lewd', name: 'НСФВ', example: 'Пример непристойной фразы' },
  { id: 'purr', name: 'Мурчание', example: 'Пример мурчания' },
  { id: 'croon', name: 'Воркование', example: 'Пример воркования' },
  { id: 'deadsay', name: 'Мёртвые', example: 'Пример речи призрака' },
  {
    id: 'telepathy',
    name: 'Телепатия',
    example: 'Пример телепатии',
    extraClasses: ['telepathybold'],
  },
  { id: 'signlang', name: 'Жесты', example: 'Пример жестовой речи' },
  { id: 'thought', name: 'Мысли', example: 'Пример мысли' },
  { id: 'dream', name: 'Сны', example: 'Пример сна' },
];

// Начертание текста стиля: пусто = как в теме.
export const MESSAGE_STYLE_FONTS = [
  { id: '', name: 'Тема' },
  { id: 'normal', name: 'Обычный' },
  { id: 'italic', name: 'Курсив' },
  { id: 'bold', name: 'Жирный' },
  { id: 'bolditalic', name: 'Жирный курсив' },
];

// Декоративные анимации стиля: пусто = как в теме.
// css - значение свойства animation; кейфреймы cs-* лежат в Chat.scss.
// Свечение перерисовывает text-shadow всего чата, поэтому идёт 15 шагами в секунду.
export const MESSAGE_STYLE_ANIMATIONS = [
  { id: '', name: 'Тема', css: null },
  { id: 'none', name: 'Нет', css: 'none' },
  {
    id: 'pulse',
    name: 'Пульс',
    css: 'cs-pulse 2000ms ease-in-out infinite alternate',
  },
  {
    id: 'glow',
    name: 'Свечение',
    css: 'cs-glow 2400ms steps(36) infinite alternate',
  },
  {
    id: 'flicker',
    name: 'Мерцание',
    css: 'cs-flicker 1600ms steps(4) infinite',
  },
  {
    id: 'rainbow',
    name: 'Радуга',
    css: 'cs-rainbow 6000ms linear infinite',
  },
];

// Игровые эффекты текста. Каждый выключается отдельно.
export const GAME_EFFECTS = [
  { id: 'tremble', name: 'Дрожь', tooltip: 'Заикание и сильный тремор говорящего', sample: '<span class="tremble">Я н-не боюсь</span>' },
  { id: 'yell', name: 'Встряска при крике', tooltip: 'Строка с криком один раз вздрагивает', sample: '<span class="yell">Стоять!</span>' },
  { id: 'drunk', name: 'Опьянение', tooltip: 'Речь пьяного плывёт', sample: '<span class="drunk_speech">Ещё по одной</span>' },
  { id: 'gasp', name: 'Удушье', tooltip: 'Речь задыхающегося бледнеет к концу', sample: '<span class="gasp_speech">Воздуха...</span>' },
  { id: 'shiver', name: 'Озноб', tooltip: 'Речь замёрзшего дрожит от холода', sample: '<span class="shiver">Х-холодно</span>' },
  { id: 'muffled', name: 'Приглушённость', tooltip: 'Речь сквозь кляп и при повреждённых ушах', sample: '<span class="muffled_speech">Ммф, помогите</span>' },
  { id: 'radio_static', name: 'Помехи рации', tooltip: 'Сообщения по рации при плохом сигнале', sample: '<span class="radio_static">[Общий] ...приём...</span>' },
  { id: 'hallucination', name: 'Галлюцинации', tooltip: 'Иногда чужая речь искажается, пока вы галлюцинируете', sample: '<span class="hear_hallucination">Они за тобой</span>' },
  { id: 'druggy', name: 'Вещества', tooltip: 'Под веществами цвет речи плывёт', sample: '<span class="hear_druggy">Как красиво</span>' },
  { id: 'dizzy', name: 'Головокружение', tooltip: 'При головокружении строки покачиваются', sample: '<span class="hear_dizzy">Всё кружится</span>' },
];

export const CHAT_STYLES = [
  { id: 'classic', name: 'Классический' },
  { id: 'bubbles', name: 'Пузырьки' },
  { id: 'compact', name: 'Компактный' },
  { id: 'terminal', name: 'Терминал' },
  { id: 'cozy', name: 'Уютный' },
  { id: 'glass', name: 'Стекло' },
  { id: 'neon', name: 'Неон' },
  { id: 'retro', name: 'Ретро' },
  { id: 'darkpro', name: 'Тёмный Про' },
  { id: 'cyberpunk', name: 'Киберпанк' },
  { id: 'sakura', name: 'Сакура' },
  { id: 'space', name: 'Космос' },
  { id: 'vaporwave', name: 'Вейпорвейв' },
  { id: 'ntfax', name: 'Факс НТ (светлая тема)' },
  { id: 'seccon', name: 'Консоль СБ' },
  { id: 'pda', name: 'КПК' },
  { id: 'logbook', name: 'Бортжурнал' },
  { id: 'syndicate', name: 'Шифровка Синдиката' },
  { id: 'bridge', name: 'Мостик' },
  { id: 'medbay', name: 'Медотсек' },
  { id: 'engineering', name: 'Инженерия' },
  { id: 'cargo', name: 'Снабжение' },
  { id: 'centcom', name: 'ЦентКом' },
  { id: 'blackbox', name: 'Чёрный ящик (тёмная тема)' },
];

export const CHAT_ANIMATIONS = [
  { id: 'none', name: 'Нет' },
  { id: 'fadein', name: 'Появление' },
  { id: 'slidein', name: 'Выезд' },
  { id: 'bounce', name: 'Прыжок' },
  { id: 'drop', name: 'Сверху' },
  { id: 'zoomin', name: 'Масштаб' },
  { id: 'pop', name: 'Хлопок' },
  { id: 'glowin', name: 'Свечение' },
  { id: 'teletype', name: 'Телетайп' },
  { id: 'faxfeed', name: 'Печать факса' },
  { id: 'interference', name: 'Помеха' },
  { id: 'crtscan', name: 'Развёртка ЭЛТ' },
  { id: 'airlock', name: 'Шлюз' },
  { id: 'develop', name: 'Проявка' },
  { id: 'scanner', name: 'Сканер' },
  { id: 'lamp', name: 'Лампа' },
];

// Типы сообщений для вкладки "Каналы". type - id из chat/constants.js.
export const CHANNEL_TYPES = [
  { type: 'radio', name: 'Рация', example: '[Общий] Инженер говорит, "Приём."' },
  { type: 'ooc', name: 'OOC', example: 'OOC: Игрок: всем привет' },
  { type: 'looc', name: 'LOOC', example: 'LOOC: Игрок: я отойду' },
  { type: 'antagooc', name: 'Антаг-OOC', example: 'AOOC: Игрок: план готов' },
  { type: 'adminpm', name: 'ПМ админа', example: 'ПМ от Админ: что случилось?' },
  { type: 'mentorsay', name: 'Менторы', example: 'Ментор PM от Ментор: держи подсказку' },
  { type: 'combat', name: 'Бой', example: 'Ассистент бьёт вас ящиком!' },
  { type: 'deadchat', name: 'Мёртвые', example: 'МЁРТВ: Призрак: скучно' },
  { type: 'warning', name: 'Предупреждения', example: 'Вы чувствуете слабость.' },
  { type: 'system', name: 'Системные', example: 'Раунд начнётся через 30 секунд.' },
  { type: 'lewd', name: 'НСФВ', example: 'Пример непристойного сообщения' },
  { type: 'adminchat', name: 'Админ-чат', example: 'ADMIN: Админ: проверьте тикет' },
];

// Анимация появления по типу: '' = как у чата.
export const TYPE_ANIM_KEYFRAMES = {
  fadein: 'chatFadeIn',
  slidein: 'chatSlideIn',
  bounce: 'chatBounce',
  drop: 'chatDrop',
  zoomin: 'chatZoomIn',
  pop: 'chatPop',
  glowin: 'chatGlowIn',
  teletype: 'chatTeletype',
  faxfeed: 'chatFaxFeed',
  interference: 'chatInterference',
  crtscan: 'chatCrtScan',
  airlock: 'chatAirlock',
  develop: 'chatDevelop',
  scanner: 'chatScanner',
  lamp: 'chatLamp',
};

export const RECOMMENDED_TYPE_OVERRIDES = {
  adminpm: { border: '#c0392b', flash: true },
  mentorsay: { border: '#3d7cc9', flash: true },
  radio: { border: '#6b7a8f' },
  combat: { border: '#7a1f1f' },
  deadchat: { border: '#5b4b8a', tint: true },
};

export const CHAT_ANIM_SPEEDS = [
  { id: 'fast', name: 'Быстро', value: '180ms' },
  { id: 'normal', name: 'Нормально', value: '320ms' },
  { id: 'slow', name: 'Медленно', value: '550ms' },
];

export const TEXT_GLOW_OPTIONS = [
  { id: 'none', name: 'Нет' },
  { id: 'subtle', name: 'Тонкое' },
  { id: 'strong', name: 'Сильное' },
];

export const TIMESTAMP_FORMATS = [
  { id: 'hm', name: 'ЧЧ:ММ' },
  { id: 'hms', name: 'ЧЧ:ММ:СС' },
];

export const TIME_DIVIDER_INTERVALS = [
  { id: 60000, name: '1 мин' },
  { id: 300000, name: '5 мин' },
  { id: 600000, name: '10 мин' },
];

export const CHAT_BG_ANIMATIONS = [
  { id: 'none', name: 'Нет' },
  { id: 'cosmos', name: 'Космос' },
  { id: 'nebula', name: 'Туманность' },
  { id: 'matrix', name: 'Матрица' },
  { id: 'aurora', name: 'Аврора' },
  { id: 'pulse', name: 'Пульс' },
  { id: 'waves', name: 'Волны' },
  { id: 'fireflies', name: 'Светлячки' },
  { id: 'sakura', name: 'Лепестки' },
  { id: 'gradient', name: 'Градиент' },
  { id: 'rain', name: 'Дождь' },
  { id: 'embers', name: 'Угольки' },
  { id: 'snow', name: 'Снег' },
  { id: 'ash', name: 'Пепел' },
  { id: 'hyperspace', name: 'Гиперпространство' },
  { id: 'crtnoise', name: 'Помехи ЭЛТ' },
  { id: 'meteors', name: 'Метеоры' },
  { id: 'beacon', name: 'Аварийный маячок' },
  { id: 'vents', name: 'Вентиляция' },
  { id: 'dust', name: 'Пыль астероидов' },
  { id: 'radiation', name: 'Радиация' },
];

export const FONTS_DISABLED = "Default";

export const FONTS = [
  FONTS_DISABLED,
  'Verdana',
  'Arial',
  'Arial Black',
  'Comic Sans MS',
  'Impact',
  'Lucida Sans Unicode',
  'Tahoma',
  'Trebuchet MS',
  'Courier New',
  'Lucida Console',
];

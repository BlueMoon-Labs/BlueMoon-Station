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
    css: 'cs-glow 2400ms ease-in-out infinite alternate',
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
];

export const CHAT_ANIM_SPEEDS = [
  { id: 'fast', name: 'Быстро', value: '100ms' },
  { id: 'normal', name: 'Нормально', value: '200ms' },
  { id: 'slow', name: 'Медленно', value: '400ms' },
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

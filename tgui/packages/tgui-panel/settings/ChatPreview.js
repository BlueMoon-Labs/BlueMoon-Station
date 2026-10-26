import { useSelector } from 'common/redux';
import { Box } from 'tgui/components';

import { getBlockFxClasses } from '../chat/messageFx';
import { getChatColorProps, getChatCustomProps, getGameFxRootClasses, getSettleRootClasses, getStyleOverrideRoot } from '../chat/rootAppearance';
import { CHANNEL_TYPES } from './constants';
import { selectSettings } from './selectors';

// Образцы рендерятся теми же классами, что и настоящий чат.
const APPEARANCE_SAMPLES = [
  { type: 'localchat', html: '<span class="say"><span class="name">Инженер</span> говорит, "Кто открыл шлюз?"</span>' },
  { type: 'localchat', html: '<span class="say"><span class="name">Ассистент</span> кричит, "<span class="yell">Пожар!</span>"</span>' },
  { type: 'radio', html: '<span class="radio">[Общий] <span class="name">Капитан</span> говорит, "Всем на мостик."</span>' },
  { type: 'ooc', html: '<span class="ooc">OOC: Игрок: всем привет</span>' },
  { type: 'adminpm', html: '<span class="pm">ПМ от Админ: всё в порядке?</span>' },
  { type: 'localchat', html: '<span class="emote">* Врач качает головой.</span>' },
  { type: 'localchat', html: '<span class="say"><span class="name">Бармен</span> говорит, "<span class="drunk_speech">Ещё по одной</span>"</span>' },
];

// Класс, по которому рендерер относит сообщение к каналу.
const CHANNEL_SAMPLE_CLASS = {
  radio: 'radio',
  ooc: 'ooc',
  looc: 'looc',
  antagooc: 'antagooc',
  adminpm: 'pm',
  mentorsay: 'mentorsay',
  combat: 'danger',
  deadchat: 'deadsay',
  warning: 'warning',
  system: 'boldannounce',
  lewd: 'love',
  adminchat: 'adminsay',
};

const escapeHtml = text => text
  .replace(/&/g, '&amp;')
  .replace(/</g, '&lt;')
  .replace(/>/g, '&gt;');

const CHANNEL_SAMPLES = CHANNEL_TYPES.map(channel => ({
  type: channel.type,
  html: '<span class="' + CHANNEL_SAMPLE_CLASS[channel.type] + '">'
    + escapeHtml(channel.example) + '</span>',
}));

const SAMPLE_SETS = {
  appearance: APPEARANCE_SAMPLES,
  channels: CHANNEL_SAMPLES,
};

const blockFxCache = new Map();

const getSampleFx = html => {
  if (!blockFxCache.has(html)) {
    const node = document.createElement('div');
    node.innerHTML = html;
    blockFxCache.set(html,
      getBlockFxClasses(node).map(cls => ' ' + cls).join(''));
  }
  return blockFxCache.get(html);
};

export const getPreviewRootClasses = settings => {
  const classes = ['Chat'];
  if (settings.chatStyle && settings.chatStyle !== 'classic') {
    classes.push('Chat--style-' + settings.chatStyle);
  }
  if (settings.hoverEffect) {
    classes.push('Chat--hover');
  }
  classes.push(...getStyleOverrideRoot(
    settings.styleOverrides, settings.spanAnimations !== false).classes);
  classes.push(...getGameFxRootClasses(
    settings.gameEffects, settings.gameEffectsEnabled !== false));
  classes.push(...getSettleRootClasses(settings.settleOldAnimations));
  return classes.join(' ');
};

export const getPreviewRootStyle = settings => {
  const props = {
    ...getChatColorProps(settings.chatBgColor, settings.chatTextColor,
      settings.chatAccentColor),
    ...getChatCustomProps(settings),
    ...getStyleOverrideRoot(
      settings.styleOverrides, settings.spanAnimations !== false).props,
  };
  const style = {};
  for (const [key, value] of Object.entries(props)) {
    if (value !== null && value !== undefined && value !== '') {
      style[key] = value;
    }
  }
  return style;
};

export const ChatPreview = props => {
  const { samples = 'appearance' } = props;
  const settings = useSelector(selectSettings);
  const animation = settings.chatAnimation || 'none';
  const anim = animation !== 'none'
    ? ' ChatMessage--anim-' + animation
    : '';
  // Смена анимации или её скорости пересоздаёт образцы, чтобы она проигралась.
  const replayKey = animation + '/' + (settings.chatAnimSpeed || '') + '/';
  return (
    <Box>
      <Box color="label" mb={0.5}>Предпросмотр:</Box>
      <div
        className={getPreviewRootClasses(settings) + ' ChatPreview'}
        style={getPreviewRootStyle(settings)}>
        {SAMPLE_SETS[samples].map((sample, i) => (
          <div
            key={replayKey + i}
            className={'ChatMessage ChatMessage--type-' + sample.type
              + getSampleFx(sample.html) + anim}
            // eslint-disable-next-line react/no-danger -- образцы: константы этого файла, не ввод игрока
            dangerouslySetInnerHTML={{ __html: sample.html }}
          />
        ))}
      </div>
    </Box>
  );
};

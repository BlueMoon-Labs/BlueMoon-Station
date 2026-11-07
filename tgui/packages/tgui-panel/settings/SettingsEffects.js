import { useDispatch, useSelector } from 'common/redux';
import { Box, Button, Divider, Section, Stack } from 'tgui/components';

import { getBlockFxClasses, SETTLE_KEEP } from '../chat/messageFx';
import { updateSettings } from './actions';
import { ChatPreview, getPreviewRootClasses } from './ChatPreview';
import { GAME_EFFECTS } from './constants';
import { selectSettings } from './selectors';

const SETTLE_TOOLTIP = 'Анимации у сообщений старше последних '
  + SETTLE_KEEP + ' останавливаются - меньше нагрузки на видеокарту.'
  + ' Выключите, если хотите, чтобы вся история продолжала анимироваться.';

let sampleFx = null;

// Блочные классы образцов - тем же правилом, что у рендерера.
const getSampleFx = id => {
  if (!sampleFx) {
    sampleFx = {};
    for (const effect of GAME_EFFECTS) {
      const node = document.createElement('div');
      node.innerHTML = effect.sample;
      sampleFx[effect.id] = getBlockFxClasses(node)
        .map(cls => ' ' + cls).join('');
    }
  }
  return sampleFx[id];
};

const toggledEffects = (effects, id, on) => {
  const next = { ...effects };
  if (on) {
    delete next[id];
  }
  else {
    next[id] = false;
  }
  return next;
};

export const SettingsEffects = props => {
  const {
    gameEffects,
    gameEffectsEnabled,
    settleOldAnimations,
  } = useSelector(selectSettings);
  const dispatch = useDispatch();
  const allOn = gameEffectsEnabled !== false;
  const rootClass = getPreviewRootClasses({
    chatStyle: 'classic',
    gameEffects,
    gameEffectsEnabled,
  });
  return (
    <Section>
      <Box color="label" mb={1}>
        Текст в чате отражает состояние персонажей: дрожь, опьянение,
        помехи рации и т.п. Каждый эффект можно выключить - тогда он
        показывается обычным текстом.
      </Box>
      <Box>
        <Button.Checkbox
          checked={allOn}
          onClick={() => dispatch(updateSettings({
            gameEffectsEnabled: !allOn,
          }))}>
          Игровые эффекты текста
        </Button.Checkbox>
      </Box>
      <Box>
        <Button.Checkbox
          checked={settleOldAnimations !== false}
          tooltip={SETTLE_TOOLTIP}
          onClick={() => dispatch(updateSettings({
            settleOldAnimations: settleOldAnimations === false,
          }))}>
          Гасить анимации старых сообщений
        </Button.Checkbox>
      </Box>
      <Divider />
      <div
        className={rootClass + ' SettingsEffects__samples'}
        style={{ overflow: 'hidden' }}>
        {GAME_EFFECTS.map(effect => {
          const on = gameEffects?.[effect.id] !== false;
          return (
            <Stack key={effect.id} align="center" mb={0.5}>
              <Stack.Item basis="13em" shrink={0}>
                <Button.Checkbox
                  checked={on}
                  disabled={!allOn}
                  tooltip={effect.tooltip}
                  onClick={() => dispatch(updateSettings({
                    gameEffects: toggledEffects(gameEffects, effect.id, !on),
                  }))}>
                  {effect.name}
                </Button.Checkbox>
              </Stack.Item>
              <Stack.Item grow basis={0} style={{ minWidth: 0 }}>
                <div
                  className={'ChatMessage' + getSampleFx(effect.id)}
                  // eslint-disable-next-line react/no-danger -- образцы: константы GAME_EFFECTS, не ввод игрока
                  dangerouslySetInnerHTML={{ __html: effect.sample }}
                />
              </Stack.Item>
            </Stack>
          );
        })}
      </div>
      <Divider />
      <ChatPreview />
      <Divider />
      <Button
        icon="undo"
        onClick={() => dispatch(updateSettings({
          gameEffects: {},
          gameEffectsEnabled: true,
          settleOldAnimations: true,
        }))}>
        Сбросить эффекты
      </Button>
    </Section>
  );
};

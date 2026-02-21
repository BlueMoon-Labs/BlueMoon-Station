import { useBackend } from '../backend';
import { Box, Button, Divider, ProgressBar, Section, Stack } from '../components';
import { Window } from '../layouts';

// Game status constants matching DM defines
const STATUS_START = 1;
const STATUS_NORMAL = 2;
const STATUS_GAMEOVER = 3;
const STATUS_MARKET = 4;

// Event constants matching DM defines
const EVENT = {
  RAIDERS: 'Raiders',
  FLUX: 'Interstellar Flux',
  ILLNESS: 'Illness',
  BREAKDOWN: 'Breakdown',
  LING: 'Changelings?',
  LING_ATTACK: 'Changeling Ambush',
  MALFUNCTION: 'Malfunction',
  COLLISION: 'Collision',
  SPACEPORT: 'Spaceport',
  BLACKHOLE: 'BlackHole',
  OLDSHIP: 'Old Ship',
  SEARCH: 'Old Ship Search',
};

// Resource bar color based on percentage
const resourceColor = (val, max) => {
  const pct = val / max;
  if (pct <= 0.15) return 'bad';
  if (pct <= 0.4) return 'average';
  return 'good';
};

// ---- Resource display component ----
const ResourceBar = (props) => {
  const { label, value, max, icon } = props;
  return (
    <Stack.Item>
      <Stack align="center">
        <Stack.Item basis="30%">
          <Box bold>
            {icon} {label}
          </Box>
        </Stack.Item>
        <Stack.Item grow>
          <ProgressBar
            value={Math.max(value, 0) / max}
            color={resourceColor(value, max)}
            ranges={{
              bad: [0, 0.15],
              average: [0.15, 0.4],
              good: [0.4, 1],
            }}>
            {value}
          </ProgressBar>
        </Stack.Item>
      </Stack>
    </Stack.Item>
  );
};

// ---- Parts display for spare parts ----
const PartsDisplay = (props) => {
  const { engine, hull, electronics } = props;
  return (
    <Stack fill>
      <Stack.Item grow textAlign="center">
        <Box bold>⚙️ Двигатель</Box>
        <Box color={engine > 0 ? 'good' : 'bad'} bold fontSize="18px">
          {engine}
        </Box>
      </Stack.Item>
      <Stack.Item grow textAlign="center">
        <Box bold>🛡️ Корпус</Box>
        <Box color={hull > 0 ? 'good' : 'bad'} bold fontSize="18px">
          {hull}
        </Box>
      </Stack.Item>
      <Stack.Item grow textAlign="center">
        <Box bold>💡 Электроника</Box>
        <Box color={electronics > 0 ? 'good' : 'bad'} bold fontSize="18px">
          {electronics}
        </Box>
      </Stack.Item>
    </Stack>
  );
};

// ---- Crew roster ----
const CrewList = (props) => {
  const { settlers } = props;
  if (!settlers || settlers.length === 0) {
    return (
      <Box color="bad" italic>
        Экипаж погиб...
      </Box>
    );
  }
  return (
    <Stack wrap>
      {settlers.map((name, i) => (
        <Stack.Item key={i}>
          <Box
            className="ArcadeOrionTrail__crew-badge"
            inline
            px="6px"
            py="2px"
            mr="4px"
            mb="4px">
            👤 {name}
          </Box>
        </Stack.Item>
      ))}
    </Stack>
  );
};

// ---- Event buttons based on event type ----
const EventButtons = (props, context) => {
  const { act } = useBackend(context);
  const { event, canContinueEvent, engine, hull, electronics } = props;

  const buttons = [];

  switch (event) {
    case EVENT.FLUX:
      buttons.push(
        { label: '🐌 Замедлиться', action: 'slow' },
        { label: '💨 Держать скорость', action: 'keepspeed' }
      );
      break;
    case EVENT.OLDSHIP:
      buttons.push(
        { label: '🔍 Обыскать корабль', action: 'search' },
        { label: '➡️ Оставить', action: 'eventclose' }
      );
      break;
    case EVENT.BREAKDOWN:
      if (engine > 0) {
        buttons.push({
          label: '⚙️ Использовать запчасть двигателя',
          action: 'useengine',
        });
      }
      buttons.push({ label: '🔧 Ждать 3 дня', action: 'wait' });
      break;
    case EVENT.MALFUNCTION:
      if (electronics > 0) {
        buttons.push({
          label: '💡 Заменить электронику',
          action: 'useelec',
        });
      }
      buttons.push({ label: '🔧 Ждать 3 дня', action: 'wait' });
      break;
    case EVENT.COLLISION:
      if (hull > 0) {
        buttons.push({
          label: '🛡️ Использовать обшивку',
          action: 'usehull',
        });
      }
      buttons.push({ label: '🔧 Ждать 3 дня', action: 'wait' });
      break;
    case EVENT.BLACKHOLE:
      buttons.push({
        label: '💀 Принять судьбу',
        action: 'holedeath',
        color: 'bad',
      });
      break;
    case EVENT.LING:
    case EVENT.LING_ATTACK:
      if (event === EVENT.LING) {
        buttons.push({
          label: '🔫 Убить члена экипажа',
          action: 'killcrew',
          color: 'danger',
        });
      }
      if (canContinueEvent) {
        buttons.push({ label: '➡️ Продолжить', action: 'eventclose' });
      }
      break;
    default:
      if (canContinueEvent) {
        buttons.push({ label: '➡️ Продолжить', action: 'eventclose' });
      }
      break;
  }

  if (buttons.length === 0) return null;

  return (
    <Box mt={1}>
      <Stack justify="center" wrap>
        {buttons.map((btn, i) => (
          <Stack.Item key={i}>
            <Button
              color={btn.color || 'default'}
              onClick={() => act(btn.action)}>
              {btn.label}
            </Button>
          </Stack.Item>
        ))}
      </Stack>
    </Box>
  );
};

// ---- Start Screen ----
const StartScreen = (props, context) => {
  const { act } = useBackend(context);
  return (
    <Section
      className="ArcadeOrionTrail__start"
      textAlign="center">
      <Box className="ArcadeOrionTrail__title" fontSize="24px" bold mb={2}>
        🚀 Тропа Ориона
      </Box>
      <Box color="label" mb={1}>
        Проведите свой экипаж через опасности космоса к Ориону!
      </Box>
      <Divider />
      <Box color="average" mb={1} italic>
        Управляйте ресурсами мудро. Каждое решение важно.
      </Box>
      <Box mb={2}>
        <Box>🍖 Запасайте <b>Еду</b> — экипажу нужно питаться!</Box>
        <Box>⛽ Следите за <b>Топливом</b> — без него вы улетите в звезду.</Box>
        <Box>⚙️ Берите <b>запчасти</b> на случай аварий.</Box>
        <Box>👤 Защищайте <b>экипаж</b> — он ваша опора.</Box>
      </Box>
      <Button
        className="ArcadeOrionTrail__start-btn"
        icon="rocket"
        color="good"
        fontSize="16px"
        onClick={() => act('newgame')}>
        Начать экспедицию
      </Button>
    </Section>
  );
};

// ---- Game Over Screen ----
const GameOverScreen = (props, context) => {
  const { act, data } = useBackend(context);
  const { gameover_reasons = [], emagged } = data;
  return (
    <Section
      className="ArcadeOrionTrail__gameover"
      textAlign="center">
      <Box fontSize="22px" bold color="bad" mb={1}>
        💀 ИГРА ОКОНЧЕНА
      </Box>
      <Divider />
      {gameover_reasons.map((reason, i) => (
        <Box key={i} color="average" italic mb={1} fontSize="14px">
          {reason}
        </Box>
      ))}
      <Divider />
      {!emagged && (
        <Button
          icon="redo"
          color="default"
          onClick={() => act('menu')}>
          Покойся с миром...
        </Button>
      )}
    </Section>
  );
};

// ---- Event Panel ----
const EventPanel = (props, context) => {
  const { data } = useBackend(context);
  const {
    event,
    event_text = [],
    canContinueEvent,
    engine,
    hull,
    electronics,
  } = data;

  if (!event) return null;

  return (
    <Section
      className="ArcadeOrionTrail__event"
      title={'⚠️ ' + event}>
      {event_text.map((line, i) => (
        <Box key={i} mb={0.5} className="ArcadeOrionTrail__event-line">
          {line}
        </Box>
      ))}
      <EventButtons
        event={event}
        canContinueEvent={canContinueEvent}
        engine={engine}
        hull={hull}
        electronics={electronics}
      />
    </Section>
  );
};

// ---- Normal Journey Screen ----
const JourneyScreen = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    food = 0,
    fuel = 0,
    engine = 0,
    hull = 0,
    electronics = 0,
    settlers = [],
    alive = 0,
    turns = 1,
    event,
    stopName = '',
    stopBlurb = '',
    emagged,
  } = data;

  const isBlackHoleTurn = turns === 7;

  return (
    <Stack vertical fill>
      {/* Current stop info */}
      <Stack.Item>
        <Section
          className="ArcadeOrionTrail__stop"
          title={'📍 Ход ' + turns + '/9 — ' + (stopName || 'Глубокий космос')}>
          {stopBlurb && (
            <Box color="label" italic>
              {stopBlurb}
            </Box>
          )}
        </Section>
      </Stack.Item>

      {/* Event panel if active */}
      {event && (
        <Stack.Item>
          <EventPanel />
        </Stack.Item>
      )}

      {/* Resources */}
      <Stack.Item>
        <Section title="📦 Ресурсы">
          <Stack vertical>
            <ResourceBar label="Еда" value={food} max={120} icon="🍖" />
            <ResourceBar label="Топливо" value={fuel} max={100} icon="⛽" />
          </Stack>
          <Box mt={1}>
            <PartsDisplay
              engine={engine}
              hull={hull}
              electronics={electronics}
            />
          </Box>
        </Section>
      </Stack.Item>

      {/* Crew */}
      <Stack.Item>
        <Section title={'👥 Экипаж (' + alive + ')'}>
          <CrewList settlers={settlers} />
        </Section>
      </Stack.Item>

      {/* Action buttons */}
      {!event && (
        <Stack.Item>
          <Stack justify="center">
            {isBlackHoleTurn ? (
              <>
                <Stack.Item>
                  <Button
                    icon="arrow-right"
                    color="danger"
                    onClick={() => act('blackhole')}>
                    🌀 Войти в чёрную дыру
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="undo"
                    color="good"
                    onClick={() => act('pastblack')}>
                    🔄 Обогнуть
                  </Button>
                </Stack.Item>
              </>
            ) : (
              <Stack.Item>
                <Button
                  icon="arrow-right"
                  color="good"
                  onClick={() => act('continue')}>
                  🚀 Продолжить путь
                </Button>
              </Stack.Item>
            )}
            <Stack.Item>
              <Button
                icon="skull"
                color="danger"
                tooltip="Устранить члена экипажа"
                onClick={() => act('killcrew')}>
                🔫 Убить члена экипажа
              </Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      )}
    </Stack>
  );
};

// ---- Spaceport Market Screen ----
const MarketScreen = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    food = 0,
    fuel = 0,
    engine = 0,
    hull = 0,
    electronics = 0,
    settlers = [],
    alive = 0,
    event_text = [],
    spaceport_raided,
    last_spaceport_action,
  } = data;

  return (
    <Stack vertical fill>
      {/* Spaceport header */}
      <Stack.Item>
        <Section title="🏪 Космопорт">
          {event_text.map((line, i) => (
            <Box key={i} mb={0.5} color="label" italic>
              {line}
            </Box>
          ))}
          {last_spaceport_action && (
            <Box mt={1} color="good" bold>
              ✅ {last_spaceport_action}
            </Box>
          )}
        </Section>
      </Stack.Item>

      {/* Resources overview */}
      <Stack.Item>
        <Section title="📦 Ваши запасы">
          <Stack vertical>
            <ResourceBar label="Еда" value={food} max={120} icon="🍖" />
            <ResourceBar label="Топливо" value={fuel} max={100} icon="⛽" />
          </Stack>
          <Box mt={1}>
            <PartsDisplay
              engine={engine}
              hull={hull}
              electronics={electronics}
            />
          </Box>
        </Section>
      </Stack.Item>

      {/* Crew */}
      <Stack.Item>
        <Section title={'👥 Экипаж (' + alive + ')'}>
          <CrewList settlers={settlers} />
        </Section>
      </Stack.Item>

      {/* Shop actions */}
      {!spaceport_raided ? (
        <Stack.Item>
          <Section title="🛒 Торговая площадка">
            <Stack vertical>
              {/* Crew management */}
              <Stack.Item>
                <Box bold mb={0.5}>Управление экипажем</Box>
                <Stack>
                  <Stack.Item>
                    <Button
                      icon="user-plus"
                      disabled={food < 10 || fuel < 10}
                      tooltip="Стоимость: 10 Еды + 10 Топлива"
                      onClick={() => act('buycrew')}>
                      Нанять (10🍖 + 10⛽)
                    </Button>
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      icon="user-minus"
                      color="caution"
                      disabled={settlers.length <= 1}
                      tooltip="Получить: 7 Еды + 7 Топлива"
                      onClick={() => act('sellcrew')}>
                      Продать (+7🍖 +7⛽)
                    </Button>
                  </Stack.Item>
                </Stack>
              </Stack.Item>

              <Stack.Item>
                <Divider />
              </Stack.Item>

              {/* Spare parts */}
              <Stack.Item>
                <Box bold mb={0.5}>Запчасти (5⛽ каждая)</Box>
                <Stack>
                  <Stack.Item>
                    <Button
                      icon="cog"
                      disabled={fuel <= 5}
                      onClick={() => act('buyparts', { type: 1 })}>
                      ⚙️ Двигатель
                    </Button>
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      icon="shield-alt"
                      disabled={fuel <= 5}
                      onClick={() => act('buyparts', { type: 2 })}>
                      🛡️ Корпус
                    </Button>
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      icon="microchip"
                      disabled={fuel <= 5}
                      onClick={() => act('buyparts', { type: 3 })}>
                      💡 Электроника
                    </Button>
                  </Stack.Item>
                </Stack>
              </Stack.Item>

              <Stack.Item>
                <Divider />
              </Stack.Item>

              {/* Trade */}
              <Stack.Item>
                <Box bold mb={0.5}>Обмен (5 на 5)</Box>
                <Stack>
                  <Stack.Item>
                    <Button
                      disabled={fuel <= 5}
                      onClick={() => act('trade', { type: 1 })}>
                      ⛽→🍖 Топливо в еду
                    </Button>
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      disabled={food <= 5}
                      onClick={() => act('trade', { type: 2 })}>
                      🍖→⛽ Еду в топливо
                    </Button>
                  </Stack.Item>
                </Stack>
              </Stack.Item>
            </Stack>
          </Section>
        </Stack.Item>
      ) : (
        <Stack.Item>
          <Section>
            <Box color="bad" bold textAlign="center">
              ⚠️ Космопорт разграблен — торговля больше недоступна.
            </Box>
          </Section>
        </Stack.Item>
      )}

      {/* Bottom actions */}
      <Stack.Item>
        <Stack justify="center">
          {!spaceport_raided && (
            <Stack.Item>
              <Button
                icon="crosshairs"
                color="danger"
                onClick={() => act('raid_spaceport')}>
                ⚔️ Ограбить космопорт
              </Button>
            </Stack.Item>
          )}
          <Stack.Item>
            <Button
              icon="sign-out-alt"
              color="good"
              onClick={() => act('leave_spaceport')}>
              🚀 Depart
            </Button>
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
};

// ---- Main Component ----
export const ArcadeOrionTrail = (props, context) => {
  const { data } = useBackend(context);
  const { gameStatus = STATUS_START, emagged } = data;

  const windowClass = emagged
    ? 'ArcadeOrionTrail ArcadeOrionTrail--emagged'
    : 'ArcadeOrionTrail';

  let content;
  switch (gameStatus) {
    case STATUS_START:
      content = <StartScreen />;
      break;
    case STATUS_NORMAL:
      content = <JourneyScreen />;
      break;
    case STATUS_GAMEOVER:
      content = <GameOverScreen />;
      break;
    case STATUS_MARKET:
      content = <MarketScreen />;
      break;
    default:
      content = <StartScreen />;
  }

  return (
    <Window
      title="Тропа Ориона"
      width={540}
      height={640}>
      <Window.Content className={windowClass} scrollable>
        {content}
      </Window.Content>
    </Window>
  );
};

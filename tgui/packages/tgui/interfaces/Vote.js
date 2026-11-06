import { useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Collapsible, Icon, Input, LabeledList, NoticeBox, ProgressBar, Section, Stack } from '../components';
import { Window } from '../layouts';

const MODE_META = {
  restart: { icon: 'sync-alt', color: 'red', label: 'Рестарт' },
  gamemode: { icon: 'dice', color: 'blue', label: 'Режим игры' },
  roundtype: { icon: 'dice', color: 'blue', label: 'Режим игры' },
  map: { icon: 'map', color: 'green', label: 'Карта' },
  transfer: { icon: 'space-shuttle', color: 'orange', label: 'Окончание раунда' },
  custom: { icon: 'vote-yea', color: 'purple', label: 'Кастомное' },
};

const SYSTEM_HINTS = {
  PLURALITY: 'Выберите один вариант, голос можно поменять.',
  APPROVAL: 'Можно выбрать несколько вариантов.',
  SCHULZE: 'Нажимайте варианты по порядку предпочтения, повторное нажатие убирает из рейтинга.',
  IRV: 'Нажимайте варианты по порядку предпочтения, повторное нажатие убирает из рейтинга.',
  SCORE: 'Оцените каждый вариант.',
  HIGHEST_MEDIAN: 'Оцените каждый вариант, побеждает лучшая медиана оценок.',
};

// Служебные английские варианты голосований сервера
const CHOICE_LABELS = {
  'Restart Round': 'Перезапустить раунд',
  'Continue Playing': 'Продолжить игру',
  'Initiate Crew Transfer': 'Закончить смену',
};

const choiceLabel = (name) => CHOICE_LABELS[name] || name;

const formatTime = (seconds) => {
  const total = Math.max(0, seconds || 0);
  const minutes = Math.floor(total / 60);
  const rest = String(total % 60).padStart(2, '0');
  return `${minutes}:${rest}`;
};

const pluralVoters = (count) => {
  const mod10 = count % 10;
  const mod100 = count % 100;
  if (mod10 === 1 && mod100 !== 11) {
    return 'игрок';
  }
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) {
    return 'игрока';
  }
  return 'игроков';
};

export const Vote = (props) => {
  const { data } = useBackend();
  const { mode, question, lower_admin, custom_setup, allow_vote_restart, allow_vote_mode } = data;

  const meta = MODE_META[mode] || MODE_META.custom;
  const title = mode ? (question || meta.label) : 'Голосование';
  // Во время голосования новое не начать: игроку блок не нужен, админу остаются тумблеры
  const canManage = mode ? !!data.upper_admin : (lower_admin || allow_vote_restart || allow_vote_mode);

  return (
    <Window resizable title={title} width={460} height={650}>
      <Window.Content>
        <Stack fill vertical>
          {!!canManage && (
            <Stack.Item>
              <VoteOptions />
            </Stack.Item>
          )}
          {!!(lower_admin && custom_setup && custom_setup.active) && (
            <Stack.Item>
              <CustomVoteSetup />
            </Stack.Item>
          )}
          <Stack.Item grow>
            <ChoicesPanel />
          </Stack.Item>
          {!!mode && (
            <Stack.Item>
              <TimePanel />
            </Stack.Item>
          )}
        </Stack>
      </Window.Content>
    </Window>
  );
};

const StartButton = (props) => {
  const { label, icon, color, action, disabled, tooltip } = props;
  const { act } = useBackend();
  return (
    <Button
      fluid
      icon={icon}
      color={color}
      disabled={disabled}
      tooltip={tooltip}
      tooltipPosition="bottom"
      textAlign="center"
      onClick={() => act(action)}>
      {label}
    </Button>
  );
};

const VoteOptions = (props) => {
  const { act, data } = useBackend();
  const { mode, allow_vote_restart, allow_vote_mode, lower_admin, upper_admin, roundtype_vote_block, vote_start_block } = data;

  const modeDisabled = !!vote_start_block || !!roundtype_vote_block || (!allow_vote_mode && !lower_admin);
  const modeTooltip = vote_start_block || roundtype_vote_block
    || (!allow_vote_mode && !lower_admin ? 'Администрация не открыла это голосование игрокам.' : null);
  const restartDisabled = !!vote_start_block || (!allow_vote_restart && !lower_admin);
  const restartTooltip = vote_start_block
    || (!allow_vote_restart && !lower_admin ? 'Администрация не открыла это голосование игрокам.' : null);

  const toggles = !!upper_admin && (
    <Stack mt={mode ? 0 : 0.75} align="center">
      <Stack.Item color="label">
        <Icon name="user-check" mr={0.5} />
        Игрокам доступно:
      </Stack.Item>
      <Stack.Item>
        <Button.Checkbox compact checked={!!allow_vote_mode} onClick={() => act('toggle_gamemode')}>
          Режим игры
        </Button.Checkbox>
      </Stack.Item>
      <Stack.Item>
        <Button.Checkbox compact checked={!!allow_vote_restart} onClick={() => act('toggle_restart')}>
          Рестарт
        </Button.Checkbox>
      </Stack.Item>
    </Stack>
  );

  if (mode) {
    return <Section>{toggles}</Section>;
  }

  return (
    <Section title="Начать голосование">
      <Stack>
        <Stack.Item grow basis={0}>
          <StartButton label="Режим игры" icon="dice" color="blue" action="gamemode"
            disabled={modeDisabled} tooltip={modeTooltip} />
        </Stack.Item>
        <Stack.Item grow basis={0}>
          <StartButton label="Рестарт" icon="sync-alt" color="red" action="restart"
            disabled={restartDisabled} tooltip={restartTooltip} />
        </Stack.Item>
      </Stack>
      {!!lower_admin && (
        <Stack mt={0.5}>
          <Stack.Item grow basis={0}>
            <StartButton label="Карта" icon="map" color="green" action="map"
              disabled={!!vote_start_block} tooltip={vote_start_block} />
          </Stack.Item>
          <Stack.Item grow basis={0}>
            <StartButton label="Кастомное" icon="vote-yea" color="purple" action="custom" />
          </Stack.Item>
        </Stack>
      )}
      {toggles}
    </Section>
  );
};

const CustomVoteSetup = (props) => {
  const { act, data } = useBackend();
  const { custom_setup, vote_type_options = [], all_display_settings = [] } = data;
  const [newOpt, setNewOpt] = useState('');

  const cs = custom_setup || {};
  const optCount = cs.options ? cs.options.length : 0;
  const canConfirm = cs.question && cs.question.length > 0 && optCount >= 2;

  const handleAddOption = () => {
    const trimmed = newOpt.trim();
    if (trimmed) {
      act('custom_add_option', { option: trimmed });
      setNewOpt('');
    }
  };

  const typeLabels = {
    PLURALITY: 'Один вариант',
    APPROVAL: 'Несколько',
    IRV: 'Ранжирование (IRV)',
    SCHULZE: 'Ранжирование (Шульце)',
    SCORE: 'Оценки',
    HIGHEST_MEDIAN: 'Медиана',
  };

  return (
    <Section
      title="Настройка голосования"
      buttons={
        <Button color="red" icon="times" onClick={() => act('custom_abort')}>
          Отмена
        </Button>
      }>
      <Stack vertical spacing={1.5}>
        <Stack.Item>
          <LabeledList>
            <LabeledList.Item label="Имя">
              <Input
                fluid
                placeholder="Название голосования..."
                value={cs.question || ''}
                onInput={(e, val) =>
                  act('custom_set_question', { question: val.trim() })
                }
              />
            </LabeledList.Item>
            <LabeledList.Item label="Тип">
              <Stack wrap>
                {vote_type_options.map((opt) => (
                  <Stack.Item key={opt.value}>
                    <Button
                      compact
                      selected={cs.vote_type === opt.value}
                      onClick={() => act('custom_set_type', { type: opt.value })}>
                      {typeLabels[opt.value] || opt.label}
                    </Button>
                  </Stack.Item>
                ))}
              </Stack>
            </LabeledList.Item>
            <LabeledList.Item label={`Варианты (${optCount}/10)`}>
              <Stack vertical spacing={0.3}>
                {(cs.options || []).map((opt, i) => (
                  <Stack.Item key={i}>
                    <Stack align="center">
                      <Stack.Item>
                        <Box color="label" minWidth="1.2em" textAlign="right">
                          {i + 1}.
                        </Box>
                      </Stack.Item>
                      <Stack.Item grow>
                        {opt}
                      </Stack.Item>
                      <Stack.Item>
                        <Button
                          compact
                          color="transparent"
                          icon="times"
                          tooltip="Удалить"
                          onClick={() => act('custom_remove_option', { index: i + 1 })}
                        />
                      </Stack.Item>
                    </Stack>
                  </Stack.Item>
                ))}
                {optCount < 10 && (
                  <Stack.Item mt={optCount > 0 ? 0.5 : 0}>
                    <Stack>
                      <Stack.Item grow>
                        <Input
                          fluid
                          placeholder="Новый вариант..."
                          value={newOpt}
                          onInput={(e, val) => setNewOpt(val)}
                          onEnter={() => handleAddOption()}
                        />
                      </Stack.Item>
                      <Stack.Item>
                        <Button
                          icon="plus"
                          disabled={!newOpt.trim()}
                          onClick={() => handleAddOption()}>
                          Добавить
                        </Button>
                      </Stack.Item>
                    </Stack>
                  </Stack.Item>
                )}
              </Stack>
            </LabeledList.Item>
            <LabeledList.Item label="Показывать">
              <Stack wrap>
                {all_display_settings.map((ds) => (
                  <Stack.Item key={ds.flag}>
                    <Button.Checkbox
                      compact
                      checked={!!(cs.display_flags & ds.flag)}
                      onClick={() => act('custom_toggle_display', { flag: ds.flag })}>
                      {ds.name}
                    </Button.Checkbox>
                  </Stack.Item>
                ))}
              </Stack>
            </LabeledList.Item>
          </LabeledList>
        </Stack.Item>
        <Stack.Item>
          <Button
            fluid
            color={canConfirm ? 'green' : 'grey'}
            icon={canConfirm ? 'play' : 'exclamation-circle'}
            disabled={!canConfirm}
            onClick={() => act('custom_confirm')}>
            {canConfirm
              ? 'Начать голосование'
              : 'Заполните вопрос и минимум 2 варианта'}
          </Button>
        </Stack.Item>
      </Stack>
    </Section>
  );
};


const InfoLine = (props) => {
  const { icon, color = 'label', children } = props;
  return (
    <Stack mb={0.5} color={color} fontSize="0.9em">
      <Stack.Item width="1.2em" textAlign="center">
        <Icon name={icon} />
      </Stack.Item>
      <Stack.Item grow>{children}</Stack.Item>
    </Stack>
  );
};

const ChoicesPanel = (props) => {
  const { act, data } = useBackend();
  const {
    choices = [],
    vote_system,
    score_options = [],
    last_modes,
    combo_threshold,
    rotation_min_players,
    rotation_night_start,
    rotation_night_end,
    rotation_applies,
    mode,
    roundtype_descs,
    vote_start_block,
  } = data;

  if (!mode) {
    return (
      <Section fill title="Голосование">
        <Stack fill vertical align="center" justify="center" textAlign="center">
          <Stack.Item>
            <Icon name="vote-yea" size={3} color="label" />
          </Stack.Item>
          <Stack.Item mt={1} color="label">
            Сейчас голосования нет.
          </Stack.Item>
          {!!vote_start_block && (
            <Stack.Item mt={0.5} color="average" fontSize="0.9em">
              <Icon name="clock" mr={0.5} />
              {vote_start_block}
            </Stack.Item>
          )}
        </Stack>
      </Section>
    );
  }

  const meta = MODE_META[mode] || MODE_META.custom;
  const isRanked = vote_system === 'SCHULZE' || vote_system === 'IRV';
  const isScore = vote_system === 'SCORE' || vote_system === 'HIGHEST_MEDIAN';
  const voted = choices.some((c) => c.user_selected || c.user_approved || c.user_rank > 0);
  const totalVotes = choices.reduce((sum, c) => (c.votes > 0 ? sum + c.votes : sum), 0);
  const leaderVotes = Math.max(0, ...choices.map((c) => c.votes));

  let headerButton = null;
  if (voted && (vote_system === 'PLURALITY' || vote_system === 'APPROVAL')) {
    headerButton = (
      <Button compact icon="undo" color="transparent" onClick={() => act('vote_reset')}>
        Отозвать голос
      </Button>
    );
  } else if (voted && isRanked) {
    headerButton = (
      <Button compact icon="undo" color="transparent" onClick={() => act('vote_reset')}>
        Сбросить рейтинг
      </Button>
    );
  }

  return (
    <Section
      fill
      scrollable
      title={
        <Box inline>
          <Icon name={meta.icon} mr={0.75} color={meta.color} />
          {meta.label}
        </Box>
      }
      buttons={headerButton}>
      {!!SYSTEM_HINTS[vote_system] && (
        <InfoLine icon="info-circle">{SYSTEM_HINTS[vote_system]}</InfoLine>
      )}
      {!!last_modes && (
        <InfoLine icon="history">
          Последние режимы: <b>{last_modes}</b>
        </InfoLine>
      )}
      {mode === 'roundtype' && !!combo_threshold && (
        <InfoLine
          icon={rotation_applies ? 'check-circle' : 'moon'}
          color={rotation_applies ? 'good' : 'average'}>
          {rotation_applies
            ? `Раунд засчитается в ротацию: при ${combo_threshold} одинаковых режимах подряд следующий будет другим.`
            : `Раунд не засчитается в ротацию: онлайн ниже ${rotation_min_players} или ночь (${rotation_night_start}:00–${rotation_night_end}:00 МСК).`}
        </InfoLine>
      )}
      {!!(roundtype_descs && roundtype_descs.length) && (
        <Collapsible title="Описание режимов" mb={0.5}>
          {roundtype_descs.map((rd) => (
            <Box key={rd.name} mb={0.5} fontSize="0.9em">
              <Box inline bold>{rd.name}:</Box>{' '}{rd.desc}
            </Box>
          ))}
        </Collapsible>
      )}
      <Box mt={1}>
        {choices.length === 0 && <NoticeBox info>Нет вариантов.</NoticeBox>}
        {isRanked && <RankedChoices choices={choices} />}
        {isScore && <ScoreChoices choices={choices} score_options={score_options} />}
        {!isRanked && !isScore && choices.map((choice) => (
          <ChoiceRow
            key={choice.id}
            choice={choice}
            multi={vote_system === 'APPROVAL'}
            totalVotes={totalVotes}
            leaderVotes={leaderVotes}
          />
        ))}
      </Box>
    </Section>
  );
};

// Строка варианта: длинный текст переносится, голоса остаются справа
const ChoiceButton = (props) => {
  const { selected, lead, leadWidth = '1.6em', side, fill, fillColor, tooltip, onClick, children } = props;
  return (
    <Button
      fluid
      fontSize="1.2em"
      px={0.75}
      py={0.4}
      selected={selected}
      tooltip={tooltip}
      style={{ whiteSpace: 'normal', position: 'relative', overflow: 'hidden' }}
      onClick={onClick}>
      {fill > 0 && (
        <Box
          style={{
            position: 'absolute',
            left: 0,
            bottom: 0,
            height: '3px',
            width: `${fill}%`,
            background: fillColor,
            pointerEvents: 'none',
          }}
        />
      )}
      <Stack align="center" style={{ position: 'relative' }}>
        <Stack.Item width={leadWidth} textAlign="center" style={{ flexShrink: 0 }}>
          {lead}
        </Stack.Item>
        <Stack.Item grow basis={0} lineHeight={1.35} style={{ wordBreak: 'break-word' }}>
          {children}
        </Stack.Item>
        {!!side && (
          <Stack.Item style={{ whiteSpace: 'nowrap' }}>
            {side}
          </Stack.Item>
        )}
      </Stack>
    </Button>
  );
};

const ChoiceRow = (props) => {
  const { choice, multi, totalVotes, leaderVotes } = props;
  const { act } = useBackend();
  const mine = multi ? !!choice.user_approved : !!choice.user_selected;
  const hidden = choice.votes === -1;
  const percent = !hidden && totalVotes ? Math.round((choice.votes / totalVotes) * 100) : 0;
  const isLeader = !hidden && choice.votes > 0 && choice.votes === leaderVotes;
  let icon = mine ? 'dot-circle-o' : 'circle-o';
  if (multi) {
    icon = mine ? 'check-square-o' : 'square-o';
  }

  const side = hidden ? (
    <Box opacity={0.6}>
      <Icon name="eye-slash" mr={0.5} />
      скрыто
    </Box>
  ) : (
    <Box>
      {isLeader && <Icon name="crown" color="yellow" mr={0.5} />}
      {choice.votes}
      <Box inline opacity={0.6} ml={0.5} minWidth="2.6em" textAlign="right">{percent}%</Box>
    </Box>
  );

  return (
    <Box mb={0.5}>
      <ChoiceButton
        selected={mine}
        lead={<Icon name={icon} />}
        side={side}
        fill={percent}
        fillColor={mine ? '#b6f08c' : isLeader ? '#7fc4ff' : 'rgba(255, 255, 255, 0.45)'}
        tooltip={mine && !multi ? 'Ваш голос' : null}
        onClick={() => act('vote', { index: choice.id })}>
        <Box bold={mine}>{choiceLabel(choice.name)}</Box>
      </ChoiceButton>
    </Box>
  );
};

const RankedChoices = (props) => {
  const { choices } = props;
  const { act } = useBackend();
  const ranked = choices.filter((c) => c.user_rank > 0).sort((a, b) => a.user_rank - b.user_rank);
  const unranked = choices.filter((c) => !c.user_rank);

  return (
    <>
      {[...ranked, ...unranked].map((choice) => (
        <Box key={choice.id} mb={0.5}>
          <ChoiceButton
            selected={choice.user_rank > 0}
            leadWidth="2.2em"
            lead={choice.user_rank > 0
              ? <Box bold>№{choice.user_rank}</Box>
              : <Icon name="plus" opacity={0.5} />}
            side={choice.votes !== -1 && <Box opacity={0.6}>{choice.votes} бал.</Box>}
            tooltip={choice.user_rank > 0 ? 'Убрать из рейтинга' : 'Добавить в рейтинг'}
            onClick={() => act('vote', { index: choice.id })}>
            {choiceLabel(choice.name)}
          </ChoiceButton>
        </Box>
      ))}
    </>
  );
};

const ScoreChoices = (props) => {
  const { choices, score_options } = props;
  const { act } = useBackend();

  return (
    <>
      {choices.map((choice) => {
        const rated = choice.user_score !== null && choice.user_score !== undefined;
        return (
          <Box
            key={choice.id}
            mb={1}
            px={0.75}
            py={0.6}
            style={{
              background: 'rgba(255, 255, 255, 0.04)',
              borderLeft: `3px solid ${rated ? '#5baa27' : 'rgba(255, 255, 255, 0.15)'}`,
              borderRadius: '2px',
            }}>
            <Stack align="flex-start" mb={0.6}>
              <Stack.Item grow basis={0} fontSize="1.15em" lineHeight={1.35} style={{ wordBreak: 'break-word' }}>
                {choiceLabel(choice.name)}
              </Stack.Item>
              <Stack.Item>
                <Icon
                  name={rated ? 'check-circle' : 'circle-o'}
                  color={rated ? 'good' : 'label'}
                  mt={0.25}
                />
              </Stack.Item>
            </Stack>
            <Stack>
              {score_options.map((opt) => (
                <Stack.Item key={opt.value} grow basis={0}>
                  <Button
                    fluid
                    lineHeight={1.8}
                    textAlign="center"
                    selected={choice.user_score === opt.value}
                    onClick={() => act('vote', { index: choice.id, score: opt.value })}>
                    {opt.label}
                  </Button>
                </Stack.Item>
              ))}
            </Stack>
          </Box>
        );
      })}
    </>
  );
};

const TimePanel = (props) => {
  const { act, data } = useBackend();
  const { lower_admin, time_remaining = 0, time_total = 0, initiator, voters_count = 0 } = data;
  const ending = time_remaining <= 30;

  return (
    <Section>
      <Stack align="center">
        <Stack.Item>
          <Box fontSize={1.6} bold color={ending ? 'average' : null}>
            <Icon name="hourglass-half" mr={0.75} color={ending ? 'average' : 'label'} />
            {formatTime(time_remaining)}
          </Box>
        </Stack.Item>
        <Stack.Item grow textAlign="right" color="label" fontSize="0.9em">
          {!!initiator && (
            <Box>
              <Icon name="user" mr={0.5} />
              {initiator}
            </Box>
          )}
          <Box>
            <Icon name="users" mr={0.5} />
            {voters_count} {pluralVoters(voters_count)}
          </Box>
        </Stack.Item>
        {!!lower_admin && (
          <Stack.Item>
            <Button color="red" icon="ban" tooltip="Отменить голосование" onClick={() => act('cancel')} />
          </Stack.Item>
        )}
      </Stack>
      {time_total > 0 && (
        <ProgressBar
          mt={0.5}
          height="0.4em"
          value={time_remaining / time_total}
          color={ending ? 'average' : 'blue'}>
          {' '}
        </ProgressBar>
      )}
    </Section>
  );
};

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

const BAR_RANGES = {
  red: [0, 0.34],
  orange: [0.34, 0.67],
  good: [0.67, 1],
};

export const Vote = (props) => {
  const { data } = useBackend();
  const { mode, question, lower_admin, custom_setup, allow_vote_restart, allow_vote_mode } = data;

  const meta = MODE_META[mode] || MODE_META.custom;
  const title = mode ? (question || meta.label) : 'Голосование';
  const canManage = lower_admin || allow_vote_restart || allow_vote_mode;

  return (
    <Window resizable title={title} width={460} height={650}>
      <Window.Content scrollable>
        <Stack fill vertical>
          {!!canManage && (
            <Stack.Item>
              <Section title="Управление голосованием">
                <VoteOptions />
              </Section>
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
          {!!mode && <TimePanel />}
        </Stack>
      </Window.Content>
    </Window>
  );
};

const VoteOptions = (props) => {
  const { act, data } = useBackend();
  const { allow_vote_restart, allow_vote_mode, lower_admin, upper_admin } = data;

  const startButton = (label, icon, color, onClick, disabled) => (
    <Button
      fluid
      icon={icon}
      color={color}
      disabled={disabled}
      onClick={onClick}>
      {label}
    </Button>
  );

  return (
    <Stack wrap spacing={1}>
      <Stack.Item basis="47%" grow>
        <Stack vertical spacing={0.5}>
          <Stack.Item>
            {startButton(
              'Режим игры',
              'dice',
              'blue',
              () => act('gamemode'),
              !allow_vote_mode && !lower_admin
            )}
          </Stack.Item>
          <Stack.Item>
            {startButton(
              'Рестарт',
              'sync-alt',
              'red',
              () => act('restart'),
              !allow_vote_restart && !lower_admin
            )}
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Item basis="47%" grow>
        <Stack vertical spacing={0.5}>
          {!!lower_admin && (
            <Stack.Item>
              {startButton('Карта', 'map', 'green', () => act('map'))}
            </Stack.Item>
          )}
          {!!lower_admin && (
            <Stack.Item>
              {startButton('Кастомное', 'vote-yea', 'purple', () => act('custom'))}
            </Stack.Item>
          )}
        </Stack>
      </Stack.Item>
      {!!upper_admin && (
        <Stack.Item mt={0.5}>
          <Stack spacing={1}>
            <Button.Checkbox
              checked={!!allow_vote_mode}
              color="red"
              onClick={() => act('toggle_gamemode')}>
              Режим игры
            </Button.Checkbox>
            <Button.Checkbox
              checked={!!allow_vote_restart}
              color="red"
              onClick={() => act('toggle_restart')}>
              Рестарт
            </Button.Checkbox>
          </Stack>
        </Stack.Item>
      )}
    </Stack>
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

const ChoicesPanel = (props) => {
  const { act, data } = useBackend();
  const { choices = [], vote_system, score_options = [], last_modes, combo_threshold, mode, roundtype_descs } = data;

  if (!mode) {
    return (
      <Section fill title="Варианты">
        <NoticeBox info>Нет активного голосования.</NoticeBox>
      </Section>
    );
  }

  const meta = MODE_META[mode] || MODE_META.custom;
  const systemHints = {
    APPROVAL: 'Можно выбрать несколько вариантов.',
    SCHULZE: 'Нажмите чтобы добавить в рейтинг. Повторное нажатие — убрать.',
    IRV: 'Нажмите чтобы добавить в рейтинг. Повторное нажатие — убрать.',
    SCORE: 'Оцените каждый вариант.',
    HIGHEST_MEDIAN: 'Оцените каждый вариант (медиана оценок).',
  };

  const isRanked = vote_system === 'SCHULZE' || vote_system === 'IRV';
  const totalVotes = choices.reduce((sum, choice) => (
    choice.votes !== -1 ? sum + choice.votes : sum
  ), 0);

  return (
    <Section
      fill
      scrollable
      title={
        <Box inline>
          <Icon name={meta.icon} mr={0.5} color={meta.color} />
          {meta.label}
        </Box>
      }>
      {!!(last_modes) && (
        <Box mb={1} color="label" fontSize="0.85em">
          Последние режимы: <b>{last_modes}</b>
          {!!(combo_threshold) && ` (форс при ${combo_threshold} подряд)`}
        </Box>
      )}
      {!!(roundtype_descs && roundtype_descs.length) && (
        <Collapsible title="Описание режимов" mb={1}>
          {roundtype_descs.map((rd) => (
            <Box key={rd.name} mb={0.5}>
              <Box inline bold>{rd.name}:</Box>{' '}{rd.desc}
            </Box>
          ))}
        </Collapsible>
      )}
      {!!(systemHints[vote_system]) && (
        <Box mb={1} color="average" italic>{systemHints[vote_system]}</Box>
      )}
      {choices.length === 0 ? (
        <NoticeBox info>Нет вариантов.</NoticeBox>
      ) : (
        <ChoicesList
          choices={choices}
          vote_system={vote_system}
          score_options={score_options}
          totalVotes={totalVotes}
          act={act}
        />
      )}
      {isRanked && (
        <Box mt={1}>
          <Button compact color="red" icon="undo" onClick={() => act('vote_reset')}>
            Сбросить рейтинг
          </Button>
        </Box>
      )}
    </Section>
  );
};

const ChoicesList = (props) => {
  const { choices, vote_system, score_options, totalVotes, act } = props;

  if (vote_system === 'APPROVAL') {
    return (
      <Stack vertical spacing={0.5}>
        {choices.map((choice) => (
          <Stack.Item key={choice.id}>
            <Button.Checkbox
              fluid
              checked={!!choice.user_approved}
              onClick={() => act('vote', { index: choice.id })}>
              {choice.name}
              {choice.votes !== -1 && (
                <Box inline ml={1} color="label">({choice.votes})</Box>
              )}
            </Button.Checkbox>
            <VoteBar choice={choice} totalVotes={totalVotes} />
          </Stack.Item>
        ))}
      </Stack>
    );
  }

  if (vote_system === 'SCHULZE' || vote_system === 'IRV') {
    const ranked = choices.filter((c) => c.user_rank > 0).sort((a, b) => a.user_rank - b.user_rank);
    const unranked = choices.filter((c) => !c.user_rank);
    return (
      <LabeledList>
        {ranked.map((choice) => (
          <LabeledList.Item
            key={choice.id}
            label={
              <Box inline bold color="good">
                <Icon name="arrow-up" mr={0.5} />
                {choice.name}
              </Box>
            }
            buttons={
              <Button compact color="red" onClick={() => act('vote', { index: choice.id })}>
                − Убрать
              </Button>
            }>
            <Box color="good">№{choice.user_rank}</Box>
          </LabeledList.Item>
        ))}
        {ranked.length > 0 && unranked.length > 0 && <LabeledList.Divider />}
        {unranked.map((choice) => (
          <LabeledList.Item
            key={choice.id}
            label={choice.name}
            buttons={
              <Button compact onClick={() => act('vote', { index: choice.id })}>
                + В рейтинг
              </Button>
            }>
            {choice.votes !== -1 ? `${choice.votes} бал.` : ''}
          </LabeledList.Item>
        ))}
      </LabeledList>
    );
  }

  if (vote_system === 'SCORE' || vote_system === 'HIGHEST_MEDIAN') {
    return (
      <LabeledList>
        {choices.map((choice) => (
          <LabeledList.Item key={choice.id} label={choice.name}>
            <Stack wrap>
              {score_options.map((opt) => (
                <Stack.Item key={opt.value}>
                  <Button
                    compact
                    selected={choice.user_score === opt.value}
                    onClick={() => act('vote', { index: choice.id, score: opt.value })}>
                    {opt.label}
                  </Button>
                </Stack.Item>
              ))}
            </Stack>
          </LabeledList.Item>
        ))}
      </LabeledList>
    );
  }

  return (
    <Stack vertical spacing={0.8}>
      {choices.map((choice) => (
        <Stack.Item key={choice.id}>
          <Stack align="center" spacing={1}>
            <Stack.Item grow>
              <Box bold>
                {choice.name}
                {!!choice.user_selected && (
                  <Icon name="check" ml={0.5} color="good" />
                )}
              </Box>
            </Stack.Item>
            <Stack.Item>
              <Box color={choice.user_selected ? 'good' : 'label'}>
                {choice.votes === -1 ? '???' : `${choice.votes} гол.`}
              </Box>
            </Stack.Item>
            <Stack.Item>
              <Button
                disabled={!!choice.user_selected}
                color={choice.user_selected ? 'good' : 'default'}
                icon={choice.user_selected ? 'check' : 'vote-yea'}
                onClick={() => act('vote', { index: choice.id })}>
                {choice.user_selected ? 'Выбрано' : 'Голосовать'}
              </Button>
            </Stack.Item>
          </Stack>
          <VoteBar choice={choice} totalVotes={totalVotes} />
        </Stack.Item>
      ))}
    </Stack>
  );
};

const VoteBar = ({ choice, totalVotes }) => {
  if (choice.votes === -1 || !totalVotes) {
    return null;
  }
  const percent = Math.round((choice.votes / totalVotes) * 100);
  return (
    <ProgressBar
      value={percent / 100}
      ranges={BAR_RANGES}
      mt={0.2}
      mb={0.2}>
      {percent}%
    </ProgressBar>
  );
};

const TimePanel = (props) => {
  const { act, data } = useBackend();
  const { lower_admin, time_remaining } = data;

  return (
    <Stack.Item mt={0.5}>
      <Section>
        <Stack align="center" justify="space-between">
          <Stack.Item>
            <Box fontSize={1.5} bold>
              <Icon name="hourglass-half" mr={1} color="label" />
              {time_remaining || 0}с
            </Box>
          </Stack.Item>
          {!!lower_admin && (
            <Stack.Item>
              <Button color="red" icon="ban" onClick={() => act('cancel')}>
                Отменить
              </Button>
            </Stack.Item>
          )}
        </Stack>
      </Section>
    </Stack.Item>
  );
};

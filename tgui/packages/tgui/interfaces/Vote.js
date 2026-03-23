import { useBackend, useLocalState } from '../backend';
import { Box, Button, Collapsible, Icon, Input, LabeledList, NoticeBox, Section, Stack } from '../components';
import { Window } from '../layouts';

export const Vote = (props, context) => {
  const { data } = useBackend(context);
  const { mode, question, lower_admin, upper_admin, custom_setup, allow_vote_restart, allow_vote_mode } = data;

  let windowTitle = 'Голосование';
  if (mode) {
    windowTitle += ': ' + (question || mode).replace(/^\w/, (c) => c.toUpperCase());
  }

  const canManage = lower_admin || allow_vote_restart || allow_vote_mode;

  return (
    <Window resizable title={windowTitle} width={440} height={620}>
      <Window.Content scrollable>
        <Stack fill vertical>
          {!!canManage && (
            <Section title="Управление голосованием">
              <VoteOptions />
            </Section>
          )}
          {!!(lower_admin && custom_setup && custom_setup.active) && <CustomVoteSetup />}
          <ChoicesPanel />
          {!!mode && <TimePanel />}
        </Stack>
      </Window.Content>
    </Window>
  );
};

const VoteOptions = (props, context) => {
  const { act, data } = useBackend(context);
  const { allow_vote_restart, allow_vote_mode, lower_admin, upper_admin } = data;

  return (
    <Stack.Item>
      <Collapsible title="Начать голосование">
        <LabeledList>
          <LabeledList.Item
            label="Режим игры"
            buttons={
              !!upper_admin && (
                <Button.Checkbox
                  checked={!!allow_vote_mode}
                  color="red"
                  onClick={() => act('toggle_gamemode')}>
                  {allow_vote_mode ? 'Вкл' : 'Выкл'}
                </Button.Checkbox>
              )
            }>
            <Button
              disabled={!allow_vote_mode && !lower_admin}
              onClick={() => act('gamemode')}>
              Начать
            </Button>
          </LabeledList.Item>
          <LabeledList.Item
            label="Рестарт"
            buttons={
              !!upper_admin && (
                <Button.Checkbox
                  checked={!!allow_vote_restart}
                  color="red"
                  onClick={() => act('toggle_restart')}>
                  {allow_vote_restart ? 'Вкл' : 'Выкл'}
                </Button.Checkbox>
              )
            }>
            <Button
              disabled={!allow_vote_restart && !lower_admin}
              onClick={() => act('restart')}>
              Начать
            </Button>
          </LabeledList.Item>
          {!!lower_admin && (
            <LabeledList.Item label="Карта">
              <Button onClick={() => act('map')}>Начать</Button>
            </LabeledList.Item>
          )}
          {!!lower_admin && (
            <LabeledList.Item label="Кастомное">
              <Button icon="sliders-h" onClick={() => act('custom')}>
                Настроить...
              </Button>
            </LabeledList.Item>
          )}
        </LabeledList>
      </Collapsible>
    </Stack.Item>
  );
};

const CustomVoteSetup = (props, context) => {
  const { act, data } = useBackend(context);
  const { custom_setup, vote_type_options = [], all_display_settings = [] } = data;
  const [newOpt, setNewOpt] = useLocalState(context, 'cs_opt', '');

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
    <Stack.Item>
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
    </Stack.Item>
  );
};

const ChoicesPanel = (props, context) => {
  const { act, data } = useBackend(context);
  const { choices = [], vote_system, score_options = [], last_modes, combo_threshold, mode, roundtype_descs } = data;

  if (!mode) {
    return (
      <Stack.Item grow>
        <Section fill title="Варианты">
          <NoticeBox>Нет активного голосования.</NoticeBox>
        </Section>
      </Stack.Item>
    );
  }

  const systemHints = {
    APPROVAL: 'Можно выбрать несколько вариантов.',
    SCHULZE: 'Нажмите чтобы добавить в рейтинг. Повторное нажатие — убрать.',
    IRV: 'Нажмите чтобы добавить в рейтинг. Повторное нажатие — убрать.',
    SCORE: 'Оцените каждый вариант.',
    HIGHEST_MEDIAN: 'Оцените каждый вариант (медиана оценок).',
  };

  const isRanked = vote_system === 'SCHULZE' || vote_system === 'IRV';

  return (
    <Stack.Item grow>
      <Section fill scrollable title="Варианты">
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
          <NoticeBox>Нет вариантов.</NoticeBox>
        ) : (
          <ChoicesList choices={choices} vote_system={vote_system} score_options={score_options} act={act} />
        )}
        {isRanked && (
          <Box mt={1}>
            <Button compact color="red" onClick={() => act('vote_reset')}>
              Сбросить рейтинг
            </Button>
          </Box>
        )}
      </Section>
    </Stack.Item>
  );
};

const ChoicesList = (props) => {
  const { choices, vote_system, score_options, act } = props;

  if (vote_system === 'APPROVAL') {
    return choices.map((choice) => (
      <Box key={choice.id} mb={0.5}>
        <Button.Checkbox
          fluid
          checked={!!choice.user_approved}
          onClick={() => act('vote', { index: choice.id })}>
          {choice.name}
          {choice.votes !== -1 && (
            <Box inline ml={1} color="label">({choice.votes})</Box>
          )}
        </Button.Checkbox>
      </Box>
    ));
  }

  if (vote_system === 'SCHULZE' || vote_system === 'IRV') {
    const ranked = choices.filter((c) => c.user_rank > 0).sort((a, b) => a.user_rank - b.user_rank);
    const unranked = choices.filter((c) => !c.user_rank);
    return (
      <LabeledList>
        {ranked.map((choice) => (
          <LabeledList.Item
            key={choice.id}
            label={choice.name}
            color="good"
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

  // По умолчанию: PLURALITY
  return (
    <LabeledList>
      {choices.map((choice) => (
        <Box key={choice.id}>
          <LabeledList.Item
            label={choice.name}
            textAlign="right"
            buttons={
              <Button
                disabled={!!choice.user_selected}
                color={choice.user_selected ? 'good' : 'default'}
                onClick={() => act('vote', { index: choice.id })}>
                {choice.user_selected ? (
                  <Box inline><Icon name="check" mr={1} />Выбрано</Box>
                ) : 'Голосовать'}
              </Button>
            }>
            {choice.votes === -1 ? '???' : `${choice.votes} гол.`}
          </LabeledList.Item>
          <LabeledList.Divider />
        </Box>
      ))}
    </LabeledList>
  );
};

const TimePanel = (props, context) => {
  const { act, data } = useBackend(context);
  const { lower_admin, time_remaining } = data;

  return (
    <Stack.Item mt={1}>
      <Section>
        <Stack justify="space-between">
          <Box fontSize={1.5}>Осталось: {time_remaining || 0}с</Box>
          {!!lower_admin && (
            <Button color="red" onClick={() => act('cancel')}>
              Отменить
            </Button>
          )}
        </Stack>
      </Section>
    </Stack.Item>
  );
};

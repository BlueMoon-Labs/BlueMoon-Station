import { useBackend } from '../backend';
import { BlockQuote, Box, Button, Icon, LabeledList, NoticeBox, Section, Stack } from '../components';
import { Window } from '../layouts';

export const PaiCard = (props) => {
  const { data } = useBackend();
  const { pai } = data;

  return (
    <Window width={400} height={400} title="Меню опций ПИИ">
      <Window.Content scrollable>
        {!pai ? <PaiDownload /> : <PaiOptions />}
      </Window.Content>
    </Window>
  );
};

const PaiDownload = (props) => {
  const { act, data } = useBackend();
  const { candidates = [] } = data;

  return (
    <Stack fill vertical>
      <Stack.Item>
        <NoticeBox info>
          <Stack fill>
            <Stack.Item grow fontSize="16px">
              Кандидаты в ПИИ
            </Stack.Item>
            <Stack.Item>
              <Button
                color="good"
                icon="bell"
                onClick={() => act('request')}
                tooltip="Запросить дополнительных кандидатов извне."
              >
                Запрос
              </Button>
            </Stack.Item>
          </Stack>
        </NoticeBox>
      </Stack.Item>
      {candidates.length === 0 && (
        <Stack.Item>
          <NoticeBox info>
            <Icon name="search" /> Нет доступных кандидатов.
          </NoticeBox>
        </Stack.Item>
      )}
      {candidates.map((candidate, index) => (
        <Stack.Item key={index}>
          <CandidateDisplay candidate={candidate} index={index + 1} />
        </Stack.Item>
      ))}
    </Stack>
  );
};

const CandidateDisplay = (props) => {
  const { act } = useBackend();
  const { candidate, index } = props;
  const { comments, ckey, description, name } = candidate;

  return (
    <Section
      buttons={
        <Button icon="save" onClick={() => act('download', { ckey })} tooltip="Загрузить этого кандидата в устройство.">
          Скачать
        </Button>
      }
      overflow="hidden"
      title={`Кандидат ${index}`}
    >
      <Stack vertical>
        <Stack.Item>
          <Box color="label" mb={1}>
            Имя:
          </Box>
          {name ? (
            <Box color="green">{name}</Box>
          ) : (
            'Имя не указано - оно будет выбрано случайным образом.'
          )}
        </Stack.Item>
        {!!description && (
          <>
            <Stack.Divider />
            <Stack.Item>
              <Box color="label" mb={1}>
                IC описание:
              </Box>
              {description}
            </Stack.Item>
          </>
        )}
        {!!comments && (
          <>
            <Stack.Divider />
            <Stack.Item>
              <Box color="label" mb={1}>
                OOC заметки:
              </Box>
              {comments}
            </Stack.Item>
          </>
        )}
      </Stack>
    </Section>
  );
};

const PaiOptions = (props) => {
  const { act, data } = useBackend();
  const {
    pai: {
      can_holo,
      dna,
      emagged,
      laws,
      master,
      name,
      transmit,
      receive,
      leashed,
      range,
    },
    range_max,
    range_min,
  } = data;

  const suppliedLaws = laws && laws[0] ? laws[0] : 'Отсутствуют.';

  return (
    <Section fill scrollable title={`Настройки: ${name.toUpperCase()}`}>
      <LabeledList>
        <LabeledList.Item label="Мастер">
          {master || (
            <Button icon="dna" onClick={() => act('set_dna')} tooltip="Стать мастером устройства.">
              Отпечаток
            </Button>
          )}
        </LabeledList.Item>
        {!!master && (
          <LabeledList.Item color="red" label="ДНК">
            {dna}
          </LabeledList.Item>
        )}
        <LabeledList.Item label="Законы">
          <BlockQuote>{suppliedLaws}</BlockQuote>
        </LabeledList.Item>
        <LabeledList.Item label="Голограмма">
          <Button
            icon={can_holo ? 'toggle-on' : 'toggle-off'}
            onClick={() => act('toggle_holo')}
            selected={can_holo}
            tooltip="Разрешить ПИИ использовать голограмму."
          >
            Переключить
          </Button>
        </LabeledList.Item>
        <LabeledList.Item label="Поводок">
          <Button
            icon={leashed ? 'toggle-on' : 'toggle-off'}
            onClick={() => act('toggle_leash')}
            selected={leashed}
            tooltip="Ограничить радиус передвижения ПИИ."
          >
            {leashed ? 'Отпустить' : 'Привязать'}
          </Button>
        </LabeledList.Item>
        <LabeledList.Item label="Диапазон голограммы">
          <Stack>
            <Stack.Item>
              <Button
                icon="minus"
                onClick={() => act('decrease_range')}
                disabled={range === range_min}
                tooltip="Уменьшить радиус действия голограммы."
              />
            </Stack.Item>
            <Stack.Item mt={0.5}>{range}</Stack.Item>
            <Stack.Item>
              <Button
                icon="plus"
                onClick={() => act('increase_range')}
                disabled={range === range_max}
                tooltip="Увеличить радиус действия голограммы."
              />
            </Stack.Item>
          </Stack>
        </LabeledList.Item>
        <LabeledList.Item label="Передача">
          <Button
            icon={transmit ? 'toggle-on' : 'toggle-off'}
            onClick={() => act('toggle_radio', { option: 'transmit' })}
            selected={transmit}
            tooltip="Отключить/включить микрофон ПИИ."
          >
            Переключить
          </Button>
        </LabeledList.Item>
        <LabeledList.Item label="Приём">
          <Button
            icon={receive ? 'toggle-on' : 'toggle-off'}
            onClick={() => act('toggle_radio', { option: 'receive' })}
            selected={receive}
            tooltip="Отключить/включить динамик ПИИ."
          >
            Переключить
          </Button>
        </LabeledList.Item>
        <LabeledList.Item label="Устранение неполадок">
          <Button icon="comment" onClick={() => act('fix_speech')} tooltip="Перезагрузить речевые модули ПИИ.">
            Настроить речь
          </Button>
          <Button icon="edit" onClick={() => act('set_laws')} tooltip="Установить дополнительные директивы для ПИИ.">
            Установить законы
          </Button>
        </LabeledList.Item>
        <LabeledList.Item label="Личность">
          <Button icon="trash" onClick={() => act('wipe_pai')} tooltip="Необратимо стереть личность ПИИ.">
            Стереть
          </Button>
        </LabeledList.Item>
      </LabeledList>
      {!!emagged && (
        <Button
          color="bad"
          icon="bug"
          mt={1}
          onClick={() => act('reset_software')}
          tooltip="Сбросить ПО после ЕМАГа — очищает мастер-ДНК и директивы."
        >
          Сброс ПО
        </Button>
      )}
    </Section>
  );
};

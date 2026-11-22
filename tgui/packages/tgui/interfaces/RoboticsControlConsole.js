// File modding Pe4henika (Bluemoon) 13.03.26
import { useBackend, useSharedState } from '../backend';
import { Box, Button, LabeledList, NoticeBox, ProgressBar, Section, Tabs } from '../components';
import { Window } from '../layouts';

export const RoboticsControlConsole = (props) => {
  const { act, data } = useBackend();
  const [tab, setTab] = useSharedState('tab', 1);
  const {
    can_hack,
    cyborgs = [],
    drones = [],
    cybernetics = [],
  } = data;
  return (
    <Window
      width={500}
      height={460}>
      <Window.Content overflow="auto">
        <Tabs>
          <Tabs.Tab
            icon="robot"
            lineHeight="23px"
            selected={tab === 1}
            onClick={() => setTab(1)}>
            Киборги ({cyborgs.length})
          </Tabs.Tab>
          <Tabs.Tab
            icon="microchip"
            lineHeight="23px"
            selected={tab === 2}
            onClick={() => setTab(2)}>
            Дроны ({drones.length})
          </Tabs.Tab>
          <Tabs.Tab
            icon="user-astronaut"
            lineHeight="23px"
            selected={tab === 3}
            onClick={() => setTab(3)}>
            Кибернетика ({cybernetics.length})
          </Tabs.Tab>
        </Tabs>
        {tab === 1 && (
          <Cyborgs cyborgs={cyborgs} can_hack={can_hack} />
        )}
        {tab === 2 && (
          <Drones drones={drones} />
        )}
        {tab === 3 && (
          <Cybernetics cybernetics={cybernetics} />
        )}
      </Window.Content>
    </Window>
  );
};

const Cyborgs = (props) => {
  const { cyborgs, can_hack } = props;
  const { act } = useBackend();
  if (!cyborgs.length) {
    return (
      <NoticeBox>
        В зоне доступа не обнаружено блоков киборгов
      </NoticeBox>
    );
  }
  return cyborgs.map(cyborg => {
    return (
      <Section
        key={cyborg.ref}
        title={cyborg.name}
        buttons={(
          <>
            {!!can_hack && !cyborg.emagged && (
              <Button
                icon="terminal"
                content="Взломать"
                color="bad"
                onClick={() => act('magbot', {
                  ref: cyborg.ref,
                })} />
            )}
            <Button.Confirm
              icon={cyborg.locked_down ? 'unlock' : 'lock'}
              color={cyborg.locked_down ? 'good' : 'default'}
              content={cyborg.locked_down ? "Освободить" : "Блокировка"}
              onClick={() => act('stopbot', {
                ref: cyborg.ref,
              })} />
            <Button.Confirm
              icon="bomb"
              content="Детонировать"
              color="bad"
              onClick={() => act('killbot', {
                ref: cyborg.ref,
              })} />
          </>
        )}>
        <LabeledList>
          <LabeledList.Item label="Статус">
            <Box color={cyborg.status
              ? 'bad'
              : cyborg.locked_down
                ? 'average'
                : 'good'}>
              {cyborg.status
                ? "Нет ответа"
                : cyborg.locked_down
                  ? "Заблокирован"
                  : "Норма"}
            </Box>
          </LabeledList.Item>
          <LabeledList.Item label="Заряд">
            <Box color={cyborg.charge <= 30
              ? 'bad'
              : cyborg.charge <= 70
                ? 'average'
                : 'good'}>
              {typeof cyborg.charge === 'number'
                ? cyborg.charge + "%"
                : "Не найдено"}
            </Box>
          </LabeledList.Item>
          <LabeledList.Item label="Модель">
            {cyborg.module}
          </LabeledList.Item>
          <LabeledList.Item label="Главный ИИ">
            <Box color={cyborg.synchronization ? 'default' : 'average'}>
              {cyborg.synchronization || "Нет"}
            </Box>
          </LabeledList.Item>
        </LabeledList>
      </Section>
    );
  });
};

const Drones = (props) => {
  const { drones } = props;
  const { act } = useBackend();

  if (!drones.length) {
    return (
      <NoticeBox>
        В зоне доступа не обнаружено дронов
      </NoticeBox>
    );
  }

  return drones.map(drone => {
    return (
      <Section
        key={drone.ref}
        title={drone.name}
        buttons={(
          <Button.Confirm
            icon="bomb"
            content="Детонировать"
            color="bad"
            onClick={() => act('killdrone', {
              ref: drone.ref,
            })} />
        )}>
        <LabeledList>
          <LabeledList.Item label="Статус">
            <Box color={drone.status
              ? 'bad'
              : 'good'}>
              {drone.status
                ? "Нет ответа"
                : 'Норма'}
            </Box>
          </LabeledList.Item>
        </LabeledList>
      </Section>
    );
  });
};

const Cybernetics = (props) => {
  const { cybernetics } = props;
  const { act, data } = useBackend();
  const { is_ai } = data; // Получаем статус ИИ из бэкенда

  if (!cybernetics.length) {
    return (
      <NoticeBox>
        Нейросвязанных биообъектов не обнаружено
      </NoticeBox>
    );
  }

  return cybernetics.map(cyber => {
    return (
      <Section
        key={cyber.ref}
        title={cyber.name}
        buttons={(
          <>
            {!!is_ai && (
              <>
                <Button
                  icon="smile"
                  content="Похвалить"
                  color="green"
                  onClick={() => act('praise_cyber', { ref: cyber.ref })} />
                <Button
                  icon="frown"
                  content="Отругать"
                  color="orange"
                  onClick={() => act('scold_cyber', { ref: cyber.ref })} />
              </>
            )}
            <Button.Confirm
              icon="bolt"
              content={cyber.shock_cooldown > 0 ? `${cyber.shock_cooldown}с` : "Разряд"}
              color="average"
              disabled={cyber.shock_cooldown > 0}
              onClick={() => act('shock_cyber', {
                ref: cyber.ref,
              })} />
          </>
        )}>
        <LabeledList>
          <LabeledList.Item label="Статус">
            <Box color={cyber.status >= 2 ? 'bad' : 'good'}>
              {cyber.status >= 2 ? "Без сознания" : "Активен"}
            </Box>
          </LabeledList.Item>
          <LabeledList.Item label="Здоровье">
            <ProgressBar
              value={cyber.health}
              minValue={0}
              maxValue={cyber.max_health}
              color={cyber.health <= 30 ? 'bad' : 'good'}>
              {cyber.health} / {cyber.max_health}
            </ProgressBar>
          </LabeledList.Item>
          <LabeledList.Item label="Назначение">
            {cyber.role}
          </LabeledList.Item>
        </LabeledList>
      </Section>
    );
  });
};

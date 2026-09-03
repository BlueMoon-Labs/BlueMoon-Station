import { useBackend } from '../backend';
import { Button, LabeledList, ProgressBar, Section, Stack } from '../components';
import { NtosWindow } from '../layouts';

const getMuleByRef = (mules, ref) => {
  return mules?.find(mule => mule.mule_ref === ref);
};

export const NtosRoboControl = (props) => {
  const { act, data } = useBackend();
  const {
    bots,
    id_owner,
    has_id,
  } = data;
  return (
    <NtosWindow
      width={550}
      height={550}>
      <NtosWindow.Content overflow="auto">
        <Section title="Консоль управления роботами">
          <LabeledList>
            <LabeledList.Item label="ID-карта">
              {id_owner}
              {!!has_id && (
                <Button
                  ml={2}
                  icon="eject"
                  content="Извлечь"
                  onClick={() => act('ejectcard')} />
              )}
            </LabeledList.Item>
            <LabeledList.Item label="Ботов в радиусе">
              {data.botcount}
            </LabeledList.Item>
          </LabeledList>
        </Section>
        {bots?.map(robot => (
          <RobotInfo
            key={robot.bot_ref}
            robot={robot} />
        ))}
      </NtosWindow.Content>
    </NtosWindow>
  );
};

const RobotInfo = (props) => {
  const { robot } = props;
  const { act, data } = useBackend();
  const mules = data.mules || [];
  // Get a mule object
  const mule = !!robot.mule_check
    && getMuleByRef(mules, robot.bot_ref);
  // Color based on type of a robot
  const color = robot.mule_check === 1
    ? 'rgba(110, 75, 14, 1)'
    : 'rgba(74, 59, 140, 1)';
  return (
    <Section
      title={robot.name}
      style={{
        border: `4px solid ${color}`,
      }}
      buttons={mule && (
        <>
          <Button
            icon="play"
            tooltip="Идти к пункту назначения."
            onClick={() => act('go', {
              robot: mule.mule_ref,
            })} />
          <Button
            icon="pause"
            tooltip="Остановить."
            onClick={() => act('stop', {
              robot: mule.mule_ref,
            })} />
          <Button
            icon="home"
            tooltip="Вернуться домой."
            tooltipPosition="bottom-start"
            onClick={() => act('home', {
              robot: mule.mule_ref,
            })} />
        </>
      )}>
      <Stack>
        <Stack.Item grow={1} basis={0}>
          <LabeledList>
            <LabeledList.Item label="Модель">
              {robot.model}
            </LabeledList.Item>
            <LabeledList.Item label="Местоположение">
              {robot.locat}
            </LabeledList.Item>
            <LabeledList.Item label="Статус">
              {robot.mode}
            </LabeledList.Item>
            {mule && (
              <>
                <LabeledList.Item label="Груз">
                  {data.load || "N/A"}
                </LabeledList.Item>
                <LabeledList.Item label="Дом">
                  {mule.home}
                </LabeledList.Item>
                <LabeledList.Item label="Пункт назначения">
                  {mule.dest || "N/A"}
                </LabeledList.Item>
                <LabeledList.Item label="Заряд">
                  <ProgressBar
                    value={mule.power}
                    minValue={0}
                    maxValue={100}
                    ranges={{
                      good: [60, Infinity],
                      average: [20, 60],
                      bad: [-Infinity, 20],
                    }} />
                </LabeledList.Item>
              </>
            )}
          </LabeledList>
        </Stack.Item>
        <Stack.Item width="150px">
          {mule && (
            <>
              <Button
                fluid
                content="Задать пункт назначения"
                onClick={() => act('destination', {
                  robot: mule.mule_ref,
                })} />
              <Button
                fluid
                content="Задать ID"
                onClick={() => act('setid', {
                  robot: mule.mule_ref,
                })} />
              <Button
                fluid
                content="Задать дом"
                onClick={() => act('sethome', {
                  robot: mule.mule_ref,
                })} />
              <Button
                fluid
                content="Выгрузить груз"
                onClick={() => act('unload', {
                  robot: mule.mule_ref,
                })} />
              <Button.Checkbox
                fluid
                content="Автовозврат"
                checked={mule.autoReturn}
                onClick={() => act('autoret', {
                  robot: mule.mule_ref,
                })} />
              <Button.Checkbox
                fluid
                content="Автоподбор"
                checked={mule.autoPickup}
                onClick={() => act('autopick', {
                  robot: mule.mule_ref,
                })} />
              <Button.Checkbox
                fluid
                content="Отчёт о доставке"
                checked={mule.reportDelivery}
                onClick={() => act('report', {
                  robot: mule.mule_ref,
                })} />
            </>
          )}
          {!mule && (
            <>
              <Button
                fluid
                content="Остановить патруль"
                onClick={() => act('patroloff', {
                  robot: robot.bot_ref,
                })} />
              <Button
                fluid
                content="Начать патруль"
                onClick={() => act('patrolon', {
                  robot: robot.bot_ref,
                })} />
              <Button
                fluid
                content="Вызвать"
                onClick={() => act('summon', {
                  robot: robot.bot_ref,
                })} />
              <Button
                fluid
                content="Извлечь ПИИ"
                onClick={() => act('ejectpai', {
                  robot: robot.bot_ref,
                })} />
            </>
          )}
        </Stack.Item>
      </Stack>
    </Section>
  );
};

// File modding Pe4henika (Bluemoon) 13.03.26
import { useBackend, useSharedState } from '../backend';
import { Box, Button, LabeledList, NoticeBox, Section, Tabs, ProgressBar } from '../components';
import { Window } from '../layouts';

export const RoboticsControlConsole = (props, context) => {
  const { act, data } = useBackend(context);
  const [tab, setTab] = useSharedState(context, 'tab', 1);
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
            Cyborgs ({cyborgs.length})
          </Tabs.Tab>
          <Tabs.Tab
            icon="microchip"
            lineHeight="23px"
            selected={tab === 2}
            onClick={() => setTab(2)}>
            Drones ({drones.length})
          </Tabs.Tab>
          <Tabs.Tab
            icon="user-astronaut"
            lineHeight="23px"
            selected={tab === 3}
            onClick={() => setTab(3)}>
            Cybernetics ({cybernetics.length})
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

const Cyborgs = (props, context) => {
  const { cyborgs, can_hack } = props;
  const { act } = useBackend(context);
  if (!cyborgs.length) {
    return (
      <NoticeBox>
        No cyborg units detected within access parameters
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
                content="Hack"
                color="bad"
                onClick={() => act('magbot', {
                  ref: cyborg.ref,
                })} />
            )}
            <Button.Confirm
              icon={cyborg.locked_down ? 'unlock' : 'lock'}
              color={cyborg.locked_down ? 'good' : 'default'}
              content={cyborg.locked_down ? "Release" : "Lockdown"}
              onClick={() => act('stopbot', {
                ref: cyborg.ref,
              })} />
            <Button.Confirm
              icon="bomb"
              content="Detonate"
              color="bad"
              onClick={() => act('killbot', {
                ref: cyborg.ref,
              })} />
          </>
        )}>
        <LabeledList>
          <LabeledList.Item label="Status">
            <Box color={cyborg.status
              ? 'bad'
              : cyborg.locked_down
                ? 'average'
                : 'good'}>
              {cyborg.status
                ? "Not Responding"
                : cyborg.locked_down
                  ? "Locked Down"
                  : "Nominal"}
            </Box>
          </LabeledList.Item>
          <LabeledList.Item label="Charge">
            <Box color={cyborg.charge <= 30
              ? 'bad'
              : cyborg.charge <= 70
                ? 'average'
                : 'good'}>
              {typeof cyborg.charge === 'number'
                ? cyborg.charge + "%"
                : "Not Found"}
            </Box>
          </LabeledList.Item>
          <LabeledList.Item label="Model">
            {cyborg.module}
          </LabeledList.Item>
          <LabeledList.Item label="Master AI">
            <Box color={cyborg.synchronization ? 'default' : 'average'}>
              {cyborg.synchronization || "None"}
            </Box>
          </LabeledList.Item>
        </LabeledList>
      </Section>
    );
  });
};

const Drones = (props, context) => {
  const { drones } = props;
  const { act } = useBackend(context);

  if (!drones.length) {
    return (
      <NoticeBox>
        No drone units detected within access parameters
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
            content="Detonate"
            color="bad"
            onClick={() => act('killdrone', {
              ref: drone.ref,
            })} />
        )}>
        <LabeledList>
          <LabeledList.Item label="Status">
            <Box color={drone.status
              ? 'bad'
              : 'good'}>
              {drone.status
                ? "Not Responding"
                : 'Nominal'}
            </Box>
          </LabeledList.Item>
        </LabeledList>
      </Section>
    );
  });
};

const Cybernetics = (props, context) => {
  const { cybernetics } = props;
  const { act, data } = useBackend(context);
  const { is_ai } = data; // Получаем статус ИИ из бэкенда

  if (!cybernetics.length) {
    return (
      <NoticeBox>
        No neural-linked bio-assets detected
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
              content={cyber.shock_cooldown > 0 ? `${cyber.shock_cooldown}s` : "Shock"}
              color="average"
              disabled={cyber.shock_cooldown > 0}
              onClick={() => act('shock_cyber', {
                ref: cyber.ref,
              })} />
          </>
        )}>
        <LabeledList>
          <LabeledList.Item label="Status">
            <Box color={cyber.status >= 2 ? 'bad' : 'good'}>
              {cyber.status >= 2 ? "Unconscious" : "Active"}
            </Box>
          </LabeledList.Item>
          <LabeledList.Item label="Health">
            <ProgressBar
              value={cyber.health}
              minValue={0}
              maxValue={cyber.max_health}
              color={cyber.health <= 30 ? 'bad' : 'good'}>
              {cyber.health} / {cyber.max_health}
            </ProgressBar>
          </LabeledList.Item>
          <LabeledList.Item label="Designation">
            {cyber.role}
          </LabeledList.Item>
        </LabeledList>
      </Section>
    );
  });
};

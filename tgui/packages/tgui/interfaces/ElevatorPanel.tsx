import { clamp } from 'common/math';
import { BooleanLike } from 'common/react';

import { useBackend } from '../backend';
import {
  Blink,
  Box,
  Button,
  Dimmer,
  Icon,
  Section,
  Stack,
} from '../components';
import { Window } from '../layouts';

type FloorData = {
  name: string;
  z_level: number;
};

type ElevatorPanelData = {
  current_floor: number;
  emergency_level: string;
  is_emergency: BooleanLike;
  doors_open: BooleanLike;
  lift_exists: BooleanLike;
  currently_moving: BooleanLike;
  currently_moving_to_floor: number | null;
  all_floor_data: FloorData[];
};

export const ElevatorPanel = (props) => {
  const { data, act } = useBackend<ElevatorPanelData>();

  const {
    current_floor,
    emergency_level,
    is_emergency,
    doors_open,
    lift_exists,
    currently_moving,
    all_floor_data,
  } = data;

  const calculatedHeight = clamp(all_floor_data.length * 90, 400, 600);

  return (
    <Window width={200} height={calculatedHeight} theme="retro">
      <Window.Content>
        {!lift_exists && <NoLiftDimmer />}
        <Stack height="100%" vertical>
          <Stack.Item>
            <Section title="Этаж" align="center">
              <FloorPanel />
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <Section fill align="center">
              {!!currently_moving && <MovingDimmer />}
              <Stack vertical width="90%">
                {all_floor_data.map((floor, index) => (
                  <Stack.Item key={index}>
                    <Button
                      bold
                      fontSize="14px"
                      fluid
                      ellipsis
                      textAlign="left"
                      icon="circle"
                      disabled={floor.z_level === current_floor}
                      onClick={() => act('move_lift', { z: floor.z_level })}>
                      {floor.name}
                    </Button>
                  </Stack.Item>
                ))}
              </Stack>
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Section>
              {doors_open ? (
                <Button
                  width="65%"
                  icon="door-closed"
                  tooltip="Закрывает все двери лифта, кроме тех, что на этаже кабины."
                  onClick={() => act('reset_doors')}>
                  Закрыть двери
                </Button>
              ) : (
                <Button
                  width="65%"
                  icon="door-open"
                  disabled={!is_emergency}
                  color={'bad'}
                  tooltip={
                    is_emergency
                      ? 'На случай ЧП: открывает все двери лифта.'
                      : `Код тревоги на станции пока только ${emergency_level}.`
                  }
                  onClick={() => act('emergency_door')}>
                  Экстренно
                </Button>
              )}
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const NoLiftDimmer = () => {
  return (
    <Dimmer>
      <Stack vertical align="center">
        <Stack.Item>
          <Icon size={8} name="exclamation" />
        </Stack.Item>
        <Stack.Item fontSize="16px">Лифт не подключён.</Stack.Item>
      </Stack>
    </Dimmer>
  );
};

const MovingDimmer = () => {
  return (
    <Dimmer>
      <Stack vertical align="center">
        <Stack.Item>
          <Icon size={8} name="spinner" spin />
        </Stack.Item>
        <Stack.Item fontSize="16px">Лифт едет...</Stack.Item>
      </Stack>
    </Dimmer>
  );
};

const FloorPanel = (props) => {
  const { data } = useBackend<ElevatorPanelData>();
  const { current_floor, currently_moving, currently_moving_to_floor } = data;

  return (
    <Stack width="50%" backgroundColor="black" align="center">
      <Stack.Item ml={2} mr={1} mt={1} mb={1}>
        <Stack vertical>
          <Stack.Item>
            <ArrowIcon
              icon="arrow-up"
              is_moving={
                currently_moving &&
                currently_moving_to_floor &&
                currently_moving_to_floor > current_floor
              }
            />
          </Stack.Item>
          <Stack.Item>
            <ArrowIcon
              icon="arrow-down"
              is_moving={
                currently_moving &&
                currently_moving_to_floor &&
                currently_moving_to_floor < current_floor
              }
            />
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Item>
        <Box
          textColor="white"
          style={{
            fontFamily: 'Monospace',
            fontSize: '50px',
            fontWeight: 'bold',
          }}>
          {current_floor - 1}
        </Box>
      </Stack.Item>
    </Stack>
  );
};

const ArrowIcon = (props) => {
  return props.is_moving ? (
    <Blink time={500} interval={500}>
      <Icon name={props.icon} color={'green'} size={2} />
    </Blink>
  ) : (
    <Icon name={props.icon} color={'grey'} size={2} />
  );
};

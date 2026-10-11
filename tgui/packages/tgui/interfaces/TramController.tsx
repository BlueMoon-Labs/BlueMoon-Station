import { toFixed } from 'common/math';
import { BooleanLike } from 'common/react';
import { useState } from 'react';

import { useBackend } from '../backend';
import {
  Button,
  Dropdown,
  LabeledList,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
} from '../components';
import { Window } from '../layouts';

type Data = {
  transportId: string;
  controllerActive: number;
  controllerOperational: BooleanLike;
  travelDirection: number;
  destinationPlatform: string;
  idlePlatform: string;
  recoveryMode: BooleanLike;
  currentSpeed: number;
  currentLoad: number;
  statusSF: BooleanLike;
  statusCE: BooleanLike;
  statusES: BooleanLike;
  statusPD: BooleanLike;
  statusDR: BooleanLike;
  statusCL: BooleanLike;
  statusBS: BooleanLike;
  destinations: TramDestination[];
};

type TramDestination = {
  name: string;
  dest_icons: string[];
  id: number;
};

export const TramController = (props) => {
  const { act, data } = useBackend<Data>();

  const {
    transportId,
    controllerActive,
    controllerOperational,
    travelDirection,
    destinationPlatform,
    idlePlatform,
    recoveryMode,
    currentSpeed,
    currentLoad,
    statusSF,
    statusCE,
    statusES,
    statusPD,
    statusDR,
    statusCL,
    statusBS,
    destinations = [],
  } = data;

  const [tripDestination, setTripDestination] = useState('');

  return (
    <Window title="Контроллер трамвая" width={778} height={327} theme="dark">
      <Window.Content>
        <Stack>
          <Stack.Item grow={4}>
            <Section title="Состояние системы">
              <LabeledList>
                <LabeledList.Item label="ID системы">
                  {transportId}
                </LabeledList.Item>
                <LabeledList.Item
                  label="Очередь команд"
                  color={controllerActive ? 'blue' : 'good'}>
                  {controllerActive ? 'Выполняется' : 'Готов'}
                </LabeledList.Item>
                <LabeledList.Item
                  label="Механика"
                  color={controllerOperational ? 'good' : 'bad'}>
                  {controllerOperational ? 'Норма' : 'Неисправность'}
                </LabeledList.Item>
                <LabeledList.Item
                  label="Процессор"
                  color={recoveryMode ? 'average' : 'good'}>
                  {recoveryMode ? 'Перегрузка' : 'Норма'}
                </LabeledList.Item>
                <LabeledList.Item label="Загрузка ЦП">
                  <ProgressBar
                    value={currentLoad}
                    minValue={0}
                    maxValue={15}
                    ranges={{
                      good: [-Infinity, 5],
                      average: [5, 7.5],
                      bad: [7.5, Infinity],
                    }}
                  />
                </LabeledList.Item>
                <LabeledList.Item label="Скорость">
                  <ProgressBar
                    value={currentSpeed}
                    minValue={0}
                    maxValue={32}
                    ranges={{
                      good: [28, Infinity],
                      average: [24, 28],
                      bad: [0.1, 24],
                      white: [-Infinity, 0],
                    }}>
                    {`${toFixed(currentSpeed * 2.25, 0)} км/ч`}
                  </ProgressBar>
                </LabeledList.Item>
              </LabeledList>
            </Section>
            <Section title="Местоположение">
              <LabeledList>
                <LabeledList.Item label="Направление">
                  {travelDirection === 4 ? 'Прямое' : 'Обратное'}
                </LabeledList.Item>
                <LabeledList.Item
                  label="Платформа стоянки"
                  color={controllerActive ? '' : 'blue'}>
                  {idlePlatform}
                </LabeledList.Item>
                <LabeledList.Item
                  label="Платформа назначения"
                  color={controllerActive ? 'blue' : ''}>
                  {destinationPlatform}
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>
          <Stack.Item grow={6}>
            <Section title="Управление">
              <NoticeBox>
                Nanotrasen не несёт ответственности за травмы и гибель людей при
                пользовании трамваем.
              </NoticeBox>
              <Button
                icon="arrows-rotate"
                color="yellow"
                my={1}
                lineHeight={2}
                width="28%"
                minHeight={2}
                textAlign="center"
                onClick={() => act('reset', {})}>
                Перезапуск
              </Button>
              <Button
                icon="square"
                color="bad"
                my={1}
                lineHeight={2}
                width="28%"
                minHeight={2}
                textAlign="center"
                onClick={() => act('estop', {})}>
                Стоп-кран
              </Button>
              <Button
                icon="play"
                color="green"
                disabled={statusES || statusSF}
                my={1}
                lineHeight={2}
                width="42%"
                minHeight={2}
                textAlign="center"
                onClick={() =>
                  act('dispatch', {
                    tripDestination: tripDestination,
                  })
                }>
                Отправить трамвай
              </Button>
              <Dropdown
                width="98.5%"
                options={destinations.map((id) => id.name)}
                selected={tripDestination}
                displayText={!tripDestination && 'Выберите пункт назначения'}
                onSelected={(value) => setTripDestination(value)}
              />
              <Button
                icon="bars"
                color="blue"
                my={1}
                lineHeight={2}
                width="25%"
                minHeight={2}
                textAlign="center"
                onClick={() => act('dopen', {})}>
                Открыть двери
              </Button>
              <Button
                icon="bars"
                color="blue"
                my={1}
                lineHeight={2}
                width="25%"
                minHeight={2}
                textAlign="center"
                onClick={() => act('dclose', {})}>
                Закрыть двери
              </Button>
              <Button
                icon="bars"
                color={statusBS ? 'good' : 'bad'}
                my={1}
                lineHeight={2}
                width="48%"
                minHeight={2}
                textAlign="center"
                onClick={() => act('togglesensors', {})}>
                Обход датчиков дверей
              </Button>
            </Section>
            <Section title="Индикаторы">
              <Button
                color={statusES ? 'red' : 'transparent'}
                my={1}
                lineHeight={2}
                width="16%"
                minHeight={2}
                textAlign="center">
                СТОП
              </Button>
              <Button
                color={statusSF ? 'yellow' : 'transparent'}
                my={1}
                lineHeight={2}
                width="16%"
                minHeight={2}
                textAlign="center">
                СБОЙ
              </Button>
              <Button
                color={statusCE ? 'teal' : 'transparent'}
                my={1}
                lineHeight={2}
                width="16%"
                minHeight={2}
                textAlign="center">
                СВЯЗЬ
              </Button>
              <Button
                color={statusPD ? 'blue' : 'transparent'}
                my={1}
                lineHeight={2}
                width="16%"
                minHeight={2}
                textAlign="center">
                ЗАПРОС
              </Button>
              <Button
                color={statusDR ? 'transparent' : 'blue'}
                my={1}
                lineHeight={2}
                width="16%"
                minHeight={2}
                textAlign="center">
                ДВЕРИ
              </Button>
              <Button
                color={statusCL ? 'blue' : 'transparent'}
                my={1}
                lineHeight={2}
                width="16%"
                minHeight={2}
                textAlign="center">
                ЗАНЯТ
              </Button>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

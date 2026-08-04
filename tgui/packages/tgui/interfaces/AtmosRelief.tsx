import { BooleanLike } from 'common/react';

import { useBackend } from '../backend';
import { Button, LabeledList, NumberInput, Section } from '../components';
import { Window } from '../layouts';
import { AtmosPorts, PortReading } from './common/AtmosPorts';

type AtmosReliefData = {
  open_pressure: number;
  close_pressure: number;
  max_pressure: number;
  min_open_pressure: number;
  max_close_pressure: number;
  opened: BooleanLike;
  ports?: PortReading[];
};

export const AtmosRelief = () => {
  const { act, data } = useBackend<AtmosReliefData>();
  const maxPressure = data.max_pressure || 4500;
  const ports = data.ports || [];
  return (
    <Window width={400} height={200 + ports.length * 22}>
      <Window.Content>
        <Section>
          <LabeledList>
            <LabeledList.Item
              label="Состояние"
              color={data.opened ? 'bad' : 'good'}>
              {data.opened ? 'Клапан сорван' : 'Клапан закрыт'}
            </LabeledList.Item>
            <LabeledList.Item label="Давление срыва">
              <NumberInput
                animated
                value={parseFloat(String(data.open_pressure))}
                unit="кПа"
                width="82px"
                // Границы те же, что применяет ui_act: раньше панель
                // позволяла набрать значение, которое молча уезжало.
                minValue={data.min_open_pressure}
                maxValue={maxPressure}
                step={10}
                onChange={(_event, value) =>
                  act('open_pressure', { pressure: value })
                }
              />
              <Button
                ml={1}
                icon="plus"
                content="Максимум"
                disabled={data.open_pressure === maxPressure}
                onClick={() => act('open_pressure', { pressure: 'max' })}
              />
            </LabeledList.Item>
            <LabeledList.Item label="Давление посадки">
              <NumberInput
                animated
                value={parseFloat(String(data.close_pressure))}
                unit="кПа"
                width="82px"
                minValue={0}
                maxValue={data.max_close_pressure}
                step={10}
                onChange={(_event, value) =>
                  act('close_pressure', { pressure: value })
                }
              />
              <Button
                ml={1}
                icon="plus"
                content="До срыва"
                tooltip="Поднять посадку до давления срыва"
                disabled={data.close_pressure === data.open_pressure}
                onClick={() => act('close_pressure', { pressure: 'max' })}
              />
            </LabeledList.Item>
          </LabeledList>
        </Section>
        <AtmosPorts />
      </Window.Content>
    </Window>
  );
};

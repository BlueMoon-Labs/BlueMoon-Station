import { BooleanLike } from 'common/react';

import { useBackend } from '../backend';
import {
  Button,
  LabeledList,
  NoticeBox,
  NumberInput,
  Section,
} from '../components';
import { Window } from '../layouts';
import { AtmosPorts, PortReading } from './common/AtmosPorts';

type AtmosMixerData = {
  on: BooleanLike;
  set_pressure: number;
  max_pressure: number;
  node1_concentration: number;
  node2_concentration: number;
  ports?: PortReading[];
};

export const AtmosMixer = () => {
  const { act, data } = useBackend<AtmosMixerData>();
  return (
    <Window width={420} height={320}>
      <Window.Content scrollable>
        <Section>
          <LabeledList>
            <LabeledList.Item label="Питание">
              <Button
                icon={data.on ? 'power-off' : 'times'}
                content={data.on ? 'Вкл' : 'Выкл'}
                selected={data.on}
                onClick={() => act('power')}
              />
            </LabeledList.Item>
            <LabeledList.Item label="Давление на выходе">
              <NumberInput
                animated
                value={parseFloat(String(data.set_pressure))}
                unit="кПа"
                width="82px"
                minValue={0}
                maxValue={data.max_pressure}
                step={10}
                onChange={(_event, value) =>
                  act('pressure', { pressure: value })
                }
              />
              <Button
                ml={1}
                icon="plus"
                content="Максимум"
                disabled={data.set_pressure === data.max_pressure}
                onClick={() => act('pressure', { pressure: 'max' })}
              />
            </LabeledList.Item>
            <LabeledList.Item label="Доля узла 1">
              <NumberInput
                animated
                value={data.node1_concentration}
                unit="%"
                width="65px"
                minValue={0}
                maxValue={100}
                stepPixelSize={2}
                onChange={(_event, value) =>
                  act('node1', { concentration: value })
                }
              />
            </LabeledList.Item>
            <LabeledList.Item label="Доля узла 2">
              <NumberInput
                animated
                value={data.node2_concentration}
                unit="%"
                width="65px"
                minValue={0}
                maxValue={100}
                stepPixelSize={2}
                onChange={(_event, value) =>
                  act('node2', { concentration: value })
                }
              />
            </LabeledList.Item>
          </LabeledList>
          <NoticeBox info mt={1}>
            Доли связаны: смеситель держит их сумму равной сотне, поэтому сдвиг
            одной сразу двигает вторую.
          </NoticeBox>
        </Section>
        <AtmosPorts />
      </Window.Content>
    </Window>
  );
};

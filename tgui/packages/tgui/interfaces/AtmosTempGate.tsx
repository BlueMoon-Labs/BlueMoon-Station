import { BooleanLike } from 'common/react';

import { useBackend } from '../backend';
import { Button, LabeledList, NumberInput, Section } from '../components';
import { Window } from '../layouts';
import { AtmosPorts, PortReading } from './common/AtmosPorts';

type AtmosTempGateData = {
  on: BooleanLike;
  temperature: number;
  min_temperature: number;
  max_temperature: number;
  inverted: BooleanLike;
  flowing: BooleanLike;
  ports?: PortReading[];
};

export const AtmosTempGate = () => {
  const { act, data } = useBackend<AtmosTempGateData>();
  const ports = data.ports || [];
  return (
    <Window width={420} height={200 + ports.length * 22}>
      <Window.Content>
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
            <LabeledList.Item
              label="Условие"
              // Направление сравнения переключается мультитулом, и из панели
              // его раньше было не видно вообще.
              color="label">
              Открыт, пока вход {data.inverted ? 'горячее' : 'холоднее'} порога.
              Мультитул переворачивает условие.
            </LabeledList.Item>
            <LabeledList.Item
              label="Поток"
              color={data.flowing ? 'good' : 'label'}>
              {data.flowing ? 'Газ идёт' : 'Газ не идёт'}
            </LabeledList.Item>
            <LabeledList.Item label="Порог">
              <NumberInput
                animated
                value={parseFloat(String(data.temperature))}
                unit="К"
                width="82px"
                minValue={data.min_temperature}
                maxValue={data.max_temperature}
                step={1}
                onChange={(_event, value) =>
                  act('temperature', { temperature: value })
                }
              />
              <Button
                ml={1}
                icon="plus"
                content="Максимум"
                disabled={data.temperature === data.max_temperature}
                onClick={() => act('temperature', { temperature: 'max' })}
              />
            </LabeledList.Item>
          </LabeledList>
        </Section>
        <AtmosPorts />
      </Window.Content>
    </Window>
  );
};

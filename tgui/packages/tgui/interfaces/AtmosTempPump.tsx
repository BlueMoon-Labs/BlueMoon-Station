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

type AtmosTempPumpData = {
  on: BooleanLike;
  rate: number;
  max_heat_transfer_rate: number;
  ports?: PortReading[];
};

export const AtmosTempPump = () => {
  const { act, data } = useBackend<AtmosTempPumpData>();
  const ports = data.ports || [];
  // Насос гонит тепло только со входа на выход и только вниз по градиенту.
  const backwards =
    ports.length >= 2 && ports[0].temperature <= ports[1].temperature;
  return (
    <Window width={420} height={215 + ports.length * 22}>
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
            <LabeledList.Item label="Теплоперенос">
              <NumberInput
                animated
                value={parseFloat(String(data.rate))}
                unit="%"
                width="70px"
                minValue={0}
                maxValue={data.max_heat_transfer_rate}
                step={1}
                onChange={(_event, value) => act('rate', { rate: value })}
              />
              <Button
                ml={1}
                icon="plus"
                content="Максимум"
                disabled={data.rate === data.max_heat_transfer_rate}
                onClick={() => act('rate', { rate: 'max' })}
              />
            </LabeledList.Item>
          </LabeledList>
          {!!data.on && backwards && (
            <NoticeBox warning mt={1}>
              Вход не горячее выхода: насос перекачивает тепло только вниз по
              градиенту и сейчас простаивает.
            </NoticeBox>
          )}
        </Section>
        <AtmosPorts />
      </Window.Content>
    </Window>
  );
};

import { BooleanLike } from 'common/react';

import { useBackend } from '../backend';
import { Button, LabeledList, NumberInput, Section } from '../components';
import { Window } from '../layouts';
import { AtmosPorts, PortReading } from './common/AtmosPorts';

type AtmosPumpData = {
  on: BooleanLike;
  rate?: number;
  max_rate?: number;
  pressure?: number;
  max_pressure?: number;
  /** Текущее давление выхода. Нужно объёмному насосу: он задаёт л/с, и без
   *  живого давления панель слепа. */
  line_pressure?: number | null;
  ports?: PortReading[];
};

export const AtmosPump = () => {
  const { act, data } = useBackend<AtmosPumpData>();
  const volumetric = !!data.max_rate;
  const ports = data.ports || [];
  // Строка "Линия" условная - без слагаемого окно обрезает показания снизу.
  const lineRow = volumetric && typeof data.line_pressure === 'number' ? 22 : 0;
  return (
    <Window width={360} height={155 + lineRow + ports.length * 22}>
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
            {volumetric ? (
              <LabeledList.Item label="Скорость переноса">
                <NumberInput
                  animated
                  value={parseFloat(String(data.rate))}
                  width="70px"
                  unit="л/с"
                  minValue={0}
                  maxValue={data.max_rate}
                  onChange={(_event, value) => act('rate', { rate: value })}
                />
                <Button
                  ml={1}
                  icon="plus"
                  content="Максимум"
                  disabled={data.rate === data.max_rate}
                  onClick={() => act('rate', { rate: 'max' })}
                />
              </LabeledList.Item>
            ) : (
              <LabeledList.Item label="Давление на выходе">
                <NumberInput
                  animated
                  value={parseFloat(String(data.pressure))}
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
                  disabled={data.pressure === data.max_pressure}
                  onClick={() => act('pressure', { pressure: 'max' })}
                />
              </LabeledList.Item>
            )}
            {volumetric && typeof data.line_pressure === 'number' && (
              <LabeledList.Item label="Линия">
                Давление на выходе: {data.line_pressure} кПа
              </LabeledList.Item>
            )}
          </LabeledList>
        </Section>
        <AtmosPorts />
      </Window.Content>
    </Window>
  );
};

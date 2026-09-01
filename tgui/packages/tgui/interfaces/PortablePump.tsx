import { useBackend } from '../backend';
import { Button, LabeledList, NumberInput, Section } from '../components';
import { Window } from '../layouts';
import {
  PortableAtmosData,
  PortableBasicInfo,
} from './common/PortableAtmos';

type PortablePumpData = PortableAtmosData & {
  direction: number | boolean;
  target_pressure: number;
  default_pressure: number;
  min_pressure: number;
  max_pressure: number;
};

export const PortablePump = () => {
  const { act, data } = useBackend<PortablePumpData>();
  const {
    direction,
    target_pressure,
    default_pressure,
    min_pressure,
    max_pressure,
  } = data;
  return (
    <Window width={340} height={520}>
      <Window.Content scrollable>
        <PortableBasicInfo />
        <Section
          title="Насос"
          buttons={
            <Button
              icon={direction ? 'sign-in-alt' : 'sign-out-alt'}
              content={direction ? 'Забор' : 'Выпуск'}
              tooltip={
                direction
                  ? 'Тянет воздух внутрь себя'
                  : 'Выталкивает содержимое наружу'
              }
              selected={direction}
              onClick={() => act('direction')}
            />
          }>
          <LabeledList>
            <LabeledList.Item label="Целевое давление">
              <NumberInput
                value={target_pressure}
                unit="кПа"
                width="82px"
                minValue={min_pressure}
                maxValue={max_pressure}
                step={10}
                onChange={(_event, value) =>
                  act('pressure', { pressure: value })
                }
              />
            </LabeledList.Item>
            <LabeledList.Item label="Пресеты">
              <Button
                icon="fast-backward"
                tooltip="Минимум"
                disabled={target_pressure === min_pressure}
                onClick={() => act('pressure', { pressure: 'min' })}
              />
              <Button
                icon="sync"
                tooltip="Заводское значение"
                disabled={target_pressure === default_pressure}
                onClick={() => act('pressure', { pressure: 'reset' })}
              />
              <Button
                icon="fast-forward"
                tooltip="Максимум"
                disabled={target_pressure === max_pressure}
                onClick={() => act('pressure', { pressure: 'max' })}
              />
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Window.Content>
    </Window>
  );
};

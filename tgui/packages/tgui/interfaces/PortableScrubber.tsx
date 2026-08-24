import { BooleanLike } from 'common/react';

import { useBackend } from '../backend';
import { Button, LabeledList, NumberInput, Section } from '../components';
import { getGasLabel } from '../constants';
import { Window } from '../layouts';
import {
  PortableAtmosData,
  PortableBasicInfo,
} from './common/PortableAtmos';

type FilterEntry = {
  gas_id: string;
  gas_name: string;
  enabled: BooleanLike;
};

type PortableScrubberData = PortableAtmosData & {
  volume_rate: number;
  max_volume_rate: number;
  filter_types: FilterEntry[];
};

export const PortableScrubber = () => {
  const { act, data } = useBackend<PortableScrubberData>();
  const filters = data.filter_types || [];
  const enabledCount = filters.filter((filter) => filter.enabled).length;
  return (
    <Window width={360} height={600}>
      <Window.Content scrollable>
        <PortableBasicInfo />
        <Section title="Забор">
          <LabeledList>
            <LabeledList.Item label="Скорость">
              <NumberInput
                value={data.volume_rate}
                unit="л/с"
                width="82px"
                minValue={0}
                maxValue={data.max_volume_rate}
                step={10}
                onChange={(_event, value) => act('volume_rate', { rate: value })}
              />
              <Button
                ml={1}
                icon="plus"
                content="Максимум"
                disabled={data.volume_rate === data.max_volume_rate}
                onClick={() => act('volume_rate', { rate: 'max' })}
              />
            </LabeledList.Item>
          </LabeledList>
        </Section>
        <Section
          title={`Фильтры (${enabledCount} из ${filters.length})`}
          buttons={
            <>
              <Button
                icon="check-double"
                content="Все"
                disabled={enabledCount === filters.length}
                onClick={() => act('set_all_filters', { val: 1 })}
              />
              <Button
                icon="eraser"
                content="Ничего"
                disabled={enabledCount === 0}
                onClick={() => act('set_all_filters', { val: 0 })}
              />
            </>
          }>
          {filters.map((filter) => (
            <Button
              key={filter.gas_id}
              icon={filter.enabled ? 'check-square-o' : 'square-o'}
              content={getGasLabel(filter.gas_id, filter.gas_name)}
              tooltip={filter.gas_name}
              selected={filter.enabled}
              onClick={() => act('toggle_filter', { val: filter.gas_id })}
            />
          ))}
        </Section>
      </Window.Content>
    </Window>
  );
};

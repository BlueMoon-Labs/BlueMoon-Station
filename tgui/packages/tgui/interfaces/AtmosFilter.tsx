import { BooleanLike } from 'common/react';

import { useBackend } from '../backend';
import { Button, LabeledList, NumberInput, Section } from '../components';
import { getGasLabel } from '../constants';
import { Window } from '../layouts';
import { AtmosPorts, PortReading } from './common/AtmosPorts';

type FilterType = {
  id: string;
  name: string;
  selected: BooleanLike;
};

type AtmosFilterData = {
  on: BooleanLike;
  rate: number;
  max_rate: number;
  filter_types: FilterType[];
  ports?: PortReading[];
};

export const AtmosFilter = () => {
  const { act, data } = useBackend<AtmosFilterData>();
  const filterTypes = data.filter_types || [];
  return (
    <Window width={420} height={330}>
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
            <LabeledList.Item label="Отбирать">
              {filterTypes.map((filter) => (
                <Button
                  key={filter.id}
                  selected={filter.selected}
                  content={
                    filter.id === ''
                      ? 'Ничего'
                      : getGasLabel(filter.id, filter.name)
                  }
                  tooltip={filter.name}
                  onClick={() => act('filter', { mode: filter.id })}
                />
              ))}
            </LabeledList.Item>
          </LabeledList>
        </Section>
        <AtmosPorts />
      </Window.Content>
    </Window>
  );
};

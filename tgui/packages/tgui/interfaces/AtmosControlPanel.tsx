import { BooleanLike } from 'common/react';

import { useBackend } from '../backend';
import {
  Button,
  LabeledList,
  NumberInput,
  Section,
  Stack,
  Table,
} from '../components';
import { Window } from '../layouts';

type NamedValue = {
  name: string;
  value: number | string;
};

type AreaRow = {
  name: string;
  count: number;
  sharing: number;
  planetary: number;
  ref: string;
};

type AtmosControlPanelData = {
  fire_count: number;
  wait: number;
  base_wait: number;
  atmos_speed: number;
  speed_min: number;
  speed_max: number;
  lag_scale: number;
  heat_enabled: BooleanLike;
  equalize_enabled: BooleanLike;
  equalize_valve_mode: BooleanLike;
  sleeping_edges_enabled: BooleanLike;
  log_decompression: BooleanLike;
  counters: NamedValue[];
  costs: NamedValue[];
  areas: AreaRow[];
};

const Levers = () => {
  const { act, data } = useBackend<AtmosControlPanelData>();
  const throttled = data.lag_scale < 1;
  return (
    <Section title="Рычаги">
      <LabeledList>
        <LabeledList.Item label="Скорость атмоса">
          <NumberInput
            value={data.atmos_speed}
            unit="x"
            width="70px"
            minValue={data.speed_min}
            maxValue={data.speed_max}
            step={0.25}
            stepPixelSize={4}
            onChange={(_event, value) => act('speed', { value })}
          />
          <Button
            ml={1}
            icon="undo"
            content="1x"
            disabled={data.atmos_speed === 1}
            onClick={() => act('speed', { value: 1 })}
          />
        </LabeledList.Item>
        <LabeledList.Item label="Каденция">
          {data.wait} дс (компилированная {data.base_wait} дс)
        </LabeledList.Item>
        <LabeledList.Item
          label="Клапан лага"
          color={throttled ? 'average' : 'good'}>
          {throttled
            ? `Придушен до ${data.lag_scale}x - сервер дилейтит`
            : 'Не вмешивается'}
        </LabeledList.Item>
        <LabeledList.Item label="Теплопроводность">
          <Button.Checkbox
            checked={data.heat_enabled}
            onClick={() => act('toggle_heat')}>
            Через стены и материалы
          </Button.Checkbox>
        </LabeledList.Item>
        <LabeledList.Item label="Эквализация">
          <Button.Checkbox
            checked={data.equalize_enabled}
            onClick={() => act('toggle_equalize')}>
            Принудительно
          </Button.Checkbox>
          {!data.equalize_enabled && !!data.equalize_valve_mode && (
            <Button.Checkbox
              checked
              disabled
              tooltip="Адаптивный клапан включил фазу сам: в группе слишком большой перепад">
              Клапан открыт
            </Button.Checkbox>
          )}
        </LabeledList.Item>
        <LabeledList.Item label="Спящие рёбра">
          <Button.Checkbox
            checked={data.sleeping_edges_enabled}
            tooltip="Осевшие пары турфов пропускают compare/share по ревизиям смесей. Экспериментальный перф-режим."
            onClick={() => act('toggle_sleeping_edges')}>
            Пропускать осевшие пары
          </Button.Checkbox>
        </LabeledList.Item>
        <LabeledList.Item label="Лог разгерметизаций">
          <Button.Checkbox
            checked={data.log_decompression}
            onClick={() => act('toggle_decompression_log')}>
            Писать в лог
          </Button.Checkbox>
        </LabeledList.Item>
      </LabeledList>
    </Section>
  );
};

const Counters = (props: {
  readonly title: string;
  readonly rows: NamedValue[];
  readonly suffix?: string;
}) => (
  <Section title={props.title}>
    <LabeledList>
      {(props.rows || []).map((row) => (
        <LabeledList.Item key={row.name} label={row.name}>
          {row.value}
          {props.suffix}
        </LabeledList.Item>
      ))}
    </LabeledList>
  </Section>
);

const NoisyAreas = () => {
  const { act, data } = useBackend<AtmosControlPanelData>();
  const areas = data.areas || [];
  return (
    <Section title="Самые активные зоны">
      {areas.length === 0 ? (
        'Активных турфов нет.'
      ) : (
        <Table>
          <Table.Row header>
            <Table.Cell>Зона</Table.Cell>
            <Table.Cell collapsing>Турфов</Table.Cell>
            <Table.Cell collapsing>Делятся</Table.Cell>
            <Table.Cell collapsing>Планетарных</Table.Cell>
            <Table.Cell collapsing />
          </Table.Row>
          {areas.map((area) => (
            <Table.Row key={area.ref}>
              <Table.Cell>{area.name}</Table.Cell>
              <Table.Cell collapsing>{area.count}</Table.Cell>
              <Table.Cell collapsing>{area.sharing}</Table.Cell>
              <Table.Cell collapsing>{area.planetary}</Table.Cell>
              <Table.Cell collapsing>
                <Button
                  icon="map-marker-alt"
                  tooltip="Прыгнуть к одному из турфов"
                  onClick={() => act('jump', { ref: area.ref })}
                />
              </Table.Cell>
            </Table.Row>
          ))}
        </Table>
      )}
    </Section>
  );
};

export const AtmosControlPanel = () => {
  const { data } = useBackend<AtmosControlPanelData>();
  return (
    <Window width={900} height={640}>
      <Window.Content scrollable>
        <Stack>
          <Stack.Item grow basis={0}>
            <Levers />
            <Counters title="Счётчики" rows={data.counters} />
          </Stack.Item>
          <Stack.Item grow basis={0}>
            <Counters
              title={`Стоимость фаз, мс (проходов: ${data.fire_count})`}
              rows={data.costs}
            />
          </Stack.Item>
        </Stack>
        <NoisyAreas />
      </Window.Content>
    </Window>
  );
};

import { decodeHtmlEntities } from 'common/string';

import { useBackend } from '../../../backend';
import { Box, Button, LabeledList, NoticeBox, Section } from '../../../components';
import { getGasLabel } from '../../../constants';
import { AirAlarmData, ScrubberInfo } from '../types';

const ScrubberControl = (props: { readonly scrubber: ScrubberInfo }) => {
  const { scrubber } = props;
  const { act } = useBackend();
  const { id_tag, long_name, power, scrubbing, widenet, filter_types } =
    scrubber;
  const filters = filter_types || [];
  const enabledCount = filters.filter((filter) => filter.enabled).length;
  return (
    <Section
      title={decodeHtmlEntities(long_name)}
      buttons={
        <Button
          icon={power ? 'power-off' : 'times'}
          content={power ? 'Вкл' : 'Выкл'}
          selected={power}
          onClick={() => act('power', { id_tag, val: Number(!power) })}
        />
      }>
      <LabeledList>
        <LabeledList.Item label="Режим">
          <Button
            icon={scrubbing ? 'filter' : 'sign-in-alt'}
            color={scrubbing || 'danger'}
            content={scrubbing ? 'Фильтрация' : 'Откачка'}
            tooltip={
              scrubbing
                ? 'Вытягивает только отмеченные газы'
                : 'Вытягивает воздух целиком'
            }
            onClick={() => act('scrubbing', { id_tag, val: Number(!scrubbing) })}
          />
          <Button
            icon={widenet ? 'expand' : 'compress'}
            selected={widenet}
            content={widenet ? 'Широкий охват' : 'Обычный охват'}
            tooltip="Широкий охват тянет воздух со всей комнаты, но ест больше энергии"
            onClick={() => act('widenet', { id_tag, val: Number(!widenet) })}
          />
        </LabeledList.Item>
        {!!scrubbing && (
          <LabeledList.Item
            label={`Фильтры (${enabledCount} из ${filters.length})`}
            buttons={
              <>
                <Button
                  icon="check-double"
                  content="Все"
                  disabled={enabledCount === filters.length}
                  onClick={() => act('set_all_filters', { id_tag, val: 1 })}
                />
                <Button
                  icon="eraser"
                  content="Ничего"
                  disabled={enabledCount === 0}
                  onClick={() => act('set_all_filters', { id_tag, val: 0 })}
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
                onClick={() =>
                  act('toggle_filter', { id_tag, val: filter.gas_id })
                }
              />
            ))}
          </LabeledList.Item>
        )}
      </LabeledList>
    </Section>
  );
};

export const Scrubbers = () => {
  const { act, data } = useBackend<AirAlarmData>();
  const scrubbers = data.scrubbers || [];
  if (scrubbers.length === 0) {
    return <NoticeBox>В этой зоне нет скрубберов на этой частоте.</NoticeBox>;
  }
  return (
    <>
      <Box mb={1}>
        <Button
          icon="power-off"
          content="Включить все"
          onClick={() => act('power_all', { target: 'scrubbers', val: 1 })}
        />
        <Button
          icon="times"
          content="Выключить все"
          onClick={() => act('power_all', { target: 'scrubbers', val: 0 })}
        />
      </Box>
      {scrubbers.map((scrubber) => (
        <ScrubberControl key={scrubber.id_tag} scrubber={scrubber} />
      ))}
    </>
  );
};

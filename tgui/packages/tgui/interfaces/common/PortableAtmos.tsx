import { toFixed } from 'common/math';
import { BooleanLike } from 'common/react';

import { useBackend } from '../../backend';
import {
  AnimatedNumber,
  Box,
  Button,
  LabeledList,
  ProgressBar,
  Section,
} from '../../components';
import { getGasColor, getGasLabel } from '../../constants';

const T0C = 273.15;

export type GasShare = {
  id: string;
  name: string;
  percent: number;
};

export type HoldingTank = {
  name: string;
  pressure: number;
  temperature: number;
  gases?: GasShare[];
};

export type PortableAtmosData = {
  on: BooleanLike;
  connected: BooleanLike;
  pressure: number;
  temperature: number;
  max_pressure_allowed: number;
  gases?: GasShare[];
  holding?: HoldingTank;
};

/** Состав смеси полосами: список газов без долей ничего не говорит. */
export const GasComposition = (props: { readonly gases?: GasShare[] }) => {
  const gases = props.gases || [];
  if (gases.length === 0) {
    return <Box color="label">Пусто</Box>;
  }
  return (
    <>
      {gases.map((gas) => (
        <ProgressBar
          key={gas.id}
          mt={0.5}
          value={gas.percent}
          minValue={0}
          maxValue={100}
          color={getGasColor(gas.id) || 'default'}>
          {`${getGasLabel(gas.id, gas.name)}: ${toFixed(gas.percent, 2)} %`}
        </ProgressBar>
      ))}
    </>
  );
};

export const PortableBasicInfo = () => {
  const { act, data } = useBackend<PortableAtmosData>();
  const { connected, holding, on, pressure, temperature } = data;
  return (
    <>
      <Section
        title="Состояние"
        buttons={
          <Button
            icon={on ? 'power-off' : 'times'}
            content={on ? 'Вкл' : 'Выкл'}
            selected={on}
            onClick={() => act('power')}
          />
        }>
        <LabeledList>
          <LabeledList.Item label="Давление">
            <AnimatedNumber value={pressure} format={(v) => toFixed(v, 2)} />
            {' кПа'}
          </LabeledList.Item>
          <LabeledList.Item label="Температура">
            <AnimatedNumber value={temperature} format={(v) => toFixed(v, 2)} />
            {` К (${toFixed(temperature - T0C, 1)} °C)`}
          </LabeledList.Item>
          <LabeledList.Item
            label="Порт"
            color={connected ? 'good' : 'average'}>
            {connected ? 'Подключён' : 'Не подключён'}
          </LabeledList.Item>
          <LabeledList.Item label="Содержимое">
            <GasComposition gases={data.gases} />
          </LabeledList.Item>
        </LabeledList>
      </Section>
      <Section
        title="Съёмный баллон"
        buttons={
          <Button
            icon="eject"
            content="Извлечь"
            disabled={!holding}
            onClick={() => act('eject')}
          />
        }>
        {holding ? (
          <LabeledList>
            <LabeledList.Item label="Этикетка">{holding.name}</LabeledList.Item>
            <LabeledList.Item label="Давление">
              <AnimatedNumber
                value={holding.pressure}
                format={(v) => toFixed(v, 2)}
              />
              {' кПа'}
            </LabeledList.Item>
            <LabeledList.Item label="Температура">
              {`${toFixed(holding.temperature, 2)} К (${toFixed(
                holding.temperature - T0C,
                1
              )} °C)`}
            </LabeledList.Item>
            <LabeledList.Item label="Содержимое">
              <GasComposition gases={holding.gases} />
            </LabeledList.Item>
          </LabeledList>
        ) : (
          <Box color="average">Баллон не вставлен</Box>
        )}
      </Section>
    </>
  );
};

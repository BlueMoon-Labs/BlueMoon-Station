import { toFixed } from 'common/math';
import { BooleanLike } from 'common/react';

import { useBackend } from '../backend';
import {
  AnimatedNumber,
  Button,
  LabeledList,
  NoticeBox,
  NumberInput,
  ProgressBar,
  Section,
} from '../components';
import { getGasColor, getGasLabel } from '../constants';
import { Window } from '../layouts';

const T0C = 273.15;

type SensorInfo = {
  id_tag: string;
  long_name: string;
  online: BooleanLike;
  pressure?: number;
  temperature?: number;
  gases?: Record<string, number>;
  stale?: BooleanLike;
  age?: string;
};

type AtmosControlData = {
  sensors: SensorInfo[];
  tank?: BooleanLike;
  inputting?: BooleanLike;
  inputRate?: number;
  maxInputRate?: number;
  outputting?: BooleanLike;
  outputPressure?: number | string;
  maxOutputPressure?: number;
};

const SensorPanel = (props: { readonly sensor: SensorInfo }) => {
  const { sensor } = props;
  const gases = Object.entries(sensor.gases || {}).filter(
    ([, percent]) => percent >= 0.01
  );
  if (!sensor.online) {
    return (
      <Section title={sensor.long_name}>
        <NoticeBox danger>Нет связи с сенсором.</NoticeBox>
      </Section>
    );
  }
  return (
    <Section title={sensor.long_name}>
      {!!sensor.stale && (
        <NoticeBox warning>
          Показания устарели{sensor.age ? `: последний отчёт ${sensor.age} назад` : ''}.
        </NoticeBox>
      )}
      <LabeledList>
        <LabeledList.Item label="Давление">
          <AnimatedNumber
            value={sensor.pressure}
            format={(value) => toFixed(value, 2)}
          />
          {' кПа'}
        </LabeledList.Item>
        {!!sensor.temperature && (
          <LabeledList.Item label="Температура">
            <AnimatedNumber
              value={sensor.temperature}
              format={(value) => toFixed(value, 2)}
            />
            {` К (${toFixed(sensor.temperature - T0C, 1)} °C)`}
          </LabeledList.Item>
        )}
        {gases.length === 0 ? (
          <LabeledList.Item label="Состав" color="label">
            Пусто
          </LabeledList.Item>
        ) : (
          gases.map(([gasName, percent]) => (
            <LabeledList.Item
              key={gasName}
              label={getGasLabel(gasName, gasName)}
              labelColor={getGasColor(gasName) || 'label'}>
              <ProgressBar
                value={percent}
                minValue={0}
                maxValue={100}
                color={getGasColor(gasName) || 'default'}>
                {`${toFixed(percent, 2)} %`}
              </ProgressBar>
            </LabeledList.Item>
          ))
        )}
      </LabeledList>
    </Section>
  );
};

const TankControls = () => {
  const { act, data } = useBackend<AtmosControlData>();
  return (
    <Section
      title="Управление"
      buttons={
        <Button
          icon="undo"
          content="Переподключить"
          tooltip="Заново найти инжектор и выпускной вент этого бака"
          onClick={() => act('reconnect')}
        />
      }>
      <LabeledList>
        <LabeledList.Item label="Инжектор подачи">
          <Button
            icon={data.inputting ? 'power-off' : 'times'}
            content={data.inputting ? 'Качает' : 'Выключен'}
            selected={data.inputting}
            onClick={() => act('input')}
          />
        </LabeledList.Item>
        <LabeledList.Item label="Скорость подачи">
          <NumberInput
            value={data.inputRate}
            unit="л/с"
            width="70px"
            minValue={0}
            maxValue={data.maxInputRate}
            // Команда уходит по радио и возвращается с задержкой,
            // поэтому подавляем мерцание значения.
            suppressFlicker={2000}
            onChange={(_event, value) => act('rate', { rate: value })}
          />
        </LabeledList.Item>
        <LabeledList.Item label="Выпускной вент">
          <Button
            icon={data.outputting ? 'power-off' : 'times'}
            content={data.outputting ? 'Открыт' : 'Закрыт'}
            selected={data.outputting}
            onClick={() => act('output')}
          />
        </LabeledList.Item>
        <LabeledList.Item label="Давление выхода">
          <NumberInput
            value={parseFloat(String(data.outputPressure))}
            unit="кПа"
            width="82px"
            minValue={0}
            maxValue={data.maxOutputPressure}
            step={10}
            suppressFlicker={2000}
            onChange={(_event, value) => act('pressure', { pressure: value })}
          />
        </LabeledList.Item>
      </LabeledList>
    </Section>
  );
};

export const AtmosControlConsole = () => {
  const { act, data } = useBackend<AtmosControlData>();
  const sensors = data.sensors || [];
  return (
    <Window width={540} height={430}>
      <Window.Content scrollable>
        {/* Точка входа в справочник. Консоль - первое, куда смотрит инженер в
            начале смены, а до этого справочник открывался только из приложения
            на КПК и попадался на глаза лишь тому, кто знал, что он есть. */}
        <Section
          title="Мониторинг атмосферики"
          buttons={
            <Button
              icon="book"
              content="Справочник"
              tooltip="Газы, реакции, инструменты и правила по давлению в трубах"
              onClick={() => act('handbook')}
            />
          }
        />
        {sensors.length === 0 ? (
          <NoticeBox danger>Сенсоры не подключены.</NoticeBox>
        ) : (
          sensors.map((sensor) => (
            <SensorPanel key={sensor.id_tag} sensor={sensor} />
          ))
        )}
        {!!data.tank && <TankControls />}
      </Window.Content>
    </Window>
  );
};

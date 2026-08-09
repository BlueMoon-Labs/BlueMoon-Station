import { toFixed } from 'common/math';

import { useBackend } from '../../backend';
import { Box, LabeledList, NoticeBox, ProgressBar, Section } from '../../components';
import {
  barRange,
  DANGER_COLOR,
  DANGER_TEXT,
  describeBreach,
  envColor,
  localizeEnvName,
  localizeUnit,
} from './helpers';
import { AirAlarmData, EnvironmentEntry } from './types';

const T0C = 273.15;

/** Что показать в теле полосы: у газов - и процент, и парциальное давление. */
const readout = (entry: EnvironmentEntry): string => {
  if (entry.id === 'temperature') {
    return `${toFixed(entry.value, 2)} К (${toFixed(entry.value - T0C, 1)} °C)`;
  }
  const shown = `${toFixed(entry.value, 2)} ${localizeUnit(entry.unit)}`;
  if (entry.partial_pressure === undefined) {
    return shown;
  }
  return `${shown} (${toFixed(entry.partial_pressure, 2)} кПа)`;
};

export const AirAlarmStatus = () => {
  const { data } = useBackend<AirAlarmData>();
  const { danger_level, atmos_alarm, fire_alarm, emagged } = data;
  // Следы газов ниже сотой доли процента только зашумляют список.
  const entries = (data.environment_data || []).filter(
    (entry) => entry.value >= 0.01
  );
  return (
    <Section title="Состояние воздуха">
      {entries.length === 0 ? (
        <NoticeBox danger>Не удаётся взять пробу воздуха.</NoticeBox>
      ) : (
        <LabeledList>
          {entries.map((entry) => {
            const [minValue, maxValue] = barRange(entry);
            const breach = describeBreach(entry);
            return (
              <LabeledList.Item
                key={entry.id}
                label={localizeEnvName(entry.id, entry.name)}
                labelColor={envColor(entry.id) || 'label'}>
                <ProgressBar
                  value={entry.value}
                  minValue={minValue}
                  maxValue={maxValue}
                  color={DANGER_COLOR[entry.danger_level] || 'good'}>
                  {readout(entry)}
                </ProgressBar>
                {breach && (
                  <Box
                    mt={0.5}
                    fontSize="0.9rem"
                    color={DANGER_COLOR[entry.danger_level]}>
                    {breach}
                  </Box>
                )}
              </LabeledList.Item>
            );
          })}
          <LabeledList.Item
            label="Локальный статус"
            color={DANGER_COLOR[danger_level] || 'good'}>
            {DANGER_TEXT[danger_level] || DANGER_TEXT[0]}
          </LabeledList.Item>
          <LabeledList.Item
            label="Статус зоны"
            color={atmos_alarm || fire_alarm ? 'bad' : 'good'}>
            {(atmos_alarm && 'Атмосферная тревога') ||
              (fire_alarm && 'Пожарная тревога') ||
              'Спокойно'}
          </LabeledList.Item>
        </LabeledList>
      )}
      {!!emagged && (
        <NoticeBox danger mt={1}>
          Предохранители отключены. Поведение устройства непредсказуемо.
        </NoticeBox>
      )}
    </Section>
  );
};

import './Mecha.scss';

import { useState } from 'react';

import { useBackend } from '../../backend';
import {
  Box,
  Button,
  LabeledList,
  ProgressBar,
  Section,
  Stack,
} from '../../components';
import { Window } from '../../layouts';
import { AlertPane } from './AlertPane';
import type { MainData } from './data';
import { useHonk } from './honk';
import { ManipulatorPane, ModulesPane } from './ModulesPane';

export const Mecha = () => {
  const { act, data } = useBackend<MainData>();
  const [selected, setSelected] = useState<string | null>(null);
  const [tab, setTab] = useState(0);
  const selectModule = (ref: string) => {
    setSelected(ref);
    setTab(0);
  };
  const settingsReason = !data.can_settings ? 'С этого места нельзя управлять настройками меха.' : null;
  const honk = useHonk(data.ui_honked ? 0.4 : 0);
  const powerRatio = data.power_max ? (data.power_level ?? 0) / data.power_max : 0;
  const pressureHazard = data.cabin_pressure < data.cabin_pressure_hazard_min
    || data.cabin_pressure > data.cabin_pressure_hazard_max;
  const pressureWarning = data.cabin_pressure < data.cabin_pressure_warning_min
    || data.cabin_pressure > data.cabin_pressure_warning_max;
  const tempWarning = data.cabin_temp < data.cabin_temp_warning_min
    || data.cabin_temp > data.cabin_temp_warning_max;
  return (
    <Window width={1000} height={720} theme={data.ui_theme}>
      <Window.Content className="Mecha">
        <Stack fill>
          <Stack.Item width="260px" shrink={0}>
            <Stack vertical fill>
              <Stack.Item grow>
                <Section
                  fill
                  className="Mecha__chassis"
                  title={data.name}
                  buttons={(
                    <>
                      <Button
                        icon="palette"
                        tooltip="Выбрать тему"
                        onClick={() => act('theme')} />
                      <Button
                        icon="edit"
                        tooltip={settingsReason || 'Переименовать'}
                        disabled={!data.can_settings}
                        onClick={() => act('changename')} />
                    </>
                  )}>
                  <Box height="96px" textAlign="center" mb={1}>
                    <img
                      alt={data.name}
                      src={`data:image/png;base64,${data.mech_image}`}
                      style={{
                        width: '100%',
                        height: '100%',
                        objectFit: 'contain',
                        imageRendering: 'pixelated',
                      }} />
                  </Box>
                  <ManipulatorPane onSelect={selectModule} />
                  <LabeledList>
                    <LabeledList.Item label={honk('Состояние')}>
                      <ProgressBar
                        className="Mecha__statusBar"
                        value={data.integrity_max ? data.integrity / data.integrity_max : 0}
                        ranges={{
                          bad: [-Infinity, 0.3],
                          average: [0.3, 0.7],
                          good: [0.7, Infinity],
                        }}>
                        {data.integrity} / {data.integrity_max}
                      </ProgressBar>
                    </LabeledList.Item>
                    <LabeledList.Item label={honk('Энергия')}>
                      <ProgressBar
                        className="Mecha__statusBar"
                        value={powerRatio}
                        ranges={{
                          bad: [-Infinity, 0.2],
                          average: [0.2, 0.6],
                          good: [0.6, Infinity],
                        }}>
                        {data.power_max === null ? 'Нет батареи' : `${Math.round(powerRatio * 100)}%`}
                      </ProgressBar>
                    </LabeledList.Item>
                    <LabeledList.Item label={honk('Свет')}>
                      <Button
                        icon="lightbulb"
                        content={honk(data.lights ? 'Вкл' : 'Выкл')}
                        selected={data.lights}
                        disabled={!data.can_settings || !data.has_lights}
                        tooltip={settingsReason || (!data.has_lights ? 'Осветители отсутствуют или уничтожены.' : undefined)}
                        onClick={() => act('toggle_lights')} />
                    </LabeledList.Item>
                    <LabeledList.Item label={honk('Воздух')}>
                      <Button
                        icon={data.use_internal_tank ? 'lungs' : 'wind'}
                        content={honk(data.use_internal_tank ? 'Баллон' : 'Атмосфера')}
                        selected={data.use_internal_tank}
                        disabled={!data.can_settings || !data.has_tank}
                        tooltip={settingsReason || (!data.has_tank ? 'Внутренний баллон не установлен.' : undefined)}
                        onClick={() => act('toggle_internal_tank')} />
                    </LabeledList.Item>
                    <LabeledList.Item label="Кабина">
                      <Box color={pressureHazard ? 'bad' : pressureWarning ? 'average' : 'good'}>
                        {data.cabin_pressure} кПа <Box inline color={tempWarning ? 'average' : 'label'}>· {data.cabin_temp} °C</Box>
                      </Box>
                    </LabeledList.Item>
                    <LabeledList.Item label="ДНК-блокировка">
                      <Button
                        icon="syringe"
                        content={data.dna_lock ? 'Установлена' : 'Установить'}
                        selected={!!data.dna_lock}
                        disabled={!data.can_settings || !!data.dna_lock || !data.can_dna_lock}
                        tooltip={settingsReason || (data.dna_lock ? 'ДНК-блокировка уже установлена.' : !data.can_dna_lock ? 'У пилота нет подходящего образца ДНК.' : undefined)}
                        onClick={() => act('dna_lock')} />
                      {!!data.dna_lock && (
                        <Button
                          icon="unlock"
                          content="Снять"
                          tooltip={settingsReason || `Снять блокировку: ${data.dna_lock_name || data.dna_lock}`}
                          disabled={!data.can_settings}
                          onClick={() => act('reset_dna')} />
                      )}
                    </LabeledList.Item>
                    <LabeledList.Item label="Техобслуживание">
                      <Button
                        icon="wrench"
                        selected={data.maint_access}
                        content={data.maint_access ? 'Разрешено' : 'Запрещено'}
                        disabled={!data.can_settings || data.maintenance}
                        tooltip={settingsReason || (data.maintenance ? 'Сначала завершите активный протокол техобслуживания.' : undefined)}
                        onClick={() => act('toggle_maint_access')} />
                      {!!data.maintenance && (
                        <Box color="average">Включён протокол обслуживания</Box>
                      )}
                    </LabeledList.Item>
                  </LabeledList>
                </Section>
              </Stack.Item>
              <Stack.Item><AlertPane /></Stack.Item>
            </Stack>
          </Stack.Item>
          <Stack.Item grow minWidth="0px">
            <ModulesPane selected={selected} onSelect={selectModule} tab={tab} onTabChange={setTab} />
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

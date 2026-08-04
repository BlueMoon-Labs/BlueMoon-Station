import { filter, sortBy } from 'common/collections';
import { flow } from 'common/fp';
import { toFixed } from 'common/math';

import { useBackend } from '../backend';
import { Box, Button, LabeledList, NumberInput, ProgressBar, Section, Slider, Stack } from '../components';
import { getGasColor, getGasLabel } from '../constants';
import { formatSiBaseTenUnit, formatSiUnit } from '../format';
import { Window } from '../layouts';

/**
 * Потолок шкалы газа синтеза приходит из ui_static_data() полем
 * base_max_temperature (hfr_parts.dm:204 = FUSION_MAXIMUM_TEMPERATURE,
 * code/__DEFINES/reactions.dm:47). Это значение здесь только на случай
 * первой отрисовки, пока статика ещё не приехала.
 */
const FALLBACK_MAX_FUSION_TEMPERATURE = 1e8;

/**
 * Модератор, выход и хладагент греются не напрямую, а теплообменом от газа
 * синтеза (hfr_main_processes.dm:481-501), и их рабочие температуры на
 * порядки ниже. Потолок 1e8 держал эти три полосы в нуле всегда.
 * Берём 1e7 - единственный порог, который DM проверяет по температуре
 * модератора (HFR_ANTINOBLIUM_TEMP_THRESHOLD, _hfr_defines.dm:69,
 * применяется в hfr_main_processes.dm:292). Выход считается как
 * температура модератора * HIGH_EFFICIENCY_CONDUCTIVITY 0.95
 * (hfr_main_processes.dm:328), то есть заведомо ниже; хладагент DM меряет
 * порогом HYPERTORUS_COLD_COOLANT_THRESHOLD = 1e5 (_hfr_defines.dm:175),
 * тоже с запасом внутри.
 */
const MAX_SECONDARY_TEMPERATURE = 1e7;

/**
 * heat_limiter_modifier = 5 * 10^power_level * (heating_conductor * 0.01)
 * (hfr_main_processes.dm:171 на константах HFR_HEAT_LIMITER_BASE = 5 и
 * HFR_MAGNETIC_VOLUME_FRAC = 0.01, _hfr_defines.dm:41 и :99). power_level
 * упирается в 6 (hfr_procs.dm:195-196), heating_conductor - в 500
 * (clamp в hfr_parts.dm:340), значит максимум 5 * 1e6 * 5 = 2.5e7.
 */
const MAX_HEAT_LIMITER_MODIFIER = 2.5e7;

/**
 * energy = energy_modifiers * c^2 * max(T * heat_modifier / 100, 1)
 * (hfr_main_processes.dm:161-163). c^2 собирается из LIGHT_SPEED_SQ_SCALED
 * и LIGHT_SPEED_SQ_SCALE (_hfr_defines.dm:6-9) и равен ~9e16;
 * температурный множитель упирается в FUSION_MAXIMUM_TEMPERATURE 1e8
 * (reactions.dm:47) при heat_modifier на потолке HFR_MODIFIER_CLAMP_MAX 100
 * (_hfr_defines.dm:28, применяется hfr_main_processes.dm:148), то есть в 1e8.
 * При единичных модификаторах это ~9e24, округляем до 1e25. Стоявшее тут
 * 1e35 - это HFR_ENERGY_CLAMP_MAX (_hfr_defines.dm:32-33), который сам
 * подписан "float safety": страховка от переполнения, а не игровой предел.
 */
const MAX_REACTOR_ENERGY = 1e25;

/**
 * Второй аргумент formatSiBaseTenUnit (format.js:146) — это minBase1000,
 * нижняя граница десятичной приставки, а не точность. Единица требовала
 * печатать не мельче тысяч, и всё ниже 500 K схлопывалось в «0 · 10³ K»:
 * подпись переставала отличать комнатные 293 K от настоящего нуля, а это
 * состояние простаивающего или штатно охлаждённого реактора. Ноль разрешает
 * форматтеру остаться в единицах; тысячи и миллионы он подберёт сам.
 */
const TEMPERATURE_MIN_BASE_1000 = 0;

/** Heat output is in K; negative = endothermic cooling. formatSiBaseTenUnit breaks on 0 and negatives. */
const formatHeatOutputKelvin = (kelvin) => {
  if (!Number.isFinite(kelvin)) {
    return '0 K';
  }
  if (kelvin === 0) {
    return '0 K';
  }
  const sign = kelvin > 0 ? '+' : '-';
  return sign + formatSiBaseTenUnit(
    Math.abs(kelvin), TEMPERATURE_MIN_BASE_1000, 'K');
};

export const Hypertorus = (props) => {
  const { act, data } = useBackend();
  const filterTypes = data.filter_types || [];
  const selectableFuels = data.selectable_fuel || [];
  const {
    energy_level,
    core_temperature,
    internal_power,
    power_output,
    heat_limiter_modifier,
    heat_output,
    heating_conductor,
    magnetic_constrictor,
    fuel_injection_rate,
    moderator_injection_rate,
    current_damper,
    power_level,
    iron_content,
    integrity,
    start_power,
    start_cooling,
    start_fuel,
    start_moderator,
    internal_fusion_temperature,
    moderator_internal_temperature,
    internal_output_temperature,
    internal_coolant_temperature,
    waste_remove,
    selected,
    product_gases,
    cooling_volume,
    mod_filtering_rate,
    heat_output_min,
    heat_output_max,
    base_max_temperature,
  } = data;
  const maxFusionTemperature = Number.isFinite(base_max_temperature)
    && base_max_temperature > 0
    ? base_max_temperature
    : FALLBACK_MAX_FUSION_TEMPERATURE;
  // heat_output приходит из hfr_parts.dm:276 сырым Кельвином: обёртка
  // HFR_SANITIZE_HEAT (_hfr_defines.dm:45) для валидных чисел тождественна,
  // так что домножать его на тысячу здесь было нечем оправдать.
  const safeHeatOutput = Number.isFinite(heat_output) ? heat_output : 0;
  const heatLimitMin = Number.isFinite(heat_output_min) ? heat_output_min : -1;
  const heatLimitMax = Number.isFinite(heat_output_max) && heat_output_max !== 0
    ? heat_output_max
    : 1;
  const heatDenom = safeHeatOutput < 0 ? heatLimitMin : heatLimitMax;
  const heatActivity = heatDenom !== 0 ? safeHeatOutput / heatDenom : 0;
  const safeHeatActivity = Number.isFinite(heatActivity) ? heatActivity : 0;
  const fusion_gases = flow([
    filter(gas => gas.amount >= 0.01),
    sortBy(gas => -gas.amount),
  ])(data.fusion_gases || []);
  const moderator_gases = flow([
    filter(gas => gas.amount >= 0.01),
    sortBy(gas => -gas.amount),
  ])(data.moderator_gases || []);
  const fusionMax = Math.max(1, ...fusion_gases.map(gas => gas.amount));
  const moderatorMax = Math.max(1, ...moderator_gases.map(gas => gas.amount));
  return (
    <Window
      title="Fusion Reactor"
      width={500}
      height={600}>
      <Window.Content overflow="auto">
        <Section title="Switches">
          <Stack>
            <Stack.Item color="label">
              {'Start power: '}
              <Button
                disabled={data.power_level > 0}
                icon={data.start_power ? 'power-off' : 'times'}
                content={data.start_power ? 'On' : 'Off'}
                selected={data.start_power}
                onClick={() => act('start_power')} />
            </Stack.Item>
            <Stack.Item color="label">
              {'Start cooling: '}
              <Button
                disabled={start_fuel === 1
                  || start_moderator === 1
                  || start_power === 0
                  || (start_cooling && data.power_level > 0)}
                icon={data.start_cooling ? 'power-off' : 'times'}
                content={data.start_cooling ? 'On' : 'Off'}
                selected={data.start_cooling}
                onClick={() => act('start_cooling')} />
            </Stack.Item>
            <Stack.Item color="label">
              {'Start fuel injection: '}
              <Button
                disabled={start_power === 0
                  || start_cooling === 0}
                icon={data.start_fuel ? 'power-off' : 'times'}
                content={data.start_fuel ? 'On' : 'Off'}
                selected={data.start_fuel}
                onClick={() => act('start_fuel')} />
            </Stack.Item>
          </Stack>
        </Section>
        <Section title="Reaction">
          <LabeledList>
            <LabeledList.Item label="Fuel">
              {selectableFuels.map(recipe => (
                <Button
                  disabled={data.power_level > 0}
                  key={recipe.id ?? 'nothing'}
                  selected={(recipe.id === selected)
                    || (selected === null && recipe.id === null)}
                  content={recipe.name}
                  onClick={() => act('fuel', {
                    mode: recipe.id,
                  })} />
              ))}
            </LabeledList.Item>
            <LabeledList.Item label="Gases">
              <Box m={1} style={{
                whiteSpace: 'pre-wrap',
              }}>
                {product_gases ?? 'None'}
              </Box>
            </LabeledList.Item>
          </LabeledList>
        </Section>
        <Section title="Internal Fusion Gases">
          <LabeledList>
            {fusion_gases.map(gas => (
              <LabeledList.Item
                key={gas.id}
                label={getGasLabel(gas.id)}>
                <ProgressBar
                  color={getGasColor(gas.id)}
                  value={gas.amount}
                  minValue={0}
                  maxValue={fusionMax}>
                  {toFixed(gas.amount, 2) + ' moles'}
                </ProgressBar>
              </LabeledList.Item>
            ))}
          </LabeledList>
        </Section>
        <Section title="Moderator Gases">
          <LabeledList>
            <LabeledList.Item label="Moderator injection">
              <Button
                disabled={start_power === 0 || start_cooling === 0}
                icon={start_moderator ? 'power-off' : 'times'}
                content={start_moderator ? 'On' : 'Off'}
                selected={start_moderator}
                onClick={() => act('start_moderator')} />
              <NumberInput
                animated
                value={parseFloat(moderator_injection_rate)}
                width="63px"
                unit="mol/s"
                minValue={5}
                maxValue={1500}
                onDrag={(e, value) => act('moderator_injection_rate', {
                  moderator_injection_rate: value,
                })} />
            </LabeledList.Item>
            {moderator_gases.map(gas => (
              <LabeledList.Item
                key={gas.id}
                label={getGasLabel(gas.id)}>
                <ProgressBar
                  color={getGasColor(gas.id)}
                  value={gas.amount}
                  minValue={0}
                  maxValue={moderatorMax}>
                  {toFixed(gas.amount, 2) + ' moles'}
                </ProgressBar>
              </LabeledList.Item>
            ))}
          </LabeledList>
        </Section>
        <Section title="Reactor Parameters">
          <LabeledList>
            <LabeledList.Item label="Power Level">
              <ProgressBar
                value={power_level}
                ranges={{
                  good: [0, 2],
                  average: [2, 4],
                  bad: [4, 6],
                }} />
            </LabeledList.Item>
            <LabeledList.Item label="Integrity">
              <ProgressBar
                value={integrity / 100}
                ranges={{
                  good: [0.90, Infinity],
                  average: [0.5, 0.90],
                  bad: [-Infinity, 0.5],
                }} />
            </LabeledList.Item>
            <LabeledList.Item label="Iron Content">
              <ProgressBar
                value={iron_content}
                ranges={{
                  good: [-Infinity, 3],
                  average: [3, 6],
                  bad: [6, Infinity],
                }} />
            </LabeledList.Item>
            <LabeledList.Item label="Energy Levels">
              <ProgressBar
                color={'yellow'}
                value={energy_level}
                minValue={0}
                maxValue={MAX_REACTOR_ENERGY}>
                {formatSiUnit(energy_level, 1, 'J')}
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Heat Limiter Modifier">
              <ProgressBar
                color={'blue'}
                value={heat_limiter_modifier}
                minValue={0}
                maxValue={MAX_HEAT_LIMITER_MODIFIER}>
                {formatSiBaseTenUnit(
                  heat_limiter_modifier, TEMPERATURE_MIN_BASE_1000, 'K')}
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Heat Output">
              <ProgressBar
                color={'grey'}
                value={safeHeatActivity}
                minValue={-1}
                maxValue={1.3}>
                {formatHeatOutputKelvin(safeHeatOutput)}
              </ProgressBar>
            </LabeledList.Item>
          </LabeledList>
        </Section>
        <Section title="Temperatures">
          <LabeledList>
            <LabeledList.Item label="Fusion gas temperature">
              <ProgressBar
                color={'yellow'}
                value={internal_fusion_temperature}
                minValue={0}
                maxValue={maxFusionTemperature}>
                {formatSiBaseTenUnit(
                  internal_fusion_temperature, TEMPERATURE_MIN_BASE_1000, 'K')}
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Moderator gas temperature">
              <ProgressBar
                color={'red'}
                value={moderator_internal_temperature}
                minValue={0}
                maxValue={MAX_SECONDARY_TEMPERATURE}>
                {formatSiBaseTenUnit(
                  moderator_internal_temperature, TEMPERATURE_MIN_BASE_1000, 'K')}
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Output gas temperature">
              <ProgressBar
                color={'pink'}
                value={internal_output_temperature}
                minValue={0}
                maxValue={MAX_SECONDARY_TEMPERATURE}>
                {formatSiBaseTenUnit(
                  internal_output_temperature, TEMPERATURE_MIN_BASE_1000, 'K')}
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Coolant output temperature">
              <ProgressBar
                color={'green'}
                value={internal_coolant_temperature}
                minValue={0}
                maxValue={MAX_SECONDARY_TEMPERATURE}>
                {formatSiBaseTenUnit(
                  internal_coolant_temperature, TEMPERATURE_MIN_BASE_1000, 'K')}
              </ProgressBar>
            </LabeledList.Item>
          </LabeledList>
        </Section>
        <Section title="Tweakable Inputs">
          <LabeledList>
            <LabeledList.Item label="Heating Conductor">
              <NumberInput
                animated
                value={parseFloat(data.heating_conductor)}
                width="63px"
                unit="J/cm"
                minValue={50}
                maxValue={500}
                onDrag={(e, value) => act('heating_conductor', {
                  heating_conductor: value,
                })} />
            </LabeledList.Item>
            <LabeledList.Item label="Magnetic Constrictor">
              <NumberInput
                animated
                value={parseFloat(data.magnetic_constrictor)}
                width="63px"
                unit="m^3/B"
                minValue={50}
                maxValue={1000}
                onDrag={(e, value) => act('magnetic_constrictor', {
                  magnetic_constrictor: value,
                })} />
            </LabeledList.Item>
            <LabeledList.Item label="Fuel Injection Rate">
              <NumberInput
                animated
                value={parseFloat(data.fuel_injection_rate)}
                width="63px"
                unit="mol/s"
                minValue={5}
                maxValue={1500}
                onDrag={(e, value) => act('fuel_injection_rate', {
                  fuel_injection_rate: value,
                })} />
            </LabeledList.Item>
            <LabeledList.Item label="Current Damper">
              <NumberInput
                animated
                value={parseFloat(data.current_damper)}
                width="63px"
                unit="W"
                minValue={0}
                maxValue={1000}
                onDrag={(e, value) => act('current_damper', {
                  current_damper: value,
                })} />
            </LabeledList.Item>
            <LabeledList.Item label="Cooling Volume">
              <NumberInput
                animated
                value={parseFloat(cooling_volume)}
                width="63px"
                unit="L"
                minValue={50}
                maxValue={2000}
                step={25}
                onDrag={(e, value) => act('cooling_volume', {
                  cooling_volume: value,
                })} />
            </LabeledList.Item>
          </LabeledList>
        </Section>
        <Section>
          <LabeledList>
            <LabeledList.Item label="Waste remove">
              <Button
                disabled={data.power_level > 5}
                icon={data.waste_remove ? 'power-off' : 'times'}
                content={data.waste_remove ? 'On' : 'Off'}
                selected={data.waste_remove}
                onClick={() => act('waste_remove')} />
            </LabeledList.Item>
            <LabeledList.Item label="Moderator filtering rate">
              <Slider
                value={mod_filtering_rate}
                minValue={5}
                maxValue={200}
                step={1}
                stepPixelSize={6}
                onDrag={(e, value) => act('mod_filtering_rate', {
                  mod_filtering_rate: value,
                })}>
                {mod_filtering_rate + ' mol/s'}
              </Slider>
            </LabeledList.Item>
            <LabeledList.Item label="Filter from moderator mix">
              {filterTypes.map(filter => (
                <Button
                  key={filter.gas_id}
                  selected={filter.enabled}
                  content={getGasLabel(filter.gas_id, filter.gas_name)}
                  onClick={() => act('filter', {
                    mode: filter.gas_id,
                  })} />
              ))}
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Window.Content>
    </Window>
  );
};

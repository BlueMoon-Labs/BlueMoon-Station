/**
 * Подписи температур гиперторуса завышались ровно в 1000 раз: значение
 * умножалось на 1000 перед formatSiBaseTenUnit, который сам подбирает
 * десятичную приставку. DM шлёт сырой Кельвин (hfr_procs.dm:174 берёт
 * return_temperature(), hfr_parts.dm:295-298 кладёт его в ui_data как есть),
 * поэтому реактор на 5000 K подписывался как 5 · 10⁶ K.
 *
 * Заодно тест закрепляет потолки шкал: у каждой из них он свой и выведен из
 * DM-кода, а не выбран на глаз.
 */
import { render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { Hypertorus } from './Hypertorus';

const setupStore = (data = {}) => {
  // Window.componentDidMount calls Byond.winset; stub the BYOND bridge.
  (global as any).Byond = { winset: () => {}, topic: () => {} };
  const store = createStore(
    combineReducers({ backend: backendReducer, debug: debugReducer }),
  );
  setGlobalStore(store);
  store.dispatch(
    backendUpdate({
      config: { interface: 'Hypertorus' },
      data: {
        // ui_static_data(), hfr_parts.dm:204 = FUSION_MAXIMUM_TEMPERATURE.
        base_max_temperature: 1e8,
        selectable_fuel: [{ name: 'Nothing', id: null }],
        filter_types: [],
        fusion_gases: [],
        moderator_gases: [],
        selected: null,
        product_gases: 'None',
        power_level: 0,
        integrity: 100,
        iron_content: 0,
        energy_level: 0,
        heat_limiter_modifier: 0,
        heat_output: 0,
        heat_output_min: -1,
        heat_output_max: 1,
        internal_fusion_temperature: 0,
        moderator_internal_temperature: 0,
        internal_output_temperature: 0,
        internal_coolant_temperature: 0,
        heating_conductor: 100,
        magnetic_constrictor: 100,
        fuel_injection_rate: 200,
        moderator_injection_rate: 500,
        current_damper: 0,
        cooling_volume: 1000,
        mod_filtering_rate: 50,
        start_power: 0,
        start_cooling: 0,
        start_fuel: 0,
        start_moderator: 0,
        waste_remove: 0,
        ...data,
      },
    }),
  );
  return store;
};

// Строка LabeledList ищется по подписи в первой ячейке, полоса берётся из
// второй: искать по всему документу нельзя, подписи вроде «5 · 10³ K»
// повторяются на нескольких шкалах сразу.
const rowByLabel = (container: HTMLElement, label: string) => {
  const rows = Array.from(container.querySelectorAll('.LabeledList__row'));
  const row = rows.find(
    candidate =>
      candidate.querySelector('.LabeledList__label')?.textContent
      === label + ':',
  );
  if (!row) {
    throw new Error('Не найдена строка «' + label + '»');
  }
  return row as HTMLElement;
};

const barText = (container: HTMLElement, label: string) =>
  rowByLabel(container, label).querySelector('.ProgressBar__content')
    ?.textContent;

// formatSiBaseTenUnit склеивает подпись из значения, приставки и единицы, а на
// низком диапазоне приставка — пробел (format.js:123). В разметке это даёт
// подряд идущие пробелы, которые браузер схлопывает в один; игрок видит
// «293 K». Сравниваем по тому же правилу, иначе тест ловил бы вёрстку, а не
// смысл подписи.
const barLabel = (container: HTMLElement, label: string) =>
  barText(container, label)?.replace(/\s+/g, ' ').trim();

const barFill = (container: HTMLElement, label: string) =>
  (rowByLabel(container, label).querySelector(
    '.ProgressBar__fill',
  ) as HTMLElement).style.width;

const TEMPERATURE_ROWS = [
  ['Fusion gas temperature', 'internal_fusion_temperature'],
  ['Moderator gas temperature', 'moderator_internal_temperature'],
  ['Output gas temperature', 'internal_output_temperature'],
  ['Coolant output temperature', 'internal_coolant_temperature'],
] as const;

describe('Hypertorus temperature readouts', () => {
  test.each(TEMPERATURE_ROWS)(
    'подпись «%s» показывает присланный Кельвин, а не тысячи от него',
    (label, field) => {
      setupStore({ [field]: 5000 });
      const { container } = render(<Hypertorus />);
      // formatSiBaseTenUnit(5000, 0, 'K'); с лишним * 1000 было «5 · 10⁶ K».
      expect(barText(container, label)).toBe('5.00 · 10³ K');
    },
  );

  test('подпись ограничителя тепла тоже не умножается на 1000', () => {
    setupStore({ heat_limiter_modifier: 5e6 });
    const { container } = render(<Hypertorus />);
    // С лишним * 1000 подпись читалась как «5.00 · 10⁹ K».
    expect(barText(container, 'Heat Limiter Modifier')).toBe('5.00 · 10⁶ K');
  });

  // Четыре разных значения одновременно: гарантия, что строки не перепутаны
  // между собой и ни одна не читает чужое поле.
  test('четыре температуры читаются каждая из своего поля', () => {
    setupStore({
      internal_fusion_temperature: 5e3,
      moderator_internal_temperature: 2e6,
      internal_output_temperature: 3e4,
      internal_coolant_temperature: 8e3,
    });
    const { container } = render(<Hypertorus />);
    expect(barText(container, 'Fusion gas temperature')).toBe('5.00 · 10³ K');
    expect(barText(container, 'Moderator gas temperature'))
      .toBe('2.00 · 10⁶ K');
    expect(barText(container, 'Output gas temperature')).toBe('30.0 · 10³ K');
    expect(barText(container, 'Coolant output temperature'))
      .toBe('8.00 · 10³ K');
  });
});

/**
 * Низкий диапазон — состояние простаивающего или штатно охлаждённого
 * реактора, то есть самое частое из всех. Аргумент minBase1000 = 1 требовал
 * от formatSiBaseTenUnit печатать не мельче тысяч, и всё ниже 500 K
 * схлопывалось в «0 · 10³ K»: подпись переставала отличать комнатные 293 K от
 * настоящего нуля. Ноль в этом аргументе разрешает форматтеру остаться в
 * единицах, а тысячи он по-прежнему подберёт сам.
 */
describe('Hypertorus low temperature readouts', () => {
  test.each(TEMPERATURE_ROWS)(
    'подпись «%s» показывает комнатные 293 K, а не ноль тысяч',
    (label, field) => {
      setupStore({ [field]: 293 });
      const { container } = render(<Hypertorus />);
      expect(barLabel(container, label)).toBe('293 K');
    },
  );

  test('ограничитель тепла в низком диапазоне не схлопывается в ноль', () => {
    setupStore({ heat_limiter_modifier: 300 });
    const { container } = render(<Hypertorus />);
    expect(barLabel(container, 'Heat Limiter Modifier')).toBe('300 K');
  });

  // heat_output приходит из hfr_parts.dm:276 сырым: HFR_SANITIZE_HEAT
  // (_hfr_defines.dm:45) для валидных чисел тождественна.
  test('выход тепла в низком диапазоне печатается как есть', () => {
    setupStore({ heat_output: 250, heat_output_max: 1000 });
    const { container } = render(<Hypertorus />);
    expect(barLabel(container, 'Heat Output')).toBe('+250 K');
  });

  test('эндотермический выход тепла сохраняет знак и порядок', () => {
    setupStore({ heat_output: -250, heat_output_min: -1000 });
    const { container } = render(<Hypertorus />);
    expect(barLabel(container, 'Heat Output')).toBe('-250 K');
  });

  test('выход тепла на высоком диапазоне не умножается на 1000', () => {
    setupStore({ heat_output: 5e6, heat_output_max: 1e7 });
    const { container } = render(<Hypertorus />);
    expect(barLabel(container, 'Heat Output')).toBe('+5.00 · 10⁶ K');
  });

  // Верхний диапазон обязан пережить смену аргумента: приставку форматтер
  // подбирает сам, менялся только нижний предел.
  test.each(TEMPERATURE_ROWS)(
    'подпись «%s» на высоком диапазоне остаётся в тысячах и миллионах',
    (label, field) => {
      setupStore({ [field]: 5e6 });
      const { container } = render(<Hypertorus />);
      expect(barLabel(container, label)).toBe('5.00 · 10⁶ K');
    },
  );
});

describe('Hypertorus bar ceilings', () => {
  test('шкала газа синтеза берёт потолок из base_max_temperature', () => {
    setupStore({ base_max_temperature: 1e8, internal_fusion_temperature: 5e7 });
    const { container } = render(<Hypertorus />);
    expect(barFill(container, 'Fusion gas temperature')).toBe('50%');
  });

  test('потолок газа синтеза едет за бэкендом, а не захардкожен', () => {
    setupStore({ base_max_temperature: 1e7, internal_fusion_temperature: 5e6 });
    const { container } = render(<Hypertorus />);
    expect(barFill(container, 'Fusion gas temperature')).toBe('50%');
  });

  test('без base_max_temperature шкала откатывается на 1e8', () => {
    setupStore({
      base_max_temperature: undefined,
      internal_fusion_temperature: 5e7,
    });
    const { container } = render(<Hypertorus />);
    expect(barFill(container, 'Fusion gas temperature')).toBe('50%');
  });

  // Модератор, выход и хладагент греются теплообменом от газа синтеза
  // (hfr_main_processes.dm:481-501) и до 1e8 K не доходят никогда. Их потолок
  // 1e7 = HFR_ANTINOBLIUM_TEMP_THRESHOLD (_hfr_defines.dm:69).
  test.each(TEMPERATURE_ROWS.slice(1))(
    'шкала «%s» меряется вторичным потолком 1e7',
    (label, field) => {
      setupStore({ [field]: 5e6 });
      const { container } = render(<Hypertorus />);
      expect(barFill(container, label)).toBe('50%');
    },
  );

  test('вторичный потолок ниже потолка газа синтеза', () => {
    setupStore({
      base_max_temperature: 1e8,
      internal_fusion_temperature: 1e7,
      moderator_internal_temperature: 1e7,
    });
    const { container } = render(<Hypertorus />);
    expect(barFill(container, 'Moderator gas temperature')).toBe('100%');
    expect(barFill(container, 'Fusion gas temperature')).not.toBe('100%');
  });

  // heat_limiter_modifier = 5 * 10^power_level * heating_conductor * 0.01
  // (hfr_main_processes.dm:171), максимум 5 * 1e6 * 5 = 2.5e7.
  test('шкала ограничителя тепла упирается в 2.5e7', () => {
    setupStore({ heat_limiter_modifier: 1.25e7 });
    const { container } = render(<Hypertorus />);
    expect(barFill(container, 'Heat Limiter Modifier')).toBe('50%');
  });

  // energy = energy_modifiers * c^2 * (T * heat_modifier / 100)
  // (hfr_main_processes.dm:161) даёт ~9e24 на потолках DM; 1e35 в шкале был
  // страховкой от переполнения float (HFR_ENERGY_CLAMP_MAX), не пределом игры.
  test('шкала энергии упирается в 1e25, а не в кламп 1e35', () => {
    setupStore({ energy_level: 5e24 });
    const { container } = render(<Hypertorus />);
    expect(barFill(container, 'Energy Levels')).toBe('50%');
  });
});

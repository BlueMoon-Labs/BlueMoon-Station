/**
 * Вся логика окна гиперторуса живёт в чистых функциях, чтобы её можно было
 * проверять без разметки: пороги приходят из DM, и разойтись с ними - значит
 * соврать инженеру о состоянии реактора.
 */
import {
  collectAlerts,
  formatDelta,
  formatHeatOutput,
  formatTemperature,
  gasCountWord,
  getOverfullMoleLimit,
  getPowerLevelProgress,
  getReactorStatus,
  getSelectedFuel,
  getStartupSteps,
  temperatureDelta,
} from './helpers';
import { HypertorusData } from './types';

const baseData = (overrides: Partial<HypertorusData> = {}): HypertorusData =>
  ({
    base_max_temperature: 1e8,
    selectable_fuel: [],
    filter_types: [],
    fusion_gases: [],
    moderator_gases: [],
    selected: null,
    product_gases: 'нет',
    power_level: 0,
    integrity: 100,
    iron_content: 0,
    instability: 0,
    apc_energy: 100,
    energy_level: 0,
    internal_power: 0,
    power_output: 0,
    heat_limiter_modifier: 0,
    heat_output: 0,
    heat_output_min: -1,
    heat_output_max: 1,
    internal_fusion_temperature: 0,
    moderator_internal_temperature: 0,
    internal_output_temperature: 0,
    internal_coolant_temperature: 0,
    internal_fusion_temperature_archived: 0,
    moderator_internal_temperature_archived: 0,
    internal_output_temperature_archived: 0,
    internal_coolant_temperature_archived: 0,
    temperature_period: 2,
    heating_conductor: 100,
    magnetic_constrictor: 100,
    fuel_injection_rate: 200,
    moderator_injection_rate: 500,
    current_damper: 0,
    cooling_volume: 1000,
    waste_remove: 0,
    mod_filtering_rate: 20,
    fusion_moles: 0,
    moderator_moles: 0,
    coolant_moles: 0,
    start_power: 0,
    start_cooling: 0,
    start_fuel: 0,
    start_moderator: 0,
    ...overrides,
  }) as HypertorusData;

describe('форматирование', () => {
  /**
   * Исходный баг: значение умножалось на 1000 перед formatSiBaseTenUnit,
   * который сам подбирает десятичную приставку, и реактор на 5000 K
   * подписывался как 5 · 10⁶ K.
   */
  test('температура печатается в присланных кельвинах', () => {
    expect(formatTemperature(5000)).toBe('5.00 · 10³ K');
  });

  /**
   * Низкий диапазон - состояние простаивающего реактора, то есть самое частое.
   * minBase1000 = 1 схлопывал всё ниже 500 K в «0 · 10³ K», и подпись
   * переставала отличать комнатные 293 K от настоящего нуля.
   */
  test('низкие температуры не схлопываются в ноль тысяч', () => {
    expect(formatTemperature(293).replace(/\s+/g, ' ').trim()).toBe('293 K');
  });

  test('тепловой выход сохраняет знак', () => {
    expect(formatHeatOutput(250).replace(/\s+/g, ' ').trim()).toBe('+250 K');
    expect(formatHeatOutput(-250).replace(/\s+/g, ' ').trim()).toBe('-250 K');
    expect(formatHeatOutput(0)).toBe('0 K');
  });

  test('скорость изменения температуры делится на период замера', () => {
    // 5000 K прироста за такт в 2 секунды - это 2500 K/с.
    expect(temperatureDelta(10000, 5000, 2)).toBe(2500);
  });

  test('нулевой период не даёт бесконечность', () => {
    expect(temperatureDelta(10000, 5000, 0)).toBe(0);
  });

  test('дельта печатается со знаком и десятичной приставкой', () => {
    expect(formatDelta(2500)).toBe('+2.50 · 10³ K/с');
    expect(formatDelta(-12).replace(/\s+/g, ' ').trim()).toBe('-12 K/с');
    expect(formatDelta(0)).toBe('0 K/с');
  });
});

describe('склонение по числу газов', () => {
  test.each([
    [1, 'газ'],
    [2, 'газа'],
    [4, 'газа'],
    [5, 'газов'],
    [11, 'газов'],
    [21, 'газ'],
    [24, 'газа'],
  ])('%s -> %s', (count, expected) => {
    expect(gasCountWord(count)).toBe(expected);
  });
});

describe('состояние реактора', () => {
  test('остановленный реактор', () => {
    expect(getReactorStatus(baseData()).id).toBe('idle');
  });

  test('разогнанный реактор показывает уровень мощности', () => {
    const status = getReactorStatus(baseData({ power_level: 3 }));
    expect(status.id).toBe('active');
    expect(status.label).toBe('УРОВЕНЬ 3');
  });

  // Пороги те же, по которым check_alert() решает, что орать в рацию.
  test.each([
    [40, 'danger'],
    [20, 'emergency'],
    [3, 'melting'],
  ])('целостность %s%% даёт состояние %s', (integrity, expected) => {
    expect(getReactorStatus(baseData({ integrity, power_level: 3 })).id).toBe(
      expected,
    );
  });

  /**
   * DM поднимает warning-тревогу при любой потере целостности, вплоть до 99.9%.
   * В шильдике это читалось бы как поломка на штатно работающей машине, поэтому
   * до порога danger реактор остаётся просто работающим.
   */
  test('царапина на корпусе не превращает шильдик в аварийный', () => {
    const status = getReactorStatus(baseData({ integrity: 96.4, power_level: 3 }));
    expect(status.id).toBe('active');
  });

  test('прогресс до следующего уровня считается между порогами', () => {
    // Уровень 2 занимает диапазон 1e3..1e4, середина - 5500.
    const { progress, next } = getPowerLevelProgress(
      baseData({ power_level: 2, internal_fusion_temperature: 5500 }),
    );
    expect(next).toBe(1e4);
    expect(progress).toBeCloseTo(0.5);
  });

  test('на максимальном уровне расти уже некуда', () => {
    const { progress, next } = getPowerLevelProgress(
      baseData({ power_level: 6, internal_fusion_temperature: 5e7 }),
    );
    expect(progress).toBe(1);
    expect(next).toBe(0);
  });
});

describe('пусковая цепочка', () => {
  test('без питания недоступно всё, кроме питания', () => {
    const steps = getStartupSteps(baseData());
    expect(steps.map((step) => step.disabled)).toEqual([false, true, true, true]);
  });

  test('питание нельзя снять с разогнанного реактора', () => {
    const steps = getStartupSteps(baseData({ start_power: 1, power_level: 2 }));
    expect(steps[0].disabled).toBe(true);
    expect(steps[0].hint).toMatch(/остыв/);
  });

  test('охлаждение не трогают, пока идёт впрыск', () => {
    const steps = getStartupSteps(
      baseData({ start_power: 1, start_cooling: 1, start_fuel: 1 }),
    );
    expect(steps[1].disabled).toBe(true);
    expect(steps[1].hint).toMatch(/перекройте/);
  });

  test('с питанием и охлаждением впрыск открыт', () => {
    const steps = getStartupSteps(baseData({ start_power: 1, start_cooling: 1 }));
    expect(steps[2].disabled).toBe(false);
    expect(steps[3].disabled).toBe(false);
  });
});

describe('предупреждения', () => {
  const idsOf = (data: HypertorusData) =>
    collectAlerts(data).map((alert) => alert.id);

  test('без рецепта окно так и говорит', () => {
    expect(idsOf(baseData())).toContain('no-recipe');
  });

  test('перегруз камеры ловится по порогу 5000 молей', () => {
    expect(idsOf(baseData({ fusion_moles: 5001 }))).toContain('overmole');
    expect(idsOf(baseData({ fusion_moles: 4999 }))).not.toContain('overmole');
  });

  test('гиперкритическая масса вытесняет обычный перегруз', () => {
    const ids = idsOf(baseData({ fusion_moles: 10001 }));
    expect(ids).toContain('hypercritical');
    expect(ids).not.toContain('overmole');
  });

  /**
   * round() в DM - это floor, поэтому (round(iron_content) - 1) начинает
   * бить по целостности только с двойки, а не с 1.5.
   */
  test('железо жалуется с порога урона, а не раньше', () => {
    expect(idsOf(baseData({ iron_content: 2, power_level: 5 }))).toContain(
      'iron-damage',
    );
    const growing = idsOf(baseData({ iron_content: 1.5, power_level: 5 }));
    expect(growing).toContain('iron-growth');
    expect(growing).not.toContain('iron-damage');
  });

  test('на уровне 4 и ниже железо не растёт и жалобы нет', () => {
    expect(idsOf(baseData({ iron_content: 1.5, power_level: 4 }))).not.toContain(
      'iron-growth',
    );
  });

  test('нехватка топлива считается по каждому газу рецепта', () => {
    const data = baseData({
      selected: 'nitrogen_cracking',
      start_fuel: 1,
      selectable_fuel: [
        {
          id: 'nitrogen_cracking',
          name: 'Расщепление азота',
          requirements: ['hydrogen', 'nitrogen'],
        },
      ],
      fusion_gases: [
        { id: 'hydrogen', amount: 500 },
        { id: 'nitrogen', amount: 10 },
      ],
      fusion_moles: 510,
    });
    const alert = collectAlerts(data).find((entry) => entry.id === 'missing-fuel');
    expect(alert).toBeDefined();
    // Жалуемся ровно на тот газ, которого мало, а не на весь рецепт.
    expect(alert?.text).not.toMatch(/[Вв]одород/);
  });

  test('полный бак топлива не вызывает жалоб на нехватку', () => {
    const data = baseData({
      selected: 'nitrogen_cracking',
      start_fuel: 1,
      selectable_fuel: [
        {
          id: 'nitrogen_cracking',
          name: 'Расщепление азота',
          requirements: ['hydrogen', 'nitrogen'],
        },
      ],
      fusion_gases: [
        { id: 'hydrogen', amount: 500 },
        { id: 'nitrogen', amount: 500 },
      ],
      fusion_moles: 1000,
    });
    expect(idsOf(data)).not.toContain('missing-fuel');
  });

  test('пустой контур охлаждения виден сразу', () => {
    expect(idsOf(baseData({ start_cooling: 1, coolant_moles: 0 }))).toContain(
      'no-coolant',
    );
  });

  test('севшее ОРУ предупреждает только при поданном питании', () => {
    expect(idsOf(baseData({ apc_energy: 5, start_power: 1 }))).toContain('apc');
    expect(idsOf(baseData({ apc_energy: 5 }))).not.toContain('apc');
  });

  test('лёгкий износ на рабочей мощности не поднимает шум', () => {
    // На уровне 4 и ниже корпус чинится сам - напоминать не о чем.
    expect(idsOf(baseData({ integrity: 96.4, power_level: 3 }))).not.toContain(
      'integrity',
    );
  });

  test('на высокой мощности износ объясняет, почему корпус не чинится', () => {
    expect(idsOf(baseData({ integrity: 96.4, power_level: 5 }))).toContain(
      'integrity',
    );
  });

  test('штатный режим не выдумывает претензий', () => {
    const data = baseData({
      selected: 'nitrogen_cracking',
      selectable_fuel: [
        {
          id: 'nitrogen_cracking',
          name: 'Расщепление азота',
          requirements: ['hydrogen', 'nitrogen'],
        },
      ],
      power_level: 3,
      fusion_moles: 2000,
      coolant_moles: 500,
      internal_coolant_temperature: 300,
    });
    expect(collectAlerts(data)).toHaveLength(0);
  });
});

describe('предел молей по температуре', () => {
  /**
   * DM интерполирует безопасную массу линейно между «холодным» пределом 2700
   * и «горячим» 1800 по температуре газа синтеза.
   */
  test('на холодной камере предел равен холодному', () => {
    expect(getOverfullMoleLimit(baseData())).toBeCloseTo(2700);
  });

  test('на максимальной температуре предел равен горячему', () => {
    expect(
      getOverfullMoleLimit(baseData({ internal_fusion_temperature: 1e8 })),
    ).toBeCloseTo(1800);
  });

  test('переполнение проверяется только с пятого уровня мощности', () => {
    const ids = (power_level: number) =>
      collectAlerts(
        baseData({ power_level, fusion_moles: 3000, internal_fusion_temperature: 1e7 }),
      ).map((alert) => alert.id);
    expect(ids(4)).not.toContain('overfull');
    expect(ids(5)).toContain('overfull');
  });
});

describe('выбор рецепта', () => {
  test('пустой рецепт не считается выбранным', () => {
    const data = baseData({
      selected: null,
      selectable_fuel: [{ id: null, name: 'Nothing' }],
    });
    expect(getSelectedFuel(data)).toBeUndefined();
  });
});

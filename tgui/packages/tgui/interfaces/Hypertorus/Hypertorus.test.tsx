/**
 * Разметка окна проверяется точечно: логика живёт в helpers.test.ts, здесь
 * важно, что окно собирается и что подписи шкал не врут о порядке величины.
 * Исходный баг: температуры умножались на 1000 перед forматтером, и реактор
 * на 5000 K подписывался как 5 · 10⁶ K.
 */
import { fireEvent, render, screen } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../../backend';
import { debugReducer } from '../../debug';
import { Hypertorus } from '.';

const setupStore = (data = {}) => {
  // Window.componentDidMount зовёт Byond.winset; подменяем мост в BYOND.
  (global as any).Byond = { winset: () => {}, topic: () => {} };
  const store = createStore(
    combineReducers({ backend: backendReducer, debug: debugReducer }),
  );
  setGlobalStore(store);
  store.dispatch(
    backendUpdate({
      config: { interface: 'Hypertorus' },
      data: {
        base_max_temperature: 1e8,
        selectable_fuel: [
          {
            id: 'nitrogen_cracking',
            name: 'Расщепление азота',
            requirements: ['hydrogen', 'nitrogen'],
            fusion_byproducts: ['helium'],
            product_gases: ['bz'],
            recipe_cooling_multiplier: 1,
            recipe_heating_multiplier: 1,
            energy_loss_multiplier: 1,
            fuel_consumption_multiplier: 1,
            gas_production_multiplier: 1,
            temperature_multiplier: 1,
          },
        ],
        filter_types: [{ gas_id: 'helium', gas_name: 'Helium', enabled: 1 }],
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
        ...data,
      },
    }),
  );
  return store;
};

const metricByLabel = (container: HTMLElement, label: string) => {
  const metrics = Array.from(
    container.querySelectorAll('.Hypertorus__reactionMetric'),
  );
  const metric = metrics.find(
    (candidate) =>
      candidate.querySelector('.Hypertorus__metricLabel')?.textContent === label,
  );
  if (!metric) {
    throw new Error('Не найдена шкала «' + label + '»');
  }
  return metric as HTMLElement;
};

const barFill = (container: HTMLElement, label: string) =>
  (metricByLabel(container, label).querySelector(
    '.ProgressBar__fill',
  ) as HTMLElement).style.width;

// formatSiBaseTenUnit склеивает подпись из значения, приставки и единицы, а на
// низком диапазоне приставка - пробел. В разметке это даёт подряд идущие
// пробелы, которые браузер схлопывает в один.
const squash = (text?: string | null) => text?.replace(/\s+/g, ' ').trim();

describe('окно гиперторуса', () => {
  test('собирается и показывает все вкладки', () => {
    setupStore();
    render(<Hypertorus />);
    expect(screen.getByText('Обзор')).toBeTruthy();
    expect(screen.getByText('Рецепты')).toBeTruthy();
    expect(screen.getByText('Фильтры')).toBeTruthy();
    // Отдельной вкладки настройки больше нет: регуляторы живут на обзоре.
    expect(screen.queryByText('Настройка')).toBeNull();
  });

  test('шапка показывает состояние остановленного реактора', () => {
    setupStore();
    render(<Hypertorus />);
    expect(screen.getByText('ОСТАНОВЛЕН')).toBeTruthy();
  });

  test('шапка показывает уровень мощности на ходу', () => {
    setupStore({ power_level: 4, internal_fusion_temperature: 5e5 });
    render(<Hypertorus />);
    expect(screen.getByText('УРОВЕНЬ 4')).toBeTruthy();
  });

  test('легенда графика печатает присланный кельвин', () => {
    const { container } = render(
      (setupStore({ internal_fusion_temperature: 5000 }), <Hypertorus />),
    );
    const legend = container.querySelector('.Hypertorus__chartLegendValue');
    // С лишним * 1000 подпись читалась как «5.00 · 10⁶ K».
    expect(squash(legend?.textContent)).toBe('5.00 · 10³ K');
  });

  test('низкая температура не схлопывается в ноль тысяч', () => {
    setupStore({ internal_fusion_temperature: 293 });
    const { container } = render(<Hypertorus />);
    const legend = container.querySelector('.Hypertorus__chartLegendValue');
    expect(squash(legend?.textContent)).toBe('293 K');
  });

  test('скорость изменения температуры печатается рядом со значением', () => {
    setupStore({
      internal_fusion_temperature: 10000,
      internal_fusion_temperature_archived: 5000,
      temperature_period: 2,
    });
    const { container } = render(<Hypertorus />);
    const delta = container.querySelector('.Hypertorus__chartLegendDelta');
    expect(squash(delta?.textContent)).toBe('+2.50 · 10³ K/с');
  });
});

describe('потолки шкал реакции', () => {
  /**
   * heat_limiter_modifier = 5 * 10^power_level * heating_conductor * 0.01,
   * максимум 5 * 1e6 * 5 = 2.5e7.
   */
  test('шкала ограничителя тепла упирается в 2.5e7', () => {
    setupStore({ heat_limiter_modifier: 1.25e7 });
    const { container } = render(<Hypertorus />);
    expect(barFill(container, 'Ограничитель')).toBe('50%');
  });

  /**
   * energy = energy_modifiers * c^2 * (T * heat_modifier / 100) даёт ~9e24 на
   * потолках DM; 1e35 в шкале был страховкой от переполнения float
   * (HFR_ENERGY_CLAMP_MAX), а не игровым пределом.
   */
  test('шкала энергии упирается в 1e25, а не в кламп 1e35', () => {
    setupStore({ energy_level: 5e24 });
    const { container } = render(<Hypertorus />);
    expect(barFill(container, 'Энергия')).toBe('50%');
  });

  test('тепловой выход сохраняет знак в подписи', () => {
    setupStore({ heat_output: -250, heat_output_min: -1000 });
    const { container } = render(<Hypertorus />);
    const cell = metricByLabel(container, 'Тепловой выход');
    expect(squash(cell.querySelector('.ProgressBar__content')?.textContent)).toBe(
      '-250 K',
    );
  });
});

describe('вкладки', () => {
  test('вкладка рецептов показывает карточку рецепта', () => {
    setupStore();
    render(<Hypertorus />);
    fireEvent.click(screen.getByText('Рецепты'));
    expect(screen.getByText('Расщепление азота')).toBeTruthy();
  });

  test('на разогнанном реакторе выбор рецепта заблокирован', () => {
    setupStore({ power_level: 3, internal_fusion_temperature: 5e4 });
    const { container } = render(<Hypertorus />);
    fireEvent.click(screen.getByText('Рецепты'));
    const buttons = Array.from(container.querySelectorAll('.Button')).filter(
      (button) => button.textContent?.includes('Выбрать'),
    );
    expect(buttons.length).toBeGreaterThan(0);
    buttons.forEach((button) => {
      expect(button.className).toMatch(/Button--disabled/);
    });
  });

  test('регуляторы стоят прямо на обзоре, рядом с графиком', () => {
    setupStore();
    render(<Hypertorus />);
    // Без единого клика по вкладкам: жалоба игроков была именно на то, что
    // настройка жила отдельно от температурных шкал.
    expect(screen.getByText('Теплопроводник')).toBeTruthy();
    expect(screen.getByText('Демпфер тока')).toBeTruthy();
    expect(screen.getByText('Температуры контуров')).toBeTruthy();
  });

  test('впрыск топлива и модератора виден у своих газовых колонок', () => {
    setupStore();
    render(<Hypertorus />);
    expect(screen.getByText('Камера синтеза')).toBeTruthy();
    expect(screen.getByText('Впрыск топлива')).toBeTruthy();
    expect(screen.getByText('Впрыск модератора')).toBeTruthy();
  });

  test('тумблер отвода отходов на обзоре блокируется на высокой мощности', () => {
    setupStore({ power_level: 6, internal_fusion_temperature: 5e6 });
    const { container } = render(<Hypertorus />);
    const toggle = Array.from(container.querySelectorAll('.Button')).find(
      (button) => button.textContent?.includes('Отвод:'),
    );
    expect(toggle).toBeTruthy();
    expect(toggle!.className).toMatch(/Button--disabled/);
  });

  test('чип рецепта открывает вкладку рецептов', () => {
    setupStore();
    render(<Hypertorus />);
    fireEvent.click(screen.getByText('Рецепт не выбран'));
    expect(screen.getByText('Расщепление азота')).toBeTruthy();
  });

  test('вкладка фильтров считает скорость на каждый газ', () => {
    setupStore({
      mod_filtering_rate: 20,
      filter_types: [
        { gas_id: 'helium', gas_name: 'Helium', enabled: 1 },
        { gas_id: 'bz', gas_name: 'BZ', enabled: 1 },
      ],
    });
    render(<Hypertorus />);
    fireEvent.click(screen.getByText('Фильтры'));
    // 20 моль/с делится поровну между двумя выбранными газами.
    expect(screen.getByText(/10\.00 моль\/с на 2 газ/)).toBeTruthy();
  });
});

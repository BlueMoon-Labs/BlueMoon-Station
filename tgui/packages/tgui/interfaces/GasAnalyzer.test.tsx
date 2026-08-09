/**
 * Окно анализатора читает смеси из /proc/gas_mixture_parser. Тест закрепляет три
 * места, где легко потерять смысл: названия газов бэкенд шлёт по-английски, а
 * показывать их надо русскими из общей таблицы; смесь без молей обязана давать
 * сообщение, а не пустой список; третий элемент реакции у нас всегда null, и
 * такая запись обязана читаться как "возможна", а не как пустота или "null".
 */
import { render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import type { Gasmix } from './common/GasmixParser';
import { GasAnalyzer } from './GasAnalyzer';

// Снято с реального вывода gas_mixture_parser: 21 моль O2 + 79 молей N2.
const airMix: Gasmix = {
  name: 'Пол',
  reference: '[0x2105cc03]',
  total_moles: 100,
  temperature: 293.15,
  volume: 2500,
  pressure: 97.4431,
  gases: [
    ['o2', 'Oxygen', 21],
    ['n2', 'Nitrogen', 79],
  ],
  reactions: [],
};

const emptyMix: Gasmix = {
  name: 'Пустая труба',
  reference: '[0x2105cb5b]',
  total_moles: 0,
  temperature: 2.7,
  volume: 2500,
  pressure: 0,
  gases: [],
  reactions: [],
};

const reactingMix: Gasmix = {
  name: 'Камера смешивания',
  reference: '[0x2105c48a]',
  total_moles: 40,
  temperature: 293.15,
  volume: 2500,
  pressure: 38.9772,
  gases: [
    ['n2o', 'Nitrous Oxide', 20],
    ['plasma', 'Plasma', 20],
  ],
  reactions: [['bzformation', 'BZ Gas formation', null]],
};

const setupStore = (data = {}) => {
  // Window.componentDidMount calls Byond.winset; stub the BYOND bridge.
  (global as any).Byond = { winset: () => {}, topic: () => {} };
  const store = createStore(
    combineReducers({ backend: backendReducer, debug: debugReducer }),
  );
  setGlobalStore(store);
  store.dispatch(
    backendUpdate({
      config: { interface: 'GasAnalyzer' },
      data: {
        gasmixes: [airMix],
        ...data,
      },
    }),
  );
  return store;
};

describe('GasAnalyzer', () => {
  test('состав смеси показывается русскими названиями газов', () => {
    setupStore({ gasmixes: [airMix] });
    const { container } = render(<GasAnalyzer />);
    const text = container.textContent;
    expect(text).toContain('Кислород');
    expect(text).toContain('Азот');
    // Английские имена от бэкенда - только запасной вариант, наружу не идут.
    expect(text).not.toContain('Oxygen');
    expect(text).not.toContain('Nitrogen');
    expect(text).toContain('21.00 моль (21.00 %)');
    expect(text).toContain('97.44 кПа');
    expect(text).toContain('293.15 К');
  });

  test('газ без записи в таблице показывается именем от бэкенда', () => {
    const unknownMix: Gasmix = {
      ...airMix,
      gases: [['bluemoon_unit_test_gas', 'Unit Test Gas', 4]],
      total_moles: 4,
    };
    setupStore({ gasmixes: [unknownMix] });
    const { container } = render(<GasAnalyzer />);
    expect(container.textContent).toContain('Unit Test Gas');
  });

  test('пустая смесь даёт сообщение вместо пустоты', () => {
    setupStore({ gasmixes: [emptyMix] });
    const { container } = render(<GasAnalyzer />);
    const text = container.textContent;
    expect(text).toContain('Газ не обнаружен!');
    // Параметров у пустой смеси не показываем вовсе, а не прочерками.
    expect(text).not.toContain('Давление');
  });

  test('реакция-кандидат подписывается как возможная', () => {
    setupStore({ gasmixes: [reactingMix] });
    const { container } = render(<GasAnalyzer />);
    const text = container.textContent;
    expect(text).toContain('Возможные реакции');
    expect(text).toContain('BZ Gas formation: возможна');
    expect(text).not.toContain('null');
  });

  test('смесь без реакций сообщает об их отсутствии', () => {
    setupStore({ gasmixes: [airMix] });
    const { container } = render(<GasAnalyzer />);
    // Подписи говорят о КАНДИДАТАХ: условия реакции выполнены, но пойдёт ли она,
    // решает холдер смеси, и окно этого не знает.
    expect(container.textContent).toContain('Подходящих реакций нет');
  });

  test('нестабильность синтеза показывается у своей смеси', () => {
    setupStore({
      gasmixes: [airMix, reactingMix],
      fusion_instability: { [reactingMix.reference]: 2.5 },
    });
    const { container } = render(<GasAnalyzer />);
    const text = container.textContent;
    expect(text).toContain('Нестабильность: 2.5.');
    expect(text?.indexOf('Нестабильность')).toBeGreaterThan(
      text?.indexOf('Камера смешивания') ?? -1,
    );
  });

  test('без скана окно не пустое', () => {
    setupStore({ gasmixes: [] });
    const { container } = render(<GasAnalyzer />);
    expect(container.textContent).toContain('Сканирование ещё не проводилось.');
  });
});

/**
 * Омни-фильтр держал выбор газа на отображаемой строке и после клика искал
 * газ обратным поиском по ней. Для газа без записи в GASES getGasLabel
 * возвращает сырое имя из DM, поэтому две одинаковые подписи неразличимы:
 * обратный поиск брал первое совпадение и уводил act() не с тем id.
 * Фикстура с двумя газами под одной подписью закрепляет, что в act() уходит
 * значение варианта, а подпись выбранного берётся из самих options.
 */
import { fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { AtmosOmni } from './AtmosOmni';

const setupStore = (data = {}) => {
  // Window.componentDidMount calls Byond.winset; stub the BYOND bridge.
  (global as any).Byond = { winset: () => {}, topic: () => {} };
  const store = createStore(
    combineReducers({ backend: backendReducer, debug: debugReducer }),
  );
  setGlobalStore(store);
  store.dispatch(
    backendUpdate({
      config: { interface: 'AtmosOmni' },
      data: {
        kind: 'filter',
        on: true,
        setting: 4500,
        setting_max: 4500,
        setting_label: 'Давление',
        setting_unit: 'кПа',
        filter_types: [
          { id: 'o2', name: 'Oxygen' },
          { id: 'healium', name: 'Healium' },
          { id: 'nitrium', name: 'Nitrium' },
        ],
        ports: [
          {
            index: 1,
            name: 'North',
            role: 'filter',
            connected: true,
            pressure: 101,
            temperature: 293,
            gas: 'healium',
          },
        ],
        ...data,
      },
    }),
  );
  return store;
};

// Стаб Byond перетирает глобал, поэтому ставится строго после setupStore.
const captureTopic = () => {
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  return topic;
};

const actPayload = (topic, action) => {
  const call = topic.mock.calls.find(c => c[0]?.type === 'act/' + action);
  expect(call).toBeTruthy();
  return JSON.parse(call[0].payload);
};

describe('AtmosOmni gas selection', () => {
  test('выбранный газ показан подписью, а не идентификатором', () => {
    setupStore();
    const { container } = render(<AtmosOmni />);
    expect(container.textContent).toContain('Healium');
    expect(container.textContent).not.toContain('healium');
  });

  test('выбор газа уходит идентификатором', () => {
    setupStore();
    const topic = captureTopic();
    const { container, getByText } = render(<AtmosOmni />);
    fireEvent.click(container.querySelector('.Dropdown__control'));
    fireEvent.click(getByText('Nitrium'));
    expect(actPayload(topic, 'gas')).toEqual({ index: 1, gas: 'nitrium' });
    expect(container.querySelector('.Dropdown__menu')).toBeNull();
  });

  test('одинаковые подписи не путают идентификаторы', () => {
    setupStore({
      filter_types: [
        { id: 'gas_a', name: 'Дубль' },
        { id: 'gas_b', name: 'Дубль' },
      ],
      ports: [
        {
          index: 1,
          name: 'North',
          role: 'filter',
          connected: true,
          pressure: 101,
          temperature: 293,
          gas: 'gas_a',
        },
      ],
    });
    const topic = captureTopic();
    const { container } = render(<AtmosOmni />);
    fireEvent.click(container.querySelector('.Dropdown__control'));
    const entries = Array.from(
      container.querySelectorAll('.Dropdown__menuentry'),
    );
    // Обе строки меню подписаны одинаково: различить их можно только
    // значением варианта, обратный поиск по подписи взял бы первую.
    expect(entries.map(entry => entry.textContent)).toEqual(['Дубль', 'Дубль']);
    fireEvent.click(entries[1]);
    expect(actPayload(topic, 'gas')).toEqual({ index: 1, gas: 'gas_b' });
  });
});

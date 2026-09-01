/**
 * Регресс на опечатку в имени поля: три кнопки-пресета читали
 * data.ReleasePressure (с большой буквы), которого бэкенд не шлёт,
 * поэтому сравнение всегда давало undefined === number и кнопки
 * не дизейблились даже на упоре шкалы.
 */
import { render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { Tank } from './Tank';

const setupStore = (data = {}) => {
  // Window.componentDidMount calls Byond.winset; stub the BYOND bridge.
  (global as any).Byond = { winset: () => {}, topic: () => {} };
  const store = createStore(
    combineReducers({ backend: backendReducer, debug: debugReducer }),
  );
  setGlobalStore(store);
  store.dispatch(
    backendUpdate({
      config: { interface: 'Tank' },
      data: {
        defaultReleasePressure: 101,
        minReleasePressure: 0,
        maxReleasePressure: 1013,
        leakPressure: 3000,
        fragmentPressure: 4000,
        tankPressure: 1000,
        releasePressure: 0,
        connected: false,
        ...data,
      },
    }),
  );
  return store;
};

describe('Tank pressure presets', () => {
  test('минимум дизейблится, когда выпуск уже на минимуме', () => {
    setupStore({ releasePressure: 0 });
    const { container } = render(<Tank />);
    const buttons = container.querySelectorAll('.Button');
    // NumberInput не имеет класса Button, поэтому querySelectorAll
    // возвращает только сами кнопки: 0=min, 1=max, 2=reset.
    expect(buttons[0].className).toContain('disabled');
  });

  test('максимум дизейблится, когда выпуск уже на максимуме', () => {
    setupStore({ releasePressure: 1013 });
    const { container } = render(<Tank />);
    const buttons = container.querySelectorAll('.Button');
    expect(buttons[1].className).toContain('disabled');
  });

  test('на промежуточном значении не дизейблится ничего', () => {
    setupStore({ releasePressure: 500 });
    const { container } = render(<Tank />);
    const buttons = container.querySelectorAll('.Button');
    for (const button of buttons) {
      expect(button.className).not.toContain('disabled');
    }
  });

  test('сброс дизейблится, когда выпуск равен значению по умолчанию', () => {
    setupStore({ releasePressure: 101 }); // = defaultReleasePressure
    const { container } = render(<Tank />);
    const buttons = container.querySelectorAll('.Button');
    expect(buttons[2].className).toContain('disabled');
  });
});

import { render, screen } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../../backend';
import { debugReducer } from '../../debug';
import { CharacterPrefsTab } from './tabs/CharacterPrefsTab';

const levels = {
  levels: [
    { value: 0, name: 'Не цель', color: 'red', description: 'Задания антагов не выберут персонажа.' },
    { value: 1, name: 'Без убийства', color: 'yellow', description: 'Только задания без убийства.' },
    { value: 2, name: 'Любые задания', color: 'green', description: 'Любые задания антагов.' },
  ],
  thresholds: 'СБ не ниже "Без убийства".',
  disclaimer: 'Это не отменяет правил сервера.',
};

const levelButton = (name: string) => screen.getByText(name).closest('.Button');

describe('CharacterPrefsTab: согласие на цели антагов', () => {
  it('собирает описания из static_data и выбор из обновления', () => {
    const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
    setGlobalStore(store);
    store.dispatch(backendUpdate({
      config: { interface: 'MobInteraction' },
      static_data: { antag_opt_in_levels: levels },
      data: { antag_opt_in: { level: 1, effective: 2 } },
    }));
    const ui = render(<CharacterPrefsTab />);
    expect(screen.getByText(levels.disclaimer)).toBeTruthy();
    expect(levelButton('Без убийства')?.className).toContain('Button--color--green');
    expect(screen.getByText(/Итоговый уровень с учётом порога: Любые задания/)).toBeTruthy();

    store.dispatch(backendUpdate({ data: { antag_opt_in: { level: 0, effective: 0 } } }));
    ui.rerender(<CharacterPrefsTab />);
    expect(levelButton('Не цель')?.className).toContain('Button--color--green');
    expect(levelButton('Без убийства')?.className).not.toContain('Button--color--green');
    expect(screen.queryByText(/Итоговый уровень с учётом порога/)).toBeNull();
  });
});

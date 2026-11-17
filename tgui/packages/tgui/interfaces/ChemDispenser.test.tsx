import { act as reactAct, fireEvent, render, screen } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { ChemDispenser } from './ChemDispenser';

const fixture = {
  chemicals: [],
  storedContents: [],
  beakerTransferAmounts: [],
  recipes: { Alpha: { water: 10 }, Beta: { water: 5 } },
  gameRecipeCounts: {},
  isBeakerLoaded: 1,
  beakerContents: [],
  beakerCurrentVolume: 0,
  beakerMaxVolume: 100,
  energy: 100,
  maxEnergy: 100,
  amount: 10,
  stepAmount: 5,
};

// Сервер не шлёт ни одного обновления после клика: окно обязано разморозиться само.
const setup = (overrides = {}) => {
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'ChemDispenser' }, data: { ...fixture, ...overrides } }));
  return { ...render(<ChemDispenser />), topic };
};

const button = (text: string) => screen.getByText(text).closest('.Button') as HTMLElement;
const isDisabled = (text: string) => button(text).className.includes('Button--disabled');
const shownDose = () => screen.getByText(/Доза:/).querySelector('b')?.textContent;

const advance = (ms: number) => reactAct(() => {
  jest.advanceTimersByTime(ms);
});

describe('ChemDispenser: оптимистичные состояния истекают без обновлений сервера', () => {
  beforeEach(() => {
    jest.useFakeTimers();
  });
  afterEach(() => {
    jest.useRealTimers();
  });

  it('кнопки рецептов снова активны после блокировки', () => {
    setup();
    fireEvent.click(screen.getByText('Мои (2)'));
    fireEvent.click(button('Alpha'));
    expect(isDisabled('Alpha')).toBe(true);
    expect(isDisabled('Beta')).toBe(true);

    advance(260);
    expect(isDisabled('Beta')).toBe(false);
    expect(isDisabled('Alpha')).toBe(true);

    advance(2000);
    expect(isDisabled('Alpha')).toBe(false);
  });

  it('доза без стакана откатывается к серверной', () => {
    const { topic } = setup({ isBeakerLoaded: 0 });
    expect(shownDose()).toBe('10');
    fireEvent.click(button('+5'));
    expect(shownDose()).toBe('5');

    advance(200);
    expect(topic.mock.calls.some(([message]) => message.type === 'act/amount')).toBe(true);
    expect(shownDose()).toBe('5');

    advance(1900);
    expect(shownDose()).toBe('10');
  });
});

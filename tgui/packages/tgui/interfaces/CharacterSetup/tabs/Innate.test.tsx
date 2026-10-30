import { fireEvent, render, screen, within } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../../../backend';
import { debugReducer } from '../../../debug';
import { InnateTab } from './Innate';

const item = {
  id: 'naga_tail', name: 'Опорный хвост', desc: 'Заменяет ноги опорным хвостом.',
  primary: false, selected: false, available: true,
  requirements: [{ text: 'Подходящее тело', met: true }, { text: 'Естественные конечности', met: false }],
};

let now = Date.now();

afterEach(() => jest.restoreAllMocks());

const setup = (items: unknown[] | undefined = [item]) => {
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  const topic = jest.fn();
  (global as any).Byond = { topic, winset: () => {} };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'CharacterSetup' }, data: { innateTab: items ? { balance: 3, items } : undefined } }));
  render(<InnateTab />);
  return topic;
};

test('карточки показывают категорию, описание, бюджет и все условия', () => {
  setup();
  for (const text of ['Дополнительная', item.desc, 'Подходящее тело', 'Естественные конечности']) {
    expect(screen.getByText(text)).toBeTruthy();
  }
  expect(screen.getByText(/Доступно очков квирков: 3/)).toBeTruthy();
});

test('основная и дополнительная особенности различаются в интерфейсе', () => {
  setup([item, { ...item, id: 'primary', name: 'Основная особенность', primary: true }]);
  expect(screen.getByText('Основная')).toBeTruthy();
  expect(screen.getByText('Дополнительная')).toBeTruthy();
});

test('выбор отправляет стабильный идентификатор особенности', () => {
  const topic = setup();
  fireEvent.click(screen.getByText('Выбрать'));
  const actions = topic.mock.calls.filter(([message]) => message.type === 'act/innate_toggle');
  expect(actions.length).toBe(1);
  expect(JSON.parse(actions[0][0].payload).id).toBe(item.id);
});

test('недоступную особенность нельзя выбрать', () => {
  const topic = setup([{ ...item, available: false }]);
  fireEvent.click(screen.getByText('Выбрать'));
  expect(topic.mock.calls.filter(([message]) => message.type === 'act/innate_toggle').length).toBe(0);
});

test('недоступную выбранную особенность можно убрать', () => {
  const topic = setup([{ ...item, selected: true, available: false }]);
  expect(screen.getByText(/Условия больше не выполнены/)).toBeTruthy();
  fireEvent.click(screen.getByText('Убрать'));
  const actions = topic.mock.calls.filter(([message]) => message.type === 'act/innate_toggle');
  expect(JSON.parse(actions[0][0].payload).id).toBe(item.id);
});

test('выбор одной карточки не отправляет идентификатор соседней', () => {
  const topic = setup([item, { ...item, id: 'second', name: 'Вторая' }]);
  const section = screen.getByText('Вторая').closest('.Section')!;
  fireEvent.click(within(section as HTMLElement).getByText('Выбрать'));
  const action = topic.mock.calls.find(([message]) => message.type === 'act/innate_toggle')!;
  expect(JSON.parse(action[0].payload).id).toBe('second');
});

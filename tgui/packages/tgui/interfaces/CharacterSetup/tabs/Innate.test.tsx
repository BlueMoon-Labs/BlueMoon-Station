import { fireEvent, render, screen } from '@testing-library/react';
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

test('недоступную особенность нельзя выбрать', () => {
  const topic = setup([{ ...item, available: false }]);
  fireEvent.click(screen.getByText('Выбрать'));
  expect(topic.mock.calls.filter(([message]) => message.type === 'act/innate_toggle').length).toBe(0);
});

test('недоступную выбранную особенность можно убрать', () => {
  const topic = setup([{ ...item, selected: true, available: false }]);
  fireEvent.click(screen.getByText('Убрать'));
  const actions = topic.mock.calls.filter(([message]) => message.type === 'act/innate_toggle');
  expect(actions.length).toBe(1);
  expect(JSON.parse(actions[0][0].payload).id).toBe(item.id);
});

test('выбор одной карточки не отправляет идентификатор соседней', () => {
  const topic = setup([{ ...item, selected: true }, { ...item, id: 'second', name: 'Вторая' }]);
  fireEvent.click(screen.getByText('Выбрать'));
  const actions = topic.mock.calls.filter(([message]) => message.type === 'act/innate_toggle');
  expect(actions.length).toBe(1);
  expect(JSON.parse(actions[0][0].payload).id).toBe('second');
});

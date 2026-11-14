import { fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { SkimmerContent, SkimmerData } from './Skimmer';

const base: SkimmerData = {
  knows: 1,
  stolen: [
    { ref: '[0x3001]', holder: 'Анна Смирнова', number: 111111, balance: 5000, left: 300, state: 'ok' },
    { ref: '[0x3002]', holder: 'Иван Петров', number: 222222, balance: 800, left: 300, state: 'frozen' },
    { ref: '[0x3003]', holder: null, number: null, balance: 0, left: 0, state: 'closed' },
  ],
  rate: 300,
  slots: 3,
  transfer_max: 50000,
  last_target: 333333,
  message: 'Переведено 300 кр. на счёт №333333.',
};

const setup = (data: Partial<SkimmerData> = {}) => {
  let now = Date.now();
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'Skimmer' }, data: { ...base, ...data } }));
  return { ...render(<SkimmerContent />), topic };
};

const sent = (topic, action) =>
  topic.mock.calls
    .map(([message]) => message)
    .filter((message) => message.type === `act/${action}`)
    .map((message) => (message.payload ? JSON.parse(message.payload) : {}));

const text = (container: HTMLElement) => (container.textContent || '').replace(/\u00a0/g, ' ');

test('перевод и стирание по ref слота, получатель и сумма из формы', () => {
  const { getAllByText, container, topic } = setup();
  expect(text(container)).toContain('Переведено 300 кр. на счёт №333333.');
  const amount = container.querySelectorAll('input')[1] as HTMLInputElement;
  fireEvent.focus(amount);
  fireEvent.input(amount, { target: { value: '120' } });
  fireEvent.blur(amount);
  fireEvent.click(getAllByText('Перевести')[0]);
  fireEvent.click(container.querySelectorAll('.fa-eraser')[2].closest('.Button') as HTMLElement);
  expect(sent(topic, 'siphon')).toEqual([{ ref: '[0x3001]', target: '333333', amount: 120 }]);
  expect(sent(topic, 'forget')).toEqual([{ ref: '[0x3003]' }]);
});

test('состояние счетов и лимит объяснены, с замороженного перевод закрыт', () => {
  const { getAllByText, container } = setup();
  expect(text(container)).toContain('Скопированные счета: 3/3');
  expect(text(container)).toContain('сейчас можно ещё 300 кр.');
  expect(text(container)).toContain('заморожен аудитом');
  expect(text(container)).toContain('счёт закрыт');
  expect(text(container)).toContain('не больше 300 кр. за любую минуту');
  expect(getAllByText('Перевести')[1].closest('.Button')?.className).toContain('Button--disabled');
});

test('постороннему - обычный считыватель без данных и кнопок', () => {
  const { container } = setup({ knows: 0, stolen: undefined, message: undefined });
  expect(text(container)).toContain('Бесконтактный считыватель платежей');
  expect(container.textContent).not.toContain('Анна');
  expect(container.querySelectorAll('.Button')).toHaveLength(0);
});

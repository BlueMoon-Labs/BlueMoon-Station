import { fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { EvidenceLockerContent, EvidenceLockerData } from './EvidenceLocker';

const base: EvidenceLockerData = {
  can_use: 1,
  pays_here: 1,
  catalog_ready: 1,
  count: 2,
  items: [
    { ref: '[0x2001]', name: 'agent card', value: 300 },
    { ref: '[0x2002]', name: 'emag', value: 900 },
  ],
  per_tc: 150,
  default_value: 300,
  premium_percent: 10,
  resale_percent: 50,
  cap_hour: 6000,
  cap_left: 500,
};

const setup = (data: Partial<EvidenceLockerData> = {}) => {
  let now = Date.now();
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'EvidenceLocker' }, data: { ...base, ...data } }));
  return { ...render(<EvidenceLockerContent />), topic };
};

const sent = (topic, action) =>
  topic.mock.calls
    .map(([message]) => message)
    .filter((message) => message.type === `act/${action}`)
    .map((message) => (message.payload ? JSON.parse(message.payload) : {}));

const text = (container: HTMLElement) => (container.textContent || '').replace(/\u00a0/g, ' ');

const isDisabled = (element: HTMLElement) => !!element.closest('.Button')?.className.includes('Button--disabled');

test('СБ передаёт улику NT и забирает её по ref, улика дороже остатка лимита ждёт', () => {
  const { getAllByText, container, topic } = setup();
  expect(text(container)).toContain('agent card300 кр.');
  expect(text(container)).toContain('emag900 кр.');
  expect(isDisabled(getAllByText('Передать NT')[0])).toBe(false);
  expect(isDisabled(getAllByText('Передать NT')[1])).toBe(true);
  expect(text(container)).toContain('Улика, на которую не хватает остатка, ждёт в хранилище');
  fireEvent.click(getAllByText('Передать NT')[0]);
  fireEvent.click(getAllByText('Забрать')[1]);
  expect(sent(topic, 'hand_over')).toEqual([{ ref: '[0x2001]' }]);
  expect(sent(topic, 'eject')).toEqual([{ ref: '[0x2002]' }]);
});

test('правила выплат: курс по рынку, премия и потолки из настроек', () => {
  const { container } = setup();
  expect(text(container)).toContain('150 кр. за каждый телекристалл');
  expect(text(container)).toContain('(300 кр., если цены нет)');
  expect(text(container)).toContain('премию 10%');
  expect(text(container)).toContain('не больше 50% уплаченного');
  expect(text(container)).toContain('не больше чем на 6 000 кр., в этом часе осталось 500 кр.');
});

test('без доступа видно только число улик', () => {
  const { container } = setup({ can_use: 0, items: [] });
  expect(text(container)).toContain('Улики: 2');
  expect(text(container)).toContain('Нет доступа');
  expect(container.textContent).not.toContain('Передать NT');
});

test('вне станции и при исчерпанном лимите передача NT закрыта', () => {
  const offstation = setup({ pays_here: 0 });
  expect(text(offstation.container)).toContain('вне станции');
  expect(text(offstation.container)).not.toContain('Как платит NT');
  expect(isDisabled(offstation.getAllByText('Передать NT')[0])).toBe(true);
  offstation.unmount();
  const capped = setup({ cap_left: 0 });
  expect(isDisabled(capped.getAllByText('Передать NT')[0])).toBe(true);
  expect(isDisabled(capped.getAllByText('Забрать')[0])).toBe(false);
});

import { fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../../backend';
import { debugReducer } from '../../debug';
import { ContractTable } from './ContractTable';

const contract = (uid, extra = {}) => ({
  uid,
  department: 'CIV',
  department_name: 'Гражданские',
  title: `Контракт ${uid}`,
  desc: 'Описание',
  reward: 5000,
  urgent: 0,
  time_left: null,
  taken_by: null,
  taker_id: null,
  takeable: 1,
  special: 0,
  progress: '0/1',
  rotates_in: null,
  started: 0,
  ...extra,
});

const contracts = [
  contract(1, { rotates_in: 61 }),
  contract(2, { taken_by: 'Тест Тестов', taker_id: 111, urgent: 1, time_left: 125 }),
  contract(3, { takeable: 0, special: 1 }),
  contract(4, { taken_by: 'Другой', taker_id: 222 }),
  contract(5, { started: 1, rotates_in: 3600, takeable: 0 }),
];

const setup = (data = {}, readOnly = false) => {
  let now = Date.now();
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(
    backendUpdate({ config: { interface: 'ContractBoard' }, data: { contracts, my_account: 111, performer_share: 30, ...data } }),
  );
  return { ...render(<ContractTable readOnly={readOnly} />), topic };
};

const sent = (topic, action) =>
  topic.mock.calls
    .map(([message]) => message)
    .filter((message) => message.type === `act/${action}`)
    .map((message) => JSON.parse(message.payload));

test('доска показывает, кто взял контракт, срочность, срок и смену', () => {
  const ui = setup();
  expect(ui.getByText('Ваш контракт')).toBeTruthy();
  expect(ui.getByText('Взял: Другой')).toBeTruthy();
  expect(ui.getAllByText('Выполняет отдел')).toHaveLength(2);
  expect(ui.getByText('Срочный')).toBeTruthy();
  expect(ui.getByText('Осталось 2:05')).toBeTruthy();
  expect(ui.getByText('Смена через 1:01')).toBeTruthy();
  expect(ui.getByText('Снимется через 60:00, отгруженное не вернётся')).toBeTruthy();
  expect(ui.getByText('Контракт 3 (заказ ЦК)')).toBeTruthy();
  expect(ui.getByText('Взявший контракт получает 30% награды, остальное - отделу.')).toBeTruthy();
});

test('"Взять" шлёт take с uid', () => {
  const ui = setup();
  fireEvent.click(ui.getByText('Взять'));
  expect(sent(ui.topic, 'take')).toEqual([{ uid: 1 }]);
});

test('без счёта "Взять" неактивна', () => {
  const noAccount = setup({ my_account: null });
  fireEvent.click(noAccount.getByText('Взять'));
  expect(sent(noAccount.topic, 'take')).toEqual([]);
});

test('только просмотр: без кнопки, свободный контракт помечен', () => {
  const ui = setup({}, true);
  expect(ui.queryByText('Взять')).toBeNull();
  expect(ui.getByText('Свободен')).toBeTruthy();
  expect(ui.getByText('Взял: Другой')).toBeTruthy();
});

test('от своего контракта можно отказаться с подтверждением, от чужого нет', () => {
  const ui = setup({ drop_cooldown: 5 });
  expect(ui.getAllByText('Отказаться')).toHaveLength(1);
  fireEvent.click(ui.getByText('Отказаться'));
  expect(sent(ui.topic, 'drop')).toEqual([]);
  fireEvent.click(ui.getByText('Точно отказаться?'));
  expect(sent(ui.topic, 'drop')).toEqual([{ uid: 2 }]);
});

test('только просмотр: отказа нет', () => {
  const ui = setup({}, true);
  expect(ui.queryByText('Отказаться')).toBeNull();
});

const rank = { name: 'Подрядчик', rep: 5, done: 5, slots: 2, used: 1, bonus: 0, next_name: 'Надёжный подрядчик', next_rep: 8 };
const crewRules = { min: 50, max: 10000, title_max: 60, desc_max: 300, minutes: 60, accept_minutes: 10 };

test('ранг подрядчика: слоты и сколько до следующего ранга', () => {
  const ui = setup({ rank });
  expect(ui.getByText('Подрядчик')).toBeTruthy();
  expect(ui.getByText('Контрактов взято: 1 из 2')).toBeTruthy();
  expect(ui.getByText('До ранга «Надёжный подрядчик»: ещё 3')).toBeTruthy();
});

test('личный заказ, серия и упавший спрос помечены, доля исполнителя посчитана', () => {
  const ui = setup({
    rank,
    contracts: [
      contract(10, { kind: 'personal', share: 60, reward: 1000 }),
      contract(11, { kind: 'chain', stage: 2, stages: 3, chain_bonus: 50, taken_by: 'Другой', taker_id: 222 }),
      contract(12, { demand: 60, taken_by: 'Другой', taker_id: 222 }),
    ],
  });
  expect(ui.getByText('Личный заказ')).toBeTruthy();
  expect(ui.getByText('Исполнителю 60%: 600 кр.')).toBeTruthy();
  expect(ui.getByText('Серия: этап 2 из 3')).toBeTruthy();
  expect(ui.getByText('Спрос 60%')).toBeTruthy();
  fireEvent.click(ui.getByText('Личные (1)'));
  expect(ui.queryByText('Серия: этап 2 из 3')).toBeNull();
});

test('общая работа отдела без доли бюджета: награда поровну отделу на смене', () => {
  const ui = setup({
    team_share: 25,
    contracts: [contract(20, { takeable: 0, people_only: 1, reward: 400 }), contract(21, { takeable: 0 })],
  });
  expect(ui.getByText('Поровну всем в отделе на смене, бюджету ничего')).toBeTruthy();
  expect(ui.getByText('Участникам 25% по вкладу')).toBeTruthy();
});

test('личные заказы обновляются кнопкой, на кулдауне она молчит', () => {
  const ready = setup({ rank, contracts: [contract(10, { kind: 'personal' })] });
  fireEvent.click(ready.getByText('Обновить личные заказы'));
  expect(sent(ready.topic, 'reroll')).toHaveLength(1);
  const waiting = setup({ rank, reroll_left: 90, contracts: [contract(10, { kind: 'personal' })] });
  fireEvent.click(waiting.getAllByText('Обновить личные заказы').pop()!);
  expect(sent(waiting.topic, 'reroll')).toHaveLength(0);
});

test('объявление экипажа: исполнитель сдаёт работу, заказчик принимает или отклоняет', () => {
  const crew = (uid, extra = {}) => contract(uid, { kind: 'crew', department_name: 'Экипаж', poster: 'Заказчик', poster_id: 333, ...extra });
  const performer = setup({ rank, crew_request: crewRules, contracts: [crew(20, { taken_by: 'Тест Тестов', taker_id: 111 })] });
  fireEvent.click(performer.getByText('Сдать работу'));
  expect(sent(performer.topic, 'crew_report')).toEqual([{ uid: 20 }]);
  const poster = setup({
    rank,
    my_account: 333,
    crew_request: crewRules,
    contracts: [crew(21, { taken_by: 'Другой', taker_id: 222, reported: 1 }), crew(22)],
  });
  expect(poster.getByText('Работу сдал: Другой')).toBeTruthy();
  fireEvent.click(poster.getByText('Принять работу'));
  expect(sent(poster.topic, 'crew_accept')).toEqual([{ uid: 21 }]);
  fireEvent.click(poster.getByText('Отклонить'));
  fireEvent.click(poster.getByText('Точно отклонить?'));
  expect(sent(poster.topic, 'crew_reject')).toEqual([{ uid: 21 }]);
  fireEvent.click(poster.getByText('Снять'));
  fireEvent.click(poster.getByText('Снять объявление?'));
  expect(sent(poster.topic, 'crew_cancel')).toEqual([{ uid: 22 }]);
  expect(poster.queryByText('Взять')).toBeNull();
});

test('форма объявления шлёт заголовок, описание и награду', () => {
  const ui = setup({ rank, crew_request: crewRules });
  fireEvent.click(ui.getByText('Дать объявление'));
  const [title, desc, reward] = Array.from(ui.container.querySelectorAll('input'));
  fireEvent.input(title, { target: { value: 'Починить шлюз' } });
  fireEvent.input(desc, { target: { value: 'Шлюз в баре не открывается' } });
  fireEvent.input(reward, { target: { value: '500' } });
  fireEvent.click(ui.getByText('Разместить'));
  expect(sent(ui.topic, 'crew_post')).toEqual([{ title: 'Починить шлюз', desc: 'Шлюз в баре не открывается', reward: 500 }]);
});

test('чужие свободные объявления экипажа видны сверху, "Показать" оставляет только их', () => {
  const crew = (uid, extra = {}) => contract(uid, { kind: 'crew', department_name: 'Экипаж', poster: 'Заказчик', poster_id: 333, ...extra });
  const ui = setup({ rank, contracts: [contract(1), crew(30), crew(31, { taken_by: 'Другой', taker_id: 222 }), crew(32, { poster_id: 111 })] });
  expect(ui.container.textContent).toContain('Экипаж просит о помощи: свободных объявлений 1.');
  fireEvent.click(ui.getByText('Показать'));
  expect(ui.queryByText('Контракт 1')).toBeNull();
  expect(ui.getByText('Контракт 30')).toBeTruthy();
  expect(ui.queryByText('Показать')).toBeNull();
  const viewer = setup({ contracts: [crew(30)] }, true);
  expect(viewer.queryByText('Показать')).toBeNull();
});

test('без ранга в данных (бюджет отдела) панели подрядчика нет', () => {
  const ui = setup({ crew_request: crewRules });
  expect(ui.queryByText('Дать объявление')).toBeNull();
});

const partnerOffer = {
  uid: 7,
  partner: 'Гильдия старателей',
  partner_id: 'prospectors',
  item: 'слитки золота',
  requirement: '"слитки золота"',
  quantity: 10,
  delivered: 4,
  unit_price: 60,
  unit_reward: 150,
  premium: 900,
  reward: 1500,
  paid: 240,
  accepted: 0,
  contraband: 0,
  time_left: 600,
};

test('спецзаказы партнёров видны на доске с оплатой и долей сдавшего', () => {
  const ui = setup({ team_share: 25, partner_offers: [partnerOffer] });
  expect(ui.getByText('Спецзаказы партнёров снабжения')).toBeTruthy();
  expect(ui.getByText('Гильдия старателей')).toBeTruthy();
  expect(ui.getByText('4 из 10')).toBeTruthy();
  expect(ui.getByText('Сдавшему 25% оплаты за штуки')).toBeTruthy();
  expect(ui.getByText('Сдаётся на паде')).toBeTruthy();
});

test('в режиме просмотра спецзаказов партнёров нет', () => {
  const ui = setup({ partner_offers: [partnerOffer] }, true);
  expect(ui.queryByText('Спецзаказы партнёров снабжения')).toBeNull();
});

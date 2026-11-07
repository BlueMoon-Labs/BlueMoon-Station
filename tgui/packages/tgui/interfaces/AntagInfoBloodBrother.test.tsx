import { fireEvent, render, screen, within } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { AntagInfoBloodBrother, AntagInfoBloodBrotherData, OathTexts, threadPath } from './AntagInfoBloodBrother';

const capstones: Record<string, { name: string; desc: string }> = {
  heist: { name: 'Схрон крови', desc: 'Общий карман на пять предметов.' },
  vendetta: { name: 'Метка крови', desc: 'Цель подсвечена для всех братьев.' },
  debt: { name: 'Заслон', desc: 'Половина урона соседа - на тебя.' },
};

const oath = (key: string, name: string, vow: string): OathTexts => ({
  key,
  name,
  story: `История клятвы ${name}.`,
  vow_name: vow,
  vow_desc: `Описание обета ${vow}.`,
  capstone: { ...capstones[key], how: 'Кнопка слева сверху.', cooldown: 300, passive: 0 },
  finale: 'всем живым братьям - до ЦК, без наручников',
  steps: [
    { name: `${name}: первый шаг`, desc: 'Первое дело.' },
    { name: `${name}: второй шаг`, desc: 'Второе дело.' },
    { name: `${name}: третий шаг`, desc: 'Третье дело.' },
  ],
});

const unsealed = () => [0, 1, 2].map(() => ({ sealed: 0, sealed_by: null as string | null, condition: null as string | null }));

const fixture: AntagInfoBloodBrotherData = {
  antag_name: 'Кровный брат',
  backstory: 'Мы служили на одном рудовозе.',
  backstory_owner: 1,
  brothers: [
    { name: 'Иван Рудный', job: 'Shaft Miner', self: 1 },
    { name: 'Мара Кольцова', job: 'Medical Doctor', self: 0 },
  ],
  bond_ladder: [
    {
      tier: 0,
      abilities: [
        { name: 'Чутьё брата', desc: 'Где брат и что с ним.', how: 'Алерты сверху справа.', cooldown: 0, passive: 1 },
        { name: 'Шёпот крови', desc: 'Слово только для своих.', how: 'Кнопка слева сверху.', cooldown: 2, passive: 0 },
      ],
    },
    { tier: 1, abilities: [{ name: 'Кровь за кровь', desc: 'Отдать брату кровь.', how: 'Вплотную к брату.', cooldown: 120, passive: 0 }] },
    { tier: 2, abilities: [{ name: 'Ярость за брата', desc: 'Злость за упавшего брата.', how: 'Срабатывает сама.', cooldown: 180, passive: 1 }] },
  ],
  rules: ['Шрам на ладони виден без перчаток.', 'Майндшилд глушит связь.'],
  offer_texts: [oath('heist', 'Добыча', 'Без крови'), oath('vendetta', 'Месть', 'Тень'), oath('debt', 'Долг крови', 'Плечом к плечу')],
  oath_texts: null,
  state: 'choosing',
  offered: ['heist', 'vendetta', 'debt'],
  proposed_key: null,
  proposed_by: null,
  i_proposed: 0,
  i_signed: 0,
  deadline_left: 252.4,
  oath: null,
  current_step: 0,
  can_seal: 0,
  tier: 0,
  tier_max: 3,
  vow: null,
  brother_states: [
    { name: 'Иван Рудный', state: 'ok', state_text: 'в порядке', direction: null, self: 1 },
    { name: 'Мара Кольцова', state: 'hurt', state_text: 'ранена', direction: 'северо-восток', self: 0 },
  ],
  abilities: [
    { name: 'Чутьё брата', desc: 'Где брат и что с ним.' },
    { name: 'Шёпот крови', desc: 'Слово только для своих.' },
  ],
  muted: 0,
};

const sworn = () => {
  const steps = unsealed();
  steps[0] = { ...steps[0], sealed: 1, sealed_by: 'Мара Кольцова' };
  steps[1] = { ...steps[1], condition: 'на брате: нет' };
  return {
    state: 'sworn' as const,
    offered: [],
    offer_texts: [],
    oath_texts: oath('heist', 'Добыча', 'Тень'),
    oath: { key: 'heist', steps },
    current_step: 2,
    can_seal: 1,
    tier: 1,
    vow: { name: 'Тень', desc: 'Никто не сидит в наручниках дольше минуты.', broken: 0, broken_reason: null },
  };
};

let now = Date.now();

const originalMatchMedia = window.matchMedia;

afterEach(() => {
  window.matchMedia = originalMatchMedia;
});

const setup = (overrides: Partial<AntagInfoBloodBrotherData> = {}) => {
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'AntagInfoBloodBrother' }, data: { ...fixture, ...overrides } }));
  const ui = render(<AntagInfoBloodBrother />);
  const update = (changes: Partial<AntagInfoBloodBrotherData>) => {
    store.dispatch(backendUpdate({ data: changes }));
    ui.rerender(<AntagInfoBloodBrother />);
  };
  return { ...ui, topic, update };
};

const sealSecond = () => {
  const next = sworn();
  next.oath.steps[1] = { ...next.oath.steps[1], sealed: 1, sealed_by: 'Иван Рудный', condition: null };
  return { ...next, current_step: 3 };
};

const prefersReducedMotion = () => {
  window.matchMedia = jest.fn(() => ({
    matches: true,
    addEventListener: () => {},
    removeEventListener: () => {},
  })) as unknown as typeof window.matchMedia;
};

const stamping = (container: HTMLElement) => container.querySelectorAll('.AntagInfoBloodBrother__print--stamping');

const sent = (topic: jest.Mock, action: string) =>
  topic.mock.calls.filter(([message]) => message.type === `act/${action}`).map(([message]) => JSON.parse(message.payload));

const acts = (topic: jest.Mock) => topic.mock.calls.filter(([message]) => String(message.type).startsWith('act/'));

const key = (code: string, options: object = {}) => fireEvent.keyDown(window, { code, ...options });

const command = (name: RegExp) => screen.getByRole('button', { name });

const activeTab = () => screen.getAllByRole('tab').find((tab) => tab.getAttribute('aria-selected') === 'true')?.textContent;

const abilityRow = (name: string) => screen.getByRole('listitem', { name });

test('до клятвы видны все три предложенные клятвы, их обеты и венцы', () => {
  setup();
  for (const name of ['Добыча', 'Месть', 'Долг крови']) {
    expect(screen.getAllByText(name).length).toBeGreaterThan(0);
  }
  expect(screen.getAllByText(/Плечом к плечу/).length).toBeGreaterThan(0);
  expect(screen.getAllByText(/Схрон крови/).length).toBeGreaterThan(0);
});

test('узелок клятвы виден до выбора и после клятвы', () => {
  const kit = 'изолированные перчатки, мультитул';
  const ui = setup({ offer_texts: [{ ...oath('heist', 'Добыча', 'Без крови'), kit }, oath('vendetta', 'Месть', 'Тень')] });
  expect(screen.getByText(kit)).toBeTruthy();
  expect(screen.getByText('Узелок каждому:')).toBeTruthy();
  ui.unmount();
  setup({ ...sworn(), oath_texts: { ...oath('heist', 'Добыча', 'Тень'), kit } });
  expect(screen.getByText(kit)).toBeTruthy();
  expect(screen.getByText('Узелок клятвы:')).toBeTruthy();
});

test('«Предложить» отправляет ключ выбранной клятвы', () => {
  const ui = setup();
  fireEvent.click(screen.getByRole('option', { name: /Месть/ }));
  fireEvent.click(command(/Предложить/));
  expect(sent(ui.topic, 'propose')).toEqual([{ key: 'vendetta' }]);
});

test('клятву, предложенную братом, можно подписать кровью', () => {
  const ui = setup({ proposed_key: 'vendetta', proposed_by: 'Мара Кольцова' });
  expect(screen.getAllByText(/Мара Кольцова/).length).toBeGreaterThan(0);
  fireEvent.click(command(/Подписать кровью/));
  expect(sent(ui.topic, 'sign')).toHaveLength(1);
  expect(sent(ui.topic, 'propose')).toEqual([]);
});

test('своё предложение не подписывают второй раз', () => {
  const ui = setup({ proposed_key: 'heist', proposed_by: 'Иван Рудный', i_proposed: 1, i_signed: 1 });
  expect(screen.queryByRole('button', { name: /Подписать кровью/ })).toBeNull();
  key('Enter');
  expect(acts(ui.topic)).toEqual([]);
});

test('Digit2 выбирает вторую клятву, Enter предлагает её', () => {
  const ui = setup();
  key('Digit2');
  expect(screen.getByRole('option', { name: /Месть/ }).getAttribute('aria-selected')).toBe('true');
  key('Enter');
  expect(sent(ui.topic, 'propose')).toEqual([{ key: 'vendetta' }]);
});

test('стрелки листают клятвы и не уходят за край', () => {
  setup();
  key('ArrowDown');
  key('ArrowDown');
  key('ArrowDown');
  expect(screen.getByRole('option', { name: /Долг крови/ }).getAttribute('aria-selected')).toBe('true');
  key('ArrowUp');
  expect(screen.getByRole('option', { name: /Месть/ }).getAttribute('aria-selected')).toBe('true');
});

test('после клятвы видна строка условия, «Скрепить кровью» шлёт seal', () => {
  const ui = setup(sworn());
  expect(screen.getAllByText('на брате: нет').length).toBeGreaterThan(0);
  fireEvent.click(command(/Скрепить кровью/));
  expect(sent(ui.topic, 'seal')).toHaveLength(1);
});

test('Enter скрепляет текущий шаг', () => {
  const ui = setup(sworn());
  key('Enter');
  expect(sent(ui.topic, 'seal')).toHaveLength(1);
});

test('при невыполненном условии печать недоступна и причина видна', () => {
  const ui = setup({ ...sworn(), can_seal: 'на брате нет: ручной телепорт' });
  const seal = command(/Скрепить кровью/);
  expect(seal.getAttribute('aria-disabled')).toBe('true');
  expect(screen.getByText('на брате нет: ручной телепорт')).toBeTruthy();
  fireEvent.click(seal);
  key('Enter');
  expect(sent(ui.topic, 'seal')).toEqual([]);
});

test('Digit1-3 выбирают печать шага, подробности показывают, кто скрепил', () => {
  setup(sworn());
  key('Digit1');
  expect(screen.getByRole('option', { name: /Добыча: первый шаг/ }).getAttribute('aria-selected')).toBe('true');
  expect(screen.getAllByText(/Мара Кольцова/).length).toBeGreaterThan(1);
  key('Digit3');
  expect(screen.getByRole('option', { name: /Добыча: третий шаг/ }).getAttribute('aria-selected')).toBe('true');
});

test('заглушённому брату главная команда недоступна', () => {
  const ui = setup({ ...sworn(), muted: 1 });
  const seal = command(/Скрепить кровью/);
  expect(seal.getAttribute('aria-disabled')).toBe('true');
  expect(screen.getAllByText(/связь заглушена/).length).toBeGreaterThan(0);
  fireEvent.click(seal);
  key('Enter');
  expect(acts(ui.topic)).toEqual([]);
});

test('заглушённый брат не голосует, окно говорит почему', () => {
  const ui = setup({ muted: 1 });
  expect(command(/Предложить/).getAttribute('aria-disabled')).toBe('true');
  expect(screen.getByText('связь заглушена')).toBeTruthy();
  key('Enter');
  ui.unmount();
  const signing = setup({ muted: 1, proposed_key: 'vendetta', proposed_by: 'Мара Кольцова' });
  const sign = command(/Подписать кровью/);
  expect(sign.getAttribute('aria-disabled')).toBe('true');
  expect(screen.getByText('связь заглушена')).toBeTruthy();
  fireEvent.click(sign);
  key('Enter');
  expect(acts(ui.topic)).toEqual([]);
  expect(acts(signing.topic)).toEqual([]);
});

test('«это вы» - только у своей строки, ушедший без направления так не помечен', () => {
  setup({
    brother_states: [
      { name: 'Иван Рудный', state: 'ok', state_text: 'в порядке', direction: null, self: 1 },
      { name: 'Мара Кольцова', state: 'gone', state_text: 'связь пропала', direction: null, self: 0 },
    ],
  });
  expect(screen.getAllByText(/это вы/)).toHaveLength(1);
  expect(screen.getByText('связь пропала').textContent).toBe('связь пропала');
});

test('состояние брата - словами из игры, сердце частит только в настоящем крите', () => {
  const ui = setup({
    brother_states: [
      { name: 'Иван Рудный', state: 'ok', direction: null, self: 1 },
      { name: 'Мара Кольцова', state: 'crit', state_text: 'без сознания', direction: 'юг', critical: 0 },
    ],
  });
  expect(screen.getByText(/без сознания, юг/)).toBeTruthy();
  expect(ui.container.querySelector('.AntagInfoBloodBrother__heart[data-beat="racing"]')).toBeNull();
  ui.update({
    brother_states: [
      { name: 'Иван Рудный', state: 'ok', direction: null, self: 1 },
      { name: 'Мара Кольцова', state: 'crit', state_text: 'без сознания', direction: 'юг', critical: 1 },
    ],
  });
  expect(ui.container.querySelector('.AntagInfoBloodBrother__heart[data-beat="racing"]')).not.toBeNull();
});

test('разорванный брат остаётся в шапке: нить рвётся, подпись называет обряд', () => {
  const ui = setup(sworn());
  ui.update({
    brother_states: [
      fixture.brother_states[0],
      { name: 'Мара Кольцова', state: 'severed', state_text: 'клятву разорвали: обряд', direction: null, self: 0 },
    ],
  });
  expect(screen.getByText('клятву разорвали: обряд')).toBeTruthy();
  expect(ui.container.querySelectorAll('.AntagInfoBloodBrother__strand--snapping')).toHaveLength(2);
});

test('финал виден при выборе, в данной клятве и после третьей печати - по каждому брату', () => {
  const ui = setup();
  expect(screen.getAllByText(/К концу смены:/).length).toBeGreaterThan(0);
  ui.unmount();
  const given = setup(sworn());
  expect(given.container.querySelector('.AntagInfoBloodBrother__detail')?.textContent).toMatch(/К концу смены: всем живым братьям/);
  given.unmount();
  const done = sworn();
  done.oath.steps = done.oath.steps.map((step) => ({ ...step, sealed: 1, sealed_by: 'Иван Рудный', condition: null }));
  const check = {
    brothers: [
      { name: 'Иван Рудный', status: 'на ЦК', done: 1 },
      { name: 'Мара Кольцова', status: 'в наручниках', done: 0 },
    ],
    extra: 'шаттл угнан',
    extra_done: 0,
  };
  setup({ ...done, current_step: 0, tier: 3, finale_check: check });
  expect(screen.getByText(/К концу смены: всем живым братьям - до ЦК, без наручников/)).toBeTruthy();
  const finale = screen.getByLabelText('Финал');
  expect(within(finale).getByText('Мара Кольцова - в наручниках')).toBeTruthy();
  expect(within(finale).getByText('шаттл угнан: нет')).toBeTruthy();
});

test('зажатый Enter не повторяет команду', () => {
  const ui = setup();
  key('Enter', { repeat: true });
  fireEvent.keyDown(command(/Предложить/), { code: 'Enter', repeat: true });
  expect(acts(ui.topic)).toEqual([]);
  key('Enter');
  expect(sent(ui.topic, 'propose')).toHaveLength(1);
});

test('третьему брату предыстория подписана как чужая, окно ждёт подписи остальных', () => {
  setup({ backstory_owner: 0, proposed_key: 'heist', proposed_by: 'Иван Рудный', i_proposed: 1, i_signed: 1, unsigned: ['Мара Кольцова'] });
  expect(screen.getByText('Их общая история:')).toBeTruthy();
  expect(screen.getAllByText(/Ждём подписи: Мара Кольцова/).length).toBeGreaterThan(0);
});

test('перезарядки с наградой обета короче, слот вербовки и шёпоты видны во «Связи»', () => {
  const recruit = { name: 'Принять в братство', desc: 'Позвать третьего.', how: 'Встать вплотную.', cooldown: 30, passive: 0 };
  const ladder = [{ ...fixture.bond_ladder[0], abilities: [...fixture.bond_ladder[0].abilities, recruit] }, ...fixture.bond_ladder.slice(1)];
  const whispers = [{ name: 'Мара Кольцова', text: 'жду у шлюза & молчу', time: '12:40' }];
  const ui = setup({
    ...sworn(),
    bond_ladder: ladder,
    cooldown_mult: 0.75,
    recruit: { name: 'Принять в братство', slot: 'открыта замена' },
    whispers,
  });
  fireEvent.click(screen.getByRole('tab', { name: 'Связь' }));
  expect(within(abilityRow('Кровь за кровь')).getByText(/перезарядка 1 мин 30 с/)).toBeTruthy();
  expect(within(abilityRow('Принять в братство')).getByText('открыта замена')).toBeTruthy();
  expect(screen.getByText('жду у шлюза & молчу')).toBeTruthy();
  ui.update({ muted: 1 });
  expect(screen.queryByText('жду у шлюза & молчу')).toBeNull();
});

test('все шаги скреплены - кнопки печати нет, три печати стоят, узел затянут', () => {
  const done = sworn();
  done.oath.steps = done.oath.steps.map((step) => ({ ...step, sealed: 1, sealed_by: 'Иван Рудный', condition: null }));
  const ui = setup({ ...done, current_step: 0, can_seal: 'всё скреплено', tier: 3 });
  expect(screen.queryByRole('button', { name: /Скрепить кровью/ })).toBeNull();
  expect(ui.container.querySelectorAll('.AntagInfoBloodBrother__print .AntagInfoBloodBrother__seal--fresh')).toHaveLength(3);
  expect(ui.container.querySelector('.AntagInfoBloodBrother__knot')?.getAttribute('data-tier')).toBe('3');
});

test('вкладки переключаются кликом, Tab и Shift+Tab', () => {
  setup(sworn());
  expect(activeTab()).toBe('Клятва');
  fireEvent.click(screen.getByRole('tab', { name: 'Памятка' }));
  expect(activeTab()).toBe('Памятка');
  expect(screen.getByText('Майндшилд глушит связь.')).toBeTruthy();
  key('Tab');
  expect(activeTab()).toBe('Клятва');
  key('Tab');
  expect(activeTab()).toBe('Связь');
  key('Tab', { shiftKey: true });
  expect(activeTab()).toBe('Клятва');
});

test('способность в подвале открывает «Связь» на своей строке', () => {
  setup(sworn());
  const footer = screen.getByRole('navigation', { name: 'Открытые способности' });
  fireEvent.click(within(footer).getByRole('link', { name: 'Кровь за кровь' }));
  expect(activeTab()).toBe('Связь');
  expect(abilityRow('Кровь за кровь').getAttribute('aria-current')).toBe('true');
  expect(within(abilityRow('Кровь за кровь')).getByText(/открыто/)).toBeTruthy();
});

test('закрытая способность ждёт своей печати, венец берётся из клятвы', () => {
  setup(sworn());
  fireEvent.click(screen.getByRole('tab', { name: 'Связь' }));
  expect(within(abilityRow('Ярость за брата')).getByText('откроет печать 2')).toBeTruthy();
  expect(within(abilityRow('Схрон крови')).getByText('откроет печать 3')).toBeTruthy();
  expect(within(abilityRow('Шёпот крови')).getByText(/перезарядка 2 с/)).toBeTruthy();
});

test('кнопка клятвы стоит на первой ступени с подписью клятвы и открыта в подвале', () => {
  const sign = { name: 'Знак братства', desc: 'Знак кровью на полу.', how: 'Встать на клетку.', cooldown: 10, passive: 0 };
  setup({ ...sworn(), bond_ladder: [...fixture.bond_ladder, { tier: 0, abilities: [sign], label: 'Клятва «Знак братства» даёт' }] });
  const footer = screen.getByRole('navigation', { name: 'Открытые способности' });
  fireEvent.click(within(footer).getByRole('link', { name: 'Знак братства' }));
  expect(activeTab()).toBe('Связь');
  expect(within(abilityRow('Знак братства')).getByText('Клятва «Знак братства» даёт')).toBeTruthy();
  expect(within(abilityRow('Знак братства')).getByText('открыто')).toBeTruthy();
  expect(within(abilityRow('Шёпот крови')).queryByText(/даёт/)).toBeNull();
});

test('у заглушённого брата открытые способности заглушены', () => {
  setup({ ...sworn(), muted: 1 });
  fireEvent.click(screen.getByRole('tab', { name: 'Связь' }));
  expect(within(abilityRow('Кровь за кровь')).getByText('заглушено')).toBeTruthy();
});

test('нить детерминирована, рвётся у ушедшего и мёртвого', () => {
  const first = threadPath('Иван Рудный', 'Мара Кольцова', 40, 300, 'ok', 'ok');
  expect(threadPath('Иван Рудный', 'Мара Кольцова', 40, 300, 'ok', 'ok')).toEqual(first);
  expect(threadPath('Иван Рудный', 'Сева Лом', 40, 300, 'ok', 'ok')).not.toEqual(first);
  expect(first).toHaveLength(1);
  expect(threadPath('Иван Рудный', 'Мара Кольцова', 40, 300, 'ok', 'gone')).toHaveLength(2);
  expect(threadPath('Иван Рудный', 'Мара Кольцова', 40, 300, 'dead', 'ok')).toHaveLength(2);
});

test('нить провисает к раненому брату', () => {
  const lowest = (paths: string[]) => Math.max(...paths.join(' ').match(/-?\d+(\.\d+)?/g)!.filter((_, index) => index % 2).map(Number));
  const taut = lowest(threadPath('А', 'Б', 40, 300, 'ok', 'ok'));
  const sagging = lowest(threadPath('А', 'Б', 40, 300, 'ok', 'crit'));
  expect(sagging).toBeGreaterThan(taut + 4);
});

test('три брата: шапка показывает всех, сердце мёртвого остановилось', () => {
  const ui = setup({
    ...sworn(),
    brothers: [...fixture.brothers, { name: 'Сева Лом', job: 'Cook' }],
    brother_states: [...fixture.brother_states, { name: 'Сева Лом', state: 'dead', direction: 'ниже' }],
  });
  expect(screen.getAllByText('Сева Лом').length).toBeGreaterThan(0);
  expect(screen.getAllByText(/нет пульса/).length).toBeGreaterThan(0);
  expect(ui.container.querySelectorAll('.AntagInfoBloodBrother__heart[data-beat="still"]')).toHaveLength(1);
  expect(ui.container.querySelectorAll('.AntagInfoBloodBrother__heart[data-beat="fast"]')).toHaveLength(1);
});

test('печать оттискивается, когда печатей стало больше, а на первом рендере нет', () => {
  const ui = setup(sworn());
  expect(stamping(ui.container)).toHaveLength(0);
  ui.update(sealSecond());
  const pressed = stamping(ui.container);
  expect(pressed).toHaveLength(1);
  expect(within(pressed[0] as HTMLElement).getByText(/Добыча: второй шаг/)).toBeTruthy();
  expect(pressed[0].querySelector('.AntagInfoBloodBrother__sealGhost')).not.toBeNull();
  fireEvent.animationEnd(pressed[0].querySelector('.AntagInfoBloodBrother__printNote')!);
  expect(stamping(ui.container)).toHaveLength(0);
  expect(ui.container.querySelectorAll('.AntagInfoBloodBrother__print .AntagInfoBloodBrother__seal--fresh')).toHaveLength(2);
});

test('уже скреплённая клятва при открытии окна ничего не оттискивает', () => {
  const ui = setup(sealSecond());
  expect(stamping(ui.container)).toHaveLength(0);
  ui.update({ deadline_left: 10 });
  expect(stamping(ui.container)).toHaveLength(0);
});

test('без движения печать просто встаёт, нить и узел меняются без анимаций', () => {
  prefersReducedMotion();
  const ui = setup(sworn());
  ui.update({ ...sealSecond(), tier: 2, bond_pulse: 4 });
  expect(stamping(ui.container)).toHaveLength(0);
  expect(ui.container.querySelectorAll('.AntagInfoBloodBrother__print .AntagInfoBloodBrother__seal--fresh')).toHaveLength(2);
  expect(ui.container.querySelector('.AntagInfoBloodBrother__knot')?.getAttribute('data-tier')).toBe('2');
  expect(ui.container.querySelector('.AntagInfoBloodBrother__knot--tightening')).toBeNull();
  expect(ui.container.querySelector('.AntagInfoBloodBrother__bead')).toBeNull();
});

test('новая ступень затягивает узел, шёпот пускает каплю по нити', () => {
  const ui = setup({ ...sworn(), bond_pulse: 3 });
  expect(ui.container.querySelector('.AntagInfoBloodBrother__knot--tightening')).toBeNull();
  expect(ui.container.querySelector('.AntagInfoBloodBrother__bead')).toBeNull();
  ui.update({ tier: 2 });
  expect(ui.container.querySelector('.AntagInfoBloodBrother__knot--tightening')).not.toBeNull();
  ui.update({ bond_pulse: 4 });
  expect(ui.container.querySelectorAll('.AntagInfoBloodBrother__bead')).toHaveLength(1);
});

test('снятое глушение не пускает каплю за шёпоты, которых заглушённый не слышал', () => {
  const ui = setup({ ...sworn(), muted: 1, bond_pulse: null });
  ui.update({ muted: 0, bond_pulse: 7 });
  expect(ui.container.querySelector('.AntagInfoBloodBrother__bead')).toBeNull();
  ui.update({ bond_pulse: 8 });
  expect(ui.container.querySelectorAll('.AntagInfoBloodBrother__bead')).toHaveLength(1);
});

test('нить рвётся с анимацией, только когда брат ушёл при открытом окне', () => {
  const gone = [fixture.brother_states[0], { name: 'Мара Кольцова', state: 'gone' as const, direction: null }];
  const opened = setup({ ...sworn(), brother_states: gone });
  expect(opened.container.querySelector('.AntagInfoBloodBrother__strand--snapping')).toBeNull();
  opened.unmount();
  const ui = setup(sworn());
  ui.update({ brother_states: gone });
  expect(ui.container.querySelectorAll('.AntagInfoBloodBrother__strand--snapping')).toHaveLength(2);
});

test('данная клятва проступает строками, открытая уже данной - нет', () => {
  const ui = setup({ proposed_key: 'heist', proposed_by: 'Мара Кольцова' });
  ui.update(sworn());
  expect(ui.container.querySelector('.AntagInfoBloodBrother__sworn--written')).not.toBeNull();
  ui.unmount();
  const opened = setup(sworn());
  expect(opened.container.querySelector('.AntagInfoBloodBrother__sworn--written')).toBeNull();
});

test('после исполненной клятвы следующие предлагаются без срока, рядом финал, венец прежней открыт', () => {
  const done = sworn();
  done.oath.steps = done.oath.steps.map((step) => ({ ...step, sealed: 1, sealed_by: 'Иван Рудный', condition: null }));
  const heistCapstone = { ...capstones.heist, how: 'Кнопка слева сверху.', cooldown: 300, passive: 0 };
  const ui = setup({
    ...done,
    state: 'next',
    offered: ['vendetta', 'debt'],
    offer_texts: [{ ...oath('vendetta', 'Месть', 'Тень'), summary: 'забрать ID-карту предателя' }, oath('debt', 'Долг крови', 'Тень')],
    current_step: 0,
    tier: 3,
    deadline_left: 0,
    finale_check: { brothers: [{ name: 'Иван Рудный', status: 'ещё на станции', done: 0 }], extra: null, extra_done: 1 },
    fulfilled: ['Добыча'],
    earned_capstones: ['Схрон крови'],
    bond_ladder: [...fixture.bond_ladder, { tier: 3, abilities: [heistCapstone], label: 'Венец исполненной клятвы «Добыча»' }],
  });
  expect(screen.getByText('Клятва «Добыча» исполнена · следующая - по желанию')).toBeTruthy();
  expect(screen.queryByText(/осталось/)).toBeNull();
  expect(screen.getByText('забрать ID-карту предателя')).toBeTruthy();
  expect(screen.getAllByText(/венец добавится к прежним/).length).toBeGreaterThan(0);
  expect(within(screen.getByLabelText('Финал')).getByText('Иван Рудный - ещё на станции')).toBeTruthy();
  fireEvent.click(command(/Предложить/));
  expect(sent(ui.topic, 'propose')).toEqual([{ key: 'vendetta' }]);
  fireEvent.click(screen.getByRole('tab', { name: 'Связь' }));
  expect(within(abilityRow('Схрон крови')).getByText('открыто')).toBeTruthy();
  expect(within(abilityRow('Метка крови')).getByText('откроет последняя печать клятвы')).toBeTruthy();
});

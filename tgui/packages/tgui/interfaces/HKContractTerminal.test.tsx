import { act as reactAct, fireEvent, render, screen, within } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { chargeBar, formatSeconds, HKContractTerminal, HKContractTerminalData, pointsWord, Ticker } from './HKContractTerminal';

const PHOTO = 'iVBORw0KGgo=';

const offer = (ref: string, task: string, kind: string, target: string) => ({
  ref,
  id: ref,
  client: 'Синдикат',
  client_flavor: 'Платит за кровь.',
  client_bonus: 0,
  perk: null as string | null,
  dirty: 1,
  task,
  kind,
  hunt: 0,
  identified: 0,
  target,
  rules: 'Правила задачи.',
  modifier: null,
  modifier_rules: null,
  points: 1,
  bonus: 0,
  lethal: 1,
  unavailable: null as string | null,
});

const station = {
  status_name: 'тайный',
  status_text: 'станция обо мне не знает.',
  threat: 0,
  threat_max: 2,
  extraction_available: 0,
  extraction_reason: 'встаньте у клетки с открытым космосом',
  extraction_text: 'Сигнал у клетки с открытым космосом.',
};

const fixture: HKContractTerminalData = {
  points: 2,
  contracts_done: 1,
  contracts_needed: 3,
  charge: 300,
  charge_max: 450,
  rifle: { shots: 9, sniper: 0, sniper_mode: 0, sniper_cooldown: 0, stun_mode: 0 },
  shield: null,
  rifle_max: 12,
  identify_range: 2,
  protect_presence_needed: 40,
  photos: { '[0x1]': PHOTO, '[0x2]': PHOTO, '[0x3]': PHOTO, '[0x8]': PHOTO, '[0x9]': PHOTO },
  reroll_cooldown: 0,
  identify_cooldown: 0,
  scanning: 0,
  offers: [
    offer('[0x1]', 'ликвидация', 'kill', 'Джон Доу (Captain)'),
    { ...offer('[0x2]', 'охота на охотника', 'hunt', 'Тайный Агент'), hunt: 1 },
    { ...offer('[0x3]', 'саботаж', 'sabotage', 'R&D Server (Серверная)'), modifier: 'срочно', modifier_rules: 'За 10 минут.', points: 2, bonus: 1 },
  ],
  active: null,
  catalog: [
    { id: 'sniper', name: 'Снайперский режим', summary: 'Утверждение: второй режим.', specs: 'ПРИЦЕЛ 1.5 с', price_curve: null, repeatable: 0 },
    { id: 'plates', name: 'Бронеплиты', summary: 'Утверждение: сталь.', specs: 'БРОНЯ +10', price_curve: null, repeatable: 0 },
    { id: 'servants', name: 'Пара HK-50', summary: 'Утверждение: копии.', specs: 'СЛУЖБА 5 мин', price_curve: '1, 2, ДАЛЕЕ 3', repeatable: 1 },
    { id: 'ghost_servant', name: 'HK-50 с разумом', summary: 'Вопрос: разум?', specs: 'РАЗОВО', price_curve: null, repeatable: 0 },
  ],
  upgrades: [
    { id: 'sniper', cost: 1, owned: 0, available: 1, reason: null, status: null },
    { id: 'plates', cost: 1, owned: 1, available: 0, reason: 'уже установлено.', status: null },
    { id: 'servants', cost: 2, owned: 1, available: 0, reason: 'пара HK-50 ещё на службе.', status: 'На службе: 2 из 2' },
    { id: 'ghost_servant', cost: 2, owned: 0, available: 1, reason: null, status: null },
  ],
  history: [
    { contract: 'Синдикат: ликвидация - Боб', outcome: 'done', kind: 'kill', points: 1, comment: 'Комментарий: мешок с мясом больше не дышит.' },
    { contract: 'Частное лицо: охрана - Ева', outcome: 'failed', kind: 'protect', points: 0, comment: 'Комментарий: досадный сбой.' },
  ],
  tallies: { killed: 1, captured: 2, stolen: 3, sabotaged: 4 },
  ticker: 'Комментарий: досадный сбой.',
  station: null,
  extraction_ready: 0,
};

const activeHunt = {
  ...offer('[0x9]', 'охота на охотника', 'hunt', 'Скрытый Антагонист'),
  hunt: 1,
  deadline: 125,
  deadline_kind: 'urgent' as const,
  trace: { area: 'Бар', minutes: 4, cold: 0, near: 1 },
  radar: null,
  can_scan: 1,
  can_capture: 1,
  capture_called: 0,
  suspects: [{ ref: '[0x77]', name: 'Подозрительный клоун' }],
};

const activeKill = {
  ...offer('[0x8]', 'ликвидация', 'kill', 'Джон Доу (Clown)'),
  deadline: null,
  deadline_kind: 'urgent' as const,
  radar: { distance: 7, band: 'near' as const, direction: 'восток', angle: 90 },
  can_scan: 1,
  can_capture: 0,
  capture_called: 0,
  suspects: [],
};

const setup = (overrides: Partial<HKContractTerminalData> = {}) => {
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'HKContractTerminal' }, data: { ...fixture, ...overrides } }));
  return { ...render(<HKContractTerminal />), topic };
};

const sent = (topic: jest.Mock, action: string) =>
  topic.mock.calls.filter(([message]) => message.type === `act/${action}`).map(([message]) => JSON.parse(message.payload));

const key = (code: string, target: Window | Element = window) => fireEvent.keyDown(target, { code });

const selectedRow = () => screen.getAllByRole('option').find((row) => row.getAttribute('aria-selected') === 'true');

test('досье слева одной строкой, выбранное справа со снимком и командой', () => {
  setup();
  expect(screen.getAllByRole('option')).toHaveLength(3);
  expect(screen.getByText('== ДОСЬЕ 1/3 ==')).toBeTruthy();
  expect(screen.getByText('[СРОЧНО]')).toBeTruthy();
  expect(document.querySelector('.HKContractTerminal__photoImg')?.getAttribute('src')).toBe(`data:image/png;base64,${PHOTO}`);
  fireEvent.click(screen.getAllByRole('option')[2]);
  expect(screen.getByText('== ДОСЬЕ 3/3 ==')).toBeTruthy();
  expect(screen.getByText('[ПРИНЯТЬ КОНТРАКТ]')).toBeTruthy();
});

test('протокол прячется за [?]', () => {
  setup();
  expect(screen.queryByText('Правила задачи.')).toBeNull();
  fireEvent.click(screen.getByText('[?] ПРОТОКОЛ'));
  expect(screen.getByText('Правила задачи.')).toBeTruthy();
});

test('скрытая цель: ни имени, ни снимка - только помехи и [ЗАСЕКРЕЧЕНО]', () => {
  const { container } = setup();
  fireEvent.click(screen.getAllByRole('option')[1]);
  expect(container.innerHTML).not.toContain('Тайный Агент');
  expect(document.querySelector('.HKContractTerminal__photoImg')).toBeNull();
  expect(document.querySelector('.HKContractTerminal__static')).toBeTruthy();
  expect(screen.getAllByText('[ЗАСЕКРЕЧЕНО]').length).toBeGreaterThan(0);
});

test('активная охота: помехи вместо снимка, след, большой таймер и сверка сигнатуры', () => {
  const { container, topic } = setup({ offers: [], active: activeHunt });
  expect(container.innerHTML).not.toContain('Скрытый Антагонист');
  expect(document.querySelector('.HKContractTerminal__photoImg')).toBeNull();
  expect(screen.getByText('Бар, 4 мин. назад')).toBeTruthy();
  expect(screen.getByText('02:05').className).toContain('timer');
  expect(screen.queryByTestId('hk-blip')).toBeNull();
  expect(screen.getByTestId('hk-pulse')).toBeTruthy();
  expect(screen.getByText('СИГНАТУРА РЯДОМ')).toBeTruthy();
  const identify = screen.getByText('[СВЕРИТЬ СИГНАТУРУ: Подозрительный клоун]');
  expect(identify.className).toContain('primary');
  fireEvent.click(identify);
  expect(sent(topic, 'identify')).toEqual([{ ref: '[0x77]' }]);
  expect(screen.queryByText('[СКАН]')).toBeNull();
});

test('активная ликвидация: метка на радаре, большой [СКАН] и отказ', () => {
  const ui = setup({ offers: [], active: activeKill });
  const blip = screen.getByTestId('hk-blip');
  expect(Number(blip.getAttribute('cx'))).toBeGreaterThan(0);
  expect(Number(blip.getAttribute('cy'))).toBe(0);
  expect(screen.getByText('РЯДОМ: 7 кл., восток')).toBeTruthy();
  const scan = screen.getByText('[СКАН]');
  expect(scan.className).toContain('primary');
  fireEvent.click(scan);
  expect(scan.className).toContain('flash');
  fireEvent.click(screen.getByText('[ОТКАЗ]'));
  expect(sent(ui.topic, 'scan')).toHaveLength(1);
  expect(sent(ui.topic, 'reroll')).toHaveLength(1);
});

test('клавиши: 1-3 вкладки, стрелки и j/k по списку, Enter принимает выбранное, покупка - вторым Enter', () => {
  const ui = setup();
  key('ArrowDown');
  key('KeyJ');
  expect(selectedRow()?.textContent).toContain('САБОТАЖ');
  key('KeyK');
  expect(selectedRow()?.textContent).toContain('ОХОТА');
  key('Enter');
  expect(sent(ui.topic, 'accept')).toEqual([{ ref: '[0x2]' }]);
  key('Digit3');
  expect(screen.getByText(/ЛИКВИДИРОВАНО МЕШКОВ С МЯСОМ: 1/)).toBeTruthy();
  key('Digit2');
  key('Enter');
  expect(sent(ui.topic, 'buy')).toHaveLength(0);
  expect(screen.getAllByText('[ПОДТВЕРДИТЬ?]').length).toBeGreaterThan(0);
  key('Enter');
  expect(sent(ui.topic, 'buy')).toEqual([{ id: 'sniper' }]);
  key('ArrowDown');
  key('Enter');
  key('Enter');
  expect(sent(ui.topic, 'buy')).toHaveLength(1);
});

test('Enter и пробел на команде в фокусе нажимают её, а не принимают выбранное досье', () => {
  const ui = setup();
  const refuse = screen.getByText('[ОТКЛОНИТЬ ВСЕ]');
  fireEvent.keyDown(refuse, { code: 'Enter', key: 'Enter' });
  expect(sent(ui.topic, 'reroll')).toHaveLength(1);
  expect(sent(ui.topic, 'accept')).toHaveLength(0);
  fireEvent.keyDown(screen.getByText('[ПРИНЯТЬ КОНТРАКТ]'), { code: 'Space', key: ' ' });
  expect(sent(ui.topic, 'accept')).toEqual([{ ref: '[0x1]' }]);
});

test('при наборе текста клавиши терминала не срабатывают', () => {
  const ui = setup();
  const input = document.createElement('input');
  document.body.appendChild(input);
  key('Digit2', input);
  key('Enter', input);
  input.remove();
  expect(screen.getByText('== ДОСЬЕ 1/3 ==')).toBeTruthy();
  expect(sent(ui.topic, 'accept')).toHaveLength(0);
});

test('модули: [УСТАНОВИТЬ] прямо в строке, второе нажатие подтверждает покупку, состояние видно сразу', () => {
  const ui = setup();
  fireEvent.click(screen.getByText('[2] МОДУЛИ'));
  const rows = screen.getAllByRole('option');
  expect(rows[1].textContent).toContain('УСТАНОВЛЕН');
  expect(rows[2].textContent).toContain('НЕДОСТУПЕН');
  fireEvent.click(within(rows[3]).getByText('[УСТАНОВИТЬ]'));
  expect(sent(ui.topic, 'buy')).toHaveLength(0);
  fireEvent.click(within(rows[3]).getByText('[ПОДТВЕРДИТЬ?]'));
  expect(sent(ui.topic, 'buy')).toEqual([{ id: 'ghost_servant' }]);
  expect(selectedRow()?.textContent).toContain('СНАЙПЕРСКИЙ РЕЖИМ');
  fireEvent.click(rows[2]);
  expect(screen.getByText('(пара HK-50 ещё на службе)')).toBeTruthy();
  expect(screen.getByText('рост цены: 1, 2, ДАЛЕЕ 3')).toBeTruthy();
  expect(screen.getByText('На службе: 2 из 2')).toBeTruthy();
});

test('журнал: счёт сверху, свежие записи первыми, комментарий HK справа', () => {
  setup();
  fireEvent.click(screen.getByText('[3] ЖУРНАЛ'));
  expect(screen.getByText('ЛИКВИДИРОВАНО МЕШКОВ С МЯСОМ: 1 / ЗАХВАЧЕНО: 2 / УКРАДЕНО: 3 / СОРВАНО: 4')).toBeTruthy();
  expect(selectedRow()?.textContent).toContain('ПРОВАЛЕН');
  expect(screen.getAllByText('Комментарий: досадный сбой.').length).toBeGreaterThan(0);
});

test('эвакуация: большая команда, причина отказа в скобках', () => {
  const ui = setup({ contracts_done: 3, extraction_ready: 1, offers: [], station });
  const signal = screen.getByText('[ПОДАТЬ СИГНАЛ ЭВАКУАЦИИ]');
  expect(signal.className).toContain('primary');
  fireEvent.click(signal);
  expect(screen.getByText(/встаньте у клетки с открытым космосом/)).toBeTruthy();
  expect(sent(ui.topic, 'extract')).toHaveLength(0);
});

test('статус для станции в строке состояния', () => {
  setup({ station: { ...station, status_name: 'вне закона', threat: 1 } });
  expect(screen.getByText(/ВНЕ ЗАКОНА \/\/ УГРОЗА/)).toBeTruthy();
  expect(screen.getByText('1/2')).toBeTruthy();
});

test('парализующий режим винтовки виден в строке состояния', () => {
  setup({ rifle: { shots: 9, sniper: 0, sniper_mode: 0, sniper_cooldown: 0, stun_mode: 1 } });
  expect(screen.getByText('09/12 ПАРАЛ')).toBeTruthy();
});

test('щит в строке состояния: активен, перезарядка, готов', () => {
  const { unmount } = setup({ shield: { active: 1, cooldown: 60 } });
  expect(screen.getByText(/ЩИТ АКТИВЕН/)).toBeTruthy();
  unmount();
  const second = setup({ shield: { active: 0, cooldown: 7 } });
  expect(screen.getByText(/ЩИТ 07с/)).toBeTruthy();
  second.unmount();
  setup({ shield: { active: 0, cooldown: 0 } });
  expect(screen.getByText(/ЩИТ ГОТОВ/)).toBeTruthy();
});

test('бегущая строка допечатывает комментарий по символу', () => {
  jest.useFakeTimers();
  try {
    const { container } = render(<Ticker text="Комментарий: тест." />);
    expect(container.textContent).toBe('>  ');
    reactAct(() => {
      jest.advanceTimersByTime(22 * 4);
    });
    expect(container.textContent).toContain('Комм');
    reactAct(() => {
      jest.advanceTimersByTime(22 * 40);
    });
    expect(container.textContent).toContain('Комментарий: тест.');
  } finally {
    jest.useRealTimers();
  }
});

test('при сниженной анимации строка выводится сразу', () => {
  const original = window.matchMedia;
  window.matchMedia = ((query: string) => ({ matches: query.includes('reduce') })) as any;
  try {
    const { container } = render(<Ticker text="Утверждение: сразу." />);
    expect(container.textContent).toContain('Утверждение: сразу.');
  } finally {
    window.matchMedia = original;
  }
});

test('склонение очков, таймер и полоса заряда', () => {
  expect([1, 2, 5, 11, 21, 22].map(pointsWord)).toEqual(['очко', 'очка', 'очков', 'очков', 'очко', 'очка']);
  expect(formatSeconds(65)).toBe('01:05');
  expect(chargeBar(450, 450)).toBe('▓▓▓▓▓');
  expect(chargeBar(40, 450)).toBe('░░░░░');
});

test('модули: цена и причина недоступности берутся из состояния модуля', () => {
  setup({
    upgrades: [
      { id: 'sniper', cost: 3, owned: 0, available: 0, reason: 'не хватает очков: нужно 3, на счету 2.', status: null },
      ...fixture.upgrades.slice(1),
    ],
  });
  fireEvent.click(screen.getByText('[2] МОДУЛИ'));
  expect(screen.getAllByRole('option')[0].textContent).toContain('3 ОЧ');
  expect(screen.getByText('(не хватает очков: нужно 3, на счету 2)')).toBeTruthy();
});

test('досье показывает заказчика, риск и премию', () => {
  setup({
    offers: [
      { ...offer('[0x1]', 'ликвидация', 'kill', 'Джон Доу'), client_bonus: 1, points: 2 },
      { ...offer('[0x2]', 'охрана', 'protect', 'Ева'), client: 'Центральное командование', dirty: 0, perk: 'ЦК вернёт отозванную лицензию' },
    ],
  });
  expect(screen.getByText('Платит за кровь.')).toBeTruthy();
  expect(screen.getByText('грязная работа: при свидетелях - раскрытие')).toBeTruthy();
  expect(screen.getByText(/1 - премия заказчика/)).toBeTruthy();
  fireEvent.click(screen.getAllByRole('option')[1]);
  expect(screen.getByText(/чистая работа/)).toBeTruthy();
  expect(screen.getByText('+ ЦК вернёт отозванную лицензию')).toBeTruthy();
});

test('недоступное предложение помечено, не принимается и меняется бесплатно даже при кулдауне отказа', () => {
  const ui = setup({
    reroll_cooldown: 90,
    offers: [{ ...offer('[0x1]', 'ликвидация', 'kill', 'Джон Доу'), unavailable: 'цель покинула станцию.' }, fixture.offers[1]],
  });
  expect(screen.getAllByRole('option')[0].textContent).toContain('[НЕДОСТУПНО]');
  fireEvent.click(screen.getByText('[ПРИНЯТЬ КОНТРАКТ]'));
  key('Enter');
  expect(sent(ui.topic, 'accept')).toHaveLength(0);
  fireEvent.click(screen.getByText('[ОТКЛОНИТЬ ВСЕ]'));
  expect(sent(ui.topic, 'reroll')).toHaveLength(0);
  fireEvent.click(screen.getByText('[ЗАМЕНИТЬ НЕДОСТУПНЫЕ]'));
  expect(sent(ui.topic, 'replace')).toHaveLength(1);
});

test('недоступный активный контракт снимается без штрафа и при кулдауне отказа', () => {
  const clock = jest.spyOn(Date, 'now').mockReturnValue(Date.now() + 1000);
  const ui = setup({ offers: [], reroll_cooldown: 120, active: { ...activeKill, unavailable: 'цель покинула станцию.' } });
  expect(screen.getByText('[СНЯТЬ БЕЗ ШТРАФА]').className).not.toContain('off');
  fireEvent.click(screen.getByText('[СНЯТЬ БЕЗ ШТРАФА]'));
  clock.mockRestore();
  expect(sent(ui.topic, 'replace')).toHaveLength(1);
  expect(sent(ui.topic, 'reroll')).toHaveLength(0);
});

test('после контрактов для эвакуации грязная работа раскрывает и без свидетелей', () => {
  setup({ contracts_done: 3, contracts_needed: 3 });
  expect(screen.getByText('грязная работа: раскрытие даже без свидетелей')).toBeTruthy();
});

test('эвакуация и активный контракт видны вместе', () => {
  setup({ contracts_done: 3, extraction_ready: 1, offers: [], station, active: activeKill });
  expect(screen.getByText('== ЭВАКУАЦИЯ ==')).toBeTruthy();
  expect(screen.getByText('== АКТИВНЫЙ КОНТРАКТ ==')).toBeTruthy();
  expect(screen.getByText('[СКАН]')).toBeTruthy();
});

test('охрана показывает, сколько срока HK был рядом', () => {
  setup({
    offers: [],
    active: {
      ...offer('[0x5]', 'охрана', 'protect', 'Ева'),
      deadline: 300,
      deadline_kind: 'protect' as const,
      radar: null,
      can_scan: 0,
      can_capture: 0,
      capture_called: 0,
      suspects: [],
      presence: 25,
    },
  });
  expect(screen.getByText('25%').className).toContain('warn');
  expect(screen.getByText(/заказчик платит от 40%/)).toBeTruthy();
});

test('сверка без подозреваемых называет дальность из данных', () => {
  setup({ offers: [], identify_range: 3, active: { ...activeHunt, suspects: [] } });
  expect(screen.getByText(/в 3 кл\. никого не видно/)).toBeTruthy();
});

test('радар говорит, выше или ниже цель на другом уровне', () => {
  setup({ offers: [], active: { ...activeKill, radar: { other_level: 1, level: 'below' as const } } });
  expect(screen.getByText('УРОВЕНЬ НИЖЕ')).toBeTruthy();
  expect(screen.queryByTestId('hk-blip')).toBeNull();
});

import { act, fireEvent, render, screen, waitFor, within } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { ForbiddenLoreContent, ForbiddenLoreData } from './ForbiddenLore';

const makeData = (overrides: Partial<ForbiddenLoreData> = {}): ForbiddenLoreData => {
  const paths = [
    ['Ash', 'Пепел'], ['Rust', 'Ржавчина'], ['Flesh', 'Плоть'], ['Void', 'Пустота'],
    ['Blade', 'Клинок'], ['Moon', 'Луна'], ['Cosmic', 'Космос'],
    ['Lock', 'Замок'], ['Tide', 'Пучина'], ['Glass', 'Стекло'], ['Blood', 'Кровь'],
    ['Echo', 'Эхо'], ['Sand', 'Песок'], ['Wax', 'Воск'], ['Spirit', 'Дух'],
    ['Dance', 'Пляска'],
  ].map(([id, name]) => ({
    id, name, desc: `Учение: ${name}.`, strengths: ['Своя тактика.'], weaknesses: ['Своя уязвимость.'],
    innate_name: `Черта: ${name}`, innate_desc: `Врождённое свойство: ${name}.`,
  }));
  return {
    points: 2,
    total_sacrifices: 0,
    ascended: false,
    selected_path: null,
    path_stage: 0,
    paths,
    knowledge: paths.flatMap((path) => [
      {
        id: `/datum/eldritch_knowledge/${path.id.toLowerCase()}/base`,
        name: `Обет: ${path.name}`, desc: 'Первое умение.', flavour: '',
        cost: 0, sacrifices: 0, path: path.id, stage: 1, known: false,
        available: true, reason: '', kind: 'path' as const,
      },
      {
        id: `/datum/eldritch_knowledge/${path.id.toLowerCase()}/second`,
        name: `Искусство: ${path.name}`, desc: 'Продолжение пути.', flavour: 'За завесой.',
        cost: 2, sacrifices: 0, path: path.id, stage: 2, known: false,
        available: false, reason: 'Сначала примите обет.', kind: 'path' as const,
      },
    ]),
    rituals: [
      {
        id: 'blade', name: 'Пепельный клинок', desc: 'Создаёт клинок.', result: 'клинок',
        ingredients: [{ name: 'Нож', amount: 1 }, { name: 'Спичка', amount: 1 }], ascension: false,
      },
      {
        id: 'ascension', name: 'Вознесение', desc: 'Финальный ритуал.',
        ingredients: [{ name: 'Человеческий труп', amount: 3 }], ascension: true,
      },
    ],
    combat_resource: null,
    deed: null,
    hunt: {
      target_name: null, target_role: null, target_status: 'Цели ещё нет.',
      can_retarget: true, retarget_seconds: 0, sacrifices_required: 5,
      influences_harvested: 0, influence_limit: 6,
      pocket: { duration: 40, warning: 10, pull: 1, tear: 10, cooldown: 60, hold: 3, grip: 3, shake: 2 },
    },
    ...overrides,
  };
};

const setupStore = (data: ForbiddenLoreData) => {
  const topic = jest.fn();
  (global as any).Byond = { topic };
  const store = createStore(combineReducers({ backend: backendReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'ForbiddenLore' }, data }));
  return { store, topic };
};

const readActions = (topic: jest.Mock) => topic.mock.calls.filter(([message]) => message.type !== 'act/turn_page').map(([message]) => ({
  type: message.type,
  payload: JSON.parse(message.payload),
}));

const renderBook = async () => {
  const view = render(<ForbiddenLoreContent />);
  await waitFor(() => expect(view.container.querySelector('[data-book-view="living"]')).toBeTruthy());
  return view;
};

describe('Гримуар еретика', () => {
  test('подготовка показывает реальные вещи и вызывает сердце из главы охоты', async () => {
    const { topic } = setupStore(makeData({
      selected_path: 'Blade',
      preparation: {
        blade_ready: false, blade_status: 'Клинка при вас нет.',
        armor_ready: true, armor_status: 'Мантия надета.',
        heart: { ready: false, can_call: true, status: 'Сердце за завесой.', action_label: 'Призвать своё сердце' },
      },
    }));
    await renderBook();
    expect(screen.queryByRole('region', { name: 'Подготовка к охоте' })).toBeNull();
    fireEvent.click(screen.getByRole('tab', { name: 'Охота' }));
    const preparation = screen.getByRole('region', { name: 'Подготовка к охоте' });
    expect(within(preparation).getByText('1 из 3')).toBeTruthy();
    expect(within(preparation).getByText('Клинка при вас нет.')).toBeTruthy();
    expect(within(preparation).getByText('Мантия надета.').parentElement?.className).toBe('HereticBook__check--ready');
    expect(within(preparation).getByText('Сердце за завесой.')).toBeTruthy();
    fireEvent.click(within(preparation).getByRole('button', { name: 'Проверить подготовку' }));
    fireEvent.click(within(preparation).getByRole('button', { name: 'Призвать своё сердце' }));
    expect(readActions(topic).map((message) => message.type)).toEqual(['act/refresh_preparation', 'act/call_heart']);
  });

  test('сердце в чужих руках нельзя вызвать, а завершённое дело не предлагает следующий шаг', async () => {
    const { topic } = setupStore(makeData({
      selected_path: 'Cosmic',
      preparation: {
        blade_ready: true, blade_status: 'Клинок при вас.',
        armor_ready: true, armor_status: 'Мантия и капюшон надеты.',
        heart: { ready: false, can_call: false, status: 'Сердце удерживает другой человек.', action_label: 'Вернуть своё сердце' },
      },
      deed: { name: 'Небо над отделами', desc: 'Дело завершено.', hint: '', next_step: 'Зажгите звезду.', tier: 3, max_tier: 3, progress: 0, goal: 0, counted: 6 },
    }));
    await renderBook();
    fireEvent.click(screen.getByRole('tab', { name: 'Охота' }));
    expect(within(screen.getByRole('region', { name: 'Подготовка к охоте' })).getByText('2 из 3')).toBeTruthy();
    expect(screen.getByRole('button', { name: 'Вернуть своё сердце' }).hasAttribute('disabled')).toBe(true);
    expect(screen.queryByText('Зажгите звезду.')).toBeNull();
    fireEvent.click(screen.getByRole('button', { name: 'Вернуть своё сердце' }));
    expect(readActions(topic)).toEqual([]);
  });

  test.each(makeData().paths)('$name: врождённая черта видна до выбора пути', async (path) => {
    setupStore(makeData());
    await renderBook();
    fireEvent.click(screen.getByRole('button', { name: path.name }));
    expect(await screen.findByText(`Врождённая черта: ${path.innate_name}`)).toBeTruthy();
    expect(screen.getByText(path.innate_desc!)).toBeTruthy();
    expect(screen.getByText('Действует с выбора пути, без затрат знаний.')).toBeTruthy();
  });

  test.each(makeData().paths)('$name: дело и прогресс видны под разворотом и в охоте', async (path) => {
    const deed = { name: `Дело: ${path.name}`, desc: `Действие пути ${path.name}.`, hint: '', next_step: `Шаг пути ${path.name}.`, tier: 0, max_tier: 3, progress: 1, goal: 2, counted: 1 };
    const { store } = setupStore(makeData({ selected_path: path.id, path_stage: 1, deed }));
    const view = await renderBook();
    const ledger = within(screen.getByRole('group', { name: 'Знания и сила' }));
    const line = ledger.getByRole('button', { name: /^Дело:/ });
    expect(line.textContent).toBe(`${deed.name} I · 1/2`);
    expect(line.getAttribute('title')).toBe(deed.next_step);
    fireEvent.click(line);
    const section = within(screen.getByRole('region', { name: 'Дело пути' }));
    expect(section.getByText(deed.desc)).toBeTruthy();
    expect(section.getByText('Ступень 1 из 3 · 1 из 2')).toBeTruthy();
    expect(section.getByText(deed.next_step).textContent).toBe(`Дальше. ${deed.next_step}`);
    act(() => store.dispatch(backendUpdate({ data: { deed: { ...deed, tier: 1, progress: 0, goal: 3 } } })));
    view.rerender(<ForbiddenLoreContent />);
    expect(section.getByText('Ступень 2 из 3 · 0 из 3')).toBeTruthy();
    expect(line.textContent).toBe(`${deed.name} II · 0/3`);
    act(() => store.dispatch(backendUpdate({ data: { deed: { ...deed, tier: 3, progress: 0, goal: 0 } } })));
    view.rerender(<ForbiddenLoreContent />);
    expect(section.getByText('Дело завершено.')).toBeTruthy();
    expect(section.queryByText('Каждая ступень приносит очко знаний.')).toBeNull();
    expect(line.textContent).toBe(`${deed.name} завершено`);
  });

  test.each(makeData().paths)('$name: клавиши видны в содержании рядом со способностями', async (path) => {
    const ability = { id: 'grasp', name: 'Хватка Мансуса', summary: 'Ставит метку.', desc: 'Хватка.', usage: 'Коснитесь цели.', hotkey: 'Alt+1' };
    const help = 'Отмена подготовки: Alt+Q или Q. Переназначение - в настройках клавиш.';
    setupStore(makeData({ selected_path: path.id, path_stage: 1, combat_abilities: [ability], ability_hotkey_help: help }));
    await renderBook();
    const group = within(screen.getByRole('region', { name: 'Способности' }));
    const line = group.getByRole('button', { name: ability.name });
    expect(within(line).getByText('Alt+1').tagName).toBe('KBD');
    expect(line.getAttribute('title')).toBe(ability.summary);
    fireEvent.click(screen.getByRole('tab', { name: 'Помощь' }));
    expect(screen.getByText(help).closest('details')?.getAttribute('data-topic')).toBe('hotkeys');
  });

  test('обновляет клавиши в открытой книге и явно показывает снятое назначение', async () => {
    const ability = { id: 'grasp', name: 'Хватка Мансуса', desc: 'Хватка.', usage: 'Коснитесь цели.', hotkey: 'Alt+1' };
    const { store } = setupStore(makeData({ selected_path: 'Ash', path_stage: 1, combat_abilities: [ability] }));
    const view = await renderBook();
    const button = screen.getByRole('button', { name: ability.name });
    act(() => store.dispatch(backendUpdate({ data: { combat_abilities: [{ ...ability, hotkey: 'Ctrl+Shift+F2 / F3' }] } })));
    view.rerender(<ForbiddenLoreContent />);
    expect(within(button).getByText('Ctrl+Shift+F2 / F3')).toBeTruthy();
    expect(within(button).queryByText('Alt+1')).toBeNull();
    act(() => store.dispatch(backendUpdate({ data: { combat_abilities: [{ ...ability, hotkey: 'Не назначена' }] } })));
    view.rerender(<ForbiddenLoreContent />);
    expect(within(button).getByText('Не назначена')).toBeTruthy();
  });

  test('выданные способности открывают применение без покупки или каста из книги', async () => {
    const ability = { id: 'sever', name: 'Разлучение', summary: 'Отделяет душу.', desc: 'Отделяет душу врага.', usage: 'Нажмите кнопку, затем укажите цель.', hotkey: 'Alt+2' };
    const { store, topic } = setupStore(makeData({ selected_path: 'Spirit', path_stage: 1, combat_abilities: [ability] }));
    const view = await renderBook();
    fireEvent.click(screen.getByRole('button', { name: 'Разлучение' }));
    const right = within(screen.getByRole('article', { name: 'Правая страница' }));
    expect(right.getByRole('heading', { name: 'Разлучение' })).toBeTruthy();
    expect(right.getByText(ability.summary).className).toContain('HereticBook__lead');
    expect(right.getByText(ability.desc)).toBeTruthy();
    expect(right.getByText(ability.usage)).toBeTruthy();
    expect(right.getByText('Alt+2')).toBeTruthy();
    expect(right.queryByRole('button', { name: /Изучить/ })).toBeNull();
    expect(readActions(topic)).toEqual([]);
    act(() => store.dispatch(backendUpdate({ data: { combat_abilities: [] } })));
    view.rerender(<ForbiddenLoreContent />);
    expect(screen.queryByRole('button', { name: 'Разлучение' })).toBeNull();
    expect(right.queryByRole('heading', { name: 'Разлучение' })).toBeNull();
    expect(right.getByRole('heading', { name: 'Обет: Дух' })).toBeTruthy();
  });

  test('подготовка ведёт к рецепту брони, который покупается за побочные очки после открытия ступени', async () => {
    const data = makeData({
      selected_path: 'Spirit', path_stage: 1, points: 0, side_points: 2,
      preparation: {
        blade_ready: true, blade_status: 'Клинок при вас.',
        armor_ready: false, armor_status: 'Мантии при вас нет.',
        heart: { ready: true, can_call: true, status: 'Сердце при вас.', action_label: 'Спрятать сердце' },
      },
    });
    const armor = {
      ...data.knowledge[1], id: 'armor', name: 'Ритуал оружейника - броня', kind: 'side' as const,
      path: 'Side', cost: 1, starter_armor: true, reason: 'Сначала изучите ступень 2 своего пути.',
    };
    data.knowledge.push(armor);
    data.rituals.push({ id: armor.id, name: armor.name, desc: 'Создаёт мантию.', ingredients: [{ name: 'Готовый стол', amount: 1 }, { name: 'Противогаз', amount: 1 }], ascension: false });
    const { store, topic } = setupStore(data);
    const view = await renderBook();
    fireEvent.click(screen.getByRole('tab', { name: 'Охота' }));
    fireEvent.click(within(screen.getByRole('region', { name: 'Подготовка к охоте' })).getByRole('button', { name: 'Рецепт брони' }));
    expect(screen.getByRole('tabpanel', { name: 'Знания' })).toBeTruthy();
    expect(screen.getByRole('heading', { name: armor.name })).toBeTruthy();
    expect(screen.getByText(armor.reason)).toBeTruthy();
    expect(screen.getByRole('button', { name: 'Изучить за 1 очко' }).hasAttribute('disabled')).toBe(true);
    act(() => store.dispatch(backendUpdate({ data: { path_stage: 2, knowledge_state: { [armor.id]: { known: false, available: true, reason: '' } } } })));
    view.rerender(<ForbiddenLoreContent />);
    fireEvent.click(screen.getByRole('button', { name: 'Изучить за 1 очко' }));
    expect(readActions(topic)).toEqual([{ type: 'act/research', payload: { id: armor.id } }]);
    act(() => store.dispatch(backendUpdate({ data: { side_points: 1, knowledge_state: { [armor.id]: { known: true, available: false, reason: '' } } } })));
    view.rerender(<ForbiddenLoreContent />);
    expect(screen.getByText('Готовый стол')).toBeTruthy();
    expect(screen.getByText('Противогаз')).toBeTruthy();
    expect(screen.queryByRole('button', { name: 'Изучить за 1 очко' })).toBeNull();
    fireEvent.click(screen.getByRole('tab', { name: 'Охота' }));
    expect(screen.queryByRole('button', { name: 'Рецепт брони' })).toBeNull();
  });

  test('сохраняет автоматически открытую запись после изучения', async () => {
    const data = makeData({ selected_path: 'Ash', path_stage: 1 });
    data.knowledge[0].known = true;
    data.knowledge[1].available = true;
    const { store, topic } = setupStore(data);
    const view = await renderBook();
    fireEvent.click(screen.getByRole('tab', { name: 'Знания' }));
    expect(screen.getByRole('heading', { name: 'Искусство: Пепел' })).toBeTruthy();
    fireEvent.click(screen.getByRole('button', { name: 'Изучить за 2 очка' }));
    expect(readActions(topic)).toEqual([{ type: 'act/research', payload: { id: data.knowledge[1].id } }]);
    act(() => store.dispatch(backendUpdate({ data: {
      knowledge: data.knowledge.map((entry) => entry.id === data.knowledge[1].id ? { ...entry, known: true, available: false } : entry),
    } })));
    view.rerender(<ForbiddenLoreContent />);
    expect(screen.getByRole('heading', { name: 'Искусство: Пепел' })).toBeTruthy();
    expect(screen.getByRole('button', { name: /Искусство: Пепел, изучено/ }).getAttribute('aria-pressed')).toBe('true');
  });

  test('сохраняет открытый ритуал при добавлении записей и запоминает результат поиска', async () => {
    const data = makeData();
    const { store } = setupStore(data);
    const view = await renderBook();
    fireEvent.click(screen.getByRole('tab', { name: 'Ритуалы' }));
    const added = { ...data.rituals[0], id: 'new', name: 'Новый ритуал' };
    act(() => store.dispatch(backendUpdate({ data: { rituals: [added, ...data.rituals] } })));
    view.rerender(<ForbiddenLoreContent />);
    expect(screen.getByRole('heading', { name: 'Пепельный клинок' })).toBeTruthy();
    const search = screen.getByRole('textbox', { name: 'Поиск по названию, компоненту или итогу' });
    fireEvent.change(search, { target: { value: 'Человеческий труп' } });
    expect(screen.getByRole('heading', { name: 'Вознесение' })).toBeTruthy();
    fireEvent.change(search, { target: { value: '' } });
    expect(screen.getByRole('heading', { name: 'Вознесение' })).toBeTruthy();
  });

  test('находит рецепт по итогу обряда и показывает итог на карточке', async () => {
    const data = makeData();
    data.rituals[0].name = 'Карта без неба';
    setupStore(data);
    await renderBook();
    fireEvent.click(screen.getByRole('tab', { name: 'Ритуалы' }));
    fireEvent.change(screen.getByRole('textbox', { name: 'Поиск по названию, компоненту или итогу' }), { target: { value: 'клинок' } });
    const contents = within(screen.getByRole('navigation', { name: 'Ритуалы' }));
    expect(contents.getByText('Карта без неба')).toBeTruthy();
    expect(contents.queryByText('Вознесение')).toBeNull();
    expect(screen.getByRole('heading', { name: 'Карта без неба' })).toBeTruthy();
    expect(screen.getByText('Итог обряда:').textContent).toBe('Итог обряда: клинок');
  });

  test('раздел Начало даёт порядок первых шагов', async () => {
    setupStore(makeData());
    await renderBook();
    fireEvent.click(screen.getByRole('tab', { name: 'Помощь' }));
    const steps = within(screen.getByRole('list', { name: 'Первые пять минут' })).getAllByRole('listitem').map((item) => item.textContent);
    expect(steps).toHaveLength(5);
    expect(steps[0]).toContain('Призвать кодекс');
    expect(steps[0]).toContain('главе Путь');
    expect(steps[1]).toContain('руну');
    expect(steps[2]).toContain('→ клинок');
    expect(steps[3]).toContain('Ритуал оружейника');
    expect(steps[4]).toContain('сердце');
  });

  test('улучшает изученную пассивку за побочные очки и обновляет уровень без смены страницы', async () => {
    const data = makeData({ selected_path: 'Ash', path_stage: 2, points: 0, side_points: 1 });
    const knowledge = data.knowledge[1];
    knowledge.known = true;
    const passive = { level: 1, max_level: 3, cost: 1, available: true, reason: null, description: 'Поджог: 1 / 2 / 3.' };
    const { store, topic } = setupStore({ ...data, passive_upgrades: { [knowledge.id]: passive } });
    const view = await renderBook();
    fireEvent.click(screen.getByRole('tab', { name: 'Знания' }));
    fireEvent.click(screen.getByRole('button', { name: /Искусство: Пепел, изучено/ }));
    expect(screen.getByRole('heading', { name: 'Пассивка, уровень 1 из 3' })).toBeTruthy();
    const upgrade = screen.getByRole('button', { name: 'Усилить до II за 1 очко' });
    expect(upgrade.hasAttribute('disabled')).toBe(false);
    fireEvent.click(upgrade);
    expect(readActions(topic)).toEqual([{ type: 'act/upgrade_passive', payload: { id: knowledge.id, level: 1 } }]);
    store.dispatch(backendUpdate({ data: { side_points: 0, passive_upgrades: { [knowledge.id]: {
      ...passive, level: 2, cost: 2, available: false, reason: 'Не хватает знаний: нужно 2.',
    } } } }));
    view.rerender(<ForbiddenLoreContent />);
    expect(screen.getByRole('heading', { name: 'Пассивка, уровень 2 из 3' })).toBeTruthy();
    expect(screen.getByRole('button', { name: 'Усилить до III за 2 очка' }).hasAttribute('disabled')).toBe(true);
    expect(screen.getByText('Не хватает знаний: нужно 2.')).toBeTruthy();
    store.dispatch(backendUpdate({ data: { passive_upgrades: { [knowledge.id]: {
      ...passive, level: 3, cost: 0, available: false, reason: 'Достигнут максимальный уровень.',
    } } } }));
    view.rerender(<ForbiddenLoreContent />);
    expect(screen.getByText('Пассивка раскрыта полностью.')).toBeTruthy();
    expect(screen.queryByRole('button', { name: /Усилить до/ })).toBeNull();
  });

  test('показывает описание будущей пассивки без кнопки покупки до изучения', async () => {
    const data = makeData({ selected_path: 'Ash', path_stage: 1 });
    data.knowledge[1].passive_description = 'Поджог: 1 / 2 / 3.';
    setupStore(data);
    await renderBook();
    fireEvent.click(screen.getByRole('tab', { name: 'Знания' }));
    fireEvent.click(screen.getByRole('button', { name: /Искусство: Пепел, закрыто/ }));
    expect(screen.getByText('Поджог: 1 / 2 / 3.')).toBeTruthy();
    expect(screen.getByText('Усиливать её можно после изучения.')).toBeTruthy();
    expect(screen.queryByRole('button', { name: /Усилить до/ })).toBeNull();
  });

  test('облик физической книги приходит с сервера и обновляется без потери открытой главы', async () => {
    const data = makeData();
    const { store } = setupStore(data);
    const view = await renderBook();
    expect(screen.getByRole('heading', { name: 'Кодекс Рубцов' })).toBeTruthy();
    expect(screen.getByRole('article', { name: 'Левая страница' })).toBeTruthy();
    expect(screen.getByRole('article', { name: 'Правая страница' })).toBeTruthy();
    fireEvent.click(screen.getByRole('tab', { name: 'Помощь' }));
    store.dispatch(backendUpdate({ data: { ...data, book: {
      name: 'Speculum sine Facie', title: 'Серебряное завещание', subtitle: 'Не доверяй своему отражению.',
      path: 'Moon', cover_state: 'moon_open',
    } } }));
    view.rerender(<ForbiddenLoreContent />);
    expect(screen.getByRole('tabpanel', { name: 'Помощь' })).toBeTruthy();
    expect(view.container.querySelector('[data-book-path="Moon"]')).toBeTruthy();
    fireEvent.click(screen.getByRole('tab', { name: 'Путь' }));
    expect(screen.getByRole('heading', { name: 'Серебряное завещание' })).toBeTruthy();
    expect(screen.getByText('Не доверяй своему отражению.')).toBeTruthy();
    expect(screen.getByText('Speculum sine Facie')).toBeTruthy();
  });

  test('показывает неизученный рецепт и обновляет его доступность без потери выбора', async () => {
    const data = makeData({ selected_path: 'Ash', path_stage: 1 });
    const knowledgeState = Object.fromEntries(data.knowledge.map((entry) => [entry.id, {
      known: false, available: false, reason: 'Не хватает очков знаний.',
    }]));
    knowledgeState[data.knowledge[0].id] = { known: true, available: false, reason: '' };
    data.rituals[0].id = data.knowledge[0].id;
    data.rituals[1].id = data.knowledge[1].id;
    const { store } = setupStore({ ...data, knowledge_state: knowledgeState });
    const view = await renderBook();
    expect(screen.getByText('Не хватает очков знаний.')).toBeTruthy();
    store.dispatch(backendUpdate({ data: {
      knowledge_state: { ...knowledgeState, [data.knowledge[1].id]: { known: false, available: true, reason: '' } },
    } }));
    view.rerender(<ForbiddenLoreContent />);
    expect(screen.getByRole('button', { name: 'Изучить за 2 очка' }).hasAttribute('disabled')).toBe(false);
    fireEvent.click(screen.getByRole('tab', { name: 'Ритуалы' }));
    expect(screen.getByRole('heading', { name: 'Пепельный клинок' })).toBeTruthy();
    fireEvent.click(screen.getByRole('button', { name: /Вознесение/ }));
    expect(screen.getByRole('heading', { name: 'Вознесение' })).toBeTruthy();
    expect(screen.getByRole('button', { name: 'Изучить за 2 очка' }).hasAttribute('disabled')).toBe(false);
    store.dispatch(backendUpdate({ data: {
      knowledge_state: { ...knowledgeState, [data.knowledge[1].id]: { known: true, available: false, reason: '' } },
    } }));
    view.rerender(<ForbiddenLoreContent />);
    expect(screen.getByRole('heading', { name: 'Вознесение' })).toBeTruthy();
    expect(screen.getByText('Последний обряд · изучен')).toBeTruthy();
    expect(screen.queryByRole('button', { name: /Изучить за/ })).toBeNull();
  });

  test('находит броню до изучения и разрешает покупку только после открытия ступени', async () => {
    const data = makeData({ selected_path: 'Ash', path_stage: 1, points: 0, side_points: 1 });
    const armor = {
      ...data.knowledge[1], id: '/datum/eldritch_knowledge/armor', name: 'Ритуал оружейника — броня',
      desc: 'Создаёт мантию с капюшоном.', kind: 'side' as const, path: 'Side', cost: 1,
      reason: 'Сначала изучите ступень 2 своего пути.',
    };
    data.knowledge.push(armor);
    data.rituals.push({
      id: armor.id, name: armor.name, desc: armor.desc, ascension: false, duration: 5,
      hint: 'Готовый стол будет израсходован.',
      ingredients: [{ name: 'Стол', amount: 1 }, { name: 'Противогаз', amount: 1 }],
    });
    const { store, topic } = setupStore(data);
    const view = await renderBook();
    fireEvent.click(screen.getByRole('tab', { name: 'Ритуалы' }));
    fireEvent.change(screen.getByRole('textbox'), { target: { value: 'брон' } });
    expect(screen.getByRole('heading', { name: armor.name })).toBeTruthy();
    expect(screen.getByText('Готовый стол будет израсходован.')).toBeTruthy();
    expect(screen.getByText(/Обряд длится 5 сек/)).toBeTruthy();
    const research = screen.getByRole('button', { name: 'Изучить за 1 очко' });
    expect(research.hasAttribute('disabled')).toBe(true);
    expect(screen.getByText(armor.reason)).toBeTruthy();
    fireEvent.click(research);
    expect(readActions(topic)).toEqual([]);
    act(() => store.dispatch(backendUpdate({ data: {
      path_stage: 2,
      knowledge_state: { [armor.id]: { known: false, available: true, reason: '' } },
    } })));
    view.rerender(<ForbiddenLoreContent />);
    expect(research.hasAttribute('disabled')).toBe(false);
    fireEvent.click(research);
    expect(readActions(topic)).toEqual([{ type: 'act/research', payload: { id: armor.id } }]);
  });

  test('после выбора пути показывает его будущие рецепты и общие знания, скрывая чужие пути', async () => {
    const data = makeData({ selected_path: 'Ash', path_stage: 1 });
    data.rituals[0].id = data.knowledge[1].id;
    data.rituals[1].id = data.knowledge[3].id;
    setupStore(data);
    await renderBook();
    fireEvent.click(screen.getByRole('tab', { name: 'Ритуалы' }));
    expect(screen.getByRole('heading', { name: 'Пепельный клинок' })).toBeTruthy();
    expect(screen.queryByRole('button', { name: /Вознесение/ })).toBeNull();
    expect(screen.getByRole('button', { name: 'Изучить за 2 очка' }).hasAttribute('disabled')).toBe(true);
  });

  test('закладки перелистываются стрелками, Home и End с переносом клавиатурного фокуса', async () => {
    setupStore(makeData());
    await renderBook();
    const pathTab = screen.getByRole('tab', { name: 'Путь' });
    pathTab.focus();
    fireEvent.keyDown(pathTab, { key: 'ArrowRight' });
    const knowledgeTab = screen.getByRole('tab', { name: 'Знания' });
    expect(document.activeElement).toBe(knowledgeTab);
    expect(screen.getByRole('tabpanel', { name: 'Знания' })).toBeTruthy();
    fireEvent.keyDown(knowledgeTab, { key: 'End' });
    const helpTab = screen.getByRole('tab', { name: 'Помощь' });
    expect(document.activeElement).toBe(helpTab);
    expect(helpTab.getAttribute('tabindex')).toBe('0');
    fireEvent.keyDown(helpTab, { key: 'Home' });
    expect(document.activeElement).toBe(pathTab);
    expect(screen.getAllByRole('tab').filter((tab) => tab.getAttribute('tabindex') === '0')).toHaveLength(1);
  });

  test('звук страницы вызывается только при настоящем перелистывании', async () => {
    // Отдельное окно не должно наследовать 50-мс защиту sendAct от предыдущего теста.
    let now = Date.now() + 1000;
    const clock = jest.spyOn(Date, 'now').mockImplementation(() => ++now);
    const { topic } = setupStore(makeData());
    await renderBook();
    expect(topic).not.toHaveBeenCalled();
    fireEvent.click(screen.getByRole('tab', { name: 'Путь' }));
    fireEvent.click(screen.getByRole('button', { name: 'Пепел' }));
    expect(topic).not.toHaveBeenCalled();
    fireEvent.click(screen.getByRole('button', { name: 'Луна' }));
    fireEvent.click(screen.getByRole('button', { name: 'Луна' }));
    fireEvent.click(screen.getByRole('tab', { name: 'Ритуалы' }));
    expect(topic.mock.calls.map(([message]) => ({ type: message.type, payload: JSON.parse(message.payload) }))).toEqual([
      { type: 'act/turn_page', payload: { chapter: 'Путь' } },
      { type: 'act/turn_page', payload: { chapter: 'Ритуалы' } },
    ]);
    clock.mockRestore();
  });

  test.each([
    ['Cosmic', 'Космос'], ['Glass', 'Стекло'], ['Blood', 'Кровь'],
    ['Echo', 'Эхо'], ['Sand', 'Песок'], ['Wax', 'Воск'], ['Spirit', 'Дух'],
    ['Dance', 'Пляска'],
  ])('%s: показывает все пути, подтверждает обет и отправляет только идентификатор знания', async (path, name) => {
    const data = makeData();
    const { topic } = setupStore(data);
    await renderBook();
    const index = screen.getByRole('navigation', { name: 'Пути Мансуса' });
    expect(within(index).getAllByRole('button')).toHaveLength(16);
    expect(within(index).getByText('XVI')).toBeTruthy();
    fireEvent.click(within(index).getByRole('button', { name }));
    expect(screen.getByRole('heading', { name })).toBeTruthy();
    fireEvent.click(screen.getByText('Все ступени пути'));
    expect(within(screen.getByText('Все ступени пути').closest('details')!).getByText(`Искусство: ${name}`)).toBeTruthy();
    fireEvent.click(screen.getByRole('button', { name: 'Принять этот путь' }));
    expect(readActions(topic)).toHaveLength(0);
    const confirm = screen.getByRole('button', { name: 'Ещё раз, и пути назад не будет' });
    expect(confirm.classList.contains('HereticBook__seal--armed')).toBe(true);
    fireEvent.click(confirm);
    expect(readActions(topic)).toEqual([{
      type: 'act/research', payload: { id: `/datum/eldritch_knowledge/${path.toLowerCase()}/base` },
    }]);
  });

  test('клик мимо снимает взведённый выбор пути без отправки', async () => {
    const { topic } = setupStore(makeData());
    await renderBook();
    fireEvent.click(screen.getByRole('button', { name: 'Принять этот путь' }));
    expect(screen.getByRole('button', { name: 'Ещё раз, и пути назад не будет' })).toBeTruthy();
    act(() => { fireEvent.click(document.body); });
    const idle = screen.getByRole('button', { name: 'Принять этот путь' });
    expect(idle.classList.contains('HereticBook__seal--armed')).toBe(false);
    expect(readActions(topic)).toHaveLength(0);
  });

  test('после принятия обета другой путь остаётся доступным только для чтения', async () => {
    const data = makeData({ selected_path: 'Ash', path_stage: 1 });
    setupStore(data);
    await renderBook();
    fireEvent.click(screen.getByRole('tab', { name: 'Путь' }));
    fireEvent.click(screen.getByRole('button', { name: 'Луна' }));
    expect(screen.getByRole('heading', { name: 'Луна' })).toBeTruthy();
    expect(screen.queryByRole('button', { name: 'Принять этот путь' })).toBeNull();
    expect(screen.getByText('Ваш путь уже выбран. Остальные можно только читать.')).toBeTruthy();
  });

  test('дерево сохраняет закрытые ступени и объясняет причину блокировки', async () => {
    const data = makeData({ selected_path: 'Ash', path_stage: 1 });
    data.knowledge[0].known = true;
    const { topic } = setupStore(data);
    await renderBook();
    expect(screen.getByText('Сначала примите обет.')).toBeTruthy();
    fireEvent.click(screen.getByRole('button', { name: 'Изучить за 2 очка' }));
    expect(readActions(topic)).toHaveLength(0);
    const tree = screen.getByRole('navigation', { name: 'Дерево знаний' });
    expect(within(tree).getByText('Обет: Пепел')).toBeTruthy();
    expect(within(tree).getByText('Искусство: Пепел')).toBeTruthy();
  });

  test('новая запись и глава открываются с начала страницы', async () => {
    setupStore(makeData({ selected_path: 'Ash', path_stage: 1 }));
    const view = await renderBook();
    const page = screen.getByRole('article', { name: 'Правая страница' });
    const text = screen.getByLabelText('Текст правой страницы');
    page.scrollTop = 180;
    text.scrollTop = 240;
    fireEvent.click(screen.getByRole('button', { name: /Искусство: Пепел/ }));
    expect(page.scrollTop).toBe(0);
    expect(text.scrollTop).toBe(0);
    view.container.querySelector('.HereticBook__spread')!.scrollTop = 300;
    fireEvent.click(screen.getByRole('tab', { name: 'Помощь' }));
    expect(screen.getByRole('tabpanel', { name: 'Помощь' }).scrollTop).toBe(0);
  });

  test('доступное общее знание покупается независимо от закрытой следующей ступени', async () => {
    const data = makeData({ selected_path: 'Ash', path_stage: 1 });
    data.knowledge[0].known = true;
    data.knowledge.push({
      ...data.knowledge[1], id: '/datum/eldritch_knowledge/medallion',
      name: 'Глаз Мансуса', kind: 'side', path: 'Side', stage: 1, available: true, reason: '',
    });
    const { topic } = setupStore(data);
    await renderBook();
    fireEvent.click(screen.getByRole('button', { name: /Глаз Мансуса/ }));
    fireEvent.click(screen.getByRole('button', { name: 'Изучить за 2 очка' }));
    expect(readActions(topic)).toEqual([{
      type: 'act/research', payload: { id: '/datum/eldritch_knowledge/medallion' },
    }]);
  });

  test('при обновлении баланса недоступное исследование не отправляет действие', async () => {
    const data = makeData({ selected_path: 'Ash', path_stage: 1 });
    data.knowledge[0].known = true;
    data.knowledge[1].available = true;
    data.knowledge[1].reason = '';
    const { topic, store } = setupStore(data);
    const view = await renderBook();
    store.dispatch(backendUpdate({ data: { ...data, points: 0 } }));
    view.rerender(<ForbiddenLoreContent />);
    expect(screen.getByText('Не хватает знаний: нужно 2 очка.')).toBeTruthy();
    fireEvent.click(screen.getByRole('button', { name: 'Изучить за 2 очка' }));
    expect(readActions(topic)).toHaveLength(0);
  });

  test('побочный баланс оплачивает общее знание, но не ступень пути', async () => {
    const data = makeData({ selected_path: 'Ash', path_stage: 1, points: 0, side_points: 2 });
    data.knowledge[0].known = true;
    data.knowledge[1].available = true;
    data.knowledge[1].reason = '';
    data.knowledge.push({
      ...data.knowledge[1], id: '/datum/eldritch_knowledge/medallion',
      name: 'Глаз Мансуса', kind: 'side', path: 'Side', stage: 1,
    });
    const { topic } = setupStore(data);
    await renderBook();
    fireEvent.click(screen.getByRole('button', { name: 'Изучить за 2 очка' }));
    expect(readActions(topic)).toHaveLength(0);
    fireEvent.click(screen.getByRole('button', { name: /Глаз Мансуса/ }));
    fireEvent.click(screen.getByRole('button', { name: 'Изучить за 2 очка' }));
    expect(readActions(topic)).toEqual([{
      type: 'act/research', payload: { id: '/datum/eldritch_knowledge/medallion' },
    }]);
  });

  test('рецепты ищутся по ингредиентам и не запускаются из книги', async () => {
    const { topic } = setupStore(makeData());
    await renderBook();
    fireEvent.click(screen.getByRole('tab', { name: 'Ритуалы' }));
    fireEvent.input(screen.getByRole('textbox'), { target: { value: 'спичка' } });
    expect(screen.getByRole('heading', { name: 'Пепельный клинок' })).toBeTruthy();
    expect(screen.queryByRole('heading', { name: 'Вознесение' })).toBeNull();
    expect(screen.queryByRole('button', { name: /Провести|Создать/ })).toBeNull();
    expect(readActions(topic)).toHaveLength(0);
  });

  test('охота соблюдает задержку смены цели и открывает серверный выбор после неё', async () => {
    const data = makeData();
    data.hunt = { ...data.hunt, target_name: 'Алексей Зимин', target_role: 'Врач', can_retarget: false, retarget_seconds: 31.4 };
    const { topic, store } = setupStore(data);
    const view = await renderBook();
    fireEvent.click(screen.getByRole('tab', { name: 'Охота' }));
    expect(screen.getByText('Сменить цель можно через 32 сек.')).toBeTruthy();
    fireEvent.click(screen.getByRole('button', { name: 'Сменить цель' }));
    expect(readActions(topic)).toHaveLength(0);
    store.dispatch(backendUpdate({ data: { ...data, hunt: { ...data.hunt, can_retarget: true, retarget_seconds: 0 } } }));
    view.rerender(<ForbiddenLoreContent />);
    fireEvent.click(screen.getByRole('button', { name: 'Сменить цель' }));
    expect(readActions(topic)).toEqual([{ type: 'act/retarget', payload: {} }]);
  });

  test('шкала силы читает описание пути с сервера, а помощь использует актуальные пределы', async () => {
    const data = makeData({
      combat_resource: { name: 'Созвездия', value: 2, max: 4, description: 'Замкните звёздную ловушку.' },
    });
    data.hunt.influence_limit = 8;
    data.hunt.influence_initial_count = 2;
    data.hunt.influence_interval_minutes = 5;
    data.hunt.sacrifices_required = 6;
    setupStore(data);
    await renderBook();
    const toggle = screen.getByRole('button', { name: /^Созвездия/ });
    expect(within(toggle).getByLabelText('Созвездия: 2 из 4').querySelectorAll('.HereticBook__mark--on')).toHaveLength(2);
    fireEvent.click(toggle);
    expect(screen.getByText('Замкните звёздную ловушку.')).toBeTruthy();
    fireEvent.click(screen.getByRole('tab', { name: 'Помощь' }));
    expect(screen.getByText(/изучить 8 разломов/)).toBeTruthy();
    expect(screen.getByText(/В начале раунда открыто 2 разлома, потом каждые 5 мин/)).toBeTruthy();
    expect(screen.getByText(/Совершите 6 жертвоприношений/)).toBeTruthy();
  });

  test('дело пути показывается под разворотом, в охоте и помощи, а без пути остаётся подсказка', async () => {
    const data = makeData({ selected_path: 'Ash', path_stage: 1, deed: {
      name: 'Сожжённые письма', desc: 'Сжигайте бумаги станции.', hint: 'Пепел остаётся на полу.',
      tier: 1, max_tier: 3, progress: 2, goal: 5, counted: 7,
    } });
    data.hunt.deed_tiers = 3;
    const { store } = setupStore(data);
    const view = await renderBook();
    const line = screen.getByRole('button', { name: /^Сожжённые письма/ });
    expect(line.textContent).toBe('Сожжённые письма II · 2/5');
    expect(line.getAttribute('title')).toBe('Сжигайте бумаги станции.');
    fireEvent.click(screen.getByRole('tab', { name: 'Охота' }));
    const deed = screen.getByRole('region', { name: 'Дело пути' });
    expect(within(deed).getByText('Сжигайте бумаги станции.')).toBeTruthy();
    expect(within(deed).getByText('Пепел остаётся на полу.')).toBeTruthy();
    expect(within(deed).getByText('Ступень 2 из 3 · 2 из 5')).toBeTruthy();
    expect(within(deed).getByLabelText('Ступеней дела: 1 из 3').querySelectorAll('.HereticBook__mark--on')).toHaveLength(1);
    fireEvent.click(screen.getByRole('tab', { name: 'Помощь' }));
    expect(screen.getByText(/Дело состоит из 3 ступеней/)).toBeTruthy();
    act(() => store.dispatch(backendUpdate({ data: { deed: { ...data.deed, tier: 3, progress: 0, goal: 5 } } })));
    view.rerender(<ForbiddenLoreContent />);
    expect(line.textContent).toBe('Сожжённые письма завершено');
    act(() => store.dispatch(backendUpdate({ data: { deed: null } })));
    view.rerender(<ForbiddenLoreContent />);
    expect(screen.queryByRole('button', { name: /^Сожжённые письма/ })).toBeNull();
    fireEvent.click(screen.getByRole('tab', { name: 'Охота' }));
    expect(screen.getByText('Дело появится после выбора пути.')).toBeTruthy();
    expect(screen.queryByText(/завершено/)).toBeNull();
  });

  test('боевой шаг виден в охоте, обновляет доступность и скрывается после завершения дела', async () => {
    const deed = {
      name: 'Оболы на глазах', desc: 'Кладите оболы на глаза.', hint: '',
      tier: 0, max_tier: 3, progress: 0, goal: 2, counted: 0,
      combat_hint: 'Сместите душу назначенной цели и заставьте связь истощить её.',
      combat_available: true,
    };
    const { store } = setupStore(makeData({ selected_path: 'Spirit', path_stage: 2, deed }));
    const view = await renderBook();
    fireEvent.click(screen.getByRole('tab', { name: 'Охота' }));
    const step = () => screen.queryByLabelText('Боевой шаг дела');
    expect(step()?.textContent).toContain(deed.combat_hint);
    expect(step()?.textContent).toContain('Это заменяет один шаг ступени');
    act(() => store.dispatch(backendUpdate({ data: { deed: { ...deed, progress: 1, combat_available: false } } })));
    view.rerender(<ForbiddenLoreContent />);
    expect(step()?.textContent).toContain('Боевой шаг этой ступени уже засчитан');
    expect(step()?.textContent).not.toContain('Это заменяет один шаг ступени');
    act(() => store.dispatch(backendUpdate({ data: { deed: { ...deed, tier: 3, goal: 0, combat_available: false } } })));
    view.rerender(<ForbiddenLoreContent />);
    expect(screen.queryByText(new RegExp(deed.combat_hint))).toBeNull();
    expect(step()).toBeNull();
  });

  test.each([[1, 'разлом'], [2, 'разлома'], [5, 'разломов'], [11, 'разломов'], [14, 'разломов'], [21, 'разлом'], [22, 'разлома'], [25, 'разломов']])('пределы разломов согласованы с числом %s', async (count, noun) => {
    const data = makeData();
    data.hunt.influence_initial_count = Number(count);
    data.hunt.influence_limit = Number(count);
    setupStore(data);
    await renderBook();
    fireEvent.click(screen.getByRole('tab', { name: 'Помощь' }));
    expect(screen.getByText(new RegExp(`изучить ${count} ${noun}\\.`))).toBeTruthy();
    expect(screen.getByText(new RegExp(`В начале раунда открыто ${count} ${noun},`))).toBeTruthy();
  });

  test('помощь объясняет изнанку числами сервера, а тема охоты ведёт к ней', async () => {
    const data = makeData();
    data.hunt.pocket = { duration: 35, warning: 7, pull: 2, tear: 12, cooldown: 90, hold: 4, grip: 5, shake: 6 };
    setupStore(data);
    await renderBook();
    fireEvent.click(screen.getByRole('tab', { name: 'Помощь' }));
    const topic = () => screen.getByText('Изнанка', { selector: 'summary' }).closest('details')!;
    expect(topic().getAttribute('data-topic')).toBe('pocket');
    expect(topic().open).toBe(false);
    expect(within(topic()).getByText(/«Увести за руну», увод займёт 2 сек\./)).toBeTruthy();
    expect(within(topic()).getByText(/держится 35 сек\., за 7 до конца/)).toBeTruthy();
    expect(within(topic()).getByText(/цель 4 сек\. не может двинуться/)).toBeTruthy();
    expect(within(topic()).getByText(/прижимает её к полу до 5 сек\.: .* растолкать можно за 6 сек\./)).toBeTruthy();
    expect(within(topic()).getByText(/руками его можно разорвать за 12 сек\. Снова открыть изнанку можно через 90 сек\./)).toBeTruthy();
    fireEvent.click(screen.getByRole('button', { name: 'изнанке', hidden: true }));
    expect(topic().open).toBe(true);
  });

  test('отсчёт смены цели идёт без пакетов сервера и сохраняется между главами', async () => {
    const data = makeData();
    data.hunt = { ...data.hunt, target_name: 'Алексей Зимин', can_retarget: false, retarget_seconds: 3 };
    const { topic } = setupStore(data);
    jest.useFakeTimers();
    try {
      await renderBook();
      fireEvent.click(screen.getByRole('tab', { name: 'Охота' }));
      expect(screen.getByText('Сменить цель можно через 3 сек.')).toBeTruthy();
      act(() => jest.advanceTimersByTime(1000));
      expect(screen.getByText('Сменить цель можно через 2 сек.')).toBeTruthy();
      fireEvent.click(screen.getByRole('tab', { name: 'Помощь' }));
      act(() => jest.advanceTimersByTime(2000));
      fireEvent.click(screen.getByRole('tab', { name: 'Охота' }));
      expect(screen.queryByText(/Сменить цель можно через/)).toBeNull();
      fireEvent.click(screen.getByRole('button', { name: 'Сменить цель' }));
      expect(readActions(topic)).toEqual([{ type: 'act/retarget', payload: {} }]);
    } finally {
      jest.useRealTimers();
    }
  });
});

const structuredGlass = (overrides: Partial<ForbiddenLoreData> = {}) => {
  const data = makeData({ selected_path: 'Glass', path_stage: 1, ...overrides });
  const casket = data.knowledge.find((entry) => entry.id === '/datum/eldritch_knowledge/glass/second')!;
  Object.assign(casket, {
    name: 'Витраж', available: true, reason: '', role: 'capture', flavour: 'Свет лёг цветными плитками.',
    summary: 'Запирает поверженную цель в саркофаг на 10 секунд.',
    details: ['Цель в 3 клетках.', 'Стекло нарастает секунду.', 'Прочность 90.', 'После выхода минута защиты.', 'Нулевой жезл рассеивает.', 'Перезарядка 45 секунд.'],
    desc: 'Запирает поверженную цель в саркофаг на 10 секунд. Цель в 3 клетках. Стекло нарастает секунду.',
  });
  data.rituals.push({
    id: casket.id, name: casket.name, desc: casket.summary!, ascension: false, duration: 5,
    hints: ['Сердце кладут рядом.', 'Цель держат неподвижно.'],
    ingredients: [{ name: 'Лист стекла', amount: 2 }],
  });
  return { data, casket };
};

describe('Структурированный кодекс', () => {
  test('знание показывает рубрику, пометки на полях, эпиграф под заголовком, лид и кнопку над фактами', async () => {
    const { data, casket } = structuredGlass();
    const { topic } = setupStore(data);
    await renderBook();
    fireEvent.click(screen.getByRole('button', { name: /Витраж, доступно/ }));
    const right = within(screen.getByRole('article', { name: 'Правая страница' }));
    expect(right.getByText('Ступень II').className).toBe('HereticBook__kicker');
    expect(right.getByLabelText('Пометки на полях').textContent).toBe('IIзахват2 очкадоступно');
    const lead = right.getByText(casket.summary!);
    expect(lead.className).toContain('HereticBook__lead');
    const research = right.getByRole('button', { name: 'Изучить за 2 очка' });
    const firstDetail = right.getByText('Цель в 3 клетках.');
    expect(lead.compareDocumentPosition(research) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
    expect(research.compareDocumentPosition(firstDetail) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
    expect(right.getByText('Перезарядка 45 секунд.')).toBeTruthy();
    expect(right.queryByRole('button', { name: /Ещё/ })).toBeNull();
    expect(right.queryByText(casket.desc)).toBeNull();
    const flavour = right.getByText(casket.flavour);
    expect(flavour.closest('blockquote')?.className).toBe('HereticBook__epigraph');
    expect(flavour.compareDocumentPosition(lead) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
    fireEvent.click(research);
    expect(readActions(topic)).toEqual([{ type: 'act/research', payload: { id: casket.id } }]);
  });

  test('рецепт знания не повторяет лид и общие правила руны, а подсказки идут списком', async () => {
    const { data, casket } = structuredGlass();
    setupStore(data);
    await renderBook();
    fireEvent.click(screen.getByRole('button', { name: /Витраж, доступно/ }));
    const right = within(screen.getByRole('article', { name: 'Правая страница' }));
    expect(right.getAllByText(casket.summary!)).toHaveLength(1);
    const recipe = within(right.getByRole('region', { name: 'Компоненты обряда' }));
    expect(recipe.getByText('Лист стекла')).toBeTruthy();
    expect(recipe.getByText('Сердце кладут рядом.').tagName).toBe('LI');
    expect(recipe.getByText('Обряд длится 5 сек.')).toBeTruthy();
    expect(screen.queryByText(/Вещи в руках/)).toBeNull();
    fireEvent.click(screen.getByRole('tab', { name: 'Ритуалы' }));
    fireEvent.click(screen.getByRole('button', { name: /Витраж/ }));
    expect(screen.getAllByText(casket.summary!)).toHaveLength(1);
    expect(screen.queryByText('Цель в 3 клетках.')).toBeNull();
    expect(screen.getAllByText(/Вещи в руках, на теле и в сумках не в счёт/)).toHaveLength(1);
  });

  test('знание без лида показывает прежнее описание, но кнопка изучения стоит над ним', async () => {
    const data = makeData({ selected_path: 'Ash', path_stage: 1 });
    data.knowledge[1].available = true;
    data.knowledge[1].reason = '';
    setupStore(data);
    await renderBook();
    fireEvent.click(screen.getByRole('button', { name: /Искусство: Пепел/ }));
    const right = within(screen.getByRole('article', { name: 'Правая страница' }));
    expect(right.getByText('За завесой.').closest('blockquote')?.className).toBe('HereticBook__epigraph');
    const research = right.getByRole('button', { name: 'Изучить за 2 очка' });
    const desc = right.getByText('Продолжение пути.');
    expect(research.compareDocumentPosition(desc) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
    expect(right.queryByRole('button', { name: /Ещё/ })).toBeNull();
    expect(right.queryByText(/Ремесло|Захват/)).toBeNull();
  });

  test('содержание называет роль только словами, без значков', async () => {
    const { data } = structuredGlass();
    setupStore(data);
    const view = await renderBook();
    const tree = screen.getByRole('navigation', { name: 'Дерево знаний' });
    const line = within(tree).getByRole('button', { name: 'Витраж, доступно, 2 очка, захват' });
    expect(line.textContent).toBe('IIВитраж2');
    expect(within(tree).getByRole('button', { name: 'Обет: Стекло, доступно, 0 очков' })).toBeTruthy();
    expect(view.container.querySelectorAll('[class*="HereticBook__role"]')).toHaveLength(0);
  });

  test('путь показывает лид, ремесло, захват и уход абзацами, стороны списками и совет, а старый путь - прежние тексты', async () => {
    const data = makeData();
    const glass = data.paths.find((path) => path.id === 'Glass')!;
    Object.assign(glass, {
      tagline: 'Смотрит через окна и запирает жертву в витраж.',
      craft: 'Хваткой настройте окно.', capture: 'Витраж на 10 секунд.', escape: 'Шаг сквозь своё окно.',
      strength_points: ['Глаза по всей станции.', 'Луч без подготовки.', 'Саркофаг для обряда.'],
      weakness_points: ['Нулевой жезл снимает настройку.', 'Витраж видно заранее.', 'Удары бьют сильнее.'],
      practice: 'Настройте окно и шагните сквозь него.',
    });
    setupStore(data);
    await renderBook();
    fireEvent.click(screen.getByRole('button', { name: 'Стекло' }));
    expect(screen.getByText(glass.tagline!).className).toContain('HereticBook__lead');
    expect(screen.queryByText(glass.desc)).toBeNull();
    const model = screen.getByLabelText('Ремесло, захват и уход');
    expect(Array.from(model.querySelectorAll('p')).map((row) => row.textContent)).toEqual([
      `Ремесло. ${glass.craft}`, `Захват. ${glass.capture}`, `Уход. ${glass.escape}`,
    ]);
    const strong = within(screen.getByRole('region', { name: 'Сильные стороны' }));
    expect(strong.getAllByRole('listitem').map((item) => item.textContent)).toEqual(glass.strength_points);
    const weak = within(screen.getByRole('region', { name: 'Слабые стороны' }));
    expect(weak.getAllByRole('listitem').map((item) => item.textContent)).toEqual(glass.weakness_points);
    expect(screen.getByText('Совет.').parentElement?.textContent).toBe(`Совет. ${glass.practice}`);
    expect(screen.getByRole('heading', { name: 'Врождённая черта: Черта: Стекло' })).toBeTruthy();
    fireEvent.click(screen.getByRole('button', { name: 'Пепел' }));
    expect(screen.getByText('Учение: Пепел.')).toBeTruthy();
    expect(screen.queryByLabelText('Ремесло, захват и уход')).toBeNull();
    expect(within(screen.getByRole('region', { name: 'Сильные стороны' })).getByText('Своя тактика.').tagName).toBe('LI');
    expect(screen.queryByText(/^Совет/)).toBeNull();
  });

  test('строка под разворотом показывает запас и состояние сразу, правила - во всплывающем листе', async () => {
    setupStore(makeData({
      selected_path: 'Glass', path_stage: 1,
      combat_resource: {
        name: 'Грани', value: 2, max: 4, description: 'Старое описание. Призм: 1 из 3.',
        rules: ['Грань возвращается каждые 4 секунды.', 'Витраж стоит 2 грани.'], state: 'Призм: 1 из 3.',
      },
    }));
    await renderBook();
    const ledger = within(screen.getByRole('group', { name: 'Знания и сила' }));
    const toggle = ledger.getByRole('button', { name: /^Грани/ });
    expect(within(toggle).getByText('Призм: 1 из 3.')).toBeTruthy();
    expect(toggle.getAttribute('aria-expanded')).toBe('false');
    expect(screen.queryByRole('region', { name: 'Правила запаса' })).toBeNull();
    fireEvent.click(toggle);
    expect(toggle.getAttribute('aria-expanded')).toBe('true');
    const rules = screen.getByRole('region', { name: 'Правила запаса' });
    expect(rules.closest('.HereticBook__pageScroll')).toBeNull();
    expect(within(rules).getAllByRole('listitem').map((item) => item.textContent)).toEqual(['Грань возвращается каждые 4 секунды.', 'Витраж стоит 2 грани.']);
    expect(screen.queryByText(/Старое описание/)).toBeNull();
    act(() => { fireEvent.click(document.body); });
    expect(screen.queryByRole('region', { name: 'Правила запаса' })).toBeNull();
    expect(toggle.getAttribute('aria-expanded')).toBe('false');
  });

  test('способности стоят группой в содержании, без клавиши строка остаётся без пустой метки', async () => {
    const ability = { id: 'casket', name: 'Витраж', summary: 'Саркофаг на 10 секунд.', desc: 'Полное описание Витража.', usage: 'Укажите цель.', hotkey: 'Alt+4' };
    const unbound = { id: 'grasp', name: 'Хватка Мансуса', desc: 'Хватка.', usage: 'Коснитесь цели.' };
    setupStore(makeData({ selected_path: 'Glass', path_stage: 1, combat_abilities: [ability, unbound] }));
    await renderBook();
    const group = screen.getByRole('region', { name: 'Способности' });
    expect(Array.from(group.querySelectorAll('kbd')).map((key) => key.textContent)).toEqual(['Alt+4']);
    const groups = Array.from(screen.getByRole('navigation', { name: 'Дерево знаний' }).querySelectorAll('section')).map((section) => section.getAttribute('aria-label'));
    expect(groups).toEqual(['Ступени пути', 'Способности']);
    fireEvent.click(within(group).getByRole('button', { name: 'Хватка Мансуса' }));
    const right = within(screen.getByRole('article', { name: 'Правая страница' }));
    expect(right.getByText('Хватка.')).toBeTruthy();
    expect(right.getByText('Способность').tagName).toBe('P');
  });

  test('над содержанием нет сворачиваемых подсказок, оно начинается сразу с групп', async () => {
    setupStore(makeData({
      selected_path: 'Glass', path_stage: 1,
      combat_abilities: [{ id: 'casket', name: 'Витраж', summary: 'Саркофаг на 10 секунд.', desc: 'Витраж.', usage: 'Укажите цель.' }],
      preparation: {
        blade_ready: false, blade_status: 'Клинка при вас нет.',
        armor_ready: false, armor_status: 'Поднимите капюшон.',
        heart: { ready: false, can_call: true, status: 'Сердце за завесой.', action_label: 'Призвать своё сердце' },
      },
      deed: { name: 'Настроенные стёкла', desc: 'Настройте стёкла.', hint: '', next_step: 'Коснитесь окна.', tier: 0, max_tier: 3, progress: 1, goal: 3, counted: 1 },
    }));
    await renderBook();
    const left = screen.getByRole('article', { name: 'Левая страница' });
    expect(left.querySelectorAll('details')).toHaveLength(0);
    expect(within(left).queryByText('Клинка при вас нет.')).toBeNull();
    expect(within(left).queryByText('Коснитесь окна.')).toBeNull();
    expect(within(left).getByRole('heading', { name: 'Содержание' })).toBeTruthy();
  });

  test('страницы не держат сводку: очки и жертвы стоят одной строкой под разворотом', async () => {
    setupStore(makeData({ selected_path: 'Glass', path_stage: 1, points: 3, side_points: 1, total_sacrifices: 2 }));
    await renderBook();
    for (const page of screen.getAllByRole('article')) {
      expect(within(page).queryByText(/побочн/)).toBeNull();
    }
    const ledger = screen.getByRole('group', { name: 'Знания и сила' });
    expect(ledger.closest('.HereticBook__toolbar')).toBeTruthy();
    expect(within(ledger).getByTitle('Очки знаний').textContent).toBe('3 знания');
    expect(within(ledger).getByTitle('Побочные очки').textContent).toBe('1 побочн.');
    expect(within(ledger).getByTitle('Жертвоприношения').textContent).toBe('жертвы 2/5');
  });

  test('помощь разбита на темы, охота ведёт в тему правил жертвы', async () => {
    const data = makeData();
    data.hunt.sacrifices_required = 3;
    setupStore(data);
    await renderBook();
    fireEvent.click(screen.getByRole('tab', { name: 'Помощь' }));
    const topics = Array.from(document.querySelectorAll('details.HereticBook__topic')) as HTMLDetailsElement[];
    expect(topics.map((topic) => topic.querySelector('summary')?.textContent)).toEqual([
      'Начало', 'Путь и знания', 'Разломы', 'Охота и жертва', 'Изнанка', 'Мансус', 'Удержание СБ', 'Вознесение', 'Дело пути', 'Горячие клавиши',
    ]);
    expect(topics.filter((topic) => topic.open).map((topic) => topic.dataset.topic)).toEqual(['start']);
    for (const topic of topics) {
      const points = topic.querySelectorAll('li').length + topic.querySelectorAll('.HereticBook__topicBody > p').length;
      expect(points).toBeGreaterThanOrEqual(2);
      expect(points).toBeLessThanOrEqual(5);
    }
    expect(screen.getByText(/Совершите 3 жертвоприношения и изучите/)).toBeTruthy();
    fireEvent.click(screen.getByRole('tab', { name: 'Охота' }));
    expect(screen.queryByText(/Одна душа - один раз/)).toBeNull();
    fireEvent.click(screen.getByRole('button', { name: 'Все правила жертвы' }));
    expect(screen.getByRole('tabpanel', { name: 'Помощь' })).toBeTruthy();
    const opened = (Array.from(document.querySelectorAll('details.HereticBook__topic')) as HTMLDetailsElement[]).filter((topic) => topic.open);
    expect(opened.map((topic) => topic.dataset.topic)).toEqual(['hunt']);
    expect(within(opened[0]).getByText(/Одна душа - один раз/)).toBeTruthy();
    expect(within(opened[0]).getByText(/Перенос жертвы или прерывание срывают обряд/)).toBeTruthy();
    const ascension = document.querySelector('details[data-topic="ascension"]')!;
    expect(within(ascension as HTMLElement).getByText(/между попытками не меньше 3 минут/)).toBeTruthy();
    expect(within(ascension as HTMLElement).getByText(/подсвечиваются зелёным/)).toBeTruthy();
    const hotkeys = document.querySelector('details[data-topic="hotkeys"]')!;
    expect(hotkeys.textContent).not.toMatch(/по умолчанию Q|видны в главе Знания/);
  });
});

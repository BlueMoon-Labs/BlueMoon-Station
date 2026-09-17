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
        id: 'blade', name: 'Пепельный клинок', desc: 'Создаёт клинок.',
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
        armor_ready: false, armor_status: 'Поднимите капюшон.',
        heart: { ready: false, can_call: true, status: 'Сердце за завесой.', action_label: 'Призвать своё сердце' },
      },
    }));
    await renderBook();
    fireEvent.click(screen.getByText('Подготовка к охоте · 0/3'));
    const preparation = screen.getByRole('region', { name: 'Подготовка к охоте' });
    expect(within(preparation).getByText('Клинка при вас нет.')).toBeTruthy();
    expect(within(preparation).getByText('Поднимите капюшон.')).toBeTruthy();
    fireEvent.click(within(preparation).getByRole('button', { name: 'Проверить подготовку' }));
    fireEvent.click(screen.getByRole('tab', { name: 'Охота' }));
    fireEvent.click(await screen.findByRole('button', { name: 'Призвать своё сердце' }));
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
    fireEvent.click(screen.getByText('Подготовка к охоте · 2/3'));
    expect(screen.getByRole('button', { name: 'Вернуть своё сердце' }).hasAttribute('disabled')).toBe(true);
    expect(screen.queryByText('Зажгите звезду.')).toBeNull();
    fireEvent.click(screen.getByRole('button', { name: 'Вернуть своё сердце' }));
    expect(readActions(topic)).toEqual([]);
  });

  test.each(makeData().paths)('$name: врождённая черта видна до выбора пути', async (path) => {
    setupStore(makeData());
    await renderBook();
    fireEvent.click(screen.getByRole('button', { name: path.name }));
    expect(await screen.findByText(`Врождённая черта — ${path.innate_name}`)).toBeTruthy();
    expect(screen.getByText(path.innate_desc!)).toBeTruthy();
    expect(screen.getByText('Действует с выбора пути, без затрат знаний.')).toBeTruthy();
  });

  test.each(makeData().paths)('$name: дело и прогресс видны рядом со знаниями', async (path) => {
    const deed = { name: `Дело: ${path.name}`, desc: `Действие пути ${path.name}.`, hint: '', tier: 0, max_tier: 3, progress: 1, goal: 2, counted: 1 };
    const { store } = setupStore(makeData({ selected_path: path.id, path_stage: 1, deed }));
    const view = await renderBook();
    const guide = within(screen.getByRole('complementary', { name: 'Подсказки по развитию' }));
    expect(guide.getByText(deed.desc)).toBeTruthy();
    expect(guide.getByText(/Ступень/).textContent).toBe('Ступень 1 из 3 · 1 из 2');
    act(() => store.dispatch(backendUpdate({ data: { deed: { ...deed, tier: 1, progress: 0, goal: 3 } } })));
    view.rerender(<ForbiddenLoreContent />);
    expect(guide.getByText(/Ступень/).textContent).toBe('Ступень 2 из 3 · 0 из 3');
    act(() => store.dispatch(backendUpdate({ data: { deed: { ...deed, tier: 3, progress: 0, goal: 0 } } })));
    view.rerender(<ForbiddenLoreContent />);
    expect(guide.getByText('Завершено.')).toBeTruthy();
    expect(guide.queryByText('Завершите ступень, чтобы получить очко знаний.')).toBeNull();
  });

  test.each(makeData().paths)('$name: клавиши видны рядом со способностями без открытия записи', async (path) => {
    const ability = { id: 'grasp', name: 'Хватка Мансуса', desc: 'Хватка.', usage: 'Коснитесь цели.', hotkey: 'Alt+1' };
    const help = 'Отмена подготовки: Alt+Q или Q. Переназначение — в настройках клавиш.';
    setupStore(makeData({ selected_path: path.id, path_stage: 1, combat_abilities: [ability], ability_hotkey_help: help }));
    await renderBook();
    const guide = within(screen.getByRole('region', { name: 'Доступные боевые способности' }));
    expect(guide.getByText(help)).toBeTruthy();
    expect(within(guide.getByRole('button', { name: ability.name })).getByText('Alt+1')).toBeTruthy();
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
    const ability = { id: 'sever', name: 'Разлучение', desc: 'Отделяет душу врага.', usage: 'Нажмите кнопку, затем укажите цель.' };
    const { store, topic } = setupStore(makeData({ selected_path: 'Spirit', path_stage: 1, combat_abilities: [ability] }));
    const view = await renderBook();
    fireEvent.click(screen.getByRole('button', { name: 'Разлучение' }));
    const right = within(screen.getByRole('article', { name: 'Правая страница' }));
    expect(right.getByRole('heading', { name: 'Разлучение' })).toBeTruthy();
    expect(right.getByText(ability.usage)).toBeTruthy();
    expect(right.queryByRole('button', { name: /Изучить/ })).toBeNull();
    expect(readActions(topic)).toEqual([]);
    act(() => store.dispatch(backendUpdate({ data: { combat_abilities: [] } })));
    view.rerender(<ForbiddenLoreContent />);
    expect(screen.queryByRole('button', { name: 'Разлучение' })).toBeNull();
    expect(right.queryByRole('heading', { name: 'Разлучение' })).toBeNull();
    expect(right.getByRole('heading', { name: 'Обет: Дух' })).toBeTruthy();
  });

  test('подсказка брони ведёт от открытия ступени к покупке за побочные очки и изготовлению', async () => {
    const data = makeData({ selected_path: 'Spirit', path_stage: 1, points: 0, side_points: 2 });
    const armor = {
      ...data.knowledge[1], id: 'armor', name: 'Ритуал оружейника — броня', kind: 'side' as const,
      path: 'Side', cost: 1, starter_armor: true, reason: 'Сначала изучите ступень 2 своего пути.',
    };
    data.knowledge.push(armor);
    data.rituals.push({ id: armor.id, name: armor.name, desc: 'Создаёт мантию.', ingredients: [{ name: 'Готовый стол', amount: 1 }, { name: 'Противогаз', amount: 1 }], ascension: false });
    const { store, topic } = setupStore(data);
    const view = await renderBook();
    const armorGuide = within(screen.getByRole('region', { name: 'Стартовая броня' }));
    expect(armorGuide.getByText(armor.reason)).toBeTruthy();
    fireEvent.click(armorGuide.getByRole('button', { name: 'Открыть рецепт брони' }));
    expect(screen.getByRole('heading', { name: armor.name })).toBeTruthy();
    expect(screen.getByRole('button', { name: 'Изучить · 1 очк. знаний' }).hasAttribute('disabled')).toBe(true);
    act(() => store.dispatch(backendUpdate({ data: { path_stage: 2, knowledge_state: { [armor.id]: { known: false, available: true, reason: '' } } } })));
    view.rerender(<ForbiddenLoreContent />);
    expect(armorGuide.getByText(/Рецепт доступен за 1/)).toBeTruthy();
    fireEvent.click(screen.getByRole('button', { name: 'Изучить · 1 очк. знаний' }));
    expect(readActions(topic)).toEqual([{ type: 'act/research', payload: { id: armor.id } }]);
    act(() => store.dispatch(backendUpdate({ data: { side_points: 1, knowledge_state: { [armor.id]: { known: true, available: false, reason: '' } } } })));
    view.rerender(<ForbiddenLoreContent />);
    expect(armorGuide.getByText(/Рецепт изучен. Проведите обряд/)).toBeTruthy();
    expect(screen.getByText('Готовый стол')).toBeTruthy();
    expect(screen.getByText('Противогаз')).toBeTruthy();
    expect(screen.queryByRole('button', { name: 'Изучить · 1 очк. знаний' })).toBeNull();
  });

  test('сохраняет автоматически открытую запись после изучения', async () => {
    const data = makeData({ selected_path: 'Ash', path_stage: 1 });
    data.knowledge[0].known = true;
    data.knowledge[1].available = true;
    const { store, topic } = setupStore(data);
    const view = await renderBook();
    fireEvent.click(screen.getByRole('tab', { name: 'Знания' }));
    expect(screen.getByRole('heading', { name: 'Искусство: Пепел' })).toBeTruthy();
    fireEvent.click(screen.getByRole('button', { name: 'Изучить · 2 очк. знаний' }));
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
    const search = screen.getByRole('textbox', { name: 'Найти запись или ингредиент' });
    fireEvent.change(search, { target: { value: 'Человеческий труп' } });
    expect(screen.getByRole('heading', { name: 'Вознесение' })).toBeTruthy();
    fireEvent.change(search, { target: { value: '' } });
    expect(screen.getByRole('heading', { name: 'Вознесение' })).toBeTruthy();
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
    expect(screen.getByRole('heading', { name: 'Пассивка · 1 / 3' })).toBeTruthy();
    const upgrade = screen.getByRole('button', { name: 'Улучшить до 2 · 1 очк. знаний' });
    expect(upgrade.hasAttribute('disabled')).toBe(false);
    fireEvent.click(upgrade);
    expect(readActions(topic)).toEqual([{ type: 'act/upgrade_passive', payload: { id: knowledge.id, level: 1 } }]);
    store.dispatch(backendUpdate({ data: { side_points: 0, passive_upgrades: { [knowledge.id]: {
      ...passive, level: 2, cost: 2, available: false, reason: 'Не хватает знаний: нужно 2.',
    } } } }));
    view.rerender(<ForbiddenLoreContent />);
    expect(screen.getByRole('heading', { name: 'Пассивка · 2 / 3' })).toBeTruthy();
    expect(screen.getByRole('button', { name: 'Улучшить до 3 · 2 очк. знаний' }).hasAttribute('disabled')).toBe(true);
    expect(screen.getByText('Не хватает знаний: нужно 2.')).toBeTruthy();
    store.dispatch(backendUpdate({ data: { passive_upgrades: { [knowledge.id]: {
      ...passive, level: 3, cost: 0, available: false, reason: 'Достигнут максимальный уровень.',
    } } } }));
    view.rerender(<ForbiddenLoreContent />);
    expect(screen.getByText('Максимальный уровень пассивки')).toBeTruthy();
    expect(screen.queryByRole('button', { name: /Улучшить до/ })).toBeNull();
  });

  test('показывает описание будущей пассивки без кнопки покупки до изучения', async () => {
    const data = makeData({ selected_path: 'Ash', path_stage: 1 });
    data.knowledge[1].passive_description = 'Поджог: 1 / 2 / 3.';
    setupStore(data);
    await renderBook();
    fireEvent.click(screen.getByRole('tab', { name: 'Знания' }));
    fireEvent.click(screen.getByRole('button', { name: /Искусство: Пепел, закрыто/ }));
    expect(screen.getByText('Поджог: 1 / 2 / 3.')).toBeTruthy();
    expect(screen.getByText('Сначала изучите знание, чтобы открыть улучшения.')).toBeTruthy();
    expect(screen.queryByRole('button', { name: /Улучшить до/ })).toBeNull();
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
      name: 'Серебряное завещание', title: 'Серебряное завещание', subtitle: 'Не доверяй своему отражению.',
      path: 'Moon', cover_state: 'moon_open',
    } } }));
    view.rerender(<ForbiddenLoreContent />);
    expect(screen.getByRole('tabpanel', { name: 'Помощь' })).toBeTruthy();
    expect(view.container.querySelector('[data-book-path="Moon"]')).toBeTruthy();
    fireEvent.click(screen.getByRole('tab', { name: 'Путь' }));
    expect(screen.getByRole('heading', { name: 'Серебряное завещание' })).toBeTruthy();
    expect(screen.getByText('Не доверяй своему отражению.')).toBeTruthy();
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
    expect(screen.getByRole('button', { name: 'Изучить · 2 очк. знаний' }).hasAttribute('disabled')).toBe(false);
    fireEvent.click(screen.getByRole('tab', { name: 'Ритуалы' }));
    expect(screen.getByRole('heading', { name: 'Пепельный клинок' })).toBeTruthy();
    fireEvent.click(screen.getByRole('button', { name: /Вознесение/ }));
    expect(screen.getByRole('heading', { name: 'Вознесение' })).toBeTruthy();
    expect(screen.getByRole('button', { name: 'Изучить · 2 очк. знаний' }).hasAttribute('disabled')).toBe(false);
    store.dispatch(backendUpdate({ data: {
      knowledge_state: { ...knowledgeState, [data.knowledge[1].id]: { known: true, available: false, reason: '' } },
    } }));
    view.rerender(<ForbiddenLoreContent />);
    expect(screen.getByRole('heading', { name: 'Вознесение' })).toBeTruthy();
    expect(screen.getByText('Изучено · обряд доступен на руне')).toBeTruthy();
    expect(screen.queryByRole('button', { name: /Изучить ·/ })).toBeNull();
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
    expect(screen.getByText(/Время проведения: 5 сек/)).toBeTruthy();
    const research = screen.getByRole('button', { name: 'Изучить · 1 очк. знаний' });
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
    expect(screen.getByRole('button', { name: 'Изучить · 2 очк. знаний' }).hasAttribute('disabled')).toBe(true);
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
  ])('%s: показывает все пути, подтверждает обет и отправляет только идентификатор знания', async (path, name) => {
    const data = makeData();
    const { topic } = setupStore(data);
    await renderBook();
    const index = screen.getByRole('navigation', { name: 'Пути Мансуса' });
    expect(within(index).getAllByRole('button')).toHaveLength(15);
    expect(within(index).getByText('XV')).toBeTruthy();
    fireEvent.click(within(index).getByRole('button', { name }));
    expect(screen.getByRole('heading', { name })).toBeTruthy();
    fireEvent.click(screen.getByText('Знания пути'));
    expect(screen.getByText(`II. Искусство: ${name}`)).toBeTruthy();
    fireEvent.click(screen.getByRole('button', { name: 'Выбрать этот путь' }));
    expect(readActions(topic)).toHaveLength(0);
    fireEvent.click(screen.getByRole('button', { name: 'Подтвердить выбор пути' }));
    expect(readActions(topic)).toEqual([{
      type: 'act/research', payload: { id: `/datum/eldritch_knowledge/${path.toLowerCase()}/base` },
    }]);
  });

  test('после принятия обета другой путь остаётся доступным только для чтения', async () => {
    const data = makeData({ selected_path: 'Ash', path_stage: 1 });
    setupStore(data);
    await renderBook();
    fireEvent.click(screen.getByRole('tab', { name: 'Путь' }));
    fireEvent.click(screen.getByRole('button', { name: 'Луна' }));
    expect(screen.getByRole('heading', { name: 'Луна' })).toBeTruthy();
    expect(screen.queryByRole('button', { name: 'Выбрать этот путь' })).toBeNull();
    expect(screen.getByText('Ваш путь выбран. Остальные доступны для просмотра.')).toBeTruthy();
  });

  test('дерево сохраняет закрытые ступени и объясняет причину блокировки', async () => {
    const data = makeData({ selected_path: 'Ash', path_stage: 1 });
    data.knowledge[0].known = true;
    const { topic } = setupStore(data);
    await renderBook();
    expect(screen.getByText('Сначала примите обет.')).toBeTruthy();
    fireEvent.click(screen.getByRole('button', { name: 'Изучить · 2 очк. знаний' }));
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
    fireEvent.click(screen.getByRole('button', { name: 'Изучить · 2 очк. знаний' }));
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
    expect(screen.getByText('Не хватает очков знаний: нужно 2.')).toBeTruthy();
    fireEvent.click(screen.getByRole('button', { name: 'Изучить · 2 очк. знаний' }));
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
    fireEvent.click(screen.getByRole('button', { name: 'Изучить · 2 очк. знаний' }));
    expect(readActions(topic)).toHaveLength(0);
    fireEvent.click(screen.getByRole('button', { name: /Глаз Мансуса/ }));
    fireEvent.click(screen.getByRole('button', { name: 'Изучить · 2 очк. знаний' }));
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
    expect(screen.getByText('Смена цели через 32 сек.')).toBeTruthy();
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
    expect(screen.getByText('Созвездия')).toBeTruthy();
    expect(screen.getByText('Замкните звёздную ловушку.')).toBeTruthy();
    fireEvent.click(screen.getByRole('tab', { name: 'Помощь' }));
    expect(screen.getByText(/изучить 8 разломов/)).toBeTruthy();
    expect(screen.getByText(/В начале раунда — 2 разлома. Затем каждые 5 мин/)).toBeTruthy();
    expect(screen.getByText(/Совершите 6 жертвоприношений/)).toBeTruthy();
  });

  test('дело пути показывается в ведомости, охоте и помощи, а без пути остаётся подсказка', async () => {
    const data = makeData({ selected_path: 'Ash', path_stage: 1, deed: {
      name: 'Сожжённые письма', desc: 'Сжигайте бумаги станции.', hint: 'Пепел остаётся на полу.',
      tier: 1, max_tier: 3, progress: 2, goal: 5, counted: 7,
    } });
    data.hunt.deed_tiers = 3;
    const { store } = setupStore(data);
    const view = await renderBook();
    expect(screen.getByRole('heading', { name: 'Дело пути · Сожжённые письма' })).toBeTruthy();
    expect(within(screen.getByRole('region', { name: 'Дело пути' })).getByText(/Ступень/).textContent).toBe('Ступень 2 из 3 · 2 из 5');
    fireEvent.click(screen.getByRole('tab', { name: 'Охота' }));
    expect(screen.getByText('II / III · 2 / 5')).toBeTruthy();
    const deed = screen.getByRole('region', { name: 'Дело пути' });
    expect(within(deed).getByText('Сжигайте бумаги станции.')).toBeTruthy();
    expect(within(deed).getByText('Пепел остаётся на полу.')).toBeTruthy();
    expect(within(deed).getByText((_, element) => element?.tagName === 'P' && element.textContent === 'Ступень 2 из 3 · 2 из 5')).toBeTruthy();
    expect(within(deed).getByLabelText('Ступеней дела: 1 из 3').querySelectorAll('.HereticBook__soulMarks--filled')).toHaveLength(1);
    fireEvent.click(screen.getByRole('tab', { name: 'Помощь' }));
    expect(screen.getByText(/Дело состоит из 3 ступеней/)).toBeTruthy();
    store.dispatch(backendUpdate({ data: { deed: { ...data.deed, tier: 3, progress: 0, goal: 5 } } }));
    view.rerender(<ForbiddenLoreContent />);
    expect(screen.getByText('III / III · Завершено')).toBeTruthy();
    store.dispatch(backendUpdate({ data: { deed: null } }));
    view.rerender(<ForbiddenLoreContent />);
    fireEvent.click(screen.getByRole('tab', { name: 'Охота' }));
    expect(screen.getByText('Дело появится после выбора пути.')).toBeTruthy();
    expect(screen.queryByText(/Завершено/)).toBeNull();
  });

  test('боевой шаг виден в ведомости и охоте, обновляет доступность и скрывается после завершения дела', async () => {
    const deed = {
      name: 'Места последнего сна', desc: 'Расстилайте постели.', hint: '',
      tier: 0, max_tier: 3, progress: 0, goal: 2, counted: 0,
      combat_hint: 'Сместите душу назначенной цели и заставьте связь истощить её.',
      combat_available: true,
    };
    const { store } = setupStore(makeData({ selected_path: 'Spirit', path_stage: 2, deed }));
    const view = await renderBook();
    expect(screen.getByText(deed.combat_hint)).toBeTruthy();
    expect(screen.getByText(/Заменяет один шаг этой ступени/)).toBeTruthy();
    fireEvent.click(screen.getByRole('tab', { name: 'Охота' }));
    expect(screen.getByText(deed.combat_hint)).toBeTruthy();
    act(() => store.dispatch(backendUpdate({ data: { deed: { ...deed, progress: 1, combat_available: false } } })));
    view.rerender(<ForbiddenLoreContent />);
    expect(screen.getByText(/Боевой шаг этой ступени уже засчитан/)).toBeTruthy();
    expect(screen.queryByText(/Заменяет один шаг этой ступени/)).toBeNull();
    act(() => store.dispatch(backendUpdate({ data: { deed: { ...deed, tier: 3, goal: 0, combat_available: false } } })));
    view.rerender(<ForbiddenLoreContent />);
    expect(screen.queryByText(deed.combat_hint)).toBeNull();
    expect(screen.queryByLabelText('Боевой шаг дела')).toBeNull();
  });

  test.each([[1, 'разлом'], [2, 'разлома'], [5, 'разломов'], [11, 'разломов'], [14, 'разломов'], [21, 'разлом'], [22, 'разлома'], [25, 'разломов']])('пределы разломов согласованы с числом %s', async (count, noun) => {
    const data = makeData();
    data.hunt.influence_initial_count = Number(count);
    data.hunt.influence_limit = Number(count);
    setupStore(data);
    await renderBook();
    fireEvent.click(screen.getByRole('tab', { name: 'Помощь' }));
    expect(screen.getByText(new RegExp(`изучить ${count} ${noun}\\.`))).toBeTruthy();
    expect(screen.getByText(new RegExp(`В начале раунда — ${count} ${noun}\\.`))).toBeTruthy();
  });

  test('отсчёт смены цели идёт без пакетов сервера и сохраняется между главами', async () => {
    const data = makeData();
    data.hunt = { ...data.hunt, target_name: 'Алексей Зимин', can_retarget: false, retarget_seconds: 3 };
    const { topic } = setupStore(data);
    jest.useFakeTimers();
    try {
      await renderBook();
      fireEvent.click(screen.getByRole('tab', { name: 'Охота' }));
      expect(screen.getByText('Смена цели через 3 сек.')).toBeTruthy();
      act(() => jest.advanceTimersByTime(1000));
      expect(screen.getByText('Смена цели через 2 сек.')).toBeTruthy();
      fireEvent.click(screen.getByRole('tab', { name: 'Помощь' }));
      act(() => jest.advanceTimersByTime(2000));
      fireEvent.click(screen.getByRole('tab', { name: 'Охота' }));
      expect(screen.queryByText(/Смена цели через/)).toBeNull();
      fireEvent.click(screen.getByRole('button', { name: 'Сменить цель' }));
      expect(readActions(topic)).toEqual([{ type: 'act/retarget', payload: {} }]);
    } finally {
      jest.useRealTimers();
    }
  });
});

import { act, fireEvent, render, screen, waitFor, within } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { ForbiddenLoreContent, ForbiddenLoreData } from './ForbiddenLore';

const makeData = (overrides: Partial<ForbiddenLoreData> = {}): ForbiddenLoreData => {
  const paths = [
    ['Ash', 'Пепел'], ['Rust', 'Ржавчина'], ['Flesh', 'Плоть'], ['Void', 'Пустота'],
    ['Blade', 'Клинок'], ['Moon', 'Луна'], ['Cosmic', 'Космос'],
    ['Lock', 'Замок'], ['Tide', 'Пучина'], ['Glass', 'Стекло'], ['Blood', 'Кровь'],
    ['Echo', 'Эхо'],
  ].map(([id, name]) => ({
    id, name, desc: `Учение: ${name}.`, strengths: ['Своя тактика.'], weaknesses: ['Своя уязвимость.'],
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

  test('статический каталог сохраняется при обновлении доступности и открывает только изученные рецепты', async () => {
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
    expect(screen.queryByText('Вознесение')).toBeNull();
    store.dispatch(backendUpdate({ data: {
      knowledge_state: { ...knowledgeState, [data.knowledge[1].id]: { known: true, available: false, reason: '' } },
    } }));
    view.rerender(<ForbiddenLoreContent />);
    expect(screen.getByText('Вознесение')).toBeTruthy();
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
    ['Echo', 'Эхо'],
  ])('%s: показывает все пути, подтверждает обет и отправляет только идентификатор знания', async (path, name) => {
    const data = makeData();
    const { topic } = setupStore(data);
    await renderBook();
    const index = screen.getByRole('navigation', { name: 'Пути Мансуса' });
    expect(within(index).getAllByRole('button')).toHaveLength(12);
    expect(within(index).getByText('XI')).toBeTruthy();
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

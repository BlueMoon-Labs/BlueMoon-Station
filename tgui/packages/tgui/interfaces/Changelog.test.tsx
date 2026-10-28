import { act as reactAct, fireEvent, render, waitFor } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { Changelog, resetChangelogCache } from './Changelog';

const october = `2026-10-01:
  DuLL-FoX:
  - pr: 4100
    rscadd: Добавлен путь Пляски
  - bugfix: Исправлено удержание жертв
    pr: 4100
2026-10-15:
  Pingvas:
  - pr: 4201
    tweak: Ёлка стала зеленее
  - imageadd: Новые спрайты
    pr: 4202
  Безымянный автор:
  - tweak: Запись без PR
`;

const september = `2026-09-20:
  Ghost:
  - balance: Сентябрьский баланс
`;

let now = Date.now();

const setup = (data: Record<string, unknown>, files: Record<string, string[]>) => {
  jest.spyOn(Date, 'now').mockImplementation(() => (now += 100));
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, winget: () => Promise.resolve(null), topic };
  const fetchMock = jest.fn((url: string) => {
    const queue = files[url] || [];
    const text = queue.length > 1 ? queue.shift() : queue[0];
    return Promise.resolve({ text: () => Promise.resolve(text ?? 'Cannot find ' + url) });
  });
  (global as any).fetch = fetchMock;
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'Changelog' }, data }));
  return { ...render(<Changelog />), topic, fetchMock };
};

const monthCalls = (topic: jest.Mock) =>
  topic.mock.calls.filter(([message]) => message.type === 'act/get_month').map(([message]) => JSON.parse(message.payload));

beforeEach(() => {
  resetChangelogCache();
  jest.useRealTimers();
});

test('открывается на свежем месяце: просит ассет, показывает дни свежими первыми', async () => {
  const ui = setup({ dates: ['2026-10', '2026-09'], last_seen: '' }, { '2026-10.yml': [october] });
  expect(monthCalls(ui.topic)).toEqual([{ date: '2026-10' }]);
  await ui.findByText('Ёлка стала зеленее');
  const text = ui.container.textContent || '';
  expect(text.indexOf('15 октября 2026')).toBeLessThan(text.indexOf('1 октября 2026'));
  expect(ui.getAllByText('Октябрь 2026').length).toBeGreaterThan(0);
  expect(ui.queryByText(/Новое: /)).toBeNull();
  expect(ui.container.querySelector('.Changelog__day--new')).toBeNull();
});

test('пока ассет не дошёл, окно повторяет запрос, а не падает', async () => {
  const ui = setup({ dates: ['2026-10'], last_seen: '' }, { '2026-10.yml': ['Cannot find 2026-10.yml', october] });
  await ui.findByText('Добавлен путь Пляски');
  expect(ui.fetchMock).toHaveBeenCalledTimes(2);
});

test('если ассет так и не пришёл - ошибка и «Повторить» запрашивает месяц снова', async () => {
  jest.useFakeTimers();
  const ui = setup({ dates: ['2026-10'], last_seen: '' }, {});
  for (let i = 0; i < 10; i++) {
    await reactAct(async () => {
      jest.runOnlyPendingTimers();
    });
  }
  expect(ui.getByText('Не удалось загрузить месяц.')).toBeTruthy();
  expect(ui.fetchMock).toHaveBeenCalledTimes(6);
  fireEvent.click(ui.getByText('Повторить'));
  expect(monthCalls(ui.topic)).toEqual([{ date: '2026-10' }, { date: '2026-10' }]);
});

test('записи свежее прошлого просмотра помечены, «Новое» оставляет только их', async () => {
  const ui = setup({ dates: ['2026-10'], last_seen: '2026-10-07' }, { '2026-10.yml': [october] });
  await ui.findByText('Ёлка стала зеленее');
  expect(ui.container.querySelectorAll('.Changelog__day--new').length).toBe(1);
  fireEvent.click(ui.getByText('Новое: 3'));
  expect(ui.queryByText('Добавлен путь Пляски')).toBeNull();
  expect(ui.getByText('Новые спрайты')).toBeTruthy();
});

test('чип категории фильтрует, «Все» сбрасывает, поиск сужает', async () => {
  const ui = setup({ dates: ['2026-10'], last_seen: '' }, { '2026-10.yml': [october] });
  await ui.findByText('Ёлка стала зеленее');
  expect(ui.getByText('Все 5')).toBeTruthy();
  fireEvent.click(ui.getByText('Исправления 1'));
  expect(ui.queryByText('Ёлка стала зеленее')).toBeNull();
  expect(ui.getByText('Исправлено удержание жертв')).toBeTruthy();
  fireEvent.click(ui.getByText('Все 5'));
  expect(ui.getByText('Ёлка стала зеленее')).toBeTruthy();

  const input = ui.container.querySelector('.Input__input') as HTMLInputElement;
  fireEvent.input(input, { target: { value: 'елка' } });
  expect(ui.queryByText('Добавлен путь Пляски')).toBeNull();
  expect(ui.getByText('Все 1')).toBeTruthy();
  fireEvent.input(input, { target: { value: 'ничего такого' } });
  fireEvent.click(ui.getByText('Сбросить фильтры'));
  expect(ui.getByText('Добавлен путь Пляски')).toBeTruthy();
});

test('стрелка и боковая колонка переключают месяц, «О проекте» открывает благодарности', async () => {
  const ui = setup(
    { dates: ['2026-10', '2026-09'], last_seen: '' },
    { '2026-10.yml': [october], '2026-09.yml': [september] },
  );
  await ui.findByText('Ёлка стала зеленее');
  expect(ui.queryByText('Архив')).toBeNull();
  fireEvent.click(ui.container.querySelector('.fa-chevron-right')!.closest('.Button')!);
  await ui.findByText('Сентябрьский баланс');
  expect(monthCalls(ui.topic)).toEqual([{ date: '2026-10' }, { date: '2026-09' }]);

  fireEvent.click(ui.container.querySelector('.fa-folder-tree')!.closest('.Button')!);
  expect(ui.getByText('Архив')).toBeTruthy();
  fireEvent.click(ui.getByText('Октябрь'));
  await ui.findByText('Ёлка стала зеленее');
  expect(monthCalls(ui.topic)).toHaveLength(2);

  fireEvent.click(ui.container.querySelector('.fa-circle-info')!.closest('.Button')!);
  expect(ui.getByText('GoonStation 13 Development Team')).toBeTruthy();
  fireEvent.click(ui.getByText('К изменениям'));
  await waitFor(() => expect(ui.getByText('Ёлка стала зеленее')).toBeTruthy());
});

test('месяц после отметки помечен точкой ещё до загрузки, свёрнутый архив тоже', async () => {
  const ui = setup(
    { dates: ['2026-12', '2026-11', '2026-10'], last_seen: '2026-10-15' },
    { '2026-12.yml': ['2026-12-02:\n  A:\n  - rscadd: Декабрьская запись\n'] },
  );
  await ui.findByText('Декабрьская запись');
  const archiveButton = ui.container.querySelector('.fa-folder-tree')!.closest('.Button')!;
  expect(archiveButton.querySelector('.Changelog__dot')).toBeTruthy();
  fireEvent.click(archiveButton);
  const marked = Array.from(ui.container.querySelectorAll('.Changelog__archive .Changelog__dot')).map(
    (dot) => dot.closest('.Button')?.textContent,
  );
  expect(marked).toEqual(['Декабрь', 'Ноябрь']);
});

test('переход на старый месяц не помечает его новым записями прошлого месяца', async () => {
  const ui = setup(
    { dates: ['2026-10', '2026-09'], last_seen: '2026-10-07' },
    { '2026-10.yml': [october], '2026-09.yml': [september] },
  );
  await ui.findByText('Ёлка стала зеленее');
  fireEvent.click(ui.container.querySelector('.fa-folder-tree')!.closest('.Button')!);
  fireEvent.click(ui.getByText('Сентябрь'));
  await ui.findByText('Сентябрьский баланс');
  const marked = Array.from(ui.container.querySelectorAll('.Changelog__archive .Changelog__dot')).map(
    (dot) => dot.closest('.Button')?.textContent,
  );
  expect(marked).toEqual(['Октябрь']);
});

test('у автора аватарка и ссылка на PR; несколько PR за день - ссылка у каждой группы', async () => {
  const ui = setup({ dates: ['2026-10'], last_seen: '' }, { '2026-10.yml': [october] });
  await ui.findByText('Ёлка стала зеленее');
  const links = Array.from(ui.container.querySelectorAll('.Changelog__pr')).map((link) => [
    link.textContent,
    link.getAttribute('href'),
  ]);
  expect(links).toEqual([
    ['#4201', 'https://github.com/BlueMoon-Labs/BlueMoon-Station/pull/4201'],
    ['#4202', 'https://github.com/BlueMoon-Labs/BlueMoon-Station/pull/4202'],
    ['#4100', 'https://github.com/BlueMoon-Labs/BlueMoon-Station/pull/4100'],
  ]);
  const avatars = Array.from(ui.container.querySelectorAll('img.Changelog__avatar')).map((img) =>
    img.getAttribute('src'),
  );
  expect(avatars).toEqual(['https://github.com/Pingvas.png?size=48', 'https://github.com/DuLL-FoX.png?size=48']);
  expect(ui.container.querySelectorAll('.Changelog__avatar--none').length).toBe(1);

  expect(ui.getByText('Pingvas').tagName).not.toBe('A');
  fireEvent.load(ui.container.querySelector('img[src^="https://github.com/Pingvas"]')!);
  expect(ui.getByText('Pingvas').getAttribute('href')).toBe('https://github.com/Pingvas');
  fireEvent.error(ui.container.querySelector('img[src^="https://github.com/DuLL-FoX"]')!);
  expect(ui.container.querySelectorAll('.Changelog__avatar--none').length).toBe(2);
  expect(ui.getByText('DuLL-FoX').tagName).not.toBe('A');
});

test('поиск по #номеру оставляет записи одного PR', async () => {
  const ui = setup({ dates: ['2026-10'], last_seen: '' }, { '2026-10.yml': [october] });
  await ui.findByText('Ёлка стала зеленее');
  fireEvent.input(ui.container.querySelector('.Input__input')!, { target: { value: '#4100' } });
  expect(ui.getByText('Добавлен путь Пляски')).toBeTruthy();
  expect(ui.getByText('Исправлено удержание жертв')).toBeTruthy();
  expect(ui.queryByText('Ёлка стала зеленее')).toBeNull();
});

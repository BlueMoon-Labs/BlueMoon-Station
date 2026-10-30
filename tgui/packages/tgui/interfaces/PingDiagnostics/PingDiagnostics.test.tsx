import { fireEvent, render, screen } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../../backend';
import { debugReducer } from '../../debug';
import { PingDiagnostics } from '.';
import { PingDiagnosticsData, VERDICTS } from './model';

const base: PingDiagnosticsData = {
  staff: 0,
  tab: 'self',
  hint_enabled: 1,
  server_rtt_median: 60,
  server_base_median: 40,
  target: 'tester',
  self: 1,
  verdicts: ['ok'],
  stats: { samples: 120, rtt_now: 45, rtt_median: 44, rtt_min: 40, rtt_p95: 60, base: 40, stall_mean: 1, shared_mean: 1, personal_mean: 2, personal_median: 2, spikes_per_min: 0, freezes: 0, loop_lag: 4, fps: 60 },
  percentile: 40,
  graph: [{ t: -10, rtt: 44, stall: 0, shared: 0, spike: 0 }],
  byond: '516.1688',
};

const topic = jest.fn();

const mount = (overrides: Partial<PingDiagnosticsData> = {}) => {
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'PingDiagnostics' }, data: { ...base, ...overrides } }));
  return render(<PingDiagnostics />);
};

describe('PingDiagnostics', () => {
  it('всё хорошо - без советов', () => {
    mount();
    expect(screen.getByText(VERDICTS.ok.title)).toBeTruthy();
    expect(screen.queryByText('Что можно сделать')).toBeNull();
  });

  it('сервер - "это не у вас", без советов игроку', () => {
    mount({ verdicts: ['server'], stats: { ...base.stats, stall_mean: 90, extra_mean: 95 } });
    expect(screen.getByText(VERDICTS.server.title)).toBeTruthy();
    expect(screen.queryByText('Что можно сделать')).toBeNull();
  });

  it('ритм - советы и почему', () => {
    mount({ verdicts: ['periodic', 'loss'], stats: { ...base.stats, period: 600, spikes_per_min: 1, loss_per_min: 1 } });
    expect(screen.getByText('Что можно сделать')).toBeTruthy();
    expect(screen.getByText(VERDICTS.periodic.advice[0])).toBeTruthy();
    expect(screen.getByText(VERDICTS.loss.advice[0])).toBeTruthy();
  });

  it('скрытое окно игры - прочерк', () => {
    mount({ stats: { ...base.stats, loop_lag: null, fps: null, hidden: 1 } });
    expect(screen.getByText('Окно игры:').closest('tr')?.textContent).toBe('Окно игры:-');
    expect(screen.queryByText(/к\/с/)).toBeNull();
  });

  it('вкладка сервера видна только админу и показывает таблицу', () => {
    mount();
    expect(screen.queryByText('Сервер')).toBeNull();
    mount({
      staff: 1,
      tab: 'server',
      clients: [{ ckey: 'slowpoke', base: 180, rtt_median: 200, rtt_p95: 400, personal_median: 30, spikes_per_min: 1, freezes: 0, ours_fraction: 0.1, verdict: 'far' }],
      events: [{ time: '12:00:00', type: 'host_network', clients: 40, fraction: 0.9, extra_ms: 150, stall_ms: 0, source: '' }],
      round: { ours_fraction: 0.2, verdicts: { ok: 10 }, events: { host_network: 1 } },
    });
    expect(screen.getByText('slowpoke')).toBeTruthy();
    expect(screen.getByText('12:00:00')).toBeTruthy();
    fireEvent.click(screen.getByText('slowpoke'));
    const inspect = topic.mock.calls.find(([message]) => message.type === 'act/inspect');
    expect(JSON.parse(inspect?.[0].payload ?? '{}')).toEqual({ ckey: 'slowpoke' });
  });

  it('главный вердикт сервер - подвисание не вешается на игрока', () => {
    mount({ verdicts: ['server', 'freeze', 'jitter'], stats: { ...base.stats, freezes: 2 } });
    expect(screen.queryByText(VERDICTS.freeze.advice[0])).toBeNull();
    expect(screen.queryByText(VERDICTS.freeze.title)).toBeNull();
    expect(screen.getByText(VERDICTS.jitter.advice[0])).toBeTruthy();
    expect(screen.getByText('Ещё с вашей стороны')).toBeTruthy();
    expect(screen.queryByText('Что можно сделать')).toBeNull();
  });

  it('скрытое окно с числами - прочерк', () => {
    mount({ stats: { ...base.stats, hidden: 1 } });
    expect(screen.getByText('Окно игры:').closest('tr')?.textContent).toBe('Окно игры:-');
  });

  it('карточки колебаний и потока чата', () => {
    mount({ stats: { ...base.stats, personal_median: 17, chat_rate: 12.34, chat_messages: 5000 } });
    expect(screen.getByText('Колебания:').closest('tr')?.textContent).toBe('Колебания:17 мс');
    expect(screen.getByText('Поток чата:').closest('tr')?.textContent).toBe('Поток чата:12.3 сообщ./с');
    expect(screen.queryByText('Панель чата:')).toBeNull();
    expect(screen.queryByText(/5000/)).toBeNull();
  });

  it('поток чата неизвестен - прочерк', () => {
    mount({ stats: { ...base.stats, chat_rate: null } });
    expect(screen.getByText('Поток чата:').closest('tr')?.textContent).toBe('Поток чата:-');
  });

  it('поток чата - советы про призрачные уши и почему', () => {
    mount({ verdicts: ['flood'], stats: { ...base.stats, chat_rate: 40.2, freezes: 4 } });
    expect(screen.getAllByText(VERDICTS.flood.title).length).toBeGreaterThan(0);
    expect(screen.getByText(VERDICTS.flood.advice[0])).toBeTruthy();
    expect(screen.getByText(VERDICTS.flood.advice[1])).toBeTruthy();
    expect(screen.getByText(/присылает вам 40 сообщений в секунду/)).toBeTruthy();
    expect(screen.queryByText(VERDICTS.freeze.advice[0])).toBeNull();
  });

  it('доля игроков ниже - только когда игроков с данными хотя бы пять', () => {
    mount({ server_clients: 4 });
    expect(screen.getByText('По серверу:').closest('tr')?.textContent).toBe('По серверу:медиана 60 мс');
    mount({ server_clients: 5 });
    expect(screen.getAllByText('По серверу:').pop()?.closest('tr')?.textContent).toBe('По серверу:медиана 60 мс, у 40% игроков пинг ниже вашего');
  });

  it('полоса разбивки не рисует части меньше 1 мс', () => {
    const { container } = mount({ stats: { ...base.stats, base: 40, stall_mean: 0.4, shared_mean: 0, personal_mean: 2 } });
    expect(container.querySelectorAll('.Stack .Stack__item').length).toBe(2);
  });

  it('пустая разбивка не рисует полосу', () => {
    const { container } = mount({ stats: { samples: 0 } });
    expect(container.querySelector('.Stack')).toBeNull();
  });

  it('без цели - замеров нет, без баннера', () => {
    mount({ target: undefined, self: 0, graph: [], verdicts: undefined, stats: undefined });
    expect(screen.getByText('Замеров пока нет.')).toBeTruthy();
    expect(screen.queryByText(/Смотрите соединение/)).toBeNull();
    expect(screen.queryByText('Вернуться к своему')).toBeNull();
  });

  it('админ без цели может вернуться к своему', () => {
    topic.mockClear();
    mount({ staff: 1, target: undefined, self: 0, graph: [], verdicts: undefined, stats: undefined });
    fireEvent.click(screen.getByText('Вернуться к своему'));
    expect(topic.mock.calls.some(([message]) => message.type === 'act/reset_target')).toBe(true);
  });

  it('вкладка игрока у админа называется по-человечески', () => {
    mount({ staff: 1 });
    expect(screen.getByText('Моё соединение')).toBeTruthy();
    expect(screen.getByText('Сервер')).toBeTruthy();
  });

  it('таблица игроков: ихнее, заголовки событий и сортировка по клику', () => {
    const { container } = mount({
      staff: 1,
      tab: 'server',
      clients: [
        { ckey: 'slowpoke', base: 180, rtt_median: 200, rtt_p95: 400, personal_median: 30, spikes_per_min: 1, freezes: 0, ours_fraction: 0.1, verdict: 'far' },
        { ckey: 'jittery', base: 20, rtt_median: 300, rtt_p95: 500, personal_median: 90, spikes_per_min: 4, freezes: 1, ours_fraction: 0.3, verdict: 'jitter' },
      ],
      events: [{ time: '12:00:00', type: 'host_network', clients: 40, fraction: 0.9, extra_ms: 150, stall_ms: 0, source: '' }],
    });
    const order = () => {
      const text = container.textContent ?? '';
      return text.indexOf('slowpoke') < text.indexOf('jittery') ? 'slowpoke' : 'jittery';
    };
    expect(screen.getByText('ихнее')).toBeTruthy();
    expect(screen.getByText('90%')).toBeTruthy();
    expect(screen.getByText('масштаб')).toBeTruthy();
    expect(screen.getByText('источник')).toBeTruthy();
    expect(order()).toBe('jittery');
    fireEvent.click(screen.getByText('база'));
    expect(order()).toBe('slowpoke');
    fireEvent.click(screen.getByText('база'));
    expect(order()).toBe('jittery');
  });

  it('таблица игроков: колонка чат/с с сортировкой', () => {
    const { container } = mount({
      staff: 1,
      tab: 'server',
      clients: [
        { ckey: 'quiet', base: 30, rtt_median: 400, rtt_p95: 40, personal_median: 2, spikes_per_min: 0, freezes: 0, chat_rate: 1.5, ours_fraction: null, verdict: 'ok' },
        { ckey: 'ghosty', base: 30, rtt_median: 35, rtt_p95: 900, personal_median: 60, spikes_per_min: 0, freezes: 3, chat_rate: 41.37, ours_fraction: null, verdict: 'flood' },
        { ckey: 'newbie', base: 30, rtt_median: 300, rtt_p95: 40, personal_median: 2, spikes_per_min: 0, freezes: 0, chat_rate: null, ours_fraction: null, verdict: 'ok' },
      ],
    });
    const order = () => {
      const text = container.textContent ?? '';
      return ['quiet', 'ghosty', 'newbie'].sort((a, b) => text.indexOf(a) - text.indexOf(b)).join(',');
    };
    const row = (ckey: string) => [...(screen.getByText(ckey).closest('tr')?.querySelectorAll('td') ?? [])].map((cell) => cell.textContent);
    expect(row('ghosty')[7]).toBe('41.4');
    expect(row('newbie')[7]).toBe('-');
    expect(row('ghosty')[10]).toBe(VERDICTS.flood.title);
    expect(order()).toBe('quiet,newbie,ghosty');
    fireEvent.click(screen.getByText('чат/с'));
    expect(order()).toBe('ghosty,quiet,newbie');
    fireEvent.click(screen.getByText('чат/с'));
    expect(order()).toBe('newbie,quiet,ghosty');
  });

  it('общая задержка неизвестна - подпись вместо миллисекунд', () => {
    mount({ stats: { ...base.stats, shared_known: 0.2 } });
    expect(screen.getByText('Общая задержка:').closest('tr')?.textContent).toBe('Общая задержка:неизвестна: мало игроков на сервере');
    mount({ stats: { ...base.stats, shared_known: 1 } });
    expect(screen.getAllByText('Общая задержка:').pop()?.closest('tr')?.textContent).toBe('Общая задержка:1 мс - наша сторона');
  });

  it('малое лишнее - прочерк в долях, подвисание у всех - своим именем', () => {
    mount({
      staff: 1,
      tab: 'server',
      clients: [{ ckey: 'calm', base: 30, rtt_median: 35, rtt_p95: 40, personal_median: 2, spikes_per_min: 0, freezes: 0, ours_fraction: null, verdict: 'ok' }],
      events: [{ time: '12:00:00', type: 'mass_freeze', clients: 30, fraction: 1, extra_ms: 3000, stall_ms: 0, source: '-' }],
    });
    const cells = [...(screen.getByText('calm').closest('tr')?.querySelectorAll('td') ?? [])].map((cell) => cell.textContent);
    expect(cells[7]).toBe('-');
    expect(cells[8]).toBe('-');
    expect(cells[9]).toBe('-');
    expect(screen.getByText('подвисание у всех')).toBeTruthy();
  });
});

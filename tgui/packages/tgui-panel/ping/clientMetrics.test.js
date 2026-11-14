import { createClientMetrics, FPS_WINDOW, LOOP_PROBE_INTERVAL } from './clientMetrics';

// Гоняет кадры по step мс, пока окно счёта просит следующий; возвращает число кадров.
const runFrames = (metrics, clock, step) => {
  let count = 0;
  let more = true;
  while (more) {
    clock.t += step;
    count++;
    more = metrics.frame();
  }
  return count;
};

describe('clientMetrics', () => {
  it('меряет отставание event loop, потом сбрасывается', () => {
    let clock = 0;
    const metrics = createClientMetrics(() => clock);
    metrics.loopTick();
    clock += LOOP_PROBE_INTERVAL + 40;
    metrics.loopTick();
    clock += LOOP_PROBE_INTERVAL + 5;
    metrics.loopTick();
    clock = 1000;
    metrics.noteRoundtrip(87.6);
    expect(metrics.take(false, 50)).toEqual({ loopLag: 40, fps: null, hidden: 0, rtt: 88, chatMessages: 50 });
    clock = 2000;
    expect(metrics.take(true, undefined)).toEqual({ loopLag: null, fps: null, hidden: 1, rtt: null, chatMessages: null });
  });

  it('считает кадры одним коротким окном и отдаёт их в следующем отчёте', () => {
    const clock = { t: 0 };
    const metrics = createClientMetrics(() => clock.t);
    expect(metrics.frame()).toBe(false);
    metrics.startFrames();
    expect(runFrames(metrics, clock, 20)).toBe(FPS_WINDOW / 20);
    expect(metrics.frame()).toBe(false);
    clock.t += 1500;
    expect(metrics.take(false, undefined).fps).toBe(50);
    expect(metrics.take(false, undefined).fps).toBeNull();
  });

  it('отчёт посреди окна - кадров нет, окно закрыто', () => {
    const clock = { t: 0 };
    const metrics = createClientMetrics(() => clock.t);
    metrics.startFrames();
    clock.t += 100;
    expect(metrics.frame()).toBe(true);
    expect(metrics.take(false, undefined).fps).toBeNull();
    expect(metrics.frame()).toBe(false);
  });

  it('не отдаёт loopLag и fps за интервал, где окно было скрыто', () => {
    const clock = { t: 0 };
    const metrics = createClientMetrics(() => clock.t);
    metrics.startFrames();
    runFrames(metrics, clock, 40);
    metrics.noteVisibility(true);
    clock.t += 400;
    metrics.noteVisibility(false);
    expect(metrics.take(false, 50)).toEqual({ loopLag: null, fps: null, hidden: 1, rtt: null, chatMessages: 50 });
    metrics.loopTick();
    clock.t += LOOP_PROBE_INTERVAL + 10;
    metrics.loopTick();
    metrics.startFrames();
    expect(runFrames(metrics, clock, 40)).toBe(25);
    expect(metrics.take(false, 50)).toEqual({ loopLag: 10, fps: 25, hidden: 0, rtt: null, chatMessages: 50 });
  });

  it('RTT уходит один раз: без нового ответа отчёт без rtt', () => {
    const metrics = createClientMetrics(() => 0);
    metrics.noteRoundtrip(1500);
    expect(metrics.take(false, 0).rtt).toBe(1500);
    expect(metrics.take(false, 0).rtt).toBeNull();
    expect(metrics.take(false, 0).rtt).toBeNull();
    metrics.noteRoundtrip(70.4);
    expect(metrics.take(false, 0).rtt).toBe(70);
  });

  it('число сообщений в чате - только целое неотрицательное', () => {
    const metrics = createClientMetrics(() => 0);
    expect(metrics.take(false, 0).chatMessages).toBe(0);
    expect(metrics.take(false, 1234).chatMessages).toBe(1234);
    expect(metrics.take(false, -3).chatMessages).toBeNull();
    expect(metrics.take(false, 2.5).chatMessages).toBeNull();
    expect(metrics.take(false, '7').chatMessages).toBeNull();
    expect(metrics.take(false, undefined).chatMessages).toBeNull();
  });
});

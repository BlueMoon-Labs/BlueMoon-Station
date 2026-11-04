import { breakdown, buildReport, gameWindowText, graphGeometry, OLD_BUILD, VERDICTS, whyText } from './model';

describe('PingDiagnostics model', () => {
  it('у каждого вердикта есть заголовок и сторона', () => {
    for (const [code, info] of Object.entries(VERDICTS)) {
      expect(info.title.length).toBeGreaterThan(0);
      expect(['ours', 'yours', 'none']).toContain(info.side);
      if (info.side === 'yours') {
        expect(info.advice.length).toBeGreaterThan(0);
      }
      expect(typeof whyText(code as keyof typeof VERDICTS, {})).toBe('string');
    }
  });

  it('разбивка делит RTT на четыре части со стороной', () => {
    const parts = breakdown({ base: 40, stall_mean: 10, shared_mean: 5, personal_mean: 25 });
    expect(parts.map((p) => p.value)).toEqual([40, 10, 5, 25]);
    expect(parts.map((p) => p.side)).toEqual(['yours', 'ours', 'ours', 'yours']);
  });

  it('почему - с конкретными цифрами', () => {
    expect(whyText('periodic', { period: 600, spikes_per_min: 1 })).toContain('60');
    expect(whyText('far', { base: 180 })).toContain('180');
  });

  it('геометрия графика укладывается в рамку и помечает спайки', () => {
    const geometry = graphGeometry(
      [
        { t: -300, rtt: 40, stall: 0, shared: 0, spike: 0 },
        { t: -150, rtt: 400, stall: 0, shared: 0, spike: 1 },
        { t: 0, rtt: 50, stall: 30, shared: 10, spike: 0 },
      ],
      600,
      100,
    );
    expect(geometry.maxRtt).toBe(400);
    expect(geometry.spikes).toEqual([{ x: 300, y: 0 }]);
    expect(geometry.line).toBe('0,90 300,0 600,87.5');
  });

  it('отчёт содержит вердикт и цифры', () => {
    const report = buildReport({
      target: 'tester',
      byond: '516.1688',
      verdicts: ['jitter'],
      stats: { rtt_median: 80, base: 40, personal_median: 35 },
      server_rtt_median: 60,
    });
    expect(report).toContain('tester');
    expect(report).toContain(VERDICTS.jitter.title);
    expect(report).toContain('80');
  });

  it('скрытое окно игры - прочерк вместо нулей', () => {
    const report = buildReport({ stats: { loop_lag: null, fps: null, hidden: 1 } });
    expect(report).toContain('Окно игры: -');
    expect(report).not.toContain('0 к/с');
    expect(whyText('pc', { loop_lag: null, fps: null })).not.toContain('0 кадров');
  });

  it('скрытое окно с числами - тоже прочерк', () => {
    expect(gameWindowText({ loop_lag: 4, fps: 60, hidden: 1 })).toBe('-');
    expect(whyText('pc', { loop_lag: 4, fps: 60, hidden: 1 })).not.toContain('кадров');
  });

  it('pc - каждое поле отдельно', () => {
    const lagOnly = whyText('pc', { loop_lag: 30, fps: null });
    expect(lagOnly).toContain('отстаёт на 30 мс');
    expect(lagOnly).not.toContain('кадров');
    const fpsOnly = whyText('pc', { loop_lag: null, fps: 12 });
    expect(fpsOnly).toContain('12 кадров');
    expect(fpsOnly).not.toContain('отстаёт');
  });

  it('главный вердикт сервер - подвисания нет и в отчёте', () => {
    const report = buildReport({ verdicts: ['server', 'freeze', 'jitter'], stats: { freezes: 2 } });
    expect(report).not.toContain(VERDICTS.freeze.title);
    expect(report).not.toContain('подвисаний');
    expect(report).toContain(VERDICTS.jitter.title);
    expect(buildReport({ verdicts: ['freeze'], stats: { freezes: 2 } })).toContain('подвисаний за 5 минут: 2');
  });

  it('общая задержка неизвестна при малом онлайне', () => {
    expect(buildReport({ stats: { shared_known: 0.2, shared_mean: 0 } })).toContain('Общая задержка: неизвестна: мало игроков на сервере');
    expect(buildReport({ stats: { shared_known: 1, shared_mean: 12 } })).toContain('Общая задержка: 12 мс');
  });

  it('подвисания склоняются', () => {
    expect(whyText('freeze', { freezes: 1 })).toContain('1 раз.');
    expect(whyText('freeze', { freezes: 2 })).toContain('2 раза.');
    expect(whyText('freeze', { freezes: 5 })).toContain('5 раз.');
    expect(whyText('freeze', { freezes: 22 })).toContain('22 раза.');
  });

  it('поток чата - сколько сообщений в секунду', () => {
    expect(whyText('flood', { chat_rate: 41.4 })).toBe('Сервер присылает вам 41 сообщение в секунду - клиент не успевает их показывать, и пинг стоит в той же очереди.');
    expect(whyText('flood', { chat_rate: 12 })).toContain('12 сообщений в секунду');
    expect(VERDICTS.flood.side).toBe('yours');
    expect(VERDICTS.flood.color).toBe('average');
    expect(VERDICTS.flood.advice.join(' ')).toContain('«Вся речь в режиме призрака»');
    expect(VERDICTS.flood.advice[0]).toContain('откройте «Настройки», вкладку «Чат»');
    expect('chat' in VERDICTS).toBe(false);
  });

  it('старая сборка - совет в отчёте, не вердикт', () => {
    expect('old_build' in VERDICTS).toBe(false);
    expect(buildReport({ verdicts: ['ok'], old_build: 1 })).toContain(`Совет: ${OLD_BUILD.title}. ${OLD_BUILD.why}`);
    expect(buildReport({ verdicts: ['ok'] })).not.toContain('Совет:');
  });

  it('отчёт - строка про поток чата', () => {
    expect(buildReport({ stats: { chat_rate: 41.37 } })).toContain('Поток чата: 41.4 сообщ./с');
    expect(buildReport({ stats: { chat_rate: null } })).toContain('Поток чата: -');
    expect(buildReport({ stats: {} })).not.toContain('Панель чата');
  });

  it('отчёт при потоке - подвисания не вешаются на сеть', () => {
    const report = buildReport({ verdicts: ['flood'], stats: { chat_rate: 40, freezes: 3 } });
    expect(report).toContain(`- ${VERDICTS.flood.title}. Сервер присылает вам 40 сообщений в секунду`);
    expect(report).not.toContain(VERDICTS.freeze.title);
  });
});

import { plural } from 'common/ru/plural';

export type VerdictCode = 'collecting' | 'ok' | 'server' | 'flood' | 'freeze' | 'pc' | 'periodic' | 'loss' | 'jitter' | 'far';

export type Stats = Partial<Record<
  | 'samples' | 'rtt_now' | 'rtt_median' | 'rtt_min' | 'rtt_p95' | 'base' | 'stall_mean' | 'shared_mean'
  | 'personal_mean' | 'extra_mean' | 'ours_fraction' | 'shared_known' | 'personal_median' | 'spikes_per_min' | 'loss_per_min'
  | 'period' | 'freezes' | 'loop_lag' | 'fps' | 'hidden' | 'browser_rtt' | 'chat_rate' | 'chat_messages' | 'server_base'
  | 'build' | 'warn_build',
  number | null
>>;

export type GraphPoint = { t: number; rtt: number; stall: number; shared: number; spike: number | boolean };

export type ClientRow = {
  ckey: string; base: number; rtt_median: number; rtt_p95: number; personal_median: number;
  spikes_per_min: number; freezes: number; chat_rate?: number | null; ours_fraction: number | null; verdict: VerdictCode;
  old_build?: number | boolean;
};

export type PingEvent = {
  time: string; type: 'server' | 'server_load' | 'host_network' | 'mass_freeze'; clients: number;
  fraction: number; extra_ms: number; stall_ms: number; source: string;
};

export type RoundSummary = { ours_fraction: number; verdicts: Record<string, number>; events: Record<string, number> };

export type PingDiagnosticsData = {
  staff: number; tab: 'self' | 'server'; hint_enabled: number;
  server_rtt_median: number; server_base_median: number; server_clients?: number;
  target?: string; self?: number; verdicts?: VerdictCode[]; stats?: Stats;
  percentile?: number; graph?: GraphPoint[]; byond?: string; old_build?: number | boolean;
  clients?: ClientRow[]; events?: PingEvent[]; round?: RoundSummary;
};

type Side = 'ours' | 'yours' | 'none';

export const VERDICTS: Record<VerdictCode, { title: string; color: string; side: Side; advice: string[] }> = {
  collecting: { title: 'Собираем данные, подождите минуту', color: 'label', side: 'none', advice: [] },
  ok: { title: 'Связь в порядке', color: 'good', side: 'none', advice: [] },
  server: { title: 'Задержки на стороне сервера - это не у вас', color: 'average', side: 'ours', advice: [] },
  flood: {
    title: 'Клиент не успевает за потоком сообщений',
    color: 'average',
    side: 'yours',
    advice: [
      'Если вы наблюдатель - откройте «Настройки», вкладку «Чат», и выключите «Вся речь в режиме призрака», «Все эмоуты в режиме призрака» и «Радио в режиме призрака»: они присылают всё, что происходит на станции.',
      'Там же можно выключить «OOC чат» и «LOOC чат» - меньше сообщений, меньше задержка. Вкладки панели чата поток не уменьшают: сообщения всё равно приходят.',
    ],
  },
  freeze: {
    title: 'Соединение время от времени подвисает',
    color: 'bad',
    side: 'yours',
    advice: ['Проверьте, не переподключается ли Wi-Fi и не отваливается ли кабель.', 'Закройте программы, которые грузят сеть: торренты, обновления, облака.'],
  },
  pc: {
    title: 'Компьютер не успевает',
    color: 'bad',
    side: 'yours',
    advice: ['Закройте тяжёлые программы и вкладки браузера.', 'Если ноутбук - подключите зарядку и включите режим производительности.'],
  },
  periodic: {
    title: 'Пинг скачет через ровные промежутки',
    color: 'average',
    side: 'yours',
    advice: ['Так часто ведёт себя поиск сетей Wi-Fi - лучше всего помогает кабель.', 'Проверьте фоновые программы: синхронизацию облака, лаунчеры, торрент.'],
  },
  loss: {
    title: 'По дороге теряются пакеты',
    color: 'bad',
    side: 'yours',
    advice: ['Подключитесь кабелем или поближе к роутеру.', 'Перезагрузите роутер. Если не поможет - это повод написать провайдеру.'],
  },
  jitter: {
    title: 'Нестабильная сеть',
    color: 'average',
    side: 'yours',
    advice: ['Чаще всего виноват Wi-Fi - попробуйте кабель.', 'Остановите загрузки и стримы на этой сети.'],
  },
  far: {
    title: 'До сервера далеко',
    color: 'average',
    side: 'yours',
    advice: ['Если включён VPN или прокси - попробуйте без него.', 'Иногда провайдер ведёт трафик кружным путём, тут поможет только другой провайдер или VPN с точкой поближе к серверу.'],
  },
};

// Старая сборка - совет, а не вердикт: на пинг она не влияет.
export const OLD_BUILD = {
  title: 'Обновите BYOND',
  why: 'Ваша сборка BYOND старше рекомендуемой. На пинг это не влияет - старые сборки держат связь не хуже новых.',
  advice: 'Свежая версия есть на byond.com, в ней исправлены ошибки клиента.',
};

export const ms = (value?: number | null) => `${Math.round(value ?? 0)} мс`;

const isNumber = (value?: number | null): value is number => typeof value === 'number';

// Пока окно игры скрыто, замеры отрисовки не свежие: сервер шлёт hidden = 1 или null.
export const gameWindowText = (stats: Stats) =>
  !stats.hidden && isNumber(stats.loop_lag) && isNumber(stats.fps)
    ? `отстаёт на ${ms(stats.loop_lag)}, ${Math.round(stats.fps)} к/с`
    : '-';

const pcWhyText = (stats: Stats) => {
  const lag = !stats.hidden && isNumber(stats.loop_lag);
  const fps = !stats.hidden && isNumber(stats.fps);
  if (lag && fps) {
    return `Окно игры отстаёт на ${ms(stats.loop_lag)} и рисует ${Math.round(stats.fps ?? 0)} кадров в секунду.`;
  }
  if (lag) {
    return `Окно игры отстаёт на ${ms(stats.loop_lag)}.`;
  }
  if (fps) {
    return `Окно игры рисует ${Math.round(stats.fps ?? 0)} кадров в секунду.`;
  }
  return 'Окно игры было свёрнуто, свежих замеров отрисовки нет.';
};

export const chatRateText = (rate?: number | null) => (isNumber(rate) ? `${rate.toFixed(1)} сообщ./с` : '-');

// При общей беде на сервере его простой выглядит подвисанием у всех, это не вина игрока.
const blamesPlayer = (verdicts: VerdictCode[], code: VerdictCode) => !(verdicts[0] === 'server' && code === 'freeze');

export const adviceFor = (verdicts: VerdictCode[]) => ({
  title: verdicts[0] === 'server' ? 'Ещё с вашей стороны' : 'Что можно сделать',
  codes: verdicts.filter((code) => VERDICTS[code]?.side === 'yours' && blamesPlayer(verdicts, code)),
});

export const whyText = (verdict: VerdictCode, stats: Stats): string => {
  switch (verdict) {
    case 'server':
      return `Простой сервера и общая задержка - ${Math.round((stats.ours_fraction ?? 0) * 100)}% лишнего пинга, у других игроков в это время то же самое.`;
    case 'freeze':
      return `За 5 минут соединение замолкало на 3 с и дольше ${stats.freezes ?? 0} ${plural(stats.freezes ?? 0, 'раз', 'раза', 'раз')}.`;
    case 'pc':
      return pcWhyText(stats);
    case 'flood': {
      const rate = Math.round(stats.chat_rate ?? 0);
      return `Сервер присылает вам ${rate} ${plural(rate, 'сообщение', 'сообщения', 'сообщений')} в секунду - клиент не успевает их показывать, и пинг стоит в той же очереди.`;
    }
    case 'periodic':
      return `Скачки повторяются примерно раз в ${Math.round((stats.period ?? 0) / 10)} с.`;
    case 'loss':
      return `${(stats.loss_per_min ?? 0).toFixed(1)} одиночных скачков в минуту на 180 мс и выше - так выглядит повтор потерянного пакета.`;
    case 'jitter':
      return `Пинг гуляет в среднем на ${ms(stats.personal_median)} от вашего минимума.`;
    case 'far':
      return `Даже в лучший момент пинг ${ms(stats.base)}${stats.server_base ? `, у большинства игроков ${ms(stats.server_base)}` : ''}.`;
    default:
      return '';
  }
};

// Ниже этой доли замеров общую задержку посчитать не из чего, как PING_DIAG_SHARED_KNOWN_MIN.
const SHARED_KNOWN_MIN = 0.5;

export const SHARED_UNKNOWN_TEXT = 'неизвестна: мало игроков на сервере';

export const sharedUnknown = (stats: Stats) => isNumber(stats.shared_known) && stats.shared_known < SHARED_KNOWN_MIN;

export const breakdown = (stats: Stats) => [
  { key: 'base', label: 'База сети', value: stats.base ?? 0, side: 'yours' as Side, color: '#4a8fd4', unknown: false },
  { key: 'stall', label: 'Простой сервера', value: stats.stall_mean ?? 0, side: 'ours' as Side, color: '#d4774a', unknown: false },
  { key: 'shared', label: 'Общая задержка', value: stats.shared_mean ?? 0, side: 'ours' as Side, color: '#d4b24a', unknown: sharedUnknown(stats) },
  { key: 'personal', label: 'Колебания сети', value: stats.personal_mean ?? 0, side: 'yours' as Side, color: '#9a5fd4', unknown: false },
];

export const GRAPH_WINDOW_SECONDS = 300;

export const graphGeometry = (points: GraphPoint[], width: number, height: number) => {
  const maxRtt = Math.max(100, ...points.map((p) => p.rtt));
  const x = (t: number) => Math.round(((t + GRAPH_WINDOW_SECONDS) / GRAPH_WINDOW_SECONDS) * width * 100) / 100;
  const y = (value: number) => Math.round((height - (value / maxRtt) * height) * 100) / 100;
  const line = points.map((p) => `${x(p.t)},${y(p.rtt)}`).join(' ');
  const ours = points.length
    ? `${x(points[0].t)},${height} ${points.map((p) => `${x(p.t)},${y(p.stall + p.shared)}`).join(' ')} ${x(points[points.length - 1].t)},${height}`
    : '';
  const spikes = points.filter((p) => p.spike).map((p) => ({ x: x(p.t), y: y(p.rtt) }));
  return { maxRtt, line, ours, spikes };
};

export const buildReport = (data: Partial<PingDiagnosticsData>) => {
  const stats = data.stats ?? {};
  const all = data.verdicts ?? [];
  const verdicts = all.filter((code) => blamesPlayer(all, code));
  const spikes = `Спайков в минуту: ${(stats.spikes_per_min ?? 0).toFixed(1)}`;
  const lines = [
    `Диагностика пинга: ${data.target ?? '?'}, BYOND ${data.byond ?? '?'}`,
    `Пинг: сейчас ${ms(stats.rtt_now)}, медиана ${ms(stats.rtt_median)}, минимум ${ms(stats.rtt_min)}, p95 ${ms(stats.rtt_p95)}`,
    `По серверу медиана ${ms(data.server_rtt_median)}`,
    ...breakdown(stats).map((part) => `${part.label}: ${part.unknown ? SHARED_UNKNOWN_TEXT : ms(part.value)}`),
    verdicts.length < all.length ? spikes : `${spikes}, подвисаний за 5 минут: ${stats.freezes ?? 0}`,
    `Окно игры: ${gameWindowText(stats)}`,
    `Поток чата: ${chatRateText(stats.chat_rate)}`,
    ...verdicts.map((code) => `- ${VERDICTS[code]?.title ?? code}. ${whyText(code, stats)}`),
    ...(data.old_build ? [`Совет: ${OLD_BUILD.title}. ${OLD_BUILD.why}`] : []),
  ];
  return lines.join('\n');
};

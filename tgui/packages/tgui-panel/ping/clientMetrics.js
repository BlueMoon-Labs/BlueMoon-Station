/**
 * Метрики клиента для диагностики пинга: насколько отстаёт event loop браузера,
 * сколько кадров он рисует, видно ли окно и сколько сообщений на экране чата.
 */

export const LOOP_PROBE_INTERVAL = 250;
// Кадры считаются коротким окном раз за интервал пинга, а не постоянно.
export const FPS_WINDOW = 1000;

export const createClientMetrics = (now = () => performance.now()) => {
  let expectedAt = 0;
  let maxLag = 0;
  let frames = 0;
  let framesSince = null;
  let fps = null;
  let lastRtt;
  let hiddenSeen = false;
  return {
    loopTick() {
      const t = now();
      if (expectedAt) {
        maxLag = Math.max(maxLag, t - expectedAt);
      }
      expectedAt = t + LOOP_PROBE_INTERVAL;
    },
    startFrames() {
      frames = 0;
      fps = null;
      framesSince = now();
    },
    // true - окно ещё идёт и нужен следующий кадр.
    frame() {
      if (framesSince === null) {
        return false;
      }
      frames++;
      const elapsed = now() - framesSince;
      if (elapsed < FPS_WINDOW) {
        return true;
      }
      fps = Math.round(frames / (elapsed / 1000));
      framesSince = null;
      return false;
    },
    noteRoundtrip(rtt) {
      lastRtt = rtt;
    },
    noteVisibility(hidden) {
      if (hidden) {
        hiddenSeen = true;
      }
    },
    take(hidden, chatMessages) {
      // Скрытое окно троттлит таймеры и ставит rAF на паузу: такие замеры врут.
      const wasHidden = !!hidden || hiddenSeen;
      const report = {
        loopLag: wasHidden ? null : Math.round(maxLag),
        fps: wasHidden ? null : fps,
        hidden: wasHidden ? 1 : 0,
        // Только ответ, пришедший с прошлого отчёта: повтор старого RTT исказил бы медиану на сервере.
        rtt: lastRtt === undefined ? null : Math.round(lastRtt),
        chatMessages: Number.isInteger(chatMessages) && chatMessages >= 0 ? chatMessages : null,
      };
      lastRtt = undefined;
      maxLag = 0;
      fps = null;
      framesSince = null;
      hiddenSeen = !!hidden;
      return report;
    },
  };
};

/**
 * BYOND IE: cooldown_per_use / ext_cooldown in deciseconds (world.time).
 * @param external — внешний КД корпуса: 0 = «нет»; внутренний: 0 = «0 с».
 */
export function formatIeCooldownDs(ds: unknown, external = false): string {
  if (ds === null || ds === undefined || ds === '') {
    return '—';
  }
  const n = Number(ds);
  if (!Number.isFinite(n) || n < 0) {
    return '—';
  }
  if (n === 0) {
    return external ? 'нет' : '0 с';
  }
  const sec = n / 10;
  const rounded = Math.round(sec * 10) / 10;
  const s = rounded % 1 === 0 ? String(rounded) : rounded.toFixed(1);
  return `${s} с`;
}

export function formatIeSizeDisplay(size: unknown): string {
  if (size === null || size === undefined || size === '') {
    return '—';
  }
  const n = Number(size);
  if (!Number.isFinite(n)) {
    return '—';
  }
  if (n < 0) {
    return '0';
  }
  return String(n);
}

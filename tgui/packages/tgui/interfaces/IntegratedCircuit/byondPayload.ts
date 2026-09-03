/**
 * BYOND may serialize dense 1-based lists as JSON objects `{ "1": a, "2": b }`
 * instead of arrays. If the client only accepts `Array.isArray`, the UI shows
 * zero components. Wiremod builds lists with `+=` and usually yields arrays.
 */

import type { CircuitComponentPayload, CircuitComponentView, CircuitPortPayload } from './types';

export function byondListToArray<T = unknown>(raw: unknown): T[] {
  if (raw === null || raw === undefined) {
    return [];
  }
  if (Array.isArray(raw)) {
    return raw as T[];
  }
  if (typeof raw !== 'object') {
    return [];
  }
  const keys = Object.keys(raw as object);
  if (!keys.length) {
    return [];
  }
  if (!keys.every((k) => /^\d+$/.test(k))) {
    return [];
  }
  const nums = keys.map((k) => Number(k));
  const minKey = Math.min(...nums);
  const maxKey = Math.max(...nums);
  if (minKey !== 1) {
    return [];
  }
  const keySet = new Set(nums);
  if (keySet.size !== keys.length) {
    return [];
  }
  for (let i = 1; i <= maxKey; i++) {
    if (!keySet.has(i)) {
      return [];
    }
  }
  return keys
    .sort((a, b) => Number(a) - Number(b))
    .map((k) => (raw as Record<string, T>)[k]);
}

/**
 * Список исходящих ref'ов на входе: BYOND шлёт массив или плотный объект;
 * элемент — строка REF или объект с полем `ref`.
 */
export function connectedToRefList(raw: unknown): string[] {
  return byondListToArray<string | { ref?: string }>(raw)
    .map((entry) => (typeof entry === 'string' ? entry : entry?.ref))
    .filter((r): r is string => typeof r === 'string' && r.length > 0);
}

export function normalizeCircuitComponent(
  comp: unknown,
): CircuitComponentView | null {
  if (!comp || typeof comp !== 'object') {
    return null;
  }
  const c = comp as CircuitComponentPayload;
  return {
    ...c,
    input_ports: byondListToArray<CircuitPortPayload>(c.input_ports),
    output_ports: byondListToArray<CircuitPortPayload>(c.output_ports),
  };
}

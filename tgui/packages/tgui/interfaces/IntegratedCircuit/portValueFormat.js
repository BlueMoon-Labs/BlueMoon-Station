/** Max characters for inline live port value in the circuit UI */
const MAX_LIVE_LEN = 44;

/**
 * Format a port's live value for read-only display (BYOND → JSON types).
 */
export function formatPortLiveValue(data, portType) {
  if (data === null || data === undefined) {
    return '—';
  }
  if (portType === 'signal') {
    return data ? '●' : '○';
  }
  if (portType === 'boolean') {
    return data ? 'true' : 'false';
  }
  if (portType === 'list') {
    return typeof data === 'string' ? data : `list(${Array.isArray(data) ? data.length : '?'})`;
  }
  if (typeof data === 'boolean') {
    return data ? 'true' : 'false';
  }
  if (typeof data === 'number') {
    return Number.isFinite(data) ? String(data) : '—';
  }
  if (typeof data === 'string') {
    return data.length > MAX_LIVE_LEN
      ? `${data.slice(0, MAX_LIVE_LEN)}…`
      : data;
  }
  if (typeof data === 'object') {
    try {
      const s = JSON.stringify(data);
      return s.length > MAX_LIVE_LEN
        ? `${s.slice(0, MAX_LIVE_LEN)}…`
        : s;
    } catch {
      return '…';
    }
  }
  const s = String(data);
  return s.length > MAX_LIVE_LEN ? `${s.slice(0, MAX_LIVE_LEN)}…` : s;
}

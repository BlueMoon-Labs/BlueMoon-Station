import './notices.scss';

import { memo, useEffect, useRef, useState } from 'react';
import { createPortal } from 'react-dom';

import { Icon } from '../../components';
import { themeStyle } from './themes';
import { NetrunNotice } from './types';
import { useNetrunSelector } from './useNetrunBackend';

type Toast = NetrunNotice & { count: number; deadline: number };
const NOTICE_ICONS = { good: 'circle-check', bad: 'triangle-exclamation', average: 'circle-exclamation', label: 'circle-info' };

const receiveNotices = (current: Toast[], incoming: NetrunNotice[], now: number): Toast[] => {
  let next = current.filter((toast) => toast.deadline > now);
  for (const notice of incoming) {
    if (!notice.text.trim()) { continue; }
    const deadline = now + (notice.kind === 'bad' ? 7000 : 5000);
    const previous = next.find((toast) => toast.kind === notice.kind && toast.text === notice.text && toast.topic === notice.topic);
    if (previous) {
      next = next.map((toast) => toast === previous ? { ...toast, count: toast.count + 1, deadline } : toast);
    } else {
      next = [...next, { ...notice, count: 1, deadline }].slice(-3);
    }
  }
  return next;
};

/** Fresh server notices only: the first snapshot is history, never a toast replay. */
const NoticeToastsView = () => {
  const { notices, theme, inCombat } = useNetrunSelector((data) => ({
    notices: data.notices, theme: data.ui_theme, inCombat: data.workspace_view === 'combat',
  }));
  const cursor = useRef<number | null>(null);
  const [toasts, setToasts] = useState<Toast[]>([]);
  useEffect(() => {
    if (!Array.isArray(notices)) { return; }
    const latest = notices.length ? notices[notices.length - 1].id : 0;
    if (cursor.current === null || latest < cursor.current) {
      cursor.current = latest;
      setToasts((current) => current.length ? [] : current);
      return;
    }
    if (latest === cursor.current) { return; }
    const fresh = notices.filter((notice) => notice.id > cursor.current! && (!inCombat || notice.topic !== 'combat'));
    cursor.current = latest;
    if (fresh.length) { setToasts((current) => receiveNotices(current, fresh, performance.now())); }
  }, [notices, inCombat]);

  useEffect(() => {
    if (inCombat) { setToasts((current) => current.some((toast) => toast.topic === 'combat') ? current.filter((toast) => toast.topic !== 'combat') : current); }
  }, [inCombat]);

  // One deadline timer for at most three cards; no polling or network actions.
  useEffect(() => {
    if (!toasts.length) { return; }
    const deadline = Math.min(...toasts.map((toast) => toast.deadline));
    const timer = window.setTimeout(() => {
      setToasts((current) => current.filter((toast) => toast.deadline > performance.now()));
    }, Math.max(0, Math.ceil(deadline - performance.now())));
    return () => window.clearTimeout(timer);
  }, [toasts]);

  const shown = inCombat ? toasts.filter((toast) => toast.topic !== 'combat') : toasts;
  if (!shown.length) { return null; }
  return createPortal(
    <aside className="netrun-notices" role="region" aria-label="Уведомления" style={themeStyle(theme)}>
      {shown.map((toast) => (
        <div key={toast.id} className="netrun-notice" data-net-notice={toast.id} data-kind={toast.kind}
          role={toast.kind === 'bad' ? 'alert' : 'status'} aria-live="polite" aria-atomic="true"
          onMouseEnter={() => setToasts((current) => current.filter((entry) => entry.id !== toast.id))}>
          <Icon name={NOTICE_ICONS[toast.kind]} aria-hidden="true" />
          <div className="netrun-notice__text">
            {toast.text}
            {toast.count > 1 && <small aria-label={`Повторов: ${toast.count}`}>×{toast.count}</small>}
          </div>
          <button type="button" aria-label="Закрыть уведомление" title="Закрыть уведомление"
            onClick={() => setToasts((current) => current.filter((entry) => entry.id !== toast.id))}>×
          </button>
        </div>
      ))}
    </aside>,
    document.body,
  );
};

export const NoticeToasts = memo(NoticeToastsView);

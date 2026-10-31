import { memo, useMemo, useState } from 'react';

import { Box, Button, Icon } from '../../components';
import { NetOperation, THEME } from './types';
import { useNetrunBackend } from './useNetrunBackend';

export const operationActive = (operation: NetOperation) => operation.phase === 'queued' || operation.phase === 'running';
export const OPERATION_PHASES: Record<NetOperation['phase'], { label: string; icon: string; color: string }> = {
  queued: { label: 'Ожидает доставки', icon: 'clock', color: THEME.muted },
  running: { label: 'Обрабатывается', icon: 'gears', color: THEME.accent },
  completed: { label: 'Обработано', icon: 'check', color: THEME.good },
  rejected: { label: 'Отклонено', icon: 'triangle-exclamation', color: THEME.bad },
  cancelled: { label: 'Отменено', icon: 'ban', color: THEME.warn },
};
const EMPTY: NetOperation[] = [];

/** Server delivery outcomes stay separate from the immediate input receipt. */
export const OperationsPanel = memo((props: { onLocate: (address: string) => void }) => {
  const { data } = useNetrunBackend(['operations']);
  const operations = data.operations ?? EMPTY;
  const [filter, setFilter] = useState<'all' | 'active' | 'errors'>('all');
  const [query, setQuery] = useState('');
  const shown = useMemo(() => operations.filter((operation) => (
    (filter === 'all' || (filter === 'active' ? operationActive(operation)
      : operation.phase === 'rejected' || operation.phase === 'cancelled'))
    && [operation.id, operation.operation_id, operation.label, operation.kind, operation.service, operation.from, operation.to, operation.reason, operation.result]
      .some((value) => typeof value === 'string' && value.toLowerCase().includes(query.trim().toLowerCase()))
  )).slice().reverse(), [operations, filter, query]);
  return (
    <div className="netrun-operations" role="region" aria-label="Журнал сетевых операций">
      <div className="netrun-operations__tools">
        {([['all', 'Все'], ['active', 'В работе'], ['errors', 'Отказы']] as const).map(([id, label]) => (
          <Button key={id} compact role="button" selected={filter === id} aria-pressed={filter === id} content={label} onClick={() => setFilter(id)} />
        ))}
        <input aria-label="Поиск операций" value={query} onChange={(event) => setQuery(event.target.value)}
          placeholder="Адрес, команда, ID или причина…" />
      </div>
      <Box color={THEME.muted} fontSize="11px" mb={1}>
        Последние операции сеанса. «Обработано» означает завершение сетевого запроса; состояние машины показывает его эффект.
      </Box>
      <div className="netrun-operations__list">
        {!shown.length && <Box color={THEME.muted}>{operations.length ? 'Нет операций по выбранному фильтру.' : 'Сетевых операций пока нет.'}</Box>}
        {shown.map((operation) => {
          const state = OPERATION_PHASES[operation.phase];
          return (
            <details key={operation.id} className="netrun-operations__entry" data-net-operation={operation.id}>
              <summary>
                <Icon name={state.icon} color={state.color} />
                <span className="netrun-operations__label">{operation.label || operation.kind}</span>
                <span style={{ color: state.color }}>{state.label}</span>
                <code>{operation.to || '—'}</code>
              </summary>
              <div className="netrun-operations__details">
                <div><span>ID операции</span><code>{operation.operation_id}</code></div>
                <div><span>Пакет</span><code>{operation.id} · {operation.kind}</code></div>
                {!!operation.service && <div><span>Служба</span><code>{operation.service}</code></div>}
                <div><span>Откуда → куда</span><code>{operation.from || '—'} → {operation.to || '—'}</code></div>
                <div><span>Время до последнего этапа</span><span>{Math.max(0, Math.round((operation.updated_at - operation.started_at) * 100))} мс</span></div>
                {!!operation.reason && <Box color={state.color}>{operation.reason}</Box>}
                {!!operation.result && <Box style={{ whiteSpace: 'pre-wrap', overflowWrap: 'anywhere', maxHeight: '240px', overflowY: 'auto' }}>{operation.result}</Box>}
                {!!operation.route?.length && <div><span>Маршрут</span><code>{operation.route.join(' → ')}</code></div>}
                {!!operation.to && <Button compact role="button" icon="location-crosshairs" content="Показать узел"
                  onClick={() => props.onLocate(operation.to!)} />}
              </div>
            </details>
          );
        })}
      </div>
    </div>
  );
});

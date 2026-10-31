import { memo, ReactNode, useCallback, useMemo } from 'react';

import { Box, Button, Stack } from '../../components';
import { MatrixState, NetrunData, THEME } from './types';
import { useNetrunBackend as useBackend } from './useNetrunBackend';

const LIME = THEME.accent;
const CELL = 46;

/** Головоломка взлома. Тип выбирает сервер: протокол (matrix) или трассировка (sequence). */
export const MatrixPanel = (props: { state: MatrixState }) => {
  const { act } = useBackend<NetrunData>([]);
  const signature = JSON.stringify(props.state);
  const state = useMemo(() => props.state, [signature]);
  return <MatrixView state={state} act={act} />;
};

// Компактная рамка: не растягивается на всю адаптивную область, а остаётся небольшой и по центру.
const Shell = (props: { children: ReactNode }) => (
  <Box
    p={2}
    className="netrun-breach-card"
    style={{
      background: THEME.panel,
      border: `1px solid ${THEME.line}`,
      display: 'block',
      maxWidth: '800px',
      width: '100%',
      maxHeight: '100%',
      overflowY: 'auto',
      margin: '24px auto',
      boxSizing: 'border-box',
      borderRadius: '10px',
    }}
  >
    {props.children}
  </Box>
);

const MatrixView = memo((props: { state: MatrixState; act: (action: string, payload?: object) => void }) => {
  const { state, act } = props;
  if (state.minigame === 'automatic') {
    return (
      <Box p={2} className="netrun-auto-breach" style={{ width: '100%', maxWidth: '760px', margin: '24px auto', overflowY: 'auto' }}>
        <Box bold color={LIME}>autobreach.exe · {state.target}</Box>
        <Box my={1}>Подбор доступа: {Math.round((state.progress ?? 0) * 100)}% · осталось {state.time_left} с</Box>
        <Box style={{ height: '12px', background: THEME.line }}>
          <Box style={{ width: `${(state.progress ?? 0) * 100}%`, height: '100%', background: LIME }} />
        </Box>
        <Box my={1} color={THEME.muted}>Результат: USER узла или ГОСТЬ ЛВС. Не теряйте связь и файл программы. ICE и трассировка остаются активны.</Box>
        <Box mb={1} color={THEME.muted}>Отмена сохраняет накопленную трассировку, но не добавляет штраф.</Box>
        <Button icon="stop" color="bad" content="Прервать взлом" onClick={() => act('breach_abort')} />
      </Box>
    );
  }
  if (state.minigame === 'sequence') {
    return <SequenceView state={state} act={act} />;
  }
  return <ProtocolView state={state} act={act} />;
});

// ——— Протокол взлома (матрица кодов) ———

const ProtocolView = (props: { state: MatrixState; act: (action: string, payload?: object) => void }) => {
  const { state, act } = props;
  const rows = useMemo(() => Array.from({ length: state.size }, (_, row) =>
    Array.from({ length: state.size }, (_, column) => row * state.size + column)), [state.size]);
  const onPick = useCallback((index: number) => act('breach_pick', { index: index + 1 }), [act]);
  return (
    <Box style={{ display: 'flex', justifyContent: 'center', width: '100%' }}>
      <Shell>
        <Header target={state.target} security={state.security} timeLeft={state.time_left}
          subtitle={`выбор в ${state.pick_row ? 'строке' : 'столбце'}`} />
        <Box mb={1} color={THEME.muted} fontSize="11px">
          Первый код выбирайте в верхней строке. Затем чередуйте столбец и строку последней выбранной клетки.
          Клетки нельзя использовать повторно. Соберите коды цели подряд в буфере; число мест в нём ограничено.
          Завершение сохраняет уже собранные цели.
        </Box>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '14px' }}>
          <table aria-label="Матрица протокола" style={{ borderCollapse: 'separate', borderSpacing: '3px', width: 'auto', flex: '0 0 auto' }}>
            <tbody>
              {rows.map((row, r) => (
                <tr key={r}>
                  {row.map((index) => (
                    <GridCell key={index} code={state.cells[index].code} active={state.cells[index].active}
                      index={index} onPick={onPick} />
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
          <Box style={{ flex: '1 1 150px', minWidth: '150px' }}>
            <Box color={THEME.muted} fontSize="11px" mb={0.5}>БУФЕР</Box>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: '3px', marginBottom: '8px' }}>
              {Array.from({ length: state.buffer_size ?? 0 }).map((_, i) => (
                <Box key={i} style={{ width: '28px', height: '24px', lineHeight: '24px', textAlign: 'center',
                  fontFamily: 'monospace', border: `1px dashed ${state.buffer?.[i] ? LIME : THEME.line}`, color: LIME }}>
                  {state.buffer?.[i] || ''}
                </Box>
              ))}
            </div>
            <Box color={THEME.muted} fontSize="11px" mb={0.5}>ЦЕЛИ</Box>
            {state.daemons.map((goal) => (
              <Box key={goal.name} mb={0.5} style={{ fontFamily: 'monospace' }}>
                <Box inline color={goal.done ? THEME.good : THEME.text} mr={1}>{goal.sequence.join(' ')}</Box>
                <Box inline color={goal.done ? THEME.good : THEME.muted} fontSize="11px">{goal.done ? '✔ ' : ''}{goal.name}</Box>
              </Box>
            ))}
            <Button mt={1} icon="stop" color="bad" content="Завершить" onClick={() => act('breach_abort')} />
          </Box>
        </div>
      </Shell>
    </Box>
  );
};

// ——— Трассировка цепочки (нажимать пронумерованные ячейки по порядку) ———

const SequenceView = (props: { state: MatrixState; act: (action: string, payload?: object) => void }) => {
  const { state, act } = props;
  const rows = useMemo(() => Array.from({ length: state.size }, (_, row) =>
    Array.from({ length: state.size }, (_, column) => row * state.size + column)), [state.size]);
  const onPick = useCallback((index: number) => act('breach_pick', { index: index + 1 }), [act]);
  const progress = state.progress ?? 0;
  const total = state.total ?? 0;
  return (
    <Box style={{ display: 'flex', justifyContent: 'center', width: '100%' }}>
      <Shell>
        <Header target={state.target} security={state.security} timeLeft={state.time_left}
          subtitle={`трассировка ${progress}/${total}`} />
        <Box mb={0.5} style={{ height: '4px', background: THEME.line, borderRadius: '2px' }}>
          <Box style={{ height: '4px', width: `${total ? (progress / total) * 100 : 0}%`, background: LIME,
            borderRadius: '2px', transition: 'width 0.3s ease' }} />
        </Box>
        <table aria-label="Последовательность трассировки" style={{ borderCollapse: 'separate', borderSpacing: '3px', width: 'auto', margin: '12px auto' }}>
          <tbody>
            {rows.map((row, r) => (
              <tr key={r}>
                {row.map((index) => (
                  <SeqCell key={index} cell={state.cells[index]} index={index} onPick={onPick} />
                ))}
              </tr>
            ))}
          </tbody>
        </table>
        <Box mt={1} color={THEME.muted} fontSize="11px">
          Нажимайте пронумерованные клетки по порядку: 1, 2, 3 и далее. Следующая клетка подсвечена.
          Частичная цепочка открывает первую цель, полная — ROOT. Завершение сохраняет уже собранные цели; ошибка отнимает 3 секунды.
        </Box>
        <Button mt={1} icon="stop" color="bad" content="Завершить" onClick={() => act('breach_abort')} />
      </Shell>
    </Box>
  );
};

const Header = (props: { target: string; security: number; timeLeft: number; subtitle: string }) => (
  <Stack align="center" mb={1}>
    <Stack.Item grow>
      <Box color={LIME} bold style={{ fontFamily: 'monospace' }}>{props.target}</Box>
      <Box color={THEME.muted} fontSize="11px">Сложность {props.security} · {props.subtitle}</Box>
    </Stack.Item>
    <Stack.Item>
      <Box fontSize="20px" style={{ fontFamily: 'monospace' }} color={props.timeLeft <= 10 ? THEME.bad : LIME}>
        {props.timeLeft}s
      </Box>
    </Stack.Item>
  </Stack>
);

const GridCell = memo((props: {
  code: string | null;
  active: boolean;
  index: number;
  onPick: (index: number) => void;
}) => {
  const { code, active, index, onPick } = props;
  const clickable = active && !!code;
  return (
    <td
      role={clickable ? 'button' : undefined}
      tabIndex={clickable ? 0 : -1}
      aria-label={clickable ? `Выбрать код ${code}` : undefined}
      onClick={clickable ? () => onPick(index) : undefined}
      onKeyDown={(event) => {
        if (clickable && (event.key === 'Enter' || event.key === ' ')) {
          event.preventDefault();
          onPick(index);
        }
      }}
      style={{
        width: `${CELL}px`, height: `${CELL}px`, textAlign: 'center', fontFamily: 'monospace', fontSize: '15px',
        cursor: clickable ? 'pointer' : 'default',
        color: !code ? '#566b7a' : active ? '#e5f1fa' : '#91a8bc',
        background: active ? 'rgba(85, 203, 233, 0.17)' : '#0c1a27',
        border: `1px solid ${active ? LIME : THEME.line}`,
        transition: 'background 0.2s, color 0.2s',
      }}
    >
      {code || '[ ]'}
    </td>
  );
});

const SeqCell = memo((props: {
  cell: { code: string | null; order?: number; done?: boolean; active?: boolean };
  index: number;
  onPick: (index: number) => void;
}) => {
  const { cell, index, onPick } = props;
  const isTarget = (cell.order ?? 0) > 0;
  const clickable = !!cell.active;
  const color = cell.done ? THEME.good : cell.active ? THEME.text : isTarget ? '#9cb6c8' : '#7992a6';
  return (
    <td
      role={clickable ? 'button' : undefined}
      tabIndex={clickable ? 0 : -1}
      aria-label={clickable ? `Выбрать код ${cell.code}, шаг ${cell.order || ''}` : undefined}
      onClick={clickable ? () => onPick(index) : undefined}
      onKeyDown={(event) => {
        if (clickable && (event.key === 'Enter' || event.key === ' ')) {
          event.preventDefault();
          onPick(index);
        }
      }}
      style={{
        width: `${CELL}px`, height: `${CELL}px`, textAlign: 'center', fontFamily: 'monospace', fontSize: '15px',
        position: 'relative', cursor: clickable ? 'pointer' : 'default', color,
        background: cell.done ? 'rgba(91, 218, 177, 0.17)' : cell.active ? 'rgba(85, 203, 233, 0.20)' : '#0c1a27',
        border: `1px solid ${cell.active ? LIME : cell.done ? THEME.good + '66' : THEME.line}`,
        boxShadow: cell.active ? `inset 0 0 0 1px ${LIME}66` : undefined,
        transition: 'background 0.2s, box-shadow 0.2s, border-color 0.2s',
      }}
    >
      {cell.done ? '✔' : cell.code}
      {isTarget && !cell.done && (
        <span style={{ position: 'absolute', top: '1px', right: '2px', fontSize: '8px', color: cell.active ? LIME : THEME.muted }}>
          {cell.order}
        </span>
      )}
    </td>
  );
});

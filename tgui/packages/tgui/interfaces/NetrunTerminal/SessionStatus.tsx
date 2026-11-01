import { memo } from 'react';

import { Box, Button, Icon } from '../../components';
import { IncomingAttacks } from './CombatPanel';
import { OPERATION_PHASES, operationActive } from './OperationsPanel';
import { NetrunData, THEME } from './types';
import { useNetrunBackend as useBackend, useNetrunFeedback } from './useNetrunBackend';

/** A reserved row keeps urgent feedback visible without moving tools or taking focus. */
const SessionStatusView = (props: { onCombat: () => void; onBreach: () => void; onOperations?: () => void; onSecurity?: () => void }) => {
  const { act, data } = useBackend<NetrunData>(['combat', 'entity', 'locked', 'breach', 'operations', 'security']);
  const feedback = useNetrunFeedback();
  const incoming = !!data.combat?.incoming?.length;
  const turn = data.combat?.turn;
  const travel = data.entity?.travel;
  const latestOperation = data.operations?.[data.operations.length - 1];
  const operation = feedback
    ? data.operations?.find((entry) => entry.nonce === feedback.nonce)
    : latestOperation;
  const operationState = operation ? OPERATION_PHASES[operation.phase] : null;
  return (
    <div className="netrun-session-status" data-net-layout="status" style={{ display: 'flex', alignItems: 'center', gap: '6px',
      flex: '0 0 32px', height: '32px', minWidth: 0, overflow: 'hidden' }}>
      <div style={{ flex: '1 1 auto', minWidth: 0, height: '100%', display: 'flex', alignItems: 'center' }}>
        {incoming ? <IncomingAttacks compact onCombat={props.onCombat} /> : turn ? (
          <button type="button" className="netrun-session-combat" data-own-turn={turn.your_turn}
            title="Открыть очередь боя и программы" onClick={props.onCombat}>
            <Icon name={turn.your_turn ? 'bolt' : 'crosshairs'} />
            <span>{turn.participating === false ? `Бой в узле · ход ${turn.actor_name}`
              : turn.your_turn ? `Ваш ход · ${turn.ap}/${turn.max_ap} ОД` : `Ожидание хода · ${turn.actor_name}`}
            </span>
            <small>Открыть бой</small>
          </button>
        ) : (
          <>
            <Box role="status" aria-live="polite" data-net-feedback={feedback?.phase}
              color={data.locked > 0 ? THEME.bad : operationState?.color || (feedback?.phase === 'delayed' ? THEME.warn : THEME.muted)} fontSize="11px"
              style={{ flex: '1 1 auto', minWidth: 0, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
              {data.locked > 0 ? `Сеанс заблокирован · осталось ${data.locked} с`
                : operation && (feedback || operationActive(operation)) ? `${operationState?.label}: ${operation.label}${operation.reason ? ` · ${operation.reason}` : ''}`
                  : feedback ? `${feedback.phase === 'received' ? 'Сервер ответил' : feedback.phase === 'delayed' ? 'Ответ задерживается' : 'Отправлен запрос'}: ${feedback.label}`
                  : data.breach ? `${data.breach.target} · взлом продолжается · ${data.breach.time_left} с`
                  : travel ? `Автопроход к ${travel.target} · осталось переходов: ${travel.remaining}`
                    : operation ? `${operationState?.label}: ${operation.label}${operation.reason ? ` · ${operation.reason}` : ''}`
                    : 'Выберите узел на карте и откройте управление. В терминале доступна команда help.'}
            </Box>
            {!!data.breach && <Button compact icon="key" content="К взлому" onClick={props.onBreach} />}
          </>
        )}
      </div>
      {turn?.participating === false && <Button compact icon="user-plus" content="Вступить в бой"
        disabled={!turn.can_join || data.locked > 0}
        onClick={() => act('combat_join', turn.join_id || turn.id ? { turn_id: turn.join_id || turn.id } : {})} />}
      {!!travel && <Button compact icon="stop" content={incoming ? 'Стоп' : 'Остановить маршрут'}
        aria-label="Остановить автопроход" tooltip={`Остановить автопроход к ${travel.target}`}
        onClick={() => act('travel_cancel')} />}
      {!!props.onOperations && <Button compact role="button" icon="list-check" aria-label={`Операции${data.operations?.some(operationActive) ? ` (${data.operations.filter(operationActive).length})` : ''}`}
        content={<span className="netrun-session-status__label">{`Операции${data.operations?.some(operationActive) ? ` (${data.operations.filter(operationActive).length})` : ''}`}</span>}
        onClick={props.onOperations} />}
      {!!props.onSecurity && !!data.security?.entries?.length && <Button compact role="button" icon="shield-halved"
        aria-label={`Угрозы (${data.security.entries.length})`}
        content={<span className="netrun-session-status__label">{`Угрозы (${data.security.entries.length})`}</span>} color="caution" onClick={props.onSecurity} />}
    </div>
  );
};

export const SessionStatus = memo(SessionStatusView);

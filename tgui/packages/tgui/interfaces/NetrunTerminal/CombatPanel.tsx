import './combat.scss';

import { CSSProperties, memo, useEffect, useRef, useState } from 'react';

import { Box, Button, Icon } from '../../components';
import { factionColor } from './actorTaxonomy';
import { ActionTooltip } from './CommandTooltip';
import { EntityAvatar } from './EntityAvatar';
import { BlackIceWarning, BotAvatar, botKindLabel, factionLabel, IceAvatar, iceKindLabel } from './EntityContacts';
import {
  CombatState,
  CombatTarget,
  CombatTurn,
  FORTRESS_MODULE_ICONS,
  FORTRESS_MODULE_NAMES,
  IncomingProgram,
  NetrunData,
  THEME,
} from './types';
import { useNetrunBackend as useBackend } from './useNetrunBackend';

const ROLE_COLORS: Record<string, string> = {
  attack: THEME.bad,
  stun: THEME.warn,
  shield: THEME.accent,
  repair: THEME.good,
  purge: THEME.warn,
};

/** Slim gauge shared by integrity, memory and fortress slots. Integrity is green when
 * full; usage warns as it fills. A zero maximum with content reads as full. */
export const Meter = (props: {
  value: number;
  max: number;
  label: string;
  tone?: 'integrity' | 'usage';
  color?: string;
  height?: number;
  style?: CSSProperties;
}) => {
  const { value, max, tone = 'integrity', height = 6 } = props;
  const ratio = max > 0 ? Math.max(0, Math.min(1, value / max)) : value > 0 ? 1 : 0;
  const color = props.color || (tone === 'usage'
    ? ratio >= 0.95 ? THEME.bad : ratio >= 0.75 ? THEME.warn : THEME.accent
    : ratio > 0.5 ? THEME.good : ratio > 0.25 ? THEME.warn : THEME.bad);
  return (
    <div role="meter" aria-label={props.label} aria-valuemin={0} aria-valuemax={Math.max(0, max)}
      aria-valuenow={value} aria-valuetext={`${value}/${max}`} title={`${props.label}: ${value}/${max}`}
      style={{ height: `${height}px`, background: THEME.line, borderRadius: `${height / 2}px`, overflow: 'hidden', ...props.style }}>
      <div style={{ height: '100%', width: `${ratio * 100}%`, background: color, transition: 'width 0.3s' }} />
    </div>
  );
};

export const IntegrityBar = (props: { cur: number; max: number; label?: string }) => (
  <Meter value={props.cur} max={props.max} label={props.label || 'Целостность'} style={{ marginTop: '0.5rem' }} />
);

/** Bots and fortress modules carry their archetype and allegiance on the card. */
const TargetIcon = ({ target }: { target: CombatTarget }) => {
  switch (target.kind) {
    case 'entity':
      return <EntityAvatar avatar={target.persona?.avatar} accent={target.persona?.accent} size={30} />;
    case 'bot':
      return <BotAvatar kind={target.bot_kind} faction={target.faction} factionColor={target.faction_color} size={30} />;
    case 'ice':
      return <IceAvatar kind={target.ice_kind} size={30} />;
    case 'fortress':
      return (<Icon name={FORTRESS_MODULE_ICONS[target.module ?? ''] || 'chess-rook'} mr={1}
        color={factionColor(target.faction, target.faction_color)} />);
    default:
      return <Icon name="skull" mr={1} />;
  }
};

const targetRole = (target: CombatTarget) => {
  if (target.kind === 'ice' && target.ice_kind) { return iceKindLabel(target.ice_kind); }
  if (target.kind === 'bot') {
    return [botKindLabel(target.bot_kind), target.faction_name || factionLabel('bot', target.faction)].filter(Boolean).join(' · ');
  }
  if (target.kind === 'fortress') {
    return [FORTRESS_MODULE_NAMES[target.module ?? ''] || 'Модуль крепости', target.faction_name || factionLabel('fortress', target.faction)]
      .filter(Boolean).join(' · ');
  }
  return null;
};

const TargetCard = (props: {
  target: CombatTarget;
  selected: boolean;
  localNode: string | null;
  selectionLocked?: boolean;
  onSelect: (ref: string) => void;
}) => {
  const { target: t, selected, localNode, onSelect, selectionLocked } = props;
  const role = targetRole(t);
  // Outer works of a neighbouring fortress are engaged across the link.
  const siege = t.kind === 'fortress' && !!t.node && !!localNode && t.node !== localNode;
  return (
    <Box
      className="netrun-combat-target"
      data-net-target={t.kind}
      mb={0.5}
      p={1}
      onClick={() => !selectionLocked && !t.unavailable_reason && onSelect(t.ref)}
      style={{
        cursor: selectionLocked || t.unavailable_reason ? 'default' : 'pointer',
        background: selected ? THEME.line : THEME.panel,
        border: `1px solid ${selected ? THEME.accent : t.hostile ? THEME.bad : THEME.line}`,
        borderRadius: '8px',
      }}
    >
      <Box color={t.hostile ? THEME.bad : THEME.text}>
        <TargetIcon target={t} />
        {t.name}
        {t.stunned ? <Box inline ml={1} color={THEME.warn}>оглушён</Box> : null}
        {t.shielded ? <Box inline ml={1} color={THEME.accent}>щит</Box> : null}
        {siege ? <Box inline ml={1} color={THEME.warn}>осада</Box> : null}
        {selected ? <Box inline ml={1} color={THEME.accent}>● цель</Box> : null}
      </Box>
      {!!role && <Box fontSize="11px" color={factionColor(t.faction, t.faction_color)}>{role}</Box>}
      {t.kind === 'ice' && t.ice_kind === 'black' && <BlackIceWarning />}
      {siege && (
        <Box fontSize="11px" color={THEME.muted}>
          Укрепления соседнего узла: удар идёт через канал осады.
        </Box>
      )}
      {!!t.persona?.tagline && <Box className="netrun-contact-tagline">{t.persona.tagline}</Box>}
      {!!t.node && <Box color={THEME.muted} fontSize="10px">{t.node_name} {t.node}</Box>}
      {!!t.unavailable_reason && <Box color={THEME.warn} fontSize="11px">{t.unavailable_reason}</Box>}
      <IntegrityBar cur={t.integrity} max={t.max_integrity} label={`Целостность ${t.name}`} />
      <Box fontSize="10px" color={THEME.muted}>
        {t.integrity}/{t.max_integrity}
      </Box>
      <Box className="netrun-target-cast" bold color={THEME.bad} title={t.casting ? `Готовит ${t.casting.name}: ${t.casting.remaining} с` : undefined}>
        {t.casting ? `Готовит ${t.casting.name}: ${t.casting.remaining} с` : '\u00a0'}
      </Box>
      {t.programs?.map((p) => {
        const turnCooldown = typeof p.ready_turns === 'number';
        const remaining = turnCooldown ? p.ready_turns! : p.ready_in;
        const cooldown = typeof p.cooldown_turns === 'number' ? `${p.cooldown_turns} ход.` : `${p.cooldown} с`;
        return (<Box key={p.name} className="netrun-enemy-program" fontSize="11px" color={remaining > 0 ? THEME.muted : THEME.warn}
          title={`${p.desc} · сила ${p.power} · подготовка ${p.windup} с · перезарядка ${cooldown}${typeof p.ap_cost === 'number' ? ` · стоимость ${p.ap_cost} ОД` : ''}`}>
          {p.name}: {remaining > 0 ? `перезарядка ${remaining} ${turnCooldown ? 'ход.' : 'с'}` : 'готова'}
          {typeof p.ap_cost === 'number' && ` · ${p.ap_cost} ОД`}
                </Box>);
      })}
    </Box>
  );
};

const incomingEffect = (attack: IncomingProgram, turnBased = false) => {
  switch (attack.role) {
    case 'trace': return `+${attack.power}% трассировки`;
    case 'stun': return turnBased
      ? `пропуск ${attack.stun_turns ?? 1} ${(attack.stun_turns ?? 1) === 1 ? 'хода' : 'ходов'}`
      : `${attack.power / 10} с оглушения`;
    case 'attack': return `${attack.power} урона до щита`;
    default: return `сила ${attack.power}`;
  }
};

const incomingAdvice = (role: string, compact = false, turnBased = false) => {
  if (turnBased) {
    switch (role) {
      case 'trace': return compact
        ? 'Прервите взлом. Подавление ICE доступно в свой ход.'
        : 'Прервите взлом, чтобы сорвать трассировку; подавление ICE доступно в свой ход.';
      case 'stun': return compact
        ? 'Пропуск хода от оглушения. Подавление ICE доступно в свой ход.'
        : 'Оглушение заставит пропустить ход. Подавление ICE подготовьте в свой ход.';
      case 'attack': return compact
        ? 'Щит и подавление подготовьте в свой ход. Отступление: 1 ОД.'
        : 'Удар готовится в ход противника. Щит подготовьте в свой ход; отступление стоит 1 ОД.';
    }
  }
  switch (role) {
    case 'trace': return compact
      ? 'Прервите взлом или оглушите ICE.'
      : 'Прервите взлом или оглушите ICE, чтобы сорвать трассировку. Щит не скрывает трассировку.';
    case 'stun': return compact
      ? 'Оглушите ICE или выйдите из узла.'
      : 'Оглушите ICE или выйдите из узла, чтобы сорвать оглушение. Щит не защищает от оглушения.';
    case 'attack': return compact
      ? 'Включите щит, оглушите ICE или выйдите из узла.'
      : 'Щит снижает урон. Оглушите ICE или выйдите из узла, чтобы сорвать атаку.';
    default: return 'Проверьте программу противника в боевой панели.';
  }
};

const incomingSummary = (attack: IncomingProgram, turnBased = false) =>
  `${attack.source} готовит ${attack.name} · ${incomingEffect(attack, turnBased)} · через ${attack.remaining} с`;

const blockedCombatActions = (combat: CombatState, locked: number) => [
  combat.turn?.participating === false ? 'Вы наблюдаете бой. Вступите, чтобы занять место в очереди.'
    : combat.turn && !combat.turn.your_turn ? 'Сейчас ход другого участника.' : null,
  combat.self?.stunned ? 'Вы оглушены: дождитесь окончания оглушения.' : null,
  locked > 0 ? `Терминал заблокирован: ещё ${locked} с.` : null,
  !combat.turn && (combat.action_ready_in ?? 0) > 0 ? `Общая пауза запуска: ещё ${combat.action_ready_in} с.` : null,
].filter((reason): reason is string => !!reason);

/** One local display clock per active encounter. Expiry never polls or sends an action. */
const turnKey = (turn: CombatTurn) => turn.id || `${turn.round}:${turn.actor_ref}`;

const TurnHud = ({ turn, active, joinBlocked, pass, join, onExpired }: {
  turn: CombatTurn; active: boolean; joinBlocked: boolean; pass: () => void; join: () => void; onExpired: (key: string) => void;
}) => {
  const key = turnKey(turn);
  const clock = useRef({ key: '', value: turn, deadline: 0, duration: 1 });
  const received = performance.now();
  if (clock.current.key !== key) {
    clock.current = { key, value: turn, deadline: received + Math.max(0, turn.remaining) * 1000, duration: turn.decision_seconds || Math.max(1, turn.remaining) };
  } else if (clock.current.value !== turn) {
    clock.current.value = turn;
    clock.current.deadline = Math.min(clock.current.deadline, received + Math.max(0, turn.remaining) * 1000);
  }
  const [now, setNow] = useState(received);
  const deadline = clock.current.deadline;
  useEffect(() => {
    if (!active) { return; }
    setNow(performance.now());
    if (performance.now() >= deadline) { return; }
    const interval = window.setInterval(() => {
      const value = performance.now(); setNow(value);
      if (value >= deadline) { window.clearInterval(interval); }
    }, 200);
    return () => window.clearInterval(interval);
  }, [active, key, deadline]);
  const remaining = Math.max(0, (deadline - now) / 1000);
  const expired = remaining <= 0;
  useEffect(() => {
    if (active && expired) { onExpired(key); }
  }, [active, expired, key, onExpired]);
  return (
    <section className="netrun-turn-hud" aria-label="Порядок боя" data-net-turn={key}>
      <div className="netrun-turn-hud__actor">
        <strong style={{ color: turn.your_turn ? THEME.good : THEME.warn }}>{turn.your_turn ? 'Ваш ход' : `Ход: ${turn.actor_name}`}</strong>
        <small>Раунд {turn.round}</small>
      </div>
      <div className="netrun-turn-hud__ap">
        <strong>ОД {turn.ap}/{turn.max_ap}</strong>
        <Meter value={turn.ap} max={turn.max_ap} label="Очки действия текущего хода" color={turn.your_turn ? THEME.accent : THEME.warn} />
      </div>
      <div className="netrun-turn-hud__timer">
        <strong aria-label={`Осталось ${Math.ceil(remaining)} с`}>{Math.ceil(remaining)} с</strong>
        <Meter value={remaining} max={clock.current.duration} label="Время на решение" color={remaining <= 3 ? THEME.bad : THEME.accent} />
      </div>
      {turn.participating === false
        ? <Button compact icon="user-plus" content="Вступить в бой" disabled={!turn.can_join || joinBlocked} onClick={join} />
        : <Button compact icon="forward-step" content="Завершить ход" disabled={!turn.your_turn || !turn.can_pass || expired} onClick={pass} />}
      {!!turn.participants?.length && (
        <div className="netrun-turn-order" aria-label="Участники боя">
          {turn.participants.map((participant) => (
            <span key={participant.ref} aria-current={participant.current ? 'step' : undefined}>
              {participant.current && <Icon name="caret-right" />}{participant.name}
            </span>
          ))}
        </div>
      )}
    </section>
  );
};

/** Shared warning for every workspace, including a running breach puzzle. */
const IncomingAttacksView = (props: { onCombat: () => void; compact?: boolean }) => {
  const { act, data } = useBackend<NetrunData>(['combat', 'breach']);
  const incoming = data.combat?.incoming ?? [];
  const turnBased = !!data.combat?.turn;
  if (!incoming.length) { return null; }
  if (props.compact) {
    const next = incoming.reduce((soonest, attack) => attack.remaining < soonest.remaining ? attack : soonest);
    return (
      <Box role="alert" style={{ flex: '1 1 auto', minWidth: 0, height: '100%', boxSizing: 'border-box', padding: '1px 5px',
        display: 'flex', alignItems: 'center', gap: '6px', border: `1px solid ${THEME.bad}`, background: THEME.bg }}>
        <Box title={incoming.map((attack) => `${incomingSummary(attack, turnBased)}\n${incomingAdvice(attack.role, false, turnBased)}`).join('\n')}
          style={{ flex: '1 1 auto', minWidth: 0, overflow: 'hidden', fontSize: '11px', lineHeight: '13px' }}>
          <Box color={THEME.bad} bold style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
            {incomingEffect(next, turnBased)} · через {next.remaining} с · {next.source} готовит {next.name}{incoming.length > 1 ? ` · угроз: ${incoming.length}` : ''}
          </Box>
          <Box style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{incomingAdvice(next.role, true, turnBased)}</Box>
        </Box>
        <Button compact icon="crosshairs" content="Открыть бой" style={{ flexShrink: 0 }} onClick={props.onCombat} />
        {!!data.breach && <Button compact icon="stop" content="Прервать взлом" style={{ flexShrink: 0 }} onClick={() => act('breach_abort')} />}
      </Box>
    );
  }
  return (
    <Box p={1} mb={0.5} role="alert" style={{ border: `2px solid ${THEME.bad}`, background: THEME.bg }}>
      {incoming.map((attack, index) => (
        <Box key={`${attack.source_ref ?? attack.source}-${attack.name}-${index}`} color={THEME.bad} bold>
          {incomingSummary(attack, turnBased)}
        </Box>
      ))}
      {Array.from(new Set(incoming.map((attack) => attack.role))).map((role) => (
        <Box key={role} fontSize="11px">{incomingAdvice(role, false, turnBased)}</Box>
      ))}
      <Button icon="crosshairs" content="Открыть бой" onClick={props.onCombat} />
      {!!data.breach && <Button icon="stop" content="Прервать взлом" onClick={() => act('breach_abort')} />}
    </Box>
  );
};

const CombatPanelView = () => {
  const { act, data } = useBackend<NetrunData>(['workspace_view', 'combat', 'locked']);
  const active = !data.workspace_view || data.workspace_view === 'combat';
  const confirmed = useRef<CombatState | null>(null);
  if (active) { confirmed.current = data.combat || null; }
  const combat = active ? data.combat : confirmed.current;
  const [target, setTarget] = useState<string | null>(null);
  const [expiredDecision, setExpiredDecision] = useState<string | null>(null);
  const pursuit = combat?.pursuit;

  // Preserve a usable selection and replace removed or disconnected targets in one update.
  // Fortress modules are never picked automatically: a siege, like an attack on your own
  // or the station's works, starts with a deliberate selection.
  const targets = combat?.targets ?? [];
  useEffect(() => {
    if (pursuit?.target_ref) {
      setTarget(pursuit.target_ref);
      return;
    }
    const usable = targets.find((t) => t.ref === target && !t.unavailable_reason)
      ?? targets.find((t) => t.hostile && t.kind !== 'fortress' && !t.unavailable_reason);
    setTarget(usable?.ref ?? null);
  }, [targets, target, pursuit?.target_ref]);

  if (!combat) {
    return (
      <Box color={THEME.muted} p={1} style={{ fontFamily: 'monospace' }}>
        Нет боевого контакта. Встаньте в узел с целью (или выберите доступный узел с процессом).
      </Box>
    );
  }

  const programs = combat.programs ?? [];
  const selectedRef = pursuit?.target_ref || target;
  const selectedTarget = targets.find((t) => t.ref === selectedRef);
  const pursuitOutsideNode = !!pursuit && (!selectedTarget || !combat.node || selectedTarget.node !== combat.node);
  const canPursue = combat.pursuit_available && selectedTarget
    && (selectedTarget.kind === 'entity' || selectedTarget.kind === 'bot');
  const turn = combat.turn;
  const actionBlockReasons = blockedCombatActions(combat, data.locked);
  if (turn && expiredDecision === turnKey(turn)) {
    actionBlockReasons.unshift('Время на решение истекло. Ожидается следующий ход.');
  }
  const turnParams = turn?.id ? { turn_id: turn.id } : {};
  return (
    <Box className="netrun-combat-panel" style={{ background: THEME.bg, border: `1px solid ${THEME.line}`, height: '100%', width: '100%', overflowY: 'auto', boxSizing: 'border-box', fontFamily: 'monospace' }} p={1}>
      <div className="netrun-combat-content">
      {!!turn && <TurnHud turn={turn} active={active} joinBlocked={data.locked > 0} pass={() => act('combat_pass', turnParams)}
        join={() => act('combat_join', turn.join_id || turn.id ? { turn_id: turn.join_id || turn.id } : {})} onExpired={setExpiredDecision} />}
      <Box color={THEME.muted} fontSize="12px" mb={1}>
        <Icon name="crosshairs" mr={1} />
        {combat.node ? <>Узел боя: {combat.node_name} {combat.node}</> : 'Ответный бой'}
      </Box>
      {!!combat.self && (
        <Box mb={1} p={1} className="netrun-self-panel" style={{ background: THEME.panel, border: `1px solid ${THEME.line}`, borderRadius: '8px' }}>
          <Box color={THEME.accent}>
            Вы {combat.self.stunned ? ' · ОГЛУШЕНЫ' : ''}{combat.self.shielded ? ' · ЩИТ АКТИВЕН' : ''}
          </Box>
          <IntegrityBar cur={combat.self.integrity} max={combat.self.max_integrity} />
          <Box fontSize="10px" color={THEME.muted}>
            Целостность {combat.self.integrity}/{combat.self.max_integrity}
          </Box>
        </Box>
      )}

      <div className="netrun-combat-workbench">
      <section className="netrun-combat-actions" aria-label="Боевые программы">
      <Box color={THEME.muted} fontSize="12px" mb={0.5}>Боевые программы</Box>
      <Box className="netrun-combat-selected-target" title={selectedTarget?.name || pursuit?.name || undefined}>
        Цель: {selectedTarget?.name || pursuit?.name || 'не выбрана'}
      </Box>
      <div className="netrun-combat-action-status">
        {actionBlockReasons.length ? <Box role="status" color={THEME.warn} fontSize="11px">
          {actionBlockReasons.map((reason) => <Box key={reason}>{reason}</Box>)}
                                     </Box> : <Box color={THEME.muted} fontSize="11px">
          {turn ? 'Выберите программу или завершите ход. ОД расходуются на запуск.' : 'Выберите программу. Для атаки используется указанная цель.'}
                                              </Box>}
      </div>
      {programs.length === 0 ? (
        <Box color={THEME.muted}>Нет боевых программ. Запишите их на шард или добудьте из обломков ICE.</Box>
      ) : (
        <div className="netrun-combat-programs">
          {programs.map((p) => {
            const onCd = turn ? (p.ready_turns ?? 0) > 0 : p.ready_in > 0;
            const cost = p.ap_cost ?? 1;
            const cooldown = turn ? `Ещё ${p.ready_turns || 0} ход.` : `Ещё ${p.ready_in} с`;
            const nominalCooldown = turn ? p.cooldown_turns === undefined ? 'Готова' : `${p.cooldown_turns} ход.` : `${p.cooldown} с`;
            const needTarget = p.needs_target && (!selectedTarget || !!selectedTarget.unavailable_reason || pursuitOutsideNode);
            const blockReasons = [
              ...actionBlockReasons,
              p.unavailable_reason,
              onCd ? turn ? `Перезарядка: ещё ${p.ready_turns} ход.` : `Перезарядка: ещё ${p.ready_in} с.` : null,
              turn && turn.ap < cost ? `Нужно ${cost} ОД, осталось ${turn.ap}.` : null,
              needTarget ? pursuitOutsideNode ? 'Цель вне текущего узла: дождитесь встречи.' : 'Сначала выберите доступную цель.' : null,
            ].filter((reason): reason is string => !!reason);
            return (
              <Button
                key={p.uid}
                data-net-program={p.uid}
                icon={p.icon}
                disabled={blockReasons.length > 0}
                style={{ background: THEME.panel, border: `1px solid ${ROLE_COLORS[p.role] || THEME.line}`, borderRadius: '7px' }}
                tooltip={<ActionTooltip name={p.name} id={p.id} icon={p.icon} description={p.desc}
                  facts={[
                    { label: 'Сила', value: String(p.power) },
                    { label: 'Стоимость', value: `${cost} ОД` },
                    { label: 'Перезарядка', value: onCd ? cooldown : nominalCooldown, warning: onCd },
                    ...(p.shield_turns ? [{ label: 'Длительность щита', value: `${p.shield_turns} ход.` }] : []),
                    ...(p.stun_turns ? [{ label: 'Оглушение', value: `${p.stun_turns} ход.` }] : []),
                    { label: 'Файл', value: p.consumable ? 'Одноразовый' : 'Многоразовый' },
                    { label: 'Цель', value: p.needs_target ? 'Процесс в одном узле' : 'Собственная сущность' },
                  ]}
                  notices={blockReasons.map((text) => ({ text }))} />}
                onClick={() => act('program_use', { uid: p.uid, target: p.needs_target ? selectedRef : null, ...turnParams })}
              >
                <Box style={{ minWidth: 0 }}>
                  <div className="netrun-program-title"><span>{p.name.replace(/\.(exe|card)$/, '')}</span>{!!turn && <small>{cost} ОД</small>}</div>
                  <Box className="netrun-program-status" fontSize="10px" color={blockReasons.length ? THEME.warn : THEME.good}>
                    {blockReasons[0] || 'Готова'}
                  </Box>
                </Box>
              </Button>
            );
          })}
        </div>
      )}
      </section>
      <section className="netrun-combat-contacts" aria-label="Цели и процессы">
      <Box color={THEME.muted} fontSize="12px" mb={1}>Цели и процессы</Box>
      {!!pursuit && <Box mb={1} p={1} data-net-pursuit role="status" style={{ border: `1px solid ${THEME.accent}`, borderRadius: '6px' }}>
        <Box bold color={THEME.accent}><Icon name="crosshairs" mr={0.5} />Захвачена цель: {pursuit.name}</Box>
        <Box fontSize="11px">{pursuit.status}</Box>
        {!!pursuit.node && <Box fontSize="10px" color={THEME.muted}>Узел цели: {pursuit.node}</Box>}
        {pursuitOutsideNode && <Box fontSize="11px" color={THEME.muted}>Цель вне текущего узла. Атакующие программы недоступны до встречи.</Box>}
        <Button mt={0.5} compact icon="stop" content="Остановить преследование" onClick={() => act('pursuit_stop')} />
                    </Box>}
      <div className="netrun-combat-targets">
        {targets.length === 0 ? <Box color={THEME.muted} mb={1}>Других процессов нет.</Box>
          : targets.map((t: CombatTarget) => (<TargetCard key={t.ref} target={t} selected={selectedRef === t.ref} localNode={combat.node}
            selectionLocked={!!pursuit} onSelect={setTarget} />))}
      </div>
      {!!canPursue && !pursuit && <Button compact icon="route" content="Преследовать"
        disabled={data.locked > 0 || !!combat.self?.stunned}
        tooltip="Захватить цель и идти за ней узел за узлом. Атаки запускаются вручную при встрече."
        onClick={() => act('pursue', { ref: selectedTarget.ref })} />}
      </section>
      </div>
      {!!combat.loot?.length && (
        <Box mt={1} p={0.5} style={{ border: `1px solid ${THEME.good}` }}>
          <Box bold color={THEME.good}>Добыча в узле</Box>
          {combat.loot.map((file) => (
            <Box key={file.uid}>
              {file.name} · {file.size} яч.
              <Button ml={1} icon="download" content="Забрать" disabled={combat.self?.stunned || data.locked > 0}
                onClick={() => act('recover_salvage', { uid: file.uid })} />
            </Box>
          ))}
        </Box>
      )}
      </div>
    </Box>
  );
};

export const IncomingAttacks = memo(IncomingAttacksView);

export const CombatPanel = memo(CombatPanelView);

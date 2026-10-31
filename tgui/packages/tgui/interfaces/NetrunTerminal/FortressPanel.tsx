import { useState } from 'react';

import { Box, Button, Icon } from '../../components';
import { Meter } from './CombatPanel';
import { commandClass, commandColor } from './CommandList';
import { CommandTooltip } from './CommandTooltip';
import { factionLabel } from './EntityContacts';
import {
  ACCESS_NAMES,
  FACTION_COLORS,
  FORTRESS_MODULE_ICONS,
  FORTRESS_MODULE_NAMES,
  FortressDetails,
  FortressModule,
  NetCommand,
  THEME,
} from './types';

const BUILD_PREFIX = 'fort_build@';
const DISMANTLE_PREFIX = 'fort_dismantle@';

const MODULE_STATUS: Record<FortressModule['status'], { label: string; color: string }> = {
  online: { label: 'в строю', color: THEME.good },
  building: { label: 'строится', color: THEME.accent },
  destroyed: { label: 'разрушен', color: THEME.bad },
  offline: { label: 'отключён', color: THEME.muted },
};

/** Module kind carried by `fort_build@<kind>` / `fort_dismantle@<kind>`. */
const commandKind = (id: string) => id.slice(id.indexOf('@') + 1);

const moduleName = (kind: string, fallback?: string) => FORTRESS_MODULE_NAMES[kind] || fallback || kind;

const moduleStatus = (module: FortressModule) => {
  const status = module.jammed && module.status === 'online' ? { label: 'подавлен', color: THEME.warn } : MODULE_STATUS[module.status] || MODULE_STATUS.offline;
  // Construction, or the re-arm of a spent module, counts down on the server.
  const remaining = Math.ceil(Number(module.remaining) || 0);
  return { ...status, text: remaining > 0 ? `${status.label} · ${remaining} с` : status.label };
};

/** One reason shared by every disabled request reads better than repeating it per button. */
const sharedReason = (commands: NetCommand[]) => {
  if (!commands.length || commands.some((command) => command.allowed)) { return null; }
  const reasons = new Set(commands.map((command) => command.unavailable_reason || 'Сейчас действие недоступно.'));
  return reasons.size === 1 ? [...reasons][0] : null;
};

const FactionBadge = (props: { faction: string }) => {
  const color = FACTION_COLORS[props.faction] || THEME.muted;
  return (
    <Box inline fontSize="10px" px={0.5} style={{ flex: '0 0 auto', color, border: `1px solid ${color}`,
      borderRadius: '8px', textTransform: 'uppercase', letterSpacing: '.05em' }}>
      {factionLabel('fortress', props.faction) || props.faction}
    </Box>
  );
};

const ModuleRow = (props: { module: FortressModule; commands: NetCommand[]; disabled?: boolean; onCommand: (id: string) => void }) => {
  const { module } = props;
  const status = moduleStatus(module);
  const name = moduleName(module.kind, module.name);
  const inactive = module.status === 'destroyed' || module.status === 'offline';
  return (
    <Box mb={0.5} data-net-fortress-module={module.kind} title={module.desc || undefined}
      style={{ opacity: inactive ? 0.75 : 1 }}>
      <Box style={{ display: 'flex', alignItems: 'baseline', gap: '6px', minWidth: 0 }}>
        <Icon name={FORTRESS_MODULE_ICONS[module.kind] || 'cube'} color={status.color}
          style={{ width: '14px', textAlign: 'center', flex: '0 0 auto' }} />
        <Box style={{ flex: '1 1 auto', minWidth: 0, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
          {name}
        </Box>
        <Box fontSize="11px" color={status.color} style={{ flex: '0 0 auto' }}>{status.text}</Box>
      </Box>
      <Box style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
        <Meter value={module.integrity} max={module.max_integrity} label={`Прочность ${name}`} height={4}
          style={{ flex: '1 1 auto' }} />
        <Box fontSize="10px" color={THEME.muted} style={{ flex: '0 0 auto', fontFamily: 'monospace' }}>
          {module.integrity}/{module.max_integrity}
        </Box>
      </Box>
      {[module.repair_command, module.dismantle_command].filter(Boolean).map((id) => {
        const request = props.commands.find((entry) => entry.id === id);
        if (!request) { return null; }
        const repair = id === module.repair_command;
        return (<Button key={id} compact icon={repair ? 'screwdriver-wrench' : 'hammer'} content={repair ? 'Починить' : 'Разобрать'}
          className={commandClass(request)} color={commandColor(request)} disabled={props.disabled || !request.allowed}
          tooltip={<CommandTooltip command={request} />} onClick={() => props.onCommand(id)} />);
      })}
    </Box>
  );
};

/** Module requests in the same uniform grid, risk styling and tooltip as the node's command list. */
const ModuleCommandGrid = (props: {
  label: string;
  commands: NetCommand[];
  disabled?: boolean;
  onCommand: (id: string) => void;
}) => {
  const reason = sharedReason(props.commands);
  return (
    <div role="group" aria-label={props.label}>
      <Box className="netrun-command-grid"
        style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(112px, 1fr))', gap: '4px' }}>
        {props.commands.map((command) => {
          const kind = commandKind(command.id);
          return (
            <Button
              key={command.id}
              fluid
              ellipsis
              className={commandClass(command)}
              color={commandColor(command)}
              icon={FORTRESS_MODULE_ICONS[kind] || command.icon}
              content={moduleName(kind)}
              disabled={props.disabled || !command.allowed}
              style={{ margin: 0, textAlign: 'left' }}
              tooltip={<CommandTooltip command={command} />}
              onClick={() => props.onCommand(command.id)}
            />
          );
        })}
      </Box>
      {!!reason && <Box fontSize="11px" color={THEME.muted}>{reason}</Box>}
    </div>
  );
};

/** Requests of the 'fortress' group: a compact build menu, repair and a dismantle menu.
 * Each one is the node's own request (`act('command', { id })` from the node card). */
export const FortressActions = (props: {
  commands: NetCommand[];
  onCommand: (id: string) => void;
  disabled?: boolean;
}) => {
  const { commands, onCommand, disabled } = props;
  const [menu, setMenu] = useState<'build' | 'dismantle' | null>(null);
  const build = commands.filter((command) => command.id.startsWith(BUILD_PREFIX));
  const dismantle = commands.filter((command) => command.id.startsWith(DISMANTLE_PREFIX));
  const other = commands.filter((command) => !build.includes(command) && !dismantle.includes(command));
  if (!commands.length) { return null; }
  const toggle = (next: 'build' | 'dismantle') => setMenu(menu === next ? null : next);
  const shownMenu = menu === 'build' && build.length ? 'build' : menu === 'dismantle' && dismantle.length ? 'dismantle' : null;
  return (
    <Box mt={1}>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: '4px', alignItems: 'center' }}>
        {!!build.length && (
          <Button compact icon="trowel-bricks" selected={shownMenu === 'build'} aria-expanded={shownMenu === 'build'}
            tooltip="Нужны доступ ROOT и демон forge.exe. Каждый модуль занимает слоты крепости и строится не сразу."
            onClick={() => toggle('build')}>
            Построить
            <Icon name="caret-down" ml={0.5} rotation={shownMenu === 'build' ? 180 : 0} />
          </Button>
        )}
        {other.map((command) => (
          <Button
            key={command.id}
            compact
            className={commandClass(command)}
            color={commandColor(command)}
            icon={command.icon}
            content={command.name}
            disabled={disabled || !command.allowed}
            tooltip={<CommandTooltip command={command} />}
            onClick={() => onCommand(command.id)}
          />
        ))}
        {!!dismantle.length && (
          <Button compact icon="hammer" selected={shownMenu === 'dismantle'} aria-expanded={shownMenu === 'dismantle'}
            onClick={() => toggle('dismantle')}>
            Разобрать
            <Icon name="caret-down" ml={0.5} rotation={shownMenu === 'dismantle' ? 180 : 0} />
          </Button>
        )}
      </div>
      {shownMenu === 'build' && (
        <ModuleCommandGrid label="Постройка модулей" commands={build} disabled={disabled} onCommand={onCommand} />
      )}
      {shownMenu === 'dismantle' && (
        <ModuleCommandGrid label="Разбор модулей" commands={dismantle} disabled={disabled} onCommand={onCommand} />
      )}
    </Box>
  );
};

/** Fortress of the selected node: modules, slots and the 'fortress' request group. */
export const FortressPanel = (props: {
  fortress?: FortressDetails | null;
  commands: NetCommand[];
  /** Viewer's level on the node: without GUEST the works are not disclosed. */
  access: number;
  disabled?: boolean;
  onCommand: (id: string) => void;
}) => {
  const { fortress, commands, access, disabled, onCommand } = props;
  if (!fortress) {
    return (
      <Box mt={1} p={1} data-net-fortress="none"
        style={{ background: THEME.bg, border: `1px dashed ${THEME.line}`, borderRadius: '6px' }}>
        <Box bold><Icon name="chess-rook" mr={1} color={THEME.muted} />Крепость</Box>
        <Box color={THEME.muted} fontSize="11px">
          {access >= 1
            ? 'Укреплений нет. Модули строятся с доступом ROOT и демоном forge.exe.'
            : `Состояние укреплений скрыто: нужен доступ ${ACCESS_NAMES[1]}.`}
        </Box>
        <FortressActions commands={commands} disabled={disabled} onCommand={onCommand} />
      </Box>
    );
  }
  const color = FACTION_COLORS[fortress.faction] || THEME.line;
  const modules = fortress.modules ?? [];
  const moduleCommands = new Set(modules.flatMap((module) => [module.repair_command, module.dismantle_command]).filter(Boolean));
  const commonCommands = commands.filter((request) => !moduleCommands.has(request.id)
    && !(moduleCommands.size && request.id.startsWith(DISMANTLE_PREFIX)));
  return (
    <Box mt={1} p={1} data-net-fortress={fortress.faction}
      style={{ background: THEME.bg, border: `1px solid ${color}`, borderRadius: '6px' }}>
      <Box style={{ display: 'flex', alignItems: 'center', gap: '6px', minWidth: 0 }}>
        <Icon name="chess-rook" color={color} style={{ flex: '0 0 auto' }} />
        <Box bold style={{ flex: '1 1 auto', minWidth: 0, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
          {fortress.name}
        </Box>
        <FactionBadge faction={fortress.faction} />
      </Box>
      <Box color={THEME.muted} fontSize="11px">
        Владелец: {fortress.owner || '—'}{fortress.preset ? ` · шаблон ${fortress.preset}` : ''}
      </Box>
      <Box fontSize="11px" mt={0.5} style={{ display: 'flex', flexWrap: 'wrap', gap: '4px 12px' }}>
        <span>Защита узла: +{fortress.security_bonus || 0}</span>
        <span>Слоты: {fortress.slots_used}/{fortress.slots_max}</span>
      </Box>
      <Meter value={fortress.slots_used} max={fortress.slots_max} tone="usage" label="Слоты крепости" height={4}
        style={{ margin: '3px 0 6px' }} />
      {!!fortress.storage && <Box mb={1} data-net-fortress-storage>
        <Box fontSize="11px"><Icon name="vault" mr={0.5} />Хранилище: {fortress.storage.used}/{fortress.storage.capacity}
          {fortress.storage.vault_bonus > 0 ? ` · сейф +${fortress.storage.vault_bonus}` : ''}
        </Box>
        <Meter value={fortress.storage.used} max={fortress.storage.capacity} tone="usage" label="Память крепости" height={4} />
        <Box color={THEME.muted} fontSize="10px">Доступ к файлам: {ACCESS_NAMES[fortress.storage.required_access] || 'ROOT'}.</Box>
                             </Box>}
      {modules.length ? (
        modules.map((module) => <ModuleRow key={module.id || module.ref} module={module} commands={commands} disabled={disabled} onCommand={onCommand} />)
      ) : (
        <Box color={THEME.muted} fontSize="11px">Модулей нет.</Box>
      )}
      {!fortress.can_manage && !!fortress.manage_reason && (
        <Box mt={0.5} fontSize="11px" color={THEME.warn}>
          <Icon name="circle-info" mr={0.5} />{fortress.manage_reason}
        </Box>
      )}
      <FortressActions commands={commonCommands} disabled={disabled} onCommand={onCommand} />
    </Box>
  );
};

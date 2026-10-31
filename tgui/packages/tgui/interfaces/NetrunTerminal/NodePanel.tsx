import { memo, useRef } from 'react';

import { Box, Button, Icon, LabeledList, Section } from '../../components';
import { AutoBreachButton } from './AutoBreachButton';
import { Meter } from './CombatPanel';
import { CommandList } from './CommandList';
import { EntityContacts } from './EntityContacts';
import { fileSizeLabel } from './filePermissions';
import { fileIcon } from './filePresentation';
import { FortressPanel } from './FortressPanel';
import { NodeInteractions } from './NodeInteractions';
import { NodeMovement } from './NodeMovement';
import { PacketJournal } from './PacketJournal';
import { RemoteFileActions } from './RemoteFileActions';
import {
  ACCESS_COLORS,
  ACCESS_NAMES,
  NetFile,
  NetrunData,
  NODE_ICONS,
  SelectedNode,
  THEME,
} from './types';
import { useNetrunBackend as useBackend } from './useNetrunBackend';

const NodePanelView = () => {
  const { act, data } = useBackend<NetrunData>(['workspace_view', 'map', 'selected', 'selected_network', 'networks', 'can_breach', 'breach', 'entity', 'waypoint', 'locked']);
  // A hidden workspace is serialized without selected-node details. Do not turn
  // the brief omission into a blank sidebar when the player returns to the map.
  const confirmed = useRef<Pick<NetrunData,
    'selected' | 'selected_network' | 'networks' | 'can_breach' | 'breach' | 'entity' | 'waypoint'> | null>(null);
  if (data.workspace_view === 'map' && data.map) {
    confirmed.current = {
      selected: data.selected, selected_network: data.selected_network,
      networks: data.networks, can_breach: data.can_breach, breach: data.breach,
      entity: data.entity, waypoint: data.waypoint,
    };
  }
  const pending = !data.map || (data.workspace_view !== undefined && data.workspace_view !== 'map');
  const display = pending && confirmed.current ? confirmed.current : data;
  const { selected, can_breach, breach, networks, selected_network } = display;
  if (!selected && selected_network) {
    const net = selected_network;
    return (
      <Section
        title={net.code}
        scrollable
        style={{ minHeight: '100%', overflowY: 'auto' }}
        buttons={<Icon name="network-wired" />}
      >
        <LabeledList>
          <LabeledList.Item label="Сеть">{net.name}</LabeledList.Item>
          <LabeledList.Item label="Защита">{net.security}</LabeledList.Item>
          <LabeledList.Item label="Доступ">
            <Box inline color={ACCESS_COLORS[net.access]} bold>
              {ACCESS_NAMES[net.access]}
            </Box>
            {!!net.has_key && <Icon name="key" ml={1} color={THEME.good} />}
          </LabeledList.Item>
        </LabeledList>
        {!!net.can_breach && (
          <Button
            mt={1}
            icon="key"
            color="caution"
            content="Подобрать доступ к сети"
            disabled={!!breach}
            onClick={() => act('breach', { kind: 'network', id: net.id })}
          />
        )}
        {!!net.can_breach && <AutoBreachButton kind="network" id={net.id} />}
        {net.access < 1 && !net.can_breach && (
          <Box mt={1} color={THEME.muted}>
            Нужен ключ сети или легальный доступ отдела.
          </Box>
        )}
        {net.log.length > 0 && (
          <Box
            mt={1}
            p={1}
            style={{
              background: THEME.bg,
              fontFamily: 'monospace',
              fontSize: '10px',
              color: THEME.muted,
            }}
          >
            {net.log.map((line, i) => (
              <Box key={i}>{line}</Box>
            ))}
          </Box>
        )}
      </Section>
    );
  }
  if (!selected) {
    return (
      <Section title="Сети" scrollable style={{ minHeight: '100%', overflowY: 'auto' }}>
        <Box color={THEME.muted} mb={1}>
          Выберите узел на карте или подберите доступ к сети.
        </Box>
        {networks
          .filter((net) => net.id !== 'web')
          .map((net) => (
            <Box
              key={net.id}
              p={1}
              mb={0.5}
              style={{
                background: THEME.bg,
                border: `1px solid ${net.reachable ? net.color : THEME.line}`,
                opacity: net.reachable ? 1 : 0.5,
              }}
            >
              <Box>
                <Box inline bold style={{ fontFamily: 'monospace', color: net.color }}>
                  {net.code}
                </Box>
                {!!net.has_key && <Icon name="key" ml={1} color={THEME.good} />}
                <Box inline ml={1} color={ACCESS_COLORS[net.access]}>
                  {ACCESS_NAMES[net.access]}
                </Box>
              </Box>
              <Box color={THEME.muted} fontSize="11px">
                {net.name} · защита {net.security} · узлов {net.nodes}
              </Box>
              <Box mt={0.5}>
                <Button
                  compact
                  icon="diagram-project"
                  content="Открыть"
                  disabled={!net.reachable}
                  onClick={() => act('select_network', { id: net.id })}
                />
                {!!net.can_breach && (
                  <Button
                    compact
                    icon="key"
                    color="caution"
                    content="Подобрать доступ"
                    disabled={!!breach}
                    onClick={() => act('breach', { kind: 'network', id: net.id })}
                  />
                )}
                {!!net.can_breach && <AutoBreachButton kind="network" id={net.id} disabled={!net.reachable} />}
              </Box>
            </Box>
          ))}
      </Section>
    );
  }
  return (
    <Section
      title={selected.name}
      scrollable
      style={{ minHeight: '100%', overflowY: 'auto' }}
      buttons={
        <Box inline>
          <Button
            icon="location-arrow"
            tooltip="Пеленг на узел — показать направление на карте"
            selected={display.waypoint?.address === selected.address}
            onClick={() => act('set_waypoint', { address: selected.address })}
          />
          <Button
            icon="window-maximize"
            content="Закрепить"
            tooltip="Открыть в закреплённых узлах"
            onClick={() => act('window_open', { address: selected.address })}
          />
          <Icon name={NODE_ICONS[selected.type] || 'circle'} ml={1} />
        </Box>
      }
    >
      <div className="netrun-node-detail">
      <LabeledList>
        <LabeledList.Item label="Адрес">
          <Box inline style={{ fontFamily: 'monospace' }}>
            {selected.address}
          </Box>{' '}
          · {selected.network}
        </LabeledList.Item>
        <LabeledList.Item label="Состояние">
          <Box inline color={selected.online ? THEME.good : THEME.bad}>
            {selected.online ? 'в сети' : 'не отвечает'}
          </Box>
          {' · защита '}
          {selected.security}
        </LabeledList.Item>
        <LabeledList.Item label="Доступ">
          <Box inline color={ACCESS_COLORS[selected.access]} bold>
            {ACCESS_NAMES[selected.access]}
          </Box>
          {selected.legit < selected.access && (
            <Box inline color={THEME.warn} ml={1}>
              (без авторизации)
            </Box>
          )}
        </LabeledList.Item>
      </LabeledList>
      {!!selected.manual_uid && (
        <Button mt={1} icon="book" content="Справка узла"
          disabled={pending || !!data.locked || !selected.online}
          onClick={() => act('read', { uid: selected.manual_uid })} />
      )}
      <NodeInteractions actions={selected.interactions} pending={pending} />
      {selected.access < 1 && (
        <Box mt={1} color={THEME.warn}>
          Узел закрыт. Подберите доступ к узлу или его сети.
        </Box>
      )}
      {!!selected.lan && (
        <Box mt={1} p={1} style={{ background: THEME.bg, border: `1px solid ${selected.lan.color}` }}>
          <Box>
            <Icon name="network-wired" mr={1} color={selected.lan.color} />
            <Box inline bold style={{ fontFamily: 'monospace', color: selected.lan.color }}>
              {selected.lan.code}
            </Box>
            {!!selected.lan.has_key && <Icon name="key" ml={1} color={THEME.good} />}
            <Box inline ml={1} color={ACCESS_COLORS[selected.lan.access]}>
              {ACCESS_NAMES[selected.lan.access]}
            </Box>
          </Box>
          <Box color={THEME.muted} fontSize="11px">
            ЛВС: {selected.lan.name} · защита {selected.lan.security}
          </Box>
          <Box mt={0.5}>
            <Button
              compact
              icon="diagram-project"
              content="Открыть ЛВС"
              onClick={() => act('select_network', { id: selected.lan!.id })}
            />
            {!!selected.lan.can_breach && (
              <Button
                compact
                icon="key"
                color="caution"
                content="Подобрать доступ к ЛВС"
                disabled={!!breach}
                onClick={() => act('breach', { kind: 'network', id: selected.lan!.id })}
              />
            )}
            {!!selected.lan.can_breach && <AutoBreachButton kind="network" id={selected.lan.id} />}
          </Box>
        </Box>
      )}
      {selected.status.length > 0 && (
        <Box
          mt={1}
          p={1}
          style={{ background: THEME.bg, fontFamily: 'monospace', fontSize: '11px' }}
        >
          {selected.status.map((line, i) => (
            <Box key={i}>{line}</Box>
          ))}
        </Box>
      )}
      <Box mt={1}>
        <CommandList
          commands={selected.commands}
          onCommand={(id) => act('command', { id })}
        />
      </Box>
      <NodeMovement selected={selected} host={display.entity?.host} pending={pending} act={act} />
      {!!can_breach && selected.access < 3 && (
        <Button
          mt={1}
          icon="key"
          color="caution"
          content="Подобрать доступ"
          disabled={!!breach || !selected.online}
          onClick={() => act('breach', { kind: 'node', id: selected.address })}
        />
      )}
      {!!can_breach && selected.access >= 1 && selected.access < 2 && <AutoBreachButton kind="node" id={selected.address} disabled={!selected.online} />}
      <NodeFortress key={selected.address} selected={selected} disabled={pending} onCommand={(id) => act('command', { id })} />
      <EntityContacts address={selected.address} contacts={selected.contacts} pending={pending}
        localEntity={display.entity?.host === selected.address} />
      {!!selected.files && (
        <Box mt={2}>
          <Box color={THEME.muted} mb={0.5}>
            Хранилище узла: {selected.storage?.used}/{selected.storage?.capacity}
            <StorageMeter storage={selected.storage} />
          </Box>
          {selected.files.length === 0 && <Box color={THEME.muted}>Пусто.</Box>}
          <div data-net-files="remote" style={{ maxHeight: '40vh', minHeight: 0, overflowY: 'auto', paddingRight: '4px' }}>
          {selected.files.map((file) => (
            <RemoteFile key={file.uid} file={file} root={selected.access >= 3}
              disabled={pending || !!data.locked} readOnly={selected.storage?.capacity === 0} />
          ))}
          </div>
        </Box>
      )}
      <PacketJournal packets={selected.packets} root={selected.access >= 3} disabled={pending || !!data.locked} />
      {!!selected.logs?.length && (
        <Box mt={1} p={1} style={{ background: THEME.bg, whiteSpace: 'pre-wrap', fontFamily: 'monospace', maxHeight: '160px', overflowY: 'auto' }}>
          <Box color={THEME.muted} mb={0.5}>Журнал узла</Box>
          {selected.logs.map((line, index) => <div key={index}>{line}</div>)}
        </Box>
      )}
      </div>
    </Section>
  );
};

const RemoteFile = (props: { file: NetFile; root: boolean; disabled: boolean; readOnly: boolean }) => {
  const { data } = useBackend<NetrunData>(['shard', 'storage']);
  const { file, root, disabled, readOnly } = props;
  return (
    <Box mb={0.5} p={0.5} data-net-file-row="remote" style={{ display: 'flex', alignItems: 'center',
      minWidth: 0, gap: '6px', fontFamily: 'monospace', borderBottom: `1px solid ${THEME.line}` }}>
      <Box title={file.name} style={{ flex: '1 1 auto', minWidth: 0, overflow: 'hidden',
        textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
        <Icon name={fileIcon(file.kind)} mr={1} />
        {file.name}
        <Box inline ml={1} color={THEME.muted}>[{fileSizeLabel(file)}]</Box>
      </Box>
      <Box className="netrun-file-actions" data-net-file-actions="remote" style={{ display: 'flex', flex: '0 0 auto', justifyContent: 'flex-end',
        flexWrap: 'nowrap', gap: '3px' }}>
        <RemoteFileActions file={file} local={data.storage} shard={data.shard} root={root} readOnly={readOnly} iconsOnly
          reason={disabled ? 'Ожидание актуальных данных узла.' : null} />
      </Box>
    </Box>
  );
};

/** Grouped fortress requests leave the generic grid for the fortress section. */
const NodeFortress = (props: { selected: SelectedNode; disabled: boolean; onCommand: (id: string) => void }) => {
  const { selected } = props;
  const commands = (selected.commands ?? []).filter((command) => command.group === 'fortress');
  if (!selected.fortress && !commands.length) { return null; }
  return (<FortressPanel fortress={selected.fortress} commands={commands} access={selected.access}
    disabled={props.disabled} onCommand={props.onCommand} />);
};

const StorageMeter = (props: { storage?: { used: number; capacity: number } }) => (
  <Meter value={props.storage?.used ?? 0} max={props.storage?.capacity ?? 0} tone="usage"
    label="Заполнение хранилища узла" height={4}
    style={{ display: 'inline-block', verticalAlign: 'middle', width: '80px', marginLeft: '8px' }} />
);

export const NodePanel = memo(NodePanelView);

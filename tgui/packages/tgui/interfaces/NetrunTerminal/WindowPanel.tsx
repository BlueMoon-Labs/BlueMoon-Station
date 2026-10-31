import { memo } from 'react';

import { Box, Button, Icon, Section } from '../../components';
import { AutoBreachButton } from './AutoBreachButton';
import { CommandList } from './CommandList';
import { RemotePanel } from './RemotePanel';
import {
  ACCESS_COLORS,
  ACCESS_NAMES,
  MachineWindow,
  NetrunData,
  NODE_ICONS,
  THEME,
} from './types';
import { useNetrunBackend as useBackend } from './useNetrunBackend';

/** Окно машины: состояние, команды-запросы и особые действия (часть под взломом) */
const WindowPanelView = (props: { window: MachineWindow }) => {
  const { act, data } = useBackend<NetrunData>(['breach', 'locked']);
  const { window: w } = props;
  return (
    <Section
      title={w.title}
      scrollable
      style={{ height: '100%', minHeight: '100%', boxSizing: 'border-box', overflowY: 'auto' }}
      buttons={
        <Box inline>
          <Icon name={NODE_ICONS[w.type] || 'window-maximize'} mr={1} />
          <Box inline color={ACCESS_COLORS[w.access]} mr={1}>
            {ACCESS_NAMES[w.access]}
          </Box>
          <Button icon="xmark" onClick={() => act('window_close', { address: w.address })} />
        </Box>
      }
    >
      <div className="netrun-machine">
      {!w.online && (
        <Box color={THEME.bad} mb={1}>
          Узел не отвечает.
        </Box>
      )}
      <Box color={THEME.muted} mb={1} style={{ fontFamily: 'monospace' }}>
        {w.address}
        {w.network ? ` · ${w.network.code}` : ''}
        {w.security !== undefined ? ` · защита ${w.security}` : ''}
      </Box>
      {w.access < 1 && (
        <Box color={THEME.warn} mb={1}>
          Доступ к узлу закрыт. Подберите доступ, чтобы читать состояние и выполнять запросы.
        </Box>
      )}
      {!!(w.can_breach || w.network?.can_breach) && (
        <Box mb={1}>
          {!!w.can_breach && w.access < 2 && <AutoBreachButton kind="node" id={w.address} disabled={!w.online} />}
          {!!w.network?.can_breach && <AutoBreachButton kind="network" id={w.network.id} />}
          {!!w.can_breach && (
            <Button
              icon="key"
              color="caution"
              content="Подобрать доступ к узлу"
              disabled={!!data.breach || !w.online || data.locked > 0}
              onClick={() => act('breach', { kind: 'node', id: w.address })}
            />
          )}
          {!!w.network?.can_breach && (
            <Button
              icon="network-wired"
              color="caution"
              content={`Подобрать доступ к ${w.network.code}`}
              disabled={!!data.breach || data.locked > 0}
              onClick={() => act('breach', { kind: 'network', id: w.network?.id })}
            />
          )}
        </Box>
      )}
      {!!w.feed && (
        <Box
          mb={1}
          p={1}
          style={{
            background: '#05090d',
            border: `1px solid ${THEME.line}`,
            fontFamily: 'monospace',
            fontSize: '11px',
          }}
        >
          <Box color={w.watching ? THEME.good : THEME.muted} mb={0.5}>
            <Icon name="video" mr={1} />
            {w.watching ? 'ВЫ СМОТРИТЕ ЧЕРЕЗ КАМЕРУ' : 'Видеопоток'}
          </Box>
          {w.feed.map((line, i) => (
            <Box key={i}>— {line}</Box>
          ))}
        </Box>
      )}
      {w.fields.length > 0 && (
        <Box
          mb={1}
          p={1}
          style={{ background: THEME.bg, fontFamily: 'monospace', fontSize: '11px' }}
        >
          {w.fields.map((line, i) => (
            <Box key={i}>{line}</Box>
          ))}
        </Box>
      )}
      {w.extra.length > 0 && (
        <Box mb={1}>
          {w.extra.map((a) => (
            <Button
              key={a.id}
              icon={a.icon}
              content={a.name}
              color={a.danger ? 'bad' : undefined}
              disabled={!a.allowed}
              tooltip={a.desc}
              onClick={() => act('window_act', { address: w.address, waction: a.id })}
            />
          ))}
        </Box>
      )}
      <Box color={THEME.muted} fontSize="11px" mb={0.5}>
        Запросы
      </Box>
      <CommandList
        commands={w.commands}
        onCommand={(id) => act('window_act', { address: w.address, waction: id })}
      />
      {!!w.remote && <RemotePanel key={w.address} address={w.address} remote={w.remote} />}
      {!!w.logs?.length && (
        <Box mt={1} p={1} style={{ background: THEME.bg, whiteSpace: 'pre-wrap', fontFamily: 'monospace', maxHeight: '160px', overflowY: 'auto' }}>
          <Box color={THEME.muted} mb={0.5}>Журнал узла</Box>
          {w.logs.map((line, index) => <div key={index}>{line}</div>)}
        </Box>
      )}
      </div>
    </Section>
  );
};

export const WindowPanel = memo(WindowPanelView);

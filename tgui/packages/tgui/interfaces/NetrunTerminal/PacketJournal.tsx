import { Box, Button } from '../../components';
import { NetPacketHeader, THEME } from './types';
import { useNetrunBackend } from './useNetrunBackend';

export const PacketJournal = (props: { packets?: NetPacketHeader[]; root: boolean; disabled?: boolean }) => {
  const { act } = useNetrunBackend();
  if (!props.packets?.length) return null;
  return (
    <details style={{ marginTop: '8px' }}>
      <summary>Журнал пакетов · заголовки</summary>
      <Box color={THEME.muted} fontSize="11px">Последние 20 этапов. Расшифровка с ROOT открывает содержимое во вкладке операций.</Box>
      <div style={{ maxHeight: '280px', overflowY: 'auto', overflowWrap: 'anywhere' }}>
        {props.packets.map((packet, index) => (
          <details key={`${packet.id}-${packet.phase}-${index}`} style={{ borderBottom: `1px solid ${THEME.line}`, padding: '4px' }}>
            <summary><code>{packet.id}</code> · {packet.phase} · {packet.service || packet.kind}</summary>
            <Box fontFamily="monospace" fontSize="11px">
              <div>{packet.from || '—'} → {packet.to || '—'}</div>
              <div>{Math.round(packet.time * 100)} мс · {packet.kind}</div>
              {Object.entries(packet.headers || {}).map(([key, value]) => <div key={key}>{key}: {String(value)}</div>)}
              {!!packet.reason && <Box color={THEME.bad}>{packet.reason}</Box>}
            </Box>
            <Button compact icon="unlock" content="Расшифровать"
              disabled={!props.root || props.disabled || !packet.headers}
              tooltip={props.root ? 'Прочитать захваченный фрагмент пакета' : 'Требуется ROOT'}
              onClick={() => act('command', { id: 'packet_decrypt', packet_id: packet.id })} />
          </details>
        ))}
      </div>
    </details>
  );
};

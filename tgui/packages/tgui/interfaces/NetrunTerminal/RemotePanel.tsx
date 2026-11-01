import { useState } from 'react';

import { Box, Button } from '../../components';
import { ActionTooltip } from './CommandTooltip';
import { machinePresentation } from './nativePresentation';
import { remoteArguments, remoteParameterValue } from './remoteParameters';
import { ACCESS_NAMES, MachineWindow, NetrunData, THEME } from './types';
import { useNetrunBackend as useBackend } from './useNetrunBackend';

type Remote = NonNullable<MachineWindow['remote']>;

const LABELS: Record<string, string> = {
  name: 'Название', status: 'Состояние', locked: 'Блокировка',
  active: 'Активен', enabled: 'Включено', power: 'Питание',
  charge: 'Заряд', mode: 'Режим', pressure: 'Давление',
  temperature: 'Температура', contents: 'Содержимое', amount: 'Количество',
  network: 'Сеть', address: 'Адрес', error: 'Ошибка',
  wearer: 'Носитель', modules: 'Модули', open: 'Сервисная панель открыта',
  selected: 'Выбран', remote_utility: 'Сетевое управление',
};

/** Data only: native actions are declared and validated by the machine adapter. */
export const RemotePanel = (props: { address: string; remote: Remote }) => {
  const machine = machinePresentation(props.remote);
  const [diagnostics, setDiagnostics] = useState(false);
  return (
  <Box mt={1} className="netrun-remote-panel">
    <Box bold mb={1}>{machine?.title || `Управление машиной · ${props.remote.interface}`}</Box>
    {machine && <dl style={{ margin: '0 0 12px', overflowWrap: 'anywhere' }}>
      {machine.readings.map((reading, index) => (<div key={`${reading.label}:${index}`} style={{ display: 'flex', flexWrap: 'wrap', gap: '6px', marginBottom: '4px' }}>
        <dt style={{ color: THEME.muted }}>{reading.label}:</dt><dd style={{ margin: 0 }}>{reading.value}</dd>
                                                 </div>))}
                </dl>}
    {(machine?.actions || props.remote.actions).map((action) => (
      <RemoteAction key={`${props.address}:${props.remote.interface}:${action.id}`} address={props.address} action={action} />
    ))}
    <details open={diagnostics || !machine} onToggle={(event) => setDiagnostics(event.currentTarget.open)}>
      <summary>Данные устройства · {props.remote.interface}</summary>
      {(diagnostics || !machine) && <Box p={1} mt={1} className="netrun-remote-tree" style={{ background: THEME.bg, maxHeight: '350px', overflowY: 'auto' }}>
        <DataTree value={props.remote.data} depth={0} />
                                    </Box>}
    </details>
  </Box>
  );
};

const DataTree = (props: { value: unknown; depth: number }) => {
  const { value, depth } = props;
  if (value === null || value === undefined) {
    return <span>—</span>;
  }
  if (typeof value !== 'object') {
    return <span>{typeof value === 'boolean' ? (value ? 'Да' : 'Нет') : String(value)}</span>;
  }
  if (depth > 5) {
    return <span>{JSON.stringify(value)}</span>;
  }
  const entries = Object.entries(value);
  if (!entries.length) {
    return <Box color={THEME.muted}>Нет данных.</Box>;
  }
  return (
    <div style={{ overflowWrap: 'anywhere' }}>
      {entries.map(([key, entry]) => {
        const display = entry && typeof entry === 'object'
          ? (entry as Record<string, unknown>).name ?? (entry as Record<string, unknown>).title
          : null;
        const label = Array.isArray(value)
          ? (typeof display === 'string' && display ? display : `#${Number(key) + 1}`)
          : LABELS[key] || key.replace(/_/g, ' ');
        return entry && typeof entry === 'object' ? (
          <details key={key} open={depth < 1 && !Array.isArray(entry) && Object.keys(entry).length <= 6}
            style={{ marginLeft: depth ? '8px' : 0 }}>
            <summary>{label}</summary>
            <DataTree value={entry} depth={depth + 1} />
          </details>
        ) : (
          <Box key={key} mb={0.25}>
            <Box inline color={THEME.muted}>{label}: </Box>
            <DataTree value={entry} depth={depth + 1} />
          </Box>
        );
      })}
    </div>
  );
};

const RemoteAction = (props: { address: string; action: Remote['actions'][number] }) => {
  const { act } = useBackend<NetrunData>([]);
  const { action } = props;
  const params = action.params ?? [];
  const [values, setValues] = useState<Record<string, string>>({});
  const request = remoteArguments(params, values);
  return (
    <Box className="netrun-remote-action" mb={1}>
      {params.map((param) => (
        <label key={param.id} style={{ display: 'block', maxWidth: '100%', minWidth: 0, marginRight: '6px', marginBottom: '5px' }}>
          <span style={{ marginRight: '5px' }}>{param.name}</span>
          {param.options ? <select aria-label={param.name} value={remoteParameterValue(param, values)} disabled={!action.allowed}
            onChange={(event) => setValues((previous) => ({ ...previous, [param.id]: event.target.value }))}
            style={{ maxWidth: '100%', boxSizing: 'border-box', background: THEME.bg, color: THEME.text,
              border: `1px solid ${THEME.line}`, padding: '4px 6px', fontFamily: 'inherit' }}>
            <option value="">Выберите…</option>
            {param.options.map((option) => <option key={option.value} value={option.value}>{option.name}</option>)}
                           </select> : <input
            aria-label={param.name}
            inputMode={param.type === 'number' ? 'decimal' : 'text'}
            value={remoteParameterValue(param, values)}
            disabled={!action.allowed}
            onChange={(event) => setValues((previous) => ({ ...previous, [param.id]: event.target.value }))}
            style={{ width: '130px', boxSizing: 'border-box', background: THEME.bg, color: THEME.text,
              border: `1px solid ${THEME.line}`, padding: '3px 5px', fontFamily: 'monospace' }}
          />}
          {param.type === 'number' && (param.min !== undefined || param.max !== undefined) && <span
            style={{ color: THEME.muted, marginLeft: '5px', fontSize: '10px' }}>
            {param.min ?? '…'}–{param.max ?? '…'}
                                                                                              </span>}
        </label>
      ))}
      <Button
        icon="paper-plane"
        content={action.name}
        disabled={!action.allowed || !!request.error}
        color={action.danger ? 'bad' : undefined}
        tooltip={<ActionTooltip name={action.name} id={action.id} icon="sliders" description={action.desc}
          facts={[{ label: 'Доступ', value: ACCESS_NAMES[action.access] || '—' }, { label: 'Доставка', value: 'По сетевому маршруту' }]}
          notices={[
            ...(action.danger ? [{ text: 'Изменяет работу устройства', danger: true }] : []),
            ...(action.reason || request.error ? [{ text: action.reason || request.error || '' }] : []),
          ]} />}
        onClick={() => {
          if (request.error || !action.allowed) { return; }
          act('remote_act', { address: props.address, request: action.id, arguments: request.args });
        }}
      />
      {!!(!action.allowed && action.reason || request.error) && <Box role="status" color={THEME.warn} fontSize="11px">
        {!action.allowed && action.reason || request.error}
                                                                </Box>}
    </Box>
  );
};

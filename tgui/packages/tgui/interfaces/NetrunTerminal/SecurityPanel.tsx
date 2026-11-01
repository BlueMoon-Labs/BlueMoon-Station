import { memo } from 'react';

import { Box, Button, Icon } from '../../components';
import { SecurityEvidence, THEME } from './types';
import { useNetrunBackend } from './useNetrunBackend';

const KINDS: Record<string, string> = { breach: 'Попытка взлома', intrusion: 'Вторжение' };
const EvidenceCard = ({ entry }: { entry: SecurityEvidence }) => {
  const { act } = useNetrunBackend([]);
  const source = entry.attributed ? entry.name || 'Источник установлен' : 'Неизвестный источник';
  const mapAllowed = entry.attributed && entry.map_allowed;
  const pursueAllowed = entry.attributed && entry.pursue_allowed;
  const mapReason = entry.map_reason || (!entry.attributed ? 'Сначала установите источник.' : null);
  const pursueReason = entry.pursue_reason || (!entry.attributed ? 'Сначала установите источник.' : null);
  return (<article className="netrun-security__entry" data-net-evidence={entry.id}>
    <div className="netrun-security__heading">
      <strong><Icon name={entry.attributed ? 'fingerprint' : 'user-secret'} mr={0.5} />{source}</strong>
      <span style={{ color: entry.active ? THEME.warn : THEME.muted }}>{entry.active ? 'Активная попытка' : 'Сохранённый след'}</span>
    </div>
    <Box color={THEME.muted} fontSize="11px" mt={0.5}>
      {KINDS[entry.kind] || 'Подозрительная активность'} · {Math.max(0, Math.round(entry.age))} с назад
      {entry.attributed && ` · контакт ещё ${Math.max(0, Math.ceil(entry.ttl))} с`}
    </Box>
    {!!entry.status && <Box mt={0.5}>{entry.status}</Box>}
    {entry.attributed && !!entry.source_address && <Box mt={0.5} fontSize="11px">
      Узел источника: {entry.source_name} <code>{entry.source_address}</code>
                                                   </Box>}
    <div className="netrun-security__actions">
      <div>
        <Button compact icon="satellite-dish" content="Контртрассировка" disabled={!entry.trace_allowed}
          tooltip={entry.trace_reason || 'Отправить запрос и установить источник по следу.'}
          onClick={() => act('security_trace', { id: entry.id })} />
        {!entry.trace_allowed && !!entry.trace_reason && <small>{entry.trace_reason}</small>}
      </div>
      <div>
        <Button compact icon="location-crosshairs" content="Узел на карте" disabled={!mapAllowed}
          tooltip={mapReason || 'Выбрать узел источника и поставить пеленг.'}
          onClick={() => act('security_map', { id: entry.id })} />
        {!mapAllowed && !!mapReason && <small>{mapReason}</small>}
      </div>
      <div>
        <Button compact icon="crosshairs" content="Преследовать" disabled={!pursueAllowed}
          tooltip={pursueReason || 'Захватить установленную цель и следовать за ней по узлам.'}
          onClick={() => act('security_pursue', { id: entry.id })} />
        {!pursueAllowed && !!pursueReason && <small>{pursueReason}</small>}
      </div>
    </div>
          </article>);
};

/** Server evidence owns attribution, expiry and countermeasure authority; this view has no polling clock. */
export const SecurityPanel = memo(() => {
  const { act, data } = useNetrunBackend(['security']);
  const defended = data.security?.defended;
  const entries = (data.security?.entries || []).slice(0, 16);
  return (<div className="netrun-security" role="region" aria-label="Безопасность сети">
    <Box bold><Icon name="shield-halved" mr={0.5} />Безопасность</Box>
    <Box mt={0.5} color={THEME.muted} fontSize="11px">Контртрассировка устанавливает источник по следу атаки. Найденный узел можно отметить на карте, а сущность — преследовать.</Box>
    <Box mt={1} mb={1}>
      {defended ? <>Защищаемый узел: <strong>{defended.name}</strong> <code>{defended.address}</code></>
        : <Box color={THEME.muted}>Защищаемый узел не выбран.</Box>}
    </Box>
    {!entries.length && <Box color={THEME.muted} mb={1}>Следов атак пока нет.</Box>}
    <Button compact icon="satellite-dish" content={entries.length ? 'Обновить контртрассировку' : 'Проверить следы'} disabled={!defended?.can_countertrace}
      tooltip={defended?.reason || 'Отправить контртрассировку к защищаемому узлу.'} onClick={() => act('security_probe')} />
    {!!defended?.reason && <Box color={THEME.muted} fontSize="11px" mt={0.5}>{defended.reason}</Box>}
    {entries.map((entry) => <EvidenceCard key={entry.id} entry={entry} />)}
          </div>);
});

import { memo, useRef } from 'react';

import { Box, Button, Icon } from '../../components';
import { AgentBuilderPanel } from './AgentBuilderPanel';
import { AgentsPanel } from './AgentsPanel';
import { BotAvatar, botKindLabel } from './EntityContacts';
import { NetrunData, THEME } from './types';
import { useNetrunBackend } from './useNetrunBackend';

/** Template selection is the same inventory selection as Files; switching pages never invents a new UID. */
export const AgentsWorkspace = memo(() => {
  const { act, data } = useNetrunBackend(['workspace_view', 'file', 'storage', 'shard', 'selected', 'entity']);
  const confirmed = useRef<NetrunData['file']>(null);
  if (data.workspace_view === 'agents' || data.workspace_view === 'files') { confirmed.current = data.file; }
  const file = data.file || confirmed.current;
  const templates = [...new Map([...(data.storage?.files || []), ...(data.shard?.files || [])]
    .filter((entry) => entry.kind === 'bot').map((entry) => [entry.uid, entry])).values()];
  const selected = file?.kind === 'bot' && templates.some((entry) => entry.uid === file.uid) ? file : null;
  const host = data.entity?.host;
  const site = host ? `${data.entity?.host_name || ''} ${host}`
    : data.selected ? `${data.selected.name} ${data.selected.address}` : null;
  return (<div className="netrun-agents-workspace" role="region" aria-label="Управление агентами">
    <Box bold fontSize="16px"><Icon name="robot" mr={0.5} />Агенты</Box>
    <Box color={THEME.muted} mt={0.5} fontSize="11px">Запускайте помощников, задавайте им цели и следите за их работой. Программы, память и личность раскрываются в карточках.</Box>
    <div className="netrun-agent-context">
      <div><strong>Цель адресных приказов</strong><Box mt={0.5} fontSize="11px">
        {data.selected ? <>{data.selected.name} <code>{data.selected.address}</code></> : 'Выберите нужное устройство на карте.'}
                                                  </Box>
      </div>
      <Button compact icon="location-crosshairs" content="Выбрать на карте" onClick={() => act('workspace_view', { page: 'map' })} />
      <Box color={THEME.muted} fontSize="11px">Приказы с целью и команды устройству используют этот узел.</Box>
    </div>
    <AgentsPanel />
    <section className="netrun-agent-launcher" aria-label="Запуск и создание агентов">
      <Box bold mb={0.5}>Запуск и создание</Box>
      <Box color={THEME.muted} fontSize="11px" mb={1}>Выберите файл агента из памяти или шарда. В конструкторе можно собрать отдельную копию со своими программами и модулями.</Box>
      {!templates.length && <Box color={THEME.muted}>Нужен файл .bot. Запишите шаблон на шард или получите его от другого процесса.</Box>}
      <div className="netrun-agent-template-grid">{templates.map((template) => (
        <Button key={template.uid} className="netrun-agent-template" role="button" selected={selected?.uid === template.uid}
          aria-pressed={selected?.uid === template.uid} aria-label={`Шаблон ${template.name}`}
          onClick={() => act('file_select', { uid: template.uid })}>
          <BotAvatar kind={template.agent_profile} faction="owner" size={28} />
          <span><strong>{template.name}</strong><small>{botKindLabel(template.agent_profile)} · память {template.size}</small></span>
        </Button>
      ))}
      </div>
      {!!selected && <div className="netrun-agent-launch-card" data-net-bot-launch={selected.uid}>
        <Box bold>{selected.name}</Box>
        {!!selected.preview && <Box color={THEME.muted} fontSize="11px" mt={0.5}>{selected.preview}</Box>}
        <Box mt={0.5} fontSize="11px">Старт: {site || 'выберите узел на карте с доступом ПОЛЬЗОВАТЕЛЯ и маршрутом.'}</Box>
        <Box color={THEME.muted} mt={0.5} mb={0.5} fontSize="11px">Файл переходит в агента и возвращается при отзыве.</Box>
        <Button compact icon="play" content="Запустить агента" disabled={!site} onClick={() => act('bot_launch', { uid: selected.uid })} />
        <Button compact icon="folder-open" content="Файл в памяти" onClick={() => act('workspace_view', { page: 'files' })} />
        {!!selected.agent_builder && <AgentBuilderPanel key={selected.uid} builder={selected.agent_builder} />}
                     </div>}
    </section>
          </div>);
});

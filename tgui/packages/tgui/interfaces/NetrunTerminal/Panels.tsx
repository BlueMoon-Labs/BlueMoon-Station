import { memo, useMemo, useState } from 'react';

import { Box, Button, Icon, Input, Section } from '../../components';
import { AccessExport } from './AccessExport';
import { FilePanel } from './FilePanel';
import { fileSizeLabel, fileTransferState, isCopyableFile, SESSION_FILE_REASON, visibleFiles } from './filePermissions';
import { fileFormat, fileIcon } from './filePresentation';
import { RemoteFileActions } from './RemoteFileActions';
import { NetFile, NetrunData, SelectedNode, Storage, THEME } from './types';
import { useFollowOutput } from './useFollowOutput';
import { useNetrunBackend as useBackend } from './useNetrunBackend';

const StoragePanelView = () => {
  const { data } = useBackend<NetrunData>(['storage', 'shard', 'selected', 'workspace_view', 'locked']);
  const { storage, shard, selected } = data;
  const [query, setQuery] = useState('');
  const localFiles = useMemo(() => visibleFiles(storage.files, query), [storage.files, query]);
  const shardFiles = useMemo(() => visibleFiles(shard?.files || [], query), [shard?.files, query]);
  const uploadReason = !selected ? 'Выберите узел назначения на карте.' : !selected.online ? 'Узел назначения не отвечает.'
    : !selected.files || selected.access < 2 ? 'Нет доступа к файлам выбранного узла.' : null;
  const destination = selected?.storage ? { ...selected.storage, files: selected.files || [] } : undefined;
  return (
    <Section title={`Память ${storage.used}/${storage.capacity}`} scrollable
      style={{ height: '100%', minHeight: 0, boxSizing: 'border-box', overflowY: 'auto' }}>
      <div className="netrun-files-layout">
        <div className="netrun-files-catalog">
          <input aria-label="Поиск файлов по имени или типу" placeholder="Имя или тип файла…" value={query}
            onChange={(event) => setQuery(event.target.value)}
            style={{ width: '100%', boxSizing: 'border-box', padding: '6px', marginBottom: '8px', background: THEME.bg, color: THEME.text, border: `1px solid ${THEME.line}` }} />
          <Box bold mb={1} color={THEME.text}>Локальные файлы ({localFiles.length}/{storage.files.length}) · {storage.used}/{storage.capacity}</Box>
          <Box color={THEME.muted} fontSize="11px" mb={0.5}>{selected ? `Загрузка копий: ${selected.name}` : 'Для загрузки выберите узел на карте.'}</Box>
          <FileList files={localFiles} uploadReason={uploadReason} destination={destination} readOnly={storage.capacity <= 0} source="local" />
          {!!shard && (
            <Box mt={2}>
              <Box color={THEME.muted} mb={0.5}>
                <Icon name="sd-card" mr={1} />
                {shard.name} ({shardFiles.length}/{shard.files.length}) · {shard.used}/{shard.capacity}
              </Box>
              <FileList files={shardFiles} uploadReason={uploadReason} destination={destination} readOnly={shard.capacity <= 0} source="shard" />
            </Box>
          )}
          <AccessExport />
          {data.workspace_view === 'files' && <RemoteFileCatalog node={selected} query={query} local={storage} shard={shard} locked={!!data.locked} />}
        </div>
        <div className="netrun-files-preview">
          <Box bold mb={1} color={THEME.text}>Просмотр и редактирование</Box>
          <FilePanel />
        </div>
      </div>
    </Section>
  );
};

/** Current target stays usable from the files workspace; all mutations use native queued actions. */
const RemoteFileCatalog = ({ node, query, local, shard, locked }: {
  node?: SelectedNode | null; query: string; local: Storage; shard?: Storage | null; locked: boolean;
}) => {
  const files = useMemo(() => visibleFiles(node?.files || [], query), [node?.files, query]);
  if (!node) { return null; }
  const reason = locked ? 'Сетевой доступ временно заблокирован.'
    : !node.online ? 'Узел не отвечает.' : !node.files ? 'Недостаточно доступа к хранилищу узла.' : null;
  return (<Box mt={2} data-net-remote-catalog>
    <Box bold>Узел: {node.name}</Box>
    <Box color={THEME.muted} fontSize="11px">{node.address} · файлов {files.length}/{node.files?.length || 0}
      {node.storage ? ` · память ${node.storage.used}/${node.storage.capacity}` : ''}
    </Box>
    {!!reason && <Box color={THEME.warn} fontSize="11px">{reason}</Box>}
    <div className="netrun-remote-files">
    {files.map((file) => (<Box key={file.uid} mt={0.5} p={0.5} style={{ background: THEME.bg, border: `1px solid ${THEME.line}`, overflowWrap: 'anywhere' }}>
        <Box><Icon name={fileIcon(file.kind)} mr={0.5} />{file.name} <Box inline color={THEME.muted} fontSize="10px">· {fileSizeLabel(file)}</Box></Box>
        <div style={{ display: 'flex', gap: '4px', flexWrap: 'wrap', marginTop: '4px' }}>
          <RemoteFileActions file={file} local={local} shard={shard} root={node.access >= 3}
            readOnly={node.storage?.capacity === 0} reason={reason} />
        </div>
                          </Box>))}
    {!files.length && !reason && <Box color={THEME.muted} fontSize="11px">Файлы не найдены.</Box>}
    </div>
          </Box>);
};

const FileList = (props: { files: NetFile[]; uploadReason: string | null; destination?: Storage; readOnly: boolean; source: 'local' | 'shard' }) => {
  const { act } = useBackend<NetrunData>([]);
  if (!props.files.length) {
    return <Box color={THEME.muted}>Пусто.</Box>;
  }
  return (
    <div data-net-files={props.source}>
      {props.files.map((file) => {
        const uploadReason = props.uploadReason || (props.destination ? fileTransferState(file, props.destination).reason : null);
        return (
        <Box
          key={file.uid}
          data-net-file-row={props.source}
          mb={0.5}
          p={0.5}
          style={{
            fontFamily: 'monospace',
            background: file.selected ? THEME.line : THEME.bg,
            border: `1px solid ${THEME.line}`,
            display: 'grid',
            gridTemplateColumns: 'minmax(0, 1fr) 78px',
            gap: '6px',
            alignItems: 'center',
            cursor: 'pointer',
          }}
          onClick={() => act('file_select', { uid: file.uid })}
          role="button" tabIndex={0} aria-label={`Выбрать файл ${file.name}`}
          onKeyDown={(event) => {
            if (event.target === event.currentTarget && (event.key === 'Enter' || event.key === ' ')) {
              event.preventDefault(); act('file_select', { uid: file.uid });
            }
          }}
        >
          <Box style={{ flex: 1, minWidth: 0, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
            <Icon name={fileIcon(file.kind)} mr={1} color={THEME.accent} />
            {file.name}
            <Box inline ml={1} color={THEME.muted} fontSize="9px">
              {fileFormat(file.name, file.kind)} · {fileSizeLabel(file)}
              {file.session_bound && <span title={SESSION_FILE_REASON}> · сеанс</span>}
            </Box>
          </Box>
          <div className="netrun-file-actions" data-net-file-actions={props.source}
            style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 24px)', gridAutoRows: '24px', gap: '3px' }}>
            {file.kind === 'text' && (
              <Button compact icon="eye" tooltip="Открыть" style={{ gridColumn: 1 }}
                onClick={(e) => { e.stopPropagation(); act('read', { uid: file.uid }); }} />
            )}
            {isCopyableFile(file) && (
              <Button compact icon="upload" tooltip={uploadReason || 'Загрузить копию на выбранный узел'} disabled={!!uploadReason} style={{ gridColumn: 2 }}
                onClick={(e) => { e.stopPropagation(); act('upload', { uid: file.uid }); }} />
            )}
            <Button compact icon={file.session_bound ? 'ban' : 'trash'} color="transparent" tooltip={file.session_bound ? 'Отозвать доступ ID' : props.readOnly ? 'Носитель доступен только для чтения.' : 'Удалить'} style={{ gridColumn: 3 }}
              disabled={props.readOnly && !file.session_bound}
              onClick={(e) => { e.stopPropagation(); act('delete_local', { uid: file.uid }); }} />
          </div>
        </Box>
        );
      })}
    </div>
  );
};

/** Канал #noosphere - общий чат сущностей и консолей (NTNRC) */
const NetChatView = (props: { active?: boolean } = {}) => {
  const { act, data } = useBackend<NetrunData>(['chat', 'uplink', 'entity']);
  const { chat, uplink, entity } = data;
  const output = useFollowOutput(`${chat.messages.length}:${chat.messages[chat.messages.length - 1]}`, props.active);
  return (
    <Box style={{ background: THEME.bg, border: `1px solid ${THEME.line}`, display: 'flex', flexDirection: 'column', height: '100%', width: '100%', minHeight: 0 }}>
      <div
        ref={output.scroller}
        onScroll={output.handleScroll}
        aria-label="Сообщения noosphere"
        style={{
          flex: '1 1 auto',
          minHeight: '70px',
          overflowY: 'auto',
          padding: '4px 6px',
          fontFamily: 'monospace',
          fontSize: '11px',
        }}
      >
        {chat.messages.map((line, i) => (
          <div
            key={i}
            style={{
              color: line.includes(' -!- ') ? THEME.muted : THEME.text,
              whiteSpace: 'pre-wrap',
            }}
          >
            {line}
          </div>
        ))}
      </div>
      {!!output.unread && <Button compact icon="arrow-down" content="К новым сообщениям" onClick={output.handleFollowLatest} />}
      <Box style={{ display: 'flex' }}>
        {!entity && (
          <Input
            width="110px"
            value={chat.handle}
            onChange={(_e, value) => act('set_handle', { handle: value })}
            style={{ fontFamily: 'monospace', background: THEME.panel }}
          />
        )}
        <Box style={{ flexGrow: 1 }}>
          <Input
            fluid
            selfClear
            disabled={!uplink}
            placeholder={uplink ? `${chat.handle} в #noosphere` : 'Нет связи с NTnet'}
            onEnter={(_e, value) => { output.handleFollowLatest(); act('chat_send', { text: value }); }}
            style={{ fontFamily: 'monospace', background: THEME.panel }}
          />
        </Box>
      </Box>
    </Box>
  );
};

export { ConsoleLog } from './TerminalConsole';

export const StoragePanel = memo(StoragePanelView);

export { EntityPanel } from './EntityProfile';

export const NetChat = memo(NetChatView);

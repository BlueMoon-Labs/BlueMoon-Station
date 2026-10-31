import { memo, useEffect, useRef, useState } from 'react';

import { Box, Button, Input } from '../../components';
import { FileExchangePanel } from './FileExchange';
import { fileSourceLabel, fileTransferState, isTransferableFile, SESSION_FILE_REASON } from './filePermissions';
import { fileKindLabel } from './filePresentation';
import { NetrunData, THEME } from './types';
import { useNetrunBackend as useBackend } from './useNetrunBackend';

const FilePanelView = () => {
  const { data } = useBackend<NetrunData>(['file']);
  const [creating, setCreating] = useState(false);
  return (
    <Box mt={1}>
      <FileExchangePanel />
      <Button compact icon="file-circle-plus" content="Новый текстовый файл" selected={creating} onClick={() => setCreating(!creating)} />
      {creating ? (
        <FileEditor key="new" onCreated={() => setCreating(false)} />
      ) : data.file ? (
        <FileEditor key={data.file.uid} />
      ) : (
        <Box mt={0.5} color={THEME.muted} fontSize="11px">Выберите файл для просмотра, редактирования или печати.</Box>
      )}
    </Box>
  );
};

const FileTransfer = ({ file }: { file: NonNullable<NetrunData['file']> }) => {
  const { act, data } = useBackend<NetrunData>(['shard', 'storage']);
  if (!isTransferableFile(file)) { return <Box color={THEME.muted} fontSize="11px">{SESSION_FILE_REASON}</Box>; }
  if (file.source === 'shard') {
    if (!file.can_import) { return null; }
    const state = file.transfer?.local || fileTransferState(file, data.storage);
    return (<>
      <Button compact icon="download" content={state.merge ? 'Объединить с ключом в памяти' : 'Копировать в память'} disabled={!state.copy}
        tooltip={state.reason || 'Сохранить локальную копию; исходный файл остаётся на шарде.'}
        onClick={() => act('file_import', { uid: file.uid, move: false })} />
      <Button compact icon="arrow-right-arrow-left" content="Перенести в память" disabled={!state.move}
        tooltip={state.reason || 'Переместить файл с шарда в локальную память.'}
        onClick={() => act('file_import', { uid: file.uid, move: true })} />
      {!!state.reason && <Box color={THEME.warn} fontSize="11px">{state.reason}</Box>}
            </>);
  }
  const local = file.transfer?.local || fileTransferState(file, data.storage);
  const state = file.transfer?.shard || fileTransferState(file, data.shard);
  return (<>
    <Button compact icon="copy" content="Дублировать в памяти" disabled={!local.copy}
      tooltip={local.reason || 'Создать независимую копию на том же диске. Ключи доступов объединяются в общий ключ.'}
      onClick={() => act('file_copy', { uid: file.uid, to_shard: false })} />
    {!!local.reason && <Box color={THEME.warn} fontSize="11px">{local.reason}</Box>}
    {!!data.shard && <>
    <Button compact icon="copy" content={state.merge ? 'Объединить с ключом на шарде' : 'Копировать на шард'} disabled={!state.copy}
      tooltip={state.reason || 'Исходный файл остаётся в локальной памяти.'} onClick={() => act('file_copy', { uid: file.uid, to_shard: true })} />
    <Button compact icon="arrow-right-arrow-left" content="Перенести на шард" disabled={!state.move}
      tooltip={state.reason || 'Исходный файл покинет локальную память.'} onClick={() => act('file_move', { uid: file.uid, to_shard: true })} />
    {!!state.reason && <Box color={THEME.warn} fontSize="11px">{state.reason}</Box>}
                     </>}
          </>);
};

const FileEditor = (props: { onCreated?: () => void }) => {
  const { act, data } = useBackend<NetrunData>(['file', 'shard']);
  const file = props.onCreated ? null : data.file;
  const [name, setName] = useState(file?.name ?? 'note.txt');
  const [content, setContent] = useState(file?.content ?? '');
  const confirmed = useRef({ name: file?.name ?? 'note.txt', content: file?.content ?? '' });
  const [toShard, setToShard] = useState(file?.source === 'shard');
  const [submitted, setSubmitted] = useState<{
    previousUid: string | null;
    name: string;
    content: string;
  } | null>(null);
  useEffect(() => {
    if (!file) { return; }
    const before = confirmed.current, next = { name: file.name, content: file.content ?? '' };
    // A clean field follows server pushes. A dirty field keeps the draft,
    // including text entered after saving but before its receipt arrived.
    setName((draft) => draft === before.name ? next.name : draft);
    setContent((draft) => draft === before.content ? next.content : draft);
    confirmed.current = next;
  }, [file?.uid, file?.name, file?.content]);
  useEffect(() => {
    // A failed request leaves the draft mounted. Only a newly created file
    // with the submitted contents acknowledges creation; polling cannot erase
    // text typed since the request was sent.
    if (props.onCreated && submitted && data.file?.kind === 'text'
      && data.file.uid !== submitted.previousUid
      && data.file.content === submitted.content
      && name === submitted.name && content === submitted.content) {
      props.onCreated();
    }
  }, [data.file, submitted, name, content, props.onCreated]);
  return (
    <Box mt={0.5} p={0.5} style={{ background: THEME.bg }}>
      {file?.session_bound ? <input aria-label="Имя снимка ID" readOnly value={file.name}
        style={{ width: '100%', boxSizing: 'border-box', padding: '6px', borderRadius: '6px', border: `1px solid ${THEME.line}`, background: THEME.bg, color: THEME.text }} />
        : <Input fluid value={name} onInput={(_event, value) => setName(value)} />}
      {!!file && (
        <Box mt={0.5} color={THEME.muted} fontSize="11px">
          {fileSourceLabel(file.source)} · {fileKindLabel(file.kind)} · память {file.size}
        </Box>
      )}
      {file?.kind === 'photo' && !!file.image && (
        <div
          style={{
            marginTop: '6px',
            maxWidth: '100%',
            maxHeight: '260px',
            // Сохраняем пропорции кадра: контейнер не превышает натуральный размер картинки.
            aspectRatio: file.width && file.height ? `${file.width} / ${file.height}` : undefined,
            width: file.width ? `${file.width}px` : 'auto',
            overflow: 'hidden',
            background: THEME.bg,
          }}
        >
          <img
            src={file.image}
            alt={file.name}
            style={{
              display: 'block',
              width: '100%',
              height: '100%',
              // Картинка растягивается по размеру рамки, а не повторяется плиткой.
              objectFit: 'contain',
              backgroundRepeat: 'no-repeat',
              imageRendering: 'pixelated',
            }}
          />
        </div>
      )}
      {(!file || file.kind === 'text') ? (
        <textarea
          value={content}
          onChange={(event) => setContent(event.target.value)}
          rows={6}
          maxLength={10000}
          spellCheck={false}
          style={{ width: '100%', boxSizing: 'border-box', resize: 'vertical', background: THEME.panel, color: THEME.text, border: `1px solid ${THEME.line}`, marginTop: '6px', fontFamily: 'monospace' }}
        />
      ) : file?.preview ? (
        <Box mt={0.5} style={{ whiteSpace: 'pre-wrap', overflowWrap: 'anywhere' }}>{file.preview}</Box>
      ) : null}
      <Box mt={0.5} style={{ display: 'flex', flexWrap: 'wrap', gap: '4px', alignItems: 'center' }}>
        {!file ? (
          <>
            {!!data.shard && <Button compact icon="sd-card" content="На шард" selected={toShard} onClick={() => setToShard(!toShard)} />}
            <Button compact icon="save" content="Создать" disabled={!name.trim()} onClick={() => {
              setSubmitted({ previousUid: data.file?.uid ?? null, name, content });
              act('file_new', { name, content, to_shard: toShard });
            }} />
          </>
        ) : (
          <>
            {!file.session_bound && <Button compact icon="signature" content="Переименовать" disabled={!name.trim() || name === file.name} onClick={() => act('file_rename', { uid: file.uid, name })} />}
            {file.kind === 'text' && <Button compact icon="save" content="Сохранить" disabled={content === file.content} onClick={() => act('file_edit', { uid: file.uid, content })} />}
            <FileTransfer file={file} />
          </>
        )}
      </Box>
      {file?.kind === 'bot' && <Button mt={0.5} compact icon="robot" content="К агентам: настройка и запуск"
        onClick={() => act('workspace_view', { page: 'agents' })} />}
      {!file && !!submitted && (
        <Box mt={0.5} color={THEME.muted} fontSize="11px">
          Запрос отправлен. До подтверждения создания текст остаётся в редакторе; результат — в журнале.
        </Box>
      )}
    </Box>
  );
};

export const FilePanel = memo(FilePanelView);

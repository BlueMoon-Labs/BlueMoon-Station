import { Box, Button } from '../../components';
import { fileTransferState, isCopyableFile, isTransferableFile, SESSION_FILE_REASON } from './filePermissions';
import { isReadableFile } from './filePresentation';
import { NetFile, Storage, THEME } from './types';
import { useNetrunBackend as useBackend } from './useNetrunBackend';

/** Both remote catalogs use the same live file permissions and queued operations. */
export const RemoteFileActions = (props: {
  file: NetFile;
  local: Storage;
  shard?: Storage | null;
  root: boolean;
  readOnly: boolean;
  reason?: string | null;
  iconsOnly?: boolean;
}) => {
  const { act } = useBackend([]);
  const { file, local, shard, root, readOnly, reason, iconsOnly } = props;
  const memory = fileTransferState(file, local), disk = fileTransferState(file, shard);
  const transferable = isTransferableFile(file);
  const copyReason = reason || (!isCopyableFile(file) ? 'Этот файл нельзя копировать.' : null);
  const deleteReason = reason || (!root ? 'Удалить исходный файл с узла: нужен ROOT.'
    : readOnly ? 'Хранилище доступно только для чтения.'
      : file.deletable === false ? file.delete_reason || 'Этот файл нельзя удалить.' : null);
  return (
    <>
      {isReadableFile(file.kind) && <Button compact icon="eye" tooltip={`Открыть ${file.name}`} disabled={!!reason}
        onClick={() => act('read', { uid: file.uid })} />}
      {!transferable && <Box color={THEME.muted} fontSize="10px">{file.transfer_reason || SESSION_FILE_REASON}</Box>}
      {transferable && (
        <>
          <Button compact icon="download" content={iconsOnly ? undefined : memory.merge ? 'Объединить ключ' : 'В память'}
            disabled={!!copyReason || !memory.copy} tooltip={copyReason || memory.reason || (memory.merge ? 'Объединить ключ с доступами в памяти.' : 'Скачать копию в локальную память.')}
            onClick={() => act('download', { uid: file.uid, to_shard: false })} />
          {!!shard && <Button compact icon="sd-card" content={iconsOnly ? undefined : 'На шард'}
            disabled={!!copyReason || !disk.copy} tooltip={copyReason || disk.reason || 'Скачать копию на подключённый шард.'}
            onClick={() => act('download', { uid: file.uid, to_shard: true })} />}
        </>
      )}
      {(root || !iconsOnly) && <Button compact icon="trash" color={iconsOnly ? 'bad' : undefined}
        disabled={!!deleteReason} tooltip={deleteReason || 'Удалить исходный файл с узла.'}
        onClick={() => act('delete_remote', { uid: file.uid })} />}
    </>
  );
};

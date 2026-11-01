import { fileSearchLabel } from './filePresentation';
import type { NetFile, Storage } from './types';

export const SESSION_FILE_REASON = 'Только для текущего погружения';
export const isTransferableFile = (file: NetFile) => file.transferable !== false && !file.session_bound;
export const isCopyableFile = (file: NetFile) => isTransferableFile(file) && file.copyable !== false;
export const fileSizeLabel = (file: NetFile) => file.copy_size !== undefined && file.copy_size !== file.size
  ? `${file.size} · копия ${file.copy_size}` : `${file.size}`;
export const fileSourceLabel = (source?: string) => ({ local: 'Локальная память', shard: 'Шард', session: 'Текущее погружение' })[source ?? ''] || 'Локальная память';
export const visibleFiles = (files: NetFile[], query: string) => {
  const term = query.trim().toLocaleLowerCase('ru');
  return files.filter((file) => !term || `${file.name} ${file.kind} ${fileSearchLabel(file.kind)}`.toLocaleLowerCase('ru').includes(term))
    .sort((a, b) => a.name.localeCompare(b.name, 'ru', { numeric: true, sensitivity: 'base' }) || a.uid.localeCompare(b.uid));
};

/** Compatibility admission for older payloads; current selected files include server decisions. */
export const fileTransferState = (file: NetFile, destination?: Storage | null) => {
  const merge = file.kind === 'grants' && !!destination?.files?.some((entry) => entry.kind === 'grants');
  let reason: string | null = null;
  if (!isTransferableFile(file)) { reason = file.transfer_reason || SESSION_FILE_REASON; }
  else if (!destination) { reason = 'Носитель назначения недоступен.'; }
  else if (destination.capacity <= 0) { reason = 'Носитель назначения доступен только для чтения.'; }
  else if (destination.used > destination.capacity || (!merge && (file.copy_size ?? file.size) > destination.capacity - destination.used)) {
    reason = 'На носителе назначения недостаточно свободной памяти.';
  }
  return { copy: !reason && isCopyableFile(file), move: !reason, reason, merge };
};

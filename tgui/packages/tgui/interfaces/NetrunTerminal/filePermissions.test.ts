import { fileTransferState, isCopyableFile, visibleFiles } from './filePermissions';
import type { NetFile } from './types';

const key: NetFile = { uid: 'key', name: 'key.grants', kind: 'grants', size: 1, preview: null };
test('a full physical medium accepts a merged acquired key but remains read-only at zero capacity', () => {
  const disk = { used: 1, capacity: 1, files: [key] };
  expect(fileTransferState({ ...key, uid: 'new' }, disk)).toEqual({ copy: true, move: true, merge: true, reason: null });
  expect(fileTransferState({ ...key, kind: 'text' }, disk).copy).toBe(false);
  expect(fileTransferState(key, { ...disk, capacity: 0 }).reason).toMatch(/чтения/);
});

test('search matches names and readable types and sorts without mutating server order', () => {
  const files = [{ ...key, uid: 'z', name: 'z10.grants' }, { ...key, uid: 'b', name: 'z2.grants' },
    { ...key, uid: 'a', name: 'agent.bot', kind: 'bot' }];
  expect(visibleFiles(files, 'ключ').map((file) => file.uid)).toEqual(['b', 'z']);
  expect(visibleFiles(files, 'АГЕНТ').map((file) => file.uid)).toEqual(['a']);
  expect(files.map((file) => file.uid)).toEqual(['z', 'b', 'a']);
});

test('copy permission and session transport remain distinct from destination capacity', () => {
  expect(isCopyableFile({ ...key, copyable: false })).toBe(false);
  const result = fileTransferState({ ...key, session_bound: true }, { used: 0, capacity: 10, files: [] });
  expect(result.copy || result.move).toBe(false);
  expect(result.reason).toBe('Только для текущего погружения');
});

import { fileFormat, fileIcon, fileKindLabel, fileSearchLabel, isReadableFile } from './filePresentation';

test('new file kinds retain their identity with neutral presentation and no unsupported viewer action', () => {
  for (const kind of ['new_format', 'constructor', '__proto__']) {
    expect(fileKindLabel(kind)).toBe(kind);
    expect(fileIcon(kind)).toBe('file-lines');
    expect(fileFormat('unnamed', kind)).toBe('DAT');
    expect(fileSearchLabel(kind)).toBe('');
    expect(isReadableFile(kind)).toBe(false);
  }
  expect(fileFormat('record.custom', 'new_format')).toBe('CUSTOM');
});

test('filename extensions override the shared kind format while extensionless files keep readable defaults', () => {
  expect(fileFormat('note.md', 'text')).toBe('MD');
  expect(fileFormat('note', 'text')).toBe('TXT');
  expect(fileFormat('.hidden', 'key')).toBe('KEY');
  expect(fileFormat('image.', 'photo')).toBe('IMG');
});

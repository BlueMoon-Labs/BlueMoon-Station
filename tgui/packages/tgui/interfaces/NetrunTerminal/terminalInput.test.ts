import { completionContext, insertCompletion, matchingCompletions, quoteCliArgument } from './terminalInput';

test('completion follows quoted and escaped filenames rather than splitting on spaces', () => {
  expect(completionContext('exec "My shi').prefix).toBe('My shi');
  expect(completionContext('exec my\\ shi').prefix).toBe('my shi');
  expect(completionContext('rename "My shield.exe" ').argument).toBe(2);
  expect(matchingCompletions('exec "my s', ['My shield.exe', 'Other.exe'])).toEqual(['My shield.exe']);
  expect(insertCompletion('exec "My shi', 'My shield.exe').value).toBe('exec "My shield.exe" ');
});

test('completing in the middle replaces a whole token and preserves following arguments', () => {
  const command = 'exec shiel.exe target-ref';
  const result = insertCompletion(command, 'shield.exe', 'exec sh'.length);
  expect(result.value).toBe('exec shield.exe target-ref');
  expect(result.caret).toBe('exec shield.exe'.length);
  expect(insertCompletion('rename "old name" "new name"', 'actual file.txt', 'rename "old'.length).value)
    .toBe('rename "actual file.txt" "new name"');
});

test('inserted arguments round-trip quote and slash characters without command composition', () => {
  expect(quoteCliArgument('simple.exe')).toBe('simple.exe');
  expect(quoteCliArgument('')).toBe('""');
  expect(quoteCliArgument('a "quote".txt')).toBe('"a \\"quote\\".txt"');
  expect(quoteCliArgument('a\\b')).toBe('"a\\\\b"');
  expect(matchingCompletions('ex', ['exec', 'exec', 'help'])).toEqual(['exec']);
});

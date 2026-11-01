import { KeyboardEvent, memo, useEffect, useRef, useState } from 'react';

import { Box, Button, Icon } from '../../components';
import { completionContext, insertCompletion, matchingCompletions } from './terminalInput';
import { LogLine, NetrunData, THEME } from './types';
import { useFollowOutput } from './useFollowOutput';
import { useNetrunBackend as useBackend } from './useNetrunBackend';

const KIND_COLORS: Record<string, string> = {
  good: THEME.good, bad: THEME.bad, average: THEME.warn, label: THEME.text,
};

const LogLines = memo((props: { lines: LogLine[] }) => (
  <>
    {props.lines.map((line, index) => (
      <div key={index} style={{ color: KIND_COLORS[line.kind] || THEME.text, whiteSpace: 'pre-wrap',
        lineHeight: 1.55, padding: '1px 0', overflowWrap: 'anywhere' }}>
        {!!line.time && <span style={{ color: THEME.muted, marginRight: '8px', opacity: 0.75 }}>{line.time}</span>}
        {line.text}
      </div>
    ))}
  </>
));

const TerminalConsoleView = (props: { active?: boolean } = {}) => {
  const { act, data } = useBackend<NetrunData>(['log', 'cli', 'map', 'view', 'networks', 'window', 'selected', 'storage', 'shard']);
  const latestLine = data.log[data.log.length - 1];
  const output = useFollowOutput(`${data.log.length}:${latestLine?.time}:${latestLine?.text}`, props.active);
  const input = useRef<HTMLInputElement>(null);
  const [value, setValue] = useState('');
  const [history, setHistory] = useState<string[]>([]);
  const [historyIndex, setHistoryIndex] = useState<number | null>(null);
  const [draft, setDraft] = useState('');
  const [searchHistory, setSearchHistory] = useState(false);
  const [showSuggestions, setShowSuggestions] = useState(false);
  const [suggestionIndex, setSuggestionIndex] = useState(0);
  const [caret, setCaret] = useState(0);
  const entries = data.cli?.verbs ?? [];
  const context = completionContext(value, caret);
  const entry = entries.find((candidate) => candidate.id === context.verb);
  const registered = (entry?.completion_key ? data.cli?.completions?.[entry.completion_key] : undefined) ?? entry?.completions ?? [];
  const commands = (data.window?.commands ?? data.selected?.commands ?? []).map((command) => command.id);
  const files = [...(data.storage?.files ?? []), ...(data.shard?.files ?? [])];
  const executableFiles = files.filter((file) => file.kind === 'daemon' || file.kind === 'program').map((file) => file.name);
  const verbs = entries.map((verb) => verb.id);
  const fileVerbs = ['rm', 'cat', 'rename', 'cp', 'mv'];
  const fallback = context.verb === 'run' ? [...commands, ...executableFiles]
    : context.verb === 'exec' ? executableFiles
    : context.verb === 'help' ? [...verbs, ...commands]
    : fileVerbs.includes(context.verb) ? files.map((file) => file.name)
    : context.verb === 'net' ? (data.networks ?? []).map((network) => network.code)
    : ['sel', 'ping', 'open', 'breach'].includes(context.verb) ? (data.map?.nodes ?? data.view?.nodes ?? []).map((node) => node.address) : [];
  const pool = context.argument === 0 ? verbs
    : context.argument === 2 && ['cp', 'mv'].includes(context.verb) ? ['local', 'shard']
    : context.argument > 1 ? [] : [...registered, ...fallback];
  const suggestions = searchHistory
    ? [...history].reverse().filter((command) => command.toLowerCase().includes(value.toLowerCase())).slice(0, 6)
    : matchingCompletions(value, pool, caret).slice(0, 6);

  useEffect(() => {
    if (props.active && !document.activeElement?.closest('[role="tablist"]')) { input.current?.focus(); }
  }, [props.active]);

  const replaceInput = (text: string, position = text.length) => {
    setValue(text); setCaret(position);
    requestAnimationFrame(() => { input.current?.focus(); input.current?.setSelectionRange(position, position); });
  };
  const execute = (text: string) => {
    text = text.trim();
    if (!text) { return; }
    output.handleFollowLatest();
    act('cli', { text });
    setHistory((previous) => (previous[previous.length - 1] === text ? previous : [...previous, text]).slice(-50));
    setHistoryIndex(null); setDraft(''); setSearchHistory(false); setShowSuggestions(false); replaceInput('');
  };
  const chooseSuggestion = (candidate: string) => {
    if (searchHistory) { replaceInput(candidate); setSearchHistory(false); }
    else { const result = insertCompletion(value, candidate, caret); replaceInput(result.value, result.caret); }
    setShowSuggestions(false); setSuggestionIndex(0);
  };
  const navigateHistory = (direction: number) => {
    if (!history.length) { return; }
    if (historyIndex === null) { setDraft(value); }
    const next = historyIndex === null ? history.length - 1 : Math.max(0, historyIndex + direction);
    if (next >= history.length) { setHistoryIndex(null); replaceInput(draft); }
    else { setHistoryIndex(next); replaceInput(history[next]); }
    setShowSuggestions(false);
  };
  const onKeyDown = (event: KeyboardEvent<HTMLInputElement>) => {
    if (event.ctrlKey && ['l', 'u', 'r'].includes(event.key.toLowerCase())) {
      event.preventDefault();
      if (event.key.toLowerCase() === 'l') { act('cli', { text: 'clear' }); }
      if (event.key.toLowerCase() === 'u') { replaceInput(''); }
      if (event.key.toLowerCase() === 'r') { setSearchHistory((previous) => !previous); setShowSuggestions(true); setSuggestionIndex(0); }
      return;
    }
    switch (event.key) {
      case 'Enter':
        event.preventDefault();
        if (searchHistory && !suggestions.length) { break; }
        if ((showSuggestions || searchHistory) && suggestions.length) { chooseSuggestion(suggestions[suggestionIndex % suggestions.length]); }
        else { execute(value); }
        break;
      case 'ArrowUp':
      case 'ArrowDown':
        event.preventDefault();
        if ((showSuggestions || searchHistory) && suggestions.length) {
          setSuggestionIndex((previous) => (previous + (event.key === 'ArrowUp' ? -1 : 1) + suggestions.length) % suggestions.length);
        } else { navigateHistory(event.key === 'ArrowUp' ? -1 : 1); }
        break;
      case 'Tab':
        event.preventDefault();
        if (suggestions.length === 1) { chooseSuggestion(suggestions[0]); }
        else if (suggestions.length) { setShowSuggestions(true); setSuggestionIndex((previous) => showSuggestions ? (previous + (event.shiftKey ? -1 : 1) + suggestions.length) % suggestions.length : 0); }
        break;
      case 'Escape':
        event.preventDefault(); setShowSuggestions(false); setSearchHistory(false); input.current?.focus();
        break;
    }
  };

  return (
    <Box data-net-layout="console" style={{ background: THEME.bg, border: `1px solid ${THEME.line}`, borderRadius: '8px',
      display: 'flex', flexDirection: 'column', height: '100%', width: '100%', minHeight: 0, overflow: 'hidden', boxSizing: 'border-box' }}>
      <Box p={0.75} style={{ borderBottom: `1px solid ${THEME.line}`, display: 'flex', flexWrap: 'wrap', alignItems: 'center', gap: '6px' }}>
        <Icon name="terminal" color={THEME.accent} />
        <Box bold style={{ flex: '1 1 auto', fontFamily: 'monospace', fontSize: '11px' }}>COMMAND SHELL</Box>
        {['help', 'info', 'ls', 'mem'].map((command) => (
          <Button key={command} compact color="transparent" content={command} onClick={() => execute(command)} />
        ))}
        <Button compact icon="eraser" tooltip="Очистить вывод · Ctrl+L" onClick={() => act('cli', { text: 'clear' })} />
      </Box>
      <div ref={output.scroller} onScroll={output.handleScroll} aria-label="Журнал терминала"
        style={{ flex: '1 1 auto', minHeight: '70px', overflowY: 'auto', padding: '10px 12px', fontFamily: 'monospace', fontSize: '12px', userSelect: 'text' }}>
        {!data.log.length && <Box color={THEME.muted}>Терминал готов. help — команды, ls — файлы, Tab — дополнение.</Box>}
        <LogLines lines={data.log} />
      </div>
      {!!output.unread && <Button compact icon="arrow-down" content="К новым сообщениям" onClick={output.handleFollowLatest} />}
      {(showSuggestions || searchHistory) && (
        <Box p={0.75} style={{ borderTop: `1px solid ${THEME.line}`, background: THEME.panel }}>
          <Box color={THEME.muted} fontSize="10px" mb={0.5}>{searchHistory ? 'ПОИСК В ИСТОРИИ' : 'ДОПОЛНЕНИЕ'} · ↑/↓ выбор · Enter вставить · Esc закрыть</Box>
          {!suggestions.length && <Box color={THEME.muted}>Совпадений нет.</Box>}
          {suggestions.map((candidate, index) => (
            <Button key={candidate} fluid compact ellipsis selected={index === suggestionIndex % suggestions.length}
              style={{ textAlign: 'left', fontFamily: 'monospace', margin: '2px 0' }} content={candidate}
              onClick={() => chooseSuggestion(candidate)} />
          ))}
        </Box>
      )}
      <Box p={0.5} px={1} color={THEME.muted} fontSize="10px" style={{ borderTop: `1px solid ${THEME.line}`, minHeight: '24px' }}>
        {entry ? <><Box inline bold color={THEME.accent}>{entry.id} {entry.args}</Box>{' · '}{entry.desc}</>
          : 'Tab — дополнение · ↑/↓ история · Ctrl+R поиск · Ctrl+L очистить · имена с пробелами: "Мой демон.exe"'}
      </Box>
      <div style={{ display: 'flex', gap: '8px', alignItems: 'center', background: THEME.panel, padding: '8px 10px' }}>
        <span aria-hidden="true" style={{ color: THEME.accent, fontFamily: 'monospace', flexShrink: 0 }}>{searchHistory ? '?' : '$'}</span>
        <input ref={input} aria-label="Командная строка" value={value} onChange={(event) => {
          setValue(event.target.value); setCaret(event.target.selectionStart ?? event.target.value.length); setHistoryIndex(null); setSuggestionIndex(0);
        }} onSelect={(event) => setCaret(event.currentTarget.selectionStart ?? value.length)} onKeyDown={onKeyDown}
        placeholder={searchHistory ? 'Найти команду в истории…' : 'Введите команду…'} spellCheck={false} autoComplete="off" maxLength={512}
        style={{ flex: '1 1 0', minWidth: 0, fontFamily: 'monospace', fontSize: '13px', color: THEME.text,
          background: 'transparent', border: 'none', outline: 'none' }} />
        <Button compact icon="arrow-turn-down" tooltip="Выполнить · Enter" disabled={!value.trim()} onClick={() => execute(value)} />
      </div>
    </Box>
  );
};

export const ConsoleLog = memo(TerminalConsoleView);

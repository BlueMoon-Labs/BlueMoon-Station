import { useEffect, useMemo, useRef, useState } from 'react';

import { useBackend } from '../../backend';
import { Box, Button, Dropdown, Icon, Input, NoticeBox, Section, Stack, Table } from '../../components';
import { Window } from '../../layouts';
import { formatBytes, parseCsv, splitByMatches } from './helpers';

const SEARCH_HIGHLIGHT_CAP = 2000;

export type LogEntry = {
  name: string;
  isDir: boolean;
  size: number;
  mtime: number;
};

export type LogFileState = {
  name: string;
  size: number;
  pageStart: number;
  pageEnd: number;
  pageNum: number;
  pageCount: number;
  pageBytes: number;
  content: string;
  tailAvailable: boolean;
  tailActive: boolean;
};

// Согласован с белым списком set_page_size на сервере; 0 = весь файл.
const PAGE_SIZE_OPTIONS: { label: string; value: number }[] = [
  { label: '256 КиБ', value: 256 * 1024 },
  { label: '1 МиБ', value: 1024 * 1024 },
  { label: '4 МиБ', value: 4 * 1024 * 1024 },
  { label: 'Весь файл', value: 0 },
];

export type LogViewerData = {
  crumbs: string[];
  entries: LogEntry[];
  canArchive: boolean;
  osUnix: boolean;
  file: LogFileState | null;
  searchResults: { line: number; offset: number; preview: string }[] | null;
  searchQuery: string;
};

const entryIcon = (entry: LogEntry): string => {
  if (entry.isDir) {
    return entry.name.startsWith('round-') ? 'box-archive' : 'folder';
  }
  if (entry.name.endsWith('.json')) {
    return 'code';
  }
  if (entry.name.endsWith('.csv')) {
    return 'table';
  }
  if (entry.name.endsWith('.html') || entry.name.endsWith('.htm')) {
    return 'globe';
  }
  return 'file-lines';
};

const Crumbs = (props) => {
  const { act, data } = useBackend<LogViewerData>();
  return (
    <Box mb={1} style={{ wordWrap: 'break-word' }}>
      <Button compact icon="server" onClick={() => act('crumb', { index: 0 })}>
        логи
      </Button>
      {data.crumbs.map((crumb, i) => (
        <Box as="span" key={i}>
          {' / '}
          <Button compact onClick={() => act('crumb', { index: i + 1 })}>
            {crumb}
          </Button>
        </Box>
      ))}
    </Box>
  );
};

type SortKey = 'name' | 'size' | 'mtime';

const FileList = (props) => {
  const { act, data } = useBackend<LogViewerData>();
  const [sortKey, setSortKey] = useState<SortKey>('name');
  const [sortAsc, setSortAsc] = useState(true);
  const [selected, setSelected] = useState<string[]>([]);

  // Смена каталога обнуляет выбор - имена другого каталога не имеют смысла.
  const crumbsKey = data.crumbs.join('/');
  useEffect(() => setSelected([]), [crumbsKey]);

  const sorted = useMemo(() => {
    const factor = sortAsc ? 1 : -1;
    const compare = (a: LogEntry, b: LogEntry) => {
      if (a.isDir !== b.isDir) {
        return a.isDir ? -1 : 1;
      }
      if (sortKey === 'name') {
        return factor * a.name.localeCompare(b.name);
      }
      return factor * ((a[sortKey] ?? 0) - (b[sortKey] ?? 0));
    };
    return [...data.entries].sort(compare);
  }, [data.entries, sortKey, sortAsc]);

  // Листинг мог обновиться под выбором - серверу шлём только всё ещё существующие имена.
  const fileNames = data.entries
    .filter((entry) => !entry.isDir)
    .map((entry) => entry.name);
  const validSelected = selected.filter((name) => fileNames.includes(name));
  const totalSize = data.entries
    .filter((entry) => validSelected.includes(entry.name))
    .reduce((sum, entry) => sum + Math.max(entry.size, 0), 0);
  const allSelected =
    fileNames.length > 0 && validSelected.length === fileNames.length;

  const toggleName = (name: string) =>
    setSelected((prev) =>
      prev.includes(name) ? prev.filter((n) => n !== name) : [...prev, name],
    );

  if (!data.entries.length) {
    return <NoticeBox info>Каталог пуст</NoticeBox>;
  }
  return (
    <>
      <Box mb={0.5}>
        {fileNames.length > 0 && (
          <Button
            compact
            icon={
              allSelected
                ? 'square-check'
                : validSelected.length
                  ? 'square-minus'
                  : 'square'
            }
            tooltip={allSelected ? 'Снять выбор' : 'Выбрать все файлы'}
            onClick={() => setSelected(allSelected ? [] : fileNames)}
          />
        )}
        {(
          [
            ['name', 'Имя'],
            ['size', 'Размер'],
            ['mtime', 'Дата'],
          ] as [SortKey, string][]
        ).map(([key, label]) => (
          <Button
            compact
            icon={sortKey === key ? (sortAsc ? 'caret-up' : 'caret-down') : undefined}
            key={key}
            selected={sortKey === key}
            onClick={() => {
              if (sortKey === key) {
                setSortAsc(!sortAsc);
              } else {
                setSortKey(key);
                setSortAsc(true);
              }
            }}>
            {label}
          </Button>
        ))}
      </Box>
      {validSelected.length > 0 && (
        <Button
          color="good"
          fluid
          icon="download"
          mb={0.5}
          tooltip="Один файл придёт как есть, несколько - одним архивом"
          onClick={() => act('download_selected', { names: validSelected })}>
          Скачать выбранные ({validSelected.length}, {formatBytes(totalSize)})
        </Button>
      )}
      {sorted.map((entry) => (
        <Box
          key={entry.name}
          className={
            'AdminLogViewer__entry' +
            (data.file?.name === entry.name ? ' AdminLogViewer__entry--active' : '')
          }
          onClick={() =>
            entry.isDir
              ? act('navigate', { name: entry.name })
              : act('open_file', { name: entry.name })
          }>
          {!entry.isDir && (
            <Button
              compact
              icon={
                validSelected.includes(entry.name) ? 'square-check' : 'square'
              }
              mr={0.5}
              onClick={(e) => {
                e.stopPropagation();
                toggleName(entry.name);
              }}
            />
          )}
          <Icon mr={1} name={entryIcon(entry)} color={entry.isDir ? 'yellow' : 'label'} />
          {entry.name}
          {!entry.isDir && (
            <>
              {entry.mtime > 0 && (
                <Box as="span" className="AdminLogViewer__entry-size">
                  {new Date(entry.mtime * 1000).toLocaleString('ru-RU', {
                    day: '2-digit',
                    month: '2-digit',
                    hour: '2-digit',
                    minute: '2-digit',
                  })}
                </Box>
              )}
              <Box as="span" className="AdminLogViewer__entry-size">
                {formatBytes(entry.size)}
              </Box>
            </>
          )}
        </Box>
      ))}
    </>
  );
};

const Pager = (props) => {
  const { act, data } = useBackend<LogViewerData>();
  const file = data.file!;
  return (
    <>
      <Button
        disabled={file.pageStart <= 0}
        icon="angles-left"
        onClick={() => act('page', { dir: 'first' })}
      />
      <Button
        disabled={file.pageStart <= 0}
        icon="angle-left"
        onClick={() => act('page', { dir: 'prev' })}
      />
      <Box as="span" mx={0.5}>
        {file.pageNum} / {file.pageCount}
      </Box>
      <Button
        disabled={file.pageEnd >= file.size}
        icon="angle-right"
        onClick={() => act('page', { dir: 'next' })}
      />
      <Button
        disabled={file.pageEnd >= file.size}
        icon="angles-right"
        onClick={() => act('page', { dir: 'last' })}
      />
    </>
  );
};

const ViewerContent = (props: {
  content: string;
  clientQuery: string;
  activeMatch: number;
  wrap: boolean;
}) => {
  const { content, clientQuery, activeMatch, wrap } = props;
  const { segments } = splitByMatches(content, clientQuery, SEARCH_HIGHLIGHT_CAP);
  let matchIndex = -1;
  return (
    <Box
      className={
        'AdminLogViewer__content' + (wrap ? '' : ' AdminLogViewer__content--nowrap')
      }>
      {segments.map((segment, i) => {
        if (!segment.match) {
          return segment.text;
        }
        matchIndex += 1;
        return (
          <mark
            className={matchIndex === activeMatch ? 'AdminLogViewer__match--active' : undefined}
            id={matchIndex === activeMatch ? 'AdminLogViewer__active-match' : undefined}
            key={i}>
            {segment.text}
          </mark>
        );
      })}
    </Box>
  );
};

type RenderMode = 'text' | 'json' | 'csv';

const Viewer = (props) => {
  const { act, data } = useBackend<LogViewerData>();
  const file = data.file;
  const [clientQuery, setClientQuery] = useState('');
  const [activeMatch, setActiveMatch] = useState(0);
  const [renderMode, setRenderMode] = useState<RenderMode>('text');
  const [wrap, setWrap] = useState(true);
  const { count } = splitByMatches(file?.content ?? '', clientQuery, SEARCH_HIGHLIGHT_CAP);
  const contentRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    if (file?.tailActive) {
      return;
    }
    document
      .getElementById('AdminLogViewer__active-match')
      ?.scrollIntoView({ block: 'center' });
  }, [activeMatch, clientQuery, file?.pageStart, file?.tailActive]);

  // Смена страницы или файла меняет число совпадений - индекс активного сбрасываем.
  useEffect(() => {
    setActiveMatch(0);
  }, [file?.name, file?.pageStart]);

  // Смена файла сбрасывает режим отображения - JSON/CSV-режим одного файла
  // не должен навязываться следующему.
  useEffect(() => setRenderMode('text'), [file?.name]);

  // В режиме tail новый контент дописывается снизу - держим прокрутку у последней строки.
  useEffect(() => {
    if (file?.tailActive && contentRef.current) {
      const scrollable = contentRef.current.closest('.Section__content');
      if (scrollable) {
        scrollable.scrollTop = scrollable.scrollHeight;
      }
    }
  }, [file?.pageEnd, file?.tailActive]);

  if (!file) {
    return (
      <Section fill>
        <Stack align="center" fill justify="center" vertical>
          <Stack.Item>
            <Icon color="gray" name="file-circle-question" size={3} />
          </Stack.Item>
          <Stack.Item color="gray">Файл не выбран</Stack.Item>
        </Stack>
      </Section>
    );
  }

  const jsonAvailable = file.name.endsWith('.json');
  const csvAvailable = file.name.endsWith('.csv');

  let renderedJson: string | null = null;
  if (renderMode === 'json') {
    try {
      renderedJson = JSON.stringify(JSON.parse(file.content), null, 2);
    } catch {
      renderedJson = null;
    }
  }

  // Подсветка живёт только в ViewerContent - в CSV-таблице и форматированном JSON контролы поиска скрываем.
  const searchUsable = renderMode === 'text' || (renderMode === 'json' && renderedJson === null);

  return (
    <Stack fill vertical>
      <Stack.Item>
        <Section
          buttons={
            <>
              <Button
                icon="download"
                tooltip="Скачать файл"
                onClick={() => act('download_file')}
              />
              <Button icon="xmark" tooltip="Закрыть файл" onClick={() => act('close_file')} />
            </>
          }
          title={`${file.name} (${formatBytes(file.size)})`}>
          {/* контролы отдельной строкой: панель кнопок секции не умеет переноситься,
              а блочный Dropdown в ней ломает строку и наезжает на содержимое */}
          {searchUsable && (
            <>
              <Input
                placeholder="Поиск на странице..."
                value={clientQuery}
                width="14em"
                onChange={(e, value) => {
                  setClientQuery(value);
                  setActiveMatch(0);
                }}
              />
              <Box as="span" color={count ? 'label' : 'bad'} mx={0.5}>
                {clientQuery ? `${count ? activeMatch + 1 : 0} из ${count}` : ''}
              </Box>
              <Button
                disabled={!count}
                icon="chevron-up"
                onClick={() => setActiveMatch((activeMatch - 1 + count) % count)}
              />
              <Button
                disabled={!count}
                icon="chevron-down"
                onClick={() => setActiveMatch((activeMatch + 1) % count)}
              />
              <Button
                disabled={!clientQuery || clientQuery.length < 2}
                icon="magnifying-glass"
                mr={1}
                tooltip="Искать по всему файлу (на сервере)"
                onClick={() => act('search_file', { query: clientQuery })}
              />
            </>
          )}
          <Box inline mr={1}>
            <Dropdown
              displayText={
                (PAGE_SIZE_OPTIONS.find((o) => o.value === file.pageBytes) ??
                  PAGE_SIZE_OPTIONS[0]).label
              }
              options={PAGE_SIZE_OPTIONS.map((o) => o.label)}
              width="8em"
              onSelected={(label) => {
                const option = PAGE_SIZE_OPTIONS.find((o) => o.label === label);
                if (option) {
                  act('set_page_size', { size: option.value });
                }
              }}
            />
          </Box>
          <Pager />
          {file.tailAvailable && (
            <Button
              icon="satellite-dish"
              selected={file.tailActive}
              tooltip="Следить за файлом (автообновление хвоста)"
              onClick={() => act('toggle_tail')}
            />
          )}
          {jsonAvailable && (
            <Button
              icon="code"
              selected={renderMode === 'json'}
              tooltip="Форматировать JSON"
              onClick={() => setRenderMode(renderMode === 'json' ? 'text' : 'json')}
            />
          )}
          {csvAvailable && (
            <Button
              icon="table"
              selected={renderMode === 'csv'}
              tooltip="Показать как таблицу"
              onClick={() => setRenderMode(renderMode === 'csv' ? 'text' : 'csv')}
            />
          )}
          <Button
            icon="align-left"
            selected={wrap}
            tooltip="Перенос строк"
            onClick={() => setWrap(!wrap)}
          />
        </Section>
      </Stack.Item>
      {data.searchResults && (
        <Stack.Item>
          <Section
            buttons={<Button icon="xmark" onClick={() => act('clear_search')} />}
            title={`Совпадений по файлу: ${data.searchResults.length}${
              data.searchResults.length >= 500 ? ' (обрезано)' : ''
            }`}>
            <Box maxHeight="150px" overflowY="auto">
              {data.searchResults.map((result, i) => (
                <Box
                  className="AdminLogViewer__entry"
                  key={i}
                  onClick={() => act('goto_offset', { offset: result.offset })}>
                  <Box as="span" color="label" mr={1}>
                    {result.line}:
                  </Box>
                  {result.preview}
                </Box>
              ))}
            </Box>
          </Section>
        </Stack.Item>
      )}
      <Stack.Item grow>
        <Section fill scrollable>
          <div ref={contentRef}>
            {renderMode === 'csv' ? (
              <Table
                className={
                  'AdminLogViewer__content' + (wrap ? '' : ' AdminLogViewer__content--nowrap')
                }>
                {parseCsv(file.content).map((row, i) => (
                  // Заголовок CSV есть только в начале файла - на следующих страницах первая строка это данные
                  <Table.Row header={i === 0 && file.pageStart === 0} key={i}>
                    {row.map((cell, j) => (
                      <Table.Cell key={j}>{cell}</Table.Cell>
                    ))}
                  </Table.Row>
                ))}
              </Table>
            ) : renderMode === 'json' && renderedJson !== null ? (
              <Box
                className={
                  'AdminLogViewer__content' + (wrap ? '' : ' AdminLogViewer__content--nowrap')
                }>
                {renderedJson}
              </Box>
            ) : (
              <ViewerContent
                activeMatch={activeMatch}
                clientQuery={clientQuery}
                content={file.content}
                wrap={wrap}
              />
            )}
            {renderMode === 'json' && renderedJson === null && (
              <NoticeBox danger>Не удалось разобрать JSON (файл обрезан страницей?)</NoticeBox>
            )}
          </div>
        </Section>
      </Stack.Item>
    </Stack>
  );
};

export const AdminLogViewer = (props) => {
  const { act, data } = useBackend<LogViewerData>();
  const isRoundDir = (data.crumbs[data.crumbs.length - 1] ?? '').startsWith(
    'round-',
  );
  return (
    <Window height={700} theme="admin" title="Журнал сервера" width={1150}>
      <Window.Content>
        <Stack fill>
          <Stack.Item width="330px">
            <Section
              buttons={
                <Button icon="rotate" tooltip="Обновить" onClick={() => act('refresh')} />
              }
              fill
              scrollable
              title="Навигация">
              <Button fluid icon="satellite-dish" mb={1} onClick={() => act('go_current_round')}>
                Текущий раунд
              </Button>
              {data.canArchive && (
                <Button
                  color="good"
                  fluid
                  icon="file-zipper"
                  mb={1}
                  tooltip={
                    isRoundDir
                      ? 'Скачать все логи этого раунда одним архивом'
                      : 'Скачать этот каталог со всеми подпапками одним архивом - например, логи за день или месяц'
                  }
                  onClick={() => act('download_archive')}>
                  {isRoundDir ? 'Скачать раунд архивом' : 'Скачать каталог архивом'}
                </Button>
              )}
              <Crumbs />
              <FileList />
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <Viewer />
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

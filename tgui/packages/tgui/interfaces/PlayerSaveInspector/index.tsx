import { BooleanLike } from 'common/react';
import { useEffect, useMemo, useState } from 'react';

import { useBackend } from '../../backend';
import { Box, Button, Input, NoticeBox, Section, Stack } from '../../components';
import { Window } from '../../layouts';
import {
  fileLabel,
  filterLines,
  formatSize,
  groupFiles,
  MAX_FILTERED_LINES,
  prettyJson,
  readableSave,
  SaveFile,
  SaveGroup,
} from './helpers';

export type PlayerSaveInspectorData = {
  ckey: string | null;
  files: SaveFile[];
  default_slot: number | null;
  selected: string | null;
  preview: string | null;
  preview_error: string | null;
  preview_truncated: BooleanLike;
  message: string | null;
};

type ViewMode = 'readable' | 'json' | 'raw';

const FileRow = (props: { file: SaveFile; selected: boolean }) => {
  const { act } = useBackend();
  const { file, selected } = props;
  return (
    <Stack align="center" className="PlayerSaveInspector__file" mb={0.5}>
      <Stack.Item grow>
        <Button fluid selected={selected} icon={file.recovery ? 'history' : 'file'} tooltip={file.path} onClick={() => act('view', { path: file.path })}>
          {fileLabel(file)}
        </Button>
      </Stack.Item>
      <Stack.Item color="label" width="6em" textAlign="right">
        {formatSize(file.size)}
      </Stack.Item>
      <Stack.Item>
        <Button icon="download" tooltip="Скачать исходник" onClick={() => act('download', { path: file.path })} />
      </Stack.Item>
    </Stack>
  );
};

const GroupBlock = (props: { group: SaveGroup; selected: string | null }) => {
  const { act } = useBackend();
  const { group, selected } = props;
  return (
    <Box mb={1.5}>
      <Stack align="center" mb={0.5}>
        <Stack.Item grow bold color={group.active ? 'good' : undefined}>
          {group.title}
          {group.active && (
            <Box as="span" color="label" ml={1}>
              (активный)
            </Box>
          )}
        </Stack.Item>
        {group.slot !== null && (
          <Stack.Item>
            <Button
              compact
              icon="file-archive"
              tooltip="Раздел слота вместе с корнем аккаунта и его откатом, одним JSON"
              onClick={() => act('download_bundle', { slot: group.slot })}
            >
              Слот целиком
            </Button>
          </Stack.Item>
        )}
      </Stack>
      {group.files.map((file) => (
        <FileRow key={file.path} file={file} selected={file.path === selected} />
      ))}
    </Box>
  );
};

const Preview = (props: { data: PlayerSaveInspectorData }) => {
  const { data } = props;
  const [mode, setMode] = useState<ViewMode>('readable');
  const [search, setSearch] = useState('');
  const readable = useMemo(() => readableSave(data.preview), [data.preview]);
  const pretty = useMemo(() => prettyJson(data.preview), [data.preview]);
  const text = (mode === 'readable' && readable) || (mode !== 'raw' && pretty) || data.preview || '';
  const shownMode: ViewMode = text === readable ? 'readable' : text === pretty ? 'json' : 'raw';
  const filtered = useMemo(() => (search.trim() ? filterLines(text, search) : null), [text, search]);

  if (!data.selected) {
    return <NoticeBox info>Выберите файл слева. Удобочитаемый вид раскрывает обёртки type/items JSON-сейва.</NoticeBox>;
  }
  return (
    <Section
      fill
      scrollable
      title={data.selected}
      buttons={
        <Stack align="center">
          <Stack.Item>
            <Button selected={shownMode === 'readable'} disabled={!readable} onClick={() => setMode('readable')}>
              Читаемо
            </Button>
            <Button selected={shownMode === 'json'} disabled={!pretty} onClick={() => setMode('json')}>
              JSON
            </Button>
            <Button selected={shownMode === 'raw'} onClick={() => setMode('raw')}>
              Как на диске
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Input width="14em" placeholder="Найти строки..." value={search} onInput={(_, value: string) => setSearch(value)} />
          </Stack.Item>
        </Stack>
      }
    >
      {!!data.preview_error && <NoticeBox danger>{data.preview_error}</NoticeBox>}
      {!!data.preview_truncated && <NoticeBox>Показан первый 1 МиБ. Целиком файл доступен через скачивание.</NoticeBox>}
      {filtered ? (
        <>
          <Box color="label" mb={1}>
            Совпадений: {filtered.total}
            {filtered.total > MAX_FILTERED_LINES && `, показаны первые ${MAX_FILTERED_LINES}`}
          </Box>
          <Box as="pre" className="PlayerSaveInspector__preview" style={{ whiteSpace: 'pre-wrap', wordBreak: 'break-all', margin: 0 }}>
            {filtered.found.map((entry) => (
              <div key={entry.line}>
                <Box as="span" color="label" mr={1}>
                  {entry.line}:
                </Box>
                {entry.text}
              </div>
            ))}
          </Box>
        </>
      ) : (
        <Box as="pre" className="PlayerSaveInspector__preview" style={{ whiteSpace: 'pre-wrap', wordBreak: 'break-all', margin: 0 }}>
          {text}
        </Box>
      )}
    </Section>
  );
};

export const PlayerSaveInspector = () => {
  const { act, data } = useBackend<PlayerSaveInspectorData>();
  const [ckeyDraft, setCkeyDraft] = useState(data.ckey || '');
  const [filter, setFilter] = useState('');
  useEffect(() => setCkeyDraft(data.ckey || ''), [data.ckey]);
  const files = data.files || [];
  const groups = useMemo(() => groupFiles(files, data.default_slot, filter), [files, data.default_slot, filter]);
  const total = files.reduce((sum, file) => sum + file.size, 0);
  const activeCharacter = files.find((file) => file.slot === data.default_slot && file.character)?.character;
  const open = (value = ckeyDraft) => value.trim() && act('open', { ckey: value });

  return (
    <Window width={1150} height={720} title="Сейвы игрока">
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            <Section>
              <Stack align="center">
                <Stack.Item color="label">ckey</Stack.Item>
                <Stack.Item grow>
                  <Input
                    fluid
                    autoFocus={!data.ckey}
                    placeholder="ckey игрока; присутствие на сервере не требуется"
                    value={ckeyDraft}
                    onInput={(_, value: string) => setCkeyDraft(value)}
                    onEnter={(_, value: string) => open(value)}
                  />
                </Stack.Item>
                <Stack.Item>
                  <Button icon="folder-open" disabled={!ckeyDraft.trim()} onClick={() => open()}>
                    Открыть
                  </Button>
                  <Button icon="sync" tooltip="Перечитать файлы с диска" disabled={!data.ckey} onClick={() => act('refresh')} />
                  <Button icon="file-archive" disabled={!files.length} tooltip="Все файлы игрока одним JSON; старые .sav внутри - текстом ExportText" onClick={() => act('download_bundle')}>
                    Скачать всё
                  </Button>
                </Stack.Item>
              </Stack>
              {!!data.ckey && !!files.length && (
                <Box color="label" mt={1}>
                  {files.length} файлов, {formatSize(total)}
                  {data.default_slot !== null && `; активный слот ${data.default_slot}`}
                  {!!activeCharacter && ` (${activeCharacter})`}. Несохранённые изменения из меню здесь не видны.
                </Box>
              )}
              {!!data.message && (
                <NoticeBox mt={1} mb={0}>
                  {data.message}
                </NoticeBox>
              )}
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <Stack fill>
              <Stack.Item width="40%">
                <Section
                  fill
                  scrollable
                  title="Файлы"
                  buttons={<Input width="12em" placeholder="Имя, слот, файл..." value={filter} onInput={(_, value: string) => setFilter(value)} />}
                >
                  {!data.ckey && <NoticeBox info>Введите ckey игрока.</NoticeBox>}
                  {!!data.ckey && !groups.length && <NoticeBox>{files.length ? 'Ничего не найдено.' : 'Файлов нет.'}</NoticeBox>}
                  {groups.map((group) => (
                    <GroupBlock key={group.id} group={group} selected={data.selected} />
                  ))}
                </Section>
              </Stack.Item>
              <Stack.Item grow basis={0}>
                <Preview key={data.selected || ''} data={data} />
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

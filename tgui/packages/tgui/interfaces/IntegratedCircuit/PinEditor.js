import { useEffect, useState } from 'react';

import { useBackend } from '../../backend';
import {
  Box,
  Button,
  Dropdown,
  Input,
  Modal,
  Section,
  Stack,
  TextArea,
} from '../../components';
import { byondListToArray } from './byondPayload';

const LIST_KINDS = [
  'string',
  'number',
  'boolean',
  'null',
];

const KIND_LABEL = {
  string: 'текст',
  number: 'число',
  boolean: 'bool',
  null: 'null',
  ref: 'ref',
  list: 'list',
  text: 'текст',
};

const ANY_KIND_LABEL = {
  string: 'текст (string)',
  number: 'число (number)',
  boolean: 'bool (boolean)',
  char: 'символ (char)',
  color: 'цвет (color)',
  dir: 'направление (dir)',
  ref: 'референс (ref)',
  list: 'список (list)',
};

const ANY_KINDS = Object.keys(ANY_KIND_LABEL);

/**
 * Нативный редактор значения пина: список (добавить/убрать/передвинуть/очистить,
 * поправить ячейку) или длинный текст (для string/any). Заменяет старый браузерный
 * popup list_pin.dm — удобнее и не зависит от отдельного окна браузера.
 */
export const PinEditor = (props) => {
  const { act, data } = useBackend();
  const editor = data.pin_editor;

  if (!editor) {
    return null;
  }

  const close = () => act('ie_pin_editor_close');

  return (
    <Modal className="PinEditor__modal">
      <Section
        title={`Редактор: ${editor.name}`}
        buttons={(
          <>
            <Button
              icon="download"
              color="transparent"
              tooltip="Скопировать текущее значение пина в память отладчика"
              onClick={() => act('ie_copy_pin_to_debugger')}>
              В отладчик
            </Button>
            <Button
              icon="upload"
              color="transparent"
              tooltip="Вставить в пин память отладчика (скопированное значение, ref или null)"
              onClick={() => act('ie_pin_editor_paste_debugger')}>
              Из отладчика
            </Button>
            <Button
              icon="times"
              color="transparent"
              tooltip="Закрыть"
              onClick={close}
            />
          </>
        )}>
        <Box mb={0.5} className="PinEditor__subtitle">
          Тип: <b>{editor.pin_type || editor.type}</b>
          {' '}
          {editor.is_output ? '(выход)' : '(вход)'}
        </Box>
        {editor.kind === 'list'
          ? (
            <>
              <ListEditor editor={editor} act={act} />
              <AddRowForm act={act} />
              <Box mt={0.5}>
                <NullButton act={act} />
              </Box>
            </>
          )
          : (
            <ValueEditor editor={editor} act={act} />
          )}
      </Section>
    </Modal>
  );
};

const ListEditor = (props) => {
  const { editor, act } = props;
  const rows = byondListToArray(editor.rows);

  if (!rows.length) {
    return (
      <Box className="PinEditor__empty" py={1}>
        Список пуст. Добавьте элемент ниже.
      </Box>
    );
  }

  return (
    <Box className="PinEditor__list">
      <Box
        className="PinEditor__listHeader"
        font-size="0.78rem"
        opacity={0.6}
        mb={0.25}>
        Элементов: <b>{editor.length}</b>
      </Box>
      <Box
        className="PinEditor__listScroll"
        maxHeight="22rem"
        overflowY="auto"
        pr={0.5}>
        <Stack vertical>
          {rows.map((row) => (
            <ListRow
              key={`${row.index}-${row.display}`}
              row={row}
              act={act}
            />
          ))}
        </Stack>
      </Box>
      <Box mt={0.5}>
        <Button
          icon="trash"
          color="bad"
          onClick={() => act('ie_list_edit', { edit_action: 'clear' })}>
          Очистить список
        </Button>
      </Box>
    </Box>
  );
};

const ListRow = (props) => {
  const { row, act } = props;
  const editable = row.kind === 'string' || row.kind === 'number'
    || row.kind === 'boolean' || row.kind === 'null' || row.kind === 'text';

  return (
    <Stack className="PinEditor__row" align="center">
      <Stack.Item width="2.4rem">
        <Box textAlign="right" opacity={0.55} className="PinEditor__idx">
          #{row.index}
        </Box>
      </Stack.Item>
      <Stack.Item width="3.6rem">
        <Box className="PinEditor__kind" textAlign="center">
          {KIND_LABEL[row.kind] || row.kind}
        </Box>
      </Stack.Item>
      <Stack.Item grow={1}>
        {editable
          ? (
            <EditCell row={row} act={act} />
          )
          : (
            <Box className="PinEditor__display">
              {row.display ?? (row.kind === 'ref' ? 'ref' : '')}
            </Box>
          )}
      </Stack.Item>
      <Stack.Item>
        <Button
          icon="arrow-up"
          compact
          color="transparent"
          tooltip="Выше"
          onClick={() => act('ie_list_edit', {
            edit_action: 'move',
            index: row.index,
            text: '-1',
          })}
        />
      </Stack.Item>
      <Stack.Item>
        <Button
          icon="arrow-down"
          compact
          color="transparent"
          tooltip="Ниже"
          onClick={() => act('ie_list_edit', {
            edit_action: 'move',
            index: row.index,
            text: '1',
          })}
        />
      </Stack.Item>
      <Stack.Item>
        <Button
          icon="times"
          compact
          color="transparent"
          tooltip="Удалить"
          onClick={() => act('ie_list_edit', {
            edit_action: 'remove',
            index: row.index,
          })}
        />
      </Stack.Item>
    </Stack>
  );
};

const EditCell = (props) => {
  const { row, act } = props;
  const initial = row.kind === 'null' ? '' : String(row.display);
  const commit = (value) => {
    act('ie_list_edit', {
      edit_action: 'set',
      index: row.index,
      kind: row.kind,
      text: value,
    });
  };
  return (
    <Input
      fluid
      placeholder={row.kind}
      value={initial}
      defaultValue={initial}
      onEnter={(e, value) => commit(value)}
      onBlur={(e) => {
        const val = e.target.value;
        if (val !== initial) {
          commit(val);
        }
      }}
    />
  );
};

const AddRowForm = (props) => {
  const { act } = props;
  const [addKind, setAddKind] = useState('string');
  const [localText, setLocalText] = useState('');

  const add = () => {
    act('ie_list_edit', {
      edit_action: 'add',
      kind: addKind,
      text: localText,
    });
    setLocalText('');
  };

  const kindOptions = LIST_KINDS.map((k) => KIND_LABEL[k] || k);

  return (
    <Section title="Добавить элемент" mt={0.75}>
      <Stack align="center" wrap>
        <Stack.Item>
          <Dropdown
            width="7rem"
            displayText={KIND_LABEL[addKind] || addKind}
            options={kindOptions}
            onSelected={(label) => {
              const k = LIST_KINDS.find(
                (kk) => (KIND_LABEL[kk] || kk) === label,
              ) || 'string';
              setAddKind(k);
              setLocalText('');
            }}
          />
        </Stack.Item>
        <Stack.Item grow={1} minWidth="10rem">
          <Input
            fluid
            placeholder={addKind === 'boolean' ? 'true / false' : 'значение'}
            value={localText}
            onChange={(e, val) => setLocalText(val)}
            onEnter={() => add()}
          />
        </Stack.Item>
        <Stack.Item>
          <Button icon="plus" color="good" onClick={add}>
            Добавить
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="upload"
            color="transparent"
            tooltip="Добавить ссылку (ref): предмет в активной руке, либо память-ref на отладчике, либо marked-датум"
            onClick={() => act('ie_list_edit', { edit_action: 'add_ref' })}>
            Ref
          </Button>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const ValueEditor = (props) => {
  const { editor, act } = props;

  if (editor.pin_type === 'any') {
    return <AnyValueEditor editor={editor} act={act} />;
  }

  switch (editor.type) {
    case 'boolean':
      return <BooleanValueEditor editor={editor} act={act} />;
    case 'number':
    case 'index':
      return <NumberValueEditor editor={editor} act={act} />;
    case 'char':
      return <CharValueEditor editor={editor} act={act} />;
    case 'dir':
      return <DirValueEditor editor={editor} act={act} />;
    case 'color':
      return <ColorValueEditor editor={editor} act={act} />;
    case 'entity':
      return <EntityValueEditor editor={editor} act={act} />;
    case 'string':
    case 'any':
    default:
      return <TextValueEditor editor={editor} act={act} />;
  }
};

const NullButton = ({ act }) => (
  <Button
    icon="eraser"
    onClick={() => act('ie_value_edit', { set_null: true })}>
    null
  </Button>
);

const BooleanValueEditor = ({ editor, act }) => {
  const on = editor.value === true || editor.value === 1;
  const off = editor.value === false || editor.value === 0;
  return (
    <Stack align="center" wrap>
      <Stack.Item>
        <Button
          color={on ? 'good' : 'transparent'}
          icon={on ? 'toggle-on' : 'toggle-off'}
          onClick={() => act('ie_value_edit', { value: 1 })}>
          Да (true)
        </Button>
      </Stack.Item>
      <Stack.Item>
        <Button
          color={off ? 'bad' : 'transparent'}
          icon={off ? 'toggle-on' : 'toggle-off'}
          onClick={() => act('ie_value_edit', { value: 0 })}>
          Нет (false)
        </Button>
      </Stack.Item>
    </Stack>
  );
};

const NumberValueEditor = ({ editor, act }) => {
  const init = editor.value === null || editor.value === undefined
    ? ''
    : String(editor.value);
  const [draft, setDraft] = useState(init);
  useEffect(() => setDraft(init), [init]);
  const commit = (val) => act('ie_value_edit', { value: val });
  return (
    <Stack vertical>
      <Stack.Item>
        <Input
          fluid
          placeholder="число"
          value={draft}
          onChange={(e, val) => setDraft(val)}
          onEnter={(e, val) => commit(val)}
        />
      </Stack.Item>
      <Stack.Item>
        <Stack>
          <Stack.Item>
            <Button icon="save" color="good" onClick={() => commit(draft)}>
              Записать
            </Button>
          </Stack.Item>
          <Stack.Item>
            <NullButton act={act} />
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
};

const CharValueEditor = ({ editor, act }) => {
  const init = editor.value === null || editor.value === undefined
    ? ''
    : String(editor.value);
  const [draft, setDraft] = useState(init.slice(0, 1));
  useEffect(() => setDraft(init.slice(0, 1)), [init]);
  const commit = (val) => act('ie_value_edit', { value: (val || '').slice(0, 1) });
  return (
    <Stack vertical>
      <Stack.Item>
        <Input
          placeholder="символ"
          maxLength={1}
          value={draft}
          onChange={(e, val) => setDraft((val || '').slice(0, 1))}
          onEnter={(e, val) => commit(val)}
          width="4rem"
        />
      </Stack.Item>
      <Stack.Item>
        <Stack>
          <Stack.Item>
            <Button icon="save" color="good" onClick={() => commit(draft)}>
              Записать
            </Button>
          </Stack.Item>
          <Stack.Item>
            <NullButton act={act} />
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
};

const IE_DIR_OPTIONS = [
  [1, 'N (1)'],
  [2, 'S (2)'],
  [4, 'E (4)'],
  [8, 'W (8)'],
  [5, 'NE (5)'],
  [9, 'NW (9)'],
  [6, 'SE (6)'],
  [10, 'SW (10)'],
];

const DirValueEditor = ({ editor, act }) => {
  const value = typeof editor.value === 'number' ? editor.value : null;
  const match = IE_DIR_OPTIONS.find(([v]) => v === value);
  return (
    <Stack align="center" wrap>
      <Stack.Item>
        <Dropdown
          width="8rem"
          displayText={match ? match[1] : '—'}
          options={IE_DIR_OPTIONS.map(([, label]) => label)}
          onSelected={(label) => {
            const found = IE_DIR_OPTIONS.find(([, l]) => l === label);
            if (found) {
              act('ie_value_edit', { value: found[0] });
            }
          }}
        />
      </Stack.Item>
      <Stack.Item>
        <NullButton act={act} />
      </Stack.Item>
    </Stack>
  );
};

const ColorValueEditor = ({ editor, act }) => {
  const hex = typeof editor.value === 'string'
      && /^#[0-9A-Fa-f]{6}$/.test(editor.value)
    ? editor.value
    : '#FFFFFF';
  const [draft, setDraft] = useState(typeof editor.value === 'string'
    ? editor.value
    : '');
  useEffect(() => {
    setDraft(typeof editor.value === 'string' ? editor.value : '');
  }, [editor.value]);
  return (
    <Stack align="center" wrap>
      <Stack.Item>
        <input
          type="color"
          value={hex}
          onChange={(e) => act('ie_value_edit', { value: e.target.value.toUpperCase() })}
          style={{
            width: '36px',
            height: '28px',
            padding: 0,
            border: 'none',
            cursor: 'pointer',
          }}
        />
      </Stack.Item>
      <Stack.Item>
        <Input
          placeholder="#RRGGBB"
          value={draft}
          width="90px"
          onChange={(e, val) => setDraft(val)}
          onEnter={(e, val) => act('ie_value_edit', { value: val })}
        />
      </Stack.Item>
      <Stack.Item>
        <Button
          icon="save"
          color="good"
          onClick={() => act('ie_value_edit', { value: draft })}>
          Записать
        </Button>
      </Stack.Item>
      <Stack.Item>
        <NullButton act={act} />
      </Stack.Item>
    </Stack>
  );
};

const EntityValueEditor = ({ editor, act }) => {
  const name = editor.value === null || editor.value === undefined
    ? 'null'
    : String(editor.value);
  return (
    <Stack vertical>
      <Stack.Item>
        <Box className="PinEditor__display">
          Текущее: <b>{name}</b>
        </Box>
      </Stack.Item>
      <Stack.Item>
        <Stack wrap>
          <Stack.Item>
            <Button
              icon="upload"
              color="good"
              tooltip="Предмет в активной руке; иначе память-ref отладчика; иначе marked-датум"
              onClick={() => act('ie_value_edit', { marked_atom: true })}>
              Взять ref
            </Button>
          </Stack.Item>
          <Stack.Item>
            <NullButton act={act} />
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
};

const AnyValueEditor = ({ editor, act }) => {
  const [kind, setKind] = useState('string');
  const init = editor.value === null || editor.value === undefined
    ? ''
    : String(editor.value);
  const [draft, setDraft] = useState(init);
  useEffect(() => setDraft(init), [init]);

  const kindOptions = ANY_KINDS.map((k) => ANY_KIND_LABEL[k]);

  const kindRow = (
    <Stack align="center" wrap>
      <Stack.Item>
        <Box color="label">Тип значения:</Box>
      </Stack.Item>
      <Stack.Item>
        <Dropdown
          width="10rem"
          displayText={ANY_KIND_LABEL[kind]}
          options={kindOptions}
          onSelected={(label) => {
            const k = ANY_KINDS.find(
              (kk) => ANY_KIND_LABEL[kk] === label,
            ) || 'string';
            setKind(k);
          }}
        />
      </Stack.Item>
    </Stack>
  );

  const saveButton = (k) => (
    <Button
      icon="save"
      color="good"
      onClick={() => act('ie_value_edit', { kind: k, value: draft })}>
      Записать
    </Button>
  );

  let kindInput;
  if (kind === 'list') {
    kindInput = (
      <Stack align="center" wrap>
        <Stack.Item>
          <Button
            icon="list-ul"
            color="good"
            tooltip="Заменить текущее значение пустым списком и открыть его редактор"
            onClick={() => act('ie_value_edit', { make_list: true })}>
            Создать список
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Box color="label">
            Текущее значение будет заменено пустым списком.
          </Box>
        </Stack.Item>
      </Stack>
    );
  }
  else if (kind === 'boolean') {
    const on = editor.value === true || editor.value === 1;
    const off = editor.value === false || editor.value === 0;
    kindInput = (
      <Stack>
        <Stack.Item>
          <Button
            color={on ? 'good' : 'transparent'}
            icon={on ? 'toggle-on' : 'toggle-off'}
            onClick={() => act('ie_value_edit', { kind: 'boolean', value: 1 })}>
            Да (true)
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Button
            color={off ? 'bad' : 'transparent'}
            icon={off ? 'toggle-on' : 'toggle-off'}
            onClick={() => act('ie_value_edit', { kind: 'boolean', value: 0 })}>
            Нет (false)
          </Button>
        </Stack.Item>
      </Stack>
    );
  }
  else if (kind === 'dir') {
    const value = typeof editor.value === 'number' ? editor.value : null;
    const match = IE_DIR_OPTIONS.find(([v]) => v === value);
    kindInput = (
      <Dropdown
        width="9rem"
        displayText={match ? match[1] : '—'}
        options={IE_DIR_OPTIONS.map(([, label]) => label)}
        onSelected={(label) => {
          const found = IE_DIR_OPTIONS.find(([, l]) => l === label);
          if (found) {
            act('ie_value_edit', { kind: 'dir', value: found[0] });
          }
        }}
      />
    );
  }
  else if (kind === 'ref') {
    const name = editor.value === null || editor.value === undefined
      ? 'null'
      : String(editor.value);
    kindInput = (
      <Stack vertical>
        <Stack.Item>
          <Box className="PinEditor__display">
            Текущее: <b>{name}</b>
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="upload"
            color="good"
            tooltip="Предмет в активной руке; иначе память-ref отладчика; иначе marked-датум"
            onClick={() => act('ie_value_edit', { marked_atom: true })}>
            Взять ref
          </Button>
        </Stack.Item>
      </Stack>
    );
  }
  else if (kind === 'color') {
    const hex = typeof draft === 'string' && /^#[0-9A-Fa-f]{6}$/.test(draft)
      ? draft
      : '#FFFFFF';
    kindInput = (
      <Stack align="center" wrap>
        <Stack.Item>
          <input
            type="color"
            value={hex}
            onChange={(e) => {
              const val = e.target.value.toUpperCase();
              setDraft(val);
              act('ie_value_edit', { kind: 'color', value: val });
            }}
            style={{
              width: '36px',
              height: '28px',
              padding: 0,
              border: 'none',
              cursor: 'pointer',
            }}
          />
        </Stack.Item>
        <Stack.Item>
          <Input
            placeholder="#RRGGBB"
            value={draft}
            width="90px"
            onChange={(e, val) => setDraft(val)}
            onEnter={(e, val) => act('ie_value_edit', { kind: 'color', value: val })}
          />
        </Stack.Item>
        <Stack.Item>
          {saveButton('color')}
        </Stack.Item>
      </Stack>
    );
  }
  else if (kind === 'char') {
    kindInput = (
      <Stack align="center">
        <Stack.Item>
          <Input
            placeholder="символ"
            maxLength={1}
            width="4rem"
            value={draft}
            onChange={(e, val) => setDraft((val || '').slice(0, 1))}
            onEnter={(e, val) => act('ie_value_edit', {
              kind: 'char',
              value: (val || '').slice(0, 1),
            })}
          />
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="save"
            color="good"
            onClick={() => act('ie_value_edit', {
              kind: 'char',
              value: (draft || '').slice(0, 1),
            })}>
            Записать
          </Button>
        </Stack.Item>
      </Stack>
    );
  }
  else if (kind === 'number') {
    kindInput = (
      <Stack align="center">
        <Stack.Item grow={1}>
          <Input
            fluid
            placeholder="число"
            value={draft}
            onChange={(e, val) => setDraft(val)}
            onEnter={(e, val) => act('ie_value_edit', { kind: 'number', value: val })}
          />
        </Stack.Item>
        <Stack.Item>
          {saveButton('number')}
        </Stack.Item>
      </Stack>
    );
  }
  else {
    kindInput = (
      <Stack align="center">
        <Stack.Item grow={1}>
          <Input
            fluid
            placeholder="значение (текст)"
            value={draft}
            onChange={(e, val) => setDraft(val)}
            onEnter={(e, val) => act('ie_value_edit', { kind: 'string', value: val })}
          />
        </Stack.Item>
        <Stack.Item>
          {saveButton('string')}
        </Stack.Item>
      </Stack>
    );
  }

  return (
    <Stack vertical>
      <Stack.Item>{kindRow}</Stack.Item>
      <Stack.Item>{kindInput}</Stack.Item>
      <Stack.Item>
        <Stack justify="space-between">
          <Stack.Item>
            <Button
              icon="upload"
              color="transparent"
              tooltip="Вставить ref из руки/отладчика/marked"
              onClick={() => act('ie_value_edit', { marked_atom: true })}>
              Вставить ref
            </Button>
          </Stack.Item>
          <Stack.Item>
            <NullButton act={act} />
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
};

const TextValueEditor = ({ editor, act }) => {
  const complex = editor.value !== null && typeof editor.value === 'object';
  const init = complex ? '' : (editor.value === null || editor.value === undefined
    ? ''
    : String(editor.value));
  const [draft, setDraft] = useState(init);
  useEffect(() => setDraft(init), [init]);

  if (complex) {
    return (
      <Box>
        <Box color="label" mb={0.4}>
          Значение — сложный объект/список; правка недоступна здесь.
        </Box>
        <Box className="PinEditor__display">
          {JSON.stringify(editor.value)}
        </Box>
      </Box>
    );
  }

  return (
    <Stack vertical>
      <Stack.Item>
        <TextArea
          fluid
          height="16rem"
          placeholder="значение…"
          value={init}
          onInput={(e, val) => setDraft(val)}
        />
      </Stack.Item>
      {editor.pin_type === 'any' && (
        <Stack.Item>
          <Button
            icon="upload"
            color="transparent"
            tooltip="Вставить ref из руки/отладчика/marked"
            onClick={() => act('ie_value_edit', { marked_atom: true })}>
            Вставить ref
          </Button>
        </Stack.Item>
      )}
      <Stack.Item>
        <Stack justify="flex-end">
          <Stack.Item>
            <Button
              icon="save"
              color="good"
              onClick={() => act('ie_value_edit', { value: draft })}>
              Записать
            </Button>
          </Stack.Item>
          <Stack.Item>
            <NullButton act={act} />
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
};

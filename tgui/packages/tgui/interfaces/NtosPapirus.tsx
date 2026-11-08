// BLUEMOON ADD - Папирус: редактор документов для NTOS с печатью на принтер компьютера.
//
// Документ редактируется прямо на листе (contentEditable) и живёт в интерфейсе:
// сервер получает его с задержкой (sync), а при печати и сохранении шаблона - вместе с действием.
// Сервер заменяет документ только сам (шаблон, новый документ) и тогда поднимает revision.
import {
  KeyboardEvent,
  MouseEvent,
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
} from 'react';

import { useBackend } from '../backend';
import {
  Box,
  Button,
  Input,
  NoticeBox,
  Section,
  Stack,
  Tabs,
} from '../components';
import { NtosWindow } from '../layouts';

type BlockType = 'p' | 'h1' | 'h2' | 'h3' | 'list' | 'hr' | 'spacer';
type Align = 'left' | 'center' | 'right';
type Token = 'поле' | 'подпись' | 'должность' | 'дата' | 'время';

/** Блок, как его хранит сервер: текст с Markdown и {токенами}. */
type ServerBlock = { id: number; type: BlockType; align: Align; text: string };
/** Блок в редакторе: HTML листа. v растёт, когда редактор блока надо пересоздать. */
type EdBlock = { id: number; type: BlockType; align: Align; html: string; v: number };
type Doc = { title: string; blocks: EdBlock[] };

type Data = {
  doc: { title: string; blocks: ServerBlock[] };
  revision: number;
  autofill: boolean;
  code: string;
  max_length: number;
  max_block_text: number;
  max_blocks: number;
  has_printer: boolean;
  paper: number;
  max_paper: number;
  id_name: string | null;
  id_job: string | null;
  builtin_templates: { id: string; name: string }[];
  user_templates: { name: string }[];
};

const TOKENS: Token[] = ['поле', 'подпись', 'должность', 'дата', 'время'];
const TOKEN_RE = /\{(поле|подпись|должность|дата|время)\}/g;
const SYNC_DELAY = 600;
const TYPING_GROUP = 1000;
const HISTORY_LIMIT = 100;

/* ============================================================
   Перевод между текстом сервера и HTML листа
   ============================================================ */

const esc = (s: string) =>
  s.replace(
    /[&<>"]/g,
    (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]!,
  );

const chipHtml = (token: Token) =>
  `<span class="Papirus__chip Papirus__chip--${TOKENS.indexOf(token)}" ` +
  `contenteditable="false" data-token="${token}">${token}</span>`;

const inlineToHtml = (line: string) =>
  esc(line)
    .replace(TOKEN_RE, (_, t) => chipHtml(t))
    .replace(/&lt;u&gt;([\s\S]*?)&lt;\/u&gt;/g, '<u>$1</u>')
    .replace(/\*\*([^*]+?)\*\*/g, '<b>$1</b>')
    .replace(/\*([^*]+?)\*/g, '<i>$1</i>');

export const textToHtml = (text: string) =>
  text
    ? text
        .split('\n')
        .map((line) => `<div>${inlineToHtml(line) || '<br>'}</div>`)
        .join('')
    : '';

/** Разметка вокруг текста, пробелы по краям выносятся наружу (иначе Markdown её не поймёт). */
const wrapMark = (open: string, close: string, s: string) => {
  if (!s.trim()) return s;
  const m = s.match(/^(\s*)([\s\S]*?)(\s*)$/)!;
  return m[1] + open + m[2] + close + m[3];
};

const nodeToText = (node: Node): string => {
  let out = '';
  node.childNodes.forEach((n, i) => {
    if (n.nodeType === Node.TEXT_NODE) {
      out += (n.nodeValue || '').replace(/\u00a0/g, ' ').replace(/\u200b/g, '');
      return;
    }
    if (n.nodeType !== Node.ELEMENT_NODE) return;
    const el = n as HTMLElement;
    const tag = el.tagName;
    if (el.dataset.token) {
      out += `{${el.dataset.token}}`;
      return;
    }
    if (tag === 'BR') {
      if (n.nextSibling) out += '\n';
      return;
    }
    if (tag === 'DIV' || tag === 'P') {
      if (i > 0) out += '\n';
      out += nodeToText(el);
      return;
    }
    let s = nodeToText(el);
    const weight = el.style?.fontWeight;
    if (tag === 'B' || tag === 'STRONG' || weight === 'bold' || weight === '700') {
      s = wrapMark('**', '**', s);
    }
    if (tag === 'I' || tag === 'EM' || el.style?.fontStyle === 'italic') {
      s = wrapMark('*', '*', s);
    }
    if (tag === 'U') s = wrapMark('<u>', '</u>', s);
    out += s;
  });
  return out;
};

export const htmlToText = (html: string) => {
  const tmp = document.createElement('div');
  tmp.innerHTML = html;
  return nodeToText(tmp);
};

const fromServer = (doc: Data['doc']): Doc => ({
  title: doc.title || '',
  blocks: (doc.blocks || []).map((b) => ({
    id: b.id,
    type: b.type,
    align: b.align || 'left',
    html: textToHtml(b.text || ''),
    v: 0,
  })),
});

const toServer = (doc: Doc) =>
  JSON.stringify({
    title: doc.title,
    blocks: doc.blocks.map((b) => ({
      id: b.id,
      type: b.type,
      align: b.align,
      text: b.type === 'hr' || b.type === 'spacer' ? '' : htmlToText(b.html),
    })),
  });

const isEmptyHtml = (html: string) =>
  !html || html === '<br>' || html === '<div><br></div>';

/* ============================================================
   Стили листа
   ============================================================ */

const CSS = `
.Papirus__canvas { background: #2b2f38; padding: 14px 10px 30px; min-height: 100%; }
.Papirus__page {
  background: #fff; color: #000; font-family: 'Times New Roman', serif; font-size: 15px;
  line-height: 1.35; max-width: 620px; margin: 0 auto; padding: 22px 30px 22px 34px;
  box-shadow: 0 3px 12px rgba(0,0,0,.55); min-height: 420px; cursor: text;
}
.Papirus__blk { position: relative; padding: 1px 4px; margin: 0 -5px; border: 1px dashed transparent; border-radius: 3px; }
.Papirus__blk:hover { border-color: #c9cfdc; }
.Papirus__blk--sel, .Papirus__blk--sel:hover { border: 1px solid #4a90d9; background: rgba(74,144,217,.05); }
.Papirus__tag {
  position: absolute; left: -30px; top: 3px; width: 24px; text-align: right;
  font: 10px Verdana, sans-serif; color: #a6adbd; user-select: none;
}
.Papirus__blk--sel .Papirus__tag { color: #4a90d9; font-weight: bold; }
.Papirus__ops {
  position: absolute; right: -1px; top: -19px; display: none; z-index: 2;
  background: #4a90d9; border-radius: 3px 3px 0 0; padding: 1px 3px; user-select: none;
}
.Papirus__blk--sel .Papirus__ops { display: flex; }
.Papirus__op { color: #fff; font: 11px Verdana, sans-serif; padding: 1px 5px; cursor: pointer; border-radius: 2px; }
.Papirus__op:hover { background: rgba(255,255,255,.25); }
.Papirus__ed { outline: none; min-height: 1.35em; white-space: pre-wrap; word-break: break-word; }
.Papirus__ed:empty::before { content: attr(data-ph); color: #a9a9a9; font-style: italic; }
.Papirus__ed--h1 { font-size: 2em; font-weight: bold; margin: .2em 0; }
.Papirus__ed--h2 { font-size: 1.5em; font-weight: bold; margin: .15em 0; }
.Papirus__ed--h3 { font-size: 1.17em; font-weight: bold; }
.Papirus__ed--list > div { padding-left: 1.1em; text-indent: -.8em; }
.Papirus__ed--list > div::before { content: '• '; }
.Papirus__hr { border-top: 1px solid #000; margin: 9px 0; }
.Papirus__spacer { height: 1.35em; font: italic 10px Verdana, sans-serif; color: #c0c0c0; line-height: 1.9em; }
.Papirus__plain { outline: none; }
.Papirus__chip {
  display: inline-block; padding: 0 6px; margin: 0 1px; border-radius: 3px; line-height: 1.25em;
  font: 12px Verdana, sans-serif; user-select: none; vertical-align: baseline; white-space: nowrap;
  background: #eef1f6; border: 1px solid #b7c0d0; color: #3c4658;
}
.Papirus__chip--1 { background: #eaf2ff; border-color: #8fb1e6; color: #1f4f9a; font-family: 'Segoe Script', cursive; }
.Papirus__chip--2 { background: #eefaf0; border-color: #95cfa0; color: #23683a; }
.Papirus__chip--3, .Papirus__chip--4 { background: #fff6e6; border-color: #e3c27f; color: #7a5410; }
.Papirus__add { text-align: center; margin-top: 10px; color: #a6adbd; font: 11px Verdana, sans-serif; user-select: none; }
.Papirus__add span { cursor: pointer; padding: 2px 8px; border-radius: 3px; }
.Papirus__add span:hover { background: #eef1f6; color: #3c4658; }
.Papirus__hint { color: #8b93a3; font-size: 11px; }
`;

const TYPE_TAG: Record<BlockType, string> = {
  p: '¶',
  h1: 'H1',
  h2: 'H2',
  h3: 'H3',
  list: '☰',
  hr: '―',
  spacer: '↵',
};

const PLACEHOLDER: Partial<Record<BlockType, string>> = {
  p: 'Введите текст…',
  h1: 'Заголовок',
  h2: 'Заголовок',
  h3: 'Заголовок',
  list: 'Пункт списка',
};

const STYLES: { type: BlockType; label: string; tooltip: string }[] = [
  { type: 'p', label: 'Обычный', tooltip: 'Обычный абзац' },
  { type: 'h1', label: 'H1', tooltip: 'Заголовок 1' },
  { type: 'h2', label: 'H2', tooltip: 'Заголовок 2' },
  { type: 'h3', label: 'H3', tooltip: 'Заголовок 3' },
  { type: 'list', label: '• Список', tooltip: 'Список: каждый пункт с новой строки' },
];

const ALIGNS: { align: Align; icon: string; tooltip: string }[] = [
  { align: 'left', icon: 'align-left', tooltip: 'По левому краю' },
  { align: 'center', icon: 'align-center', tooltip: 'По центру' },
  { align: 'right', icon: 'align-right', tooltip: 'По правому краю' },
];

const INSERTS: { token: Token; icon: string; label: string; tooltip: string }[] = [
  {
    token: 'поле',
    icon: 'square',
    label: 'Поле',
    tooltip: 'Пустое поле: его заполняют ручкой на бумаге',
  },
  {
    token: 'подпись',
    icon: 'signature',
    label: 'Подпись',
    tooltip: 'При печати подписывается именем с ID-карты',
  },
  {
    token: 'должность',
    icon: 'id-badge',
    label: 'Должность',
    tooltip: 'При печати заполняется должностью с ID-карты',
  },
  { token: 'дата', icon: 'calendar', label: 'Дата', tooltip: 'Дата печати' },
  { token: 'время', icon: 'clock', label: 'Время', tooltip: 'Время печати' },
];

type Preset = { type: BlockType; align?: Align; text?: string };
const PRESETS: { name: string; icon: string; blocks: Preset[] }[] = [
  {
    name: 'Шапка NT',
    icon: 'building',
    blocks: [
      { type: 'h2', align: 'center', text: 'NanoTrasen' },
      { type: 'p', align: 'center', text: '*Космическая станция 13*' },
      { type: 'hr' },
    ],
  },
  {
    name: 'Блок подписи',
    icon: 'pen-nib',
    blocks: [
      { type: 'spacer' },
      {
        type: 'p',
        text: 'Должность: {должность}\nФ.И.О.: {поле}\nПодпись: {подпись}\nДата: {дата} {время}',
      },
    ],
  },
];

/* ============================================================
   Работа с курсором
   ============================================================ */

const editorOf = (node: Node | null): HTMLElement | null => {
  const el = node
    ? node.nodeType === Node.ELEMENT_NODE
      ? (node as HTMLElement)
      : node.parentElement
    : null;
  return el ? (el.closest('[data-papirus-ed]') as HTMLElement | null) : null;
};

const placeCaretEnd = (el: HTMLElement) => {
  el.focus();
  const range = document.createRange();
  range.selectNodeContents(el);
  range.collapse(false);
  const sel = window.getSelection();
  sel?.removeAllRanges();
  sel?.addRange(range);
};

const insertHtmlAtCaret = (html: string) => {
  const sel = window.getSelection();
  if (!sel || !sel.rangeCount) return;
  const range = sel.getRangeAt(0);
  range.deleteContents();
  const tmp = document.createElement('div');
  tmp.innerHTML = html;
  const frag = document.createDocumentFragment();
  let last: Node | null = null;
  while (tmp.firstChild) last = frag.appendChild(tmp.firstChild);
  range.insertNode(frag);
  if (last) {
    range.setStartAfter(last);
    range.collapse(true);
    sel.removeAllRanges();
    sel.addRange(range);
  }
};

/** Кнопки панели не забирают фокус у листа, иначе теряется курсор. */
const keepFocus = (e: MouseEvent) => e.preventDefault();

/* ============================================================
   Редактор блока
   ============================================================ */

type EditableProps = {
  block: EdBlock;
  onInput: (id: number, html: string) => void;
  onKeyDown: (e: KeyboardEvent<HTMLDivElement>, block: EdBlock) => void;
  onFocus: (id: number) => void;
};

/** Неуправляемый contentEditable: HTML ставится один раз, дальше им владеет браузер. */
const Editable = (props: EditableProps) => {
  const { block, onInput, onKeyDown, onFocus } = props;
  const ref = useRef<HTMLDivElement>(null);

  useLayoutEffect(() => {
    if (ref.current) ref.current.innerHTML = block.html;
  }, []);

  return (
    <div
      ref={ref}
      className={`Papirus__ed Papirus__ed--${block.type}`}
      contentEditable
      suppressContentEditableWarning
      spellCheck
      data-papirus-ed={block.id}
      data-ph={PLACEHOLDER[block.type] || ''}
      style={{ textAlign: block.align }}
      onFocus={() => onFocus(block.id)}
      onKeyDown={(e) => onKeyDown(e, block)}
      onPaste={(e) => {
        e.preventDefault();
        document.execCommand(
          'insertText',
          false,
          e.clipboardData.getData('text/plain'),
        );
      }}
      onInput={() => {
        const el = ref.current!;
        // У первого пункта списка тоже должна быть своя строка, иначе нет маркера
        if (block.type === 'list' && el.firstChild?.nodeType === Node.TEXT_NODE) {
          const div = document.createElement('div');
          div.appendChild(el.firstChild);
          el.prepend(div);
          placeCaretEnd(div);
        }
        onInput(block.id, isEmptyHtml(el.innerHTML) ? '' : el.innerHTML);
      }}
    />
  );
};

/* ============================================================
   Программа
   ============================================================ */

export const NtosPapirus = () => {
  const { act, data } = useBackend<Data>();
  const [tab, setTab] = useState<'doc' | 'templates' | 'code'>('doc');
  const [doc, setDocState] = useState<Doc>(() => fromServer(data.doc));
  const [templateName, setTemplateName] = useState(data.doc.title || '');
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [epoch, setEpoch] = useState(0);
  const [format, setFormat] = useState({ bold: false, italic: false, underline: false });
  const [, setHistoryTick] = useState(0);

  const docRef = useRef(doc);
  const past = useRef<Doc[]>([]);
  const future = useRef<Doc[]>([]);
  const lastTyping = useRef(0);
  const dirty = useRef(false);
  const syncTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const revision = useRef(data.revision);
  const pageRef = useRef<HTMLDivElement>(null);
  const pendingFocus = useRef<number | null>(null);

  /* ---------- Синхронизация с сервером ---------- */

  const flush = () => {
    if (syncTimer.current) clearTimeout(syncTimer.current);
    syncTimer.current = null;
    if (!dirty.current) return;
    dirty.current = false;
    act('sync', { doc: toServer(docRef.current) });
  };

  /** Действие, которое должно видеть свежий документ (печать, шаблон). */
  const actWithDoc = (action: string, params: Record<string, unknown> = {}) => {
    if (syncTimer.current) clearTimeout(syncTimer.current);
    syncTimer.current = null;
    dirty.current = false;
    act(action, { ...params, doc: toServer(docRef.current) });
  };

  const scheduleSync = () => {
    dirty.current = true;
    if (syncTimer.current) clearTimeout(syncTimer.current);
    syncTimer.current = setTimeout(flush, SYNC_DELAY);
  };

  // Не теряем последние правки, если окно закрыли раньше синхронизации
  const flushRef = useRef(flush);
  flushRef.current = flush;
  useEffect(() => () => flushRef.current(), []);

  // Документ заменили на сервере (шаблон, новый документ)
  useEffect(() => {
    if (data.revision === revision.current) return;
    revision.current = data.revision;
    past.current.push(docRef.current);
    future.current = [];
    const next = fromServer(data.doc);
    docRef.current = next;
    setDocState(next);
    setSelectedId(null);
    setEpoch((e) => e + 1);
  }, [data.revision]);

  /* ---------- Изменения и история ---------- */

  const commit = (next: Doc, mode: 'push' | 'typing' = 'push') => {
    const now = Date.now();
    if (mode === 'push' || now - lastTyping.current > TYPING_GROUP) {
      past.current.push(docRef.current);
      if (past.current.length > HISTORY_LIMIT) past.current.shift();
      future.current = [];
      setHistoryTick((t) => t + 1);
    }
    lastTyping.current = mode === 'typing' ? now : 0;
    docRef.current = next;
    setDocState(next);
    scheduleSync();
  };

  const restore = (from: Doc[], to: Doc[]) => {
    const prev = from.pop();
    if (!prev) return;
    to.push(docRef.current);
    lastTyping.current = 0;
    docRef.current = prev;
    setDocState(prev);
    setEpoch((e) => e + 1);
    setHistoryTick((t) => t + 1);
    if (selectedId !== null) pendingFocus.current = selectedId;
    scheduleSync();
  };
  const undo = () => restore(past.current, future.current);
  const redo = () => restore(future.current, past.current);

  const nextId = () =>
    docRef.current.blocks.reduce((max, b) => Math.max(max, b.id), 0) + 1;

  const indexOf = (id: number | null) =>
    docRef.current.blocks.findIndex((b) => b.id === id);

  const updateBlock = (
    id: number,
    patch: Partial<EdBlock>,
    mode: 'push' | 'typing' = 'push',
  ) => {
    const cur = docRef.current;
    commit(
      { ...cur, blocks: cur.blocks.map((b) => (b.id === id ? { ...b, ...patch } : b)) },
      mode,
    );
  };

  /** Вставляет блоки после выбранного (или в конец) и ставит курсор в первый текстовый. */
  const addBlocks = (presets: Preset[], after: number | null = selectedId) => {
    const cur = docRef.current;
    if (cur.blocks.length + presets.length > data.max_blocks) return;
    let id = nextId();
    const made: EdBlock[] = presets.map((p) => ({
      id: id++,
      type: p.type,
      align: p.align || (p.type === 'h1' ? 'center' : 'left'),
      html: textToHtml(p.text || ''),
      v: 0,
    }));
    const at = after === null ? -1 : indexOf(after);
    const blocks = [...cur.blocks];
    blocks.splice(at < 0 ? blocks.length : at + 1, 0, ...made);
    commit({ ...cur, blocks });
    const target = made.find((b) => b.type !== 'hr' && b.type !== 'spacer') || made[made.length - 1];
    setSelectedId(target.id);
    pendingFocus.current = target.id;
  };

  const removeBlock = (id: number) => {
    const cur = docRef.current;
    const at = indexOf(id);
    if (at < 0) return;
    const blocks = cur.blocks.filter((b) => b.id !== id);
    commit({ ...cur, blocks });
    const neighbour = blocks[Math.max(0, at - 1)];
    setSelectedId(neighbour ? neighbour.id : null);
    if (neighbour) pendingFocus.current = neighbour.id;
  };

  const moveBlock = (id: number, dir: -1 | 1) => {
    const cur = docRef.current;
    const at = indexOf(id);
    const to = at + dir;
    if (at < 0 || to < 0 || to >= cur.blocks.length) return;
    const blocks = [...cur.blocks];
    [blocks[at], blocks[to]] = [blocks[to], blocks[at]];
    commit({ ...cur, blocks });
    pendingFocus.current = id;
  };

  const duplicateBlock = (id: number) => {
    const cur = docRef.current;
    const at = indexOf(id);
    if (at < 0 || cur.blocks.length >= data.max_blocks) return;
    const copy = { ...cur.blocks[at], id: nextId(), v: 0 };
    const blocks = [...cur.blocks];
    blocks.splice(at + 1, 0, copy);
    commit({ ...cur, blocks });
    setSelectedId(copy.id);
    pendingFocus.current = copy.id;
  };

  const setType = (type: BlockType) => {
    const b = docRef.current.blocks.find((x) => x.id === selectedId);
    if (!b || b.type === 'hr' || b.type === 'spacer' || b.type === type) return;
    // Строки пересобираются, чтобы у каждого пункта списка был свой <div>
    const html = textToHtml(htmlToText(b.html));
    updateBlock(b.id, { type, html, v: b.v + 1 });
    pendingFocus.current = b.id;
  };

  const setAlign = (align: Align) => {
    const b = docRef.current.blocks.find((x) => x.id === selectedId);
    if (!b || b.type === 'hr' || b.type === 'spacer') return;
    updateBlock(b.id, { align });
  };

  const setTitle = (title: string) => {
    if (title === docRef.current.title) return;
    commit({ ...docRef.current, title });
  };

  /* ---------- Текст и вставки ---------- */

  const onEditorInput = (id: number, html: string) =>
    updateBlock(id, { html }, 'typing');

  const editorEl = (id: number) =>
    pageRef.current?.querySelector(`[data-papirus-ed="${id}"]`) as HTMLElement | null;

  /** Поле вставляется туда, где стоит курсор; если курсора на листе нет - в конец выбранного блока. */
  const insertToken = (token: Token) => {
    const sel = window.getSelection();
    let ed = sel && sel.rangeCount ? editorOf(sel.getRangeAt(0).startContainer) : null;
    if (!ed && selectedId !== null) {
      ed = editorEl(selectedId);
      if (ed) placeCaretEnd(ed);
    }
    if (!ed) {
      addBlocks([{ type: 'p', text: `{${token}}` }]);
      return;
    }
    lastTyping.current = 0;
    insertHtmlAtCaret(chipHtml(token) + ' ');
    const id = Number(ed.dataset.papirusEd);
    updateBlock(id, { html: ed.innerHTML });
  };

  const applyFormat = (command: 'bold' | 'italic' | 'underline') => {
    const sel = window.getSelection();
    if (!sel || !sel.rangeCount || !editorOf(sel.getRangeAt(0).startContainer)) return;
    lastTyping.current = 0;
    document.execCommand(command);
    const ed = editorOf(sel.getRangeAt(0).startContainer);
    if (ed) updateBlock(Number(ed.dataset.papirusEd), { html: ed.innerHTML });
  };

  const onEditorKey = (e: KeyboardEvent<HTMLDivElement>, block: EdBlock) => {
    const ctrl = e.ctrlKey || e.metaKey;
    const code = e.nativeEvent.code;
    if (ctrl && code === 'KeyZ') {
      e.preventDefault();
      e.shiftKey ? redo() : undo();
      return;
    }
    if (ctrl && code === 'KeyY') {
      e.preventDefault();
      redo();
      return;
    }
    if (ctrl && (code === 'KeyB' || code === 'KeyI' || code === 'KeyU')) {
      e.preventDefault();
      applyFormat(code === 'KeyB' ? 'bold' : code === 'KeyI' ? 'italic' : 'underline');
      return;
    }
    if (e.altKey && (e.key === 'ArrowUp' || e.key === 'ArrowDown')) {
      e.preventDefault();
      moveBlock(block.id, e.key === 'ArrowUp' ? -1 : 1);
      return;
    }
    if (e.key === 'Enter' && (ctrl || block.type.startsWith('h'))) {
      e.preventDefault();
      addBlocks([{ type: 'p' }], block.id);
      return;
    }
    const el = e.currentTarget;
    if (
      e.key === 'Backspace' &&
      !el.textContent &&
      !el.querySelector('[data-token]') &&
      docRef.current.blocks.length > 1
    ) {
      e.preventDefault();
      removeBlock(block.id);
    }
  };

  const onPlainKey = (e: KeyboardEvent<HTMLDivElement>, block: EdBlock) => {
    if (e.key === 'Backspace' || e.key === 'Delete') {
      e.preventDefault();
      removeBlock(block.id);
    } else if (e.key === 'Enter') {
      e.preventDefault();
      addBlocks([{ type: 'p' }], block.id);
    } else if (e.altKey && (e.key === 'ArrowUp' || e.key === 'ArrowDown')) {
      e.preventDefault();
      moveBlock(block.id, e.key === 'ArrowUp' ? -1 : 1);
    }
  };

  /* ---------- Эффекты после отрисовки ---------- */

  // Курсор в нужный блок после вставки, удаления, отмены
  useEffect(() => {
    const id = pendingFocus.current;
    if (id === null || tab !== 'doc') return;
    pendingFocus.current = null;
    const el =
      editorEl(id) ||
      (pageRef.current?.querySelector(`[data-papirus-plain="${id}"]`) as HTMLElement | null);
    if (!el) return;
    if (el.isContentEditable) placeCaretEnd(el);
    else el.focus();
    el.scrollIntoView?.({ block: 'nearest' });
  });

  // Подписи на полях показывают, что будет вписано при печати
  useEffect(() => {
    const labels: Record<Token, string> = {
      поле: '▭ поле',
      подпись: data.autofill && data.id_name ? `✍ ${data.id_name}` : '✍ подпись',
      должность:
        data.autofill && data.id_job ? `◈ ${data.id_job}` : '◈ должность',
      дата: data.autofill ? '📅 дата печати' : '📅 дата',
      время: data.autofill ? '🕓 время печати' : '🕓 время',
    };
    pageRef.current?.querySelectorAll<HTMLElement>('[data-token]').forEach((el) => {
      const label = labels[el.dataset.token as Token];
      if (label && el.textContent !== label) el.textContent = label;
    });
  });

  // Подсветка Ж/К/Ч по месту курсора
  useEffect(() => {
    const update = () => {
      const sel = window.getSelection();
      const inEditor = !!(sel && sel.rangeCount && editorOf(sel.getRangeAt(0).startContainer));
      const state = (command: string) => {
        try {
          return inEditor && document.queryCommandState(command);
        } catch {
          return false;
        }
      };
      setFormat({
        bold: state('bold'),
        italic: state('italic'),
        underline: state('underline'),
      });
    };
    document.addEventListener('selectionchange', update);
    return () => document.removeEventListener('selectionchange', update);
  }, []);

  /* ---------- Разметка ---------- */

  const selected = doc.blocks.find((b) => b.id === selectedId) || null;
  const textBlock = !!selected && selected.type !== 'hr' && selected.type !== 'spacer';
  const length = data.code.length;
  const tooLong = length > data.max_length;
  const full = doc.blocks.length >= data.max_blocks;

  const toolbar = (
    <Section>
      <Stack wrap="wrap" align="center">
        <Stack.Item>
          <Button
            icon="undo"
            tooltip="Отменить (Ctrl+Z)"
            disabled={!past.current.length}
            onMouseDown={keepFocus}
            onClick={undo}
          />
          <Button
            icon="redo"
            tooltip="Вернуть (Ctrl+Y)"
            disabled={!future.current.length}
            onMouseDown={keepFocus}
            onClick={redo}
          />
        </Stack.Item>
        <Stack.Divider />
        <Stack.Item>
          <Button
            bold
            selected={format.bold}
            tooltip="Жирный (Ctrl+B)"
            onMouseDown={keepFocus}
            onClick={() => applyFormat('bold')}
          >
            Ж
          </Button>
          <Button
            italic
            selected={format.italic}
            tooltip="Курсив (Ctrl+I)"
            onMouseDown={keepFocus}
            onClick={() => applyFormat('italic')}
          >
            К
          </Button>
          <Button
            style={{ textDecoration: 'underline' }}
            selected={format.underline}
            tooltip="Подчёркнутый (Ctrl+U)"
            onMouseDown={keepFocus}
            onClick={() => applyFormat('underline')}
          >
            Ч
          </Button>
        </Stack.Item>
        <Stack.Divider />
        <Stack.Item>
          {STYLES.map((s) => (
            <Button
              key={s.type}
              selected={selected?.type === s.type}
              disabled={!textBlock}
              tooltip={s.tooltip}
              onMouseDown={keepFocus}
              onClick={() => setType(s.type)}
            >
              {s.label}
            </Button>
          ))}
        </Stack.Item>
        <Stack.Divider />
        <Stack.Item>
          {ALIGNS.map((a) => (
            <Button
              key={a.align}
              icon={a.icon}
              selected={textBlock && selected?.align === a.align}
              disabled={!textBlock}
              tooltip={a.tooltip}
              onMouseDown={keepFocus}
              onClick={() => setAlign(a.align)}
            />
          ))}
        </Stack.Item>
      </Stack>
      <Stack wrap="wrap" align="center" mt={0.5}>
        <Stack.Item color="label">В текст:</Stack.Item>
        <Stack.Item>
          {INSERTS.map((i) => (
            <Button
              key={i.token}
              icon={i.icon}
              tooltip={i.tooltip}
              onMouseDown={keepFocus}
              onClick={() => insertToken(i.token)}
            >
              {i.label}
            </Button>
          ))}
        </Stack.Item>
        <Stack.Divider />
        <Stack.Item>
          <Button
            icon="minus"
            disabled={full}
            tooltip="Горизонтальная линия"
            onMouseDown={keepFocus}
            onClick={() => addBlocks([{ type: 'hr' }])}
          >
            Линия
          </Button>
          <Button
            icon="level-down-alt"
            disabled={full}
            tooltip="Пустая строка"
            onMouseDown={keepFocus}
            onClick={() => addBlocks([{ type: 'spacer' }])}
          >
            Отступ
          </Button>
          {PRESETS.map((p) => (
            <Button
              key={p.name}
              icon={p.icon}
              disabled={full}
              tooltip="Вставить после выбранного блока"
              onMouseDown={keepFocus}
              onClick={() => addBlocks(p.blocks)}
            >
              {p.name}
            </Button>
          ))}
        </Stack.Item>
      </Stack>
    </Section>
  );

  const page = (
    <Section fill scrollable>
      <div className="Papirus__canvas">
        <div
          className="Papirus__page"
          ref={pageRef}
          onMouseDown={(e) => {
            // Щелчок по пустому месту листа ставит курсор в конец документа
            if (e.target !== e.currentTarget) return;
            const last = docRef.current.blocks[docRef.current.blocks.length - 1];
            if (!last) return;
            e.preventDefault();
            setSelectedId(last.id);
            const el = editorEl(last.id);
            if (el) placeCaretEnd(el);
          }}
        >
          {doc.blocks.map((block) => {
            const plain = block.type === 'hr' || block.type === 'spacer';
            const isSel = block.id === selectedId;
            return (
              <div
                key={`${block.id}:${block.v}:${epoch}`}
                className={`Papirus__blk${isSel ? ' Papirus__blk--sel' : ''}`}
                onMouseDown={() => setSelectedId(block.id)}
              >
                <div className="Papirus__tag">
                  {block.type.startsWith('h') ? block.type.toUpperCase() : TYPE_TAG[block.type]}
                </div>
                <div className="Papirus__ops" onMouseDown={keepFocus}>
                  <span
                    className="Papirus__op"
                    title="Выше (Alt+↑)"
                    onClick={() => moveBlock(block.id, -1)}
                  >
                    ▲
                  </span>
                  <span
                    className="Papirus__op"
                    title="Ниже (Alt+↓)"
                    onClick={() => moveBlock(block.id, 1)}
                  >
                    ▼
                  </span>
                  <span
                    className="Papirus__op"
                    title="Копия блока"
                    onClick={() => duplicateBlock(block.id)}
                  >
                    ⧉
                  </span>
                  <span
                    className="Papirus__op"
                    title="Удалить блок"
                    onClick={() => removeBlock(block.id)}
                  >
                    ✕
                  </span>
                </div>
                {plain ? (
                  <div
                    className="Papirus__plain"
                    tabIndex={0}
                    data-papirus-plain={block.id}
                    onFocus={() => setSelectedId(block.id)}
                    onKeyDown={(e) => onPlainKey(e, block)}
                  >
                    {block.type === 'hr' ? (
                      <div className="Papirus__hr" />
                    ) : (
                      <div className="Papirus__spacer">пустая строка</div>
                    )}
                  </div>
                ) : (
                  <Editable
                    block={block}
                    onInput={onEditorInput}
                    onKeyDown={onEditorKey}
                    onFocus={setSelectedId}
                  />
                )}
              </div>
            );
          })}
          <div className="Papirus__add" onMouseDown={keepFocus}>
            <span onClick={() => addBlocks([{ type: 'p' }], null)}>+ абзац</span>
            <span onClick={() => addBlocks([{ type: 'h1' }], null)}>+ заголовок</span>
            <span onClick={() => addBlocks([{ type: 'list' }], null)}>+ список</span>
          </div>
        </div>
      </div>
    </Section>
  );

  const templates = (
    <Section fill scrollable>
      <Section title="Встроенные шаблоны">
        <Stack wrap="wrap">
          {data.builtin_templates.map((t) => (
            <Stack.Item key={t.id}>
              <Button.Confirm
                icon="file-alt"
                confirmContent="Заменить документ?"
                onClick={() => actWithDoc('load_builtin', { id: t.id })}
              >
                {t.name}
              </Button.Confirm>
            </Stack.Item>
          ))}
        </Stack>
        <Box className="Papirus__hint" mt={1}>
          Открытый шаблон заменяет текущий документ. Передумали — Ctrl+Z на листе.
        </Box>
      </Section>
      <Section title="Мои шаблоны">
        <Stack mb={1} align="center">
          <Stack.Item grow>
            <Input
              fluid
              value={templateName}
              placeholder="Название шаблона"
              maxLength={40}
              onInput={(e, value) => setTemplateName(value)}
            />
          </Stack.Item>
          <Stack.Item>
            <Button
              icon="save"
              disabled={!templateName.trim()}
              tooltip="Сохранить текущий документ как шаблон (с тем же названием - перезаписать)"
              onClick={() =>
                actWithDoc('save_template', { name: templateName.trim() })
              }
            >
              Сохранить текущий
            </Button>
          </Stack.Item>
        </Stack>
        {data.user_templates.length === 0 ? (
          <Box color="label">
            Пока пусто. Шаблоны хранятся на диске этого устройства и
            копируются вместе с программой.
          </Box>
        ) : (
          data.user_templates.map((t, index) => (
            <Stack key={t.name} mb={0.5}>
              <Stack.Item grow>
                <Button.Confirm
                  fluid
                  icon="file"
                  confirmContent="Заменить документ?"
                  onClick={() => actWithDoc('load_template', { index })}
                >
                  {t.name}
                </Button.Confirm>
              </Stack.Item>
              <Stack.Item>
                <Button.Confirm
                  icon="trash"
                  color="bad"
                  confirmContent="Удалить?"
                  onClick={() => act('delete_template', { index })}
                />
              </Stack.Item>
            </Stack>
          ))
        )}
      </Section>
      <Section title="Горячие клавиши">
        <Box className="Papirus__hint">
          Ctrl+B / I / U — жирный, курсив, подчёркнутый · Ctrl+Z / Y — отмена и
          повтор · Ctrl+Enter — новый абзац · Alt+↑ / ↓ — переместить блок ·
          Backspace в пустом блоке — удалить его
        </Box>
      </Section>
    </Section>
  );

  const code = (
    <Section fill scrollable title="Разметка листа">
      <Box
        as="pre"
        m={0}
        style={{ whiteSpace: 'pre-wrap', wordBreak: 'break-word' }}
      >
        {data.code}
      </Box>
    </Section>
  );

  return (
    <NtosWindow width={640} height={760}>
      <style>{CSS}</style>
      <NtosWindow.Content>
        <Stack fill vertical>
          <Stack.Item>
            <Stack align="center">
              <Stack.Item>
                <Tabs>
                  <Tabs.Tab
                    icon="file-alt"
                    selected={tab === 'doc'}
                    onClick={() => setTab('doc')}
                  >
                    Документ
                  </Tabs.Tab>
                  <Tabs.Tab
                    icon="folder-open"
                    selected={tab === 'templates'}
                    onClick={() => {
                      flush();
                      setTab('templates');
                    }}
                  >
                    Шаблоны
                  </Tabs.Tab>
                  <Tabs.Tab
                    icon="code"
                    selected={tab === 'code'}
                    onClick={() => {
                      flush();
                      setTab('code');
                    }}
                  >
                    Код
                  </Tabs.Tab>
                </Tabs>
              </Stack.Item>
              <Stack.Item grow>
                <Input
                  fluid
                  value={doc.title}
                  placeholder="Название документа"
                  maxLength={40}
                  onChange={(e, value) => setTitle(value)}
                />
              </Stack.Item>
              <Stack.Item>
                <Button.Confirm
                  icon="file"
                  tooltip="Новый документ"
                  confirmContent="Очистить?"
                  onClick={() => actWithDoc('new_doc')}
                />
              </Stack.Item>
            </Stack>
          </Stack.Item>
          {tab === 'doc' && <Stack.Item>{toolbar}</Stack.Item>}
          <Stack.Item grow basis={0}>
            {tab === 'doc' && page}
            {tab === 'templates' && templates}
            {tab === 'code' && code}
          </Stack.Item>
          <Stack.Item>
            <Section>
              {!data.has_printer && (
                <NoticeBox>Принтер не установлен: печать недоступна.</NoticeBox>
              )}
              <Stack align="center">
                <Stack.Item grow>
                  <Box color={tooLong ? 'bad' : 'label'}>
                    {length} / {data.max_length} символов
                    {data.has_printer && ` · бумага ${data.paper}/${data.max_paper}`}
                  </Box>
                  <Box color="label">
                    {data.id_name
                      ? `ID: ${data.id_name}${data.id_job ? `, ${data.id_job}` : ''}`
                      : 'ID-карта не вставлена'}
                  </Box>
                </Stack.Item>
                <Stack.Item>
                  <Button.Checkbox
                    checked={data.autofill}
                    tooltip="Подпись и должность — по ID-карте, дата и время — по станционным часам"
                    onClick={() => act('toggle_autofill')}
                  >
                    Заполнить при печати
                  </Button.Checkbox>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="print"
                    color="good"
                    disabled={!data.has_printer || data.paper <= 0 || tooLong}
                    onClick={() => actWithDoc('print')}
                  >
                    Печать
                  </Button>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>
        </Stack>
      </NtosWindow.Content>
    </NtosWindow>
  );
};

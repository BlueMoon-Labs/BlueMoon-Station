type FilePresentation = {
  icon: string;
  format: string;
  label?: string;
  search?: string;
  readable?: boolean;
};

/** File kind presentation is shared by both catalogs and the editor. */
const FILE_KINDS: Record<string, FilePresentation> = {
  text: { icon: 'file-lines', format: 'TXT', search: 'текст заметка', readable: true },
  key: { icon: 'key', format: 'KEY', search: 'ключ сеть', readable: true },
  grants: { icon: 'key', format: 'KEY', label: 'ключ доступа', search: 'ключ доступ' },
  access: { icon: 'id-card', format: 'ID', label: 'снимок ID', search: 'ID снимок доступ' },
  daemon: { icon: 'gear', format: 'EXE', search: 'демон программа' },
  program: { icon: 'file-lines', format: 'DAT', search: 'программа бой' },
  seed: { icon: 'seedling', format: 'SEED' },
  photo: { icon: 'image', format: 'IMG', search: 'фото снимок', readable: true },
  techweb: { icon: 'flask', format: 'WEB', search: 'исследования', readable: true },
  techweb_link: { icon: 'link', format: 'LINK', search: 'ссылка исследования', readable: true },
  bot: { icon: 'robot', format: 'BOT', label: 'агент', search: 'агент' },
};
const UNKNOWN_FILE: FilePresentation = { icon: 'file-lines', format: 'DAT' };
const presentation = (kind: string): FilePresentation =>
  Object.prototype.hasOwnProperty.call(FILE_KINDS, kind) ? FILE_KINDS[kind] : UNKNOWN_FILE;

export const fileIcon = (kind: string) => presentation(kind).icon;
export const fileKindLabel = (kind: string) => presentation(kind).label || kind;
export const fileSearchLabel = (kind: string) => presentation(kind).search || '';
/** Formats offered for viewing in the catalogs; transport remains server-authorized. */
export const isReadableFile = (kind: string) => !!presentation(kind).readable;

/** A filename extension takes precedence over the kind's default format. */
export const fileFormat = (name: string, kind: string) => {
  const dot = name.lastIndexOf('.');
  return dot > 0 && dot < name.length - 1 ? name.slice(dot + 1).toUpperCase() : presentation(kind).format;
};

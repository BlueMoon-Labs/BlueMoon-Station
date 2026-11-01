import { useBackend } from '../../../backend';
import {
  Box,
  Button,
  ColorBox,
  Dropdown,
  Input,
  NumberInput,
  Stack,
} from '../../../components';
import { PrefRow } from '../components/PrefRow';

type ThemeColors = Record<string, string>;

type ContextMenuStyle = {
  renderer: string;
  layout: string;
  weight: string;
  width: string;
  icon_size: number;
  icon_side: string;
  hover: string;
  theme: string;
  font: string;
  scale: number;
  opacity: number;
  density: string;
  animation: string;
  hints: string;
  position: string;
  icons: boolean | number;
  border: boolean | number;
  header: boolean | number;
  smooth_hover: boolean | number;
  anim_speed: string;
  stripe: boolean | number;
  shadow: boolean | number;
  separators: boolean | number;
  caps: boolean | number;
  outline: boolean | number;
  page_rows: number;
  accent: string;
  text_size: number;
  hint_style: string;
  header_icon: boolean | number;
  offset: number;
  close_on_move: string;
  auto_close: number;
  danger_order: string;
  confirm_danger: boolean | number;
  show_examine: boolean | number;
  show_point: boolean | number;
  intents: string;
  pile_click: string;
  open_with: string;
  tile_sort: string;
  group_same: boolean | number;
  zebra: boolean | number;
  header_style: string;
  icon_frame: string;
  desc_line: string;
  admin_pos: string;
  sound: string;
};

type Preset = { id: string; name: string; desc: string };

type ContextMenuData = {
  right_click_mode: number;
  shift_right_click_mode: number;
  context_menu_style: ContextMenuStyle;
  context_menu_themes: Record<string, ThemeColors>;
  context_menu_presets: Preset[];
  context_menu_preset: string | null;
};

type Option<T> = { value: T; label: string };

const RIGHT_CLICK_MODE_OPTIONS: Option<number>[] = [
  { value: 1, label: 'Меню действий' },
  { value: 2, label: 'Меню BYOND' },
  { value: 0, label: 'Действие' },
];

const RENDERER_OPTIONS: Option<string>[] = [
  { value: 'html', label: 'Окном, чёткий текст' },
  { value: 'map', label: 'На карте' },
];

const THEME_OPTIONS: Option<string>[] = [
  { value: 'dark', label: 'Тёмная' },
  { value: 'slate', label: 'Графит' },
  { value: 'nanotrasen', label: 'Нанотрейзен' },
  { value: 'ocean', label: 'Океан' },
  { value: 'forest', label: 'Лес' },
  { value: 'syndicate', label: 'Синдикат' },
  { value: 'rose', label: 'Роза' },
  { value: 'terminal', label: 'Терминал' },
  { value: 'brass', label: 'Латунь' },
  { value: 'cult', label: 'Культ' },
  { value: 'mono', label: 'Монохром' },
  { value: 'light', label: 'Светлая' },
  { value: 'contrast', label: 'Контрастная' },
  { value: 'amber', label: 'Янтарь' },
  { value: 'neon', label: 'Неон' },
  { value: 'ice', label: 'Иней' },
  { value: 'plasma', label: 'Плазма' },
  { value: 'paper', label: 'Бумага' },
];

const FONT_OPTIONS: Option<string>[] = [
  { value: 'segoe', label: 'Segoe UI' },
  { value: 'calibri', label: 'Calibri' },
  { value: 'candara', label: 'Candara' },
  { value: 'tahoma', label: 'Tahoma' },
  { value: 'verdana', label: 'Verdana' },
  { value: 'arial', label: 'Arial (окном)' },
  { value: 'trebuchet', label: 'Trebuchet (окном)' },
  { value: 'georgia', label: 'Georgia (окном)' },
  { value: 'consolas', label: 'Consolas (окном)' },
  { value: 'pixel', label: 'Пиксельный' },
];

const WEIGHT_OPTIONS: Option<string>[] = [
  { value: 'normal', label: 'Обычный' },
  { value: 'medium', label: 'Полужирный' },
  { value: 'bold', label: 'Жирный' },
];

const LAYOUT_OPTIONS: Option<string>[] = [
  { value: 'list', label: 'Список' },
  { value: 'columns', label: 'Две колонки' },
  { value: 'pills', label: 'Плашки' },
];

const WIDTH_OPTIONS: Option<string>[] = [
  { value: 'auto', label: 'По тексту' },
  { value: 'narrow', label: 'Узкое' },
  { value: 'wide', label: 'Широкое' },
];

const HOVER_OPTIONS: Option<string>[] = [
  { value: 'fill', label: 'Заливка' },
  { value: 'accent', label: 'Полоска акцента' },
  { value: 'outline', label: 'Рамка' },
  { value: 'invert', label: 'Инверсия' },
];

const ICON_SIZE_OPTIONS: Option<number>[] = [16, 24, 32].map((value) => ({
  value,
  label: `${value} px`,
}));

const ICON_SIDE_OPTIONS: Option<string>[] = [
  { value: 'left', label: 'Слева' },
  { value: 'right', label: 'Справа' },
];

const SCALE_OPTIONS: Option<number>[] = [80, 90, 100, 110, 125, 150, 200].map(
  (value) => ({
    value,
    label: `${value}%`,
  }),
);

const DENSITY_OPTIONS: Option<string>[] = [
  { value: 'compact', label: 'Плотные' },
  { value: 'normal', label: 'Обычные' },
  { value: 'roomy', label: 'Просторные' },
];

const ANIMATION_OPTIONS: Option<string>[] = [
  { value: 'none', label: 'Без анимации' },
  { value: 'fade', label: 'Проявление' },
  { value: 'slide', label: 'Выезд снизу' },
  { value: 'zoom', label: 'Раскрытие' },
  { value: 'drop', label: 'Шторка' },
  { value: 'cascade', label: 'Каскад' },
];

const HINT_OPTIONS: Option<string>[] = [
  { value: 'none', label: 'Не показывать' },
  { value: 'hover', label: 'Внизу при наведении' },
  { value: 'inline', label: 'В строке справа' },
];

const POSITION_OPTIONS: Option<string>[] = [
  { value: 'right', label: 'Справа от курсора' },
  { value: 'left', label: 'Слева от курсора' },
  { value: 'center', label: 'Под курсором' },
  { value: 'above', label: 'Над курсором' },
];

const SPEED_OPTIONS: Option<string>[] = [
  { value: 'normal', label: 'Обычная' },
  { value: 'fast', label: 'Быстрая' },
  { value: 'slow', label: 'Медленная' },
];

const PAGE_ROWS_OPTIONS: Option<number>[] = [8, 10, 14, 20].map((value) => ({
  value,
  label: `${value}`,
}));

const ACCENT_SWATCHES = [
  '#7c8cff',
  '#4ea1ff',
  '#38d9c0',
  '#6dff6d',
  '#ffd400',
  '#ff9b3d',
  '#ff3b3b',
  '#ff2d6a',
  '#c77dff',
  '#ffffff',
];

const FONT_FAMILIES: Record<string, string> = {
  segoe: "'Segoe UI', sans-serif",
  calibri: 'Calibri, sans-serif',
  candara: 'Candara, sans-serif',
  tahoma: 'Tahoma, sans-serif',
  verdana: 'Verdana, sans-serif',
  arial: 'Arial, sans-serif',
  trebuchet: "'Trebuchet MS', sans-serif",
  georgia: 'Georgia, serif',
  consolas: 'Consolas, monospace',
  pixel: "'Lucida Console', Consolas, monospace",
};

const FONT_WEIGHTS: Record<string, number> = { normal: 400, medium: 600, bold: 700 };

const DENSITY_PADDING: Record<string, number> = {
  compact: 0,
  normal: 2,
  roomy: 4,
};

const DropdownRow = <T extends number | string>(props: {
  label: string;
  hint?: string;
  options: Option<T>[];
  value: T;
  onSelect: (value: T) => void;
}) => {
  const { label, hint, options, value, onSelect } = props;
  return (
    <Stack.Item>
      <Stack align="center" fill className="GamePreferences__row">
        <Stack.Item grow basis={0}>
          <div className="GamePreferences__label">{label}</div>
          {hint && <div className="GamePreferences__hint">{hint}</div>}
        </Stack.Item>
        <Stack.Item>
          <Dropdown
            width="190px"
            options={options.map((o) => o.label)}
            selected={
              options.find((o) => o.value === value)?.label || options[0].label
            }
            onSelected={(selected) => {
              const opt = options.find((o) => o.label === selected);
              if (opt) onSelect(opt.value);
            }}
          />
        </Stack.Item>
      </Stack>
    </Stack.Item>
  );
};

const PREVIEW_ROWS = [
  { name: 'Осмотреть', hint: 'Shift-ЛКМ', kind: 'current' },
  { name: 'Потянуть', hint: 'Ctrl-ЛКМ', kind: 'hover' },
  { name: 'Ударить', hint: 'ЛКМ, вред', kind: 'danger' },
  { name: 'Интенты…', hint: '', kind: 'service' },
  { name: 'Админ…', hint: '', kind: 'admin' },
];

/** Примерный вид меню: тот же расчёт размеров, что у меню окном в игре; значки - цветные квадраты */
const MenuPreview = (props: {
  style: ContextMenuStyle;
  theme: ThemeColors;
}) => {
  const { style, theme } = props;
  const accent = style.accent || theme.accent;
  const scale = style.scale / 100;
  const fontPx = Math.round(12 * scale);
  const iconPx = style.icons ? Math.round(style.icon_size * scale) : 0;
  const rowPx = Math.max(
    Math.round((20 + (DENSITY_PADDING[style.density] ?? 0) * 2) * scale),
    iconPx + 4,
  );
  const pad = Math.round(6 * scale);
  const listLayout = style.layout === 'list';
  const rowBox = (
    background: string,
    color: string,
    kind: string,
  ): Record<string, string | number> => {
    let bg = background;
    let fg = color;
    let shadow = 'none';
    if (style.stripe && (kind === 'current' || kind === 'admin')) {
      shadow = `inset ${Math.max(2, Math.round(3 * scale))}px 0 0 ${accent}`;
    }
    if (kind === 'hover') {
      if (style.hover === 'accent') {
        shadow = `inset 3px 0 0 ${accent}`;
        bg = theme.current_bg;
      } else if (style.hover === 'outline') {
        shadow = `inset 0 0 0 1px ${accent}`;
      } else if (style.hover === 'invert') {
        bg = color;
        fg = background;
      } else {
        bg = theme.hover_bg;
      }
    }
    return {
      height: `${rowPx}px`,
      padding: `0 ${pad}px`,
      background: bg,
      color: fg,
      boxShadow: shadow,
      display: 'flex',
      alignItems: 'center',
      gap: `${pad}px`,
      whiteSpace: 'nowrap',
      marginBottom: style.separators ? '1px' : '0',
      margin: style.layout === 'pills' ? `${Math.round(2 * scale)}px` : undefined,
      borderRadius: style.layout === 'pills' ? '3px' : undefined,
    };
  };
  const rowColors = (kind: string): [string, string] => {
    switch (kind) {
      case 'current':
        return [theme.current_bg, theme.text];
      case 'danger':
        return [theme.row_bg, theme.danger];
      case 'service':
        return [theme.row_bg, theme.service];
      case 'admin':
        return [theme.admin_bg, theme.admin_text];
      default:
        return [theme.row_bg, theme.text];
    }
  };
  const icon = (n: number) =>
    iconPx ? (
      <span
        style={{
          width: `${iconPx}px`,
          height: `${iconPx}px`,
          flex: '0 0 auto',
          background: ['#8a6d3b', '#6b8fbf', '#9c5a5a', '#5a9c6b', '#9c8a5a'][n % 5],
          borderRadius: style.icon_frame === 'round' ? '50%' : undefined,
          outline:
            style.icon_frame !== 'none'
              ? `${Math.max(1, Math.round(iconPx / 10))}px solid ${hexRgba(theme.text, 0.12)}`
              : undefined,
        }}
      />
    ) : null;
  const rows = style.layout === 'list' ? PREVIEW_ROWS : PREVIEW_ROWS.slice(0, 4);
  let headerBg = theme.header_bg;
  let headerText = theme.header_text;
  let modeText = theme.mode_text;
  if (style.header_style === 'accent') {
    headerBg = accent;
    headerText = contrastText(accent);
    modeText = hexRgba(headerText === '#ffffff' ? '#ffffff' : '#000000', 0.6);
  } else if (style.header_style === 'line') {
    headerBg = theme.row_bg;
  }
  return (
    <Box
      style={{
        display: 'inline-block',
        fontFamily: FONT_FAMILIES[style.font] ?? FONT_FAMILIES.segoe,
        fontSize: `${fontPx}px`,
        fontWeight: FONT_WEIGHTS[style.weight] ?? 400,
        border: style.border ? `1px solid ${style.accent || theme.border}` : 'none',
        background: style.separators ? style.accent || theme.border : theme.row_bg,
        textShadow: style.outline ? `0 0 2px ${theme.outline}` : 'none',
        textTransform: style.caps ? 'uppercase' : 'none',
        maxWidth: style.layout === 'pills' ? `${Math.round(320 * scale)}px` : undefined,
      }}
    >
      {!!style.header && (
        <div
          style={{
            ...rowBox(headerBg, headerText, 'header'),
            boxShadow:
              style.header_style === 'line'
                ? `inset 0 -${Math.max(2, Math.round(2 * scale))}px 0 ${accent}`
                : 'none',
          }}
        >
          <span style={{ flex: '1 1 auto', fontWeight: 700 }}>Ящик с инструментами</span>
          <span style={{ color: modeText }}>режим</span>
        </div>
      )}
      {!!style.header && style.desc_line === 'line' && (
        <div
          style={{
            padding: `${Math.round(2 * scale)}px ${pad}px`,
            fontSize: `${Math.round(fontPx * 0.85)}px`,
            fontWeight: 400,
            textTransform: 'none',
            background: headerBg,
            color: style.header_style === 'accent' ? modeText : theme.service,
          }}
        >
          Ящик со стандартным набором инструментов
        </div>
      )}
      <div
        style={{
          display: style.layout === 'list' ? 'block' : style.layout === 'columns' ? 'grid' : 'flex',
          gridTemplateColumns: style.layout === 'columns' ? '1fr 1fr' : undefined,
          flexWrap: style.layout === 'pills' ? 'wrap' : undefined,
        }}
      >
        {rows.map((row, i) => {
          const [background, color] = rowColors(row.kind === 'hover' ? 'normal' : row.kind);
          const side = style.icon_side === 'right';
          const box = rowBox(background, color, row.kind);
          if (style.zebra && i % 2 && row.kind !== 'current' && row.kind !== 'admin' && row.kind !== 'hover') {
            const band = hexRgba(theme.text, 0.06);
            box.background = `linear-gradient(${band}, ${band}), ${background}`;
          }
          return (
            <div key={row.name} style={box}>
              {!side && icon(i)}
              <span style={{ flex: '1 1 auto' }}>{row.name}</span>
              {listLayout && style.hints === 'inline' && row.hint && (
                <span style={{ color: theme.hint_text, fontWeight: 400 }}>{row.hint}</span>
              )}
              {side && icon(i)}
            </div>
          );
        })}
      </div>
      {style.hints === 'hover' && (
        <div
          style={{
            height: `${Math.round(rowPx * 0.85)}px`,
            lineHeight: `${Math.round(rowPx * 0.85)}px`,
            padding: `0 ${pad}px`,
            fontSize: `${Math.round(fontPx * 0.9)}px`,
            background: theme.hint_bg,
            color: theme.hint_text,
          }}
        >
          Ctrl-ЛКМ
        </div>
      )}
    </Box>
  );
};

const TEXT_SIZE_OPTIONS: Option<number>[] = [11, 12, 13, 14, 16].map((value) => ({
  value,
  label: `${value} px`,
}));

const HINT_STYLE_OPTIONS: Option<string>[] = [
  { value: 'text', label: 'Текстом' },
  { value: 'badge', label: 'Плашками клавиш' },
];

const OFFSET_OPTIONS: Option<number>[] = [
  { value: 4, label: 'Вплотную' },
  { value: 12, label: 'С отступом' },
  { value: 24, label: 'Подальше' },
];

const CLOSE_ON_MOVE_OPTIONS: Option<string>[] = [
  { value: 'far', label: 'Когда объект далеко' },
  { value: 'always', label: 'При любом шаге' },
  { value: 'never', label: 'Не закрывать' },
];

const AUTO_CLOSE_OPTIONS: Option<number>[] = [
  { value: 0, label: 'Нет' },
  { value: 3, label: 'Через 3 с' },
  { value: 6, label: 'Через 6 с' },
];

const DANGER_ORDER_OPTIONS: Option<string>[] = [
  { value: 'normal', label: 'Как есть' },
  { value: 'bottom', label: 'В конце списка' },
];

const INTENTS_OPTIONS: Option<string>[] = [
  { value: 'submenu', label: 'В подменю «Интенты…»' },
  { value: 'inline', label: 'Сразу в списке' },
];

const OPEN_WITH_OPTIONS: Option<string>[] = [
  { value: 'target', label: 'Действия объекта под курсором' },
  { value: 'tile', label: 'Список клетки, действия - по клику' },
];

const TILE_SORT_OPTIONS: Option<string>[] = [
  { value: 'layer', label: 'Как лежат, верхние первыми' },
  { value: 'name', label: 'По алфавиту' },
];

const HEADER_STYLE_OPTIONS: Option<string>[] = [
  { value: 'plain', label: 'Цвета темы' },
  { value: 'accent', label: 'Цвета акцента' },
  { value: 'line', label: 'Линия акцента снизу' },
];

const ICON_FRAME_OPTIONS: Option<string>[] = [
  { value: 'none', label: 'Нет' },
  { value: 'tile', label: 'Квадрат' },
  { value: 'round', label: 'Круг' },
];

const DESC_LINE_OPTIONS: Option<string>[] = [
  { value: 'tooltip', label: 'При наведении на шапку' },
  { value: 'line', label: 'Строкой под шапкой' },
  { value: 'none', label: 'Не показывать' },
];

/** Чёрный или белый текст поверх цвета - как в меню */
const contrastText = (hex: string) => {
  const n = parseInt(hex.replace('#', ''), 16) || 0;
  const luma = 0.299 * ((n >> 16) & 255) + 0.587 * ((n >> 8) & 255) + 0.114 * (n & 255);
  return luma > 150 ? '#101010' : '#ffffff';
};

const hexRgba = (hex: string, alpha: number) => {
  const n = parseInt(hex.replace('#', ''), 16) || 0;
  return `rgba(${(n >> 16) & 255},${(n >> 8) & 255},${n & 255},${alpha})`;
};

const PILE_CLICK_OPTIONS: Option<string>[] = [
  { value: 'take', label: 'Взять, действия - ПКМ по строке' },
  { value: 'actions', label: 'Открыть действия вещи' },
];

const ADMIN_POS_OPTIONS: Option<string>[] = [
  { value: 'bottom', label: 'Внизу каждой страницы' },
  { value: 'top', label: 'Вверху' },
  { value: 'hidden', label: 'Скрыть' },
];

const SOUND_OPTIONS: Option<string>[] = [
  { value: 'off', label: 'Без звука' },
  { value: 'click', label: 'Щелчок' },
  { value: 'soft', label: 'Мягкий' },
];

const GroupTitle = (props: { title: string }) => (
  <Stack.Item>
    <div
      className="GamePreferences__label"
      style={{
        marginTop: '0.6em',
        paddingBottom: '0.2em',
        borderBottom: '1px solid rgba(255, 255, 255, 0.15)',
        fontWeight: 'bold',
      }}
    >
      {props.title}
    </div>
  </Stack.Item>
);

export const ContextMenuSection = (props) => {
  const { act, data } = useBackend<ContextMenuData>();
  const rightClickMode = Number(data.right_click_mode ?? 1);
  const shiftRightClickMode = Number(data.shift_right_click_mode ?? 0);
  const style = data.context_menu_style;
  const themes = data.context_menu_themes || {};
  if (!style) {
    return null;
  }
  const setStyle = (key: string, value?: number | string | boolean) =>
    act('set_context_menu_style', { key, value });
  const toggle = (key: string) => setStyle(key, style[key] ? 0 : 1);
  const theme = themes[style.theme] || themes.dark;
  const html = style.renderer === 'html';

  return (
    <Stack vertical>
      <GroupTitle title="Кнопки" />
      <DropdownRow
        label="ПКМ"
        hint="Действие - второе действие сразу (толкнуть, открыть сумку не снимая, постучать). Меню действий - меню у курсора. Меню BYOND - как раньше. В комбат-режиме и в мехе ПКМ всегда действие, в дизарме ПКМ по человеку рядом - толчок. Быстро переключить - верб «Режим ПКМ» во вкладке OOC или клик по шапке меню"
        options={RIGHT_CLICK_MODE_OPTIONS}
        value={rightClickMode}
        onSelect={(value) => act('set_right_click_mode', { value })}
      />
      <DropdownRow
        label="Shift+ПКМ"
        hint="Например, ПКМ - действие, а Shift+ПКМ - меню BYOND"
        options={RIGHT_CLICK_MODE_OPTIONS}
        value={shiftRightClickMode}
        onSelect={(value) => act('set_shift_right_click_mode', { value })}
      />

      <GroupTitle title="Готовые наборы" />
      <Stack.Item>
        <div className="GamePreferences__hint">
          Набор меняет вид меню. Раскладку ПКМ и поведение (что открывать, клики по списку), если сам их не задаёт, не трогает. В игре - верб «Вид меню ПКМ» во вкладке OOC
        </div>
        <Stack wrap="wrap" mt={0.5}>
          {(data.context_menu_presets || []).map((preset) => (
            <Stack.Item key={preset.id} mb={0.5}>
              <Button
                selected={data.context_menu_preset === preset.id}
                tooltip={preset.desc}
                onClick={() => act('apply_context_menu_preset', { preset: preset.id })}
              >
                {preset.name}
              </Button>
            </Stack.Item>
          ))}
          <Stack.Item mb={0.5}>
            <Button icon="undo" onClick={() => act('reset_context_menu_style')}>
              По умолчанию
            </Button>
          </Stack.Item>
        </Stack>
      </Stack.Item>
      {!!theme && (
        <Stack.Item>
          <Stack align="center" fill className="GamePreferences__row">
            <Stack.Item grow basis={0}>
              <div className="GamePreferences__label">Так будет выглядеть меню</div>
              <div className="GamePreferences__hint">
                Примерно; значки здесь - цветные квадраты, анимация видна при открытии в игре
              </div>
            </Stack.Item>
            <Stack.Item>
              <MenuPreview style={style} theme={theme} />
            </Stack.Item>
          </Stack>
        </Stack.Item>
      )}

      <GroupTitle title="Вид" />
      <DropdownRow
        label="Как рисовать"
        hint="Окном - текст как в остальном интерфейсе, без пикселей. На карте - надписи на самой карте, там работают прозрачность и тень"
        options={RENDERER_OPTIONS}
        value={style.renderer}
        onSelect={(value) => setStyle('renderer', value)}
      />
      <DropdownRow
        label="Формат"
        hint="Две колонки и плашки - только окном; хоткеи там во всплывающей подсказке"
        options={LAYOUT_OPTIONS}
        value={style.layout}
        onSelect={(value) => setStyle('layout', value)}
      />
      <DropdownRow label="Тема" options={THEME_OPTIONS} value={style.theme} onSelect={(value) => setStyle('theme', value)} />
      <DropdownRow label="Размер меню" options={SCALE_OPTIONS} value={Number(style.scale)} onSelect={(value) => setStyle('scale', value)} />
      <DropdownRow label="Строки" options={DENSITY_OPTIONS} value={style.density} onSelect={(value) => setStyle('density', value)} />
      <DropdownRow label="Ширина" options={WIDTH_OPTIONS} value={style.width} onSelect={(value) => setStyle('width', value)} />
      <DropdownRow
        label="Подсветка строки под курсором"
        options={HOVER_OPTIONS}
        value={style.hover}
        onSelect={(value) => setStyle('hover', value)}
      />
      <Stack.Item>
        <Stack align="center" fill className="GamePreferences__row">
          <Stack.Item grow basis={0}>
            <div className="GamePreferences__label">Цвет акцента</div>
            <div className="GamePreferences__hint">Полоска у основного действия и рамка. Пусто - цвет темы</div>
          </Stack.Item>
          <Stack.Item>
            <Stack align="center">
              {ACCENT_SWATCHES.map((color) => (
                <Stack.Item key={color}>
                  <Button compact selected={style.accent === color} tooltip={color} onClick={() => setStyle('accent', color)}>
                    <ColorBox color={color} />
                  </Button>
                </Stack.Item>
              ))}
              <Stack.Item>
                <Input
                  width="70px"
                  placeholder="#rrggbb"
                  value={style.accent}
                  onChange={(e, value) => setStyle('accent', value.trim())}
                />
              </Stack.Item>
              <Stack.Item>
                <Button icon="times" tooltip="Цвет темы" onClick={() => setStyle('accent', '')} />
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <PrefRow label="Рамка" checked={!!style.border} tooltip="Тонкая рамка цвета темы или акцента" onClick={() => toggle('border')} />
      <PrefRow label="Полоска у основного действия" checked={!!style.stripe} tooltip="У действия текущего интента и у «Админ…»" onClick={() => toggle('stripe')} />
      <PrefRow label="Разделители строк" checked={!!style.separators} tooltip="Линия в пиксель между строками" onClick={() => toggle('separators')} />
      <PrefRow label="Шапка с именем" checked={!!style.header} tooltip="Без шапки режим ПКМ меняется только вербом «Режим ПКМ» и здесь" onClick={() => toggle('header')} />
      {html && (
        <>
          <DropdownRow label="Цвет шапки" options={HEADER_STYLE_OPTIONS} value={style.header_style} onSelect={(value) => setStyle('header_style', value)} />
          <DropdownRow label="Описание объекта" options={DESC_LINE_OPTIONS} value={style.desc_line} onSelect={(value) => setStyle('desc_line', value)} />
          <PrefRow label="Полосатые строки" checked={!!style.zebra} tooltip="Каждая вторая строка чуть светлее: в длинном списке глазу легче" onClick={() => toggle('zebra')} />
        </>
      )}
      {!html && (
        <>
          <Stack.Item>
            <Stack align="center" fill className="GamePreferences__row">
              <Stack.Item grow basis={0}>
                <div className="GamePreferences__label">Непрозрачность фона</div>
                <div className="GamePreferences__hint">40 - сквозь меню видно карту, 100 - сплошной фон</div>
              </Stack.Item>
              <Stack.Item>
                <NumberInput
                  width="80px"
                  minValue={40}
                  maxValue={100}
                  step={5}
                  value={Number(style.opacity ?? 92)}
                  onChange={(e, value) => setStyle('opacity', value)}
                />
              </Stack.Item>
            </Stack>
          </Stack.Item>
          <PrefRow label="Тень" checked={!!style.shadow} tooltip="Полупрозрачная тень под меню" onClick={() => toggle('shadow')} />
        </>
      )}

      <GroupTitle title="Текст" />
      <DropdownRow
        label="Шрифт"
        hint="Шрифты с пометкой «окном» на карте заменяются Calibri"
        options={FONT_OPTIONS}
        value={style.font}
        onSelect={(value) => setStyle('font', value)}
      />
      {html && (
        <DropdownRow
          label="Размер текста"
          hint="Отдельно от размера меню"
          options={TEXT_SIZE_OPTIONS}
          value={Number(style.text_size)}
          onSelect={(value) => setStyle('text_size', value)}
        />
      )}
      <DropdownRow label="Начертание" options={WEIGHT_OPTIONS} value={style.weight} onSelect={(value) => setStyle('weight', value)} />
      <PrefRow label="ЗАГЛАВНЫЕ БУКВЫ" checked={!!style.caps} onClick={() => toggle('caps')} />
      <PrefRow label="Обводка текста" checked={!!style.outline} tooltip="Тёмная обводка букв" onClick={() => toggle('outline')} />

      <GroupTitle title="Хоткеи" />
      <DropdownRow label="Подсказки управления" hint="Какой кнопкой то же действие без меню (Shift-ЛКМ, Ctrl-ЛКМ). В строке справа меню заметно шире" options={HINT_OPTIONS} value={style.hints} onSelect={(value) => setStyle('hints', value)} />
      {html && (
        <DropdownRow label="Вид хоткеев" options={HINT_STYLE_OPTIONS} value={style.hint_style} onSelect={(value) => setStyle('hint_style', value)} />
      )}

      <GroupTitle title="Значки" />
      <PrefRow label="Значки объектов" checked={!!style.icons} tooltip="Картинка объекта в строке; у людей значка нет" onClick={() => toggle('icons')} />
      <DropdownRow label="Размер значков" options={ICON_SIZE_OPTIONS} value={Number(style.icon_size)} onSelect={(value) => setStyle('icon_size', value)} />
      {html && (
        <>
          <DropdownRow label="Где значки" options={ICON_SIDE_OPTIONS} value={style.icon_side} onSelect={(value) => setStyle('icon_side', value)} />
          <DropdownRow label="Подложка значков" options={ICON_FRAME_OPTIONS} value={style.icon_frame} onSelect={(value) => setStyle('icon_frame', value)} />
          <PrefRow label="Значок в шапке" checked={!!style.header_icon} tooltip="Картинка объекта рядом с его именем; описание объекта - при наведении на шапку" onClick={() => toggle('header_icon')} />
        </>
      )}

      <GroupTitle title="Содержимое" />
      <DropdownRow label="Интенты" options={INTENTS_OPTIONS} value={style.intents} onSelect={(value) => setStyle('intents', value)} />
      <DropdownRow
        label="Что открывать"
        hint="Список клетки - если под курсором больше одного объекта, сперва выбор из них"
        options={OPEN_WITH_OPTIONS}
        value={style.open_with}
        onSelect={(value) => setStyle('open_with', value)}
      />
      <DropdownRow label="Порядок в списке клетки" options={TILE_SORT_OPTIONS} value={style.tile_sort} onSelect={(value) => setStyle('tile_sort', value)} />
      <PrefRow
        label="Одинаковые вещи одной строкой"
        checked={!!style.group_same}
        tooltip="Несколько одинаковых - одна строка со счётом, ЛКМ берёт одну. Выключено - каждая вещь своей строкой"
        onClick={() => toggle('group_same')}
      />
      <DropdownRow
        label="ЛКМ по вещи в списке клетки"
        hint="Занята активная рука - берёт вторая, свободная"
        options={PILE_CLICK_OPTIONS}
        value={style.pile_click}
        onSelect={(value) => setStyle('pile_click', value)}
      />
      <DropdownRow
        label="Опасные действия"
        hint="Ударить, обезоружить, схватить - после остальных, чтобы не попасть по ним случайно"
        options={DANGER_ORDER_OPTIONS}
        value={style.danger_order}
        onSelect={(value) => setStyle('danger_order', value)}
      />
      <PrefRow
        label="Переспрашивать опасные действия"
        checked={!!style.confirm_danger}
        tooltip="Первый клик по опасному пункту показывает «Точно?», второй - выполняет"
        onClick={() => toggle('confirm_danger')}
      />
      <PrefRow label="Пункт «Осмотреть»" checked={!!style.show_examine} tooltip="Осмотр есть и на Shift+ЛКМ" onClick={() => toggle('show_examine')} />
      <PrefRow label="Пункт «Указать»" checked={!!style.show_point} tooltip="Указать есть и на Shift+СКМ" onClick={() => toggle('show_point')} />
      <DropdownRow label="Пунктов на странице" hint="Остальные - за пунктом «Ещё…» или прокруткой" options={PAGE_ROWS_OPTIONS} value={Number(style.page_rows)} onSelect={(value) => setStyle('page_rows', value)} />
      <DropdownRow label="«Админ…» (только админам)" options={ADMIN_POS_OPTIONS} value={style.admin_pos} onSelect={(value) => setStyle('admin_pos', value)} />

      <GroupTitle title="Поведение" />
      <DropdownRow label="Где открывать" options={POSITION_OPTIONS} value={style.position} onSelect={(value) => setStyle('position', value)} />
      <DropdownRow label="Отступ от курсора" options={OFFSET_OPTIONS} value={Number(style.offset)} onSelect={(value) => setStyle('offset', value)} />
      <DropdownRow label="Закрывать на ходу" options={CLOSE_ON_MOVE_OPTIONS} value={style.close_on_move} onSelect={(value) => setStyle('close_on_move', value)} />
      {html && (
        <DropdownRow
          label="Закрывать, если курсор ушёл"
          options={AUTO_CLOSE_OPTIONS}
          value={Number(style.auto_close)}
          onSelect={(value) => setStyle('auto_close', value)}
        />
      )}
      <DropdownRow label="Анимация открытия" options={ANIMATION_OPTIONS} value={style.animation} onSelect={(value) => setStyle('animation', value)} />
      <DropdownRow label="Скорость анимации" options={SPEED_OPTIONS} value={style.anim_speed} onSelect={(value) => setStyle('anim_speed', value)} />
      <PrefRow label="Плавная подсветка" checked={!!style.smooth_hover} tooltip="Строка под курсором подсвечивается плавно" onClick={() => toggle('smooth_hover')} />
      <DropdownRow label="Звук" options={SOUND_OPTIONS} value={style.sound} onSelect={(value) => setStyle('sound', value)} />
    </Stack>
  );
};

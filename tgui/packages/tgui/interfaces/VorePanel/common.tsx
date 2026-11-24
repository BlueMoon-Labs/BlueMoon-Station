/**
 * Общие куски воре-панели
 */

import { useEffect, useState } from 'react';

import { useBackend } from '../../backend';
import {
  Box,
  Button,
  Dropdown,
  Input,
  LabeledList,
  NumberInput,
  Stack,
  TextArea,
  Tooltip,
} from '../../components';

export interface VoreContent {
  name: string;
  ref: string;
  /** /mob stat: 0 - в сознании, 1 - мягкий крит, 2 - крит, 3 - мёртв */
  stat: number;
  absorbed: boolean;
  /** base64-иконка, приходит только при включённых картинках */
  icon?: string;
  /** true - содержимое своего нутра, false - мы внутри чужого */
  outside: boolean;
}

export interface BellySummary {
  ref: string;
  name: string;
  display_name?: string;
  digest_mode: string;
  contents: number;
  selected: boolean;
  immutable: boolean;
}

export type MessageKey = 'dmp' | 'dmo' | 'smo' | 'smi' | 'em';

export type MessageText = Record<MessageKey, string>;

export interface BellyState {
  ref: string;
  name: string;
  display_name?: string;
  vore_types: string[];
  mode_addons: string[];
  digest_mode: string;
  digest_modes: string[];
  desc: string;
  absorbed_desc: string;
  vore_verb: string;
  release_verb: string;
  immutable: boolean;

  vore_sound: string;
  vore_sounds: string[];
  release_sound: string;
  release_sounds: string[];
  sound_volume: number;
  noise_freq: number;

  can_taste: boolean;
  feedable: boolean;
  is_wet: boolean;
  wet_loop: boolean;
  can_victim_see: boolean;

  /** доля 0..2, в UI показываем процентами */
  bulge_size: number;
  /** десятичные секунды */
  emote_time: number;
  emote_active: boolean;
  emote_lists: Record<string, string>;
  human_prey_swallow_time: number;
  nonhuman_prey_swallow_time: number;
  digest_brute: number;
  digest_burn: number;
  digest_oxy: number;
  digest_tox: number;
  digest_clone: number;
  nutrition_percent: number;
  item_mode: string;
  belly_temperature: number;
  temperature_damage: boolean;
  vore_capacity: number;

  escapable: boolean;
  escapechance: number;
  escapetime: number;
  transferchance: number;
  transferlocation: string | null;
  destination: string | null;
  transfer_options: string[];
  absorbchance: number;
  digestchance: number;
  autotransferchance: number;
  autotransferwait: number;
  save_digest_mode: boolean;
  eating_privacy: string;
  private_struggle: boolean;
  drain_mode: string;
  entrance_logs: boolean;
  item_digest_logs: boolean;
  absorbedrename_enabled: boolean;
  absorbedrename_name: string;
  belly_fullscreen: string | null;
  fullscreen_color: string | null;
  fullscreen_alpha: number;
  show_liquids: boolean;
  show_liq_fullness: boolean;
  contaminates: boolean;
  contaminate_color: string;
  contaminate_flavor: string;
  liquid_reagent: string;
  liquid_rate: number;
  liquids: Array<{ name: string; volume: number }>;
  liquid_total: number;
  liquid_nutrition: number;

  messages: MessageText;
  absorbed_messages: Partial<MessageText>;
  contents: VoreContent[];
}

export interface InsideState {
  ref: string | null;
  pred?: string;
  absorbed?: boolean;
  belly_name?: string;
  belly_mode?: string;
  desc?: string;
  contents?: VoreContent[];
  /** Заглушка под способности добычи */
  prey_abilities?: unknown[];
}

export interface VorePrefs {
  digestable: boolean;
  devourable: boolean;
  feeding: boolean;
  absorbable: boolean;
  allowmobvore: boolean;
  no_healbelly: boolean;
  no_temperature: boolean;
  no_autotransfer: boolean;
  no_remains: boolean;
  no_afk_prey: boolean;
  no_afk_pred: boolean;
  eating_privacy_global: boolean;
  vore_sounds: boolean;
  digestion_sounds: boolean;
}

export interface VoreLimits {
  name_min: number;
  name_max: number;
  desc_max: number;
  msg_max: number;
}

export interface VorePanelData {
  unsaved_changes: boolean;
  show_pictures: boolean;
  limits: VoreLimits;
  inside: InsideState;
  our_bellies: BellySummary[];
  selected: BellyState | null;
  prefs: VorePrefs;
  vore_type_options?: string[];
  vore_addon_options?: string[];
  liquid_options?: Array<{ name: string; path: string }>;
  has_vore_backup?: boolean;
  export_text?: string | null;
  vore_taste?: string;
  vore_smell?: string;

  // Заглушки под будущие секции
  soulcatcher?: { name?: string } | null;
  abilities?: unknown;
  presets?: unknown;
  general_pref_data?: unknown;
}

/** Подписи режимов нутра */
export const MODE_RU: Record<string, string> = {
  Hold: 'Удержание',
  Digest: 'Переваривание',
  Heal: 'Исцеление',
  Noisy: 'Шумное удержание',
  Dragon: 'Пожирание драконом',
  Absorb: 'Поглощение',
  'Un-absorb': 'Отмена поглощения',
};

export const MODE_COLOR: Record<string, string | null> = {
  Hold: null,
  Digest: 'red',
  Heal: 'green',
  Noisy: 'yellow',
  Dragon: 'blue',
  Absorb: 'purple',
  'Un-absorb': 'purple',
};

/** Что происходит с жертвой в каждом режиме. */
export const MODE_PREY_RU: Record<string, string> = {
  Hold: 'вас удерживают.',
  Digest: 'вас переваривают.',
  Heal: 'вас лечат.',
  Noisy: 'вас удерживают, и довольно громко.',
  Dragon: 'вас переваривает могущественное существо.',
  Absorb: 'вас поглощают.',
  'Un-absorb': 'вас депоглощают.',
};

/** Пресеты частоты звука. */
export const NOISE_PRESETS: Record<string, string> = {
  '0': 'Случайно',
  '28750': 'Низкая',
  '35000': 'Ниже среднего',
  '42500': 'Средняя',
  '50000': 'Выше среднего',
  '56250': 'Высокая',
};

/** Типы нутра ID из GLOB.vore_type_options. */
export const VORE_TYPE_RU: Record<string, string> = {
  'Oral Vore': 'Рот',
  'Anal Vore': 'Анальный',
  'Cock Vore': 'Через член',
  'Sheath Vore': 'В чехол',
  Unbirth: 'Вагинальный',
  'Breast Vore': 'Грудной',
  'Tail Vore': 'Хвостовой',
  Absorption: 'Поглощение',
  'Soul Vore': 'Душа',
  'Hard Vore': 'Жёсткий',
  Other: 'Другое',
};

/** Дополнения режима ID из GLOB.vore_addon_options. */
export const ADDON_RU: Record<string, string> = {
  'TURBO MODE': 'Турбо',
  'Leave Remains': 'Оставлять останки',
  'Absorbed Prey Can Devour': 'Поглощённые могут есть',
};

export const ADDON_TIP: Record<string, string> = {
  'TURBO MODE': 'Переваривание идёт в 6 раз быстрее.',
  'Leave Remains': 'После переваривания остаются останки.',
  'Absorbed Prey Can Devour': 'Поглощённая добыча может есть других.',
};

/** Цвет содержимого по индексу /mob stat. */
export const STAT_COLOR: Array<string | null> = [null, 'average', 'bad'];

/** Списки сообщений нутра: ключ = msgtype в действии set_messages. */
export const MESSAGE_TYPES: Array<{ key: MessageKey; label: string; help: string }> = [
  {
    key: 'dmp',
    label: 'Переваривание (жертве)',
    help: 'Второе лицо ("ты чувствуешь X"). Без %prey.',
  },
  {
    key: 'dmo',
    label: 'Переваривание (вам)',
    help: 'Второе лицо ("ты чувствуешь X"). Без %pred.',
  },
  {
    key: 'smo',
    label: 'Сопротивление (снаружи)',
    help: 'Третье лицо ("%belly %pred дрожит").',
  },
  {
    key: 'smi',
    label: 'Сопротивление (внутри)',
    help: 'Второе лицо ("ты чувствуешь X"). Без %prey.',
  },
  {
    key: 'em',
    label: 'Осмотр (при содержимом)',
    help: 'Третье лицо ("их %belly выпирает").',
  },
];

export const MESSAGE_VARS_HELP =
  'Сообщения разделяются пустой строкой (два Enter). %pred - хищник, ' +
  '%prey - жертва, %belly - нутро, %count - всё содержимое, ' +
  '%countprey - живая добыча. До 10 сообщений, каждое 10-150 символов.';

/** Подпись незаимплементированного поля. */
export const STUB_TEXT = '—';

const stubTip = (field: string) => {
  void field; // ключ
  return 'Пока недоступно на сервере.';
};

/** Подпись строки LabeledList с подсказкой. */
export const TipLabel = (props: { text: string; tip?: string }) =>
  props.tip ? <Tooltip content={<span className="Tooltip__text">{props.tip}</span>} position="right">{props.text}</Tooltip> : props.text

/** Большое поле textarea с кнопкой сохранения. */
export const LongTextField = (props: {
  edit: boolean;
  value: string;
  onSave: (value: string) => void;
  rows?: number;
  placeholder?: string;
}) => {
  const { edit, value, onSave, rows = 10, placeholder } = props;
  const [text, setText] = useState(value);

  useEffect(() => setText(value), [value]);

  if (!edit) {
    return (
      <Box color="label" italic style={{ whiteSpace: 'pre-wrap' }}>
        {value || placeholder || 'Пока пусто.'}
      </Box>
    );
  }

  return (
    <>
      <TextArea
        fluid
        height={`${rows}em`}
        mb={0.5}
        value={text}
        placeholder={placeholder}
        onInput={(_, value) => setText(value)}
      />
      <Button icon="save" onClick={() => onSave(text)}>
        Сохранить
      </Button>
    </>
  );
};

/** Инлайн-заглушка значения. */
export const Stub = (props: { field: string }) => (
  <Tooltip content={stubTip(props.field)}>
    <Box inline italic color="label">
      {STUB_TEXT}
    </Box>
  </Tooltip>
);

/** Заглушка-переключатель. */
export const StubButton = (props: {
  content: string;
  field: string;
  fluid?: boolean;
  color?: string;
}) => (
  <Button
    fluid={props.fluid}
    ellipsis
    disabled
    icon="toggle-off"
    color={props.color}
    tooltip={`${props.content} — ${stubTip(props.field)}`}>
    {props.content}
  </Button>
);

/** Сетка кнопок-заглушек (для свёрнутых секций «не перенесено»). */
export const StubGrid = (props: { items: Array<{ label: string; field: string }> }) => (
  <Box
    style={{
      display: 'grid',
      gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))',
      gap: '0.5em',
    }}>
    {props.items.map((item) => (
      <StubButton key={item.field} fluid content={item.label} field={item.field} />
    ))}
  </Box>
);

/** Текстовое поле с кнопкой применения. */
export const TextField = (props: {
  edit: boolean;
  value: string;
  onSave: (value: string) => void;
  placeholder?: string;
}) => {
  const { edit, value, onSave, placeholder } = props;
  const [text, setText] = useState(value);

  useEffect(() => setText(value), [value]);

  if (!edit) {
    return (
      <Box inline bold>
        {value || <Box inline color="label">{placeholder || STUB_TEXT}</Box>}
      </Box>
    );
  }

  return (
    <Stack align="center">
      <Stack.Item grow basis="0" minWidth={0}>
        <Input
          fluid
          placeholder={placeholder}
          value={text}
          onInput={(_, value) => setText(value)}
          onEnter={(_, value) => onSave(value.trim())}
        />
      </Stack.Item>
      <Stack.Item>
        <Button icon="check" tooltip="Сохранить" onClick={() => onSave(text.trim())}>
          ОК
        </Button>
      </Stack.Item>
    </Stack>
  );
};

/** Числовое поле. factor пересчитывает единицы UI в единицы DM. */
export const NumberField = (props: {
  edit: boolean;
  value: number;
  onSave: (value: number) => void;
  min?: number;
  max?: number;
  step?: number;
  unit?: string;
  factor?: number;
  format?: (value: number) => string;
  tooltip?: string;
}) => {
  const { edit, value, onSave, min = 0, max = 100, step = 1, unit, factor = 1, format, tooltip } =
    props;
  const shown = value * factor;

  if (!edit) {
    return (
      <Box inline bold>
        {format ? format(shown) : shown}
        {unit ? ` ${unit}` : ''}
      </Box>
    );
  }

  return (
    <NumberInput
      width="8ch"
      value={shown}
      minValue={min}
      maxValue={max}
      step={step}
      stepPixelSize={2}
      format={format}
      unit={unit}
      tooltip={tooltip}
      onChange={(_, value) => onSave(value)}
    />
  );
};

/** Выпадающий список. */
export const SelectField = (props: {
  edit: boolean;
  value: string;
  options: string[];
  onSave: (value: string) => void;
  labelOf?: (value: string) => string;
  width?: string;
  color?: string | null;
}) => {
  const { edit, value, options, onSave, labelOf, width, color } = props;
  const label = labelOf ? labelOf(value) : value;

  if (!edit) {
    return (
      <Box inline bold textColor={color || undefined}>
        {label}
      </Box>
    );
  }

  return (
    <Dropdown
      width={width}
      color={color || 'default'}
      options={options.map((o) => ({ value: o, displayText: labelOf ? labelOf(o) : o }))}
      selected={value}
      onSelected={(value) => onSave(String(value))}
    />
  );
};

/** Булев переключатель-пилюля. */
export const ToggleField = (props: {
  edit: boolean;
  value: boolean;
  onToggle: () => void;
  yes?: string;
  no?: string;
  tooltip?: string;
}) => {
  const { edit, value, onToggle, yes = 'Да', no = 'Нет', tooltip } = props;

  if (!edit) {
    return (
      <Box inline bold color={value ? 'good' : 'label'}>
        {value ? yes : no}
      </Box>
    );
  }

  return (
    <Button
      icon={value ? 'toggle-on' : 'toggle-off'}
      selected={value}
      tooltip={tooltip}
      onClick={onToggle}>
      {value ? yes : no}
    </Button>
  );
};

/** Короткая подпись для узких строк полный текст остаётся в тултипе. */
const shortText = (text: string, max = 26) =>
  text && text.length > max ? `${text.slice(0, max - 1)}…` : text;

/** Содержимое нутра. */
export const ContentsList = (props: { contents: VoreContent[]; belly: string }) => {
  const { act, data } = useBackend<VorePanelData>();
  const { contents, belly } = props;

  const pick = (thing: VoreContent) =>
    act(thing.outside ? 'pick_from_outside' : 'pick_from_inside', {
      pick: thing.ref,
      belly,
    });

  if (!contents.length) {
    return (
      <Box color="label" italic>
        Пусто.
      </Box>
    );
  }

  // Режим списка строка на предмет/моба + кнопка вызова меню действий.
  if (!data.show_pictures) {
    return (
      <LabeledList>
        {contents.map((thing) => (
          <LabeledList.Item
            key={thing.ref}
            label={<Tooltip content={thing.name}>{shortText(thing.name, 24)}</Tooltip>}>
            <Button
              fluid
              mt={-1}
              mb={-1}
              color={thing.absorbed ? 'purple' : STAT_COLOR[thing.stat]}
              onClick={() => pick(thing)}>
              Действия
            </Button>
          </LabeledList.Item>
        ))}
      </LabeledList>
    );
  }

  return (
    <Box
      style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
        gap: '0.5em',
      }}>
      {contents.map((thing) => (
        <Box key={thing.ref} mb={1}>
          <Button
            color={thing.absorbed ? 'purple' : STAT_COLOR[thing.stat]}
            tooltip={thing.name}
            onClick={() => pick(thing)}>
            {thing.icon ? (
              <img
                src={`data:image/png;base64,${thing.icon}`}
                width="64px"
                height="64px"
                style={{ imageRendering: 'pixelated', verticalAlign: 'middle' }}
              />
            ) : (
              <Box inline width="64px" textAlign="center">
                ?
              </Box>
            )}
          </Button>
          <Box
            inline
            ml={0.5}
            title={thing.name}
            style={{
              display: 'inline-block',
              maxWidth: 'calc(100% - 72px)',
              overflow: 'hidden',
              textOverflow: 'ellipsis',
              whiteSpace: 'nowrap',
              verticalAlign: 'middle',
            }}>
            {thing.name}
          </Box>
        </Box>
      ))}
    </Box>
  );
};

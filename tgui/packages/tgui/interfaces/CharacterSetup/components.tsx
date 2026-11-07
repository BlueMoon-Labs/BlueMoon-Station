import { sortBy } from 'common/collections';
import {
  Children,
  ComponentProps,
  isValidElement,
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
} from 'react';

import { useBackend } from '../../backend';
import {
  Box,
  Button,
  Dropdown,
  Input,
  NoticeBox,
  NumberInput,
  Stack,
  TextArea,
  Tooltip,
} from '../../components';
import {
  ColorPicker,
  normalizeHex,
  safeHex,
  uppercaseHexInput,
} from '../../components/ColorPicker';

export type AppearanceSubTab = 'body' | 'parts' | 'genitals';

let appearanceSubTab: AppearanceSubTab = 'body';
const appearanceSubTabListeners = new Set<() => void>();

export const getAppearanceSubTab = (): AppearanceSubTab => appearanceSubTab;

export const setAppearanceSubTab = (next: AppearanceSubTab) => {
  if (appearanceSubTab === next) {
    return;
  }
  appearanceSubTab = next;
  appearanceSubTabListeners.forEach((listener) => listener());
};

export const subscribeAppearanceSubTab = (listener: () => void) => {
  appearanceSubTabListeners.add(listener);
  return () => {
    appearanceSubTabListeners.delete(listener);
  };
};

let appearanceSplitView = true;
const appearanceSplitViewListeners = new Set<() => void>();

export const getAppearanceSplitView = (): boolean => appearanceSplitView;

export const setAppearanceSplitView = (next: boolean) => {
  if (appearanceSplitView === next) {
    return;
  }
  appearanceSplitView = next;
  appearanceSplitViewListeners.forEach((listener) => listener());
};

export const subscribeAppearanceSplitView = (listener: () => void) => {
  appearanceSplitViewListeners.add(listener);
  return () => {
    appearanceSplitViewListeners.delete(listener);
  };
};

export const SettingsGrid = (props: {
  compact?: boolean;
  children: React.ReactNode;
}) => {
  const gridRef = useRef<HTMLDivElement>(null);

  useLayoutEffect(() => {
    const grid = gridRef.current;
    if (!grid) return;
    let frame = 0;
    let contents: HTMLElement[] = [];
    const measure = () => {
      // Сначала все чтения размеров, затем записи: не заставляем браузер пересчитывать сетку после каждой карточки.
      const spans = contents.map((content) =>
        `span ${Math.max(1, Math.ceil(content.offsetHeight))}`
      );
      contents.forEach((content, index) => {
        const item = content.parentElement!;
        const span = spans[index];
        if (item.style.gridRowEnd !== span) item.style.gridRowEnd = span;
      });
    };
    const schedule = () => {
      cancelAnimationFrame(frame);
      frame = requestAnimationFrame(measure);
    };
    const observer = new ResizeObserver(schedule);
    const syncContents = () => {
      const next = Array.from(grid.children).map(
        (item) => item.firstElementChild as HTMLElement
      );
      for (const content of contents) {
        if (!next.includes(content)) observer.unobserve(content);
      }
      for (const content of next) {
        if (!contents.includes(content)) observer.observe(content);
      }
      contents = next;
      measure();
    };
    // Наблюдатель живёт до размонтирования сетки; обычное обновление данных его не пересоздаёт.
    const mutations = new MutationObserver(syncContents);
    mutations.observe(grid, { childList: true });
    syncContents();
    return () => {
      observer.disconnect();
      mutations.disconnect();
      cancelAnimationFrame(frame);
    };
  }, []);

  return (
    <div
      ref={gridRef}
      className={
        'CharacterSetup__settings-grid' +
        (props.compact ? ' CharacterSetup__settings-grid--compact' : '')
      }
    >
      {Children.toArray(props.children).map((child, index) => (
        <div
          key={isValidElement(child) ? (child.key ?? index) : index}
          className="CharacterSetup__settings-item"
        >
          <div className="CharacterSetup__settings-content">{child}</div>
        </div>
      ))}
    </div>
  );
};

export const quirkColor = (value: number): string | undefined => {
  if (value > 0) return 'good';
  if (value < 0) return 'bad';
  return undefined;
};

export const QuirkNames = (props: {
  names: string[];
  values?: Record<string, number>;
}) => (
  <>
    {sortBy((name: string) => {
      const value = props.values?.[name] ?? 0;
      return value > 0 ? 0 : value < 0 ? 1 : 2;
    })(props.names).map((name, index) => (
      <span key={name}>
        {index > 0 && ', '}
        <Box as="span" color={quirkColor(props.values?.[name] ?? 0)}>
          {name}
        </Box>
      </span>
    ))}
  </>
);

export const TabDataMissing = (props: { title: string }) => (
  <NoticeBox>
    Сервер ещё не прислал данные вкладки «{props.title}». Если сообщение не
    пропадает - обновите окно и проверьте лог сервера на runtime-ошибки.
  </NoticeBox>
);

export type SelectOption =
  | string
  | { value: string | number; label?: string; displayText?: string };

export type ActParams = Record<string, string | number | boolean>;

export type TooltipPosition = ComponentProps<typeof Tooltip>['position'];

export const FieldRow = (props: {
  label: string;
  tooltip?: string;
  labelBasis?: string;
  tooltipPosition?: TooltipPosition;
  children: React.ReactNode;
}) => {
  const { label, tooltip, labelBasis, tooltipPosition, children } = props;
  const fieldLabel = <div className="CharacterSetup__field-label">{label}</div>;
  return (
    <div data-search-label={label}>
      <Stack align="center" mb={1}>
        <Stack.Item basis={labelBasis || '48%'}>
          {tooltip ? (
            <Tooltip
              content={<span className="Tooltip__text">{tooltip}</span>}
              position={tooltipPosition}
            >
              {fieldLabel}
            </Tooltip>
          ) : (
            fieldLabel
          )}
        </Stack.Item>
        <Stack.Item grow basis={0} style={{ minWidth: 0 }}>
          <Box
            className="CharacterSetup__field-control"
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'flex-end',
              width: '100%',
            }}
          >
            {children}
          </Box>
        </Stack.Item>
      </Stack>
    </div>
  );
};

export const ColorField = (props: {
  label: string;
  value: string | null | undefined;
  action?: string;
  params?: ActParams;
  disabled?: boolean;
  disabledNote?: string;
  tooltip?: string;
  labelBasis?: string;
}) => {
  const { act } = useBackend<any>();
  const {
    label,
    value,
    action,
    params,
    disabled,
    disabledNote,
    tooltip,
    labelBasis,
  } = props;
  const [draft, setDraft] = useState<string | null>(null);
  const hex = safeHex(value);

  if (disabled) {
    return (
      <FieldRow label={label} tooltip={tooltip} labelBasis={labelBasis}>
        <Box color="label">{disabledNote || 'выключено'}</Box>
      </FieldRow>
    );
  }

  if (!action) {
    return null;
  }

  return (
    <FieldRow label={label} tooltip={tooltip} labelBasis={labelBasis}>
      <Box
        style={{ display: 'flex', alignItems: 'center', width: '100%' }}
        onBlur={() => setDraft(null)}
      >
        <Stack align="center" style={{ width: '100%' }}>
          <Stack.Item>
            <ColorPicker
              portalRoot=".CharacterSetup__editor"
              value={hex}
              tooltip={`Пикер цвета: ${hex}`}
              onCommit={(next) => act(action, { ...params, color: next })}
            />
          </Stack.Item>
          <Stack.Item grow>
            <Input
              width="100%"
              placeholder="#RRGGBB"
              value={draft ?? hex}
              onInput={(e, next) => setDraft(uppercaseHexInput(e, next))}
              onChange={(e, next) => {
                const normalized = normalizeHex(next);
                setDraft(null);
                if (normalized) {
                  act(action, { ...params, color: normalized });
                }
              }}
            />
          </Stack.Item>
        </Stack>
      </Box>
    </FieldRow>
  );
};

export const ColorChip = (props: {
  value: string | null | undefined;
  action: string;
  params?: ActParams;
  tooltip?: string;
}) => {
  const { act } = useBackend<any>();
  const { value, action, params, tooltip } = props;
  return (
    <ColorPicker
      portalRoot=".CharacterSetup__editor"
      value={value}
      tooltip={tooltip}
      width="30px"
      height="20px"
      onCommit={(next) => act(action, { ...params, color: next })}
    />
  );
};

export const ToggleRow = (props: {
  label: string;
  value: boolean;
  action: string;
  params?: ActParams;
  onLabel?: string;
  offLabel?: string;
  tooltip?: string;
  labelBasis?: string;
  tooltipPosition?: TooltipPosition;
}) => {
  const { act, data } = useBackend<{ emissivesAllowed: boolean }>();
  const {
    label,
    value,
    action,
    params,
    onLabel = 'Да',
    offLabel = 'Нет',
    tooltip,
    labelBasis,
    tooltipPosition,
  } = props;
  const glow = action === 'toggle_emissive_part';
  const glowButton =
    glow || (action === 'set_feature' && params?.key === 'allow_emissives');
  if (glow && !data.emissivesAllowed) return null;
  return (
    <FieldRow label={label} tooltip={tooltip} labelBasis={labelBasis} tooltipPosition={tooltipPosition}>
      <Stack align="center" inline>
        <Stack.Item>
          <Button
            className="CharacterSetup__toggle"
            icon={glowButton ? 'lightbulb' : value ? 'check' : 'times'}
            selected={!!value}
            tooltip={
              glowButton
                ? `${tooltip || label}: ${value ? onLabel : offLabel}`
                : tooltip
            }
            tooltipPosition={tooltipPosition}
            aria-label={glowButton ? label : undefined}
            onClick={() => (params ? act(action, params) : act(action))}
          />
        </Stack.Item>
        {!glowButton && (
          <Stack.Item>
            <Box ml={1} color={value ? undefined : 'label'}>
              {value ? onLabel : offLabel}
            </Box>
          </Stack.Item>
        )}
      </Stack>
    </FieldRow>
  );
};

export const asOptions = (source: unknown): SelectOption[] => {
  if (Array.isArray(source)) {
    return source as SelectOption[];
  }
  if (source && typeof source === 'object') {
    return Object.entries(source as Record<string, string | number>).map(
      ([value, label]) => ({ value, displayText: `${label}` })
    );
  }
  return [];
};

const normalizeOptions = (
  options: unknown
): (string | { value: string | number; displayText: string })[] =>
  asOptions(options).map((option) => {
    if (typeof option === 'string') {
      return option;
    }
    return {
      value: option.value,
      displayText: option.displayText || option.label || `${option.value}`,
    };
  });

export const CycleChoice = (props: {
  children: React.ReactNode;
  onCycle: (direction: 'prev' | 'next') => void;
  disabled?: boolean;
  arrowsTogether?: boolean;
  tooltipPosition?: TooltipPosition;
}) => {
  const arrow = (direction: 'prev' | 'next') => (
    <Stack.Item>
      <Button
        className="CharacterSetup__cycle-arrow"
        icon={direction === 'prev' ? 'chevron-left' : 'chevron-right'}
        tooltip={
          direction === 'prev' ? 'Предыдущий вариант' : 'Следующий вариант'
        }
        tooltipPosition={props.tooltipPosition}
        aria-label={
          direction === 'prev' ? 'Предыдущий вариант' : 'Следующий вариант'
        }
        disabled={props.disabled}
        onClick={() => props.onCycle(direction)}
      />
    </Stack.Item>
  );
  return (
    <Stack align="center" className="CharacterSetup__cycle">
      {!props.arrowsTogether && arrow('prev')}
      <Stack.Item grow>{props.children}</Stack.Item>
      {props.arrowsTogether && arrow('prev')}
      {arrow('next')}
    </Stack>
  );
};

export const SelectRow = (props: {
  label: string;
  value: string | number | null | undefined;
  options: SelectOption[];
  action: string;
  params?: ActParams;
  width?: string;
  tooltip?: string;
  labelBasis?: string;
  extra?: React.ReactNode;
  over?: boolean;
  tooltipPosition?: TooltipPosition;
  onCycle?: (direction: 'prev' | 'next') => void;
  arrowsTogether?: boolean;
}) => {
  const { act } = useBackend<any>();
  const {
    label,
    value,
    options,
    action,
    params,
    width,
    tooltip,
    labelBasis,
    extra,
    over,
    tooltipPosition,
    onCycle,
    arrowsTogether,
  } = props;
  const dropdown = (
    <Dropdown
      over={over}
      tooltip={tooltip}
      tooltipPosition={tooltipPosition}
      width={width || '100%'}
      options={normalizeOptions(options || [])}
      selected={value}
      onSelected={(next) => act(action, { ...params, value: next })}
    />
  );
  const choice = onCycle ? (
    <CycleChoice
      onCycle={onCycle}
      disabled={options.length < 2}
      arrowsTogether={arrowsTogether}
      tooltipPosition={tooltipPosition}
    >
      {dropdown}
    </CycleChoice>
  ) : (
    dropdown
  );
  return (
    <FieldRow
      label={label}
      tooltip={tooltip}
      labelBasis={labelBasis}
      tooltipPosition={tooltipPosition}
    >
      {extra ? (
        <Stack align="center" style={{ width: '100%' }}>
          <Stack.Item grow>{choice}</Stack.Item>
          <Stack.Item>{extra}</Stack.Item>
        </Stack>
      ) : (
        choice
      )}
    </FieldRow>
  );
};

export const TextRow = (props: {
  label: string;
  value: string | null | undefined;
  action: string;
  width?: string;
  tooltip?: string;
  labelBasis?: string;
}) => {
  const { act } = useBackend<any>();
  const { label, value, action, width, tooltip, labelBasis } = props;
  return (
    <FieldRow label={label} tooltip={tooltip} labelBasis={labelBasis}>
      <Input
        width={width || '100%'}
        value={value || ''}
        onChange={(e, next) => act(action, { value: next })}
      />
    </FieldRow>
  );
};

export const TextAreaRow = (props: {
  label: string;
  value: string | null | undefined;
  action: string;
  height?: string;
  maxLength?: number;
  tooltip?: string;
  placeholder?: string;
  editField?: string;
}) => {
  const { act, data } = useBackend<{ defaultSlot: number }>();
  const {
    label,
    value,
    action,
    height,
    maxLength,
    tooltip,
    placeholder,
    editField,
  } = props;
  const [expanded, setExpanded] = useState(false);
  const timer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const lastSent = useRef(value || '');
  const cancelled = useRef(false);
  useEffect(() => () => clearTimeout(timer.current), []);
  const commit = (text: string) => {
    clearTimeout(timer.current);
    if (text === lastSent.current) {
      return;
    }
    lastSent.current = text;
    act(action, { text, character_slot: data.defaultSlot });
  };
  return (
    <Box
      data-search-label={label}
      mb={1}
      onKeyDownCapture={(event) => {
        if (event.key === 'Escape') {
          clearTimeout(timer.current);
          cancelled.current = true;
        }
      }}
    >
      <Stack align="center" mb={1}>
        <Stack.Item grow>
          <Box title={tooltip}>{label}</Box>
        </Stack.Item>
        {editField && (
          <Stack.Item>
            <Button
              compact
              icon="window-maximize"
              tooltip="Редактировать в отдельном окне"
              onClick={() => act('edit_text', { field: editField })}
            />
          </Stack.Item>
        )}
        <Stack.Item>
          <Button
            compact
            icon={expanded ? 'compress' : 'expand'}
            tooltip={expanded ? 'Свернуть редактор' : 'Развернуть редактор'}
            onClick={() => setExpanded(!expanded)}
          />
        </Stack.Item>
      </Stack>
      {expanded && !!tooltip && (
        <Box color="label" mb={1}>
          <b>Формат описания:</b> {tooltip}
        </Box>
      )}
      <TextArea
        fluid
        scrollbar
        height={expanded ? '400px' : height || '110px'}
        maxLength={maxLength}
        placeholder={placeholder}
        value={value || ''}
        onInput={(event, next) => {
          cancelled.current = false;
          clearTimeout(timer.current);
          timer.current = setTimeout(() => commit(next), 600);
        }}
        onChange={(event, next) => {
          if (!cancelled.current) commit(next);
          cancelled.current = false;
        }}
      />
    </Box>
  );
};

export interface FeatureField {
  key: string;
  label: string;
  type: 'bool' | 'num' | 'list' | 'color' | 'cycle' | 'reagent';
  scope: string;
  hint?: string;
  min?: number;
  max?: number;
  step?: number;
  scale?: number;
  options?: unknown;
  colorCheck?: string;
  deletable?: boolean;
  zeroLabel?: string;
  clampTo?: string;
  clampAbove?: boolean;
  clampBelow?: boolean;
}

export function asArray<T>(value: T[] | undefined | null): T[] {
  return Array.isArray(value) ? (value as T[]) : [];
}

const asReagentOptions = (source: unknown): SelectOption[] => {
  if (!Array.isArray(source)) {
    return [];
  }
  return source.map((option) => {
    const fluid = option as { name?: string; type?: string };
    return { value: fluid.type || '', displayText: fluid.name || '' };
  });
};

export const FeatureFieldView = (props: {
  field: FeatureField;
  value: unknown;
  cycle?: boolean;
}) => (
  <div data-search-id={props.field.key} data-search-label={props.field.label}>
    <FeatureFieldControl {...props} />
  </div>
);

const FeatureFieldControl = (props: {
  field: FeatureField;
  value: unknown;
  cycle?: boolean;
}) => {
  const { act } = useBackend<any>();
  const { field, value, cycle } = props;
  const onCycle = cycle
    ? (dir: 'prev' | 'next') => act('set_feature', { key: field.key, dir })
    : undefined;

  if (field.type === 'bool') {
    return (
      <ToggleRow
        label={field.label}
        tooltip={field.hint}
        value={!!value}
        action="set_feature"
        params={{ key: field.key, value: !value }}
      />
    );
  }

  if (field.type === 'color') {
    return (
      <ColorField
        label={field.label}
        tooltip={field.hint}
        value={value as string}
        action="set_feature"
        params={{ key: field.key }}
      />
    );
  }

  if (field.type === 'num') {
    const empty = field.deletable && !(value as number);
    return (
      <FieldRow label={field.label} tooltip={field.hint}>
        <Stack align="center" style={{ width: '100%' }}>
          <Stack.Item grow>
            <NumberInput
              width="100%"
              step={field.step || 1}
              value={(value as number) || 0}
              minValue={field.min}
              maxValue={field.max}
              format={(next: number) => `${Math.round(next * 100) / 100}`}
              onChange={(e, next) =>
                act('set_feature', { key: field.key, value: next })
              }
            />
          </Stack.Item>
          {empty && (
            <Stack.Item>
              <Box color="label">{field.zeroLabel || 'отключено'}</Box>
            </Stack.Item>
          )}
        </Stack>
      </FieldRow>
    );
  }

  if (field.type === 'reagent') {
    return (
      <SelectRow
        label={field.label}
        tooltip={field.hint}
        value={value as string}
        options={asReagentOptions(field.options)}
        onCycle={onCycle}
        labelBasis={cycle ? '34%' : undefined}
        action="set_feature"
        params={{ key: field.key }}
      />
    );
  }

  const listOptions = [...asOptions(field.options)];
  if (field.deletable) {
    listOptions.unshift({
      value: '',
      displayText: field.zeroLabel || 'Отключено',
    });
  }
  return (
    <SelectRow
      label={field.label}
      tooltip={field.hint}
      value={
        field.deletable && !value ? ('' as string) : (value as string | number)
      }
      options={listOptions}
      onCycle={onCycle}
      labelBasis={cycle ? '34%' : undefined}
      action="set_feature"
      params={{ key: field.key }}
    />
  );
};

export const renderFeatureField = (
  fields: FeatureField[],
  values: Record<string, unknown>,
  key: string
) => {
  const field = fields.find((entry) => entry.key === key);
  if (!field) {
    return null;
  }
  return <FeatureFieldView key={key} field={field} value={values[key]} />;
};

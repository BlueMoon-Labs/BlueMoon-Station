import { clamp } from 'common/math';
import { useEffect, useRef, useState } from 'react';
import { createPortal } from 'react-dom';

import { useLocalState } from '../backend';
import { Box } from './Box';
import { Button } from './Button';
import { Dropdown } from './Dropdown';
import { Input } from './Input';
import { NumberInput } from './NumberInput';
import { Stack } from './Stack';

export const safeHex = (value: string | null | undefined): string => {
  if (!value) {
    return '#000000';
  }
  let hex = value.charAt(0) === '#' ? value.slice(1) : value;
  if (hex.length === 3) {
    hex = hex.replace(/./g, (char) => char + char);
  }
  return /^[0-9a-fA-F]{6}$/.test(hex) ? `#${hex.toUpperCase()}` : '#000000';
};

export const normalizeHex = (raw: string): string | null => {
  let hex = raw.trim();
  if (hex.charAt(0) === '#') {
    hex = hex.slice(1);
  }
  if (hex.length === 3) {
    hex = hex.replace(/./g, (char) => char + char);
  }
  return /^[0-9a-fA-F]{6}$/.test(hex) ? `#${hex.toUpperCase()}` : null;
};

export const uppercaseHexInput = (
  event: React.FormEvent<HTMLInputElement>,
  value: string
) => {
  const uppercase = value.toUpperCase();
  if (uppercase !== value) {
    const input = event.target as HTMLInputElement;
    const { selectionStart, selectionEnd } = input;
    input.value = uppercase;
    input.setSelectionRange(selectionStart, selectionEnd);
  }
  return uppercase;
};

const hexToHsv = (hex: string): [number, number, number] => {
  const clean = safeHex(hex).slice(1);
  const r = parseInt(clean.slice(0, 2), 16) / 255;
  const g = parseInt(clean.slice(2, 4), 16) / 255;
  const b = parseInt(clean.slice(4, 6), 16) / 255;
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  const delta = max - min;
  let hue = 0;
  if (delta !== 0) {
    if (max === r) {
      hue = 60 * (((g - b) / delta) % 6);
    } else if (max === g) {
      hue = 60 * ((b - r) / delta + 2);
    } else {
      hue = 60 * ((r - g) / delta + 4);
    }
  }
  if (hue < 0) {
    hue += 360;
  }
  return [hue, max === 0 ? 0 : delta / max, max];
};

const hsvToHex = (hue: number, saturation: number, brightness: number) => {
  const chroma = brightness * saturation;
  const sector = hue / 60;
  const mix = chroma * (1 - Math.abs((sector % 2) - 1));
  const base = brightness - chroma;
  let channels: [number, number, number];
  if (sector < 1) {
    channels = [chroma, mix, 0];
  } else if (sector < 2) {
    channels = [mix, chroma, 0];
  } else if (sector < 3) {
    channels = [0, chroma, mix];
  } else if (sector < 4) {
    channels = [0, mix, chroma];
  } else if (sector < 5) {
    channels = [mix, 0, chroma];
  } else {
    channels = [chroma, 0, mix];
  }
  const toByte = (channel: number) =>
    clamp(Math.round((channel + base) * 255), 0, 255)
      .toString(16)
      .toUpperCase()
      .padStart(2, '0');
  return `#${toByte(channels[0])}${toByte(channels[1])}${toByte(channels[2])}`;
};

const hsvToHsl = (
  hue: number,
  saturation: number,
  brightness: number
): [number, number, number] => {
  const lightness = brightness * (1 - saturation / 2);
  return [
    hue,
    lightness === 0 || lightness === 1
      ? 0
      : (brightness - lightness) / Math.min(lightness, 1 - lightness),
    lightness,
  ];
};

const hslToHsv = (
  hue: number,
  saturation: number,
  lightness: number
): [number, number, number] => {
  const brightness =
    lightness + saturation * Math.min(lightness, 1 - lightness);
  // Сохраняем тон серого и чёрного, чтобы его можно было выбрать до насыщенности.
  return [
    hue % 360,
    brightness === 0 ? 0 : 2 * (1 - lightness / brightness),
    brightness,
  ];
};

// RGB сняты с центров ячеек старого диалога: ряды идут сверху вниз, цвета слева направо.
// Не заменяем их расчётной HSV-палитрой: в оригинале есть нестандартные оттенки.
const PALETTE_ROWS = [
  [
    '#003366', '#336699', '#3366CC', '#003399', '#000099', '#0000CC', '#000066',
  ],
  [
    '#006666', '#006699', '#0099CC', '#0066CC', '#0033CC', '#0000FF', '#3333FF',
    '#333399',
  ],
  [
    '#008080', '#009999', '#33CCCC', '#00CCFF', '#0099FF', '#0066FF', '#3366FF',
    '#3333CC', '#666699',
  ],
  [
    '#339966', '#00CC99', '#00FFCC', '#00FFFF', '#33CCFF', '#3399FF', '#6699FF',
    '#6666FF', '#6600FF', '#6600CC',
  ],
  [
    '#339933', '#00CC66', '#00FF99', '#66FFCC', '#66FFFF', '#66CCFF', '#99CCFF',
    '#9999FF', '#9966FF', '#9933FF', '#9900FF',
  ],
  [
    '#006600', '#00CC00', '#00FF00', '#66FF99', '#99FFCC', '#CCFFFF', '#CCECFF',
    '#CCCCFF', '#CC99FF', '#CC66FF', '#CC00FF', '#9900CC',
  ],
  [
    '#003300', '#008000', '#33CC33', '#66FF66', '#99FF99', '#CCFFCC', '#FFFFFF',
    '#FFCCFF', '#FF99FF', '#FF66FF', '#FF00FF', '#CC00CC', '#660066',
  ],
  [
    '#336600', '#009900', '#66FF33', '#99FF66', '#CCFF99', '#FFFFCC', '#FFCCCC',
    '#FF99CC', '#FF66CC', '#FF33CC', '#CC0099', '#800080',
  ],
  [
    '#333300', '#669900', '#99FF33', '#CCFF66', '#FFFF99', '#FFCC99', '#FF9999',
    '#FF6699', '#FF3399', '#CC3399', '#990099',
  ],
  [
    '#666633', '#99CC00', '#CCFF33', '#FFFF66', '#FFCC66', '#FF9966', '#FF7C80',
    '#FF0066', '#D60093', '#993366',
  ],
  [
    '#808000', '#CCCC00', '#FFFF00', '#FFCC00', '#FF9933', '#FF6600', '#FF5050',
    '#CC0066', '#660033',
  ],
  [
    '#996633', '#CC9900', '#FF9900', '#CC6600', '#FF3300', '#FF0000', '#CC0000',
    '#990033',
  ],
  [
    '#663300', '#996600', '#CC3300', '#993300', '#990000', '#800000', '#A50021',
  ],
];
const GRAYSCALE_ROWS = [
  [
    '#F8F8F8', '#DDDDDD', '#B2B2B2', '#808080', '#5F5F5F', '#333333', '#1C1C1C',
    '#080808',
  ],
  [
    '#EAEAEA', '#C0C0C0', '#969696', '#777777', '#4D4D4D', '#292929', '#111111',
  ],
];
const HEX_WIDTH = 14;
const HEX_HEIGHT = 16;
const HEX_ROW_STEP = 12;
const PALETTE_WIDTH = HEX_WIDTH * 13;
const PALETTE_HEIGHT = HEX_ROW_STEP * 12 + HEX_HEIGHT;
const GRAYSCALE_HEIGHT = HEX_HEIGHT * 2;

// Процентные координаты сохраняют геометрию оригинала при изменении размера окна.
const paletteSwatchStyle = (
  x: number,
  y: number,
  width: number,
  height: number,
  canvasHeight: number
): React.CSSProperties => ({
  left: `${(x / PALETTE_WIDTH) * 100}%`,
  top: `${(y / canvasHeight) * 100}%`,
  width: `${(width / PALETTE_WIDTH) * 100}%`,
  height: `${(height / canvasHeight) * 100}%`,
});

const WHEEL_SIZE = 260;
const TRIANGLE_TOP = 77;
const TRIANGLE_BOTTOM = 236;
const TRIANGLE_LEFT = 130 - 53 * Math.sqrt(3);
const TRIANGLE_RIGHT = 130 + 53 * Math.sqrt(3);

const triangleWeights = (x: number, y: number): [number, number, number] => {
  const black = (y - TRIANGLE_TOP) / (TRIANGLE_BOTTOM - TRIANGLE_TOP);
  const white =
    (x - TRIANGLE_LEFT - black * (130 - TRIANGLE_LEFT)) /
    (TRIANGLE_RIGHT - TRIANGLE_LEFT);
  return [1 - black - white, white, black];
};

const HueTriangle = (props: {
  hsv: [number, number, number];
  onChange: (next: [number, number, number]) => void;
}) => {
  const {
    hsv: [hue, saturation, brightness],
    onChange,
  } = props;
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const drag = useRef<'hue' | 'triangle' | null>(null);
  // Цветная вершина исходного треугольника направлена на 300°, поэтому добавляем 60°.
  const triangleRotation = hue + 60;
  const radians = (triangleRotation * Math.PI) / 180;
  const cos = Math.cos(radians);
  const sin = Math.sin(radians);
  // Для выбора цвета переводим указатель обратно в координаты исходного треугольника.
  const weightsAt = (x: number, y: number) => triangleWeights(
    130 + (x - 130) * cos + (y - 130) * sin,
    130 - (x - 130) * sin + (y - 130) * cos
  );
  useEffect(() => {
    const context = canvasRef.current?.getContext('2d');
    if (!context) return;
    const pixels = context.createImageData(WHEEL_SIZE, WHEEL_SIZE);
    const hueHex = hsvToHex(hue, 1, 1);
    const channels = [1, 3, 5].map((offset) =>
      parseInt(hueHex.slice(offset, offset + 2), 16)
    );
    for (let y = TRIANGLE_TOP; y <= TRIANGLE_BOTTOM; y++) {
      for (let x = Math.floor(TRIANGLE_LEFT); x <= TRIANGLE_RIGHT; x++) {
        const weights = triangleWeights(x + 0.5, y + 0.5);
        if (weights.some((weight) => weight < 0)) continue;
        const offset = (y * WHEEL_SIZE + x) * 4;
        for (let channel = 0; channel < 3; channel++) {
          pixels.data[offset + channel] = Math.round(
            channels[channel] * weights[0] + 255 * weights[1]
          );
        }
        pixels.data[offset + 3] = 255;
      }
    }
    context.putImageData(pixels, 0, 0);
  }, [hue]);

  const point = (event: React.PointerEvent<HTMLDivElement>) => {
    const rect = event.currentTarget.getBoundingClientRect();
    return [
      ((event.clientX - rect.left) / rect.width) * WHEEL_SIZE,
      ((event.clientY - rect.top) / rect.height) * WHEEL_SIZE,
    ];
  };
  const pick = (x: number, y: number) => {
    if (drag.current === 'hue') {
      const next = ((Math.atan2(x - 130, 130 - y) * 180) / Math.PI + 360) % 360;
      onChange([next, saturation, brightness]);
    } else if (drag.current === 'triangle') {
      // За пределами треугольника прижимаем выбор к его границам.
      const weights = weightsAt(x, y).map((weight) =>
        Math.max(0, weight)
      );
      const total = weights.reduce((sum, weight) => sum + weight, 0);
      const value = (weights[0] + weights[1]) / total;
      onChange([
        hue,
        value ? weights[0] / (weights[0] + weights[1]) : 0,
        value,
      ]);
    }
  };
  const hueWeight = saturation * brightness;
  const whiteWeight = (1 - saturation) * brightness;
  const blackWeight = 1 - brightness;
  return (
    <div
      className="ColorPicker__wheel"
      tabIndex={0}
      role="group"
      aria-label="Круг цветового тона и треугольник насыщенности и яркости"
      onKeyDown={(event) => {
        const changes: Record<string, [number, number]> = {
          ArrowLeft: [-0.01, 0],
          ArrowRight: [0.01, 0],
          ArrowUp: [0, 0.01],
          ArrowDown: [0, -0.01],
        };
        const change = changes[event.key];
        if (!change) return;
        event.preventDefault();
        onChange([
          hue,
          clamp(saturation + change[0], 0, 1),
          clamp(brightness + change[1], 0, 1),
        ]);
      }}
      onPointerDown={(event) => {
        if (event.button !== 0) return;
        const [x, y] = point(event);
        const radius = Math.hypot(x - 130, y - 130);
        if (radius >= 109 && radius <= 130) drag.current = 'hue';
        else if (weightsAt(x, y).every((weight) => weight >= 0)) {
          drag.current = 'triangle';
        } else return;
        event.currentTarget.focus();
        event.currentTarget.setPointerCapture(event.pointerId);
        pick(x, y);
      }}
      onPointerMove={(event) => {
        if (event.currentTarget.hasPointerCapture(event.pointerId)) {
          const [x, y] = point(event);
          pick(x, y);
        }
      }}
      onPointerUp={(event) => {
        if (event.currentTarget.hasPointerCapture(event.pointerId)) {
          event.currentTarget.releasePointerCapture(event.pointerId);
        }
        drag.current = null;
      }}
      onPointerCancel={() => {
        drag.current = null;
      }}
      onLostPointerCapture={() => {
        drag.current = null;
      }}
    >
      <div className="ColorPicker__hue-ring" />
      <canvas
        ref={canvasRef}
        width={WHEEL_SIZE}
        height={WHEEL_SIZE}
        style={{ transform: `rotate(${triangleRotation}deg)` }}
      />
      <svg viewBox="0 0 260 260" aria-hidden="true">
        <circle
          cx={130 + 119 * Math.sin((hue * Math.PI) / 180)}
          cy={130 - 119 * Math.cos((hue * Math.PI) / 180)}
          r="4"
          className="ColorPicker__wheel-marker"
        />
        <g transform={`rotate(${triangleRotation} 130 130)`}>
          <polygon
            points={TRIANGLE_LEFT + ',77 ' + TRIANGLE_RIGHT + ',77 130,236'}
            fill="none"
            stroke="rgba(255,255,255,0.4)"
          />
          <circle
            cx={
              hueWeight * TRIANGLE_LEFT +
              whiteWeight * TRIANGLE_RIGHT +
              blackWeight * 130
            }
            cy={brightness * TRIANGLE_TOP + blackWeight * TRIANGLE_BOTTOM}
            r="4"
            className="ColorPicker__wheel-marker"
          />
        </g>
      </svg>
    </div>
  );
};

export const ColorPickerPanel = (props: {
  value: string;
  onCommit: (hex: string) => void;
  onCancel: () => void;
  title?: string;
  message?: string;
  largeButtons?: boolean;
  swappedButtons?: boolean;
  className?: string;
}) => {
  const {
    value,
    onCommit,
    onCancel,
    title = 'Выбор цвета',
    message,
    largeButtons,
    swappedButtons,
    className,
  } = props;
  const [hsv, setHsv] = useState<[number, number, number]>(() =>
    hexToHsv(value)
  );
  const [draft, setDraft] = useState(() => safeHex(value));
  const [colorModel, setColorModel] = useState<'RGB' | 'HSL'>('RGB');
  const [history, setRecent] = useLocalState<string[]>(
    'colorPickerHistory',
    []
  );
  const recent = [...new Set(history.map(safeHex))];
  const hex = hsvToHex(...hsv);
  const hsl = hsvToHsl(...hsv);
  const channels = colorModel === 'RGB' ? ['R', 'G', 'B'] : ['H', 'S', 'L'];
  const select = (next: string) => {
    setHsv(hexToHsv(next));
    setDraft(safeHex(next));
  };
  const selectHsv = (next: [number, number, number]) => {
    setHsv(next);
    setDraft(hsvToHex(...next));
  };
  const valid = normalizeHex(draft);
  const commit = (color: string) => {
    color = color.toUpperCase();
    setRecent(
      [color, ...recent.filter((recentColor) => recentColor !== color)].slice(
        0,
        12
      )
    );
    onCommit(color);
  };
  const apply = () => {
    if (valid) commit(valid);
  };
  const swatches = (
    colors: string[],
    position?: (index: number) => React.CSSProperties
  ) =>
    colors.map((color, index) => (
      <button
        key={color}
        type="button"
        className="ColorPicker__swatch"
        style={{
          '--swatch-color': color,
          ...position?.(index),
        } as React.CSSProperties}
        aria-label={'Выбрать цвет ' + color}
        aria-pressed={hex.toLowerCase() === color.toLowerCase()}
        onClick={() => select(color)}
        onDoubleClick={() => commit(color)}
      />
    ));

  return (
    <div
      className={'ColorPicker' + (className ? ' ' + className : '')}
      role="dialog"
      aria-modal="true"
      aria-label={title || 'Выбор цвета'}
    >
      {!!title && <Box className="ColorPicker__title">{title}</Box>}
      {!!message && (
        <Box color="label" mb={1} preserveWhitespace>
          {message}
        </Box>
      )}
      <div className="ColorPicker__layout">
        <div>
          <div className="ColorPicker__presets">
            <div
              className="ColorPicker__honeycomb"
              style={{ aspectRatio: `${PALETTE_WIDTH} / ${PALETTE_HEIGHT}` }}
              role="group"
              aria-label="Цветовая палитра"
            >
              {PALETTE_ROWS.flatMap((row, rowIndex) =>
                swatches(row, (column) =>
                  paletteSwatchStyle(
                    (PALETTE_WIDTH - row.length * HEX_WIDTH) / 2 + column * HEX_WIDTH,
                    rowIndex * HEX_ROW_STEP,
                    HEX_WIDTH,
                    HEX_HEIGHT,
                    PALETTE_HEIGHT
                  )
                )
              )}
            </div>
            <div
              className="ColorPicker__grayscale"
              style={{ aspectRatio: `${PALETTE_WIDTH} / ${GRAYSCALE_HEIGHT}` }}
              role="group"
              aria-label="Оттенки серого"
            >
              {swatches(['#FFFFFF', '#000000'], (index) =>
                paletteSwatchStyle(
                  index * (PALETTE_WIDTH - HEX_WIDTH * 2),
                  0,
                  HEX_WIDTH * 2,
                  GRAYSCALE_HEIGHT,
                  GRAYSCALE_HEIGHT
                )
              )}
              {GRAYSCALE_ROWS.flatMap((row, rowIndex) =>
                swatches(row, (column) =>
                  paletteSwatchStyle(
                    (PALETTE_WIDTH - row.length * HEX_WIDTH) / 2 + column * HEX_WIDTH,
                    HEX_HEIGHT / 4 + rowIndex * HEX_ROW_STEP,
                    HEX_WIDTH,
                    HEX_HEIGHT,
                    GRAYSCALE_HEIGHT
                  )
                )
              )}
            </div>
          </div>
          {!!recent.length && (
            <>
              <Box color="label" mt={1} mb={1}>
                Недавние цвета
              </Box>
              <div className="ColorPicker__palette">{swatches(recent)}</div>
            </>
          )}
        </div>
        <div>
          <div className="ColorPicker__editor">
            <HueTriangle hsv={hsv} onChange={selectHsv} />
            <div>
              <div className="ColorPicker__values">
                <Dropdown
                  width="100%"
                  aria-label="Цветовая модель"
                  selected={colorModel}
                  options={['RGB', 'HSL']}
                  onSelected={setColorModel}
                />
                {channels.map((channel, index) => (
                  <div key={colorModel + channel}>
                    <Box color="label" mb={0.5}>
                      {channel}
                    </Box>
                    <NumberInput
                      width="100%"
                      minValue={0}
                      maxValue={
                        colorModel === 'RGB' ? 255 : index === 0 ? 360 : 100
                      }
                      step={1}
                      unit={
                        colorModel === 'HSL'
                          ? index === 0
                            ? '°'
                            : '%'
                          : undefined
                      }
                      format={(value: number) => Math.round(value * 100) / 100}
                      value={
                        colorModel === 'HSL'
                          ? hsl[index] * (index === 0 ? 1 : 100)
                          : parseInt(
                              hex.slice(1 + index * 2, 3 + index * 2),
                              16
                            )
                      }
                      onChange={(event, next) => {
                        if (!Number.isFinite(next)) return;
                        if (colorModel === 'HSL') {
                          const nextHsl: [number, number, number] = [...hsl];
                          nextHsl[index] =
                            index === 0
                              ? clamp(next, 0, 360)
                              : clamp(next, 0, 100) / 100;
                          selectHsv(hslToHsv(...nextHsl));
                          return;
                        }
                        const channels = [1, 3, 5].map((offset) =>
                          hex.slice(offset, offset + 2)
                        );
                        channels[index] = clamp(Math.round(next), 0, 255)
                          .toString(16)
                          .padStart(2, '0');
                        select('#' + channels.join(''));
                      }}
                    />
                  </div>
                ))}
                <div>
                  <Box color="label" mb={0.5}>
                    HEX
                  </Box>
                  <Input
                    fluid
                    autoFocus
                    value={draft}
                    placeholder="#RRGGBB"
                    onInput={(event, next) => {
                      setDraft(uppercaseHexInput(event, next));
                      const normalized = normalizeHex(next);
                      if (normalized) setHsv(hexToHsv(normalized));
                    }}
                    onEnter={apply}
                  />
                </div>
              </div>

              <div className="ColorPicker__comparison">
                <Box color="label">Новый</Box>
                <div
                  className="ColorPicker__sample"
                  style={{ background: hex }}
                />
                <button
                  className="ColorPicker__sample"
                  type="button"
                  style={{ background: value }}
                  aria-label="Вернуть исходный цвет"
                  onClick={() => select(value)}
                />
                <Box color="label">Исходный</Box>
              </div>
            </div>
          </div>
        </div>
      </div>
      {!valid && (
        <Box color="bad" mt={1}>
          Введите 3 или 6 шестнадцатеричных цифр.
        </Box>
      )}
      <Stack mt={2} direction={swappedButtons ? 'row-reverse' : 'row'}>
        <Stack.Item grow>
          <Button
            fluid
            icon="times"
            content="Отмена"
            height={largeButtons ? 2 : undefined}
            onClick={onCancel}
          />
        </Stack.Item>
        <Stack.Item grow>
          <Button
            fluid
            height={largeButtons ? 2 : undefined}
            icon="check"
            color="good"
            content="Применить"
            disabled={!valid}
            onClick={apply}
          />
        </Stack.Item>
      </Stack>
    </div>
  );
};

export const ColorPicker = (props: {
  value: string | null | undefined;
  onCommit: (hex: string) => void;
  tooltip?: string;
  width?: string;
  height?: string;
  portalRoot?: string;
}) => {
  const {
    value,
    onCommit,
    tooltip,
    width = '28px',
    height = '24px',
    portalRoot,
  } = props;
  const [open, setOpen] = useState(false);
  const hex = safeHex(value);
  const anchorRef = useRef<HTMLButtonElement>(null);
  const close = () => {
    setOpen(false);
    anchorRef.current?.focus();
  };
  useEffect(() => {
    if (!open) return;
    const escape = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        event.preventDefault();
        event.stopPropagation();
        setOpen(false);
        anchorRef.current?.focus();
      }
    };
    document.addEventListener('keydown', escape, true);
    return () => document.removeEventListener('keydown', escape, true);
  }, [open]);
  const root =
    anchorRef.current?.closest(portalRoot || '.Layout') || document.body;
  return (
    <>
      <button
        ref={anchorRef}
        type="button"
        className="ColorPicker__chip"
        title={tooltip || hex}
        aria-label={tooltip || 'Выбрать цвет ' + hex}
        aria-expanded={open}
        onClick={() => setOpen(!open)}
        style={{ width, height, background: hex }}
      />
      {open &&
        root &&
        createPortal(
          <div
            className="ColorPicker__overlay"
            onMouseDown={(event) => {
              if (event.target === event.currentTarget) close();
            }}
          >
            <ColorPickerPanel
              value={hex}
              onCommit={(next) => {
                onCommit(next);
                close();
              }}
              onCancel={close}
            />
          </div>,
          root
        )}
    </>
  );
};
